# Kubecost On-Premises Deployment Guide

![Kubecost Enterprise Architecture](/assets/onpremdiagram-option1.png)

This guide provides step-by-step instructions for deploying Kubecost in an on-premises environment. Choose the deployment option that best fits your infrastructure requirements.

## Deployment Options

### Option 1: Single Cluster Deployment

![CSV in Central Object Store](/assets/onprem-single.png)

1. **Prepare Storage Backend**
   - [ ] Configure persistent storage for Prometheus
   - [ ] Set up object storage for long-term metrics & CSV pricing data

   
2. **Install Kubecost**
   - [ ] Create namespace
   ```bash
   kubectl create namespace kubecost
   ```
   - [ ] Create node pricing using CSV template
         CSV template found [here](/onprem/custom-pricing.csv)
   ```bash
   kubectl create configmap csv-pricing --from-file custom-pricing.csv -n kubecost
   ```

   - [ ] Apply Helm values
   ```bash
   helm upgrade --install kubecost \
     --repo https://kubecost.github.io/cost-analyzer/ cost-analyzer \
     --namespace kubecost \
     --values values-single-cluster-csv-pricing.yaml
   ```

3. **Configure Access**
   - [ ] Set up ingress or port-forwarding
   - [ ] Configure authentication (optional)

### Option 2: Multi-Cluster Federation with CSV Pricing (Air-Gapped Environment)

![Multi-Cluster Federation](/assets/onpremdiagram-option1.png)

1. **Set Up Shared Storage**
   - [ ] Configure object storage backend
   - [ ] Create access credentials (IAM User/IRSA and [Policy](/aws/aws-attach-roles/iam-access-cur-in-payer-account.json))
   - [ ] Create secret for object storage
   ```bash
   kubectl create secret generic federated-store --from-file=object-store.yaml -n kubecost
   ```

2. **Primary Cluster Installation**
   - [ ] Install Kubecost with federation enabled
   ```bash
   helm upgrade --install kubecost \
     --repo https://kubecost.github.io/cost-analyzer/ cost-analyzer \
     --namespace kubecost \
     --values values-csv-custom-pricing-primary.yaml
   ```
   - [ ] Verify ETL pipeline is working

3. **Secondary Clusters Installation**
   - [ ] Install Kubecost on secondary clusters
   ```bash
   helm upgrade --install kubecost \
     --repo https://kubecost.github.io/cost-analyzer/ cost-analyzer \
     --namespace kubecost \
     --values values-csv-custom-pricing-secondary.yaml
   ```
   - [ ] Verify data is being sent to primary cluster

### Option 3: Default Model Pricing

![Default Model Pricing](/assets/onpremdiagram-option3.png)

1. **Prepare Air-Gapped Environment**
   - [ ] Set up private container registry
   - [ ] Download and push Kubecost images
   - [ ] Configure Helm repository mirror

2. **Configure Storage**
   - [ ] Set up internal object storage
   - [ ] Create access credentials
   - [ ] Apply storage configuration

3. **Install Kubecost**
   - [ ] Create custom values file with air-gapped settings
   - [ ] Install using local resources
   ```bash
   helm upgrade --install kubecost \
     --repo http://internal-helm-repo/charts/ cost-analyzer \
     --namespace kubecost \
     --values values-air-gapped.yaml
   ```

## Optional Configurations

### Network Costs Monitoring
- [ ] Enable Network Costs DaemonSet
- [ ] Configure network topology

### Authentication & Authorization
- [ ] Configure SSO/SAML
- [ ] Set up RBAC policies

### Alerting & Reporting
- [ ] Configure Slack/Teams integration
- [ ] Set up email reports
- [ ] Define custom alerts

## Troubleshooting

Common issues and their solutions will be documented here.

## References

- [Kubecost Documentation](https://docs.kubecost.com/)
- [Helm Chart Reference](https://github.com/kubecost/cost-analyzer-helm-chart)
- [Support Resources](https://support.kubecost.com/) 