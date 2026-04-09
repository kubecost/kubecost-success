variable "namespace" {
  description = "Kubernetes namespace for Kubecost agent"
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
  default     = "kubecost-agent"
}

variable "chart_version" {
  description = "Kubecost Helm chart version (3.x). Leave empty for latest"
  type        = string
  default     = "3.1.6"
}

variable "cluster_name" {
  description = "Unique identifier for this cluster (required)"
  type        = string
  
  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "Cluster name must not be empty"
  }
}

variable "kubecost_token" {
  description = "Kubecost SaaS agent token provided by IBM (optional for 3.x with federated storage)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "kubecost_primary_url" {
  description = "URL of the primary Kubecost instance hosted by IBM (optional for 3.x with federated storage)"
  type        = string
  default     = ""
}

variable "federated_storage_config" {
  description = "Federated storage configuration for Kubecost 3.x SaaS deployment. Should be a YAML string with S3 bucket configuration provided by IBM."
  type        = string
  default     = ""
  sensitive   = true
}

variable "atomic_deployment" {
  description = "If true, upgrade process rolls back changes made in case of failed upgrade"
  type        = bool
  default     = true
}

variable "agent_resources" {
  description = "Resource requests and limits for the Kubecost agent"
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
      cpu    = "200m"
      memory = "512Mi"
    }
    limits = {
      cpu    = "1000m"
      memory = "2Gi"
    }
  }
}

variable "network_policy_enabled" {
  description = "Enable network policies for the agent"
  type        = bool
  default     = false
}

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

variable "pod_annotations" {
  description = "Annotations to add to the agent pods"
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
    readOnlyRootFilesystem   = true
    runAsNonRoot             = true
    runAsUser                = 1000
    capabilities = {
      drop = ["ALL"]
    }
  }
}

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