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
  source = "../../../modules/compute"
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    network_name = "prod-vpc"
    subnet_name  = "prod-subnet"
    pods_cidr    = "10.5.0.0/16"
    services_cidr = "10.6.0.0/16"
  }
}

inputs = {
  project_id  = local.project_id
  region      = local.region
  environment = local.environment
  cluster_name    = "prod-gke-cluster"
  network_name    = dependency.networking.outputs.network_name
  subnet_name     = dependency.networking.outputs.subnet_name
  pods_cidr       = dependency.networking.outputs.pods_cidr
  services_cidr   = dependency.networking.outputs.services_cidr
  machine_type    = "e2-standard-8"
  min_node_count  = 2
  max_node_count  = 10
  initial_node_count = 3
  node_pool_name  = "prod-node-pool"
}