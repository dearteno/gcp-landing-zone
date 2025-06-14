output "security_policy_id" {
  description = "ID of the Cloud Armor security policy"
  value       = google_compute_security_policy.security_policy.id
}

output "security_policy_name" {
  description = "Name of the Cloud Armor security policy"
  value       = google_compute_security_policy.security_policy.name
}

output "gke_node_service_account_email" {
  description = "Email of the GKE node service account"
  value       = google_service_account.gke_node_service_account.email
}

output "kms_keyring_name" {
  description = "Name of the KMS key ring"
  value       = google_kms_key_ring.security_keyring.name
}

output "gke_encryption_key" {
  description = "KMS key for GKE encryption"
  value       = google_kms_crypto_key.gke_encryption_key.id
}

output "disk_encryption_key" {
  description = "KMS key for disk encryption"
  value       = google_kms_crypto_key.disk_encryption_key.id
}

output "security_logs_bucket" {
  description = "Security logs storage bucket"
  value       = google_storage_bucket.security_logs.name
}

output "binary_authorization_policy" {
  description = "Binary Authorization policy ID"
  value       = var.enable_binary_authorization ? google_binary_authorization_policy.policy[0].id : null
}

output "security_notification_topic" {
  description = "Security notifications Pub/Sub topic"
  value       = var.enable_scc_notifications ? google_pubsub_topic.security_alerts[0].name : null
}