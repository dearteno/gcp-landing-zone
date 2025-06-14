variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The region where resources will be created."
  type        = string
}

variable "network_name" {
  description = "The name of the VPC network."
  type        = string
}

variable "subnet_name" {
  description = "The name of the subnet."
  type        = string
}

variable "external_lb_name" {
  description = "Name of the external load balancer."
  type        = string
  default     = "external-lb"
}

variable "internal_lb_name" {
  description = "Name of the internal load balancer."
  type        = string
  default     = "internal-lb"
}

variable "external_lb_ip" {
  description = "Reserved external IP address for the external load balancer."
  type        = string
}

variable "health_check_port" {
  description = "Port for health check."
  type        = number
  default     = 80
}

variable "backend_service_port" {
  description = "Port for backend service."
  type        = number
  default     = 80
}

variable "labels" {
  description = "Labels to apply to resources."
  type        = map(string)
  default     = {}
}

variable "ssl_domains" {
  description = "List of domains for SSL certificate"
  type        = list(string)
  default     = ["example.com"]
}
