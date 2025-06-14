# Copilot Instructions for GCP Landing Zone Project

This document provides comprehensive guidance for AI assistants working with the GCP Landing Zone Terragrunt/OpenTofu project.

## 📋 Project Overview

**Project Name:** GCP Landing Zone with Terragrunt and OpenTofu - Security Hardened  
**Version:** v2.1.0  
**Status:** Production-ready, all configurations validated  
**Last Updated:** June 14, 2025  

### 🎯 Project Purpose
This is an enterprise-grade Google Cloud Platform landing zone that provides:
- Multi-environment infrastructure (dev, staging, production)
- Security-hardened GKE clusters with private nodes
- Comprehensive networking with VPC, NAT, and firewall controls
- Load balancing with Google-managed SSL certificates
- Binary Authorization for container image security
- Complete compliance and monitoring setup

## 🏗️ Architecture Understanding

### **Current Project Structure**
```
gcp-landing-zone/
├── root.hcl                    # Root Terragrunt configuration (centralized)
├── environments/               # Environment-specific configurations
│   ├── dev/                   # Development environment
│   ├── staging/               # Staging environment
│   └── prod/                  # Production environment
├── modules/                   # OpenTofu modules
│   ├── networking/            # VPC, subnets, NAT, firewall
│   ├── compute/               # GKE clusters and node pools
│   ├── security/              # KMS, IAM, Binary Authorization
│   └── load-balancer/         # Load balancers and SSL certificates
├── Taskfile.yml              # Modern task runner (27+ tasks)
├── deploy.sh                  # Enhanced deployment script
├── logs/                      # Deployment logs
└── docs/                      # Documentation files
```

### **Key Technologies**
- **OpenTofu**: Open-source Terraform alternative (≥ 1.6.0)
- **Terragrunt**: Infrastructure orchestration (≥ 0.50.0)
- **Task**: Modern task runner replacing Make
- **Google Cloud Platform**: Target cloud provider
- **Kubernetes (GKE)**: Container orchestration

## 🔧 Configuration Management

### **Current Configuration Status (v2.1.0)**
```
✅ All OpenTofu modules validated successfully
✅ No circular dependencies in Terragrunt structure
✅ Google-managed SSL certificates configured
✅ Modern Binary Authorization implementation
✅ Enhanced security controls validated
✅ Comprehensive task automation available
```

### **Important Configuration Details**
- **Terragrunt Structure**: Single-level includes using `root.hcl`
- **No common/ directory**: Configuration merged into environment-specific files
- **Binary Authorization**: Uses `PROJECT_SINGLETON_POLICY_ENFORCE` mode
- **SSL Certificates**: Google-managed certificates (no self-signed)
- **Logging**: SYSTEM_COMPONENTS, WORKLOADS, APISERVER (not API_SERVER)

## 🛠️ Development Guidelines

### **Making Changes**
1. **Always validate before and after changes**:
   ```bash
   task validate        # OpenTofu validation
   task validate-all    # Complete validation including Terragrunt
   ```

2. **Use proper tools**:
   ```bash
   task format          # Format all code
   task clean           # Clean cache files
   task plan-dev        # Plan changes for dev environment
   ```

3. **Follow security best practices**:
   - Maintain private cluster configurations
   - Preserve workload identity settings
   - Keep encryption configurations intact
   - Validate security modules after changes

### **Common Tasks**
```bash
# Validation and formatting
task validate-all               # Complete validation
task format                     # Format all OpenTofu files
task clean                      # Clean temporary files

# Environment operations
task plan-dev                   # Plan development environment
task apply-staging              # Apply staging environment
task destroy-prod               # Destroy production (with confirmation)

# Batch operations
task plan-all                   # Plan all environments
task init-all                   # Initialize all environments

# Security validation
./deploy.sh security-check dev  # Security-specific validation
./deploy.sh validate staging    # Terragrunt validation
```

## 🔒 Security Considerations

### **Critical Security Features**
- **Private GKE Clusters**: No public endpoints
- **Workload Identity**: Secure pod-to-GCP authentication
- **Binary Authorization**: Container image validation
- **Google-Managed SSL**: Automatic certificate management
- **Network Policies**: Pod-to-pod traffic control
- **VPC Flow Logs**: Network traffic monitoring
- **Cloud KMS**: Customer-managed encryption keys

### **Security Validation**
Always verify security configurations after changes:
```bash
# Validate security modules
task validate
./deploy.sh security-check dev
./deploy.sh verify-encryption dev
```

