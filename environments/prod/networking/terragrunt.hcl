include {
  path = find_in_parent_folders("terragrunt.hcl")
}

dependency "networking" {
  config_path = "../networking"
}

inputs = {
  project_id = "your-prod-project-id"
  region     = "us-central1"
  network    = "prod-network"
  subnet     = "prod-subnet"
}