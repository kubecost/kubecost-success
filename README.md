# Kubecost Enterprise Deployment Guide

![Kubecost Enterprise Architecture](/assets/KC-Cloud-Architecture.png)

This repository contains deployment guides and configuration templates for setting up Kubecost Enterprise across different environments. Kubecost provides real-time cost visibility and insights for Kubernetes workloads.

## Deployment Options

This guide covers four main deployment scenarios:

### 1. Azure Cloud Deployment
- Integrated with Azure cost reporting
- Azure storage account configuration
- Multi-cluster federation support
- [View Azure Deployment Guide](/azure/README.md)

### 2. On-Premises Deployment
- Self-hosted environment setup
- Air-gapped installation options
- Custom pricing model configuration
- [View On-Prem Deployment Guide](/on-prem/README.md)

### 3. AWS Cloud Deployment
- AWS cost and usage integration
- S3 bucket configuration
- Multi-cluster federation
- [View AWS Deployment Guide](/aws/README.md)

### 4. Google Cloud Deployment
- GCP billing data integration
- Cloud Storage bucket configuration
- GKE cluster integration
- Multi-cluster federation support
- [View GCP Deployment Guide](/gcp/README.md)

## Key Features

- **Multi-Cluster Support**: Centralized cost management across multiple Kubernetes clusters
- **Cloud Integration**: Native integration with major cloud providers' billing APIs and billing reports
- **Custom Pricing**: Support for custom pricing models in air-gapped environments
- **Long-term Storage**: Configurable ETL data retention using cloud or local storage
- **Authentication**: SSO/SAML integration options for enterprise environments

## Prerequisites

- Kubernetes clusters (version 1.21+). Kubernetes 1.31 is officially supported as of v2.
- Helm 3.13+
- Access to cloud provider resources (for cloud deployments)
- Storage backend and durable storage for metrics retention
- Network access to dedicated central object store(for multi-cluster deployments and long term storage)

## Quick Start

1. Choose your deployment scenario from the guides above
2. Follow the environment-specific prerequisites
3. Deploy Kubecost using provided configuration templates
4. Configure cloud integration (if applicable)
5. Set up authentication and access controls

## Support Resources

- [Official Kubecost Documentation](https://docs.kubecost.com/)
- [Helm Chart Reference](https://github.com/kubecost/cost-analyzer-helm-chart)
- [Troubleshooting Guide](https://docs.kubecost.com/troubleshooting)

