terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# Get current Azure subscription
data "azurerm_subscription" "current" {}

# Azure AD Application for Kubecost
resource "azuread_application" "kubecost" {
  display_name = var.application_name
  
  tags = [
    "kubecost",
    "cost-management",
    "managed-by-terraform"
  ]
}

# Service Principal for the application
resource "azuread_service_principal" "kubecost" {
  client_id = azuread_application.kubecost.client_id
  
  tags = [
    "kubecost",
    "cost-management",
    "managed-by-terraform"
  ]
}

# Service Principal Password (Client Secret)
resource "azuread_service_principal_password" "kubecost" {
  service_principal_id = azuread_service_principal.kubecost.id
  end_date_relative    = var.client_secret_expiration
}

# Role Assignment: Reader on Subscription
resource "azurerm_role_assignment" "reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.kubecost.object_id
}

# Role Assignment: Cost Management Reader on Subscription
resource "azurerm_role_assignment" "cost_management_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Cost Management Reader"
  principal_id         = azuread_service_principal.kubecost.object_id
}

# Optional: Storage Account access for export data
resource "azurerm_role_assignment" "storage_blob_reader" {
  count = var.storage_account_id != "" ? 1 : 0
  
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azuread_service_principal.kubecost.object_id
}

# Kubernetes Secret for Azure credentials
resource "kubernetes_secret" "azure_credentials" {
  metadata {
    name      = "kubecost-azure-credentials"
    namespace = var.kubecost_namespace
    
    labels = {
      "app.kubernetes.io/name"       = "kubecost"
      "app.kubernetes.io/component"  = "cost-analyzer"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  
  data = {
    AZURE_TENANT_ID       = var.tenant_id
    AZURE_CLIENT_ID       = azuread_application.kubecost.client_id
    AZURE_CLIENT_SECRET   = azuread_service_principal_password.kubecost.value
    AZURE_SUBSCRIPTION_ID = data.azurerm_subscription.current.subscription_id
  }
  
  type = "Opaque"
}

# ConfigMap for Azure integration configuration
resource "kubernetes_config_map" "azure_integration" {
  metadata {
    name      = "kubecost-azure-integration"
    namespace = var.kubecost_namespace
    
    labels = {
      "app.kubernetes.io/name"       = "kubecost"
      "app.kubernetes.io/component"  = "cost-analyzer"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  
  data = {
    "azure-config.json" = jsonencode({
      provider                = "azure"
      description             = "Azure Cost Integration"
      azureSubscriptionID     = data.azurerm_subscription.current.subscription_id
      azureTenantID           = var.tenant_id
      azureClientID           = azuread_application.kubecost.client_id
      azureClientSecret       = azuread_service_principal_password.kubecost.value
      azureStorageAccount     = var.storage_account_name
      azureStorageContainer   = var.storage_container_name
      azureStorageAccessKey   = var.storage_access_key
      azureContainerPath      = var.container_path
      azureCloud              = var.azure_cloud
      azureOfferDurableID     = var.offer_durable_id
    })
  }
}

# ConfigMap for Azure rate card configuration (optional)
resource "kubernetes_config_map" "azure_rate_card" {
  count = var.configure_rate_card ? 1 : 0
  
  metadata {
    name      = "kubecost-azure-rate-card"
    namespace = var.kubecost_namespace
    
    labels = {
      "app.kubernetes.io/name"       = "kubecost"
      "app.kubernetes.io/component"  = "cost-analyzer"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  
  data = {
    "rate-card-config.json" = jsonencode({
      azureSubscriptionID = data.azurerm_subscription.current.subscription_id
      azureTenantID       = var.tenant_id
      azureClientID       = azuread_application.kubecost.client_id
      azureClientSecret   = azuread_service_principal_password.kubecost.value
      azureOfferDurableID = var.offer_durable_id
      azureCurrency       = var.currency
      azureRegion         = var.region
    })
  }
}