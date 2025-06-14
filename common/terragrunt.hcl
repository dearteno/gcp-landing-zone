include {
  path = "${find_in_parent_folders("root.hcl")}"
}

locals {
  project_id = "your-project-id"
  region     = "us-central1"
  zone       = "us-central1-a"
  
  # Common tags for all resources
  labels = {
    environment = basename(dirname(get_terragrunt_dir()))
    managed_by  = "terragrunt"
  }
}

inputs = {
  project_id = local.project_id
  region     = local.region
  zone       = local.zone
  labels     = local.labels
}