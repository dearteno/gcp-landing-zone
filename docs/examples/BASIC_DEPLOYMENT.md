# Basic Deployment Examples - GCP Landing Zone

This document provides step-by-step examples for common deployment scenarios using the GCP Landing Zone.

## 🚀 Quick Start Examples

### Example 1: Development Environment Setup

#### Scenario
Setting up a development environment for a small team with relaxed security and cost optimization.

#### Configuration
```bash
# 1. Clone the repository
git clone https://github.com/your-org/gcp-landing-zone.git
cd gcp-landing-zone

# 2. Set up environment variables
export PROJECT_ID="my-dev-project"
export REGION="us-central1"
export ENVIRONMENT="dev"

# 3. Update configuration files
sed -i "s/your-project-id/$PROJECT_ID/g" root.hcl
sed -i "s/your-project-id/$PROJECT_ID/g" environments/dev/terragrunt.hcl
```

#### Custom Development Settings
```hcl
# environments/dev/terragrunt.hcl
inputs = {
  project_id = "my-dev-project"
  region     = "us-central1"
  environment = "dev"
  
  # Cost-optimized settings for development
  machine_type = "e2-standard-2"
  min_node_count = 1
  max_node_count = 3
  initial_node_count = 1
  
  # Relaxed security for development
  enable_binary_authorization = false
  enable_org_policies = false
  log_retention_days = 30
  
  # Development-friendly network settings
  allowed_ip_ranges = [
    "10.0.0.0/8",      # Internal networks
    "192.168.0.0/16",  # Private networks
    "172.16.0.0/12",   # Docker networks
    "0.0.0.0/0"        # Allow all (dev only!)
  ]
  
  # Health check ports for development
  health_check_ports = ["80", "443", "8080", "3000", "9090"]
}
```

#### Deployment Commands
```bash
# 4. Deploy development environment
cd environments/dev

# Initialize all modules
terragrunt run-all init

# Validate configuration
terragrunt run-all validate

# Plan deployment
terragrunt run-all plan

# Apply infrastructure
terragrunt run-all apply --terragrunt-non-interactive
```

#### Expected Results
- VPC network with development-friendly firewall rules
- Single-node GKE cluster with autoscaling (1-3 nodes)
- Basic load balancer setup
- Minimal security controls for faster development

---

### Example 2: Production Environment Setup

#### Scenario
Setting up a production environment with maximum security, high availability, and compliance controls.

#### Configuration Updates
```hcl
# environments/prod/terragrunt.hcl
inputs = {
  project_id = "my-prod-project"
  region     = "us-central1"
  environment = "prod"
  
  # Production-grade compute resources
  machine_type = "e2-standard-8"
  min_node_count = 3
  max_node_count = 20
  initial_node_count = 5
  
  # Maximum security for production
  enable_binary_authorization = true
  enable_org_policies = true
  enable_shielded_nodes = true
  enable_private_nodes = true
  
  # Compliance settings
  log_retention_days = 2555  # 7 years
  
  # Restricted network access
  authorized_networks = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "Corporate networks only"
    }
  ]
  
  allowed_ip_ranges = [
    "10.0.0.0/8"  # Internal networks only
  ]
  
  # Production health checks
  health_check_ports = ["80", "443"]
}
```

#### Multi-Region Setup (Optional)
```hcl
# For high availability across regions
locals {
  regions = ["us-central1", "us-east1", "us-west1"]
}

# Deploy to multiple regions
inputs = {
  # ... other settings ...
  
  # Multi-region configuration
  node_locations = [
    "us-central1-a",
    "us-central1-b", 
    "us-central1-c"
  ]
}
```

#### Deployment Commands
```bash
# Deploy production environment with extra validation
cd environments/prod

# Extra validation for production
task validate-all
terragrunt run-all validate

# Plan with detailed output
terragrunt run-all plan --terragrunt-log-level debug

# Apply with confirmation prompts
terragrunt run-all apply
```

