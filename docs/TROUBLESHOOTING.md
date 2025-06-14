# Troubleshooting Guide - GCP Landing Zone

This comprehensive troubleshooting guide helps you diagnose and resolve common issues with the GCP Landing Zone deployment.

## 🚨 Quick Diagnosis

### Health Check Commands
```bash
# Quick validation of all configurations
task validate-all

# Check Terragrunt dependency graph
terragrunt graph-dependencies

# Verify GCP authentication
gcloud auth list
gcloud config list

# Check project permissions
gcloud projects get-iam-policy YOUR_PROJECT_ID
```

---

## 🔧 Common Issues & Solutions

### 1. Authentication & Permissions

#### Issue: "Application Default Credentials not found"
```
Error: google: could not find default credentials
```

**Solutions:**
```bash
# Option 1: Use service account key
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"

# Option 2: Use gcloud auth
gcloud auth application-default login

# Option 3: Use workload identity (for CI/CD)
gcloud auth activate-service-account --key-file=/path/to/key.json
```

#### Issue: "Insufficient permissions"
```
Error: Error when reading or editing Project: Request had insufficient authentication scopes
```

**Solutions:**
```bash
# Check current authentication
gcloud auth list

# Re-authenticate with required scopes
gcloud auth application-default login --scopes=https://www.googleapis.com/auth/cloud-platform

# Verify project access
gcloud projects describe YOUR_PROJECT_ID
```

#### Issue: "Service account missing roles"
```
Error: Required 'compute.networks.create' permission for 'projects/PROJECT_ID'
```

**Required IAM Roles:**
```bash
# Grant necessary roles to service account
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:terraform@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/compute.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:terraform@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/container.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:terraform@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountAdmin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:terraform@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/cloudkms.admin"
```

### 2. Terragrunt Configuration Issues

#### Issue: "Circular dependency detected"
```
Error: Found a dependency cycle between modules
```

**Diagnosis:**
```bash
# Check dependency graph
cd environments/dev
terragrunt graph-dependencies
```

**Solution:**
```bash
# Review and fix dependencies in terragrunt.hcl files
# Ensure no circular references between modules
# Example fix: Remove compute dependency from security module
```

#### Issue: "Include file not found"
```
Error: Could not find a root.hcl file in the parent folders
```

**Solutions:**
```bash
# Verify file structure
ls -la root.hcl

# Check include path in terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Ensure you're running from correct directory
pwd
```

#### Issue: "Mock outputs not working"
```
Error: Module has not been applied yet
```

**Solution:**
```hcl
# Add proper mock outputs in terragrunt.hcl
dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    network_name = "mock-vpc"
    subnet_name  = "mock-subnet"
    external_lb_ip = "1.2.3.4"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}
```

### 3. OpenTofu/Terraform Issues

#### Issue: "Provider version conflicts"
```
Error: Failed to query available provider packages
```

**Solutions:**
```bash
# Clear provider cache
rm -rf .terraform
rm .terraform.lock.hcl

# Reinitialize with specific provider versions
tofu init -upgrade

# Check provider constraints in root.hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
```

#### Issue: "State file locked"
```
Error: Error acquiring the state lock
```

**Solutions:**
```bash
# Check who has the lock
terragrunt state list

# Force unlock (use with caution)
terragrunt force-unlock LOCK_ID

# Alternative: Wait for lock to expire (usually 20 minutes)
```

#### Issue: "Resource already exists"
```
Error: A resource with this name already exists
```

**Solutions:**
```bash
# Import existing resource
terragrunt import google_compute_network.vpc_network projects/PROJECT_ID/global/networks/NETWORK_NAME

# Or destroy and recreate (if safe)
terragrunt destroy
terragrunt apply
```

### 4. GCP Resource Issues

#### Issue: "Quota exceeded"
```
Error: Quota 'CPUS' exceeded. Limit: 24.0 in region us-central1
```

