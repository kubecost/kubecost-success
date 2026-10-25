# Deployment Checklist - Multi-Cloud

This checklist covers deploying Kubecost Enterprise 3.x across clusters that span **multiple cloud providers** (AWS, Azure, and/or GCP). The multi-cloud pattern uses a single federated object store and a combined `cloud-integration.json` that references billing exports from every CSP.

> **Kubecost Enterprise required.** Multi-cloud integrations, federated storage, and the Aggregator are Enterprise-only features. Contact your Account Representative for a license key.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Shared Object Store                   │
│           (S3 / Azure Blob / GCS bucket)                │
│   /federated/<cluster-id>   /diagnostics/<cluster-id>  │
└──────────────┬───────────────────────────────┬──────────┘
               │                               │
    ┌──────────▼──────────┐         ┌──────────▼──────────┐
    │   Primary Cluster   │         │   Agent Cluster(s)  │
    │  (any CSP)          │         │  (any CSP)          │
    │  - Aggregator       │         │  - FinOps Agent     │
    │  - CloudCost pod    │         │  - federatedCluster │
    │  - UI / API         │         │                     │
    └─────────────────────┘         └─────────────────────┘
```

- **One** primary cluster hosts the Aggregator and serves the Kubecost UI.
- **All** clusters (primary + agents) push ETL data to the same shared bucket.
- **One** `cloud-integration.json` secret on the primary cluster contains billing credentials for every CSP.

---

## Step 1: Choose a Federated Object Store

Pick **one** cloud provider to host the shared storage bucket. All clusters must be able to write to it.

| Hosting CSP | Storage Type | Auth Options |
|---|---|---|
| AWS | S3 | IRSA / EKS Pod Identity / Access Key |
| Azure | Blob Storage | Workload Identity / Storage Access Key / SAS Token |
| GCP | Cloud Storage | Workload Identity Federation / Service Account Key |

Configure the `federated-store.yaml` for your chosen storage type. The file **must** be named `federated-store.yaml` when creating the Kubernetes secret.

### AWS S3 (IRSA — recommended)

```yaml
# federated-store.yaml
type: S3
config:
  bucket: <BUCKET_NAME>
  region: <AWS_REGION>
  aws_sdk_auth: true
```

- [ ] S3 bucket created
- [ ] IAM policy granting `s3:GetObject`, `s3:PutObject`, `s3:ListBucket`, `s3:DeleteObject` on the bucket attached to Kubecost's service account role
- [ ] IRSA or EKS Pod Identity configured ([AWS Multi-Cluster Storage](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=configuration-aws-multi-cluster-storage))

### Azure Blob Storage (Workload Identity — recommended)

```yaml
# federated-store.yaml (Workload Identity)
type: AZURE
config:
  storage_account: <STORAGE_ACCOUNT>
  container: <CONTAINER_NAME>
  endpoint_suffix: core.windows.net
  use_workload_identity: true
  user_assigned_id: <MANAGED_IDENTITY_CLIENT_ID>
```

- [ ] Storage account and container provisioned
- [ ] `Storage Blob Data Contributor` role assigned to Managed Identity on the container
- [ ] Federated Identity Credentials created for each cluster OIDC issuer ([Azure Multi-Cluster Storage](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=configuration-azure-multi-cluster-storage))

### GCP Cloud Storage (Workload Identity Federation — recommended)

```yaml
# federated-store.yaml
type: GCS
config:
  bucket: <GCS_BUCKET_NAME>
```

- [ ] GCS bucket created
- [ ] GCP service account with `roles/storage.objectAdmin` on the bucket
- [ ] Workload Identity binding: `NAMESPACE/kubecost-cost-analyzer` → GCP service account ([GCP Multi-Cluster Storage](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=configuration-gcp-long-term-storage))

---

## Step 2: Create the Federated Store Secret (All Clusters)

Create this secret in the `kubecost` namespace on **every** cluster where Kubecost will be installed.

```bash
kubectl create secret generic federated-store \
  --from-file=federated-store.yaml=./federated-store.yaml \
  -n kubecost
