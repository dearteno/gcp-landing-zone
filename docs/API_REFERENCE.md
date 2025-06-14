# API Reference - GCP Landing Zone Modules

This document provides comprehensive API reference for all modules in the GCP Landing Zone project.

## 📚 Module Overview

| Module | Purpose | Dependencies | Outputs |
|--------|---------|--------------|---------|
| [networking](#networking-module) | VPC, subnets, NAT, firewall | None | network_name, subnet_name, external_lb_ip |
| [security](#security-module) | KMS, IAM, policies, compliance | networking | service_accounts, encryption_keys |
| [compute](#compute-module) | GKE cluster, node pools | networking, security | cluster_endpoint, cluster_ca_certificate |
| [load-balancer](#load-balancer-module) | Load balancers, SSL, Gateway API | networking | lb_ip_address, ssl_certificate_id |

---

## 🌐 Networking Module

### Purpose
Creates secure VPC networking infrastructure with private subnets, NAT gateway, and enhanced firewall rules.

### Input Variables

#### Required Variables
```hcl
variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "region" {
  description = "The region where resources will be created"
  type        = string
}

variable "network_name" {
  description = "The name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
}
```

#### Optional Variables
```hcl
variable "pods_cidr" {
  description = "CIDR block for GKE pods"
  type        = string
  default     = "10.1.0.0/16"
}

variable "services_cidr" {
  description = "CIDR block for GKE services"
  type        = string
  default     = "10.2.0.0/16"
}

variable "enable_private_google_access" {
  description = "Enable private Google access for the subnets"
  type        = bool
  default     = true
}

variable "nat_name" {
  description = "Name of the NAT gateway"
  type        = string
  default     = "nat-gateway"
}

variable "router_name" {
  description = "Name of the Cloud Router"
  type        = string
  default     = "cloud-router"
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
```

### Output Values

```hcl
output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc_network.name
}

output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc_network.id
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = google_compute_subnetwork.subnetwork.name
}

output "subnet_id" {
  description = "The ID of the subnet"
  value       = google_compute_subnetwork.subnetwork.id
}

output "external_lb_ip" {
  description = "Reserved external IP for load balancer"
  value       = google_compute_global_address.external_lb_ip.address
}

output "nat_ip" {
  description = "Reserved external IP for NAT gateway"
  value       = google_compute_address.nat_ip.address
}

output "pods_cidr" {
  description = "CIDR block for GKE pods"
  value       = var.pods_cidr
}

output "services_cidr" {
  description = "CIDR block for GKE services"
  value       = var.services_cidr
}
```

### Usage Example

```hcl
module "networking" {
  source = "./modules/networking"
  
  project_id   = "my-gcp-project"
  region       = "us-central1"
  network_name = "dev-vpc"
  subnet_name  = "dev-subnet"
  subnet_cidr  = "10.0.1.0/24"
  pods_cidr    = "10.1.0.0/16"
  services_cidr = "10.2.0.0/16"
  
  labels = {
    environment = "dev"
    managed_by  = "terragrunt"
  }
}
```

---

## 🛡️ Security Module

### Purpose
Implements comprehensive security controls including KMS encryption, IAM service accounts, organization policies, and compliance monitoring.

### Input Variables

#### Required Variables
```hcl
variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "region" {
  description = "The region where resources will be created"
  type        = string
}

variable "environment" {
  description = "The environment name (dev, staging, prod)"
  type        = string
}

variable "network_name" {
  description = "The name of the VPC network"
  type        = string
}
```

#### Optional Variables
```hcl
variable "enable_org_policies" {
  description = "Enable organization policies"
  type        = bool
  default     = true
}

variable "enable_scc_notifications" {
  description = "Enable Security Command Center notifications"
  type        = bool
  default     = true
}

variable "enable_binary_authorization" {
  description = "Enable Binary Authorization"
  type        = bool
  default     = true
}

variable "allowed_ip_ranges" {
  description = "List of allowed IP ranges for firewall rules"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 365
}

variable "health_check_ports" {
  description = "List of ports for health checks"
  type        = list(string)
  default     = ["80", "443"]
}
```

### Output Values

```hcl
output "gke_node_service_account_email" {
  description = "Email of the GKE node service account"
  value       = google_service_account.gke_node_sa.email
}

output "gke_encryption_key" {
  description = "KMS key for GKE encryption"
  value       = google_kms_crypto_key.gke_encryption_key.id
}

output "binary_authorization_policy_id" {
  description = "Binary Authorization policy ID"
  value       = google_binary_authorization_policy.policy.id
}

output "security_keyring_id" {
  description = "Security KMS keyring ID"
  value       = google_kms_key_ring.security_keyring.id
}

output "audit_log_bucket" {
  description = "Audit log storage bucket"
  value       = google_storage_bucket.audit_logs.name
}
```

### Usage Example

```hcl
module "security" {
  source = "./modules/security"
  
  project_id   = "my-gcp-project"
  region       = "us-central1"
  environment  = "prod"
  network_name = module.networking.network_name
  
  enable_org_policies         = true
  enable_scc_notifications    = true
  enable_binary_authorization = true
  
  allowed_ip_ranges = [
    "10.0.0.0/8"
  ]
  
  log_retention_days = 2555  # 7 years for compliance
  health_check_ports = ["80", "443"]
}
```

---

## ☸️ Compute Module

### Purpose
Creates private, security-hardened GKE clusters with auto-scaling node pools, workload identity, and comprehensive security controls.

### Input Variables

#### Required Variables
```hcl
variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "region" {
  description = "The GCP region where resources will be deployed"
  type        = string
}

variable "cluster_name" {
  description = "The name of the GKE cluster"
  type        = string
}

variable "network_name" {
  description = "The name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet"
  type        = string
}

variable "pods_cidr" {
  description = "CIDR block for GKE pods"
  type        = string
}

variable "services_cidr" {
  description = "CIDR block for GKE services"
  type        = string
}

variable "environment" {
  description = "The environment name (dev, staging, prod)"
  type        = string
}
```

#### Optional Variables
```hcl
variable "zone" {
  description = "The GCP zone where resources will be deployed"
  type        = string
  default     = "us-central1-a"
}

variable "node_pool_name" {
  description = "The name of the node pool"
  type        = string
  default     = "default-pool"
}

variable "machine_type" {
  description = "The machine type for the node pool"
  type        = string
  default     = "e2-standard-4"
}

variable "disk_size_gb" {
  description = "The disk size in GB for the node pool"
  type        = number
  default     = 100
}

variable "min_node_count" {
  description = "The minimum number of nodes in the node pool"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "The maximum number of nodes in the node pool"
  type        = number
  default     = 3
}

variable "initial_node_count" {
  description = "The initial number of nodes in the node pool"
  type        = number
  default     = 1
}

variable "enable_private_nodes" {
  description = "Enable private nodes in the GKE cluster"
  type        = bool
  default     = true
}

variable "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation for the hosted master network"
  type        = string
  default     = "172.16.0.0/28"
}

variable "database_encryption_key" {
  description = "KMS key for database encryption"
  type        = string
  default     = null
}

variable "node_service_account_email" {
  description = "Service account email for GKE nodes"
  type        = string
  default     = null
}

variable "enable_binary_authorization" {
  description = "Enable Binary Authorization for the cluster"
  type        = bool
  default     = true
}

variable "enable_shielded_nodes" {
  description = "Enable Shielded GKE Nodes features"
  type        = bool
  default     = true
}

variable "authorized_networks" {
  description = "List of authorized networks for API server access"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = null
}
```

### Output Values

```hcl
output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The CA certificate of the GKE cluster"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "The location of the GKE cluster"
  value       = google_container_cluster.primary.location
}

output "node_pool_name" {
  description = "The name of the node pool"
  value       = google_container_node_pool.primary_nodes.name
}

output "cluster_id" {
  description = "The ID of the GKE cluster"
  value       = google_container_cluster.primary.id
}
```

### Usage Example

```hcl
module "compute" {
  source = "./modules/compute"
  
  project_id   = "my-gcp-project"
  region       = "us-central1"
  environment  = "prod"
  cluster_name = "prod-gke-cluster"
  
  network_name  = module.networking.network_name
  subnet_name   = module.networking.subnet_name
  pods_cidr     = module.networking.pods_cidr
  services_cidr = module.networking.services_cidr
  
  node_service_account_email = module.security.gke_node_service_account_email
  database_encryption_key    = module.security.gke_encryption_key
  
  machine_type       = "e2-standard-8"
  min_node_count     = 2
  max_node_count     = 10
  initial_node_count = 3
  
  enable_binary_authorization = true
  enable_shielded_nodes      = true
  enable_private_nodes       = true
  
  authorized_networks = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "Internal corporate networks"
    }
  ]
}
```

---

## 🔄 Load Balancer Module

### Purpose
Creates external and internal load balancers with Google-managed SSL certificates, health checks, and Gateway API configuration.

### Input Variables

#### Required Variables
```hcl
variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "region" {
  description = "The region where resources will be created"
  type        = string
}

variable "network_name" {
  description = "The name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet"
  type        = string
}

variable "external_lb_ip" {
  description = "Reserved external IP address for the external load balancer"
  type        = string
}
```

#### Optional Variables
```hcl
variable "external_lb_name" {
  description = "Name of the external load balancer"
  type        = string
  default     = "external-lb"
}

variable "internal_lb_name" {
  description = "Name of the internal load balancer"
  type        = string
  default     = "internal-lb"
}

variable "health_check_port" {
  description = "Port for health check"
  type        = number
  default     = 80
}

variable "backend_service_port" {
  description = "Port for backend service"
  type        = number
  default     = 80
}

variable "ssl_domains" {
  description = "List of domains for SSL certificate"
  type        = list(string)
  default     = ["example.com"]
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
```

### Output Values

```hcl
output "external_lb_ip" {
  description = "External load balancer IP address"
  value       = var.external_lb_ip
}

output "external_ssl_certificate_id" {
  description = "External SSL certificate ID"
  value       = google_compute_managed_ssl_certificate.external_ssl_cert.id
}

output "external_backend_service_id" {
  description = "External backend service ID"
  value       = google_compute_backend_service.external_backend_service.id
}

output "internal_backend_service_id" {
  description = "Internal backend service ID"
  value       = google_compute_region_backend_service.internal_backend_service.id
}

output "gateway_api_url_map_id" {
  description = "Gateway API URL map ID"
  value       = google_compute_url_map.gateway_api_external.id
}
```

### Usage Example

```hcl
module "load_balancer" {
  source = "./modules/load-balancer"
  
  project_id     = "my-gcp-project"
  region         = "us-central1"
  network_name   = module.networking.network_name
  subnet_name    = module.networking.subnet_name
  external_lb_ip = module.networking.external_lb_ip
  
  external_lb_name     = "prod-external-lb"
  internal_lb_name     = "prod-internal-lb"
  health_check_port    = 80
  backend_service_port = 80
  
  ssl_domains = [
    "api.example.com",
    "app.example.com"
  ]
  
  labels = {
    environment = "prod"
    managed_by  = "terragrunt"
  }
}
```

---

## 🔗 Module Dependencies

### Dependency Graph
```
networking (no dependencies)
    ↓
security (depends on: networking)
    ↓
compute (depends on: networking, security)
    ↓
load-balancer (depends on: networking)
```

### Execution Order
1. **networking** - Creates VPC, subnets, NAT, firewall rules
2. **security** - Creates KMS keys, service accounts, policies
3. **compute** - Creates GKE cluster using networking and security outputs
4. **load-balancer** - Creates load balancers using networking outputs

---

## 🚀 Best Practices

### Module Usage Guidelines

1. **Always use dependency outputs**: Don't hardcode values that are available as outputs from other modules
2. **Environment-specific configurations**: Use different variable values for dev/staging/prod
3. **Security by default**: Enable security features unless specifically disabled for development
4. **Resource naming**: Use consistent naming patterns with environment prefixes
5. **Labels and tags**: Apply consistent labeling for resource management and cost tracking

### Example Environment Configurations

#### Development Environment
```hcl
# Relaxed security for development
enable_binary_authorization = false
enable_org_policies        = false
log_retention_days         = 90
machine_type              = "e2-standard-2"
min_node_count            = 1
max_node_count            = 3
```

#### Production Environment
```hcl
# Maximum security for production
enable_binary_authorization = true
enable_org_policies        = true
log_retention_days         = 2555  # 7 years
machine_type              = "e2-standard-8"
min_node_count            = 2
max_node_count            = 10
```

---

## 🔍 Troubleshooting

### Common Issues

1. **Missing dependencies**: Ensure all required modules are deployed in the correct order
2. **Permission errors**: Verify service account has necessary IAM roles
3. **Network connectivity**: Check firewall rules and private Google access settings
4. **SSL certificate provisioning**: Verify domain ownership and DNS configuration

### Debug Commands

```bash
# Validate module configuration
tofu validate

# Check dependency outputs
terragrunt output

# Debug with detailed logging
TF_LOG=DEBUG terragrunt apply
```

---

## 📚 Additional Resources

- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
- [GCP Best Practices](https://cloud.google.com/docs/enterprise/best-practices-for-enterprise-organizations)
- [GKE Security Best Practices](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster)