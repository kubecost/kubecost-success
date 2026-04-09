# Kubecost 3.x Deployment Guide

**For Kubecost 3.x+ (Latest: 3.1.6)**

## ⚠️ Important: Kubecost 3.x Breaking Changes

Kubecost 3.0+ introduces significant architectural changes:
- **New Helm Repository**: `https://kubecost.github.io/kubecost/` (changed from `/cost-analyzer/`)
- **New Chart Name**: `kubecost` (changed from `cost-analyzer`)
- **IBM FinOps Agent**: New agent architecture replacing legacy agent mode
- **Image Registry**: Now uses `icr.io` (IBM Container Registry) instead of `gcr.io`
- **Federated Storage**: Primary configuration method for SaaS deployments
- **Migration Deadline**: Images moving from gcr.io to icr.io before July 30, 2026

This repository contains examples for deploying and managing Kubecost in both SaaS and self-hosted configurations.

## Deployment Models

### Choose Your Deployment Model

| Feature | SaaS (IBM-hosted) | Self-Hosted |
|---------|-------------------|-------------|
| Primary Instance | IBM manages | You deploy and manage |
| Agents | You deploy | You deploy |
| Storage | IBM-managed | Your infrastructure |
| Federation Storage | IBM or customer S3 | Customer S3 |
| Maintenance | IBM handles | You handle |
| **Use When** | Prefer managed service | Want full control |

### SaaS Deployment
- **Primary Instance**: Hosted and managed by IBM
- **Agents**: Deployed on your Kubernetes clusters
- **Data Storage**: Managed by IBM (or optionally your S3 for federation)
- **Your Responsibility**: Deploy and maintain agents only
- **Modules to Use**: [`terraform/kubecost-agent/`](terraform/kubecost-agent/)

### Self-Hosted Deployment
- **Primary Instance**: You deploy and manage
- **Agents**: You deploy on additional clusters (optional)
- **Data Storage**: Your infrastructure (PVC + optional S3 for federation)
- **Your Responsibility**: Deploy and maintain everything
- **Modules to Use**: [`terraform/kubecost-primary/`](terraform/kubecost-primary/) + [`terraform/kubecost-agent/`](terraform/kubecost-agent/)

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── kubecost-agent.yml        # Unified workflow for agent deployment/updates
├── terraform/
│   ├── kubecost-primary/             # Self-hosted primary cluster deployment
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── kubecost-agent/               # Agent deployment (SaaS or self-hosted)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── cloud-integrations/           # Cloud provider cost integrations
│       ├── aws/
│       ├── azure/
│       └── gcp/
├── scripts/
│   ├── setup-local-test-environment.sh
│   └── README.md
└── README.md
```

## Prerequisites

### For SaaS Deployments
- Kubernetes cluster(s) running version 1.20+
- `kubectl` configured with cluster access
- Helm 3.x (for GitHub Actions) or Terraform 1.0+
- Kubecost SaaS credentials provided by IBM (token and primary URL)

### For Self-Hosted Deployments
- Kubernetes cluster(s) running version 1.20+
- `kubectl` configured with cluster access
- Helm 3.x and Terraform 1.0+
- Storage provisioner for persistent volumes
- Ingress controller or LoadBalancer (for primary access)
- S3-compatible storage (optional, for federation)

## Local Testing Setup

Want to test locally before deploying to production? We've got you covered!

### Automated Setup Script

Run the setup script to automatically install all required tools and create a local Kubernetes cluster:

```bash
# Make the script executable
chmod +x scripts/setup-local-test-environment.sh

# Run the setup
./scripts/setup-local-test-environment.sh
```

The script will:
- ✅ Detect your OS (Fedora, Ubuntu, Debian, macOS)
- ✅ Install Docker, kubectl, Helm, kind, Terraform, and GitHub CLI
- ✅ Create a local 3-node Kubernetes cluster
- ✅ Set up Helm repositories and namespaces
- ✅ Generate example configuration files

**Supported on**: Fedora Linux, Ubuntu, Debian, macOS

See [`scripts/README.md`](scripts/README.md) for detailed documentation.

### Manual Testing

If you prefer manual setup or already have the tools installed:

1. Create a local cluster with kind:
   ```bash
   kind create cluster --name kubecost-test
   ```

2. Follow the deployment steps below

## Quick Start

### Option 1: GitHub Actions Deployment

1. Set up GitHub Secrets (see [GitHub Actions Setup](#github-actions-setup))
2. Trigger the workflow with your desired action (deploy or update)
3. Monitor the workflow execution

### Option 2: Terraform Deployment

1. Configure Terraform variables
2. Run `terraform init` and `terraform apply`
3. Verify agent deployment

## GitHub Actions Setup

### Required Secrets

Configure these secrets in your GitHub repository (Settings → Secrets and variables → Actions):

| Secret Name | Description | Example |
|------------|-------------|---------|
| `KUBE_CONFIG` | Base64-encoded kubeconfig file | `cat ~/.kube/config \| base64` |
| `FEDERATED_STORAGE_CONFIG` | Federated storage YAML config from IBM | Provided by IBM for SaaS |
| `KUBECOST_TOKEN` | (Legacy - optional for 3.x) SaaS agent token | Provided by IBM |
| `KUBECOST_PRIMARY_URL` | (Legacy - optional for 3.x) Primary instance URL | `https://kubecost.ibm.example.com` |

**Note for 3.x**: The primary configuration method is now `FEDERATED_STORAGE_CONFIG`. Legacy token/URL settings are optional for backward compatibility.

### Unified Workflow

The repository includes a single, unified GitHub Actions workflow ([`.github/workflows/kubecost-agent.yml`](.github/workflows/kubecost-agent.yml)) that handles both initial deployment and updates through workflow inputs.

#### Workflow Features

- **Single workflow** for both deploy and update operations
- **Conditional logic** that adapts based on the selected action
- **Automatic rollback** on failed updates
- **Dry run support** for testing changes
- **Version management** with latest or pinned versions
- **Health checks** and verification steps

#### Triggering the Workflow

**Via GitHub UI:**
1. Go to Actions → Kubecost Agent Deployment
2. Click "Run workflow"
3. Select options:
   - **Action**: `deploy` (initial) or `update` (existing)
   - **Cluster name**: Required for deploy, optional for update
   - **Chart version**: Leave empty for latest or specify version
   - **Namespace**: Default is `kubecost`
   - **Dry run**: Test without applying changes

**Via GitHub CLI:**

```bash
# Initial deployment
gh workflow run kubecost-agent.yml \
  -f action=deploy \
  -f cluster_name=production-us-east-1 \
  -f namespace=kubecost

# Update to latest version
gh workflow run kubecost-agent.yml \
  -f action=update

# Update to specific version
gh workflow run kubecost-agent.yml \
  -f action=update \
  -f chart_version=2.0.0

# Dry run
gh workflow run kubecost-agent.yml \
  -f action=update \
  -f dry_run=true
```

**Via GitHub API:**

```bash
curl -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/repos/OWNER/REPO/actions/workflows/kubecost-agent.yml/dispatches \
  -d '{"ref":"main","inputs":{"action":"deploy","cluster_name":"production"}}'
```

### Workflow Behavior

#### Deploy Action
- Creates namespace if it doesn't exist
- Creates Kubecost token secret
- Installs Helm chart with agent configuration
- Verifies deployment health
- Provides deployment summary

#### Update Action
- Checks for existing release
- Compares current vs target version
- Upgrades with atomic rollback enabled
- Verifies updated deployment
- Automatically rolls back on failure

## Terraform Setup

### SaaS: Agent Deployment Only

Deploy agents that connect to IBM-hosted primary:

```hcl
module "kubecost_agent" {
  source = "./terraform/kubecost-agent"

  cluster_name              = "production-us-east-1"
  federated_storage_config  = var.federated_storage_config  # IBM-provided S3 config
  namespace                 = "kubecost"
  chart_version             = "3.1.6"  # Pin to specific 3.x version
}
```

See [`terraform/kubecost-agent/README.md`](terraform/kubecost-agent/README.md) for detailed documentation.

### Self-Hosted: Primary + Agents

