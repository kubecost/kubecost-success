terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

# Get current GCP project
data "google_project" "current" {
  project_id = var.project_id
}

# Service Account for Kubecost
resource "google_service_account" "kubecost" {
  account_id   = var.service_account_id
  display_name = var.service_account_display_name
  description  = "Service account for Kubecost cost analysis"
  project      = var.project_id
}

# Service Account Key
resource "google_service_account_key" "kubecost" {
  service_account_id = google_service_account.kubecost.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

# IAM Role: BigQuery Data Viewer (for billing export)
resource "google_project_iam_member" "bigquery_data_viewer" {
  project = var.project_id
  role    = "roles/bigquery.dataViewer"
  member  = "serviceAccount:${google_service_account.kubecost.email}"
}

# IAM Role: BigQuery Job User (to run queries)
resource "google_project_iam_member" "bigquery_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.kubecost.email}"
}

# IAM Role: Compute Viewer (for GCE pricing)
resource "google_project_iam_member" "compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.kubecost.email}"
}

# Optional: Storage Object Viewer for GCS bucket access
resource "google_storage_bucket_iam_member" "bucket_viewer" {
  count = var.billing_export_bucket != "" ? 1 : 0
  
  bucket = var.billing_export_bucket
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.kubecost.email}"
}

# Workload Identity binding for GKE (if enabled)
resource "google_service_account_iam_member" "workload_identity" {
  count = var.enable_workload_identity ? 1 : 0
  
  service_account_id = google_service_account.kubecost.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.kubecost_namespace}/${var.kubernetes_service_account}]"
}

# Kubernetes Secret for GCP credentials
resource "kubernetes_secret" "gcp_credentials" {
  count = var.create_kubernetes_secret ? 1 : 0
  
  metadata {
    name      = "kubecost-gcp-credentials"
    namespace = var.kubecost_namespace
    
    labels = {
      "app.kubernetes.io/name"       = "kubecost"
      "app.kubernetes.io/component"  = "cost-analyzer"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  
  data = {
    "key.json" = base64decode(google_service_account_key.kubecost.private_key)
  }
  
  type = "Opaque"
}

# Kubernetes Service Account with Workload Identity annotation
resource "kubernetes_service_account" "kubecost" {
  count = var.enable_workload_identity && var.create_kubernetes_service_account ? 1 : 0
  
  metadata {
    name      = var.kubernetes_service_account
    namespace = var.kubecost_namespace
    
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.kubecost.email
    }
    
    labels = {
      "app.kubernetes.io/name"       = "kubecost"
      "app.kubernetes.io/component"  = "cost-analyzer"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# ConfigMap for GCP integration configuration
resource "kubernetes_config_map" "gcp_integration" {
  metadata {
    name      = "kubecost-gcp-integration"
    namespace = var.kubecost_namespace
    
    labels = {
      "app.kubernetes.io/name"       = "kubecost"
      "app.kubernetes.io/component"  = "cost-analyzer"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  
  data = {
    "gcp-config.json" = jsonencode({
      provider                = "gcp"
      description             = "GCP Cost Integration"
      projectID               = var.project_id
      billingDataDataset      = var.billing_dataset_id
      billingDataTable        = var.billing_table_id
      key                     = var.enable_workload_identity ? "" : base64decode(google_service_account_key.kubecost.private_key)
      serviceAccountEmail     = google_service_account.kubecost.email
      useWorkloadIdentity     = var.enable_workload_identity
      bigQueryBillingDataset  = var.billing_dataset_id
    })
  }
}