**Solutions:**
```bash
# Check current quotas
gcloud compute project-info describe --project=YOUR_PROJECT_ID

# Request quota increase
gcloud compute regions describe us-central1

# Reduce resource requirements temporarily
# Edit terragrunt.hcl:
machine_type = "e2-standard-2"  # Instead of e2-standard-8
max_node_count = 3              # Instead of 10
```

#### Issue: "API not enabled"
```
Error: googleapi: Error 403: Compute Engine API has not been used
```

**Solutions:**
```bash
# Enable required APIs
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable cloudkms.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable logging.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable servicenetworking.googleapis.com
gcloud services enable dns.googleapis.com

# Verify APIs are enabled
gcloud services list --enabled
```

#### Issue: "Network not found"
```
Error: The resource 'projects/PROJECT_ID/global/networks/NETWORK_NAME' was not found
```

**Solutions:**
```bash
# Check if network exists
gcloud compute networks list

# Verify network name in configuration
# Check dependency outputs
terragrunt output -raw network_name

# Deploy networking module first
cd environments/dev/networking
terragrunt apply
```

### 5. GKE Cluster Issues

#### Issue: "Master authorized networks error"
```
Error: Invalid value for field 'cluster.masterAuthorizedNetworksConfig'
```

**Solutions:**
```hcl
# Fix authorized networks configuration
authorized_networks = [
  {
    cidr_block   = "10.0.0.0/8"
    display_name = "Internal networks"
  }
]

# Ensure CIDR blocks are valid
# Remove any overlapping or invalid ranges
```

#### Issue: "Private cluster connectivity"
```
Error: Unable to connect to the server: dial tcp: lookup on 8.8.8.8:53: no such host
```

**Solutions:**
```bash
# Check private cluster configuration
gcloud container clusters describe CLUSTER_NAME --region=REGION

# Verify authorized networks include your IP
gcloud compute addresses list

# Use bastion host or Cloud Shell for access
gcloud container clusters get-credentials CLUSTER_NAME --region=REGION
```

#### Issue: "Node pool creation failed"
```
Error: Error creating NodePool: googleapi: Error 400: Invalid value for field
```

**Solutions:**
```bash
# Check node pool configuration
# Verify machine type is available in region
gcloud compute machine-types list --filter="zone:us-central1-a"

# Check disk size limits
# Ensure service account exists
gcloud iam service-accounts list
```

### 6. Load Balancer Issues

#### Issue: "SSL certificate provisioning failed"
```
Error: SSL certificate failed to provision
```

**Solutions:**
```bash
# Check domain ownership
nslookup YOUR_DOMAIN

# Verify DNS configuration
dig YOUR_DOMAIN

# Check certificate status
gcloud compute ssl-certificates list

# Ensure domains are properly configured
ssl_domains = ["yourdomain.com", "www.yourdomain.com"]
```

#### Issue: "Backend service unhealthy"
```
Error: All backend instances are unhealthy
```

**Solutions:**
```bash
# Check health check configuration
gcloud compute health-checks list

# Verify firewall rules allow health checks
gcloud compute firewall-rules list

# Check backend instances
gcloud compute instance-groups list
```

### 7. Security Module Issues

#### Issue: "KMS key creation failed"
```
Error: Error creating KeyRing: googleapi: Error 409: KeyRing already exists
```

**Solutions:**
```bash
# Import existing keyring
terragrunt import google_kms_key_ring.security_keyring projects/PROJECT_ID/locations/REGION/keyRings/KEYRING_NAME

# Or use different keyring name
keyring_name = "${var.environment}-security-keyring-v2"
```

#### Issue: "Binary Authorization policy error"
```
Error: Error creating BinaryAuthorizationPolicy
```

**Solutions:**
```hcl
# Update to current Binary Authorization syntax
binary_authorization {
  evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
}

# Check if Binary Authorization API is enabled
gcloud services enable binaryauthorization.googleapis.com
```

---

## 🔍 Debugging Techniques

### 1. Enable Debug Logging
```bash
# Enable detailed OpenTofu logging
export TF_LOG=DEBUG
export TF_LOG_PATH=./debug.log

# Run with debug output
terragrunt apply
```

