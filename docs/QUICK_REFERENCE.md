# Quick Reference - GCP Landing Zone

This quick reference provides commonly used commands and configurations for the GCP Landing Zone.

## 🚀 Essential Commands

### Task Management (Recommended)
```bash
# Show all available tasks
task --list

# Validate all configurations
task validate-all

# Deploy development environment
task apply-dev

# Deploy staging environment  
task apply-staging

# Deploy production environment (with confirmation)
task apply-prod

# Plan all environments
task plan-all

# Clean temporary files
task clean
```

### Direct Terragrunt Commands
```bash
# Initialize all modules
terragrunt run-all init

# Validate all configurations
terragrunt run-all validate

# Plan all modules
terragrunt run-all plan

# Apply all modules
terragrunt run-all apply

# Destroy all modules (careful!)
terragrunt run-all destroy

# Show dependency graph
terragrunt graph-dependencies
```

### Environment-Specific Commands
```bash
# Work with specific environment
cd environments/dev
terragrunt run-all plan
terragrunt run-all apply

# Work with specific module
cd environments/dev/networking
terragrunt plan
terragrunt apply
```

---

## 🔧 Common Configuration Patterns

### Environment Variables
```bash
# Essential environment variables
export PROJECT_ID="your-gcp-project"
export REGION="us-central1"
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"

# Optional performance variables
export TF_LOG="INFO"
export TF_LOG_PATH="./terraform.log"
```

### Project Configuration
```hcl
# root.hcl - Update these values
inputs = {
  project_id = "your-actual-project-id"
  region     = "your-preferred-region"
  zone       = "your-preferred-zone"
}

# Update state bucket
remote_state {
  backend = "gcs"
  config = {
    bucket = "your-actual-state-bucket"
    prefix = "${path_relative_to_include()}/terraform.tfstate"
  }
}
```

### Environment-Specific Settings
```hcl
# Development environment
inputs = {
  machine_type = "e2-standard-2"
  min_node_count = 1
  max_node_count = 3
  enable_binary_authorization = false
  log_retention_days = 90
}

# Production environment
inputs = {
  machine_type = "e2-standard-8"
  min_node_count = 3
  max_node_count = 20
  enable_binary_authorization = true
  log_retention_days = 2555
}
```

---

## 🛠️ Troubleshooting Quick Fixes

### Authentication Issues
```bash
# Check current authentication
gcloud auth list

# Re-authenticate
gcloud auth application-default login

# Set project
gcloud config set project YOUR_PROJECT_ID
```

### State Issues
```bash
# Refresh state
terragrunt refresh

# Force unlock (use carefully)
terragrunt force-unlock LOCK_ID

# Import existing resource
terragrunt import RESOURCE_TYPE.NAME RESOURCE_ID
```

### Validation Errors
```bash
# Validate syntax
tofu validate

# Check formatting
tofu fmt -check

# Fix formatting
tofu fmt -recursive
```

### Permission Issues
```bash
# Check enabled APIs
gcloud services list --enabled

# Enable required APIs
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable cloudkms.googleapis.com
```

---

## 📊 Monitoring & Debugging

### Log Locations
```bash
# Deployment logs
ls -la logs/deploy-*.log

# Terragrunt cache
ls -la .terragrunt-cache/

# OpenTofu state
ls -la terraform.tfstate*
```

### Debug Commands
```bash
# Enable debug logging
export TF_LOG=DEBUG
terragrunt apply

# Show current state
terragrunt state list

# Show specific resource
terragrunt state show RESOURCE_NAME

# Show outputs
terragrunt output
```

### Health Checks
```bash
# Check GKE cluster
kubectl get nodes
kubectl get pods --all-namespaces

# Check load balancer
gcloud compute forwarding-rules list
gcloud compute backend-services list

# Check networking
gcloud compute networks list
gcloud compute firewall-rules list
```

---

## 🔐 Security Quick Checks

### IAM and Permissions
```bash
# Check service accounts
gcloud iam service-accounts list

# Check project IAM policy
gcloud projects get-iam-policy PROJECT_ID

# Check organization policies
gcloud resource-manager org-policies list --project=PROJECT_ID
```

### Security Resources
```bash
# Check KMS keys
gcloud kms keys list --location=REGION --keyring=KEYRING_NAME

# Check Binary Authorization
gcloud container binauthz policy import policy.yaml

# Check Security Command Center
gcloud scc findings list ORGANIZATION_ID
```

### Network Security
```bash
# Check firewall rules
gcloud compute firewall-rules list --filter="network:NETWORK_NAME"

# Check VPC flow logs
gcloud logging read "resource.type=gce_subnetwork" --limit=10

# Check private Google access
gcloud compute networks subnets describe SUBNET_NAME --region=REGION
```

---

## 💰 Cost Management

### Resource Monitoring
```bash
# Check compute instances
gcloud compute instances list

# Check persistent disks
gcloud compute disks list

# Check load balancers
gcloud compute forwarding-rules list
```

### Cost Optimization
```bash
# Check committed use discounts
gcloud compute commitments list

# Check preemptible instances
gcloud compute instances list --filter="scheduling.preemptible=true"

# Check unused resources
gcloud compute addresses list --filter="status:RESERVED"
```

---

## 🚀 Performance Tuning

### Cluster Optimization
```bash
# Check node utilization
kubectl top nodes

# Check pod resource usage
kubectl top pods --all-namespaces

# Check cluster autoscaler status
kubectl describe configmap cluster-autoscaler-status -n kube-system
```

### Network Performance
```bash
# Check NAT gateway usage
gcloud compute routers get-nat-mapping-info ROUTER_NAME --region=REGION

# Check load balancer health
gcloud compute backend-services get-health BACKEND_SERVICE_NAME --global
```

---

## 📋 Pre-Deployment Checklist

### Before First Deployment
- [ ] GCP project created and billing enabled
- [ ] Required APIs enabled
- [ ] Service account created with proper roles
- [ ] State bucket created and configured
- [ ] Project ID updated in all configuration files
- [ ] Authentication configured (ADC or service account key)

### Before Production Deployment
- [ ] All configurations validated in dev/staging
- [ ] Security settings reviewed and approved
- [ ] Backup and disaster recovery plan in place
- [ ] Monitoring and alerting configured
- [ ] Team trained on operational procedures
- [ ] Rollback plan documented and tested

### Regular Maintenance
- [ ] Security patches applied
- [ ] Cost optimization reviewed
- [ ] Performance metrics monitored
- [ ] Backup integrity verified
- [ ] Documentation updated
- [ ] Team knowledge sharing sessions

---

## 🔗 Quick Links

### Documentation
- [Main README](../README.md) - Project overview
- [API Reference](API_REFERENCE.md) - Module documentation
- [Troubleshooting](TROUBLESHOOTING.md) - Issue resolution
- [Examples](examples/BASIC_DEPLOYMENT.md) - Deployment scenarios

### External Resources
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
- [GCP Best Practices](https://cloud.google.com/docs/enterprise/best-practices-for-enterprise-organizations)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

**Tip**: Bookmark this page for quick access to commonly used commands and configurations!