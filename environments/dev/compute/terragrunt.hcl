include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/compute"
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
    subnet_name  = "dev-subnet"
    pods_cidr    = "10.1.0.0/16"
    services_cidr = "10.2.0.0/16"
  }
}

dependency "security" {
  config_path = "../security"
  mock_outputs = {
    gke_node_service_account_email = "dev-gke-sa@your-project-id.iam.gserviceaccount.com"
    gke_encryption_key = "projects/your-project-id/locations/us-central1/keyRings/dev-security-keyring/cryptoKeys/gke-encryption-key"
  }
}

inputs = {
  project_id                     = local.project_id
  region                         = local.region
  zone                           = local.zone
  environment                    = local.environment
  cluster_name                   = "dev-gke-cluster"
  network_name                   = dependency.networking.outputs.network_name
  subnet_name                    = dependency.networking.outputs.subnet_name
  pods_cidr                      = dependency.networking.outputs.pods_cidr
  services_cidr                  = dependency.networking.outputs.services_cidr
  node_service_account_email     = dependency.security.outputs.gke_node_service_account_email
  database_encryption_key        = dependency.security.outputs.gke_encryption_key
  machine_type                   = "e2-standard-2"
  min_node_count                 = 1
  max_node_count                 = 3
  initial_node_count             = 1
  node_pool_name                 = "dev-node-pool"
}