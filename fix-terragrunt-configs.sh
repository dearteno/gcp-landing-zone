#!/bin/bash

# Fix Terragrunt configurations - Remove multiple includes and standardize

set -e

echo "Fixing Terragrunt configurations..."

# Function to fix component configuration
fix_component_config() {
    local file=$1
    local env=$2
    local component=$3
    
    echo "Fixing $file..."
    
    # Create a temporary file with the fixed content
    cat > "${file}.tmp" << EOF
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/${component}"
}

locals {
  environment = "${env}"
  project_id = "your-project-id"
  region     = "us-central1"
  zone       = "us-central1-a"
}
EOF

    # Extract the existing inputs section and append it
    if grep -q "inputs = {" "$file"; then
        echo "" >> "${file}.tmp"
        # Extract from "inputs = {" to end of file, but add project_id, region, environment
        sed -n '/inputs = {/,$ {
            /inputs = {/ {
                a\inputs = {\
  project_id  = local.project_id\
  region      = local.region\
  environment = local.environment
                n
            }
            p
        }' "$file" >> "${file}.tmp"
    else
        echo "" >> "${file}.tmp"
        echo "inputs = {" >> "${file}.tmp"
        echo "  project_id  = local.project_id" >> "${file}.tmp"
        echo "  region      = local.region" >> "${file}.tmp"
        echo "  environment = local.environment" >> "${file}.tmp"
        echo "}" >> "${file}.tmp"
    fi
    
    # Replace the original file
    mv "${file}.tmp" "$file"
}

# Function to fix component with dependencies
fix_component_with_deps() {
    local file=$1
    local env=$2
    local component=$3
    
    echo "Fixing $file (with dependencies)..."
    
    # For security and load-balancer modules that have dependencies
    case $component in
        "security")
            cat > "${file}.tmp" << EOF
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/security"
}

locals {
  environment = "${env}"
  project_id = "your-project-id"
  region     = "us-central1"
  zone       = "us-central1-a"
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    network_name = "${env}-vpc"
  }
}

dependency "compute" {
  config_path = "../compute"
  mock_outputs = {
    cluster_name = "${env}-gke-cluster"
  }
}

inputs = {
  project_id         = local.project_id
  region             = local.region
  environment        = local.environment
  network_name       = dependency.networking.outputs.network_name
  gke_cluster_name   = dependency.compute.outputs.cluster_name
EOF
            ;;
        "load-balancer")
            cat > "${file}.tmp" << EOF
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/load-balancer"
}

locals {
  environment = "${env}"
  project_id = "your-project-id"
  region     = "us-central1"
  zone       = "us-central1-a"
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    network_name = "${env}-vpc"
    subnet_name  = "${env}-subnet"
  }
}

dependency "security" {
  config_path = "../security"
  mock_outputs = {
    security_policy_name = "${env}-security-policy"
  }
}

inputs = {
  project_id           = local.project_id
  region               = local.region
  environment          = local.environment
  network_name         = dependency.networking.outputs.network_name
  subnet_name          = dependency.networking.outputs.subnet_name
  security_policy_name = dependency.security.outputs.security_policy_name
EOF
            ;;
        "compute")
            cat > "${file}.tmp" << EOF
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/compute"
}

locals {
  environment = "${env}"
  project_id = "your-project-id"
  region     = "us-central1"
  zone       = "us-central1-a"
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    network_name = "${env}-vpc"
    subnet_name  = "${env}-subnet"
  }
}

dependency "security" {
  config_path = "../security"
  mock_outputs = {
    gke_node_service_account_email = "${env}-gke-sa@your-project-id.iam.gserviceaccount.com"
    gke_encryption_key = "projects/your-project-id/locations/us-central1/keyRings/${env}-security-keyring/cryptoKeys/gke-encryption-key"
  }
}

inputs = {
  project_id                     = local.project_id
  region                         = local.region
  environment                    = local.environment
  network_name                   = dependency.networking.outputs.network_name
  subnet_name                    = dependency.networking.outputs.subnet_name
  node_service_account_email     = dependency.security.outputs.gke_node_service_account_email
  database_encryption_key        = dependency.security.outputs.gke_encryption_key
EOF
            ;;
    esac
    
    # Extract any additional inputs from the original file
    if grep -q "cluster_name\|machine_type\|min_node_count" "$file"; then
        echo "" >> "${file}.tmp"
        sed -n '/cluster_name\|machine_type\|min_node_count\|max_node_count\|initial_node_count/ {
            s/^[[:space:]]*//
            p
        }' "$file" >> "${file}.tmp"
    fi
    
    # Close the inputs block
    echo "}" >> "${file}.tmp"
    
    # Replace the original file
    mv "${file}.tmp" "$file"
}

# Fix all component configurations
environments=("dev" "staging" "prod")
components=("networking" "compute" "security" "load-balancer")

for env in "${environments[@]}"; do
    for component in "${components[@]}"; do
        file="environments/${env}/${component}/terragrunt.hcl"
        if [ -f "$file" ]; then
            if [[ "$component" == "networking" ]]; then
                fix_component_config "$file" "$env" "$component"
            else
                fix_component_with_deps "$file" "$env" "$component"
            fi
        fi
    done
done

echo "All Terragrunt configurations have been fixed!"
echo "Run './deploy.sh validate dev' to test the configuration."
