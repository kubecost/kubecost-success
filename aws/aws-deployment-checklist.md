# Deployment Checklist - AWS

It is recommended to deploy Kubecost Enterprise in this order to improve time to value. Configuring the AWS cloud integration will provide the most accurate data. Otherwise, it will default to on-demand public pricing and will not accurately reflect your AWS bill.

## Kubecost Installation
1. **Kubecost Installed on Primary Cluster**  
   - [Installation Guide](https://docs.kubecost.com/install-and-configure/install)  
   - [Cost Analyzer Helm Chart Values](/aws/primary-cluster.yaml)

2. **Cloud Cost Integration Configured**  
   - [AWS Cloud Integration](https://docs.kubecost.com/install-and-configure/install/cloud-integration/aws-cloud-integrations)  
   - [Cloud Integration Config File](/aws/cloud-integration.json)

3. **Kubecost Installed on Secondary Cluster(s)**  
   - [ETL Federation Aggregator Configuration](/aws/secondary-cluster.yaml)

## Optional Configuration
4. **Network Costs Daemonset Configured**  
   - [Configuration Guide](https://docs.kubecost.com/install-and-configure/advanced-configuration/network-costs-configuration)
   - [Network Cost Config](/aws/network-costs-enabled.yaml)

5. **SSO/SAML Enabled**
   - [SSO Documentation](https://docs.kubecost.com/install-and-configure/install/getting-started#sso-saml-rbac-oidc)
   - [OIDC](/custom/oidc-rbac.yaml)
   - [SAML](/custom/saml-rbac-enabled.yaml)