---

### Example 3: Staging Environment (Blue-Green Ready)

#### Scenario
Setting up a staging environment that mirrors production for testing deployments.

#### Configuration
```hcl
# environments/staging/terragrunt.hcl
inputs = {
  project_id = "my-staging-project"
  region     = "us-central1"
  environment = "staging"
  
  # Production-like but smaller resources
  machine_type = "e2-standard-4"
  min_node_count = 2
  max_node_count = 8
  initial_node_count = 3
  
  # Production security with some relaxation for testing
  enable_binary_authorization = true
  enable_org_policies = false  # Relaxed for testing
  enable_shielded_nodes = true
  enable_private_nodes = true
  
  # Moderate log retention
  log_retention_days = 365
  
  # Staging-specific network settings
  authorized_networks = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "Internal networks"
    },
    {
      cidr_block   = "192.168.1.0/24"
      display_name = "Testing networks"
    }
  ]
  
  # Additional ports for testing
  health_check_ports = ["80", "443", "8080"]
}
```

---

## 🔧 Module-Specific Examples

### Example 4: Custom Networking Configuration

#### Scenario
Setting up a custom network topology with multiple subnets and advanced routing.

#### Advanced Networking Module
```hcl
# modules/networking/main.tf additions
# Additional subnet for database tier
resource "google_compute_subnetwork" "database_subnet" {
  name          = "${var.network_name}-database-subnet"
  ip_cidr_range = var.database_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
  
  # Database subnet should not have internet access
  private_ip_google_access = true
  
  # No secondary ranges for database subnet
}

# Dedicated firewall rules for database tier
resource "google_compute_firewall" "database_firewall" {
  name    = "${var.network_name}-database-firewall"
  network = google_compute_network.vpc_network.name
  
  allow {
    protocol = "tcp"
    ports    = ["3306", "5432", "27017"]  # MySQL, PostgreSQL, MongoDB
  }
  
  source_ranges = [var.subnet_cidr]  # Only from application subnet
  target_tags   = ["database"]
}
```

#### Environment Configuration
```hcl
# environments/prod/networking/terragrunt.hcl
inputs = {
  # ... standard inputs ...
  
  # Custom subnet configuration
  subnet_cidr = "10.0.1.0/24"
  database_subnet_cidr = "10.0.2.0/24"
  pods_cidr = "10.1.0.0/16"
  services_cidr = "10.2.0.0/16"
  
  # Additional networking features
  enable_flow_logs = true
  flow_logs_sampling = 0.5
  enable_private_google_access = true
}
```

---

### Example 5: Multi-Cluster Setup

#### Scenario
Setting up multiple GKE clusters for different workload types (web, batch, ML).

#### Cluster Configurations
```hcl
# environments/prod/compute-web/terragrunt.hcl
inputs = {
  cluster_name = "prod-web-cluster"
  machine_type = "e2-standard-4"
  min_node_count = 3
  max_node_count = 15
  
  # Web-optimized settings
  enable_http_load_balancing = true
  enable_horizontal_pod_autoscaling = true
}

# environments/prod/compute-batch/terragrunt.hcl  
inputs = {
  cluster_name = "prod-batch-cluster"
  machine_type = "c2-standard-8"  # Compute-optimized
  min_node_count = 0
  max_node_count = 50
  
  # Batch-optimized settings
  enable_preemptible_nodes = true
  enable_autoscaling = true
}

# environments/prod/compute-ml/terragrunt.hcl
inputs = {
  cluster_name = "prod-ml-cluster"
  machine_type = "n1-standard-8"  # GPU-capable
  min_node_count = 1
  max_node_count = 10
  
  # ML-optimized settings
  enable_gpu_nodes = true
  gpu_type = "nvidia-tesla-t4"
  gpu_count = 1
}
```

---

### Example 6: Advanced Load Balancer Configuration

#### Scenario
Setting up advanced load balancing with multiple backend services and path-based routing.

