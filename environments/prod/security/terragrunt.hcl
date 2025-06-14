include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/security"
}

locals {
  environment = "prod"
  project_id = "your-project-id"
  region     = "us-central1"
  zone       = "us-central1-a"
}
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    network_name = "prod-vpc"
  }
}

dependency "compute" {
  config_path = "../compute"
  mock_outputs = {
    cluster_name = "prod-gke-cluster"
  }
}

inputs = {
  project_id         = local.project_id
  region             = local.region
  environment        = local.environment
  network_name       = dependency.networking.outputs.network_name
  gke_cluster_name   = dependency.compute.outputs.cluster_name
  
  # Strict security settings for production
  enable_org_policies         = true
  enable_scc_notifications    = true
  enable_binary_authorization = true
  
  # Very restrictive IP ranges for production
  allowed_ip_ranges = [
    "10.0.0.0/8",      # Internal networks only
  ]
  
  # Extended security logging for compliance
  log_retention_days = 2555 # 7 years for compliance
  
  # Minimal health check ports for production
  health_check_ports = ["80", "443"]
  
  # Enhanced SCC filter for production
  scc_notification_filter = "state=\"ACTIVE\" AND (severity=\"HIGH\" OR severity=\"CRITICAL\" OR severity=\"MEDIUM\")"
}