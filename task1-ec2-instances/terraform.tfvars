aws_region  = "ap-southeast-2"
ami_id      = "ami-xxxyyyyy"
environment = "dev"
owner       = "devops-interview"

instances = {
  "payments-prod" = {
    instance_type    = "t3.micro"
    root_volume_type = "gp3"
    root_volume_size = 20
    key_name         = "payments-prod-key"
  }
  "web-stage" = {
    instance_type    = "t3.small"
    root_volume_type = "gp2"
    root_volume_size = 30
    key_name         = "web-stage-key"
  }
  "worker-dev" = {
    instance_type    = "t3.medium"
    root_volume_type = "io1"
    root_volume_size = 60
    root_volume_iops = 3000
    key_name         = "worker-dev-key"
  }
  "batch-test" = {
    instance_type    = "t3.large"
    root_volume_type = "io2"
    root_volume_size = 40
    root_volume_iops = 3000
    key_name         = "batch-test-key"
  }
  "monitoring-tools" = {
    instance_type    = "m5.large"
    root_volume_type = "standard"
    root_volume_size = 50
    key_name         = "monitoring-tools-key"
  }
}
