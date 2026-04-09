# Kubecost Azure Cloud Integration

This Terraform module configures Azure cloud integration for Kubecost, enabling accurate cost allocation and cloud cost visibility for SaaS deployments.

## Features

- Azure AD Application and Service Principal creation
- Automatic role assignments (Reader, Cost Management Reader)
- Optional Storage Account access for cost exports
- Kubernetes secret creation for Azure credentials
- Integration configuration via ConfigMap
- Support for Azure Government, China, and German clouds

## Prerequisites

1. **Azure Subscription**: Active Azure subscription with appropriate permissions
2. **Azure AD Permissions**: Ability to create applications and service principals
3. **Cost Management**: Access to Azure Cost Management
4. **Storage Account** (Optional): For cost export data
5. **Kubernetes Cluster**: Running cluster with Kubecost deployed

## Usage

### Basic Example

```hcl
module "kubecost_azure_integration" {
  source = "./terraform/cloud-integrations/azure"

  # Azure Configuration
  tenant_id          = "12345678-1234-1234-1234-123456789012"
  application_name   = "kubecost-cost-analyzer"
  
  # Kubernetes Configuration
  kubecost_namespace = "kubecost"

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### With Cost Export Storage

```hcl
module "kubecost_azure_integration" {
  source = "./terraform/cloud-integrations/azure"

  tenant_id          = "12345678-1234-1234-1234-123456789012"
  application_name   = "kubecost-cost-analyzer"
  kubecost_namespace = "kubecost"

  # Storage Account for cost exports
  storage_account_id     = azurerm_storage_account.kubecost.id
  storage_account_name   = "kubecostexports"
  storage_container_name = "cost-exports"
  storage_access_key     = azurerm_storage_account.kubecost.primary_access_key
  container_path         = "exports/"
}
```

### With Rate Card Configuration

```hcl
module "kubecost_azure_integration" {
  source = "./terraform/cloud-integrations/azure"

  tenant_id          = "12345678-1234-1234-1234-123456789012"
  kubecost_namespace = "kubecost"

  # Rate Card API configuration
  configure_rate_card = true
  offer_durable_id    = "MS-AZR-0003P"  # Pay-As-You-Go
  currency            = "USD"
  region              = "US"
}
```

### Azure Government Cloud

```hcl
module "kubecost_azure_integration" {
  source = "./terraform/cloud-integrations/azure"

  tenant_id          = "12345678-1234-1234-1234-123456789012"
  kubecost_namespace = "kubecost"
  azure_cloud        = "AzureUSGovernmentCloud"
}
```

## Complete Setup Guide

### Step 1: Prepare Azure Environment

Ensure you have the necessary permissions:
```bash
# Check your Azure account
az account show

# Verify you can create service principals
az ad sp list --show-mine
```

### Step 2: Set Up Cost Export (Recommended)

1. Create a storage account:
   ```bash
   az storage account create \
     --name kubecostexports \
     --resource-group <resource-group> \
     --location <location> \
     --sku Standard_LRS
   ```

2. Create a container:
   ```bash
   az storage container create \
     --name cost-exports \
     --account-name kubecostexports
   ```

### Step 3: Deploy with Terraform

```bash
cd terraform/cloud-integrations/azure

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
tenant_id              = "12345678-1234-1234-1234-123456789012"
storage_account_name   = "kubecostexports"
storage_container_name = "cost-exports"
EOF

# Initialize and apply
terraform init
terraform plan
terraform apply
```

### Step 4: Configure Cost Export in Azure Portal

1. Go to **Cost Management + Billing** → **Exports**
2. Click **+ Add**
3. Configure export:
   ```
   Export name: kubecost-daily-export
   Export type: Daily export of month-to-date costs
   Start date: Today
   Storage account: kubecostexports
   Container: cost-exports
   Directory: exports/
   File format: CSV
   ```

### Step 5: Update Kubecost Helm Values

```yaml
# Reference the created secret
kubecostProductConfigs:
  azureStorageSecretName: kubecost-azure-credentials
  azureSubscriptionID: <from-terraform-output>
  azureTenantID: <from-terraform-output>
  azureClientID: <from-terraform-output>
```

### Step 6: Verify Integration

```bash
# Check secret
kubectl get secret kubecost-azure-credentials -n kubecost -o yaml

# Check Kubecost logs
kubectl logs -n kubecost -l app=cost-analyzer | grep -i azure

