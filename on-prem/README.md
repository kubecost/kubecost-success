# Kubecost On-Premises Deployment Guide (Self-hosted)

![Kubecost Enterprise Architecture](/assets/on-prem-v3.png)

This guide provides step-by-step instructions for deploying Kubecost in an on-premises environment. Choose the deployment option that best fits your infrastructure requirements.

## Prerequisites

1. **Prepare Air-Gapped Environment**
   - [ ] Set up private container registry
   - [ ] Download and push Kubecost images to internal container registry. Get a list of all images and image paths by running the following command:
   ```bash
   helm template kubecost --repo https://kubecost.github.io/kubecost/ kubecost --skip-tests | yq '..|.image? | select(.)' | sort -u
   ```
   - [ ] Configure Helm repository mirror

2. **Configure Storage**
   - [ ] Set up internal object storage
   - [ ] Generate Credentials (access key & secret). [Policy example](/aws/aws-attach-roles/iam-kubecost-metrics-s3-policy.json)
   - [ ] Apply storage configuration

## Multi-Cluster Federation with Enterprise Custom Pricing (Air-Gapped/Private Cloud/On-prem Environment)

1. **Set Up Shared Storage**
   - [ ] Configure [federated-store.yaml](/on-prem/federated-store.yaml) pointing to the s3 bucket configured in step 2 of prerequisites. 
   - [ ] Create secret for object storage in Kubecost namespace.
   ```bash
   kubectl create secret generic federated-store --from-file=federated-store.yaml -n kubecost
   ```

2. **Primary Cluster Installation**
   - [ ] Install Kubecost using [primary values file](/on-prem/values-ecp-primary.yaml) with federation enabled.

   ```bash
   helm upgrade --install kubecost \
     --repo http://internal-helm-repo/charts/ kubecost \
     --namespace kubecost \
     --values values-ecp-primary.yaml
   ```
   - [ ] Verify ETL pipeline is working by checking that a /federated directory was created in the object-store. If no /federated directory exists, double check configuration, finops-agent pod logs or test that the user can curl the bucket endpoint from inside the finops-agent container.

3. **Secondary Clusters Installation**
   - [ ] Configure [federated-store.yaml](/on-prem/federated-store.yaml) pointing to the s3 bucket configured in step 2 of prerequisites. 
   - [ ] Create secret for object storage in Kubecost namespace.
   ```bash
   kubectl create secret generic federated-store --from-file=federated-store.yaml -n kubecost
   ```
   - [ ] Install Kubecost on secondary clusters using [secondary values fle template](/on-prem/values-ecp-agent.yaml).

   ```bash
   helm upgrade --install kubecost \
     --repo http://internal-helm-repo/charts/ kubecost \
     --namespace kubecost \
     --values values-ecp-agent.yaml
   ```
   - [ ] Verify ETL pipeline is working by checking that a /federated directory was created with the cluster-name sub directory in the object-store. If no /federated directory exists, double check configuration, finops-agent pod logs or test that the user can curl the bucket endpoint from inside the finops-agent container.


### Authentication & Authorization
- [ ] [Configure SSO/SAML](https://docs.kubecost.com/install-and-configure/install/getting-started#sso-saml-rbac-oidc)
- [ ] [Set up SSO/OIDC](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=configuration-user-management-oidc)
- [ ] [Configure Teams](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=ui-teams)

### Configure the pricing spec
- [ ] [Configure hourly pricing spec](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=configuration-csv-pricing#concept_1__title__1)

[Example csv](/on-prem/pricing.csv)

## Troubleshooting

Common issues and their solutions will be documented here.

## References

- [Kubecost Documentation](https://www.ibm.com/docs/en/kubecost)
- [Helm Chart Reference](https://github.com/kubecost/kubecost)
- [Support Resources](https://support.ibm.com) 