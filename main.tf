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

# ✅ Ensure IAM & KMS APIs are enabled
resource "google_project_service" "kms_api" {
  project = var.project_id
  service = "cloudkms.googleapis.com"
  disable_on_destroy = false
}

# ✅ Use existing KMS Key Ring instead of creating a new one
data "google_kms_key_ring" "bucket_keyring" {
  name     = "bucket-keyring"
  location = var.region
}

data "google_kms_crypto_key" "bucket_key" {
  name     = "bucket-key"
  key_ring = data.google_kms_key_ring.bucket_keyring.id
}

resource "google_kms_crypto_key_iam_binding" "storage_kms_access" {
  crypto_key_id = data.google_kms_crypto_key.bucket_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:${var.gcs_service_account}"
  ]
}

# ✅ Create Cloud Storage Bucket with KMS Encryption
resource "google_storage_bucket" "my_bucket" {
  name          = var.bucket_name
  location      = var.region
  storage_class = "STANDARD"
  uniform_bucket_level_access = true  # Enforce uniform IAM policies

  encryption {
    default_kms_key_name = data.google_kms_crypto_key.bucket_key.id
  }

  depends_on = [google_project_service.kms_api]
}

# ✅ Assign IAM Role to a service account
resource "google_storage_bucket_iam_binding" "bucket_access" {
  bucket = google_storage_bucket.my_bucket.name
  role   = "roles/storage.objectAdmin"

  members = [
    "serviceAccount:${var.service_account_email}"
  ]
}
