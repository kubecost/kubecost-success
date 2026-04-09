terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# IAM Policy for Kubecost to access AWS Cost and Usage Reports
data "aws_iam_policy_document" "kubecost_s3_access" {
  statement {
    sid    = "KubecostCURAccess"
    effect = "Allow"
    
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    
    resources = [
      "arn:aws:s3:::${var.cur_bucket_name}",
      "arn:aws:s3:::${var.cur_bucket_name}/*",
    ]
  }
  
  statement {
    sid    = "KubecostCURReportAccess"
    effect = "Allow"
    
    actions = [
      "cur:DescribeReportDefinitions",
    ]
    
    resources = ["*"]
  }
}

# IAM Policy for Kubecost to access AWS Pricing API
data "aws_iam_policy_document" "kubecost_pricing_access" {
  statement {
    sid    = "KubecostPricingAccess"
    effect = "Allow"
    
    actions = [
      "pricing:GetProducts",
      "pricing:DescribeServices",
    ]
    
    resources = ["*"]
  }
}

# Combined IAM Policy
data "aws_iam_policy_document" "kubecost_combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.kubecost_s3_access.json,
    data.aws_iam_policy_document.kubecost_pricing_access.json,
  ]
}

# IAM Policy
resource "aws_iam_policy" "kubecost" {
  name        = var.iam_policy_name
  description = "IAM policy for Kubecost to access AWS cost data"
  policy      = data.aws_iam_policy_document.kubecost_combined.json
  
  tags = merge(
    var.tags,
    {
      Name      = var.iam_policy_name
      ManagedBy = "terraform"
      Purpose   = "kubecost-integration"
    }
  )
}

# IAM Role for IRSA (IAM Roles for Service Accounts)
resource "aws_iam_role" "kubecost" {
  count = var.create_irsa_role ? 1 : 0
  
  name               = var.iam_role_name
  description        = "IAM role for Kubecost service account"
  assume_role_policy = data.aws_iam_policy_document.kubecost_assume_role[0].json
  
  tags = merge(
    var.tags,
    {
      Name      = var.iam_role_name
      ManagedBy = "terraform"
      Purpose   = "kubecost-integration"
    }
  )
}

# Assume Role Policy for IRSA
data "aws_iam_policy_document" "kubecost_assume_role" {
  count = var.create_irsa_role ? 1 : 0
  
  statement {
    effect = "Allow"
    
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    
    actions = ["sts:AssumeRoleWithWebIdentity"]
    
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_arn, "/^(.*provider/)/", "")}:sub"
      values   = ["system:serviceaccount:${var.kubecost_namespace}:${var.service_account_name}"]
    }
    
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_arn, "/^(.*provider/)/", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "kubecost" {
  count = var.create_irsa_role ? 1 : 0
  
  role       = aws_iam_role.kubecost[0].name
  policy_arn = aws_iam_policy.kubecost.arn
}

# Kubernetes Service Account with IRSA annotation
resource "kubernetes_service_account" "kubecost" {
  count = var.create_service_account ? 1 : 0
  
  metadata {
    name      = var.service_account_name
    namespace = var.kubecost_namespace
    
    annotations = var.create_irsa_role ? {
      "eks.amazonaws.com/role-arn" = aws_iam_role.kubecost[0].arn
    } : {}
    
    labels = {
      "app.kubernetes.io/name"       = "kubecost"
      "app.kubernetes.io/component"  = "cost-analyzer"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# Kubernetes Secret for AWS credentials (alternative to IRSA)
resource "kubernetes_secret" "aws_credentials" {
  count = var.use_static_credentials ? 1 : 0
  
  metadata {
    name      = "kubecost-aws-credentials"
    namespace = var.kubecost_namespace
    
    labels = {
      "app.kubernetes.io/name"       = "kubecost"
      "app.kubernetes.io/component"  = "cost-analyzer"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  
  data = {
    AWS_ACCESS_KEY_ID     = var.aws_access_key_id
    AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
  }
  
  type = "Opaque"
}

# ConfigMap for AWS integration configuration
resource "kubernetes_config_map" "aws_integration" {
  metadata {
    name      = "kubecost-aws-integration"
    namespace = var.kubecost_namespace
    
    labels = {
      "app.kubernetes.io/name"       = "kubecost"
      "app.kubernetes.io/component"  = "cost-analyzer"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  
  data = {
    "aws-config.json" = jsonencode({
      provider              = "aws"
      description           = "AWS Cost Integration"
      AWS_ACCOUNT_ID        = var.aws_account_id
      athenaBucketName      = var.athena_bucket_name
      athenaRegion          = var.athena_region
      athenaDatabase        = var.athena_database
      athenaTable           = var.athena_table
      athenaWorkgroup       = var.athena_workgroup
      projectID             = var.aws_account_id
      billingDataDataset    = var.cur_bucket_name
      serviceKeyName        = var.use_static_credentials ? "kubecost-aws-credentials" : ""
      spotDataRegion        = var.spot_data_region
      spotDataBucket        = var.spot_data_bucket
      spotDataPrefix        = var.spot_data_prefix
    })
  }
}