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

# Namespace for Kubecost primary
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

# Storage class for Kubecost (if needed)
resource "kubernetes_storage_class" "kubecost" {
  count = var.create_storage_class ? 1 : 0

  metadata {
    name = var.storage_class_name
  }

  storage_provisioner = var.storage_provisioner
  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
  
  parameters = var.storage_class_parameters
}

# Persistent Volume Claim for Kubecost data
resource "kubernetes_persistent_volume_claim" "kubecost_data" {
  count = var.create_pvc ? 1 : 0

  metadata {
    name      = "kubecost-data"
    namespace = var.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "kubecost"
      "app.kubernetes.io/component"  = "primary"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    
    resources {
      requests = {
        storage = var.storage_size
      }
    }
    
    storage_class_name = var.create_storage_class ? kubernetes_storage_class.kubecost[0].metadata[0].name : var.storage_class_name
  }

  depends_on = [kubernetes_namespace.kubecost]
}

# Secret for federation S3 access (if using federation)
resource "kubernetes_secret" "federation_s3" {
  count = var.enable_federation && var.federation_s3_access_key != "" ? 1 : 0

  metadata {
    name      = "kubecost-federation-s3"
    namespace = var.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "kubecost"
      "app.kubernetes.io/component"  = "primary"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  data = {
    AWS_ACCESS_KEY_ID     = var.federation_s3_access_key
    AWS_SECRET_ACCESS_KEY = var.federation_s3_secret_key
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.kubecost]
}

# Helm release for Kubecost primary
resource "helm_release" "kubecost_primary" {
  name       = var.release_name
  repository = "https://kubecost.github.io/kubecost/"
  chart      = "kubecost"
  version    = var.chart_version
  namespace  = var.namespace

  wait          = true
  wait_for_jobs = true
  timeout       = 600
  atomic        = var.atomic_deployment

  create_namespace = false

  values = [
    yamlencode({
      # Kubecost 3.x primary cluster configuration
      global = {
        # Cluster identification (required in 3.x)
        clusterId = var.cluster_name
        
        # Federated storage configuration for 3.x
        federatedStorage = var.enable_federation ? {
          config = var.federation_s3_bucket != "" ? yamlencode({
            type = "S3"
            config = {
              bucket   = var.federation_s3_bucket
              endpoint = "s3.amazonaws.com"
              region   = var.federation_s3_region
              prefix   = var.federation_s3_prefix
            }
          }) : ""
        } : {}
        
        # Acknowledgment for 3.x (required for enterprise)
        acknowledged = true
      }

      # Enable aggregator for primary cluster
      aggregator = {
        enabled = true
      }
      
      # Enable frontend for primary cluster
      frontend = {
        enabled = true
      }
      
      # FinOps Agent enabled on primary too
      finopsagent = {
        enabled = true
      }

      # Persistent storage
      persistentVolume = {
        enabled = var.create_pvc
        size    = var.storage_size
        storageClass = var.create_storage_class ? kubernetes_storage_class.kubecost[0].metadata[0].name : var.storage_class_name
      }

      # Ingress configuration
      ingress = {
        enabled          = var.ingress_enabled
        className        = var.ingress_class_name
        annotations      = var.ingress_annotations
        hosts            = var.ingress_hosts
        tls              = var.ingress_tls
      }

      # Service configuration
      service = {
        type = var.service_type
        port = var.service_port
        annotations = var.service_annotations
      }

      # Resource configuration
      kubecostModel = {
        resources = {
          requests = {
            cpu    = var.primary_resources.requests.cpu
            memory = var.primary_resources.requests.memory
          }
          limits = {
            cpu    = var.primary_resources.limits.cpu
            memory = var.primary_resources.limits.memory
          }
        }
      }

      # Network policy
      networkPolicy = {
        enabled = var.network_policy_enabled
      }

      # Node selector
      nodeSelector = var.node_selector

      # Tolerations
      tolerations = var.tolerations

      # Affinity rules
      affinity = var.affinity

      # Pod annotations
      podAnnotations = var.pod_annotations

      # Security contexts
      podSecurityContext = var.pod_security_context
      securityContext    = var.security_context
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
    kubernetes_persistent_volume_claim.kubecost_data,
    kubernetes_secret.federation_s3
  ]
}

# ConfigMap to store primary metadata
resource "kubernetes_config_map" "kubecost_metadata" {
  metadata {
    name      = "kubecost-primary-metadata"
    namespace = var.namespace
    
    labels = {
      "app.kubernetes.io/name"       = "kubecost"
      "app.kubernetes.io/component"  = "primary"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  data = {
    cluster-name    = var.cluster_name
    deployment-date = timestamp()
    chart-version   = var.chart_version
    deployment-type = "primary"
    federation-enabled = tostring(var.enable_federation)
    managed-by      = "terraform"
  }

  depends_on = [kubernetes_namespace.kubecost]
}