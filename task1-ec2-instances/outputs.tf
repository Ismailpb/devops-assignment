locals {
  all_instances = merge(
    { for name, instance in aws_instance.standard : name => instance },
    { for name, instance in aws_instance.protected : name => instance }
  )
}

output "instance_ids_by_name" {
  description = "Map of instance Name tag to EC2 instance ID."
  value       = { for name, instance in local.all_instances : name => instance.id }
}

output "private_ips_by_name" {
  description = "Map of instance Name tag to private IP address."
  value       = { for name, instance in local.all_instances : name => instance.private_ip }
}
