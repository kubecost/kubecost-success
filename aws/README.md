# Kubecost AWS Deployment Guide (Self-hosted)

![Kubecost Enterprise Federation Architecture](/assets/awskubecostv2-diagram.png)

It is recommended to deploy Kubecost Enterprise in this order to improve time to value. Configuring the AWS cloud integration will provide the most accurate data. Otherwise, it will default to on-demand public pricing and will not accurately reflect your AWS bill.

## Prerequisites
1. - [ ] [Generate AWS CUR](https://docs.aws.amazon.com/cur/latest/userguide/cur-create.html) 

2. - [ ] Set up a dedicated s3 object store for cluster metrics
   - [ ] [Create storage policy](/aws/aws-attach-roles/iam-kubecost-metrics-s3-policy.json)

3. - [ ] Set up a dedicated s3 object store for athena query results
   - [ ] [Create storage policy based on set up](/aws/aws-attach-roles)

## Kubecost Installation - Choose appropriate option.

1. **Kubecost Installed on Primary Cluster**  
   - [Installation Guide](https://www.ibm.com/docs/en/kubecost/self-hosted/2.x?topic=installation-kubecost-v2-installupgrade)  

   **Option A: Basic Installation**

   - [ ] [Minimal Install (No Federation)](/aws/aws-primary-minimal.yaml)

   **Option B: Enterprise with IRSA**
   - [ ] [Enteprise Federation with IRSA/EKS Pod Identities](/aws/aws-primary-federation-irsa.yaml)

   **Option C: Enterprise without IRSA**
   - [ ] [Enteprise Federation no IRSA](/aws/aws-primary-federation-no-irsa.yaml)

2. **Cloud Cost Integration Configured**  
   - [ ] [AWS Cloud Integration](https://www.ibm.com/docs/en/kubecost/self-hosted/2.x?topic=integrations-aws-cloud-billing-integration) 

   - [ ] [AWS Cloud Integration using IRSA/EKS Pod Identities](https://www.ibm.com/docs/en/kubecost/self-hosted/2.x?topic=integration-aws-cloud-using-irsaeks-pod-identities)

   - [Cloud Integration Config File](/aws/cloud-integration.json)

3. **Kubecost Installed on Secondary Cluster(s)**  
   
   **Option A: Without IRSA**
   - [ ] [ETL Federation Aggregator Configuration no IRSA](/aws/aws-secondary-no-irsa.yaml)

   **Option B: With IRSA**
   - [ ] [ETL Federation Aggregator Configuration with IRSA](/aws/aws-secondary-irsa.yaml)

## Optional Configuration
4. **Network Costs Daemonset Configured**  
   - [ ] [Configuration Guide](https://www.ibm.com/docs/en/kubecost/self-hosted/2.x?topic=configuration-network-cost)
  
   - [Network Cost Config](/aws/network-costs-enabled.yaml)

5. **SSO/SAML Enabled**
   
   **Option A: SAML Authentication**
   - [ ] [Configure SSO/SAML](https://www.ibm.com/docs/en/kubecost/self-hosted/2.x?topic=configuration-user-management-saml)

   **Option B: OIDC Authentication**
   - [ ] [Configure SSO/OIDC](https://www.ibm.com/docs/en/kubecost/self-hosted/2.x?topic=configuration-user-management-ssooidc)

   **Option C: Team Management**
   - [Minimal Install (No Federation)](/aws/aws-primary-minimal.yaml)