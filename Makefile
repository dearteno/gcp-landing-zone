.PHONY: help plan-dev apply-dev destroy-dev plan-staging apply-staging destroy-staging plan-prod apply-prod destroy-prod validate format

# Default target
help:
	@echo "GCP Landing Zone - Terragrunt with OpenTofu Management"
	@echo ""
	@echo "Available targets:"
	@echo "  help              Show this help message"
	@echo "  validate          Validate all OpenTofu configurations"
	@echo "  format            Format all OpenTofu files"
	@echo ""
	@echo "Development Environment:"
	@echo "  plan-dev          Plan dev environment infrastructure"
	@echo "  apply-dev         Apply dev environment infrastructure"
	@echo "  destroy-dev       Destroy dev environment infrastructure"
	@echo ""
	@echo "Staging Environment:"
	@echo "  plan-staging      Plan staging environment infrastructure"
	@echo "  apply-staging     Apply staging environment infrastructure"
	@echo "  destroy-staging   Destroy staging environment infrastructure"
	@echo ""
	@echo "Production Environment:"
	@echo "  plan-prod         Plan production environment infrastructure"
	@echo "  apply-prod        Apply production environment infrastructure"
	@echo "  destroy-prod      Destroy production environment infrastructure"

# Development environment
plan-dev:
	@echo "Planning dev environment..."
	./deploy.sh dev plan

apply-dev:
	@echo "Applying dev environment..."
	./deploy.sh dev apply

destroy-dev:
	@echo "Destroying dev environment..."
	@read -p "Are you sure you want to destroy the dev environment? [y/N] " confirm && [ "$$confirm" = "y" ]
	./deploy.sh dev destroy

# Staging environment
plan-staging:
	@echo "Planning staging environment..."
	./deploy.sh staging plan

apply-staging:
	@echo "Applying staging environment..."
	./deploy.sh staging apply

destroy-staging:
	@echo "Destroying staging environment..."
	@read -p "Are you sure you want to destroy the staging environment? [y/N] " confirm && [ "$$confirm" = "y" ]
	./deploy.sh staging destroy

# Production environment
plan-prod:
	@echo "Planning production environment..."
	./deploy.sh prod plan

apply-prod:
	@echo "Applying production environment..."
	@read -p "Are you sure you want to apply to PRODUCTION? [y/N] " confirm && [ "$$confirm" = "y" ]
	./deploy.sh prod apply

destroy-prod:
	@echo "Destroying production environment..."
	@echo "This is a PRODUCTION environment!"
	@read -p "Type 'DELETE_PRODUCTION' to confirm: " confirm && [ "$$confirm" = "DELETE_PRODUCTION" ]
	./deploy.sh prod destroy

# Utility targets
validate:
	@echo "Validating OpenTofu configurations..."
	@find . -name "*.tf" -type f -exec dirname {} \; | sort -u | while read dir; do \
		echo "Validating $$dir..."; \
		(cd "$$dir" && tofu init -backend=false > /dev/null && tofu validate) || exit 1; \
	done
	@echo "All configurations are valid!"

format:
	@echo "Formatting OpenTofu files..."
	tofu fmt -recursive .
	@echo "Formatting complete!"
