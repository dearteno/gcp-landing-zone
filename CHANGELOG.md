# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2025-06-14

### Added
- **Taskfile.yml** - Modern task runner replacing Makefile with 27+ comprehensive tasks
- **Batch operations** - `plan-all`, `validate-all`, `init-all` for multi-environment workflows
- **Enhanced validation tasks** - Separate OpenTofu and Terragrunt validation
- **Utility tasks** - `clean`, `format` for maintenance operations
- **Google-managed SSL certificates** - Automatic SSL certificate provisioning and renewal
- **Missing variables** - Added `environment` variable to compute module and `ssl_domains` to load-balancer module

### Changed
- **Replaced Makefile with Taskfile** - Better cross-platform support and YAML syntax
- **Updated Binary Authorization** - Changed from deprecated `enable_binary_authorization` to proper `binary_authorization` block
- **Modernized SSL certificates** - Switched from self-signed to Google-managed certificates
- **Updated logging configuration** - Fixed component names to match current Google provider requirements
- **Enhanced README** - Added comprehensive Task usage documentation

### Fixed
- **OpenTofu validation errors** across all modules:
  - Removed unsupported `istio_config` block from compute module
  - Fixed `preemptible` placement in cluster autoscaling configuration
  - Removed deprecated `pod_security_policy_config` block
  - Fixed logging component name (`API_SERVER` → `APISERVER`)
  - Fixed binary authorization policy output attribute
  - Resolved SSL certificate file path errors
- **Missing variable declarations** - Added required variables for proper module functionality
- **Resource references** - Updated all SSL certificate references to use managed certificates

### Removed
- **Makefile** - Replaced with Taskfile.yml (backup kept as Makefile.backup)
- **Deprecated configurations** - Removed pod security policy and other deprecated blocks
- **Self-signed SSL certificate files** - No longer needed with Google-managed certificates

### Security
- **Enhanced container security** - Updated binary authorization configuration
- **Improved certificate management** - Automatic SSL certificate renewal
- **Better secret management** - Removed hardcoded certificate paths

## [2.0.0] - 2025-06-14

### Added
- **Complete project restructure** - Fixed multi-level Terragrunt includes and circular dependencies
- **Standardized configurations** - Consistent structure across all environments (dev, staging, prod)
- **Enhanced deploy.sh** - Improved validation, error handling, and user experience
- **Comprehensive documentation** - Added FIX_SUMMARY.md, SECURITY.md, network-diagram.md
- **Security hardening** - Enterprise-grade security controls and best practices

### Changed
- **Terragrunt configuration hierarchy** - Flattened to single-level includes using root.hcl
- **Environment structure** - Removed common/ directory, merged into environment-specific configs
- **Dependency management** - Resolved circular dependencies between security and compute modules
- **Variable standardization** - Consistent naming and structure across all modules

### Fixed
- **Circular dependencies** - Removed problematic dependencies causing stack overflow errors
- **Configuration syntax** - Fixed extra braces and malformed configuration blocks
- **Include paths** - Updated all Terragrunt includes to use proper relative paths
- **Mock outputs** - Added proper mock outputs for all module dependencies

### Removed
- **common/ directory** - Configuration merged into environment-specific files
- **Multi-level includes** - Simplified to direct root.hcl includes
- **Circular dependencies** - Clean dependency graph with proper module separation

## [1.0.0] - Initial Release

### Added
- **Multi-environment GCP landing zone** - Support for dev, staging, and production environments
- **Enterprise security controls** - Comprehensive security hardening and compliance
- **OpenTofu integration** - Modern open-source alternative to Terraform
- **Modular architecture** - Separate modules for networking, compute, security, and load balancing
- **GKE private clusters** - Secure Kubernetes clusters with workload identity
- **Advanced networking** - VPC, subnets, NAT, firewall rules with security best practices
- **Load balancing** - External and internal load balancers with SSL/TLS termination
- **Security monitoring** - Integration with Security Command Center and Cloud KMS
