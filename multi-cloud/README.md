# Kubecost Multi-Cloud Deployment Guide (Self-hosted)

This directory covers deploying Kubecost Enterprise 3.x across clusters that span **multiple cloud providers** — AWS, Azure, and/or GCP running simultaneously.

## Quick Start

Follow the **[Multi-Cloud Deployment Checklist](./multi-cloud-deployment-checklist.md)** for step-by-step instructions covering:

1. Choosing and provisioning a federated object store
2. Configuring billing exports per CSP (CUR, Azure Cost Export, GCP BigQuery)
3. Building the combined `cloud-integration.json` secret
4. Installing on the primary cluster (Aggregator + CloudCost)
5. Installing on agent clusters (FinOps Agent only)
6. Verifying federation across all clusters

## Files in This Directory

| File | Purpose |
|---|---|
| [`multi-cloud-deployment-checklist.md`](./multi-cloud-deployment-checklist.md) | Step-by-step deployment checklist |
| [`cloud-integration.json`](./cloud-integration.json) | Template for the combined multi-cloud billing integration secret |

## Related Provider Guides

For single-CSP deployments, see:
- [AWS](../aws/README.md)
- [Azure](../azure/README.md)
- [GCP](../gcp/README.md)

## References

- [Multi-Cloud Integrations (IBM Docs 3.x)](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=integrations-multi-cloud)
- [ETL Federation (IBM Docs 3.x)](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=cluster-etl-federation)
- [Long-Term Storage Configuration (IBM Docs 3.x)](https://www.ibm.com/docs/en/kubecost/self-hosted/3.x?topic=cluster-long-term-storage-configuration)
