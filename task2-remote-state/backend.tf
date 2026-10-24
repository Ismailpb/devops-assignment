
terraform {
  backend "s3" {
    bucket         = "devops-tfstate-641xxxwwww-ap-southeast-2"
    key            = "task2/terraform.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}
