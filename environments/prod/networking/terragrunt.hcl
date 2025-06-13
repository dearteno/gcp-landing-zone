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
  network_name = "prod-vpc"
  subnet_name  = "prod-subnet"
  subnet_cidr  = "10.0.3.0/24"
  pods_cidr    = "10.5.0.0/16"
  services_cidr = "10.6.0.0/16"
  nat_name     = "prod-nat-gateway"
  router_name  = "prod-cloud-router"
}