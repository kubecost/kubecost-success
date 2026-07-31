# Deployment Checklist - Azure with Workload Identity

This checklist covers deploying Kubecost Enterprise on AKS using **Azure AD Workload Identity** — the secretless authentication pattern that replaces storage access keys and client secrets with federated OIDC credentials. No secrets need to be stored in Kubernetes for storage or cloud integration access.

Refer to the standard [Azure README](./README.md) for the key-based deployment option.

---

## Prerequisites

### 1. AKS Cluster Requirements

Each AKS cluster (primary and agents) must have both features enabled. If your clusters already exist, enable them in-place:

```bash
az aks update \
  --resource-group <RESOURCE_GROUP> \
  --name <CLUSTER_NAME> \
  --enable-oidc-issuer \
  --enable-workload-identity
```

For new clusters, add both flags to `az aks create`.

- [ ] OIDC Issuer enabled on primary cluster
- [ ] Workload Identity enabled on primary cluster
- [ ] OIDC Issuer enabled on each agent cluster
- [ ] Workload Identity enabled on each agent cluster

Retrieve the OIDC issuer URL for each cluster — you will need it when creating federated credentials:

```bash
az aks show \
  --resource-group <RESOURCE_GROUP> \
  --name <CLUSTER_NAME> \
  --query "oidcIssuerProfile.issuerUrl" -o tsv
```

---

### 2. Create a Managed Identity

A single User-assigned Managed Identity can be reused across clusters, or you can create one per cluster.

```bash
az identity create \
  --name kubecost-identity \
  --resource-group <RESOURCE_GROUP> \
  --location <LOCATION>

# Save the clientId — needed for Helm values and federated credentials
az identity show \
  --name kubecost-identity \
  --resource-group <RESOURCE_GROUP> \
  --query clientId -o tsv
```

- [ ] Managed Identity created
- [ ] `clientId` recorded for use in Helm values

---

### 3. Grant Role Assignments

#### Storage account for ETL federation (federated-store)

```bash
az role assignment create \
  --assignee <MANAGED_IDENTITY_CLIENT_ID> \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/providers/Microsoft.Storage/storageAccounts/<STORAGE_ACCOUNT>
```

- [ ] `Storage Blob Data Contributor` granted on the ETL storage account

#### Subscription-level read for cloud cost integration (primary cluster only)

```bash
az role assignment create \
  --assignee <MANAGED_IDENTITY_CLIENT_ID> \
  --role "Reader" \
  --scope /subscriptions/<SUBSCRIPTION_ID>
```

- [ ] `Reader` granted on the subscription (primary cluster only)

---

### 4. Create Federated Identity Credentials

One federated credential is required per cluster, linking that cluster's OIDC issuer to the `kubecost` service account in the `kubecost` namespace.

```bash
az identity federated-credential create \
  --name kubecost-<CLUSTER_NAME> \
  --identity-name kubecost-identity \
  --resource-group <RESOURCE_GROUP> \
  --issuer <OIDC_ISSUER_URL> \
  --subject "system:serviceaccount:kubecost:kubecost-cost-analyzer" \
  --audience api://AzureADTokenExchange
```

Repeat for every cluster where Kubecost will be installed.

- [ ] Federated credential created for primary cluster
- [ ] Federated credential created for each agent cluster

---

## Storage Configuration

### 5. Create the ETL Storage Account and Container

If not already provisioned:

```bash
az storage account create \
  --name <STORAGE_ACCOUNT> \
  --resource-group <RESOURCE_GROUP> \
  --sku Standard_LRS

az storage container create \
  --name kubecost-etl \
  --account-name <STORAGE_ACCOUNT>
```

- [ ] Storage account provisioned
- [ ] Container created

### 6. Create the Federated Store Secret

Use [federated-store-workload-identity.yaml](./federated-store-workload-identity.yaml). Fill in `storage_account`, `container`, and `user_assigned_id` (the Managed Identity `clientId`), then create the secret on **every cluster**:

```bash
kubectl create secret generic federated-store \
  --from-file=federated-store.yaml=./federated-store-workload-identity.yaml \
  -n kubecost
```

- [ ] Secret created on primary cluster
- [ ] Secret created on each agent cluster

---

## Cloud Integration (Primary Cluster Only)

