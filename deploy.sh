#!/bin/bash

# GCP Landing Zone Deployment Script (OpenTofu + Terragrunt) - Enhanced Security Version
# This script deploys the complete GCP infrastructure using Terragrunt with OpenTofu
# Includes comprehensive security hardening, validation, and monitoring

set -e

# Script version and metadata
SCRIPT_VERSION="2.0.0"
SCRIPT_NAME="GCP Landing Zone Deployer"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging setup
LOG_DIR="logs"
LOG_FILE="$LOG_DIR/deploy-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$LOG_DIR"

# Function to print colored output and log
log_and_print() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $message" | tee -a "$LOG_FILE"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARNING]${NC} $message" | tee -a "$LOG_FILE"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message" | tee -a "$LOG_FILE"
            ;;
        "DEBUG")
            echo -e "${BLUE}[DEBUG]${NC} $message" | tee -a "$LOG_FILE"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message" | tee -a "$LOG_FILE"
            ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

print_status() {
    log_and_print "INFO" "$1"
}

print_warning() {
    log_and_print "WARN" "$1"
}

print_error() {
    log_and_print "ERROR" "$1"
}

print_debug() {
    log_and_print "DEBUG" "$1"
}

print_success() {
    log_and_print "SUCCESS" "$1"
}

# Function to print script header
print_header() {
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${CYAN}  $SCRIPT_NAME v$SCRIPT_VERSION${NC}"
    echo -e "${CYAN}  OpenTofu + Terragrunt + Security Hardening${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${BLUE}Log file: $LOG_FILE${NC}"
    echo ""
}

# Function to validate prerequisites
validate_prerequisites() {
    print_status "Validating prerequisites..."
    
    local missing_tools=()
    
    # Check required tools
    if ! command -v terragrunt &> /dev/null; then
        missing_tools+=("terragrunt")
    fi
    
    if ! command -v tofu &> /dev/null; then
        missing_tools+=("tofu (OpenTofu)")
    fi
    
    if ! command -v gcloud &> /dev/null; then
        missing_tools+=("gcloud")
    fi
    
    if ! command -v git &> /dev/null; then
        missing_tools+=("git")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_error "Please install missing tools and try again."
        print_error "Run './migrate-to-opentofu.sh' to install OpenTofu"
        exit 1
    fi
    
    # Check gcloud authentication
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 > /dev/null 2>&1; then
        print_error "No active gcloud authentication found."
        print_error "Please run: gcloud auth login"
        print_error "Or set up Application Default Credentials:"
        print_error "  gcloud auth application-default login"
        exit 1
    fi
    
    # Check if current directory is git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_warning "Not in a git repository. Consider version controlling your changes."
    fi
    
    print_success "All prerequisites validated successfully"
}

# Function to validate GCP project and permissions
validate_gcp_setup() {
    print_status "Validating GCP setup..."
    
    local project_id
    project_id=$(gcloud config get-value project 2>/dev/null)
    
    if [ -z "$project_id" ]; then
        print_error "No GCP project set. Run: gcloud config set project YOUR_PROJECT_ID"
        exit 1
    fi
    
    print_status "Using GCP project: $project_id"
    
    # Check required APIs (basic set)
    local required_apis=(
        "compute.googleapis.com"
        "container.googleapis.com"
        "cloudkms.googleapis.com"
        "logging.googleapis.com"
        "monitoring.googleapis.com"
    )
    
    for api in "${required_apis[@]}"; do
        if gcloud services list --enabled --filter="name:$api" --format="value(name)" | grep -q "$api"; then
            print_debug "API enabled: $api"
        else
            print_warning "API not enabled: $api"
            print_status "Enabling API: $api"
            gcloud services enable "$api" || {
                print_error "Failed to enable API: $api"
                exit 1
            }
        fi
    done
    
    print_success "GCP setup validated successfully"
}

