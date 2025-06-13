variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The region where resources will be created."
  type        = string
}

variable "service_account_email" {
  description = "The email of the service account to be used for security purposes."
  type        = string
}

variable "enable_logging" {
  description = "Enable logging for security resources."
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable monitoring for security resources."
  type        = bool
  default     = true
}