```

- [ ] `federated-store` secret created on primary cluster
- [ ] `federated-store` secret created on each agent cluster

---

## Step 3: Configure Cloud Billing Exports (Per CSP)

Each CSP requires a billing export to be set up before the cloud integration will work. Complete the steps for each CSP in your environment.

### AWS — Cost and Usage Report (CUR)

- [ ] [Generate AWS CUR](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=integrations-aws-cloud-billing-integration) — export to S3, Athena-enabled
- [ ] Athena database, table, and workgroup noted
- [ ] CUR S3 bucket name and Athena results bucket noted
- [ ] IAM policy for CUR + Athena access created ([policy template](../aws/cloud-integration.json))

### Azure — Cost Management Export

- [ ] [Export Azure cost report](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=integrations-azure-cloud-billing-integration) — Daily export of month-to-date costs, Amortized, no file partitioning
- [ ] Export storage account, container, and subscription ID noted

### GCP — BigQuery Billing Export

- [ ] [Enable GCP billing export to BigQuery](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=integrations-gcp-cloud-billing-integration)
- [ ] BigQuery dataset and project ID noted
- [ ] GCP service account with `roles/bigquery.user` and `roles/bigquery.dataViewer` on the billing dataset

---

## Step 4: Build the Multi-Cloud Integration Secret (Primary Cluster Only)

The `cloud-integration.json` secret lives on the **primary cluster only** and contains billing credentials for every CSP. Use [cloud-integration.json](./cloud-integration.json) as your template — include only the CSP blocks relevant to your environment.

```bash
kubectl create secret generic cloud-integration \
  --from-file=cloud-integration.json \
  -n kubecost
```

See [Multi-Cloud Integrations](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=integrations-multi-cloud) for the full field reference per CSP.

- [ ] `cloud-integration.json` populated for all applicable CSPs
- [ ] `cloud-integration` secret created on primary cluster

---

## Step 5: Install Kubecost on the Primary Cluster

The primary cluster runs the Aggregator, the CloudCost pod, and the Kubecost UI. It must have `cloudCost.enabled: true` and access to the `cloud-integration` secret.

> **3.x note:** `global.clusterId` is the single source of cluster identity in 3.x, replacing the old `kubecostProductConfigs.clusterName` and `prometheus.server.global.external_labels.cluster_id`. `global.acknowledged: true` is required to confirm awareness of 3.x breaking changes.

```bash
helm upgrade --install kubecost \
  --repo https://kubecost.github.io/kubecost/ kubecost \
  --namespace kubecost --create-namespace \
  --set global.clusterId=<PRIMARY_CLUSTER_NAME> \
  --set global.acknowledged=true \
  --set cloudCost.enabled=true \
  --set cloudCost.cloudIntegrationSecret=cloud-integration \
  --set kubecostProductConfigs.productKey.enabled=true \
  --set kubecostProductConfigs.productKey.key=<LICENSE_KEY> \
  -f <primary-values.yaml>
```

Key values for the primary cluster:

| Helm Value | Description |
|---|---|
| `global.clusterId` | Unique cluster name — must match across all metric sources |
| `global.acknowledged` | Must be `true` to confirm 3.x migration awareness |
| `cloudCost.enabled` | `true` on primary only |
| `cloudCost.cloudIntegrationSecret` | Name of the `cloud-integration` secret |
| `kubecostProductConfigs.productKey.enabled` | `true` |
| `kubecostProductConfigs.productKey.key` | Enterprise license key |

See the provider-specific primary values files for a complete starting point:
- AWS (IRSA): [`aws/clusters-using-irsa-eks-pod-identities/aws-primary-federation-irsa.yaml`](../aws/clusters-using-irsa-eks-pod-identities/aws-primary-federation-irsa.yaml)
- Azure: [`azure/values-azure-primary-workload-identity.yaml`](../azure/values-azure-primary-workload-identity.yaml)
- GCP: [`gcp/values-gcp-primary.yaml`](../gcp/values-gcp-primary.yaml)

- [ ] Kubecost installed on primary cluster
- [ ] Aggregator pod running (`kubectl get pods -n kubecost`)
- [ ] `/federated/<cluster-id>` directory created in the shared bucket
- [ ] Cloud cost data flowing (Kubecost UI → Cloud Cost Explorer)

---

## Step 6: Install Kubecost on Agent Cluster(s)

Agent clusters run only the FinOps Agent — no Aggregator, no CloudCost. They push ETL data to the shared bucket for the primary to aggregate.

```bash
helm upgrade --install kubecost \
  --repo https://kubecost.github.io/kubecost/ kubecost \
  --namespace kubecost --create-namespace \
  --set global.clusterId=<AGENT_CLUSTER_NAME> \
  --set global.acknowledged=true \
  -f <agent-values.yaml>
