include "root" {
  path = find_in_parent_folders("root.hcl")
}


locals {
  environment = "staging"
  project_id = "your-project-id"
  region     = "us-central1"
  zone       = "us-central1-a"
}
terraform {
  source = "../../../modules/networking"
}

inputs = {
  project_id  = local.project_id
  region      = local.region
  environment = local.environment
  network_name = "staging-vpc"
  subnet_name  = "staging-subnet"
  subnet_cidr  = "10.0.2.0/24"
  pods_cidr    = "10.3.0.0/16"
  services_cidr = "10.4.0.0/16"
  nat_name     = "staging-nat-gateway"
  router_name  = "staging-cloud-router"
}