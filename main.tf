terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ✅ Ensure IAM & KMS APIs are enabled before Terraform uses them
resource "google_project_service" "iam_api" {
  project = var.project_id
  service = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "kms_api" {
  project = var.project_id
  service = "cloudkms.googleapis.com"
  disable_on_destroy = false
}

# ✅ Enable Encryption using Google Cloud KMS
resource "google_kms_key_ring" "bucket_keyring" {
  name     = "bucket-keyring"
  location = var.region
  depends_on = [google_project_service.kms_api]  # Ensure KMS API is enabled first
}

resource "google_kms_crypto_key" "bucket_key" {
  name     = "bucket-key"
  key_ring = google_kms_key_ring.bucket_keyring.id  # ✅ Correct attribute
  rotation_period = "7776000s"  # Key rotation every 90 days
  depends_on = [google_kms_key_ring.bucket_keyring]  
}

# ✅ Create Cloud Storage Bucket with KMS Encryption
resource "google_storage_bucket" "my_bucket" {
  name          = var.bucket_name
  location      = var.region
  storage_class = "STANDARD"
  uniform_bucket_level_access = true  # Enforce uniform IAM policies

  encryption {
    default_kms_key_name = google_kms_crypto_key.bucket_key.id
  }

  depends_on = [google_kms_crypto_key.bucket_key]
}

# ✅ Assign IAM Role to a user/service account
resource "google_storage_bucket_iam_binding" "viewer_role" {
  bucket = google_storage_bucket.my_bucket.name
  role   = "roles/storage.objectViewer"

  members = [
    "user:${var.user_email}",
    "serviceAccount:${var.service_account_email}"
  ]
}

# ✅ Use Existing VPC Network Instead of Creating a New One
data "google_compute_network" "vpc_network" {
  name    = "my-vpc"
  project = var.project_id
}

resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = data.google_compute_network.vpc_network.id  # Use the existing network

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# ✅ Create a Service Account for Secure Access
resource "google_service_account" "bucket_service_account" {
  account_id   = "bucket-sa"
  display_name = "Bucket Service Account"
}

# ✅ Grant Storage Admin Role to the Service Account
resource "google_project_iam_binding" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"

  members = [
    "serviceAccount:${google_service_account.bucket_service_account.email}"
  ]
}
