output "application_id" {
  description = "Azure AD Application (Client) ID"
  value       = azuread_application.kubecost.client_id
}

output "application_object_id" {
  description = "Azure AD Application Object ID"
  value       = azuread_application.kubecost.object_id
}

output "service_principal_id" {
  description = "Service Principal Object ID"
  value       = azuread_service_principal.kubecost.object_id
}

output "tenant_id" {
  description = "Azure Tenant ID"
  value       = var.tenant_id
}

output "subscription_id" {
  description = "Azure Subscription ID"
  value       = data.azurerm_subscription.current.subscription_id
}

output "client_secret" {
  description = "Azure AD Application Client Secret (sensitive)"
  value       = azuread_service_principal_password.kubecost.value
  sensitive   = true
}

output "kubernetes_secret_name" {
  description = "Name of the Kubernetes secret containing Azure credentials"
  value       = kubernetes_secret.azure_credentials.metadata[0].name
}

output "integration_config" {
  description = "Azure integration configuration details"
  value = {
    tenant_id           = var.tenant_id
    subscription_id     = data.azurerm_subscription.current.subscription_id
    application_id      = azuread_application.kubecost.client_id
    storage_account     = var.storage_account_name
    storage_container   = var.storage_container_name
    azure_cloud         = var.azure_cloud
    offer_durable_id    = var.offer_durable_id
  }
}

output "next_steps" {
  description = "Next steps for completing the integration"
  value = <<-EOT
    Azure Integration Setup Complete!
    
    Next Steps:
    1. Set up Cost Export in Azure Portal:
       - Go to Cost Management + Billing > Exports
       - Create a new export with the following settings:
         * Export type: Daily export of month-to-date costs
         * Storage account: ${var.storage_account_name != "" ? var.storage_account_name : "<your-storage-account>"}
         * Container: ${var.storage_container_name != "" ? var.storage_container_name : "<your-container>"}
         * Format: CSV
    
    2. Verify Service Principal permissions:
       - Reader role on subscription: ✓
       - Cost Management Reader role on subscription: ✓
       ${var.storage_account_id != "" ? "- Storage Blob Data Reader on storage account: ✓" : ""}
    
    3. Update Kubecost Helm values to use this integration:
       - Azure credentials secret has been created: kubecost-azure-credentials
       - Reference this secret in your Kubecost configuration
    
    4. Verify integration in Kubecost UI:
       - Navigate to Settings > Cloud Integrations
       - Check Azure integration status
    
    Application (Client) ID: ${azuread_application.kubecost.client_id}
    Tenant ID: ${var.tenant_id}
    Subscription ID: ${data.azurerm_subscription.current.subscription_id}
    
    Note: Client secret expires in ${var.client_secret_expiration}. Set a reminder to rotate it before expiration.
  EOT
}