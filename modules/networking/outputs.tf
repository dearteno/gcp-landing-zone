output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc_network.name
}

output "network_self_link" {
  description = "The self-link of the VPC network"
  value       = google_compute_network.vpc_network.self_link
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = google_compute_subnetwork.subnetwork.name
}

output "subnet_self_link" {
  description = "The self-link of the subnet"
  value       = google_compute_subnetwork.subnetwork.self_link
}

output "subnet_cidr" {
  description = "The CIDR of the subnet"
  value       = google_compute_subnetwork.subnetwork.ip_cidr_range
}

output "pods_cidr" {
  description = "The CIDR for pods"
  value       = var.pods_cidr
}

output "services_cidr" {
  description = "The CIDR for services"
  value       = var.services_cidr
}

output "nat_external_ip" {
  description = "The external IP address of the NAT gateway"
  value       = google_compute_address.nat_external_ip.address
}

output "external_lb_ip" {
  description = "The external IP address for the load balancer"
  value       = google_compute_global_address.external_lb_ip.address
}

output "router_name" {
  description = "The name of the Cloud Router"
  value       = google_compute_router.router.name
}