### 7. Generate Azure Cost Export

- [ ] [Export Azure cost report](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=integrations-azure-cloud-billing-integration#ariaid-title2)

### 8. Create the Cloud Integration Secret

The `AzureDefaultCredential` authorizer uses the Workload Identity token automatically — no keys or secrets required. Use [cloud-integration.json](./cloud-integration.json) (the `AzureDefaultCredential` block), fill in `subscriptionID`, `account`, and `container`, then:

```bash
kubectl create secret generic cloud-integration \
  --from-file=cloud-integration.json \
  -n kubecost
```

- [ ] `cloud-integration` secret created on primary cluster

---

## Kubecost Installation

### 9. Install on Primary Cluster

Use [values-azure-primary-workload-identity.yaml](./values-azure-primary-workload-identity.yaml). Set the following values:

| Value | Description |
|---|---|
| `global.clusterId` | Unique cluster name |
| `serviceAccount.annotations."azure.workload.identity/client-id"` | Managed Identity `clientId` |
| `global.additionalLabels."azure.workload.identity/use"` | Must be `"true"` for webhook injection |
| `cloudCost.enabled` | Set to `true` on primary |
| `kubecostProductConfigs.productKey.key` | License key (contact your account rep) |

```bash
helm upgrade --install kubecost \
  --repo https://kubecost.github.io/kubecost/ kubecost \
  --namespace kubecost --create-namespace \
  -f values-azure-primary-workload-identity.yaml \
  --set global.clusterId=<CLUSTER_NAME> \
  --set serviceAccount.annotations."azure\.workload\.identity/client-id"=<MANAGED_IDENTITY_CLIENT_ID> \
  --set global.additionalLabels."azure\.workload\.identity/use"=true \
  --set cloudCost.enabled=true \
  --set cloudCost.cloudIntegrationSecret=cloud-integration \
  --set kubecostProductConfigs.productKey.enabled=true \
  --set kubecostProductConfigs.productKey.key=<LICENSE_KEY>
```

- [ ] Kubecost installed on primary cluster
- [ ] Pods have `azure.workload.identity/use: "true"` label injected (verify with `kubectl get pods -n kubecost --show-labels`)
- [ ] Cloud cost data flowing (check Kubecost UI → Cloud Cost)

---

### 10. Install on Agent Cluster(s)

Use [values-azure-agent-workload-identity.yaml](./values-azure-agent-workload-identity.yaml). Set `global.clusterId` and the service account annotation for each cluster:

```bash
helm upgrade --install kubecost \
  --repo https://kubecost.github.io/kubecost/ kubecost \
  --namespace kubecost --create-namespace \
  -f values-azure-agent-workload-identity.yaml \
  --set global.clusterId=<CLUSTER_NAME> \
  --set serviceAccount.annotations."azure\.workload\.identity/client-id"=<MANAGED_IDENTITY_CLIENT_ID> \
  --set global.additionalLabels."azure\.workload\.identity/use"=true
```

- [ ] Kubecost installed on each agent cluster
- [ ] Pods have `azure.workload.identity/use: "true"` label (verify with `kubectl get pods -n kubecost --show-labels`)
- [ ] ETL pipeline verified: `/federated` directory created in the storage container

---

## Optional Configuration

### 11. Network Costs Daemonset

> **Note:** The network cost daemonset can experience higher CPU and memory usage in large environments with hundreds of thousands of unique containers per day.

- [ ] Review [Configuration Guide](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=configuration-network-cost)
- [ ] Apply [Network Cost Config](./network-costs-enabled.yaml)

### 12. Kubecost Actions (Continuous Right-sizing)

> ⚠️ Requires a v3 license key. Contact your Account Representative.

```bash
helm upgrade --install kubecost \
  --repo https://kubecost.github.io/kubecost/ kubecost \
  --namespace kubecost \
  -f https://raw.githubusercontent.com/kubecost/kubecost-success/refs/heads/main/api-guides/actions.md
```

### 13. SSO / SAML

- [ ] Review [SSO Documentation](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=configuration-user-management-ssooidc)
- [ ] Configure [OIDC](../custom/oidc-rbac.yaml)
- [ ] Configure [SAML](../custom/saml-rbac-enabled.yaml)
