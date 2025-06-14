include "root" {
  path = find_in_parent_folders("root.hcl")
}


locals {
  environment = "prod"
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
  network_name = "prod-vpc"
  subnet_name  = "prod-subnet"
  subnet_cidr  = "10.0.3.0/24"
  pods_cidr    = "10.5.0.0/16"
  services_cidr = "10.6.0.0/16"
  nat_name     = "prod-nat-gateway"
  router_name  = "prod-cloud-router"
}