# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  project  = var.project_id

  # Remove default node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  # Network configuration
  network    = var.network_name
  subnetwork = var.subnet_name

  # Enhanced private cluster configuration
  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block

    master_global_access_config {
      enabled = false # Restrict master access
    }
  }

  # IP allocation policy for secondary ranges
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Enhanced master authentication with client certificates disabled
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Network policy for pod-to-pod security
  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  # Enhanced addons configuration
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    network_policy_config {
      disabled = false
    }
    # Enable DNS cache for security and performance
    dns_cache_config {
      enabled = true
    }
    # Enable Config Connector
    config_connector_config {
      enabled = var.enable_config_connector
    }
    # Enable Istio for service mesh security
    istio_config {
      disabled = !var.enable_istio
      auth     = var.enable_istio ? "AUTH_MUTUAL_TLS" : null
    }
  }

  # Workload Identity for secure pod authentication
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Database encryption using KMS
  database_encryption {
    state    = "ENCRYPTED"
    key_name = var.database_encryption_key
  }

  # Enhanced cluster security features
  cluster_autoscaling {
    enabled = true
    resource_limits {
      resource_type = "cpu"
      minimum       = 1
      maximum       = 100
    }
    resource_limits {
      resource_type = "memory"
      minimum       = 1
      maximum       = 1000
    }
    auto_provisioning_defaults {
      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform"
      ]
      service_account = var.node_service_account_email

      # Security hardening for auto-provisioned nodes
      disk_size   = 50
      disk_type   = "pd-ssd"
      image_type  = "COS_CONTAINERD" # Container-Optimized OS
      preemptible = false

      shielded_instance_config {
        enable_secure_boot          = true
        enable_integrity_monitoring = true
      }
    }
  }

  # Binary Authorization for container image security
  enable_binary_authorization = var.enable_binary_authorization

  # Pod Security Policy (deprecated but shown for reference)
  pod_security_policy_config {
    enabled = false # Replaced by Pod Security Standards
  }

  # Maintenance policy with security updates
  maintenance_policy {
    recurring_window {
      start_time = "2023-01-01T00:00:00Z"
      end_time   = "2023-01-01T04:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SU" # Sunday maintenance window
    }
  }

  # Master authorized networks for API server access control
  dynamic "master_authorized_networks_config" {
    for_each = var.authorized_networks != null ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  # Enhanced logging and monitoring
  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS",
      "API_SERVER"
    ]
  }

  monitoring_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS",
      "APISERVER",
      "SCHEDULER",
      "CONTROLLER_MANAGER"
    ]
  }

  # Enable Autopilot mode for enhanced security (optional)
  dynamic "cluster_autoscaling" {
    for_each = var.enable_autopilot ? [] : [1]
    content {
      enabled = true
      # Configuration for standard GKE
    }
  }

  resource_labels = var.labels
}

# Enhanced Node Pool with Security Hardening
resource "google_container_node_pool" "primary_nodes" {
  name     = var.node_pool_name
  location = var.region
  cluster  = google_container_cluster.primary.name
  project  = var.project_id

  node_count = var.initial_node_count

  # Autoscaling configuration
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  # Enhanced node configuration with security hardening
  node_config {
    preemptible  = false
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = "pd-ssd"         # Use SSD for better performance and security
    image_type   = "COS_CONTAINERD" # Container-Optimized OS with containerd

    # Use dedicated service account with minimal permissions
    service_account = var.node_service_account_email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = merge(var.labels, {
      "security-hardened" = "true"
      "node-pool"         = var.node_pool_name
    })

    tags = ["gke-node", "security-hardened", var.environment]

    # Enhanced security metadata
    metadata = {
      disable-legacy-endpoints = "true"
      # Disable SSH access for security
      ssh-keys = ""
      # Enable OS Login for centralized access control
      enable-oslogin = "true"
      # Block project-level SSH keys
      block-project-ssh-keys = "true"
    }

    # Shielded Instance configuration for hardware-level security
    shielded_instance_config {
      enable_secure_boot          = var.enable_shielded_nodes
      enable_integrity_monitoring = var.enable_shielded_nodes
    }

    # Workload Identity configuration
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Advanced machine features for security
    advanced_machine_features {
      threads_per_core = 1 # Disable hyperthreading for security
    }

    # Boot disk encryption with customer-managed key
    boot_disk_kms_key = var.database_encryption_key

    # Linux node configuration for enhanced security
    linux_node_config {
      sysctls = {
        "net.core.somaxconn"           = "1024"
        "net.ipv4.ip_local_port_range" = "1024 65535"
        "net.ipv4.tcp_rmem"            = "4096 65536 16777216"
        "net.ipv4.tcp_wmem"            = "4096 65536 16777216"
        # Security-focused sysctls
        "net.ipv4.conf.all.log_martians"       = "1"
        "net.ipv4.conf.default.log_martians"   = "1"
        "net.ipv4.conf.all.send_redirects"     = "0"
        "net.ipv4.conf.default.send_redirects" = "0"
      }
    }

    # Container runtime security
    containerd_config {
      private_registry_access_config {
        enabled = true
        certificate_authority_domain_config {
          fqdns = [
            "gcr.io",
            "*.gcr.io",
            "docker.io",
            "*.docker.io"
          ]
          gcp_secret_manager_certificate_config {
            secret_uri = var.registry_certificate_secret
          }
        }
      }
    }

    # Enable guest OS features for security monitoring
    guest_accelerator {
      count = 0
      type  = ""
    }

    # Resource allocation limits for security
    resource_labels = {
      "environment"    = var.environment
      "security-level" = "hardened"
      "compliance"     = "required"
    }
  }

  # Node pool management with security considerations
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Upgrade settings for security patches
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE" # Ensure availability during security updates

    blue_green_settings {
      standard_rollout_policy {
        batch_percentage    = 100
        batch_node_count    = var.max_node_count
        batch_soak_duration = "300s"
      }
      node_pool_soak_duration = "300s"
    }
  }

  # Network configuration for enhanced security
  network_config {
    create_pod_range     = false
    enable_private_nodes = var.enable_private_nodes

    pod_cidr_overprovision_config {
      disabled = false
    }

    pod_ipv4_cidr_block = var.pods_cidr
  }

  # Placement policy for security and compliance
  placement_policy {
    type        = "REGIONAL"
    policy_name = "security-placement-policy"
  }

  # Node locations for high availability and compliance
  node_locations = var.node_locations

  lifecycle {
    ignore_changes = [
      node_count,
      node_config[0].labels,
      node_config[0].taint,
    ]
  }
}

# Service Account for GKE nodes
resource "google_service_account" "gke_service_account" {
  account_id   = "${var.cluster_name}-sa"
  display_name = "GKE Service Account for ${var.cluster_name}"
  project      = var.project_id
}

# IAM bindings for the service account
resource "google_project_iam_member" "gke_service_account_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/container.nodeServiceAccount"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
}