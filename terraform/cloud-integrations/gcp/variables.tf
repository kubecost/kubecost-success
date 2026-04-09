variable "project_id" {
  description = "GCP Project ID"
  type        = string
  
  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project ID must not be empty"
  }
}

variable "service_account_id" {
  description = "Service account ID (must be 6-30 characters)"
  type        = string
  default     = "kubecost-cost-analyzer"
  
  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]{4,28}[a-z0-9])$", var.service_account_id))
    error_message = "Service account ID must be 6-30 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens"
  }
}

variable "service_account_display_name" {
  description = "Display name for the service account"
  type        = string
  default     = "Kubecost Cost Analyzer"
}

variable "billing_dataset_id" {
  description = "BigQuery dataset ID containing billing export data"
  type        = string
}

variable "billing_table_id" {
  description = "BigQuery table ID containing billing export data"
  type        = string
  default     = "gcp_billing_export_v1"
}

variable "billing_export_bucket" {
  description = "GCS bucket name for billing export (optional, for bucket-level permissions)"
  type        = string
  default     = ""
}

variable "kubecost_namespace" {
  description = "Kubernetes namespace where Kubecost is deployed"
  type        = string
  default     = "kubecost"
}

variable "kubernetes_service_account" {
  description = "Kubernetes service account name for Kubecost"
  type        = string
  default     = "kubecost-cost-analyzer"
}

variable "enable_workload_identity" {
  description = "Enable GKE Workload Identity (recommended for GKE clusters)"
  type        = bool
  default     = false
}

variable "create_kubernetes_secret" {
  description = "Create Kubernetes secret with service account key (not needed if using Workload Identity)"
  type        = bool
  default     = true
}

variable "create_kubernetes_service_account" {
  description = "Create Kubernetes service account with Workload Identity annotation"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Labels to apply to GCP resources"
  type        = map(string)
  default     = {}
}