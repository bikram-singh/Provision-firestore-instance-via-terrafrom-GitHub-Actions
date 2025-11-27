# Provision Firestore Instance via Terraform and GitHub Actions

This repository contains Terraform Infrastructure as Code (IaC) for provisioning and managing Google Cloud Firestore databases across multiple environments using automated GitHub Actions workflows with Workload Identity Federation for secure authentication.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Repository Structure](#repository-structure)
- [Setup Instructions](#setup-instructions)
  - [1. GCP Project Setup](#1-gcp-project-setup)
  - [2. Workload Identity Federation Setup](#2-workload-identity-federation-setup)
  - [3. Service Account Configuration](#3-service-account-configuration)
  - [4. GitHub Secrets Configuration](#4-github-secrets-configuration)
- [Usage](#usage)
  - [Manual Deployment](#manual-deployment)
  - [Automated Deployment via GitHub Actions](#automated-deployment-via-github-actions)
- [Environment Configuration](#environment-configuration)
- [Terraform Resources](#terraform-resources)
- [GitHub Actions Workflow](#github-actions-workflow)
- [Security Best Practices](#security-best-practices)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Overview

This project demonstrates how to:
- Provision Google Cloud Firestore databases using Terraform
- Implement multi-environment infrastructure (dev, staging, prod)
- Use GitHub Actions for CI/CD automation
- Authenticate securely using Workload Identity Federation (no service account keys!)
- Manage Firestore security rules as code
- Store Terraform state remotely in Google Cloud Storage

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       GitHub Actions                         │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Workflow: firestore.yaml                          │    │
│  │  - Checkout code                                   │    │
│  │  - Authenticate via Workload Identity              │    │
│  │  - Terraform Init/Plan/Apply                       │    │
│  └────────────────┬───────────────────────────────────┘    │
└───────────────────┼──────────────────────────────────────────┘
                    │
                    │ OIDC Token
                    ▼
┌─────────────────────────────────────────────────────────────┐
│              Workload Identity Pool                          │
│  projects/166457981312/locations/global/                    │
│  workloadIdentityPools/github-actions-pool                  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ Impersonate
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Service Account                                 │
│  github-actions-deploy@myproject-non-prod.iam               │
│  Roles: Firestore Admin, Storage Admin, etc.               │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ Manage Resources
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Google Cloud Resources                          │
│  - Firestore Databases                                      │
│  - GCS Buckets (Terraform State)                           │
│  - Security Rules                                           │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

Before you begin, ensure you have:

- **Google Cloud Platform (GCP) Account** with billing enabled
- **GCP Project(s)** for different environments (dev, staging, prod)
- **GitHub Repository** (this repository)
- **Terraform** >= 1.0.0 installed locally (optional, for manual runs)
- **gcloud CLI** installed and configured
- **Appropriate IAM permissions** to create:
  - Service Accounts
  - Workload Identity Pools
  - Storage Buckets
  - Firestore Databases

### Required GCP APIs

Enable the following APIs in your GCP project:

```bash
gcloud services enable iam.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable serviceusage.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable firestore.googleapis.com
gcloud services enable iamcredentials.googleapis.com
gcloud services enable sts.googleapis.com
```

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── firestore.yaml          # GitHub Actions workflow for Terraform
├── environments/
│   └── dev/
│       ├── dev.tfvars             # Development environment variables
│       └── dev.backend            # Development backend configuration
├── main.tf                        # Main Terraform configuration
├── variables.tf                   # Variable definitions
├── outputs.tf                     # Output definitions
├── provider.tf                    # Provider configuration
├── firestore.rules                # Firestore security rules
├── .gitignore                     # Git ignore file
└── README.md                      # This file
```

## Setup Instructions

### 1. GCP Project Setup

Create a GCP project (or use an existing one):

```bash
# Set your project ID
export PROJECT_ID="myproject-non-prod"
export PROJECT_NUMBER="166457981312"  # Get this from GCP Console

# Set the project
gcloud config set project $PROJECT_ID
```

### 2. Workload Identity Federation Setup

Create a Workload Identity Pool and Provider to allow GitHub Actions to authenticate without service account keys:

```bash
# Create Workload Identity Pool
gcloud iam workload-identity-pools create "github-actions-pool" \
  --project="$PROJECT_ID" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create Workload Identity Provider
gcloud iam workload-identity-pools providers create-oidc "github-actions-provider" \
  --project="$PROJECT_ID" \
  --location="global" \
  --workload-identity-pool="github-actions-pool" \
  --display-name="GitHub Actions Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository_owner=='bikram-singh'" \
  --issuer-uri="https://token.actions.githubusercontent.com"
```

### 3. Service Account Configuration

Create a service account and grant necessary permissions:

```bash
# Create service account
gcloud iam service-accounts create github-actions-deploy \
  --display-name="GitHub Actions Deploy"

# Grant required roles to the service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-deploy@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/datastore.owner"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-deploy@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-deploy@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

# Allow GitHub Actions to impersonate the service account
gcloud iam service-accounts add-iam-policy-binding \
  github-actions-deploy@${PROJECT_ID}.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/bikram-singh/Provision-firestore-instance-via-terraform-GitHub-Actions"
```

**Screenshot Reference:**
The service account binding was successfully configured as shown below:

```
Updated IAM policy for serviceAccount [github-actions-deploy@myproject-non-prod.iam.gserviceaccount.com].
bindings:
- members:
  - principalSet://iam.googleapis.com/projects/166457981312/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/bikram-singh/Provision-firestore-instance-via-terraform-GitHub-Actions
  role: roles/iam.workloadIdentityUser
etag: BwZD8Yb419w=
version: 1
```

### 4. GitHub Secrets Configuration

Add the following secrets to your GitHub repository (Settings → Secrets and variables → Actions):

| Secret Name | Description | Example Value |
|------------|-------------|---------------|
| `GCP_PROJECT_ID` | Your GCP Project ID | `myproject-non-prod` |
| `GCP_PROJECT_NUMBER` | Your GCP Project Number | `166457981312` |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Workload Identity Provider resource name | `projects/166457981312/locations/global/workloadIdentityPools/github-actions-pool/providers/github-actions-provider` |
| `GCP_SERVICE_ACCOUNT` | Service Account Email | `github-actions-deploy@myproject-non-prod.iam.gserviceaccount.com` |
| `TF_STATE_BUCKET` | GCS bucket for Terraform state | `terraform-state-bucket-dev` |

## Usage

### Manual Deployment

For manual deployment using Terraform CLI:

```bash
# 1. Navigate to the repository directory
cd Provision-firestore-instance-via-terraform-GitHub-Actions

# 2. Initialize Terraform (for dev environment)
terraform init -backend-config=environments/dev/dev.backend

# 3. Create a Terraform plan
terraform plan -var-file=environments/dev/dev.tfvars -out=tfplan

# 4. Review the plan and apply
terraform apply tfplan

# 5. View outputs
terraform output
```

### Automated Deployment via GitHub Actions

The repository includes a GitHub Actions workflow that automatically runs Terraform on:
- **Pull Requests**: Runs `terraform plan` for review
- **Push to main branch**: Runs `terraform apply` to deploy changes

#### Workflow Trigger Options:

1. **Automatic (recommended)**: Push changes to the `main` branch
   ```bash
   git add .
   git commit -m "Update Firestore configuration"
   git push origin main
   ```

2. **Manual Trigger**: Use workflow_dispatch from GitHub Actions UI
   - Go to Actions tab → Select workflow → Run workflow

## Environment Configuration

### Development Environment (`environments/dev/`)

**dev.tfvars:**
```hcl
project_id = "myproject-non-prod"
region     = "us-central1"
environment = "dev"
database_id = "firestore-dev-db"
location_id = "nam5"
```

**dev.backend:**
```hcl
bucket  = "terraform-state-bucket-dev"
prefix  = "firestore/dev"
```

### Adding New Environments

To add staging or production:

1. Create a new directory under `environments/` (e.g., `environments/prod/`)
2. Create `prod.tfvars` with environment-specific values
3. Create `prod.backend` with backend configuration
4. Update GitHub Actions workflow to include the new environment

## Terraform Resources

The Terraform configuration provisions the following resources:

### Main Resources

| Resource | Type | Description |
|----------|------|-------------|
| Firestore Database | `google_firestore_database` | Native mode Firestore database |
| Firestore Index | `google_firestore_index` | Composite indexes for queries |
| Firestore Field | `google_firestore_field` | Field configuration (TTL, indexing) |
| GCS Bucket | `google_storage_bucket` | Terraform state storage |

### Key Configuration Parameters

- **Database Type**: `FIRESTORE_NATIVE`
- **Location**: Multi-region (e.g., `nam5` for North America)
- **Concurrency Mode**: `OPTIMISTIC` or `PESSIMISTIC`
- **Point-in-Time Recovery**: Optional (enabled for production)
- **Delete Protection**: Enabled for production environments

## GitHub Actions Workflow

The workflow (`firestore.yaml`) performs the following steps:

```yaml
name: 'Terraform Firestore Deployment'

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  terraform:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
    
    steps:
      - name: Checkout code
      - name: Authenticate to Google Cloud
      - name: Setup Terraform
      - name: Terraform Init
      - name: Terraform Plan
      - name: Terraform Apply (on push to main)
```

### Workflow Features:

- ✅ **Secure Authentication**: Uses Workload Identity Federation (no keys stored)
- ✅ **Plan on PR**: Shows changes before merging
- ✅ **Auto-apply on merge**: Deploys to main branch automatically
- ✅ **State management**: Stores state in GCS
- ✅ **Environment isolation**: Supports multiple environments

## Security Best Practices

This repository implements several security best practices:

1. **Workload Identity Federation**: Eliminates the need for service account keys
2. **Least Privilege Access**: Service account has only required permissions
3. **Remote State**: Terraform state stored securely in GCS
4. **Firestore Security Rules**: Database access controlled by rules defined in `firestore.rules`
5. **State Locking**: Prevents concurrent modifications
6. **GitHub Secrets**: Sensitive data stored as encrypted secrets
7. **Branch Protection**: Require PR reviews before merging to main

### Firestore Security Rules

The `firestore.rules` file defines who can read/write to your Firestore database:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

Customize these rules based on your application's requirements.

## Troubleshooting

### Common Issues and Solutions

#### 1. Authentication Failed

**Error**: `Error: google: could not find default credentials`

**Solution**: 
- Verify Workload Identity Pool and Provider are created
- Check service account IAM binding is correct
- Ensure GitHub secrets are properly configured

#### 2. Terraform State Lock

**Error**: `Error acquiring the state lock`

**Solution**:
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

#### 3. Permission Denied

**Error**: `Error 403: Permission denied on resource`

**Solution**:
- Verify service account has required roles
- Check API is enabled in the project
- Ensure project ID is correct

#### 4. Workload Identity Federation Issues

**Error**: `The caller does not have permission`

**Solution**:
```bash
# Verify the workload identity binding
gcloud iam service-accounts get-iam-policy \
  github-actions-deploy@${PROJECT_ID}.iam.gserviceaccount.com
```

### Useful Commands

```bash
# List Workload Identity Pools
gcloud iam workload-identity-pools list --location=global

# Describe Workload Identity Provider
gcloud iam workload-identity-pools providers describe github-actions-provider \
  --workload-identity-pool=github-actions-pool \
  --location=global

# Check service account permissions
gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:github-actions-deploy@${PROJECT_ID}.iam.gserviceaccount.com"

# View Terraform state
gsutil ls gs://$TF_STATE_BUCKET/firestore/dev/

# Download state file (for inspection)
gsutil cp gs://$TF_STATE_BUCKET/firestore/dev/default.tfstate ./
```

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Workflow

1. Make changes in a feature branch
2. Test locally using `terraform plan`
3. Create PR to trigger GitHub Actions plan
4. Review plan output in PR comments
5. Merge to main to apply changes

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Resources

- [Terraform Google Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Google Cloud Firestore Documentation](https://cloud.google.com/firestore/docs)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform Backend Configuration](https://www.terraform.io/language/settings/backends/gcs)

## Support

For issues, questions, or contributions, please:
- Open an issue in this repository
- Contact: bikram-singh (GitHub)
- Email: [Your Email]

---

**Made with ❤️ by [Bikram Singh](https://github.com/bikram-singh)**

*Last Updated: November 2024*
