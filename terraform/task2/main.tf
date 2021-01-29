provider "google" {
  credentials = file("../terraform-sa.json")

  project = var.project_id
  region  = var.region_default
  zone    = var.zone_default
}

resource "google_service_account" "k8s-sa" {
  account_id  = "k8s-${var.project_id}-sa"
  description = "k8s service account"
  project     = var.project_id
}

resource "google_container_registry" "registry" {
  project  = var.project_id
  location = "EU"
}

resource "google_storage_bucket_iam_member" "viewer" {
  bucket = google_container_registry.registry.id
  role = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.k8s-sa.email}"
}

resource "google_container_cluster" "app-cluster" {
  name     = "app-cluster"
  location = "us-central1"

  remove_default_node_pool = true
  initial_node_count       = 1

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  ip_allocation_policy {
  }
}

resource "google_container_node_pool" "app-node-pool" {
  name       = "app-node-pool"
  location   = "us-central1"
  cluster    = google_container_cluster.app-cluster.name
  node_count = 1

  node_config {
    machine_type = "e2-medium"

    #service_account  = "test-k8s-gcr-read@dev-project-302319.iam.gserviceaccount.com"
    service_account = google_service_account.k8s-sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only"
    ]
  }
}