#### Advanced Load Balancer Module
```hcl
# modules/load-balancer/advanced-routing.tf
# Multiple backend services
resource "google_compute_backend_service" "api_backend" {
  name        = "${var.external_lb_name}-api-backend"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 30
  
  backend {
    group = google_compute_instance_group.api_instances.self_link
  }
  
  health_checks = [google_compute_health_check.api_health_check.self_link]
}

resource "google_compute_backend_service" "web_backend" {
  name        = "${var.external_lb_name}-web-backend"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10
  
  backend {
    group = google_compute_instance_group.web_instances.self_link
  }
  
  health_checks = [google_compute_health_check.web_health_check.self_link]
  
  # Enable CDN for web content
  enable_cdn = true
  cdn_policy {
    cache_mode = "CACHE_ALL_STATIC"
    default_ttl = 3600
  }
}

# Advanced URL map with path-based routing
resource "google_compute_url_map" "advanced_url_map" {
  name            = "${var.external_lb_name}-advanced-url-map"
  default_service = google_compute_backend_service.web_backend.self_link
  
  path_matcher {
    name            = "api-matcher"
    default_service = google_compute_backend_service.web_backend.self_link
    
    path_rule {
      paths   = ["/api/*", "/v1/*"]
      service = google_compute_backend_service.api_backend.self_link
    }
    
    path_rule {
      paths   = ["/static/*", "/assets/*"]
      service = google_compute_backend_service.web_backend.self_link
    }
  }
  
  host_rule {
    hosts        = ["api.example.com", "www.example.com"]
    path_matcher = "api-matcher"
  }
}
```

---

## 🛡️ Security Examples

### Example 7: Enhanced Security Configuration

#### Scenario
Implementing additional security controls for highly regulated environments.

#### Enhanced Security Module
```hcl
# modules/security/enhanced-controls.tf
# Additional organization policies
resource "google_org_policy_policy" "require_shielded_vm" {
  name   = "projects/${var.project_id}/policies/compute.requireShieldedVm"
  parent = "projects/${var.project_id}"
  
  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

resource "google_org_policy_policy" "disable_nested_virtualization" {
  name   = "projects/${var.project_id}/policies/compute.disableNestedVirtualization"
  parent = "projects/${var.project_id}"
  
  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Enhanced Binary Authorization with multiple attestors
resource "google_binary_authorization_attestor" "security_attestor" {
  name = "security-attestor"
  
  attestation_authority_note {
    note_reference = google_container_analysis_note.security_note.name
  }
}

resource "google_binary_authorization_attestor" "quality_attestor" {
  name = "quality-attestor"
  
  attestation_authority_note {
    note_reference = google_container_analysis_note.quality_note.name
  }
}

# Policy requiring multiple attestations
resource "google_binary_authorization_policy" "enhanced_policy" {
  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    
    require_attestations_by = [
      google_binary_authorization_attestor.security_attestor.name,
      google_binary_authorization_attestor.quality_attestor.name
    ]
  }
}
```

---

### Example 8: Compliance Configuration

#### Scenario
Setting up infrastructure for SOC 2 and ISO 27001 compliance.

#### Compliance-Ready Configuration
```hcl
# environments/prod/terragrunt.hcl - Compliance settings
inputs = {
  # ... other settings ...
  
  # Compliance-specific settings
  enable_audit_logs = true
  audit_log_retention_days = 2555  # 7 years
  enable_access_transparency = true
  enable_vpc_flow_logs = true
  flow_logs_sampling = 1.0  # 100% sampling for compliance
  
  # Enhanced monitoring
  enable_security_command_center = true
  enable_cloud_asset_inventory = true
  
  # Encryption requirements
  enable_envelope_encryption = true
  key_rotation_period_days = 90
  
  # Network security
  enable_private_google_access = true
  enable_private_service_connect = true
  
  # Access controls
  enable_workload_identity = true
  enable_pod_security_policy = true
}
```

---