### **Security Best Practices**
- Never disable private cluster settings
- Maintain workload identity configurations
- Preserve binary authorization policies
- Keep firewall rules restrictive
- Maintain audit logging configurations

## 📝 Code Standards

### **OpenTofu/Terraform Standards**
- Use consistent indentation (2 spaces)
- Include descriptive resource names
- Add comments for complex configurations
- Use variables for environment-specific values
- Include proper resource dependencies

### **Terragrunt Standards**
- Use `include` blocks correctly (single-level from root.hcl)
- Define proper `locals` blocks with required variables
- Include proper `inputs` for modules
- Use `dependency` blocks for inter-module dependencies
- Include mock outputs for validation

### **Variable Naming**
- `project_id`: GCP project identifier
- `region`: GCP region (e.g., us-central1)
- `zone`: GCP zone (e.g., us-central1-a)
- `environment`: Environment name (dev, staging, prod)
- `cluster_name`: GKE cluster name
- `network_name`: VPC network name

## 🚨 Common Issues and Solutions

### **Validation Errors**
1. **Provider Version Conflicts**:
   ```bash
   task clean  # Clear cache
   task validate  # Re-validate
   ```

2. **Circular Dependencies**:
   - Check dependency blocks in terragrunt.hcl files
   - Ensure security module doesn't depend on compute module
   - Validate dependency graph is clean

3. **Missing Variables**:
   - Check variables.tf files for required variables
   - Ensure all inputs are defined in terragrunt.hcl
   - Verify mock outputs are present

### **Deployment Issues**
1. **GCP Credentials**:
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
   ```

2. **State Management**:
   - Ensure GCS bucket exists for remote state
   - Verify bucket permissions
   - Check state locking configuration

## 📚 Documentation Standards

### **When to Update Documentation**
- After any architectural changes
- When adding new modules or features
- After security configuration updates
- When changing deployment procedures

### **Key Documentation Files**
- `README.md`: Main project documentation
- `SECURITY.md`: Security configuration and best practices
- `CHANGELOG.md`: Version history and changes
- `network-diagram.md`: Architecture diagrams
- `copilot-instructions.md`: This file

### **Documentation Style**
- Use clear, descriptive headings
- Include practical examples
- Provide validation commands
- Keep status information current
- Include troubleshooting guidance

## 🔍 Troubleshooting Guide

### **Validation Failures**
1. Check OpenTofu syntax: `task validate`
2. Verify Terragrunt configuration: `task validate-terragrunt`
3. Clean cache and retry: `task clean && task validate`
4. Check for deprecated resource attributes
5. Verify provider version compatibility

### **Deployment Failures**
1. Verify GCP authentication
2. Check resource quotas and limits
3. Validate IAM permissions
4. Review firewall rules and network policies
5. Check for resource naming conflicts

### **Security Issues**
1. Verify private cluster configuration
2. Check workload identity settings
3. Validate binary authorization policies
4. Review firewall rules
5. Confirm encryption settings

## 🎯 Best Practices for AI Assistance

### **When Helping Users**
1. **Always validate first**: Run `task validate` before making changes
2. **Use appropriate tools**: Prefer task commands over manual operations
3. **Maintain security posture**: Never compromise security configurations
4. **Update documentation**: Keep documentation current with changes
5. **Test thoroughly**: Validate all changes before completion

### **Code Changes**
1. **Read existing code**: Understand current implementation before changing
2. **Use proper syntax**: Follow OpenTofu/Terragrunt best practices
3. **Preserve dependencies**: Maintain proper resource relationships
4. **Include validation**: Always validate changes
5. **Update related files**: Keep all documentation synchronized

### **Security Focus**
1. **Never disable security features**: Maintain security hardening
2. **Preserve private configurations**: Keep clusters and resources private
3. **Validate security modules**: Always check security after changes
4. **Document security changes**: Update SECURITY.md when relevant
5. **Follow compliance requirements**: Maintain compliance frameworks

## 📊 Project Health Indicators

### **Healthy Project State**
```
✅ All modules validate successfully
✅ No circular dependencies
✅ Security configurations intact
✅ Documentation up-to-date
✅ Task automation working
✅ GCP credentials configured (for deployment)
```

### **Warning Signs**
```
❌ Validation failures
❌ Circular dependency errors
❌ Security modules failing
❌ Deprecated configuration usage
❌ Missing required variables
❌ Outdated documentation
```

This project represents enterprise-grade infrastructure with comprehensive security and modern DevOps practices. Always maintain the high standards established and help users achieve their infrastructure goals while preserving security and reliability.
