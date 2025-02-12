variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "bucket_name" {
  description = "The name of the GCS bucket"
  type        = string
}

variable "service_account_email" {
  description = "The service account email"
  type        = string
}

variable "user_email" {
  description = "The user email for IAM roles"
  type        = string
}

variable "gcs_service_account" {
  description = "The Cloud Storage service account for encryption"
  type        = string
}