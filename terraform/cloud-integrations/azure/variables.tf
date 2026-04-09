variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  
  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.tenant_id))
    error_message = "Tenant ID must be a valid UUID"
  }
}

variable "application_name" {
  description = "Name for the Azure AD application"
  type        = string
  default     = "kubecost-cost-analyzer"
}

variable "client_secret_expiration" {
  description = "Client secret expiration duration (e.g., '8760h' for 1 year)"
  type        = string
  default     = "8760h"
}

variable "kubecost_namespace" {
  description = "Kubernetes namespace where Kubecost is deployed"
  type        = string
  default     = "kubecost"
}

variable "storage_account_id" {
  description = "Azure Storage Account resource ID for cost export data (optional)"
  type        = string
  default     = ""
}

variable "storage_account_name" {
  description = "Azure Storage Account name for cost export data"
  type        = string
  default     = ""
}

variable "storage_container_name" {
  description = "Azure Storage Container name for cost export data"
  type        = string
  default     = ""
}

variable "storage_access_key" {
  description = "Azure Storage Account access key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "container_path" {
  description = "Path within the storage container for cost export data"
  type        = string
  default     = ""
}

variable "azure_cloud" {
  description = "Azure cloud environment (AzurePublicCloud, AzureUSGovernmentCloud, AzureChinaCloud, AzureGermanCloud)"
  type        = string
  default     = "AzurePublicCloud"
  
  validation {
    condition     = contains(["AzurePublicCloud", "AzureUSGovernmentCloud", "AzureChinaCloud", "AzureGermanCloud"], var.azure_cloud)
    error_message = "Azure cloud must be one of: AzurePublicCloud, AzureUSGovernmentCloud, AzureChinaCloud, AzureGermanCloud"
  }
}

variable "offer_durable_id" {
  description = "Azure Offer Durable ID (e.g., MS-AZR-0003P for Pay-As-You-Go)"
  type        = string
  default     = "MS-AZR-0003P"
}

variable "configure_rate_card" {
  description = "Whether to configure Azure Rate Card API access"
  type        = bool
  default     = false
}

variable "currency" {
  description = "Currency code for pricing (e.g., USD, EUR, GBP)"
  type        = string
  default     = "USD"
}

variable "region" {
  description = "Azure region for pricing (e.g., US, EU, UK)"
  type        = string
  default     = "US"
}

variable "tags" {
  description = "Tags to apply to Azure resources"
  type        = map(string)
  default     = {}
}