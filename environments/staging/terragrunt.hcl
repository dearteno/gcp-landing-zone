include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  environment = "staging"
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