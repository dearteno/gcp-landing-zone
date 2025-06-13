include "common/terragrunt.hcl"

terraform {
  source = "../modules//"
}

inputs = {
  project_id = "your-project-id"
  region     = "us-central1"
}