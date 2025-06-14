variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The region where resources will be created."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "gke_cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "organization_id" {
  description = "The organization ID for org policies"
  type        = string
  default     = ""
}

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
  description = "Enable Binary Authorization for GKE"
  type        = bool
  default     = true
}

variable "scc_notification_filter" {
  description = "Filter for Security Command Center notifications"
  type        = string
  default     = "state=\"ACTIVE\" AND (category=\"MALWARE\" OR category=\"UNAUTHORIZED_API_USAGE\" OR severity=\"HIGH\" OR severity=\"CRITICAL\")"
}

variable "allowed_ip_ranges" {
  description = "List of IP ranges allowed by Cloud Armor"
  type        = list(string)
  default     = []
}

variable "security_log_filter" {
  description = "Filter for security logs"
  type        = string
  default     = <<EOF
protoPayload.serviceName="compute.googleapis.com" OR
protoPayload.serviceName="container.googleapis.com" OR
protoPayload.serviceName="iam.googleapis.com" OR
protoPayload.serviceName="cloudkms.googleapis.com" OR
severity>=ERROR
EOF
}

variable "log_retention_days" {
  description = "Number of days to retain security logs"
  type        = number
  default     = 365
}

variable "health_check_ports" {
  description = "Ports for health checks"
  type        = list(string)
  default     = ["80", "443", "8080"]
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}