# Enhanced usage function
show_usage() {
    echo -e "${PURPLE}Usage:${NC} $0 <command> [options]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  deploy <env> [action]     Deploy infrastructure to environment"
    echo "  validate <env>            Validate Terragrunt configuration"
    echo "  output <env>              Show infrastructure outputs"
    echo "  status <env>              Check deployment status"
    echo "  cleanup <env>             Clean up Terragrunt cache"
    echo "  security-check <env>      Run security validation"
    echo "  backup <env>              Backup Terraform state"
    echo "  help                      Show this help message"
    echo ""
    echo -e "${YELLOW}Environments:${NC} dev, staging, prod"
    echo -e "${YELLOW}Actions:${NC} plan, apply, destroy (default: plan)"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 deploy dev plan        # Plan deployment to dev"
    echo "  $0 deploy prod apply      # Apply to production"
    echo "  $0 validate staging       # Validate staging config"
    echo "  $0 security-check prod    # Run security checks"
    echo "  $0 output dev             # Show dev outputs"
}

# Function to validate environment
validate_environment() {
    local env=$1
    
    if [[ ! "$env" =~ ^(dev|staging|prod)$ ]]; then
        print_error "Invalid environment: $env"
        print_error "Valid environments: dev, staging, prod"
        exit 1
    fi
    
    local work_dir="environments/$env"
    if [ ! -d "$work_dir" ]; then
        print_error "Environment directory $work_dir does not exist"
        exit 1
    fi
    
    print_debug "Environment $env validated"
}