## 📊 Monitoring Examples

### Example 9: Comprehensive Monitoring Setup

#### Scenario
Setting up detailed monitoring, alerting, and observability for production workloads.

#### Monitoring Configuration
```hcl
# modules/monitoring/main.tf
# Custom monitoring dashboard
resource "google_monitoring_dashboard" "application_dashboard" {
  dashboard_json = jsonencode({
    displayName = "Application Performance Dashboard"
    mosaicLayout = {
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "Request Rate"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"k8s_container\" AND metric.type=\"kubernetes.io/container/restart_count\""
                  }
                }
              }]
            }
          }
        },
        {
          width  = 6
          height = 4
          widget = {
            title = "Error Rate"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"gce_instance\" AND metric.type=\"compute.googleapis.com/instance/cpu/utilization\""
                  }
                }
              }]
            }
          }
        }
      ]
    }
  })
}

# Alert policies
resource "google_monitoring_alert_policy" "high_error_rate" {
  display_name = "High Error Rate"
  combiner     = "OR"
  
  conditions {
    display_name = "Error rate above 5%"
    
    condition_threshold {
      filter          = "resource.type=\"k8s_container\""
      duration        = "300s"
      comparison      = "COMPARISON_GREATER_THAN"
      threshold_value = 0.05
    }
  }
  
  notification_channels = [
    google_monitoring_notification_channel.email.name,
    google_monitoring_notification_channel.slack.name
  ]
}
```

---

## 🚀 CI/CD Integration Examples

### Example 10: GitHub Actions Integration

#### Scenario
Setting up automated deployment pipeline with GitHub Actions.

#### GitHub Actions Workflow
```yaml
# .github/workflows/deploy.yml
name: Deploy GCP Landing Zone

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
  GOOGLE_APPLICATION_CREDENTIALS: ${{ secrets.GCP_SA_KEY }}

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup OpenTofu
      uses: opentofu/setup-opentofu@v1
      with:
        tofu_version: 1.6.0
    
    - name: Setup Terragrunt
      run: |
        wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.50.0/terragrunt_linux_amd64
        chmod +x terragrunt_linux_amd64
        sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
    
    - name: Validate Configuration
      run: |
        task validate-all
    
    - name: Plan Infrastructure
      run: |
        cd environments/dev
        terragrunt run-all plan

  deploy-dev:
    needs: validate
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to Development
      run: |
        cd environments/dev
        terragrunt run-all apply --terragrunt-non-interactive

  deploy-prod:
    needs: [validate, deploy-dev]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to Production
      run: |
        cd environments/prod
        terragrunt run-all apply --terragrunt-non-interactive
```

---

## 📝 Best Practices Summary

### Configuration Management
1. **Environment-specific settings**: Use different configurations for dev/staging/prod
2. **Version control**: Keep all configurations in Git with proper branching
3. **Secrets management**: Use Google Secret Manager for sensitive data
4. **Documentation**: Document all custom configurations and deviations

### Deployment Process
1. **Validation first**: Always validate before applying changes
2. **Incremental deployment**: Deploy to dev → staging → prod
3. **Rollback plan**: Have a tested rollback procedure
4. **Monitoring**: Monitor deployments and infrastructure health

### Security Practices
1. **Least privilege**: Grant minimal necessary permissions
2. **Network isolation**: Use private clusters and restricted networks
3. **Encryption**: Enable encryption at rest and in transit
4. **Compliance**: Follow relevant compliance frameworks

### Cost Optimization
1. **Resource rightsizing**: Use appropriate machine types and disk sizes
2. **Autoscaling**: Enable cluster and pod autoscaling
3. **Preemptible instances**: Use for non-critical workloads
4. **Monitoring**: Track costs and set up billing alerts

---

**Next Steps**: After reviewing these examples, check out the [API Reference](../API_REFERENCE.md) for detailed module documentation and the [Troubleshooting Guide](../TROUBLESHOOTING.md) for common issues and solutions.