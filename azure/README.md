# Kubecost Azure Deployment Guide (Self-hosted)

![Kubecost Enterprise Federation Architecture](/assets/azure-diagram.png)

It is recommended to deploy Kubecost Enterprise in this order. Configuring the Azure cloud integration will provide the most accurate data. Otherwise, it will default to predefined pricing and will not accurately reflect your Azure bill.

## Provision dependencies for Kubecost

1. **Create storage account to store all clusters ETL data in central object-store**

   - [ ] [Provision a storage account in Azure to store all clusters ETLs](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=configuration-azure-multi-cluster-storage)
     
   - [ ] Create a secret from the [federated-store.yaml](/azure/federated-store.yaml) which holds the values needed to access the storage account API. This will be needed on ALL clusters where Kubecost is installed.

       ```bash
       kubectl create secret generic federated-store --from-file=federated-store.yaml -n kubecost
       ```

2. **Generate Azure cost export for the cloud integration**

   - [ ] [Export Azure cost report](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=integrations-azure-cloud-billing-integration#ariaid-title2)

   - [ ] [Provide Access to Storage API using Access Key](/azure/cloud-integration.json)

   - [ ] Create a secret using the cloud-integration.json file. Must follow naming convention in the example below.

   Example:

   ```bash
   kubectl create secret generic cloud-integration --from-file=cloud-integration.json -n kubecost
   ```

## Kubecost Installation

3. **Install Kubecost on Primary Cluster with AWS cloud integration and federation** 

   **A few important Notes:** 
   **+A parallel install is recommended when upgrading from 2.x to 3.x for both the primary and agents. Users can perform a parallel install in the same namespace as the current v2 deployment or a new namespace**
   

   - [ ] Run helm install against the helm chart using the override [values-azure-primary.yaml](/azure/values-azure-primary.yaml) file with the following custom values configured. 

      @param global.clusterId=CLUSTER_NAME 
      @param global.federatedStorage.fileName=federated-store.yaml
      @param cloudCost.enabled=true
      @param cloudCost.cloudIntegration.secret=cloud-integration (only runs on primary)
      @param kubecostProductConfigs.productKey.enabled=true 
      @param kubecostProductConfigs.productKey.key=YOUR_PRODUCT_KEY (only runs on primary)

      Other options for the productKey are configuring a secret or mounting the key:

      @param kubecostProductConfigs.productKey.secret=product-key-secret (only runs on primary)
      @param kubecostProductConfigs.productKey.mountPath=/etc/kubecost/product-key (only runs on primary)


       ```bash
       helm upgrade --install kubecost \
       --repo https://kubecost.github.io/cost-analyzer/ cost-analyzer \
       --namespace kubecost -f values-azure-primary.yaml
       ```

   - [ ] Check [Installation Guide Reference](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=installation)  

5. **Install Kubecost on Secondary Cluster(s)**  

   - [ ] Create a secret from the [federated-store.yaml](/azure/federated-store.yaml) which holds the values needed to access the storage account API. This will be needed on ALL clusters where Kubecost is installed.

       ```bash
       kubectl create secret generic federated-store --from-file=federated-store.yaml -n kubecost
       ```

   - [ ] Configure [ETL Federation Aggregator](/azure/values-azure-secondary.yaml) with the following custom values:

         @param global.cluserId=CLUSTER_NAME
         @parama global.federatedStorage.fileName=federated-store.yaml

   - [ ] Run helm install against the helm chart using the override [values-azure-primary.yaml](/azure/values-azure-primary.yaml) file with custom values configured. 

      ```bash
       helm upgrade --install kubecost \
       --repo https://kubecost.github.io/cost-analyzer/ cost-analyzer \
       --namespace kubecost -f values-azure-secondary.yaml
       ```

## Optional Configuration

6. **Network Costs Daemonset Configured** 

Please Note: The network cost daemonset is not recommended for large environments where there are several hundred thousand or more unique containers running per day. 

   - [ ] Review [Configuration Guide](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=configuration-network-cost)
   - [ ] Apply [Network Cost Config](/azure/network-costs-enabled.yaml)

7. **SSO/SAML Enabled**
   - [ ] Review [SSO Documentation](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=configuration-user-management-ssooidc)
   - [ ] Configure [OIDC](/custom/oidc-rbac.yaml)
   - [ ] Configure [SAML](/custom/saml-rbac-enabled.yaml)

