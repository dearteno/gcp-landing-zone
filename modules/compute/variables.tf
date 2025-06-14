variable "project_id" {
  description = "The ID of the GCP project where resources will be created."
  type        = string
}

variable "region" {
  description = "The GCP region where resources will be deployed."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone where resources will be deployed."
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "The name of the GKE cluster."
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

variable "pods_cidr" {
  description = "CIDR block for GKE pods."
  type        = string
}

variable "services_cidr" {
  description = "CIDR block for GKE services."
  type        = string
}

variable "node_pool_name" {
  description = "The name of the node pool."
  type        = string
  default     = "default-pool"
}

variable "machine_type" {
  description = "The machine type for the node pool."
  type        = string
  default     = "e2-standard-4"
}

variable "disk_size_gb" {
  description = "The disk size in GB for the node pool."
  type        = number
  default     = 100
}

variable "min_node_count" {
  description = "The minimum number of nodes in the node pool."
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "The maximum number of nodes in the node pool."
  type        = number
  default     = 3
}

variable "initial_node_count" {
  description = "The initial number of nodes in the node pool."
  type        = number
  default     = 1
}

variable "enable_private_nodes" {
  description = "Enable private nodes in the GKE cluster."
  type        = bool
  default     = true
}

variable "master_ipv4_cidr_block" {
  description = "The IP range in CIDR notation for the hosted master network."
  type        = string
  default     = "172.16.0.0/28"
}

variable "labels" {
  description = "Labels to apply to resources."
  type        = map(string)
  default     = {}
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

variable "enable_config_connector" {
  description = "Enable Config Connector addon"
  type        = bool
  default     = false
}

variable "enable_istio" {
  description = "Enable Istio service mesh"
  type        = bool
  default     = false
}

variable "enable_autopilot" {
  description = "Enable GKE Autopilot mode"
  type        = bool
  default     = false
}

variable "authorized_networks" {
  description = "List of authorized networks for API server access"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = null
}

variable "enable_shielded_nodes" {
  description = "Enable Shielded GKE Nodes features"
  type        = bool
  default     = true
}

variable "enable_image_streaming" {
  description = "Enable container image streaming"
  type        = bool
  default     = true
}

variable "security_group" {
  description = "Security group for additional access control"
  type        = string
  default     = null
}

variable "node_locations" {
  description = "List of zones for node placement"
  type        = list(string)
  default     = []
}

variable "registry_certificate_secret" {
  description = "Secret Manager secret URI for registry certificates"
  type        = string
  default     = null
}

variable "environment" {
  description = "The environment name (dev, staging, prod)"
  type        = string
}