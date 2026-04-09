# Kubecost 3.x Agent Terraform Module

This Terraform module deploys a Kubecost 3.x agent to a Kubernetes cluster for SaaS deployments where the primary instance is hosted by IBM.

## Important: Kubecost 3.x Changes

Kubecost 3.0+ introduces significant architectural changes:
- **New Helm Repository**: `https://kubecost.github.io/kubecost/` (changed from `/cost-analyzer/`)
- **New Chart Name**: `kubecost` (changed from `cost-analyzer`)
- **IBM FinOps Agent**: Uses the new `finopsagent` component instead of legacy agent configuration
- **Image Registry**: Images now hosted on `icr.io` (IBM Container Registry) instead of `gcr.io`
- **Federated Storage**: Primary configuration method for SaaS deployments
- **Required Acknowledgment**: Enterprise deployments require `global.acknowledged = true`

## Features

- Deploys Kubecost 3.x agent via Helm chart
- Uses IBM FinOps Agent architecture
- Configures federated storage for IBM-hosted SaaS
- Creates necessary secrets and namespaces
- Supports resource customization
- Includes security best practices
- Atomic deployments with automatic rollback
- Compatible with IBM Container Registry (icr.io)

## Usage

### Basic Example

```hcl
module "kubecost_agent" {
  source = "./terraform/kubecost-agent"

  cluster_name              = "production-us-east-1"
  federated_storage_config  = var.federated_storage_config  # Provided by IBM
  namespace                 = "kubecost"
  chart_version             = "3.1.6"  # Pin to specific 3.x version
}
```

### Advanced Example

```hcl
module "kubecost_agent" {
  source = "./terraform/kubecost-agent"

  # Required parameters
  cluster_name              = "production-us-east-1"
  federated_storage_config  = var.federated_storage_config  # IBM-provided S3 config
  
  # Optional parameters
  namespace        = "kubecost"
  chart_version    = "3.1.6"  # Pin to specific 3.x version
  release_name     = "kubecost-agent"
  create_namespace = true
  
  # Resource configuration
  agent_resources = {
    requests = {
      cpu    = "500m"
      memory = "1Gi"
    }
    limits = {
      cpu    = "2000m"
      memory = "4Gi"
    }
  }
  
  # Node placement
  node_selector = {
    "node-role.kubernetes.io/monitoring" = "true"
  }
  
  tolerations = [
    {
      key      = "monitoring"
      operator = "Equal"
      value    = "true"
      effect   = "NoSchedule"
    }
  ]
  
  # Security
  network_policy_enabled = true
  
  pod_annotations = {
    "prometheus.io/scrape" = "true"
    "prometheus.io/port"   = "9003"
  }
  
  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    Team        = "platform"
  }
}
```

### With Kubernetes Provider Configuration

