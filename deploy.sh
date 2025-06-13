#!/bin/bash

# GCP Landing Zone Deployment Script
# This script deploys the complete GCP infrastructure using Terragrunt

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if environment is provided
if [ $# -eq 0 ]; then
    print_error "Usage: $0 <environment> [action]"
    print_error "Environment: dev, staging, prod"
    print_error "Action: plan, apply, destroy (default: plan)"
    exit 1
fi

ENVIRONMENT=$1
ACTION=${2:-plan}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    print_error "Invalid environment. Use: dev, staging, or prod"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    print_error "Invalid action. Use: plan, apply, or destroy"
    exit 1
fi

print_status "Starting $ACTION for $ENVIRONMENT environment..."

# Check if terragrunt is installed
if ! command -v terragrunt &> /dev/null; then
    print_error "Terragrunt is not installed. Please install it first."
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install it first."
    exit 1
fi

# Set working directory
WORK_DIR="environments/$ENVIRONMENT"

if [ ! -d "$WORK_DIR" ]; then
    print_error "Environment directory $WORK_DIR does not exist"
    exit 1
fi

# Components to deploy in order
COMPONENTS=("networking" "compute" "load-balancer")

print_status "Deploying components in order: ${COMPONENTS[*]}"

for component in "${COMPONENTS[@]}"; do
    component_dir="$WORK_DIR/$component"
    
    if [ ! -d "$component_dir" ]; then
        print_warning "Component directory $component_dir does not exist, skipping..."
        continue
    fi
    
    print_status "Processing $component..."
    
    cd "$component_dir"
    
    case $ACTION in
        plan)
            print_status "Running terragrunt plan for $component..."
            terragrunt plan
            ;;
        apply)
            print_status "Running terragrunt apply for $component..."
            terragrunt apply -auto-approve
            ;;
        destroy)
            print_warning "Running terragrunt destroy for $component..."
            terragrunt destroy -auto-approve
            ;;
    esac
    
    if [ $? -ne 0 ]; then
        print_error "Failed to $ACTION $component"
        exit 1
    fi
    
    cd - > /dev/null
    
    print_status "Completed $component"
done

print_status "Successfully completed $ACTION for $ENVIRONMENT environment!"

# If applying, show some useful outputs
if [ "$ACTION" == "apply" ]; then
    print_status "Getting infrastructure outputs..."
    
    echo -e "\n${YELLOW}=== Infrastructure Summary ===${NC}"
    
    # Get networking outputs
    if [ -d "$WORK_DIR/networking" ]; then
        echo -e "\n${GREEN}Networking:${NC}"
        cd "$WORK_DIR/networking"
        terragrunt output 2>/dev/null || print_warning "No networking outputs available"
        cd - > /dev/null
    fi
    
    # Get compute outputs
    if [ -d "$WORK_DIR/compute" ]; then
        echo -e "\n${GREEN}Compute (GKE):${NC}"
        cd "$WORK_DIR/compute"
        terragrunt output 2>/dev/null || print_warning "No compute outputs available"
        cd - > /dev/null
    fi
    
    # Get load balancer outputs
    if [ -d "$WORK_DIR/load-balancer" ]; then
        echo -e "\n${GREEN}Load Balancer:${NC}"
        cd "$WORK_DIR/load-balancer"
        terragrunt output 2>/dev/null || print_warning "No load balancer outputs available"
        cd - > /dev/null
    fi
fi

print_status "Deployment script completed!"
