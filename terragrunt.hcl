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