# Migration Guide - GCP Landing Zone

This guide helps you migrate existing GCP infrastructure to the OpenTofu/Terragrunt-based landing zone or upgrade from previous versions.

## 📋 Migration Scenarios

### 1. [Fresh Deployment](#fresh-deployment) - New GCP project
### 2. [Terraform to OpenTofu](#terraform-to-opentofu) - Existing Terraform infrastructure
### 3. [Legacy GCP to Landing Zone](#legacy-gcp-to-landing-zone) - Existing manual GCP resources
### 4. [Version Upgrades](#version-upgrades) - Upgrading landing zone versions

---

## 🆕 Fresh Deployment

### Prerequisites
- New GCP project with billing enabled
- Project owner or editor permissions
- Required APIs enabled

### Step-by-Step Process

#### 1. Project Setup
```bash
# Set project variables
export PROJECT_ID="your-new-project-id"
export REGION="us-central1"
export ZONE="us-central1-a"

# Set default project
gcloud config set project $PROJECT_ID

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
gcloud services enable binaryauthorization.googleapis.com
```

#### 2. Authentication Setup
```bash
# Create service account for Terragrunt
gcloud iam service-accounts create terragrunt-sa \
    --display-name="Terragrunt Service Account"

# Grant necessary roles
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:terragrunt-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/compute.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:terragrunt-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/container.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:terragrunt-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountAdmin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:terragrunt-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/cloudkms.admin"

# Create and download key
gcloud iam service-accounts keys create terragrunt-key.json \
    --iam-account=terragrunt-sa@$PROJECT_ID.iam.gserviceaccount.com

# Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/terragrunt-key.json"
```

#### 3. State Bucket Setup
```bash
# Create bucket for Terragrunt state
gsutil mb gs://$PROJECT_ID-terragrunt-state

# Enable versioning
gsutil versioning set on gs://$PROJECT_ID-terragrunt-state

# Update root.hcl with your bucket name
sed -i "s/your-terraform-state-bucket/$PROJECT_ID-terragrunt-state/g" root.hcl
```

#### 4. Configuration Updates
```bash
# Update project ID in root.hcl
sed -i "s/your-project-id/$PROJECT_ID/g" root.hcl

# Update project ID in all environment files
find environments/ -name "terragrunt.hcl" -exec sed -i "s/your-project-id/$PROJECT_ID/g" {} \;

# Update region if different
find . -name "terragrunt.hcl" -exec sed -i "s/us-central1/$REGION/g" {} \;
```

#### 5. Deploy Infrastructure
```bash
# Start with development environment
cd environments/dev

# Initialize and validate
terragrunt run-all init
terragrunt run-all validate

# Plan deployment
terragrunt run-all plan

# Apply infrastructure
terragrunt run-all apply
```

---

## 🔄 Terraform to OpenTofu

### Migration Overview
This section covers migrating from existing Terraform-managed GCP infrastructure to OpenTofu with Terragrunt.

### Pre-Migration Assessment

#### 1. Inventory Current Infrastructure
```bash
# List all Terraform resources
terraform state list

# Export current state
terraform state pull > current-state.json

# Document current configuration
terraform show -json > current-config.json
```

#### 2. Backup Current State
```bash
# Create backup directory
mkdir -p migration-backup/$(date +%Y%m%d)

# Backup state files
cp terraform.tfstate* migration-backup/$(date +%Y%m%d)/

# Backup configuration files
cp -r *.tf migration-backup/$(date +%Y%m%d)/
```

### Migration Process

#### 1. Install OpenTofu
```bash
# Install OpenTofu
curl -fsSL https://get.opentofu.org/install-opentofu.sh | sh

# Verify installation
tofu version
```

#### 2. Convert Configuration Files

**Option A: Automatic Conversion**
```bash
# Use the provided migration script
./migrate-to-opentofu.sh

# Review changes
git diff
```

**Option B: Manual Conversion**
```bash
# Replace terraform binary references
find . -name "*.tf" -exec sed -i 's/terraform {/terraform {/g' {} \;

# Update provider sources if needed
find . -name "*.tf" -exec sed -i 's/hashicorp\/terraform/hashicorp\/terraform/g' {} \;
```

#### 3. State Migration
```bash
# Initialize with OpenTofu
tofu init

# Verify state compatibility
tofu plan

# If plan shows no changes, migration is successful
# If changes are detected, review and adjust configuration
```

#### 4. Restructure for Terragrunt

**Create Terragrunt Structure:**
```bash
# Create environment directories
mkdir -p environments/{dev,staging,prod}/{networking,security,compute,load-balancer}

# Move existing configurations to modules
mkdir -p modules/{networking,security,compute,load-balancer}
```

