locals {
  # This is the one instance protected from Terraform-driven destruction.
  protected_instance_name = "payments-prod"

  standard_instances = {
    for name, config in var.instances : name => config
    if name != local.protected_instance_name
  }

  protected_instances = {
    for name, config in var.instances : name => config
    if name == local.protected_instance_name
  }
}

resource "aws_instance" "standard" {
  for_each = local.standard_instances

  ami           = var.ami_id
  instance_type = each.value.instance_type
  key_name      = each.value.key_name

  root_block_device {
    volume_type = each.value.root_volume_type
    volume_size = each.value.root_volume_size
    iops        = contains(["io1", "io2"], each.value.root_volume_type) ? each.value.root_volume_iops : null
    encrypted   = true
  }

  tags = {
    Name        = each.key
    Environment = var.environment
    Owner       = var.owner
  }
}

resource "aws_instance" "protected" {
  for_each = local.protected_instances

  ami           = var.ami_id
  instance_type = each.value.instance_type
  key_name      = each.value.key_name

  root_block_device {
    volume_type = each.value.root_volume_type
    volume_size = each.value.root_volume_size
    iops        = contains(["io1", "io2"], each.value.root_volume_type) ? each.value.root_volume_iops : null
    encrypted   = true
  }

  tags = {
    Name        = each.key
    Environment = var.environment
    Owner       = var.owner
  }

  lifecycle {
    prevent_destroy = true
  }
}
