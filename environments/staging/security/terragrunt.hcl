include "terragrunt.hcl"

dependency "common" {
  config_path = "../../common"
}

inputs = {
  project_id = "your-staging-project-id"
  region     = "us-central1"
  environment = "staging"
}