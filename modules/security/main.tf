# Security Hardening Module for GCP Landing Zone
# This module implements comprehensive security controls and hardening measures

# Organization Policy Constraints
resource "google_org_policy_policy" "disable_guest_attributes" {
  count   = var.enable_org_policies ? 1 : 0
  name    = "projects/${var.project_id}/policies/compute.disableGuestAttributesAccess"
  parent  = "projects/${var.project_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

resource "google_org_policy_policy" "disable_serial_port_access" {
  count   = var.enable_org_policies ? 1 : 0
  name    = "projects/${var.project_id}/policies/compute.disableSerialPortAccess"
  parent  = "projects/${var.project_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

resource "google_org_policy_policy" "require_ssl_certificates" {
  count   = var.enable_org_policies ? 1 : 0
  name    = "projects/${var.project_id}/policies/compute.requireSslCertificates"
  parent  = "projects/${var.project_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

resource "google_org_policy_policy" "disable_nested_virtualization" {
  count   = var.enable_org_policies ? 1 : 0
  name    = "projects/${var.project_id}/policies/compute.disableNestedVirtualization"
  parent  = "projects/${var.project_id}"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Security Command Center Notifications
resource "google_scc_notification_config" "security_notifications" {
  count           = var.enable_scc_notifications ? 1 : 0
  config_id       = "security-notifications"
  organization    = var.organization_id
  description     = "Security findings notifications"
  pubsub_topic    = google_pubsub_topic.security_alerts[0].id
  streaming_config {
    filter = var.scc_notification_filter
  }
}

resource "google_pubsub_topic" "security_alerts" {
  count   = var.enable_scc_notifications ? 1 : 0
  name    = "security-alerts"
  project = var.project_id

  labels = var.labels
}

# Cloud KMS for encryption at rest
resource "google_kms_key_ring" "security_keyring" {
  name     = "${var.environment}-security-keyring"
  location = var.region
  project  = var.project_id
}

resource "google_kms_crypto_key" "gke_encryption_key" {
  name     = "gke-encryption-key"
  key_ring = google_kms_key_ring.security_keyring.id
  purpose  = "ENCRYPT_DECRYPT"

  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key" "disk_encryption_key" {
  name     = "disk-encryption-key"
  key_ring = google_kms_key_ring.security_keyring.id
  purpose  = "ENCRYPT_DECRYPT"

  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }
}

# IAM Security Service Accounts with minimal permissions
resource "google_service_account" "gke_node_service_account" {
  account_id   = "${var.environment}-gke-node-sa"
  display_name = "GKE Node Service Account - ${var.environment}"
  project      = var.project_id
  description  = "Service account for GKE nodes with minimal required permissions"
}

# Minimal IAM roles for GKE nodes
resource "google_project_iam_member" "gke_node_service_account_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_node_service_account.email}"
}

# Cloud Armor Security Policy
resource "google_compute_security_policy" "security_policy" {
  name        = "${var.environment}-security-policy"
  project     = var.project_id
  description = "Security policy for ${var.environment} environment"

  # Default rule - deny all
  rule {
    action   = "deny(403)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default deny rule"
  }

  # Allow specific IP ranges
  dynamic "rule" {
    for_each = var.allowed_ip_ranges
    content {
      action   = "allow"
      priority = rule.key + 1000
      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = [rule.value]
        }
      }
      description = "Allow traffic from ${rule.value}"
    }
  }

  # Rate limiting rule
  rule {
    action   = "rate_based_ban"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    rate_limit_options {
      conform_action      = "allow"
      exceed_action      = "deny(429)"
      enforce_on_key     = "IP"
      ban_duration_sec   = 600
      rate_limit_threshold {
        count        = 100
        interval_sec = 60
      }
    }
    description = "Rate limiting rule"
  }

  # Block known malicious IPs (using Cloud Armor managed rules)
  rule {
    action   = "deny(403)"
    priority = "500"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('crs-v33-id942110-sqli')"
      }
    }
    description = "Block SQL injection attempts"
  }

  rule {
    action   = "deny(403)"
    priority = "501"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('crs-v33-id941100-xss')"
      }
    }
    description = "Block XSS attempts"
  }
}

