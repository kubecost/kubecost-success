# Kubecost Openshift On-Premises Deployment Guide (Self-hosted)

![Kubecost Enterprise Architecture](/assets/on-prem-v3.png)

This guide provides step-by-step instructions for deploying Kubecost in an on-premises environment. Choose the deployment option that best fits your infrastructure requirements.

## Prerequisites

1. **Prepare Air-Gapped Environment (If applicable)**
   - [ ] Set up private container registry
   - [ ] Download and push Kubecost images to internal container registry. Get a list of all images and image paths by running the following command:
   ```bash
   helm template kubecost --repo https://kubecost.github.io/kubecost/ kubecost --skip-tests | yq '..|.image? | select(.)' | sort -u
   ```
   - [ ] Configure Helm repository mirror

2. **Configure Storage**
   - [ ] Set up internal object storage (s3 compatible)
   - [ ] Generate Credentials (access key & secret). [Policy example](/aws/aws-attach-roles/iam-kubecost-metrics-s3-policy.json)
   - [ ] Apply storage configuration

3. **Set the operator group**

```bash 
oc apply -f https://raw.githubusercontent.com/kubecost/kubecost-success/refs/heads/main/openshift/operator-group.yaml
```

4. **Add Subscription**

```bash
oc apply -f https://raw.githubusercontent.com/kubecost/kubecost-success/refs/heads/main/openshift/operator-subscription.yaml
```

## Multi-Cluster Federation with Enterprise Custom Pricing (Air-Gapped/Private Cloud/On-prem Environment)

1. **Set Up Shared Storage**
   - [ ] Configure [federated-store.yaml](/openshift/federated-store.yaml) pointing to the s3 bucket configured in step 2 of prerequisites. 
   - [ ] Create secret for object storage in Kubecost namespace.
   ```bash
   kubectl create secret generic federated-store --from-file=federated-store.yaml -n kubecost
   ```

2. **Primary Cluster Installation**
   - [ ] Install Kubecost using [primary custom resource.yaml](/openshift/kubecost-v3-custom-resource.yaml) with federation enabled. Ensure the appropriate custom values are added to the custom resource before running the command in this step.

```bash
   oc apply -f kubecost-v3-custom-resource.yaml
```
   - [ ] Verify ETL pipeline is working by checking that a /federated directory was created in the object-store. If no /federated directory exists, double check configuration, finops-agent pod logs or test that the user can curl the bucket endpoint from inside the finops-agent container.

3. **Secondary Clusters Installation**
   - [ ] Configure [federated-store.yaml](/openshift/federated-store.yaml) pointing to the s3 bucket configured in step 2 of prerequisites. 
   - [ ] Create secret for object storage in Kubecost namespace.
```bash
   oc create secret generic federated-store --from-file=federated-store.yaml -n kubecost
```
   - [ ] Install Kubecost on secondary clusters using [kubecost v3 agent Custom Resource yaml](/openshift/kubecostv3-agent-custom-resource.yaml).

```bash
oc apply -f kubecostv3-agent-custom-resource.yaml
```
   - [ ] Verify ETL pipeline is working by checking that a /federated directory was created with the cluster-name sub directory in the object-store. If no /federated directory exists, double check configuration, finops-agent pod logs or test that the user can curl the bucket endpoint from inside the finops-agent container.

### Configure the pricing spec (If applicable)
- [ ] [Configure hourly pricing spec](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=configuration-csv-pricing#concept_1__title__1)

[Example csv](/on-prem/pricing.csv)

## Optional Configuration

 **Kubecost Actions**

Continuous Container Requst Right-sizing & Resource Quota Right-sizing

⚠️**Important Note:** In order to use this feature, users must obtain a v3 license key. Reach out to your Account Representative(s)

   - [ ] [Add Kubecost Actions values to Custom Resource](https://raw.githubusercontent.com/kubecost/kubecost-success/refs/heads/main/actions-primary.yaml)
  

 **SSO/SAML Enabled**
   - [ ] Review [SSO Documentation](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=configuration-user-management-ssooidc)
   - [ ] Configure [OIDC](/custom/oidc-rbac.yaml)
   - [ ] Configure [SAML](/custom/saml-rbac-enabled.yaml)

## Troubleshooting

Common issues and their solutions will be documented here.

## References

- [Kubecost Documentation](https://www.ibm.com/docs/en/kubecost)
- [Helm Chart Reference](https://github.com/kubecost/kubecost)
- [Support Resources](https://support.ibm.com) 