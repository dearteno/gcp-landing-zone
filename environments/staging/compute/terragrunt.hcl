include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/compute"
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    network_name = "staging-vpc"
    subnet_name  = "staging-subnet"
    pods_cidr    = "10.3.0.0/16"
    services_cidr = "10.4.0.0/16"
  }
}

inputs = {
  cluster_name    = "staging-gke-cluster"
  network_name    = dependency.networking.outputs.network_name
  subnet_name     = dependency.networking.outputs.subnet_name
  pods_cidr       = dependency.networking.outputs.pods_cidr
  services_cidr   = dependency.networking.outputs.services_cidr
  machine_type    = "e2-standard-4"
  min_node_count  = 1
  max_node_count  = 5
  initial_node_count = 2
  node_pool_name  = "staging-node-pool"
}