# Binary Authorization Policy for GKE
resource "google_binary_authorization_policy" "policy" {
  count   = var.enable_binary_authorization ? 1 : 0
  project = var.project_id

  admission_whitelist_patterns {
    name_pattern = "gcr.io/${var.project_id}/*"
  }

  default_admission_rule {
    evaluation_mode  = "REQUIRE_ATTESTATION"
    enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    
    require_attestations_by = [
      google_binary_authorization_attestor.build_attestor[0].name
    ]
  }

  cluster_admission_rules {
    cluster                 = "${var.region}.${var.gke_cluster_name}"
    evaluation_mode        = "REQUIRE_ATTESTATION"
    enforcement_mode       = "ENFORCED_BLOCK_AND_AUDIT_LOG"
    
    require_attestations_by = [
      google_binary_authorization_attestor.build_attestor[0].name
    ]
  }
}

resource "google_binary_authorization_attestor" "build_attestor" {
  count   = var.enable_binary_authorization ? 1 : 0
  name    = "build-attestor"
  project = var.project_id

  attestation_authority_note {
    note_reference = google_container_analysis_note.build_note[0].name
  }
}

resource "google_container_analysis_note" "build_note" {
  count   = var.enable_binary_authorization ? 1 : 0
  name    = "build-note"
  project = var.project_id

  attestation_authority {
    hint {
      human_readable_name = "Build Attestor"
    }
  }
}

# Cloud Logging and Monitoring Security
resource "google_logging_project_sink" "security_sink" {
  name        = "${var.environment}-security-logs"
  project     = var.project_id
  destination = "storage.googleapis.com/${google_storage_bucket.security_logs.name}"
  
  filter = var.security_log_filter

  unique_writer_identity = true
}

resource "google_storage_bucket" "security_logs" {
  name          = "${var.project_id}-${var.environment}-security-logs"
  location      = var.region
  project       = var.project_id
  storage_class = "STANDARD"

  # Enable versioning
  versioning {
    enabled = true
  }

  # Retention policy
  retention_policy {
    retention_period = var.log_retention_days * 24 * 3600 # Convert days to seconds
  }

  # Encryption
  encryption {
    default_kms_key_name = google_kms_crypto_key.disk_encryption_key.id
  }

  # Public access prevention
  public_access_prevention = "enforced"

  # Uniform bucket-level access
  uniform_bucket_level_access = true

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = var.log_retention_days
    }
  }

  labels = var.labels
}

# Grant logging service account access to the bucket
resource "google_storage_bucket_iam_member" "security_logs_writer" {
  bucket = google_storage_bucket.security_logs.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.security_sink.writer_identity
}

# VPC Flow Logs (configured in networking module but referenced here)
resource "google_compute_firewall" "deny_all_ingress" {
  name    = "${var.environment}-deny-all-ingress"
  network = var.network_name
  project = var.project_id

  deny {
    protocol = "all"
  }

  direction     = "INGRESS"
  priority      = 65534
  source_ranges = ["0.0.0.0/0"]
  
  # This rule should be the lowest priority catch-all
  description = "Deny all ingress traffic - security hardening"
}

resource "google_compute_firewall" "deny_all_egress" {
  name    = "${var.environment}-deny-all-egress"
  network = var.network_name
  project = var.project_id

  deny {
    protocol = "all"
  }

  direction          = "EGRESS"
  priority          = 65534
  destination_ranges = ["0.0.0.0/0"]
  
  description = "Deny all egress traffic - security hardening"
}

# Network Security Scanning
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.environment}-allow-health-checks"
  network = var.network_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = var.health_check_ports
  }

  direction     = "INGRESS"
  priority      = 1000
  source_ranges = [
    "130.211.0.0/22",  # Google Cloud Load Balancer health check ranges
    "35.191.0.0/16"    # Google Cloud Load Balancer health check ranges
  ]
  target_tags = ["health-check-target"]
  
  description = "Allow Google Cloud health checks"
}