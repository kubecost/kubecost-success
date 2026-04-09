output "namespace" {
  description = "Kubernetes namespace where Kubecost agent is deployed"
  value       = var.namespace
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.kubecost_agent.name
}

output "release_version" {
  description = "Deployed Helm chart version"
  value       = helm_release.kubecost_agent.version
}

output "release_status" {
  description = "Status of the Helm release"
  value       = helm_release.kubecost_agent.status
}

output "cluster_name" {
  description = "Cluster name configured for this agent"
  value       = var.cluster_name
}

output "kubecost_primary_url" {
  description = "Primary Kubecost instance URL"
  value       = var.kubecost_primary_url
}

output "agent_metadata" {
  description = "Metadata about the agent deployment"
  value = {
    namespace      = var.namespace
    cluster_name   = var.cluster_name
    chart_version  = helm_release.kubecost_agent.version
    release_name   = helm_release.kubecost_agent.name
    deployment_date = kubernetes_config_map.kubecost_metadata.data["deployment-date"]
  }
}