# Verify in Kubecost UI
# Navigate to Settings → Cloud Integrations → Azure
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | ~> 3.0 |
| azuread | ~> 2.0 |
| kubernetes | ~> 2.23 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 3.0 |
| azuread | ~> 2.0 |
| kubernetes | ~> 2.23 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| tenant_id | Azure Tenant ID | `string` | n/a | yes |
| application_name | Name for the Azure AD application | `string` | `"kubecost-cost-analyzer"` | no |
| client_secret_expiration | Client secret expiration duration | `string` | `"8760h"` | no |
| kubecost_namespace | Kubernetes namespace where Kubecost is deployed | `string` | `"kubecost"` | no |
| storage_account_id | Azure Storage Account resource ID for cost export data | `string` | `""` | no |
| storage_account_name | Azure Storage Account name for cost export data | `string` | `""` | no |
| storage_container_name | Azure Storage Container name for cost export data | `string` | `""` | no |
| storage_access_key | Azure Storage Account access key | `string` | `""` | no |
| container_path | Path within the storage container for cost export data | `string` | `""` | no |
| azure_cloud | Azure cloud environment | `string` | `"AzurePublicCloud"` | no |
| offer_durable_id | Azure Offer Durable ID | `string` | `"MS-AZR-0003P"` | no |
| configure_rate_card | Whether to configure Azure Rate Card API access | `bool` | `false` | no |
| currency | Currency code for pricing | `string` | `"USD"` | no |
| region | Azure region for pricing | `string` | `"US"` | no |
| tags | Tags to apply to Azure resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| application_id | Azure AD Application (Client) ID |
| application_object_id | Azure AD Application Object ID |
| service_principal_id | Service Principal Object ID |
| tenant_id | Azure Tenant ID |
| subscription_id | Azure Subscription ID |
| client_secret | Azure AD Application Client Secret (sensitive) |
| kubernetes_secret_name | Name of the Kubernetes secret containing Azure credentials |
| integration_config | Azure integration configuration details |
| next_steps | Next steps for completing the integration |

## Azure Permissions

The module creates a Service Principal with the following role assignments:

### Reader Role
- Read access to all resources in the subscription
- Required for resource metadata and tagging

### Cost Management Reader Role
- Read access to cost data
- View cost analysis and budgets
- Access to cost exports

### Storage Blob Data Reader (Optional)
- Read access to cost export files in storage account
- Only assigned if `storage_account_id` is provided

## Common Azure Offer IDs

| Offer Type | Offer Durable ID |
|------------|------------------|
| Pay-As-You-Go | MS-AZR-0003P |
| Enterprise Agreement | MS-AZR-0017P |
| Dev/Test Pay-As-You-Go | MS-AZR-0023P |
| Visual Studio Enterprise | MS-AZR-0063P |
| CSP | MS-AZR-0145P |

## Troubleshooting

### Service Principal Creation Fails

1. Verify Azure AD permissions:
   ```bash
   az ad sp create-for-rbac --name "test-sp" --skip-assignment
   ```

2. Check if you have Application Administrator role:
   ```bash
   az role assignment list --assignee <your-user-id>
   ```

### No Cost Data Appearing

1. Verify cost export is running:
   ```bash
   az costmanagement export list --scope "/subscriptions/<subscription-id>"
   ```

2. Check storage account access:
   ```bash
   az storage blob list \
     --account-name kubecostexports \
     --container-name cost-exports
   ```

3. Review Kubecost logs:
   ```bash
   kubectl logs -n kubecost -l app=cost-analyzer | grep -i "azure\|error"
   ```

### Permission Errors

1. Verify role assignments:
   ```bash
   az role assignment list --assignee <service-principal-id>
   ```

2. Test service principal authentication:
   ```bash
   az login --service-principal \
     --username <client-id> \
     --password <client-secret> \
     --tenant <tenant-id>
   ```

### Client Secret Expiration

The client secret expires after the configured duration (default: 1 year). To rotate:

```bash
# Create new secret
az ad sp credential reset --id <service-principal-id>

# Update Kubernetes secret
kubectl create secret generic kubecost-azure-credentials \
  --from-literal=AZURE_CLIENT_SECRET=<new-secret> \
  --namespace kubecost \
  --dry-run=client -o yaml | kubectl apply -f -
```

## Security Best Practices

1. **Rotate Secrets**: Set up automated secret rotation before expiration
2. **Least Privilege**: The module follows least privilege with minimal required roles
3. **Audit Logging**: Enable Azure Activity Log for service principal actions
4. **Conditional Access**: Consider applying conditional access policies to the service principal
5. **Secret Management**: Store client secret securely (e.g., Azure Key Vault)

## Cost Considerations

- **Cost Export Storage**: S3 storage costs for exports (~$1-5/month)
- **API Calls**: Minimal cost for Cost Management API calls
- **Service Principal**: No additional cost

## Multi-Subscription Support

To monitor multiple subscriptions, deploy this module once per subscription:

```hcl
module "kubecost_azure_sub1" {
  source = "./terraform/cloud-integrations/azure"
  
  tenant_id          = var.tenant_id
  kubecost_namespace = "kubecost"
  
  providers = {
    azurerm = azurerm.subscription1
  }
}

module "kubecost_azure_sub2" {
  source = "./terraform/cloud-integrations/azure"
  
  tenant_id          = var.tenant_id
  kubecost_namespace = "kubecost"
  
  providers = {
    azurerm = azurerm.subscription2
  }
}
```

## License

[Your License Here]