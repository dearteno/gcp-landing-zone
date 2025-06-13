include "terragrunt.hcl"

dependency "common" {
  config_path = "../../common"
}

inputs = {
  region = "us-central1"
  network_name = "dev-network"
  subnet_name = "dev-subnet"
  cidr_block = "10.0.0.0/24"
}