output "vpc_id" {
  value = module.vpc.vpc_id
}

output "subnet_ids" {
  value = module.vpc.subnet_ids
}

output "firewall_rule_ids" {
  value = module.firewall.firewall_rule_ids
}