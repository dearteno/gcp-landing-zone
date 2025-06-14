include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/networking"
}

locals {
  environment = "dev"
  project_id = "your-project-id"
  region     = "us-central1"
  zone       = "us-central1-a"
}

inputs = {
  project_id   = local.project_id
  region       = local.region
  environment  = local.environment
  network_name = "dev-vpc"
  subnet_name  = "dev-subnet"
  subnet_cidr  = "10.0.1.0/24"
  pods_cidr    = "10.1.0.0/16"
  services_cidr = "10.2.0.0/16"
  nat_name     = "dev-nat-gateway"
  router_name  = "dev-cloud-router"
}