```hcl
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  # Or use other authentication methods
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

module "kubecost_agent" {
  source = "./terraform/kubecost-agent"

  cluster_name         = "production-cluster"
  kubecost_token       = var.kubecost_token
  kubecost_primary_url = var.kubecost_primary_url
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| kubernetes | ~> 2.23 |
| helm | ~> 2.11 |

## Providers

| Name | Version |
|------|---------|
| kubernetes | ~> 2.23 |
| helm | ~> 2.11 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Unique identifier for this cluster | `string` | n/a | yes |
| federated_storage_config | Federated storage configuration YAML (provided by IBM) | `string` | `""` | yes for SaaS |
| kubecost_token | Legacy token (optional for 3.x) | `string` | `""` | no |
| kubecost_primary_url | Legacy primary URL (optional for 3.x) | `string` | `""` | no |
| namespace | Kubernetes namespace for Kubecost agent | `string` | `"kubecost"` | no |
| create_namespace | Whether to create the namespace | `bool` | `true` | no |
| release_name | Helm release name | `string` | `"kubecost-agent"` | no |
| chart_version | Kubecost 3.x Helm chart version | `string` | `"3.1.6"` | no |
| atomic_deployment | If true, upgrade process rolls back changes made in case of failed upgrade | `bool` | `true` | no |
| agent_resources | Resource requests and limits for the Kubecost agent | `object` | See variables.tf | no |
| network_policy_enabled | Enable network policies for the agent | `bool` | `false` | no |
| node_selector | Node selector for pod assignment | `map(string)` | `{}` | no |
| tolerations | Tolerations for pod assignment | `list(object)` | `[]` | no |
| affinity | Affinity rules for pod assignment | `any` | `{}` | no |
| pod_annotations | Annotations to add to the agent pods | `map(string)` | `{}` | no |
| pod_security_context | Security context for the pod | `any` | See variables.tf | no |
| security_context | Security context for the container | `any` | See variables.tf | no |
| additional_values | Additional Helm values to set (key-value pairs) | `map(string)` | `{}` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | Kubernetes namespace where Kubecost agent is deployed |
| release_name | Helm release name |
| release_version | Deployed Helm chart version |
| release_status | Status of the Helm release |
| cluster_name | Cluster name configured for this agent |
| kubecost_primary_url | Primary Kubecost instance URL |
| agent_metadata | Metadata about the agent deployment |

## Deployment Steps

1. **Configure providers**:
   ```hcl
   provider "kubernetes" {
     config_path = "~/.kube/config"
   }
   
   provider "helm" {
     kubernetes {
       config_path = "~/.kube/config"
     }
   }
   ```

2. **Create terraform.tfvars**:
   ```hcl
   cluster_name              = "my-cluster"
   federated_storage_config  = <<-EOT
     type: S3
     config:
       bucket: ibm-kubecost-saas-data
       endpoint: s3.amazonaws.com
       region: us-east-1
       access_key: YOUR_ACCESS_KEY
       secret_key: YOUR_SECRET_KEY
   EOT
   ```
   
   **Note**: The federated storage configuration is provided by IBM for SaaS deployments.

3. **Initialize and apply**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Verification

After deployment, verify the agent is running:

```bash
# Check pods
kubectl get pods -n kubecost

# Check logs
kubectl logs -n kubecost -l app.kubernetes.io/name=cost-analyzer

# Verify connection
kubectl logs -n kubecost -l app.kubernetes.io/name=cost-analyzer | grep "connected"
```

## Updating the Agent

To update to a new version:

1. Update the `chart_version` variable
2. Run `terraform plan` to review changes
3. Run `terraform apply` to apply the update

The module uses atomic deployments by default, which will automatically roll back if the update fails.

## Troubleshooting

### Agent Not Starting

Check pod events:
```bash
kubectl describe pod -n kubecost -l app.kubernetes.io/name=finops-agent
```

### Federated Storage Issues

Verify storage configuration:
```bash
kubectl get configmap -n kubecost -o yaml | grep -A 20 "federatedStorage"
```

Check S3 connectivity:
```bash
kubectl logs -n kubecost -l app.kubernetes.io/name=finops-agent | grep -i "s3\|storage\|bucket"
```

### Resource Issues

Adjust resource limits in the module configuration:
```hcl
agent_resources = {
  requests = {
    cpu    = "1000m"
    memory = "2Gi"
  }
  limits = {
    cpu    = "2000m"
    memory = "4Gi"
  }
}
```

## Security Considerations

- Federated storage credentials are marked as sensitive and won't appear in logs
- Images are pulled from IBM Container Registry (icr.io) for enhanced security
- Default security contexts follow least-privilege principles
- Network policies can be enabled for additional isolation
- Containers run as non-root by default
- Supports IBM Cloud IAM for S3 access (IRSA/Workload Identity)

## Migration from 2.x to 3.x

If migrating from Kubecost 2.x:

1. **Backup existing data** before upgrading
2. **Update Helm repository**: Change from `/cost-analyzer/` to `/kubecost/`
3. **Update chart name**: Change from `cost-analyzer` to `kubecost`
4. **Configure federated storage**: Obtain configuration from IBM
5. **Remove legacy settings**: `kubecostToken` and `kubecostPrimaryCluster` are replaced by federated storage
6. **Update image references**: Images now use `icr.io` registry
7. **Test in non-production** environment first

See the [Kubecost 3.x Migration Guide](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x) for detailed instructions.

## License

[Your License Here]