```

Key values for agent clusters:

| Helm Value | Description |
|---|---|
| `global.clusterId` | Unique cluster name — must be different on every cluster |
| `global.acknowledged` | Must be `true` |
| `cloudCost.enabled` | `false` (omit or leave default) |
| `kubecostProductConfigs.productKey.enabled` | `false` on agents |

See the provider-specific agent values files:
- AWS (IRSA): [`aws/clusters-using-irsa-eks-pod-identities/aws-kubecost-agent-irsa.yaml`](../aws/clusters-using-irsa-eks-pod-identities/aws-kubecost-agent-irsa.yaml)
- Azure: [`azure/values-azure-agent-workload-identity.yaml`](../azure/values-azure-agent-workload-identity.yaml)
- GCP: [`gcp/values-gcp-secondary.yaml`](../gcp/values-gcp-secondary.yaml)

- [ ] Kubecost installed on each agent cluster
- [ ] `/federated/<cluster-id>` directory created in the shared bucket for each agent
- [ ] Agent cluster(s) visible in Kubecost UI (primary) → Settings → Multi-Cluster Diagnostics

---

## Step 7: Verify Federation

```bash
# Check that each cluster has written its ETL data to the shared bucket
# AWS S3 example:
aws s3 ls s3://<BUCKET_NAME>/federated/

# Azure example:
az storage blob list \
  --account-name <STORAGE_ACCOUNT> \
  --container-name <CONTAINER_NAME> \
  --prefix federated/ \
  --output table

# GCP example:
gsutil ls gs://<GCS_BUCKET_NAME>/federated/
```

- [ ] `/federated/<cluster-id>` subdirectory present for **each** cluster
- [ ] All clusters visible in Kubecost UI (Allocations / Assets show data from all clusters)
- [ ] Multi-Cluster Diagnostics show healthy status for each agent

---

## Optional Configuration

### Network Costs Daemonset

> **Note:** The network cost daemonset can experience higher CPU and memory usage in large environments with hundreds of thousands of unique containers per day.

- [ ] Review [Configuration Guide](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=configuration-network-cost)
- [ ] Apply the network costs config for the relevant provider:
  - AWS: [`aws/network-costs-enabled.yaml`](../aws/network-costs-enabled.yaml)
  - Azure: [`azure/network-costs-enabled.yaml`](../azure/network-costs-enabled.yaml)

### Kubecost Actions (Continuous Right-sizing)

> ⚠️ Requires a v3 license key. Contact your Account Representative.

- [ ] Review [Kubecost Actions documentation](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=configuration-kubecost-actions)
- [ ] Enable on primary cluster via your primary values file

### SSO / SAML

- [ ] Review [SSO Documentation](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=configuration-user-management-ssooidc)
- [ ] Configure [OIDC](../custom/oidc-rbac.yaml)
- [ ] Configure [SAML](../custom/saml-rbac-enabled.yaml)

---

## Troubleshooting

| Symptom | Check |
|---|---|
| `/federated` directory not created | FinOps Agent logs: `kubectl logs -n kubecost -l app=finops-agent` — verify bucket credentials and reachability |
| Cloud cost data not appearing | CloudCost pod logs: `kubectl logs -n kubecost -l app=kubecost-cloud-cost` — verify `cloud-integration` secret and billing export is populated |
| Agent cluster not visible in UI | Diagnostics pod logs on primary; verify `global.clusterId` is unique and matches the value used when creating the bucket secret |
| `helm upgrade` blocked by checks | Review [Helm Checks](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=checks-helm) for 3.x breaking changes; ensure `global.acknowledged: true` is set |
