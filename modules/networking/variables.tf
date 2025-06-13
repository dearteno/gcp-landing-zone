variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The region where resources will be created."
  type        = string
}

variable "zone" {
  description = "The zone where resources will be created."
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

variable "subnet_cidr" {
  description = "CIDR block for the subnet."
  type        = string
}

variable "pods_cidr" {
  description = "CIDR block for GKE pods."
  type        = string
  default     = "10.1.0.0/16"
}

variable "services_cidr" {
  description = "CIDR block for GKE services."
  type        = string
  default     = "10.2.0.0/16"
}

variable "enable_private_google_access" {
  description = "Enable private Google access for the subnets."
  type        = bool
  default     = true
}

variable "nat_name" {
  description = "Name of the NAT gateway."
  type        = string
  default     = "nat-gateway"
}

variable "router_name" {
  description = "Name of the Cloud Router."
  type        = string
  default     = "cloud-router"
}

variable "labels" {
  description = "Labels to apply to resources."
  type        = map(string)
  default     = {}
}