include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/security"
}

locals {
  environment = "dev"
  project_id = "your-project-id"
  region     = "us-central1"
  zone       = "us-central1-a"
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    network_name = "dev-vpc"
  }
}

inputs = {
  project_id         = local.project_id
  region             = local.region
  environment        = local.environment
  network_name       = dependency.networking.outputs.network_name
  
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