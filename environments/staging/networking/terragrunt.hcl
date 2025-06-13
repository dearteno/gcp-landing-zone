include "terragrunt.hcl"

dependency "common" {
  config_path = "../../common"
}

inputs = {
  region = "us-central1"
  network_name = "staging-network"
  subnet_name = "staging-subnet"
  cidr_block = "10.0.1.0/24"
}