# External Load Balancer Components

# Health Check for External Load Balancer
resource "google_compute_health_check" "external_health_check" {
  name               = "${var.external_lb_name}-health-check"
  project            = var.project_id
  check_interval_sec = 10
  timeout_sec        = 5

  http_health_check {
    port         = var.health_check_port
    request_path = "/health"
  }
}

# Backend Service for External Load Balancer
resource "google_compute_backend_service" "external_backend_service" {
  name        = "${var.external_lb_name}-backend-service"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 30
  project     = var.project_id

  backend {
    group = google_compute_instance_group.external_instance_group.self_link
  }

  health_checks = [google_compute_health_check.external_health_check.self_link]
}

# Instance Group for External Load Balancer
resource "google_compute_instance_group" "external_instance_group" {
  name    = "${var.external_lb_name}-instance-group"
  zone    = "${var.region}-a"
  project = var.project_id

  named_port {
    name = "http"
    port = var.backend_service_port
  }
}

# URL Map for External Load Balancer
resource "google_compute_url_map" "external_url_map" {
  name            = "${var.external_lb_name}-url-map"
  default_service = google_compute_backend_service.external_backend_service.self_link
  project         = var.project_id
}

# HTTP(S) Proxy for External Load Balancer
resource "google_compute_target_https_proxy" "external_https_proxy" {
  name             = "${var.external_lb_name}-https-proxy"
  url_map          = google_compute_url_map.external_url_map.self_link
  ssl_certificates = [google_compute_ssl_certificate.external_ssl_cert.self_link]
  project          = var.project_id
}

# SSL Certificate for External Load Balancer
resource "google_compute_ssl_certificate" "external_ssl_cert" {
  name        = "${var.external_lb_name}-ssl-cert"
  private_key = file("${path.module}/ssl/private.key")
  certificate = file("${path.module}/ssl/certificate.crt")
  project     = var.project_id

  lifecycle {
    create_before_destroy = true
  }
}

# Global Forwarding Rule for External Load Balancer
resource "google_compute_global_forwarding_rule" "external_forwarding_rule" {
  name       = "${var.external_lb_name}-forwarding-rule"
  target     = google_compute_target_https_proxy.external_https_proxy.self_link
  port_range = "443"
  ip_address = var.external_lb_ip
  project    = var.project_id
}

# Internal Load Balancer Components

# Health Check for Internal Load Balancer
resource "google_compute_health_check" "internal_health_check" {
  name               = "${var.internal_lb_name}-health-check"
  project            = var.project_id
  check_interval_sec = 10
  timeout_sec        = 5

  tcp_health_check {
    port = var.health_check_port
  }
}

# Regional Backend Service for Internal Load Balancer
resource "google_compute_region_backend_service" "internal_backend_service" {
  name                  = "${var.internal_lb_name}-backend-service"
  region                = var.region
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  project               = var.project_id

  backend {
    group = google_compute_instance_group.internal_instance_group.self_link
  }

  health_checks = [google_compute_health_check.internal_health_check.self_link]
}

# Instance Group for Internal Load Balancer
resource "google_compute_instance_group" "internal_instance_group" {
  name    = "${var.internal_lb_name}-instance-group"
  zone    = "${var.region}-a"
  project = var.project_id

  named_port {
    name = "tcp"
    port = var.backend_service_port
  }
}

# Forwarding Rule for Internal Load Balancer
resource "google_compute_forwarding_rule" "internal_forwarding_rule" {
  name                  = "${var.internal_lb_name}-forwarding-rule"
  region                = var.region
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.internal_backend_service.self_link
  all_ports             = true
  network               = var.network_name
  subnetwork            = var.subnet_name
  project               = var.project_id
}

# Gateway API Configuration
resource "google_compute_url_map" "gateway_api_external" {
  name            = "gateway-api-external"
  default_service = google_compute_backend_service.external_backend_service.self_link
  project         = var.project_id

  path_matcher {
    name            = "api-matcher"
    default_service = google_compute_backend_service.external_backend_service.self_link

    path_rule {
      paths   = ["/api/v1/*"]
      service = google_compute_backend_service.external_backend_service.self_link
    }
  }

  host_rule {
    hosts        = ["api.example.com"]
    path_matcher = "api-matcher"
  }
}

resource "google_compute_target_https_proxy" "gateway_api_external_proxy" {
  name             = "gateway-api-external-proxy"
  url_map          = google_compute_url_map.gateway_api_external.self_link
  ssl_certificates = [google_compute_ssl_certificate.external_ssl_cert.self_link]
  project          = var.project_id
}

resource "google_compute_global_forwarding_rule" "gateway_api_external_rule" {
  name       = "gateway-api-external-rule"
  target     = google_compute_target_https_proxy.gateway_api_external_proxy.self_link
  port_range = "443"
  ip_address = var.external_lb_ip
  project    = var.project_id
}
