variable "namespace" {
  description = "Kubernetes namespace for Kubecost primary"
  type        = string
  default     = "kubecost"
}

variable "create_namespace" {
  description = "Whether to create the namespace"
  type        = bool
  default     = true
}

variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "kubecost-primary"
}

variable "chart_version" {
  description = "Kubecost Helm chart version (3.x+). Leave empty for latest"
  type        = string
  default     = "3.1.6"
  
  validation {
    condition     = var.chart_version == "" || can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+", var.chart_version))
    error_message = "Chart version must be empty or in format X.Y.Z"
  }
}

variable "cluster_name" {
  description = "Unique identifier for this primary cluster (required)"
  type        = string
  
  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "Cluster name must not be empty"
  }
}

variable "atomic_deployment" {
  description = "If true, upgrade process rolls back changes made in case of failed upgrade"
  type        = bool
  default     = true
}

# Storage Configuration
variable "create_storage_class" {
  description = "Whether to create a storage class for Kubecost"
  type        = bool
  default     = false
}

variable "storage_class_name" {
  description = "Name of the storage class to use"
  type        = string
  default     = "standard"
}

variable "storage_provisioner" {
  description = "Storage provisioner (e.g., kubernetes.io/aws-ebs, kubernetes.io/gce-pd)"
  type        = string
  default     = "kubernetes.io/aws-ebs"
}

variable "storage_class_parameters" {
  description = "Parameters for the storage class"
  type        = map(string)
  default     = {
    type = "gp3"
  }
}

variable "create_pvc" {
  description = "Whether to create a PVC for Kubecost data"
  type        = bool
  default     = true
}

variable "storage_size" {
  description = "Size of the persistent volume"
  type        = string
  default     = "32Gi"
}

# Federation Configuration
variable "enable_federation" {
  description = "Enable federation for multi-cluster deployments"
  type        = bool
  default     = false
}

variable "federation_s3_bucket" {
  description = "S3 bucket name for federated storage"
  type        = string
  default     = ""
}

variable "federation_s3_region" {
  description = "AWS region for S3 bucket"
  type        = string
  default     = "us-east-1"
}

variable "federation_s3_prefix" {
  description = "S3 prefix for federated data"
  type        = string
  default     = "kubecost"
}

variable "federation_s3_access_key" {
  description = "AWS access key for S3 bucket (leave empty to use IRSA/Workload Identity)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "federation_s3_secret_key" {
  description = "AWS secret key for S3 bucket (leave empty to use IRSA/Workload Identity)"
  type        = string
  default     = ""
  sensitive   = true
}

# Ingress Configuration
variable "ingress_enabled" {
  description = "Enable ingress for Kubecost UI"
  type        = bool
  default     = true
}

variable "ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = "nginx"
}

variable "ingress_annotations" {
  description = "Annotations for the ingress"
  type        = map(string)
  default     = {}
}

variable "ingress_hosts" {
  description = "List of ingress hosts"
  type        = list(string)
  default     = ["kubecost.example.com"]
}

variable "ingress_tls" {
  description = "TLS configuration for ingress"
  type        = list(object({
    secretName = string
    hosts      = list(string)
  }))
  default     = []
}

# Service Configuration
variable "service_type" {
  description = "Kubernetes service type (ClusterIP, LoadBalancer, NodePort)"
  type        = string
  default     = "ClusterIP"
  
  validation {
    condition     = contains(["ClusterIP", "LoadBalancer", "NodePort"], var.service_type)
    error_message = "Service type must be ClusterIP, LoadBalancer, or NodePort"
  }
}

variable "service_port" {
  description = "Service port"
  type        = number
  default     = 9090
}

variable "service_annotations" {
  description = "Annotations for the service"
  type        = map(string)
  default     = {}
}

# Resource Configuration
variable "primary_resources" {
  description = "Resource requests and limits for the Kubecost primary"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "500m"
      memory = "2Gi"
    }
    limits = {
      cpu    = "2000m"
      memory = "8Gi"
    }
  }
}

# Network Policy
variable "network_policy_enabled" {
  description = "Enable network policies"
  type        = bool
  default     = false
}

# Pod Placement
variable "node_selector" {
  description = "Node selector for pod assignment"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations for pod assignment"
  type = list(object({
    key      = string
    operator = string
    value    = optional(string)
    effect   = string
  }))
  default = []
}

variable "affinity" {
  description = "Affinity rules for pod assignment"
  type        = any
  default     = {}
}

# Pod Configuration
variable "pod_annotations" {
  description = "Annotations to add to the pods"
  type        = map(string)
  default     = {}
}

variable "pod_security_context" {
  description = "Security context for the pod"
  type        = any
  default = {
    runAsNonRoot = true
    runAsUser    = 1000
    fsGroup      = 1000
  }
}

variable "security_context" {
  description = "Security context for the container"
  type        = any
  default = {
    allowPrivilegeEscalation = false
    readOnlyRootFilesystem   = false
    runAsNonRoot             = true
    runAsUser                = 1000
    capabilities = {
      drop = ["ALL"]
    }
  }
}

# Additional Configuration
variable "additional_values" {
  description = "Additional Helm values to set (key-value pairs)"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}