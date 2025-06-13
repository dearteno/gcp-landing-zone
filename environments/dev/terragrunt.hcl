include "terragrunt.hcl"

locals {
  environment = "dev"
}

include {
  path = find_in_parent_folders()
}

dependencies {
  paths = [
    "../common"
  ]
}

inputs = {
  project_id = "your-dev-project-id"
  region     = "us-central1"
  network    = "dev-network"
  subnet     = "dev-subnet"
}