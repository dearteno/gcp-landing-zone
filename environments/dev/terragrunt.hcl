include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  environment = "dev"
  project_id = "your-project-id"
  region     = "us-central1"
  zone       = "us-central1-a"
  
  # Common tags for all resources
  labels = {
    environment = local.environment
    managed_by  = "terragrunt"
  }
}

inputs = {
  project_id = local.project_id
  region     = local.region
  zone       = local.zone
  labels     = local.labels
  environment = local.environment
  
  # Networking
  network_name = "${local.environment}-vpc"
  subnet_name  = "${local.environment}-subnet"
  subnet_cidr  = "10.0.1.0/24"
  pods_cidr    = "10.1.0.0/16"
  services_cidr = "10.2.0.0/16"
  
  # GKE
  cluster_name = "${local.environment}-gke-cluster"
  machine_type = "e2-standard-2"
  min_node_count = 1
  max_node_count = 3
  initial_node_count = 1
  
  # Load Balancer
  external_lb_name = "${local.environment}-external-lb"
  internal_lb_name = "${local.environment}-internal-lb"
  
  # Security Configuration
  enable_binary_authorization = false # Relaxed for dev
  enable_shielded_nodes = true
  enable_private_nodes = true
  authorized_networks = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "Internal networks"
    }
  ]
  allowed_ip_ranges = [
    "10.0.0.0/8",      # Internal networks
    "192.168.0.0/16",  # Private networks
  ]
  log_retention_days = 90 # Shorter retention for dev
}