**Split Monolithic Configuration:**
```bash
# Example: Extract networking resources
grep -A 20 "resource \"google_compute_network\"" main.tf > modules/networking/main.tf
grep -A 10 "variable.*network" variables.tf > modules/networking/variables.tf
grep -A 5 "output.*network" outputs.tf > modules/networking/outputs.tf
```

#### 5. Import Existing Resources
```bash
# Import existing resources into new structure
cd environments/dev/networking

# Import VPC network
terragrunt import google_compute_network.vpc_network projects/$PROJECT_ID/global/networks/existing-vpc

# Import subnet
terragrunt import google_compute_subnetwork.subnetwork projects/$PROJECT_ID/regions/$REGION/subnetworks/existing-subnet

# Continue for all resources...
```

### Post-Migration Validation

#### 1. Verify Resource State
```bash
# Compare resource counts
terraform state list | wc -l  # Old count
terragrunt state list | wc -l  # New count

# Verify no drift
terragrunt plan  # Should show no changes
```

#### 2. Test Functionality
```bash
# Test basic operations
terragrunt plan
terragrunt apply

# Verify infrastructure works
kubectl get nodes  # For GKE clusters
gcloud compute instances list  # For compute instances
```

---

## 🏗️ Legacy GCP to Landing Zone

### Assessment Phase

#### 1. Infrastructure Discovery
```bash
# List all compute resources
gcloud compute instances list
gcloud compute networks list
gcloud compute firewall-rules list

# List GKE clusters
gcloud container clusters list

# List load balancers
gcloud compute forwarding-rules list
gcloud compute backend-services list

# List security resources
gcloud kms keyrings list --location=global
gcloud iam service-accounts list
```

#### 2. Document Current Architecture
```bash
# Export current configuration
gcloud compute networks describe NETWORK_NAME --format=json > current-network.json
gcloud container clusters describe CLUSTER_NAME --zone=ZONE --format=json > current-cluster.json

# Create architecture diagram
# Document dependencies and relationships
```

### Migration Strategy

#### 1. Parallel Deployment Approach (Recommended)
```bash
# Deploy new landing zone alongside existing infrastructure
# Use different network/project for testing
# Gradually migrate workloads

# Create new VPC for landing zone
network_name = "landing-zone-vpc"  # Different from existing

# Deploy in phases:
# Phase 1: Networking
# Phase 2: Security
# Phase 3: Compute
# Phase 4: Load Balancer
# Phase 5: Workload Migration
```

#### 2. In-Place Migration Approach (Advanced)
```bash
# Import existing resources into Terragrunt
# Requires careful planning and testing

# Example: Import existing VPC
cd environments/prod/networking
terragrunt import google_compute_network.vpc_network projects/$PROJECT_ID/global/networks/existing-vpc
```

### Resource-Specific Migration

#### 1. VPC Networks
```bash
# Export existing network configuration
gcloud compute networks describe existing-vpc --format=json

# Import into landing zone
terragrunt import google_compute_network.vpc_network projects/$PROJECT_ID/global/networks/existing-vpc

# Update configuration to match existing settings
```

#### 2. GKE Clusters
```bash
# Document existing cluster configuration
gcloud container clusters describe existing-cluster --zone=$ZONE

# Option A: Import existing cluster
terragrunt import google_container_cluster.primary projects/$PROJECT_ID/locations/$ZONE/clusters/existing-cluster

# Option B: Create new cluster and migrate workloads
# Deploy new cluster with landing zone
# Use blue-green deployment for workload migration
```

#### 3. Load Balancers
```bash
# List existing load balancers
gcloud compute forwarding-rules list

# Import backend services
terragrunt import google_compute_backend_service.external_backend_service projects/$PROJECT_ID/global/backendServices/existing-backend

# Import forwarding rules
terragrunt import google_compute_global_forwarding_rule.external_forwarding_rule projects/$PROJECT_ID/global/forwardingRules/existing-rule
```

#### 4. Security Resources
```bash
# Import KMS keyrings
terragrunt import google_kms_key_ring.security_keyring projects/$PROJECT_ID/locations/$REGION/keyRings/existing-keyring

# Import service accounts
terragrunt import google_service_account.gke_node_sa projects/$PROJECT_ID/serviceAccounts/existing-sa@$PROJECT_ID.iam.gserviceaccount.com
```

---

## ⬆️ Version Upgrades

### Upgrading from v2.0.0 to v2.1.0

#### 1. Backup Current State
```bash
# Create backup
mkdir -p backups/v2.0.0-to-v2.1.0
cp -r environments/ backups/v2.0.0-to-v2.1.0/
gsutil -m cp -r gs://your-state-bucket/ backups/v2.0.0-to-v2.1.0/state/
```

#### 2. Update Configuration Files
```bash
# Pull latest changes
git pull origin main

# Review changes
git log v2.0.0..v2.1.0 --oneline

# Key changes in v2.1.0:
# - Google-managed SSL certificates
# - Updated Binary Authorization syntax
# - Enhanced Taskfile.yml
# - Fixed deprecated configurations
```

