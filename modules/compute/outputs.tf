output "instance_ids" {
  value = aws_instance.my_instance[*].id
}

output "instance_ips" {
  value = aws_instance.my_instance[*].public_ip
}

output "instance_names" {
  value = aws_instance.my_instance[*].tags["Name"]
}