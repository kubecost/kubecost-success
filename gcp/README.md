# Kubecost GCP Deployment Guide (Self-hosted)

![Kubecost Enterprise Architecture](/assets/gcp-cloud-diagram.png)

This guide provides step-by-step instructions for deploying Kubecost in GCP.

## Prerequisites
1. **Configure GCP Cloud Integration**
   - [ ] [Enable billing data export](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=integrations-gcp-cloud-integration#ariaid-title2)
   - [ ] [Create a GCP service account](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=integrations-gcp-cloud-integration#ariaid-title3)
   - [ ] [Connect using Workload Identity Federation](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=integrations-gcp-cloud-integration#ariaid-title5)


2. **Configure Storage for Cluster Metrics**
   - [ ] [Set up object storage](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=configuration-gcp-multi-cluster-storage)
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
helm upgrade --install kubecost   --repo https://kubecost.github.io/kubecost/ kubecost   --namespace kedd-primary --create-namespace \
-f values-gcp-primary.yaml
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
helm upgrade --install kubecost   --repo https://kubecost.github.io/kubecost/ kubecost   --namespace kedd-primary --create-namespace \
-f values-gcp-primary.yaml
```
  - [ ] Verify ETL pipeline is working by checking that a /federated directory was created in the object-store. If no /federated directory exists, double check configuration, finops-agent pod logs or test that the user can curl the bucket endpoint from inside the finops-agent container.


## Optional Configuration

4. **Network Costs Daemonset Configured** 

Please Note: The network cost daemonset is not recommended for large environments where there are several hundred thousand or more unique containers running per day. 

   - [ ] Review [Configuration Guide](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=configuration-network-cost)
   - [ ] Apply [Network Cost Config](/azure/network-costs-enabled.yaml)

5. **SSO/SAML Enabled**
   - [ ] Review [SSO Documentation](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=configuration-user-management-ssooidc)
   - [ ] Configure [OIDC](/custom/oidc-rbac.yaml)
   - [ ] Configure [SAML](/custom/saml-rbac-enabled.yaml)