#### Step 1: Deploy Primary Cluster

```hcl
module "kubecost_primary" {
  source = "./terraform/kubecost-primary"

  cluster_name = "production-primary"
  namespace    = "kubecost"
  
  # Ingress for UI and agent connectivity
  ingress_enabled    = true
  ingress_class_name = "nginx"
  ingress_hosts      = ["kubecost.example.com"]
  
  # Optional: Enable federation for multi-cluster
  enable_federation      = true
  federation_s3_bucket   = "my-kubecost-federation"
  federation_s3_region   = "us-east-1"
  
  storage_size = "100Gi"
}
```

See [`terraform/kubecost-primary/README.md`](terraform/kubecost-primary/README.md) for detailed documentation.

#### Step 2: Deploy Agents (Optional, for additional clusters)

```hcl
module "kubecost_agent" {
  source = "./terraform/kubecost-agent"

  cluster_name              = "production-worker-1"
  federated_storage_config  = var.federated_storage_config  # Same config as primary
  namespace                 = "kubecost"
  chart_version             = "3.1.6"
}
```

### Cloud Provider Integrations

Configure cloud provider integrations to enable accurate cost allocation:

#### AWS Integration

```hcl
module "kubecost_aws" {
  source = "./terraform/cloud-integrations/aws"

  aws_account_id      = "123456789012"
  cur_bucket_name     = "my-cur-bucket"
  athena_bucket_name  = "my-athena-results"
  oidc_provider_arn   = var.oidc_provider_arn
  kubecost_namespace  = "kubecost"
}
```

See [`terraform/cloud-integrations/aws/README.md`](terraform/cloud-integrations/aws/README.md) for details.

#### Azure Integration

```hcl
module "kubecost_azure" {
  source = "./terraform/cloud-integrations/azure"

  tenant_id              = "12345678-1234-1234-1234-123456789012"
  storage_account_name   = "kubecostexports"
  storage_container_name = "cost-exports"
  kubecost_namespace     = "kubecost"
}
```

See [`terraform/cloud-integrations/azure/README.md`](terraform/cloud-integrations/azure/README.md) for details.

#### GCP Integration

```hcl
module "kubecost_gcp" {
  source = "./terraform/cloud-integrations/gcp"

  project_id              = "my-gcp-project"
  billing_dataset_id      = "billing_export"
  enable_workload_identity = true
  kubecost_namespace      = "kubecost"
}
```

See [`terraform/cloud-integrations/gcp/README.md`](terraform/cloud-integrations/gcp/README.md) for details.

## Deployment Comparison

| Feature | GitHub Actions | Terraform |
|---------|---------------|-----------|
| **Best For** | CI/CD pipelines, automated updates | Infrastructure as Code, GitOps |
| **Setup Complexity** | Low | Medium |
| **Version Control** | Workflow files | State management |
| **Rollback** | Automatic on failure | Manual or automated |
| **Multi-Cluster** | Multiple workflow runs | Module instances |
| **Cloud Integration** | Manual setup | Automated with modules |
| **Dry Run** | Built-in support | `terraform plan` |

## Verification

After deployment, verify the agent is running:

```bash
# Check FinOps agent pods
kubectl get pods -n kubecost -l app.kubernetes.io/name=finops-agent

# Check agent logs
kubectl logs -n kubecost -l app.kubernetes.io/name=finops-agent

# Verify federated storage connection
kubectl logs -n kubecost -l app.kubernetes.io/name=finops-agent | grep -i "storage\|s3"

# Check agent version (should be 3.x)
helm list -n kubecost
```

## Updating Agents

### Via GitHub Actions

Use the unified workflow with `action=update`:

```bash
gh workflow run kubecost-agent.yml -f action=update
```

The workflow will:
1. Check current version
2. Fetch latest (or specified) version
3. Perform atomic upgrade
4. Verify health
5. Rollback automatically if update fails

### Via Terraform

Update the `chart_version` variable and apply:

```hcl
module "kubecost_agent" {
  source = "./terraform/kubecost-agent"
  
  chart_version = "2.0.0"  # Update this
  # ... other variables
}
```

```bash
terraform plan
terraform apply
```

