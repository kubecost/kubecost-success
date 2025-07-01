# Kubecost On-Premises Deployment Guide (Self-hosted)

![Kubecost Enterprise Architecture](/assets/onpremdiagram-option1.png)

This guide provides step-by-step instructions for deploying Kubecost in an on-premises environment. Choose the deployment option that best fits your infrastructure requirements.

## Prerequisites

1. **Prepare Air-Gapped Environment**
   - [ ] Set up private container registry
   - [ ] Download and push Kubecost images
   - [ ] Configure Helm repository mirror

2. **Configure Storage**
   - [ ] Set up internal object storage
   - [ ] Create access credentials (IAM User/IRSA and [Policy](/aws/aws-attach-roles/iam-access-cur-in-payer-account.json))
   - [ ] Apply storage configuration

### Option 1: Multi-Cluster Federation with CSV Pricing (Air-Gapped Environment)

![Multi-Cluster Federation](/assets/onpremdiagram-option1.png)

1. **Set Up Shared Storage**
   - [ ] Configure [federated-store.yaml](/on-prem/federated-store.yaml) pointing to the s3 bucket configured in step 2 of prerequisites. 
   - [ ] Create secret for object storage in Kubecost namespace.
   ```bash
   kubectl create secret generic federated-store --from-file=object-store.yaml -n kubecost
   ```

2. **Primary Cluster Installation**
   - [ ] Install Kubecost using [primary values file](/on-prem/values-defaultmodelpricing-primary.yaml) with federation enabled.

   ```bash
   helm upgrade --install kubecost \
     --repo https://kubecost.github.io/cost-analyzer/ kubecost \
     --namespace kubecost \
     --values values-csv-custom-pricing-primary.yaml
   ```
   - [ ] Verify ETL pipeline is working

3. **Secondary Clusters Installation**
   - [ ] Configure [federated-store.yaml](/on-prem/federated-store.yaml) pointing to the s3 bucket configured in step 2 of prerequisites. 
   - [ ] Create secret for object storage in Kubecost namespace.
   ```bash
   kubectl create secret generic federated-store --from-file=federated-store.yaml -n kubecost
   ```
   - [ ] Install Kubecost on secondary clusters using [secondary values fle template](/on-prem/values-csv-custom-pricing-secondary.yaml).

   ```bash
   helm upgrade --install kubecost \
     --repo https://kubecost.github.io/cost-analyzer/ kubecost \
     --namespace kubecost \
     --values values-csv-custom-pricing-secondary.yaml
   ```
   - [ ] Verify data is being sent to primary cluster

### Option 2: Default Model Pricing

![Default Model Pricing](/assets/onpremdiagram-option3.png)
   - [ ] Create access credentials 
   - [ ] Configure [federated-store.yaml](/on-prem/federated-store.yaml) pointing to the s3 bucket configured in step 2 of prerequisites. 
   - [ ] Create secret for object storage in Kubecost namespace.
   ```bash
   kubectl create secret generic federated-store --from-file=federated-store.yaml -n kubecost
   ```
1. **Install Kubecost on primary**
   - [ ] Install using [primary values file template](/on-prem/values-defaultmodelpricing-primary.yaml) with federation enabled for long term ETL storage. 
   ```bash
   helm upgrade --install kubecost \
     --repo http://internal-helm-repo/charts/ cost-analyzer \
     --namespace kubecost \
     --values values-defaultmodelpricing-primary.yaml
   ```

2. **Secondary Clusters Installation**
   - [ ] Configure [federated-store.yaml](/on-prem/federated-store.yaml) pointing to the s3 bucket configured in step 2 of prerequisites. 
   - [ ] Create secret for object storage in Kubecost namespace.
   ```bash
   kubectl create secret generic federated-store --from-file=federated-store.yaml -n kubecost
   ```
   - [ ] Install Kubecost on secondary clusters using [secondary values fle template](/on-prem/values-defaultmodelpricing-primary.yaml).
   ```bash
   helm upgrade --install kubecost \
     --repo http://internal-helm-repo/charts/ cost-analyzer \
     --namespace kubecost \
     --values values-defaultmodelpricing-primary.yaml
   ```

### Authentication & Authorization
- [ ] [Configure SSO/SAML](https://docs.kubecost.com/install-and-configure/install/getting-started#sso-saml-rbac-oidc)
- [ ] [Set up RBAC policies](https://docs.kubecost.com/using-kubecost/navigating-the-kubecost-ui/teams)

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