output "security_policy_id" {
  value = google_compute_security_policy.default.id
}

output "security_policy_name" {
  value = google_compute_security_policy.default.name
}

output "firewall_rule_ids" {
  value = google_compute_firewall.default.*.id
}

output "firewall_rule_names" {
  value = google_compute_firewall.default.*.name
}