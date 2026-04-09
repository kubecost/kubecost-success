# Kubecost GCP Cloud Integration

This Terraform module configures GCP cloud integration for Kubecost, enabling accurate cost allocation and cloud cost visibility for SaaS deployments.

## Features

- GCP Service Account creation with appropriate IAM roles
- BigQuery billing export integration
- Support for GKE Workload Identity (recommended)
- Alternative service account key authentication
- Kubernetes secret creation for GCP credentials
- Integration configuration via ConfigMap
- Optional GCS bucket access for billing exports

## Prerequisites

1. **GCP Project**: Active GCP project with billing enabled
2. **BigQuery Billing Export**: Configured billing export to BigQuery
3. **IAM Permissions**: Ability to create service accounts and assign roles
4. **Kubernetes Cluster**: Running cluster with Kubecost deployed
5. **GKE Workload Identity** (Optional but recommended): Enabled on GKE cluster

## Usage

### Basic Example with Service Account Key

```hcl
module "kubecost_gcp_integration" {
  source = "./terraform/cloud-integrations/gcp"

  # GCP Configuration
  project_id         = "my-gcp-project"
  billing_dataset_id = "billing_export"
  billing_table_id   = "gcp_billing_export_v1"
  
  # Kubernetes Configuration
  kubecost_namespace = "kubecost"
  
  # Use service account key (default)
  enable_workload_identity = false
  create_kubernetes_secret = true
}
```

### With GKE Workload Identity (Recommended)

```hcl
module "kubecost_gcp_integration" {
  source = "./terraform/cloud-integrations/gcp"

  project_id         = "my-gcp-project"
  billing_dataset_id = "billing_export"
  kubecost_namespace = "kubecost"
  
  # Enable Workload Identity
  enable_workload_identity            = true
  create_kubernetes_service_account   = true
  kubernetes_service_account          = "kubecost-cost-analyzer"
  
  # Don't create secret when using Workload Identity
  create_kubernetes_secret = false
}
```

### With GCS Bucket Access

```hcl
module "kubecost_gcp_integration" {
  source = "./terraform/cloud-integrations/gcp"

  project_id              = "my-gcp-project"
  billing_dataset_id      = "billing_export"
  billing_export_bucket   = "my-billing-export-bucket"
  kubecost_namespace      = "kubecost"
}
```

### Custom Service Account Name

```hcl
module "kubecost_gcp_integration" {
  source = "./terraform/cloud-integrations/gcp"

  project_id                    = "my-gcp-project"
  billing_dataset_id            = "billing_export"
  service_account_id            = "kubecost-prod"
  service_account_display_name  = "Kubecost Production"
  kubecost_namespace            = "kubecost"
}
```

## Complete Setup Guide

### Step 1: Enable BigQuery Billing Export

1. Go to **Billing** → **Billing Export** in GCP Console
2. Click **Edit Settings** for BigQuery export
3. Configure:
   ```
   Project: <your-project-id>
   Dataset: billing_export (or your preferred name)
   ```
4. Click **Save**

Note: It can take 24-48 hours for billing data to start appearing in BigQuery.

### Step 2: Enable Workload Identity (GKE Only, Recommended)

If using GKE, enable Workload Identity on your cluster:

```bash
# Enable on existing cluster
gcloud container clusters update <cluster-name> \
  --workload-pool=<project-id>.svc.id.goog \
  --region=<region>

# Enable on node pool
gcloud container node-pools update <node-pool-name> \
  --cluster=<cluster-name> \
  --workload-metadata=GKE_METADATA \
  --region=<region>
```

### Step 3: Deploy with Terraform

```bash
cd terraform/cloud-integrations/gcp

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
project_id                  = "my-gcp-project"
billing_dataset_id          = "billing_export"
enable_workload_identity    = true
create_kubernetes_secret    = false
EOF

# Initialize and apply
terraform init
terraform plan
terraform apply
```

### Step 4: Update Kubecost Helm Values

#### For Workload Identity:

```yaml
serviceAccount:
  create: false  # We created it via Terraform
  name: kubecost-cost-analyzer

kubecostProductConfigs:
  projectID: my-gcp-project
  bigQueryBillingDataDataset: billing_export
```

#### For Service Account Key:

```yaml
kubecostProductConfigs:
  projectID: my-gcp-project
  gcpSecretName: kubecost-gcp-credentials
  bigQueryBillingDataDataset: billing_export
```

### Step 5: Verify Integration

