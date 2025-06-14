include "terragrunt.hcl"

dependency "common" {
  config_path = "../../common"
}

inputs = {
  project_id  = local.project_id
  region      = local.region
  environment = local.environment
  project_id = "your-staging-project-id"
  region     = "us-central1"
  environment = "staging"
}