# Configure Terragrunt to use OpenTofu
terraform_binary = "tofu"
terraform_version_constraint = ">= 1.6.0"
terragrunt_version_constraint = ">= 0.50.0"

# Configure remote state
remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket = "your-terraform-state-bucket"
    prefix = "${path_relative_to_include()}/terraform.tfstate"
  }
}

# Generate provider configuration
generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}
EOF
}

inputs = {
  project_id = "your-project-id"
  region     = "us-central1"
  zone       = "us-central1-a"
}