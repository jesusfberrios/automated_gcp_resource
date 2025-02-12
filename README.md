# Terraform Deployment for Google Cloud Storage with KMS Encryption

## Overview
This project automates the deployment of a Google Cloud Storage bucket with KMS encryption using Terraform and GitHub Actions. The setup ensures secure access and permissions using IAM roles and best practices.

## Setup & Preparation

### Prerequisites
- A GitHub repository configured with GitHub Actions
- Google Cloud project with necessary permissions
- GitHub Secrets configured for authentication and Terraform variables

### Authenticate with GCP
Ensure that the GitHub Actions workflow is set up with the correct service account credentials stored in GitHub Secrets.

## Define Terraform Configuration for Cloud Storage

### Initialize Terraform in GitHub Actions
The workflow automatically initializes Terraform when the repository is updated.

### Plan Terraform Deployment
The GitHub Actions workflow runs `terraform plan` to preview changes before applying them.

### Apply Configuration
The workflow runs `terraform apply -auto-approve` to deploy the resources.

## Security & IAM Roles

### Required IAM Roles
Ensure the Terraform service account has these roles:
- Storage Admin (`roles/storage.admin`) to manage the Cloud Storage bucket
- KMS CryptoKey Encrypter/Decrypter (`roles/cloudkms.cryptoKeyEncrypterDecrypter`) for encryption and decryption
- IAM Admin (`roles/resourcemanager.projectIamAdmin`) to modify IAM policies

### Assign IAM Roles
To grant permissions, use the following command:
```sh
gcloud kms keys add-iam-policy-binding bucket-key \
    --location=us-central1 \
    --keyring=bucket-keyring \
    --member="serviceAccount:YOUR_TERRAFORM_SA" \
    --role="roles/cloudkms.admin"
```

## Automate with GitHub Actions

### Setup Repository Secrets
Configure the following GitHub secrets in Settings → Secrets and Variables → Actions:
- `TF_VAR_PROJECT_ID`
- `TF_VAR_REGION`
- `TF_VAR_BUCKET_NAME`
- `TF_VAR_SERVICE_ACCOUNT_EMAIL`
- `TF_VAR_USER_EMAIL`
- `TF_VAR_GCS_SERVICE_ACCOUNT`

### GitHub Actions Workflow (`.github/workflows/deploy.yml`)
The workflow:
1. Checks out the repository
2. Authenticates to GCP
3. Runs Terraform Plan & Apply
4. Deploys Cloud Storage with KMS encryption

## Testing & Validation

### Verify Storage Bucket Creation
```sh
gcloud storage buckets list --filter="name:YOUR_BUCKET_NAME"
```

### Confirm KMS Encryption is Applied
```sh
gcloud storage buckets describe YOUR_BUCKET_NAME --format="value(encryption.defaultKmsKeyName)"
```

### Validate IAM Roles
```sh
gcloud projects get-iam-policy YOUR_PROJECT_ID --flatten="bindings[].members" --format="table(bindings.role, bindings.members)" | grep "YOUR_TERRAFORM_SA"
```

## Conclusion
This setup ensures a secure, automated, and scalable deployment of Google Cloud Storage with KMS encryption. Using GitHub Actions, the infrastructure is deployed seamlessly while maintaining security best practices.

Next Steps:
- Extend Terraform to support more GCP resources
- Implement monitoring and logging using Cloud Logging & Cloud Monitoring
- Optimize IAM roles based on the least privilege principle

