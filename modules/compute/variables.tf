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

variable "instance_type" {
  description = "The type of the compute instance."
  type        = string
  default     = "n1-standard-1"
}

variable "machine_image" {
  description = "The machine image to use for the compute instance."
  type        = string
}

variable "network" {
  description = "The name of the network to attach the compute instance."
  type        = string
}

variable "subnetwork" {
  description = "The name of the subnetwork to attach the compute instance."
  type        = string
}