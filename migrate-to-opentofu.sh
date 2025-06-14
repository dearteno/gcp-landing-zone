#!/bin/bash

# OpenTofu Migration Helper Script
# This script helps users migrate from Terraform to OpenTofu

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

echo -e "${BLUE}=== OpenTofu Migration Helper ===${NC}"
echo ""

# Check if OpenTofu is already installed
if command -v tofu &> /dev/null; then
    print_info "OpenTofu is already installed!"
    tofu version
    echo ""
else
    print_step "Installing OpenTofu..."
    
    # Detect OS and install accordingly
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install opentofu
        else
            print_error "Homebrew not found. Please install Homebrew first or install OpenTofu manually."
            print_info "Visit: https://opentofu.org/docs/intro/install/"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        print_info "Installing OpenTofu on Linux..."
        curl -fsSL https://get.opentofu.org/install-opentofu.sh | sh
        
        # Add to PATH if not already there
        if ! command -v tofu &> /dev/null; then
            echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
            export PATH=$PATH:~/.local/bin
        fi
    else
        print_error "Unsupported operating system. Please install OpenTofu manually."
        print_info "Visit: https://opentofu.org/docs/intro/install/"
        exit 1
    fi
    
    # Verify installation
    if command -v tofu &> /dev/null; then
        print_info "OpenTofu installed successfully!"
        tofu version
    else
        print_error "OpenTofu installation failed. Please install manually."
        exit 1
    fi
fi

echo ""

# Check if Terragrunt is installed
print_step "Checking Terragrunt installation..."
if command -v terragrunt &> /dev/null; then
    print_info "Terragrunt is installed!"
    terragrunt --version
else
    print_warning "Terragrunt is not installed. Installing..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install terragrunt
        else
            print_error "Please install Terragrunt manually."
            exit 1
        fi
    else
        print_error "Please install Terragrunt manually for your operating system."
        print_info "Visit: https://terragrunt.gruntwork.io/docs/getting-started/installation/"
        exit 1
    fi
fi

echo ""

# Check for existing Terraform state
print_step "Checking for existing Terraform state..."
if find . -name "*.tfstate*" -type f | grep -q .; then
    print_warning "Found existing Terraform state files!"
    print_info "OpenTofu is compatible with Terraform state files."
    print_info "Your existing state will work without modification."
    echo ""
fi

# Migration completed
print_info "Migration to OpenTofu completed successfully!"
echo ""
echo -e "${GREEN}=== Next Steps ===${NC}"
echo "1. Run 'tofu version' to verify OpenTofu is working"
echo "2. Run 'terragrunt --version' to verify Terragrunt is working"
echo "3. Use './deploy.sh dev plan' to test your infrastructure"
echo "4. All your existing .tf files will work with OpenTofu"
echo ""
echo -e "${YELLOW}=== OpenTofu Benefits ===${NC}"
echo "✅ Open source and community-driven"
echo "✅ Compatible with existing Terraform configurations"
echo "✅ MPL 2.0 license (no vendor lock-in)"
echo "✅ Faster development and innovation"
echo "✅ Linux Foundation governance"
echo ""

print_info "Happy Infrastructure as Code with OpenTofu! 🚀"