### Manual Update

```bash
# Update Helm repository
helm repo update

# Upgrade agent to 3.x
helm upgrade kubecost-agent kubecost/kubecost \
  --namespace kubecost \
  --reuse-values \
  --version 3.1.6
```

## Troubleshooting

### Agent Not Connecting

1. Verify `FEDERATED_STORAGE_CONFIG` is correct (for 3.x)
2. Check S3 bucket access and credentials
3. Review agent logs: `kubectl logs -n kubecost -l app.kubernetes.io/name=finops-agent`
4. Verify network connectivity to S3 endpoint

### Cloud Integration Issues

1. Verify IAM/RBAC permissions
2. Check cloud provider credentials
3. Review integration logs in Kubecost UI

### GitHub Actions Failures

1. Check workflow logs in Actions tab
2. Verify GitHub Secrets are configured correctly
3. Ensure kubeconfig has proper permissions
4. Try dry run mode to test configuration

### Common Issues

| Issue | Solution |
|-------|----------|
| Agent pods CrashLoopBackOff | Check federated storage config and S3 access |
| No cost data appearing | Verify cloud integration and storage connectivity |
| High memory usage | Adjust resource limits in finopsagent values |
| Workflow permission denied | Check kubeconfig and cluster RBAC |
| Update fails | Check logs, automatic rollback should occur |
| Image pull errors | Verify access to icr.io registry |

## Best Practices

1. **Version Pinning**: Pin Helm chart versions in production
2. **Resource Limits**: Set appropriate CPU/memory limits
3. **Monitoring**: Set up alerts for agent health
4. **Regular Updates**: Keep agents updated for security and features
5. **Multi-Cluster**: Use unique cluster names for each deployment
6. **Secrets Management**: Use GitHub Secrets or external secret managers
7. **Testing**: Use dry run mode before applying changes
8. **Cloud Integration**: Set up cloud provider integrations for accurate costs

## Multi-Cluster Deployment

### GitHub Actions Approach

Create separate workflow runs for each cluster or use matrix strategy:

```yaml
strategy:
  matrix:
    cluster:
      - name: production-us-east-1
        kubeconfig: KUBE_CONFIG_PROD_US
      - name: production-eu-west-1
        kubeconfig: KUBE_CONFIG_PROD_EU
```

### Terraform Approach

Use module instances:

```hcl
module "kubecost_agent_us" {
  source = "./terraform/kubecost-agent"
  
  cluster_name = "production-us-east-1"
  # ... other config
}

module "kubecost_agent_eu" {
  source = "./terraform/kubecost-agent"
  
  cluster_name = "production-eu-west-1"
  # ... other config
}
```

## Security Considerations

- Store sensitive values in GitHub Secrets or secret managers
- Use IRSA/Workload Identity for cloud provider access when possible
- Rotate credentials regularly
- Enable network policies for agent pods
- Use least-privilege IAM roles
- Audit access to deployment workflows

## Support

For issues related to:
- **Agent Deployment**: Check this repository's documentation
- **SaaS Platform**: Contact IBM support at team-kubecost@wwpdl.vnet.ibm.com
- **Kubecost 3.x Features**: Visit [IBM Kubecost Documentation](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x)
- **Migration from 2.x**: See the [Migration Guide](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x)

## Migration from 2.x to 3.x

If you're currently using Kubecost 2.x, please note:

1. **Backup your data** before upgrading
2. **Update Helm repository** from `/cost-analyzer/` to `/kubecost/`
3. **Update chart name** from `cost-analyzer` to `kubecost`
4. **Obtain federated storage config** from IBM for SaaS deployments
5. **Update image registry** references from `gcr.io` to `icr.io`
6. **Test in non-production** environment first
7. **Review breaking changes** in the [release notes](https://github.com/kubecost/kubecost/releases)

**Important**: Images are migrating from gcr.io to icr.io before July 30, 2026. Update your configurations accordingly.

## Contributing

When contributing to this repository:
1. Test changes in a non-production environment
2. Use dry run mode for workflow testing
3. Update documentation for any changes
4. Follow existing code style and structure

## License

[Your License Here]