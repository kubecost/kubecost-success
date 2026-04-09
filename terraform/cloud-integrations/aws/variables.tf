variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  
  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "AWS Account ID must be a 12-digit number"
  }
}

variable "cur_bucket_name" {
  description = "S3 bucket name containing Cost and Usage Reports"
  type        = string
}

variable "athena_bucket_name" {
  description = "S3 bucket name for Athena query results"
  type        = string
}

variable "athena_region" {
  description = "AWS region for Athena"
  type        = string
  default     = "us-east-1"
}

variable "athena_database" {
  description = "Athena database name for CUR data"
  type        = string
  default     = "athenacurcfn_kubecost"
}

variable "athena_table" {
  description = "Athena table name for CUR data"
  type        = string
  default     = "kubecost"
}

variable "athena_workgroup" {
  description = "Athena workgroup name"
  type        = string
  default     = "primary"
}

variable "kubecost_namespace" {
  description = "Kubernetes namespace where Kubecost is deployed"
  type        = string
  default     = "kubecost"
}

variable "service_account_name" {
  description = "Kubernetes service account name for Kubecost"
  type        = string
  default     = "kubecost-cost-analyzer"
}

variable "iam_policy_name" {
  description = "Name for the IAM policy"
  type        = string
  default     = "KubecostCostAnalyzerPolicy"
}

variable "iam_role_name" {
  description = "Name for the IAM role (IRSA)"
  type        = string
  default     = "KubecostCostAnalyzerRole"
}

variable "create_irsa_role" {
  description = "Whether to create IAM role for service account (IRSA)"
  type        = bool
  default     = true
}

variable "create_service_account" {
  description = "Whether to create Kubernetes service account"
  type        = bool
  default     = true
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for EKS cluster (required for IRSA)"
  type        = string
  default     = ""
}

variable "use_static_credentials" {
  description = "Use static AWS credentials instead of IRSA (not recommended for production)"
  type        = bool
  default     = false
}

variable "aws_access_key_id" {
  description = "AWS Access Key ID (only if use_static_credentials is true)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key (only if use_static_credentials is true)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "spot_data_region" {
  description = "AWS region for spot instance data feed"
  type        = string
  default     = ""
}

variable "spot_data_bucket" {
  description = "S3 bucket for spot instance data feed"
  type        = string
  default     = ""
}

variable "spot_data_prefix" {
  description = "S3 prefix for spot instance data feed"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to AWS resources"
  type        = map(string)
  default     = {}
}