# Function to validate action
validate_action() {
    local action=$1
    
    if [[ ! "$action" =~ ^(plan|apply|destroy)$ ]]; then
        print_error "Invalid action: $action"
        print_error "Valid actions: plan, apply, destroy"
        exit 1
    fi
    
    print_debug "Action $action validated"
}
# Function to run security checks
run_security_check() {
    local env=$1
    print_status "Running security validation for $env environment..."
    
    local work_dir="environments/$env"
    
    # Check for hardcoded secrets in configuration files
    print_status "Checking for potential secrets in configuration..."
    if grep -r -i -E "(password|secret|key|token)" "$work_dir" --include="*.hcl" --include="*.tf" | grep -v "variable\|description\|output"; then
        print_warning "Potential hardcoded secrets found. Please review the above matches."
    else
        print_success "No obvious hardcoded secrets found"
    fi
    
    # Validate Terragrunt configuration
    print_status "Validating Terragrunt configuration..."
    cd "$work_dir"
    if terragrunt validate-all; then
        print_success "Terragrunt configuration is valid"
    else
        print_error "Terragrunt configuration validation failed"
        return 1
    fi
    cd - > /dev/null
    
    # Check for security best practices
    print_status "Checking security best practices..."
    local security_issues=()
    
    # Check if private clusters are enabled
    if ! grep -r "enable_private_nodes.*=.*true" "$work_dir" > /dev/null; then
        security_issues+=("Private nodes not explicitly enabled")
    fi
    
    # Check if network policies are enabled
    if ! grep -r "network_policy_enabled.*=.*true" "$work_dir" > /dev/null; then
        security_issues+=("Network policies not explicitly enabled")
    fi
    
    # Check if workload identity is enabled
    if ! grep -r "workload_identity_enabled.*=.*true" "$work_dir" > /dev/null; then
        security_issues+=("Workload identity not explicitly enabled")
    fi
    
    if [ ${#security_issues[@]} -eq 0 ]; then
        print_success "Security best practices check passed"
    else
        print_warning "Security recommendations:"
        for issue in "${security_issues[@]}"; do
            print_warning "  - $issue"
        done
    fi
    
    print_success "Security check completed"
}

# Function to cleanup Terragrunt cache
cleanup_cache() {
    local env=$1
    print_status "Cleaning up Terragrunt cache for $env environment..."
    
    local work_dir="environments/$env"
    
    # Remove .terragrunt-cache directories
    find "$work_dir" -name ".terragrunt-cache" -type d -exec rm -rf {} + 2>/dev/null || true
    
    # Remove .terraform directories
    find "$work_dir" -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
    
    # Remove .tofu directories
    find "$work_dir" -name ".tofu" -type d -exec rm -rf {} + 2>/dev/null || true
    
    print_success "Cache cleanup completed"
}

# Function to backup state
backup_state() {
    local env=$1
    print_status "Backing up Terraform state for $env environment..."
    
    local work_dir="environments/$env"
    local backup_dir="backups/$env/$(date +%Y%m%d-%H%M%S)"
    
    mkdir -p "$backup_dir"
    
    # Find and backup state files
    find "$work_dir" -name "*.tfstate" -exec cp {} "$backup_dir/" \; 2>/dev/null || true
    find "$work_dir" -name "terraform.tfstate" -exec cp {} "$backup_dir/" \; 2>/dev/null || true
    
    if [ "$(ls -A "$backup_dir" 2>/dev/null)" ]; then
        print_success "State backup created: $backup_dir"
    else
        print_warning "No state files found to backup"
        rmdir "$backup_dir" 2>/dev/null || true
    fi
}

# Function to show infrastructure outputs
show_outputs() {
    local env=$1
    print_status "Retrieving infrastructure outputs for $env environment..."
    
    local work_dir="environments/$env"
    
    echo -e "\n${CYAN}=== Infrastructure Outputs for $env ===${NC}"
    
    # Components to check for outputs
    local components=("security" "networking" "compute" "load-balancer")
    
    for component in "${components[@]}"; do
        local component_dir="$work_dir/$component"
        
        if [ -d "$component_dir" ]; then
            echo -e "\n${YELLOW}$component:${NC}"
            cd "$component_dir"
            
            if terragrunt output > /dev/null 2>&1; then
                terragrunt output 2>/dev/null | sed 's/^/  /'
            else
                echo "  No outputs available or not yet applied"
            fi
            
            cd - > /dev/null
        fi
    done
    
    echo ""
}

# Function to check deployment status
check_status() {
    local env=$1
    print_status "Checking deployment status for $env environment..."
    
    local work_dir="environments/$env"
    echo -e "\n${CYAN}=== Deployment Status for $env ===${NC}"
    
    local components=("security" "networking" "compute" "load-balancer")
    
    for component in "${components[@]}"; do
        local component_dir="$work_dir/$component"
        
        if [ -d "$component_dir" ]; then
            echo -e "\n${YELLOW}$component:${NC}"
            cd "$component_dir"
            
            # Check if state exists
            if terragrunt state list > /dev/null 2>&1; then
                local resource_count
                resource_count=$(terragrunt state list 2>/dev/null | wc -l)
                echo "  Status: Applied ($resource_count resources)"
                
                # Check for drift
                if terragrunt plan -detailed-exitcode > /dev/null 2>&1; then
                    echo "  Drift: No changes detected"
                else
                    echo "  Drift: Changes detected (run plan to see details)"
                fi
            else
                echo "  Status: Not applied"
            fi
            
            cd - > /dev/null
        fi
    done
    
    echo ""
}

# Enhanced deployment function with security components
deploy_infrastructure() {
    local env=$1
    local action=$2
    
    print_status "Starting $action for $env environment..."
    
    local work_dir="environments/$env"
    
    # Components to deploy in order (including security first)
    local components=("security" "networking" "compute" "load-balancer")
    
    # For destroy, reverse the order
    if [ "$action" == "destroy" ]; then
        components=("load-balancer" "compute" "networking" "security")
    fi
    
    print_status "Processing components in order: ${components[*]}"
    
    # Create backup before apply/destroy
    if [[ "$action" =~ ^(apply|destroy)$ ]]; then
        backup_state "$env"
    fi
    
    local failed_components=()
    
    for component in "${components[@]}"; do
        local component_dir="$work_dir/$component"
        
        if [ ! -d "$component_dir" ]; then
            print_warning "Component directory $component_dir does not exist, skipping..."
            continue
        fi
        
        print_status "Processing $component..."
        
        cd "$component_dir"
        
        # Run terragrunt command
        local cmd_output
        local cmd_result=0
        
        case $action in
            plan)
                print_status "Running terragrunt plan for $component..."
                cmd_output=$(terragrunt plan 2>&1) || cmd_result=$?
                ;;
            apply)
                print_status "Running terragrunt apply for $component..."
                # Add confirmation for production
                if [ "$env" == "prod" ] && [ "$component" != "security" ]; then
                    print_warning "About to apply $component to PRODUCTION environment"
                    read -p "Are you sure? (yes/no): " -r
                    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
                        print_warning "Skipping $component deployment"
                        cd - > /dev/null
                        continue
                    fi
                fi
                cmd_output=$(terragrunt apply -auto-approve 2>&1) || cmd_result=$?
                ;;
            destroy)
                print_warning "Running terragrunt destroy for $component..."
                # Always confirm for destroy
                print_warning "About to DESTROY $component in $env environment"
                read -p "Type 'yes' to confirm destruction: " -r
                if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
                    print_warning "Skipping $component destruction"
                    cd - > /dev/null
                    continue
                fi
                cmd_output=$(terragrunt destroy -auto-approve 2>&1) || cmd_result=$?
                ;;
        esac
        
        # Log the output
        echo "$cmd_output" >> "$LOG_FILE"
        
        if [ $cmd_result -ne 0 ]; then
            print_error "Failed to $action $component"
            print_error "Check log file for details: $LOG_FILE"
            failed_components+=("$component")
            
            # Show last few lines of error
            echo -e "\n${RED}Error output:${NC}"
            echo "$cmd_output" | tail -10
            
            # Ask if user wants to continue
            if [ ${#components[@]} -gt 1 ]; then
                read -p "Continue with remaining components? (yes/no): " -r
                if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
                    cd - > /dev/null
                    break
                fi
            fi
        else
            print_success "Completed $component successfully"
        fi
        
        cd - > /dev/null
    done
    
    # Summary
    if [ ${#failed_components[@]} -eq 0 ]; then
        print_success "All components processed successfully for $env environment!"
        
        # Show outputs after successful apply
        if [ "$action" == "apply" ]; then
            show_outputs "$env"
        fi
    else
        print_error "Some components failed: ${failed_components[*]}"
        print_error "Check the log file for details: $LOG_FILE"
        exit 1
    fi
}

# Main script logic
main() {
    print_header
    
    # Parse command line arguments
    if [ $# -eq 0 ]; then
        show_usage
        exit 1
    fi
    
    local command=$1
    shift
    
    case $command in
        "deploy")
            if [ $# -lt 1 ]; then
                print_error "Environment required for deploy command"
                show_usage
                exit 1
            fi
            
            local env=$1
            local action=${2:-plan}
            
            validate_environment "$env"
            validate_action "$action"
            validate_prerequisites
            validate_gcp_setup
            
            deploy_infrastructure "$env" "$action"
            ;;
        "validate")
            if [ $# -lt 1 ]; then
                print_error "Environment required for validate command"
                show_usage
                exit 1
            fi
            
            local env=$1
            validate_environment "$env"
            validate_prerequisites
            
            print_status "Validating Terragrunt configuration for $env..."
            cd "environments/$env"
            terragrunt validate-all
            cd - > /dev/null
            print_success "Validation completed"
            ;;
        "output")
            if [ $# -lt 1 ]; then
                print_error "Environment required for output command"
                show_usage
                exit 1
            fi
            
            local env=$1
            validate_environment "$env"
            validate_prerequisites
            
            show_outputs "$env"
            ;;
        "status")
            if [ $# -lt 1 ]; then
                print_error "Environment required for status command"
                show_usage
                exit 1
            fi
            
            local env=$1
            validate_environment "$env"
            validate_prerequisites
            
            check_status "$env"
            ;;
        "cleanup")
            if [ $# -lt 1 ]; then
                print_error "Environment required for cleanup command"
                show_usage
                exit 1
            fi
            
            local env=$1
            validate_environment "$env"
            
            cleanup_cache "$env"
            ;;
        "security-check")
            if [ $# -lt 1 ]; then
                print_error "Environment required for security-check command"
                show_usage
                exit 1
            fi
            
            local env=$1
            validate_environment "$env"
            validate_prerequisites
            
            run_security_check "$env"
            ;;
        "backup")
            if [ $# -lt 1 ]; then
                print_error "Environment required for backup command"
                show_usage
                exit 1
            fi
            
            local env=$1
            validate_environment "$env"
            
            backup_state "$env"
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            print_error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
    
    print_success "Script completed successfully!"
}

# Run main function with all arguments
main "$@"
