include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path = "${get_terragrunt_dir()}/../terragrunt.hcl"
}

terraform {
  source = "../../../modules/compute"
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    network_name = "dev-vpc"
    subnet_name  = "dev-subnet"
    pods_cidr    = "10.1.0.0/16"
    services_cidr = "10.2.0.0/16"
  }
}

inputs = {
  cluster_name    = "dev-gke-cluster"
  network_name    = dependency.networking.outputs.network_name
  subnet_name     = dependency.networking.outputs.subnet_name
  pods_cidr       = dependency.networking.outputs.pods_cidr
  services_cidr   = dependency.networking.outputs.services_cidr
  machine_type    = "e2-standard-2"
  min_node_count  = 1
  max_node_count  = 3
  initial_node_count = 1
  node_pool_name  = "dev-node-pool"
}