#### 3. Update SSL Certificate Configuration
```hcl
# Old configuration (v2.0.0)
resource "google_compute_ssl_certificate" "external_ssl_cert" {
  name        = "${var.external_lb_name}-ssl-cert"
  private_key = file("path/to/private.key")
  certificate = file("path/to/certificate.crt")
}

# New configuration (v2.1.0)
resource "google_compute_managed_ssl_certificate" "external_ssl_cert" {
  name    = "${var.external_lb_name}-ssl-cert"
  project = var.project_id

  managed {
    domains = var.ssl_domains
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

#### 4. Update Binary Authorization
```hcl
# Old configuration (v2.0.0)
enable_binary_authorization = true

# New configuration (v2.1.0)
binary_authorization {
  evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
}
```

#### 5. Run Migration
```bash
# Validate new configuration
task validate-all

# Plan changes
cd environments/dev
terragrunt run-all plan

# Apply changes (start with dev)
terragrunt run-all apply

# Verify functionality
task validate-all
```

### Upgrading from v1.x to v2.x

#### Major Changes
- Flattened Terragrunt hierarchy
- Removed circular dependencies
- Updated module structure
- Enhanced security controls

#### Migration Steps
```bash
# 1. Review breaking changes
cat CHANGELOG.md

# 2. Update include paths
find environments/ -name "terragrunt.hcl" -exec sed -i 's/common\/terragrunt.hcl/root.hcl/g' {} \;

# 3. Remove common directory
rm -rf environments/common/

# 4. Update dependency configurations
# Remove circular dependencies between security and compute modules

# 5. Test migration
cd environments/dev
terragrunt run-all plan
```

---

## 🧪 Testing Migration

### Pre-Migration Testing
```bash
# Create test environment
cp -r environments/dev environments/test

# Update test configuration
sed -i 's/dev/test/g' environments/test/terragrunt.hcl

# Deploy test environment
cd environments/test
terragrunt run-all apply
```

### Post-Migration Validation
```bash
# Verify all resources are managed
terragrunt state list

# Check for configuration drift
terragrunt plan  # Should show no changes

# Test functionality
kubectl get nodes
gcloud compute instances list
curl -k https://your-load-balancer-ip
```

### Rollback Procedures
```bash
# If migration fails, rollback using backups
cd migration-backup/$(date +%Y%m%d)

# Restore state files
cp terraform.tfstate* ../../

# Restore configuration
cp *.tf ../../

# Reinitialize
terraform init
terraform plan
```

---

## 📊 Migration Checklist

### Pre-Migration
- [ ] Backup all state files and configurations
- [ ] Document current infrastructure
- [ ] Test migration in non-production environment
- [ ] Verify all dependencies are identified
- [ ] Plan rollback procedures

### During Migration
- [ ] Follow migration steps in order
- [ ] Validate each phase before proceeding
- [ ] Monitor for errors and issues
- [ ] Document any deviations from plan
- [ ] Test functionality at each step

### Post-Migration
- [ ] Verify all resources are properly managed
- [ ] Test all functionality
- [ ] Update documentation
- [ ] Train team on new processes
- [ ] Monitor for issues in first 24-48 hours

---

## 🆘 Migration Support

### Common Migration Issues

#### 1. Resource Import Failures
```bash
# Issue: Resource already exists
# Solution: Import existing resource
terragrunt import RESOURCE_TYPE.RESOURCE_NAME RESOURCE_ID
```

#### 2. State File Conflicts
```bash
# Issue: State file corruption
# Solution: Restore from backup
gsutil cp gs://backup-bucket/terraform.tfstate ./
```

#### 3. Configuration Drift
```bash
# Issue: Configuration doesn't match actual resources
# Solution: Update configuration or modify resources
terragrunt refresh
terragrunt plan
```

### Getting Help
- Review [Troubleshooting Guide](./TROUBLESHOOTING.md)
- Check [API Reference](./API_REFERENCE.md)
- Contact infrastructure team
- Open GitHub issue for bugs

---

## 📈 Best Practices

### Migration Planning
1. **Start Small**: Begin with non-critical environments
2. **Test Thoroughly**: Validate each step before proceeding
3. **Document Everything**: Keep detailed migration logs
4. **Plan Rollbacks**: Always have a rollback strategy
5. **Communicate**: Keep stakeholders informed of progress

### Risk Mitigation
1. **Backup Everything**: State files, configurations, data
2. **Use Blue-Green**: Deploy alongside existing infrastructure
3. **Gradual Migration**: Move workloads incrementally
4. **Monitor Closely**: Watch for issues during and after migration
5. **Have Support Ready**: Ensure team availability during migration

---

**Remember**: Migration is a critical process. Always test thoroughly in non-production environments first!