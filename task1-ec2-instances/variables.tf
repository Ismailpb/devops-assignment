variable "aws_region" {
  description = "AWS region used for EC2 and related resources."
  type        = string
  default     = "ap-southeast-2"
}

variable "ami_id" {
  description = "A valid Linux AMI ID for the selected AWS region."
  type        = string
}

variable "environment" {
  description = "Environment tag applied to EC2 instances."
  type        = string
  default     = "interview"
}

variable "owner" {
  description = "Owner tag applied to EC2 instances."
  type        = string
  default     = "platform-team"
}

variable "instances" {
  description = "All EC2 instances are defined in this single map input."
  type = map(object({
    instance_type    = string
    root_volume_type = string
    root_volume_size = number
    key_name         = string
    root_volume_iops = optional(number)
  }))

  validation {
    condition     = length(var.instances) == 5
    error_message = "Provide exactly five instances in var.instances."
  }

  validation {
    condition = alltrue([
      for instance in values(var.instances) :
      contains(["gp2", "gp3", "io1", "io2", "standard", "sc1", "st1"], instance.root_volume_type)
    ])
    error_message = "Each root_volume_type must be a supported EBS volume type."
  }

  validation {
    condition = anytrue([
      for instance in values(var.instances) :
      contains(["io1", "io2"], instance.root_volume_type)
    ])
    error_message = "At least one instance must use io1 or io2."
  }
}

