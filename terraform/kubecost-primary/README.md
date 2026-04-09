# Kubecost 3.x Primary Cluster Terraform Module

**For Kubecost 3.x+ (Latest: 3.1.6)**

## ⚠️ Important: Kubecost 3.x Changes

This module has been updated for Kubecost 3.x:
- **New Helm Repository**: `https://kubecost.github.io/kubecost/`
- **New Chart Name**: `kubecost` (was `cost-analyzer`)
- **Image Registry**: `icr.io` (IBM Container Registry)
- **Architecture**: Uses aggregator, frontend, and finopsagent components

This Terraform module deploys a Kubecost primary instance for self-hosted deployments. Use this for the main Kubecost cluster that will aggregate data from agents in a multi-cluster environment.

## Deployment Models

### SaaS vs Self-Hosted

| Feature | SaaS (IBM-hosted) | Self-Hosted (This Module) |
|---------|-------------------|----------------------------|
| Primary Instance | Hosted by IBM | You deploy and manage |
| Agents | You deploy | You deploy |
| Storage | IBM-managed | Your infrastructure |
| Federation Storage | IBM S3 or yours | Your S3 bucket |
| Maintenance | IBM handles | You handle |

**Use this module when**: You want full control over your Kubecost deployment and data.

**Use SaaS instead when**: You prefer IBM to manage the primary instance (use `terraform/kubecost-agent/` only).

## Features

- Full Kubecost 3.x+ primary instance deployment
- Optional federation for multi-cluster deployments
- Persistent storage configuration
- Ingress/LoadBalancer support
- S3 integration for federated storage

## Prerequisites

- Kubernetes cluster 1.20+
- Helm 3.x
- Storage provisioner (for PVC)
- Ingress controller (if using ingress)
- S3-compatible storage (if using federation)

## Usage

### Basic Single-Cluster Deployment

```hcl
module "kubecost_primary" {
  source = "./terraform/kubecost-primary"

  cluster_name = "production-primary"
  namespace    = "kubecost"
  
  # Ingress configuration
  ingress_enabled    = true
  ingress_class_name = "nginx"
  ingress_hosts      = ["kubecost.example.com"]
  
  # Storage
  storage_size = "50Gi"
}
```

### Multi-Cluster with Federation

```hcl
module "kubecost_primary" {
  source = "./terraform/kubecost-primary"

  cluster_name = "production-primary"
  namespace    = "kubecost"
  
  # Enable federation
  enable_federation      = true
  federation_s3_bucket   = "my-kubecost-federation"
  federation_s3_region   = "us-east-1"
  federation_s3_prefix   = "kubecost-data"
  
  # S3 credentials (or use IRSA/Workload Identity)
  federation_s3_access_key = var.aws_access_key
  federation_s3_secret_key = var.aws_secret_key
  
  # Ingress for agent connectivity
  ingress_enabled    = true
  ingress_hosts      = ["kubecost.example.com"]
  
  # Larger storage for primary
  storage_size = "100Gi"
}
```

### With LoadBalancer

```hcl
module "kubecost_primary" {
  source = "./terraform/kubecost-primary"

  cluster_name = "production-primary"
  
  # Use LoadBalancer instead of Ingress
  ingress_enabled = false
  service_type    = "LoadBalancer"
  service_annotations = {
    "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
  }
}
```

### With Custom Storage Class

```hcl
module "kubecost_primary" {
  source = "./terraform/kubecost-primary"

  cluster_name = "production-primary"
  
  # Create custom storage class
  create_storage_class    = true
  storage_class_name      = "kubecost-ssd"
  storage_provisioner     = "kubernetes.io/aws-ebs"
  storage_class_parameters = {
    type = "gp3"
    iops = "3000"
  }
  
  storage_size = "100Gi"
}
```

## Complete Setup Guide

### Step 1: Prepare Infrastructure

```bash
# Ensure you have:
# - Kubernetes cluster with storage provisioner
# - Ingress controller (nginx, traefik, etc.)
# - S3 bucket (if using federation)
```

### Step 2: Configure Terraform

```bash
cd terraform/kubecost-primary

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
cluster_name = "production-primary"
namespace    = "kubecost"

# Ingress
ingress_enabled    = true
ingress_class_name = "nginx"
ingress_hosts      = ["kubecost.example.com"]

# Federation (optional)
enable_federation      = true
federation_s3_bucket   = "my-kubecost-data"
federation_s3_region   = "us-east-1"

# Storage
storage_size = "100Gi"
EOF
```

### Step 3: Deploy

```bash
terraform init
terraform plan
terraform apply
```

### Step 4: Access Kubecost

```bash
# If using ingress
open https://kubecost.example.com

# If using port-forward
kubectl port-forward -n kubecost svc/kubecost-primary-cost-analyzer 9090:9090
open http://localhost:9090
```

### Step 5: Configure Cloud Integrations

Deploy cloud integration modules:

```bash
# AWS
cd ../cloud-integrations/aws
terraform apply

# Azure
cd ../cloud-integrations/azure
terraform apply

# GCP
cd ../cloud-integrations/gcp
terraform apply
```

### Step 6: Deploy Agents (Multi-Cluster)

For additional clusters, deploy agents:

```bash
cd ../kubecost-agent

# Configure agent to connect to primary
cat > terraform.tfvars <<EOF
cluster_name         = "production-worker-1"
kubecost_token       = "token-from-kubecost-ui"
kubecost_primary_url = "https://kubecost.example.com"
EOF

terraform apply
```

