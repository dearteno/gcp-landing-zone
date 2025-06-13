include {
  path = "${find_in_parent_folders("terragrunt.hcl")}"
}

locals {
  project_id = "your-project-id"
  region     = "us-central1"
}

inputs = {
  project_id = local.project_id
  region     = local.region
}