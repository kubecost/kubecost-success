# Kubecost AWS Deployment Guide (Self-hosted)

![Kubecost Enterprise Federation Architecture](/assets/aws-cloud-integrationv3.png)

It is recommended to deploy Kubecost Enterprise in this order to improve time to value. Configuring the AWS cloud integration will provide the most accurate data. Otherwise, it will default to on-demand public pricing and will not accurately reflect your AWS bill.

## Prerequisites

A total of 3 buckets are required in order to support a IBM Kubecost Federated deployment with AWS cloud integration.

1. - [ ] [Generate AWS CUR](https://docs.aws.amazon.com/cur/latest/userguide/cur-create.html) 

2. - [ ] Set up a dedicated s3 object store for cluster metrics
   - [ ] [Create storage policy](/aws/aws-attach-roles/iam-kubecost-metrics-s3-policy.json)

3. - [ ] Set up a dedicated s3 object store for athena query results
   - [ ] [Create storage policy based on set up](/aws/aws-attach-roles)

## Kubecost Installation - Choose appropriate option.

1. **Kubecost Installed on Primary Cluster**  

   ***Option A: Enterprise with IRSA/EKS Pod Identities***
   - [ ] [Enteprise Federation with IRSA/EKS Pod Identities](/aws/clusters-using-irsa-eks-pod-identities/aws-primary-federation-irsa.yaml)
   
```bash
   helm upgrade --install kubecost \
     --repo https://kubecost.github.io/kubecost/ kubecost \
     --namespace kubecost \
     -f aws-primary-federation-irsa.yaml
```
   - [ ] Verify ETL pipeline is working by checking that a /federated directory was created in the object-store. If no /federated directory exists, double check configuration, finops-agent pod logs or test that the user can curl the bucket endpoint from inside the finops-agent container.

   ***Option B: Using Access Key and Secret***
   - [ ] [Enteprise Federation no IRSA](/aws/clusters-using-access-key/aws-primary.yaml)
```bash
   helm upgrade --install kubecost \
     --repo https://kubecost.github.io/kubecost/ kubecost \
     --namespace kubecost \
     -f aws-primary.yaml
```

2. **Cloud Cost Integration Configured**  
   - [ ] [AWS Cloud Integration](https://www.ibm.com/docs/en/kubecost/self-hosted/2.x?topic=integrations-aws-cloud-billing-integration) 

   - [ ] [AWS Cloud Integration using IRSA/EKS Pod Identities](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=integration-aws-cloud-using-irsaeks-pod-identities)

   - [Cloud Integration Config File](/aws/cloud-integration.json)

3. **Kubecost Installed on Secondary Cluster(s)**

   ***Option A: With IRSA/EKS Pod Identities***
   - [ ] [ETL Federation Aggregator Configuration with IRSA](/aws/clusters-using-irsa-eks-pod-identities/aws-kubecost-agent-irsa.yaml)

```bash
   helm upgrade --install kubecost \
     --repo https://kubecost.github.io/kubecost/ kubecost \
     --namespace kubecost \
     -f aws-kubecost-agent-irsa.yaml
```

   ***Option B: Using Access Key and Secret***
   - [ ] [ETL Federation Aggregator Configuration no IRSA](/aws/clusters-using-access-key/aws-kubecost-agent.yaml)

```bash
   helm upgrade --install kubecost \
     --repo https://kubecost.github.io/kubecost/ kubecost \
     --namespace kubecost \
     -f aws-kubecost-agent.yaml
```
## Optional Configuration
4. **Network Costs Daemonset Configured**  
   - [ ] [Configuration Guide](https://www.ibm.com/docs/en/kubecost/self-hosted/2.x?topic=configuration-network-cost)
  
   - [Network Cost Config](/aws/network-costs-enabled.yaml)

5. **SSO/SAML/OIDC Enabled**
   
 ### Authentication & Authorization
- [ ] [Configure SSO/SAML](https://docs.kubecost.com/install-and-configure/install/getting-started#sso-saml-rbac-oidc)
- [ ] [Set up SSO/OIDC](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=configuration-user-management-oidc)
- [ ] [Configure Teams](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=ui-teams)

## Troubleshooting

Common issues and their solutions will be documented here.

## References

- [Kubecost Documentation](https://www.ibm.com/docs/en/kubecost)
- [Helm Chart Reference](https://github.com/kubecost/kubecost)
- [Support Resources](https://support.ibm.com) 