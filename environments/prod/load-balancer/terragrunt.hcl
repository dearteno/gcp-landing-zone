include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path = "${get_terragrunt_dir()}/../terragrunt.hcl"
}

terraform {
  source = "../../../modules/load-balancer"
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    network_name = "prod-vpc"
    subnet_name  = "prod-subnet"
    external_lb_ip = "1.2.3.4"
  }
}

inputs = {
  network_name     = dependency.networking.outputs.network_name
  subnet_name      = dependency.networking.outputs.subnet_name
  external_lb_ip   = dependency.networking.outputs.external_lb_ip
  external_lb_name = "prod-external-lb"
  internal_lb_name = "prod-internal-lb"
  health_check_port = 80
  backend_service_port = 80
}
