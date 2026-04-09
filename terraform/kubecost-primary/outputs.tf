output "namespace" {
  description = "Kubernetes namespace where Kubecost primary is deployed"
  value       = var.namespace
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.kubecost_primary.name
}

output "release_version" {
  description = "Deployed Helm chart version"
  value       = helm_release.kubecost_primary.version
}

output "release_status" {
  description = "Status of the Helm release"
  value       = helm_release.kubecost_primary.status
}

output "cluster_name" {
  description = "Cluster name configured for this primary"
  value       = var.cluster_name
}

output "service_type" {
  description = "Kubernetes service type"
  value       = var.service_type
}

output "service_port" {
  description = "Service port"
  value       = var.service_port
}

output "ingress_enabled" {
  description = "Whether ingress is enabled"
  value       = var.ingress_enabled
}

output "ingress_hosts" {
  description = "Ingress hosts"
  value       = var.ingress_enabled ? var.ingress_hosts : []
}

output "federation_enabled" {
  description = "Whether federation is enabled"
  value       = var.enable_federation
}

output "federation_s3_bucket" {
  description = "S3 bucket for federation (if enabled)"
  value       = var.enable_federation ? var.federation_s3_bucket : ""
}

output "primary_url" {
  description = "Primary Kubecost URL (for agent configuration)"
  value       = var.ingress_enabled && length(var.ingress_hosts) > 0 ? "https://${var.ingress_hosts[0]}" : "http://kubecost-primary.${var.namespace}.svc.cluster.local:${var.service_port}"
}

output "primary_metadata" {
  description = "Metadata about the primary deployment"
  value = {
    namespace          = var.namespace
    cluster_name       = var.cluster_name
    chart_version      = helm_release.kubecost_primary.version
    release_name       = helm_release.kubecost_primary.name
    deployment_date    = kubernetes_config_map.kubecost_metadata.data["deployment-date"]
    federation_enabled = var.enable_federation
    deployment_type    = "primary"
  }
}

output "agent_connection_info" {
  description = "Information needed for agents to connect to this primary"
  value = {
    primary_url = var.ingress_enabled && length(var.ingress_hosts) > 0 ? "https://${var.ingress_hosts[0]}" : "http://kubecost-primary.${var.namespace}.svc.cluster.local:${var.service_port}"
    namespace   = var.namespace
    cluster_name = var.cluster_name
  }
}

output "next_steps" {
  description = "Next steps after primary deployment"
  value = <<-EOT
    Kubecost Primary Cluster Deployed Successfully!
    
    Access Information:
    ${var.ingress_enabled ? "- Kubecost UI: https://${var.ingress_hosts[0]}" : "- Kubecost UI: Port-forward to access"}
    ${!var.ingress_enabled ? "  kubectl port-forward -n ${var.namespace} svc/${var.release_name}-cost-analyzer ${var.service_port}:${var.service_port}" : ""}
    - Namespace: ${var.namespace}
    - Service: ${var.release_name}-cost-analyzer
    
    ${var.enable_federation ? "Federation Configuration:\n    - S3 Bucket: ${var.federation_s3_bucket}\n    - Region: ${var.federation_s3_region}\n    - Prefix: ${var.federation_s3_prefix}\n" : ""}
    Next Steps:
    
    1. Access Kubecost UI:
       ${var.ingress_enabled ? "Open https://${var.ingress_hosts[0]} in your browser" : "Run: kubectl port-forward -n ${var.namespace} svc/${var.release_name}-cost-analyzer ${var.service_port}:${var.service_port}"}
    
    2. Configure Cloud Integrations:
       - Deploy cloud integration modules from terraform/cloud-integrations/
       - AWS: terraform/cloud-integrations/aws/
       - Azure: terraform/cloud-integrations/azure/
       - GCP: terraform/cloud-integrations/gcp/
    
    3. Deploy Agents (if multi-cluster):
       - Use terraform/kubecost-agent/ module
       - Set kubecost_primary_url to: ${var.ingress_enabled && length(var.ingress_hosts) > 0 ? "https://${var.ingress_hosts[0]}" : "http://kubecost-primary.${var.namespace}.svc.cluster.local:${var.service_port}"}
       - Generate agent token in Kubecost UI (Settings → Agents)
    
    4. Verify Deployment:
       kubectl get pods -n ${var.namespace}
       kubectl logs -n ${var.namespace} -l app.kubernetes.io/name=cost-analyzer
    
    ${var.enable_federation ? "5. Verify Federation:\n       - Check S3 bucket for data: aws s3 ls s3://${var.federation_s3_bucket}/${var.federation_s3_prefix}/\n       - Monitor federation status in Kubecost UI\n" : ""}
    Chart Version: ${helm_release.kubecost_primary.version}
    Deployment Type: Primary Cluster
    Federation: ${var.enable_federation ? "Enabled" : "Disabled"}
  EOT
}