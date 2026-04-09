# Kubecost AWS Cloud Integration

This Terraform module configures AWS cloud integration for Kubecost, enabling accurate cost allocation and cloud cost visibility for SaaS deployments.

## Features

- IAM policy for accessing Cost and Usage Reports (CUR)
- IAM policy for AWS Pricing API access
- IRSA (IAM Roles for Service Accounts) support for EKS
- Alternative static credentials support
- Kubernetes service account creation
- Integration configuration via ConfigMap
- Optional spot instance data feed integration

## Prerequisites

1. **AWS Cost and Usage Reports (CUR)**:
   - Enable CUR in AWS Billing Console
   - Configure hourly granularity with resource IDs
   - Enable Athena integration
   - Store reports in S3 bucket

2. **EKS Cluster with OIDC Provider** (for IRSA):
   - OIDC provider must be configured
   - Note the OIDC provider ARN

3. **Athena Setup**:
   - S3 bucket for Athena query results
   - Athena database and table for CUR data

## Usage

### Basic Example with IRSA (Recommended)

```hcl
module "kubecost_aws_integration" {
  source = "./terraform/cloud-integrations/aws"

  # AWS Configuration
  aws_account_id      = "123456789012"
  cur_bucket_name     = "my-cur-bucket"
  athena_bucket_name  = "my-athena-results-bucket"
  athena_region       = "us-east-1"
  athena_database     = "athenacurcfn_kubecost"
  athena_table        = "kubecost"

  # IRSA Configuration
  create_irsa_role    = true
  oidc_provider_arn   = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
  
  # Kubernetes Configuration
  kubecost_namespace     = "kubecost"
  service_account_name   = "kubecost-cost-analyzer"
  create_service_account = true

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### With Static Credentials (Not Recommended for Production)

```hcl
module "kubecost_aws_integration" {
  source = "./terraform/cloud-integrations/aws"

  aws_account_id      = "123456789012"
  cur_bucket_name     = "my-cur-bucket"
  athena_bucket_name  = "my-athena-results-bucket"

  # Use static credentials
  use_static_credentials = true
  aws_access_key_id      = var.aws_access_key_id
  aws_secret_access_key  = var.aws_secret_access_key
  
  # Disable IRSA
  create_irsa_role = false

  kubecost_namespace = "kubecost"
}
```

### With Spot Instance Data Feed

```hcl
module "kubecost_aws_integration" {
  source = "./terraform/cloud-integrations/aws"

  aws_account_id      = "123456789012"
  cur_bucket_name     = "my-cur-bucket"
  athena_bucket_name  = "my-athena-results-bucket"
  oidc_provider_arn   = var.oidc_provider_arn

  # Spot instance data feed
  spot_data_region = "us-east-1"
  spot_data_bucket = "my-spot-data-bucket"
  spot_data_prefix = "spot-data/"

  kubecost_namespace = "kubecost"
}
```

## Complete Setup Guide

### Step 1: Enable Cost and Usage Reports

1. Go to AWS Billing Console → Cost & Usage Reports
2. Create a new report:
   ```
   Report name: kubecost-cur
   Time granularity: Hourly
   Include resource IDs: Yes
   Enable report data integration: Amazon Athena
   S3 bucket: <your-cur-bucket>
   Report path prefix: cur/
   Compression: GZIP
   ```

### Step 2: Set Up Athena

1. Create S3 bucket for Athena results:
   ```bash
   aws s3 mb s3://my-athena-results-bucket
   ```

2. Verify Athena database and table are created (automatic with CUR Athena integration)

### Step 3: Get OIDC Provider ARN (for IRSA)

```bash
# Get cluster OIDC provider
aws eks describe-cluster --name <cluster-name> --query "cluster.identity.oidc.issuer" --output text

# Get OIDC provider ARN
aws iam list-open-id-connect-providers | grep <oidc-id>
```

### Step 4: Deploy with Terraform

```bash
cd terraform/cloud-integrations/aws

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
aws_account_id     = "123456789012"
cur_bucket_name    = "my-cur-bucket"
athena_bucket_name = "my-athena-results-bucket"
oidc_provider_arn  = "arn:aws:iam::123456789012:oidc-provider/..."
EOF

# Initialize and apply
terraform init
terraform plan
terraform apply
```

### Step 5: Update Kubecost Helm Values

After applying this module, update your Kubecost Helm deployment:

```yaml
# For IRSA
serviceAccount:
  create: false  # We created it via Terraform
  name: kubecost-cost-analyzer

# The service account is already annotated with the IAM role
```

### Step 6: Verify Integration

```bash
# Check service account annotation
kubectl get sa kubecost-cost-analyzer -n kubecost -o yaml

# Check Kubecost logs
kubectl logs -n kubecost -l app=cost-analyzer | grep -i aws