### 2. Validate Configuration Step by Step
```bash
# Validate syntax
tofu validate

# Check formatting
tofu fmt -check

# Plan without applying
terragrunt plan

# Show current state
terragrunt state list
```

### 3. Check Resource Dependencies
```bash
# Show dependency graph
terragrunt graph-dependencies

# Check specific resource
terragrunt state show google_compute_network.vpc_network

# List all resources
terragrunt state list
```

### 4. Network Connectivity Testing
```bash
# Test from Cloud Shell
gcloud cloud-shell ssh

# Test connectivity to private resources
ping 10.0.1.1

# Check firewall rules
gcloud compute firewall-rules list --filter="network:YOUR_NETWORK"
```

---

## 🚨 Emergency Procedures

### 1. Complete Environment Reset
```bash
# WARNING: This will destroy all resources
cd environments/dev
terragrunt run-all destroy --terragrunt-non-interactive

# Clean up state files
rm -rf .terragrunt-cache
find . -name "terraform.tfstate*" -delete

# Redeploy from scratch
terragrunt run-all apply
```

### 2. Partial Recovery
```bash
# Destroy only problematic module
cd environments/dev/compute
terragrunt destroy

# Redeploy specific module
terragrunt apply
```

### 3. State File Recovery
```bash
# List state file versions
gsutil ls -l gs://YOUR_STATE_BUCKET/environments/dev/

# Restore from backup
gsutil cp gs://YOUR_STATE_BUCKET/environments/dev/terraform.tfstate.backup ./terraform.tfstate

# Refresh state
terragrunt refresh
```

---

## 📊 Monitoring & Alerting

### 1. Set Up Monitoring
```bash
# Enable monitoring APIs
gcloud services enable monitoring.googleapis.com
gcloud services enable logging.googleapis.com

# Create monitoring workspace
gcloud alpha monitoring workspaces create
```

### 2. Check Logs
```bash
# View deployment logs
tail -f logs/deploy-*.log

# Check GCP logs
gcloud logging read "resource.type=gce_instance" --limit=50

# Monitor specific resources
gcloud logging read "resource.type=k8s_cluster" --limit=50
```

### 3. Health Checks
```bash
# Check cluster health
kubectl get nodes
kubectl get pods --all-namespaces

# Check load balancer health
gcloud compute backend-services get-health BACKEND_SERVICE_NAME --global
```

---

## 📞 Getting Help

### 1. Community Resources
- [OpenTofu Community](https://opentofu.org/community/)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
- [GCP Support](https://cloud.google.com/support)

### 2. Internal Documentation
- [API Reference](./API_REFERENCE.md)
- [Security Guide](../SECURITY.md)
- [Network Diagram](../network-diagram.md)

### 3. Support Channels
- GitHub Issues: Report bugs and feature requests
- Internal Slack: #infrastructure-support
- Email: infrastructure-team@company.com

---

## 📋 Troubleshooting Checklist

Before seeking help, ensure you've checked:

- [ ] GCP authentication is working (`gcloud auth list`)
- [ ] Required APIs are enabled (`gcloud services list --enabled`)
- [ ] Service account has necessary permissions
- [ ] Configuration syntax is valid (`tofu validate`)
- [ ] Dependencies are deployed in correct order
- [ ] No circular dependencies exist
- [ ] Mock outputs are properly configured
- [ ] Resource quotas are sufficient
- [ ] Network connectivity is established
- [ ] Logs have been reviewed for specific errors

---

## 🔄 Version-Specific Issues

### OpenTofu v1.6.0+
- Ensure provider compatibility
- Check for deprecated syntax
- Update provider versions

### Terragrunt v0.50.0+
- New include syntax supported
- Enhanced dependency management
- Updated CLI commands

### Google Provider v5.0+
- Binary Authorization syntax changes
- Updated logging configuration
- New SSL certificate management

---

**Remember**: Always test changes in the dev environment first, and maintain regular backups of your state files!