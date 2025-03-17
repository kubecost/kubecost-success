# Kubecost Azure Deployment Guide (Self-hosted)

![Kubecost Enterprise Federation Architecture](/assets/azure-diagram.png)

It is recommended to deploy Kubecost Enterprise in this order. Configuring the Azure cloud integration will provide the most accurate data. Otherwise, it will default to predefined pricing and will not accurately reflect your Azure bill.

## Provision dependencies for Kubecost

1. **Create storage account to store all clusters ETL data in central object-store**

   - [ ] [Provision a storage account in Azure to store all clusters ETLs](https://docs.kubecost.com/install-and-configure/install/multi-cluster/long-term-storage-configuration/long-term-storage-azure)
     
   - [ ] Create a secret from the [object-store.yaml](/azure/object-store.yaml) which holds the values needed to access the storage account API. This will be needed on ALL clusters where Kubecost is installed.

       ```bash
       kubectl create secret generic federated-store --from-file=object-store.yaml -n kubecost
       ```

2. **Generate Azure cost export for the cloud integration**

   - [ ] [Export Azure cost report](https://docs.kubecost.com/install-and-configure/install/cloud-integration/azure-out-of-cluster#step-1-export-azure-cost-report)

   - [ ] [Provide Access to Storage API using Access Key](/azure/cloud-integration.json)

   - [ ] Create a secret using the cloud-integration.json file. Must follow naming convention in the example below.

   Example:

   ```bash
   kubectl create secret generic cloud-integration --from-file=cloud-integration.json -n kubecost
   ```

## Kubecost Installation

3. **Install Kubecost on Primary Cluster**  

   - [ ] Run helm install against the helm chart using the override [values-azure-primary.yaml](/azure/values-azure-primary.yaml) file with custom values configured. Set Values.kubecostProductConfigs.clusterName and 

       ```bash
       helm upgrade --install kubecost \
       --repo https://kubecost.github.io/cost-analyzer/ cost-analyzer \
       --namespace kubecost - values-azure-primary.yaml
       ```

   - [ ] Check [Installation Guide Reference](https://docs.kubecost.com/install-and-configure/install)  

5. **Install Kubecost on Secondary Cluster(s)**  

   - [ ] Create a secret from the [object-store.yaml](/azure/object-store.yaml) which holds the values needed to access the storage account API. This will be needed on ALL clusters where Kubecost is installed.

       ```bash
       kubectl create secret generic federated-store --from-file=object-store.yaml -n kubecost
       ```

   - [ ] Configure [ETL Federation Aggregator](/azure/secondary-cluster.yaml)

## Optional Configuration

6. **Network Costs Daemonset Configured** 

Please Note: The network cost daemonset is not recommended for large environments where there are several hundred thousand or more unique containers running per day. 

   - [ ] Review [Configuration Guide](https://docs.kubecost.com/install-and-configure/advanced-configuration/network-costs-configuration)
   - [ ] Apply [Network Cost Config](/azure/network-costs-enabled.yaml)

7. **SSO/SAML Enabled**
   - [ ] Review [SSO Documentation](https://docs.kubecost.com/install-and-configure/install/getting-started#sso-saml-rbac-oidc)
   - [ ] Configure [OIDC](/custom/oidc-rbac.yaml)
   - [ ] Configure [SAML](/custom/saml-rbac-enabled.yaml)
