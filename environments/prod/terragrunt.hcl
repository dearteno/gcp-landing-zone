include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${get_terragrunt_dir()}/../../common/terragrunt.hcl"
}

locals {
  environment = "prod"
}

inputs = {
  environment = local.environment
  
  # Networking
  network_name = "${local.environment}-vpc"
  subnet_name  = "${local.environment}-subnet"
  subnet_cidr  = "10.0.3.0/24"
  pods_cidr    = "10.5.0.0/16"
  services_cidr = "10.6.0.0/16"
  
  # GKE
  cluster_name = "${local.environment}-gke-cluster"
  machine_type = "e2-standard-8"
  min_node_count = 2
  max_node_count = 10
  initial_node_count = 3
  
  # Load Balancer
  external_lb_name = "${local.environment}-external-lb"
  internal_lb_name = "${local.environment}-internal-lb"
  
  # Enhanced Security Configuration for Production
  enable_binary_authorization = true
  enable_shielded_nodes = true
  enable_private_nodes = true
  enable_istio = true # Service mesh for production
  enable_config_connector = true
  
  # Restricted network access for production
  authorized_networks = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "Internal corporate networks"
    }
  ]
  
  # Minimal allowed IP ranges for production
  allowed_ip_ranges = [
    "10.0.0.0/8",      # Internal networks only
  ]
  
  # Extended log retention for compliance
  log_retention_days = 2555 # 7 years for compliance
  
  # Strict health check ports
  health_check_ports = ["80", "443"]
}