output "external_lb_ip" {
  description = "The external IP address of the external load balancer"
  value       = google_compute_global_forwarding_rule.external_forwarding_rule.ip_address
}

output "internal_lb_ip" {
  description = "The internal IP address of the internal load balancer"
  value       = google_compute_forwarding_rule.internal_forwarding_rule.ip_address
}

output "external_backend_service_name" {
  description = "The name of the external backend service"
  value       = google_compute_backend_service.external_backend_service.name
}

output "internal_backend_service_name" {
  description = "The name of the internal backend service"
  value       = google_compute_region_backend_service.internal_backend_service.name
}

output "external_url_map_name" {
  description = "The name of the external URL map"
  value       = google_compute_url_map.external_url_map.name
}

output "gateway_api_external_url_map_name" {
  description = "The name of the Gateway API external URL map"
  value       = google_compute_url_map.gateway_api_external.name
}
