include "root" {
  path = find_in_parent_folders()
}

include "common" {
  path = "${get_terragrunt_dir()}/../../common/terragrunt.hcl"
}

locals {
  environment = "staging"
}

inputs = {
  environment = local.environment
  
  # Networking
  network_name = "${local.environment}-vpc"
  subnet_name  = "${local.environment}-subnet"
  subnet_cidr  = "10.0.2.0/24"
  pods_cidr    = "10.3.0.0/16"
  services_cidr = "10.4.0.0/16"
  
  # GKE
  cluster_name = "${local.environment}-gke-cluster"
  machine_type = "e2-standard-4"
  min_node_count = 1
  max_node_count = 5
  initial_node_count = 2
  
  # Load Balancer
  external_lb_name = "${local.environment}-external-lb"
  internal_lb_name = "${local.environment}-internal-lb"
}