```bash
# Check secret (if using service account key)
kubectl get secret kubecost-gcp-credentials -n kubecost

# Check service account (if using Workload Identity)
kubectl get sa kubecost-cost-analyzer -n kubecost -o yaml

# Check Kubecost logs
kubectl logs -n kubecost -l app=cost-analyzer | grep -i gcp

# Verify in Kubecost UI
# Navigate to Settings → Cloud Integrations → GCP
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| google | ~> 5.0 |
| kubernetes | ~> 2.23 |

## Providers

| Name | Version |
|------|---------|
| google | ~> 5.0 |
| kubernetes | ~> 2.23 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | GCP Project ID | `string` | n/a | yes |
| billing_dataset_id | BigQuery dataset ID containing billing export data | `string` | n/a | yes |
| service_account_id | Service account ID (must be 6-30 characters) | `string` | `"kubecost-cost-analyzer"` | no |
| service_account_display_name | Display name for the service account | `string` | `"Kubecost Cost Analyzer"` | no |
| billing_table_id | BigQuery table ID containing billing export data | `string` | `"gcp_billing_export_v1"` | no |
| billing_export_bucket | GCS bucket name for billing export | `string` | `""` | no |
| kubecost_namespace | Kubernetes namespace where Kubecost is deployed | `string` | `"kubecost"` | no |
| kubernetes_service_account | Kubernetes service account name for Kubecost | `string` | `"kubecost-cost-analyzer"` | no |
| enable_workload_identity | Enable GKE Workload Identity | `bool` | `false` | no |
| create_kubernetes_secret | Create Kubernetes secret with service account key | `bool` | `true` | no |
| create_kubernetes_service_account | Create Kubernetes service account with Workload Identity annotation | `bool` | `false` | no |
| tags | Labels to apply to GCP resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| service_account_email | Email address of the created service account |
| service_account_id | ID of the created service account |
| service_account_unique_id | Unique ID of the created service account |
| service_account_key_id | ID of the service account key |
| service_account_private_key | Private key for the service account (sensitive) |
| project_id | GCP Project ID |
| billing_dataset_id | BigQuery dataset ID for billing data |
| kubernetes_secret_name | Name of the Kubernetes secret containing GCP credentials |
| kubernetes_service_account_name | Name of the Kubernetes service account |
| workload_identity_enabled | Whether Workload Identity is enabled |
| integration_config | GCP integration configuration details |
| next_steps | Next steps for completing the integration |

## IAM Permissions

The module creates a service account with the following IAM roles:

### BigQuery Data Viewer
- Read access to BigQuery datasets and tables
- Required to query billing export data

### BigQuery Job User
- Ability to run BigQuery queries
- Required to execute cost analysis queries

### Compute Viewer
- Read access to Compute Engine resources
- Required for accurate pricing and resource metadata

### Storage Object Viewer (Optional)
- Read access to GCS bucket
- Only assigned if `billing_export_bucket` is provided

## Workload Identity vs Service Account Key

### Workload Identity (Recommended)

**Pros:**
- No service account keys to manage
- Automatic credential rotation
- Better security posture
- Native GKE integration

**Cons:**
- Only available on GKE
- Requires cluster configuration

**Use when:** Running on GKE clusters

### Service Account Key

**Pros:**
- Works on any Kubernetes cluster
- Simpler initial setup

**Cons:**
- Manual key rotation required
- Keys stored in cluster secrets
- Higher security risk

**Use when:** Running on non-GKE clusters (EKS, AKS, on-prem)

## Troubleshooting

### No Billing Data Appearing

1. Verify BigQuery export is enabled:
   ```bash
   gcloud billing accounts list
   gcloud billing accounts describe <billing-account-id>
   ```

2. Check if data exists in BigQuery:
   ```bash
   bq query --use_legacy_sql=false \
     'SELECT COUNT(*) FROM `<project-id>.<dataset-id>.<table-id>`'
   ```

3. Wait 24-48 hours for initial data population

### Workload Identity Not Working

1. Verify Workload Identity is enabled on cluster:
   ```bash
   gcloud container clusters describe <cluster-name> \
     --region=<region> \
     --format="value(workloadIdentityConfig.workloadPool)"
   ```

2. Check service account annotation:
   ```bash
   kubectl get sa kubecost-cost-analyzer -n kubecost -o yaml
   ```

3. Verify IAM binding:
   ```bash
   gcloud iam service-accounts get-iam-policy \
     <service-account-email>
   ```

### Permission Errors

1. Verify service account roles:
   ```bash
   gcloud projects get-iam-policy <project-id> \
     --flatten="bindings[].members" \
     --filter="bindings.members:serviceAccount:<service-account-email>"
   ```

2. Test BigQuery access:
   ```bash
   bq query --use_legacy_sql=false \
     --service_account_credential_file=key.json \
     'SELECT 1'
   ```

### Service Account Key Rotation

To rotate the service account key:

```bash
# Create new key
gcloud iam service-accounts keys create new-key.json \
  --iam-account=<service-account-email>

# Update Kubernetes secret
kubectl create secret generic kubecost-gcp-credentials \
  --from-file=key.json=new-key.json \
  --namespace kubecost \
  --dry-run=client -o yaml | kubectl apply -f -

# Delete old key
gcloud iam service-accounts keys delete <old-key-id> \
  --iam-account=<service-account-email>
```

## Security Best Practices

1. **Use Workload Identity**: Prefer Workload Identity over service account keys when on GKE
2. **Rotate Keys**: If using service account keys, rotate them regularly (every 90 days)
3. **Least Privilege**: The module follows least privilege with minimal required roles
4. **Audit Logging**: Enable Cloud Audit Logs for service account activity
5. **Key Management**: Never commit service account keys to version control

## Cost Considerations

- **BigQuery Storage**: Minimal cost for billing export data (~$0.02/GB/month)
- **BigQuery Queries**: Charged per TB scanned (~$5/TB)
- **Service Account**: No additional cost
- **API Calls**: Minimal cost for Compute Engine API calls

## Multi-Project Support

To monitor multiple GCP projects, deploy this module once per project:

```hcl
module "kubecost_gcp_project1" {
  source = "./terraform/cloud-integrations/gcp"
  
  project_id         = "project-1"
  billing_dataset_id = "billing_export"
  kubecost_namespace = "kubecost"
  
  providers = {
    google = google.project1
  }
}

module "kubecost_gcp_project2" {
  source = "./terraform/cloud-integrations/gcp"
  
  project_id         = "project-2"
  billing_dataset_id = "billing_export"
  kubecost_namespace = "kubecost"
  
  providers = {
    google = google.project2
  }
}
```

## BigQuery Dataset Naming

Common BigQuery billing export dataset names:
- `billing_export` (default)
- `cloud_costs`
- `gcp_billing_export`

The table name is typically `gcp_billing_export_v1_<BILLING_ACCOUNT_ID>`.

## License

[Your License Here]