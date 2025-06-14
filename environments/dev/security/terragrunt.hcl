include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path = "${get_terragrunt_dir()}/../terragrunt.hcl"
}

terraform {
  source = "../../../modules/security"
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    network_name = "dev-vpc"
  }
}

dependency "compute" {
  config_path = "../compute"
  mock_outputs = {
    cluster_name = "dev-gke-cluster"
  }
}

inputs = {
  environment         = "dev"
  network_name       = dependency.networking.outputs.network_name
  gke_cluster_name   = dependency.compute.outputs.cluster_name
  
  # Security settings for dev environment
  enable_org_policies         = false # Relaxed for dev
  enable_scc_notifications    = true
  enable_binary_authorization = false # Relaxed for dev
  
  # Allowed IP ranges for dev
  allowed_ip_ranges = [
    "10.0.0.0/8",      # Internal networks
    "192.168.0.0/16",  # Private networks
    "172.16.0.0/12",   # Docker networks
  ]
  
  # Security logging
  log_retention_days = 90 # Shorter retention for dev
  
  # Health check ports
  health_check_ports = ["80", "443", "8080", "3000", "9090"]
}