## Federation Setup

### S3 Bucket Configuration

Create an S3 bucket for federation:

```bash
# AWS CLI
aws s3 mb s3://my-kubecost-federation
aws s3api put-bucket-versioning \
  --bucket my-kubecost-federation \
  --versioning-configuration Status=Enabled
```

### IAM Policy for S3 Access

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-kubecost-federation",
        "arn:aws:s3:::my-kubecost-federation/*"
      ]
    }
  ]
}
```

### Using IRSA (Recommended for EKS)

Instead of static credentials, use IRSA:

```hcl
module "kubecost_primary" {
  source = "./terraform/kubecost-primary"

  # ... other config ...
  
  enable_federation = true
  federation_s3_bucket = "my-kubecost-federation"
  
  # Leave credentials empty to use IRSA
  federation_s3_access_key = ""
  federation_s3_secret_key = ""
  
  # Add service account annotation
  pod_annotations = {
    "eks.amazonaws.com/role-arn" = "arn:aws:iam::ACCOUNT:role/kubecost-primary"
  }
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
| cluster_name | Unique identifier for this primary cluster | `string` | n/a | yes |
| namespace | Kubernetes namespace | `string` | `"kubecost"` | no |
| chart_version | Kubecost Helm chart version (3.x+) | `string` | `"3.1.6"` | no |
| enable_federation | Enable federation for multi-cluster | `bool` | `false` | no |
| federation_s3_bucket | S3 bucket for federated storage | `string` | `""` | no |
| federation_s3_region | AWS region for S3 bucket | `string` | `"us-east-1"` | no |
| ingress_enabled | Enable ingress | `bool` | `true` | no |
| ingress_hosts | Ingress hostnames | `list(string)` | `["kubecost.example.com"]` | no |
| service_type | Service type (ClusterIP/LoadBalancer/NodePort) | `string` | `"ClusterIP"` | no |
| storage_size | PVC size | `string` | `"32Gi"` | no |

See [`variables.tf`](variables.tf) for complete list.

## Outputs

| Name | Description |
|------|-------------|
| primary_url | URL for agents to connect |
| namespace | Deployment namespace |
| release_version | Deployed chart version |
| federation_enabled | Whether federation is enabled |
| agent_connection_info | Info needed for agent configuration |

## Architecture

### Single Cluster
```
┌─────────────────────────────┐
│   Kubernetes Cluster        │
│                             │
│  ┌───────────────────────┐  │
│  │  Kubecost Primary     │  │
│  │  - UI                 │  │
│  │  - API                │  │
│  │  - Data Storage       │  │
│  └───────────────────────┘  │
│           │                 │
│           ▼                 │
│  ┌───────────────────────┐  │
│  │  Persistent Volume    │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

### Multi-Cluster with Federation
```
┌─────────────────────────────┐
│   Primary Cluster           │
│                             │
│  ┌───────────────────────┐  │
│  │  Kubecost Primary     │  │
│  │  - UI                 │  │
│  │  - API                │  │
│  │  - Federation ETL     │  │
│  └──────────┬────────────┘  │
└─────────────┼───────────────┘
              │
              ▼
      ┌───────────────┐
      │   S3 Bucket   │
      │  (Federation) │
      └───────┬───────┘
              │
      ┌───────┴───────┐
      │               │
      ▼               ▼
┌──────────┐    ┌──────────┐
│ Agent    │    │ Agent    │
│ Cluster1 │    │ Cluster2 │
└──────────┘    └──────────┘
```

## Troubleshooting

### Primary Not Starting

```bash
# Check pod status
kubectl get pods -n kubecost

# Check logs
kubectl logs -n kubecost -l app.kubernetes.io/name=cost-analyzer

# Check events
kubectl get events -n kubecost --sort-by='.lastTimestamp'
```

### Storage Issues

```bash
# Check PVC
kubectl get pvc -n kubecost

# Check storage class
kubectl get storageclass

# Describe PVC for issues
kubectl describe pvc kubecost-data -n kubecost
```

### Federation Not Working

```bash
# Check S3 access
kubectl logs -n kubecost -l app.kubernetes.io/name=cost-analyzer | grep -i s3

# Verify S3 bucket
aws s3 ls s3://my-kubecost-federation/

# Check federation config
kubectl get configmap -n kubecost -o yaml
```

### Ingress Not Accessible

```bash
# Check ingress
kubectl get ingress -n kubecost

# Check ingress controller
kubectl get pods -n ingress-nginx

# Test service directly
kubectl port-forward -n kubecost svc/kubecost-primary-cost-analyzer 9090:9090
```

## Upgrading

```bash
# Update chart version in terraform.tfvars
chart_version = "3.1.6"

# Apply update
terraform plan
terraform apply
```

## Cleanup

```bash
# Remove deployment
terraform destroy

# Clean up S3 data (if needed)
aws s3 rm s3://my-kubecost-federation/ --recursive
```

## Best Practices

1. **Use Federation**: For multi-cluster deployments
2. **Persistent Storage**: Use reliable storage with backups
3. **Ingress/TLS**: Secure access with HTTPS
4. **Resource Limits**: Set appropriate limits for your scale
5. **Monitoring**: Monitor primary cluster health
6. **Backups**: Regular backups of PVC data
7. **IRSA/Workload Identity**: Use instead of static credentials

## License

[Your License Here]