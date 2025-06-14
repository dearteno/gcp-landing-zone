include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/security"
}

locals {
  environment = "staging"
  project_id = "your-project-id"
  region     = "us-central1"
  zone       = "us-central1-a"
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    network_name = "staging-vpc"
  }
}

inputs = {
  project_id         = local.project_id
  region             = local.region
  environment        = local.environment
  network_name       = dependency.networking.outputs.network_name
  
  # Moderate security settings for staging
  enable_org_policies         = false # Warning mode for staging
  enable_scc_notifications    = true
  enable_binary_authorization = false # Warning mode for staging
  
  # Moderate IP ranges for staging
  allowed_ip_ranges = [
    "10.0.0.0/8",      # Internal networks
    "192.168.0.0/16",  # Private networks
  ]
  
  # Moderate log retention for staging
  log_retention_days = 365 # 1 year for staging
}