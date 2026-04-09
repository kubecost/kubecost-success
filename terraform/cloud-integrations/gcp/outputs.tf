output "service_account_email" {
  description = "Email address of the created service account"
  value       = google_service_account.kubecost.email
}

output "service_account_id" {
  description = "ID of the created service account"
  value       = google_service_account.kubecost.account_id
}

output "service_account_unique_id" {
  description = "Unique ID of the created service account"
  value       = google_service_account.kubecost.unique_id
}

output "service_account_key_id" {
  description = "ID of the service account key"
  value       = google_service_account_key.kubecost.id
}

output "service_account_private_key" {
  description = "Private key for the service account (base64 encoded, sensitive)"
  value       = google_service_account_key.kubecost.private_key
  sensitive   = true
}

output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "billing_dataset_id" {
  description = "BigQuery dataset ID for billing data"
  value       = var.billing_dataset_id
}

output "kubernetes_secret_name" {
  description = "Name of the Kubernetes secret containing GCP credentials"
  value       = var.create_kubernetes_secret ? kubernetes_secret.gcp_credentials[0].metadata[0].name : null
}

output "kubernetes_service_account_name" {
  description = "Name of the Kubernetes service account (if Workload Identity is enabled)"
  value       = var.enable_workload_identity && var.create_kubernetes_service_account ? kubernetes_service_account.kubecost[0].metadata[0].name : var.kubernetes_service_account
}

output "workload_identity_enabled" {
  description = "Whether Workload Identity is enabled"
  value       = var.enable_workload_identity
}

output "integration_config" {
  description = "GCP integration configuration details"
  value = {
    project_id              = var.project_id
    service_account_email   = google_service_account.kubecost.email
    billing_dataset_id      = var.billing_dataset_id
    billing_table_id        = var.billing_table_id
    workload_identity       = var.enable_workload_identity
  }
}

output "next_steps" {
  description = "Next steps for completing the integration"
  value = <<-EOT
    GCP Integration Setup Complete!
    
    Next Steps:
    1. Set up BigQuery Billing Export:
       - Go to Billing → Billing Export
       - Enable "BigQuery export"
       - Select dataset: ${var.billing_dataset_id}
       - Wait for data to populate (can take 24-48 hours)
    
    2. Verify Service Account permissions:
       - BigQuery Data Viewer: ✓
       - BigQuery Job User: ✓
       - Compute Viewer: ✓
       ${var.billing_export_bucket != "" ? "- Storage Object Viewer on bucket: ✓" : ""}
    
    3. ${var.enable_workload_identity ? "Workload Identity Configuration:" : "Service Account Key Configuration:"}
       ${var.enable_workload_identity ? 
         "- Kubernetes service account annotated with GCP service account\n       - Use service account: ${var.kubernetes_service_account}" :
         "- Kubernetes secret created: kubecost-gcp-credentials\n       - Reference this secret in your Kubecost configuration"}
    
    4. Update Kubecost Helm values:
       ${var.enable_workload_identity ?
         "serviceAccount:\n         create: false\n         name: ${var.kubernetes_service_account}" :
         "kubecostProductConfigs:\n         gcpSecretName: kubecost-gcp-credentials"}
    
    5. Verify integration in Kubecost UI:
       - Navigate to Settings → Cloud Integrations
       - Check GCP integration status
    
    Service Account: ${google_service_account.kubecost.email}
    Project ID: ${var.project_id}
    BigQuery Dataset: ${var.billing_dataset_id}
    ${var.enable_workload_identity ? "Workload Identity: Enabled" : "Authentication: Service Account Key"}
    
    Note: BigQuery billing data may take 24-48 hours to populate initially.
  EOT
}