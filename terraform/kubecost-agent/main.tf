terraform {
  required_version = ">= 1.0"
  
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

# Namespace for Kubecost agent
resource "kubernetes_namespace" "kubecost" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
    
    labels = {
      name                                = var.namespace
      "app.kubernetes.io/managed-by"      = "terraform"
      "app.kubernetes.io/part-of"         = "kubecost"
    }
  }
}

# Secret for Kubecost SaaS token
resource "kubernetes_secret" "kubecost_token" {
  metadata {
    name      = "kubecost-token"
    namespace = var.namespace
  }

  data = {
    token = var.kubecost_token
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.kubecost]
}

# Helm release for Kubecost agent
resource "helm_release" "kubecost_agent" {
  name       = var.release_name
  repository = "https://kubecost.github.io/kubecost/"
  chart      = "kubecost"
  version    = var.chart_version
  namespace  = var.namespace

  # Wait for resources to be ready
  wait          = true
  wait_for_jobs = true
  timeout       = 600

  # Atomic ensures rollback on failure
  atomic = var.atomic_deployment

  # Create namespace if it doesn't exist
  create_namespace = false

  # Values for Kubecost 3.x SaaS agent configuration
  values = [
    yamlencode({
      global = {
        # Cluster identification (required in 3.x)
        clusterId = var.cluster_name
        
        # Federated storage configuration for SaaS
        federatedStorage = {
          config = var.federated_storage_config
        }
        
        # Acknowledgment for 3.x upgrade (required for enterprise)
        acknowledged = true
      }

      # FinOps Agent configuration (replaces old agent settings)
      finopsagent = {
        enabled = true
        
        image = {
          repository = "ibm-finops/agent"
          registry   = "icr.io"
        }
        
        # Resource configuration for FinOps agent
        resources = {
          requests = {
            cpu    = var.agent_resources.requests.cpu
            memory = var.agent_resources.requests.memory
          }
          limits = {
            cpu    = var.agent_resources.limits.cpu
            memory = var.agent_resources.limits.memory
          }
        }
        
        # Node selector
        nodeSelector = var.node_selector
        
        # Tolerations
        tolerations = var.tolerations
        
        # Affinity
        affinity = var.affinity
      }

      # Disable components not needed for agent-only deployment
      aggregator = {
        enabled = false
      }
      
      frontend = {
        enabled = false
      }
      
      cloudCost = {
        enabled = false
      }
      
      clusterController = {
        enabled = false
      }
      
      forecasting = {
        enabled = false
      }

      # Network policy
      networkPolicy = {
        enabled = var.network_policy_enabled
      }

      # Network policy
      networkPolicy = {
        enabled = var.network_policy_enabled
      }
    })
  ]

  # Additional custom values
  dynamic "set" {
    for_each = var.additional_values
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    kubernetes_namespace.kubecost,
    kubernetes_secret.kubecost_token
  ]
}

# ConfigMap to store cluster metadata
resource "kubernetes_config_map" "kubecost_metadata" {
  metadata {
    name      = "kubecost-agent-metadata"
    namespace = var.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "kubecost"
      "app.kubernetes.io/component"  = "agent"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  data = {
    cluster-name    = var.cluster_name
    deployment-date = timestamp()
    chart-version   = var.chart_version
    managed-by      = "terraform"
  }

  depends_on = [kubernetes_namespace.kubecost]
}