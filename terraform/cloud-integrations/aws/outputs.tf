output "iam_policy_arn" {
  description = "ARN of the IAM policy for Kubecost"
  value       = aws_iam_policy.kubecost.arn
}

output "iam_policy_name" {
  description = "Name of the IAM policy for Kubecost"
  value       = aws_iam_policy.kubecost.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role for Kubecost (if IRSA is enabled)"
  value       = var.create_irsa_role ? aws_iam_role.kubecost[0].arn : null
}

output "iam_role_name" {
  description = "Name of the IAM role for Kubecost (if IRSA is enabled)"
  value       = var.create_irsa_role ? aws_iam_role.kubecost[0].name : null
}

output "service_account_name" {
  description = "Name of the Kubernetes service account"
  value       = var.create_service_account ? kubernetes_service_account.kubecost[0].metadata[0].name : var.service_account_name
}

output "service_account_namespace" {
  description = "Namespace of the Kubernetes service account"
  value       = var.kubecost_namespace
}

output "integration_config" {
  description = "AWS integration configuration details"
  value = {
    aws_account_id     = var.aws_account_id
    cur_bucket         = var.cur_bucket_name
    athena_bucket      = var.athena_bucket_name
    athena_region      = var.athena_region
    athena_database    = var.athena_database
    athena_table       = var.athena_table
    athena_workgroup   = var.athena_workgroup
    using_irsa         = var.create_irsa_role
    using_static_creds = var.use_static_credentials
  }
}

output "next_steps" {
  description = "Next steps for completing the integration"
  value = <<-EOT
    AWS Integration Setup Complete!
    
    Next Steps:
    1. Ensure Cost and Usage Reports are enabled in AWS:
       - Go to AWS Billing Console > Cost & Usage Reports
       - Create a report if not exists with the following settings:
         * Report name: kubecost-cur
         * Time granularity: Hourly
         * Include resource IDs: Yes
         * Enable report data integration: Amazon Athena
         * S3 bucket: ${var.cur_bucket_name}
    
    2. Configure Athena:
       - Ensure Athena database '${var.athena_database}' exists
       - Verify CUR data is being populated
    
    3. Update Kubecost Helm values to use this integration:
       - Set serviceAccount.name to '${var.service_account_name}'
       ${var.create_irsa_role ? "- Service account is already annotated with IAM role" : ""}
       ${var.use_static_credentials ? "- AWS credentials secret has been created" : ""}
    
    4. Verify integration in Kubecost UI:
       - Navigate to Settings > Cloud Integrations
       - Check AWS integration status
    
    IAM Role ARN: ${var.create_irsa_role ? aws_iam_role.kubecost[0].arn : "N/A"}
    IAM Policy ARN: ${aws_iam_policy.kubecost.arn}
  EOT
}