include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path = "${get_terragrunt_dir()}/../terragrunt.hcl"
}

terraform {
  source = "../../../modules/networking"
}

inputs = {
  network_name = "dev-vpc"
  subnet_name  = "dev-subnet"
  subnet_cidr  = "10.0.1.0/24"
  pods_cidr    = "10.1.0.0/16"
  services_cidr = "10.2.0.0/16"
  nat_name     = "dev-nat-gateway"
  router_name  = "dev-cloud-router"
}