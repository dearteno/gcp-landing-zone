include "root" {
  path = find_in_parent_folders("root.hcl")
}


locals {
  environment = "dev"
  project_id = "your-project-id"
  region     = "us-central1"
  zone       = "us-central1-a"
}
terraform {
  source = "../../../modules/load-balancer"
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    network_name = "dev-vpc"
    subnet_name  = "dev-subnet"
    external_lb_ip = "1.2.3.4"
  }
}

inputs = {
  project_id  = local.project_id
  region      = local.region
  environment = local.environment
  network_name     = dependency.networking.outputs.network_name
  subnet_name      = dependency.networking.outputs.subnet_name
  external_lb_ip   = dependency.networking.outputs.external_lb_ip
  external_lb_name = "dev-external-lb"
  internal_lb_name = "dev-internal-lb"
  health_check_port = 80
  backend_service_port = 80
}
