include "terragrunt.hcl"

dependency "networking" {
  config_path = "../networking"
}

dependency "security" {
  config_path = "../security"
}

inputs = {
  region = "us-central1"
  project_id = "your-prod-project-id"
  instance_type = "n1-standard-1"
  # Add other inputs as necessary
}