# Verify in Kubecost UI
# Navigate to Settings → Cloud Integrations → AWS
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |
| kubernetes | ~> 2.23 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |
| kubernetes | ~> 2.23 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_account_id | AWS Account ID | `string` | n/a | yes |
| cur_bucket_name | S3 bucket name containing Cost and Usage Reports | `string` | n/a | yes |
| athena_bucket_name | S3 bucket name for Athena query results | `string` | n/a | yes |
| athena_region | AWS region for Athena | `string` | `"us-east-1"` | no |
| athena_database | Athena database name for CUR data | `string` | `"athenacurcfn_kubecost"` | no |
| athena_table | Athena table name for CUR data | `string` | `"kubecost"` | no |
| athena_workgroup | Athena workgroup name | `string` | `"primary"` | no |
| kubecost_namespace | Kubernetes namespace where Kubecost is deployed | `string` | `"kubecost"` | no |
| service_account_name | Kubernetes service account name for Kubecost | `string` | `"kubecost-cost-analyzer"` | no |
| iam_policy_name | Name for the IAM policy | `string` | `"KubecostCostAnalyzerPolicy"` | no |
| iam_role_name | Name for the IAM role (IRSA) | `string` | `"KubecostCostAnalyzerRole"` | no |
| create_irsa_role | Whether to create IAM role for service account (IRSA) | `bool` | `true` | no |
| create_service_account | Whether to create Kubernetes service account | `bool` | `true` | no |
| oidc_provider_arn | ARN of the OIDC provider for EKS cluster (required for IRSA) | `string` | `""` | no |
| use_static_credentials | Use static AWS credentials instead of IRSA | `bool` | `false` | no |
| aws_access_key_id | AWS Access Key ID (only if use_static_credentials is true) | `string` | `""` | no |
| aws_secret_access_key | AWS Secret Access Key (only if use_static_credentials is true) | `string` | `""` | no |
| spot_data_region | AWS region for spot instance data feed | `string` | `""` | no |
| spot_data_bucket | S3 bucket for spot instance data feed | `string` | `""` | no |
| spot_data_prefix | S3 prefix for spot instance data feed | `string` | `""` | no |
| tags | Tags to apply to AWS resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| iam_policy_arn | ARN of the IAM policy for Kubecost |
| iam_policy_name | Name of the IAM policy for Kubecost |
| iam_role_arn | ARN of the IAM role for Kubecost (if IRSA is enabled) |
| iam_role_name | Name of the IAM role for Kubecost (if IRSA is enabled) |
| service_account_name | Name of the Kubernetes service account |
| service_account_namespace | Namespace of the Kubernetes service account |
| integration_config | AWS integration configuration details |
| next_steps | Next steps for completing the integration |

## IAM Permissions

The module creates an IAM policy with the following permissions:

### S3 Access (CUR Data)
- `s3:GetObject` - Read CUR files from S3
- `s3:ListBucket` - List CUR bucket contents

### Cost and Usage Reports
- `cur:DescribeReportDefinitions` - Get CUR configuration details

### Pricing API
- `pricing:GetProducts` - Get AWS service pricing information
- `pricing:DescribeServices` - List available AWS services for pricing

## Troubleshooting

### IRSA Not Working

1. Verify OIDC provider is configured:
   ```bash
   aws eks describe-cluster --name <cluster-name> --query "cluster.identity.oidc.issuer"
   ```

2. Check service account annotation:
   ```bash
   kubectl get sa kubecost-cost-analyzer -n kubecost -o yaml
   ```

3. Verify IAM role trust policy:
   ```bash
   aws iam get-role --role-name KubecostCostAnalyzerRole
   ```

### No Cost Data Appearing

1. Verify CUR is being generated:
   ```bash
   aws s3 ls s3://<cur-bucket>/cur/
   ```

2. Check Athena table:
   ```sql
   SELECT * FROM athenacurcfn_kubecost.kubecost LIMIT 10;
   ```

3. Review Kubecost logs:
   ```bash
   kubectl logs -n kubecost -l app=cost-analyzer | grep -i "aws\|athena\|error"
   ```

### Permission Errors

1. Test IAM permissions:
   ```bash
   aws sts assume-role --role-arn <role-arn> --role-session-name test
   ```

2. Verify policy attachment:
   ```bash
   aws iam list-attached-role-policies --role-name KubecostCostAnalyzerRole
   ```

## Security Best Practices

1. **Use IRSA**: Always prefer IRSA over static credentials for better security
2. **Least Privilege**: The IAM policy follows least privilege principles with only required permissions
3. **Audit Access**: Enable CloudTrail for IAM and S3 access logging
4. **Rotate Credentials**: If using static credentials, rotate regularly (though IRSA is recommended)
5. **Restrict S3 Access**: Use bucket policies to restrict access to CUR data

## Cost Considerations

- **CUR Storage**: S3 storage costs for Cost and Usage Reports (~$5-20/month depending on usage)
- **Athena Queries**: Charged per TB of data scanned (~$5/TB)
- **API Calls**: Minimal cost for Pricing API calls (typically < $1/month)

## License

[Your License Here]