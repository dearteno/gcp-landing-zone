# VPC Network
resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
  project                 = var.project_id
}

# Subnet
resource "google_compute_subnetwork" "subnetwork" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc_network.id
  project       = var.project_id

  private_ip_google_access = var.enable_private_google_access

  # Enable VPC Flow Logs for security monitoring
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 1.0
    metadata            = "INCLUDE_ALL_METADATA"
  }

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }
}

# Reserve External Static IP for NAT Gateway
resource "google_compute_address" "nat_external_ip" {
  name    = "${var.nat_name}-external-ip"
  region  = var.region
  project = var.project_id
}

# Reserve External Static IP for External Load Balancer
resource "google_compute_global_address" "external_lb_ip" {
  name    = "external-lb-ip"
  project = var.project_id
}

# Cloud Router
resource "google_compute_router" "router" {
  name    = var.router_name
  region  = var.region
  network = google_compute_network.vpc_network.id
  project = var.project_id

  # Enable BGP for advanced routing
  bgp {
    asn            = 64512
    advertise_mode = "CUSTOM"
    
    advertised_groups = ["ALL_SUBNETS"]
    
    advertised_ip_ranges {
      range = var.subnet_cidr
      description = "Primary subnet range"
    }
  }
}

# NAT Gateway
resource "google_compute_router_nat" "nat" {
  name                               = var.nat_name
  router                            = google_compute_router.router.name
  region                            = var.region
  nat_ip_allocate_option            = "MANUAL_ONLY"
  nat_ips                           = [google_compute_address.nat_external_ip.self_link]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                           = var.project_id

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall Rules
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.network_name}-allow-internal"
  network = google_compute_network.vpc_network.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr, var.pods_cidr, var.services_cidr]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.network_name}-allow-ssh"
  network = google_compute_network.vpc_network.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-allowed"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "${var.network_name}-allow-http"
  network = google_compute_network.vpc_network.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "google_compute_firewall" "allow_https" {
  name    = "${var.network_name}-allow-https"
  network = google_compute_network.vpc_network.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
}

# Enhanced Security Features for Networking

# Enhanced Firewall Rules with security hardening
resource "google_compute_firewall" "allow_internal_secure" {
  name    = "${var.network_name}-allow-internal-secure"
  network = google_compute_network.vpc_network.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "8080", "9090", "3000"] # Specific ports only
  }

  allow {
    protocol = "udp"
    ports    = ["53", "123"] # DNS and NTP only
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr, var.pods_cidr, var.services_cidr]
  target_tags   = ["internal-secure"]
  
  description = "Allow internal secure communication"
}

# Explicit deny for high-risk ports
resource "google_compute_firewall" "deny_high_risk_ports" {
  name    = "${var.network_name}-deny-high-risk-ports"
  network = google_compute_network.vpc_network.name
  project = var.project_id
  priority = 500

  deny {
    protocol = "tcp"
    ports    = [
      "23",    # Telnet
      "135",   # RPC
      "139",   # NetBIOS
      "445",   # SMB
      "1433",  # SQL Server
      "1521",  # Oracle
      "3389",  # RDP
      "5432",  # PostgreSQL
      "5984",  # CouchDB
      "6379",  # Redis
      "9200",  # Elasticsearch
      "27017", # MongoDB
    ]
  }

  source_ranges = ["0.0.0.0/0"]
  description   = "Deny access to high-risk ports"
}

# GKE-specific firewall rules with security hardening
resource "google_compute_firewall" "gke_webhooks" {
  name    = "${var.network_name}-gke-webhooks"
  network = google_compute_network.vpc_network.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["8443", "9443", "15017"] # Webhook and Istio ports
  }

  source_ranges = [var.subnet_cidr]
  target_tags   = ["gke-cluster"]
  
  description = "Allow GKE webhooks and service mesh communication"
}