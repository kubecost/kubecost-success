# Kubecost GCP Deployment Guide (Self-hosted)

![Kubecost Enterprise Architecture](/assets/gcp-diagram.png)

This guide provides step-by-step instructions for deploying Kubecost in GCP.

## Prerequisites
1. **Configure GCP Cloud Integration**
   - [ ] [Enable billing data export](https://www.ibm.com/docs/en/kubecost/self-hosted/2.x?topic=integrations-gcp-cloud-integration#ariaid-title2)
   - [ ] [Create a GCP service account](https://www.ibm.com/docs/en/kubecost/self-hosted/2.x?topic=integrations-gcp-cloud-integration#ariaid-title3)
   - [ ] [Connect using Workload Identity Federation](https://www.ibm.com/docs/en/kubecost/self-hosted/2.x?topic=integrations-gcp-cloud-integration#ariaid-title5)


2. **Configure Storage for Cluster Metrics**
   - [ ] [Set up object storage](https://www.ibm.com/docs/en/kubecost/self-hosted/2.x?topic=configuration-gcp-multi-cluster-storage)
   - [ ] Apply storage configuration

### Multi-Cluster Federation 

1. **Set Up Shared Storage**
   - [ ] Configure [federated-store.yaml](/gcp/federated-store.yaml) pointing to the google storage bucket configured in step 2 of prerequisites. 
   - [ ] Create secret for object storage in Kubecost namespace.
   ```bash
   kubectl create secret generic federated-store --from-file=object-store.yaml -n kubecost
   ```

2. **Primary Cluster Installation**
   - [ ] Install Kubecost using [primary values file](/gcp/values-gcp-primary.yaml) with federation enabled.

   ```bash
   helm upgrade --install kubecost \
     --repo https://kubecost.github.io/cost-analyzer/ kubecost \
     --namespace kubecost \
     --values values-gcp-primary.yaml
   ```
   - [ ] Verify ETL pipeline is working

3. **Secondary Clusters Installation**
   - [ ] Configure [federated-store.yaml](/gcp/federated-store.yaml) pointing to the google storage bucket configured in step 2 of prerequisites. 
   - [ ] Create secret for object storage in Kubecost namespace.
   ```bash
   kubectl create secret generic federated-store --from-file=federated-store.yaml -n kubecost
   ```
   - [ ] Install Kubecost on secondary clusters using [secondary values fle template](/gcp/values-gcp-secondary.yaml).

   ```bash
   helm upgrade --install kubecost \
     --repo https://kubecost.github.io/cost-analyzer/ kubecost \
     --namespace kubecost \
     --values values-gcp-secondary.yaml
   ```
   - [ ] Verify data is being sent to primary cluster


### Authentication & Authorization
- [ ] [Configure SSO/SAML](https://www.ibm.com/docs/en/kubecost/self-hosted/2.x?topic=configuration-user-management-saml)
- [ ] [Configure SSO/OIDC](https://www.ibm.com/docs/en/kubecost/self-hosted/2.x?topic=configuration-user-management-ssooidc)
- [ ] [Set up Teams (RBAC)](https://www.ibm.com/docs/en/kubecost/self-hosted/2.x?topic=ui-teams)

### Alerting & Reporting
- [ ] Configure Slack/Teams integration
- [ ] Set up email reports
- [ ] Define custom alerts

## Troubleshooting

Common issues and their solutions will be documented here.

## References

- [Kubecost Documentation](https://www.ibm.com/docs/en/kubecost)
- [Helm Chart Reference](https://github.com/kubecost/cost-analyzer-helm-chart)
- [Support Resources](https://support.kubecost.com/) 
