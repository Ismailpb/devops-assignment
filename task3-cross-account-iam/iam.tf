
variable "aws_region" {
  description = "AWS region for the IAM and CI configuration."
  type        = string
  default     = "ap-southeast-2"
}

variable "account_a_id" {
  description = "AWS Account A ID."
  type        = string
  default     = "000000000000"
}

variable "account_b_id" {
  description = "AWS Account B ID."
  type        = string
  default     = "111111111111"
}

variable "cross_account_bucket_name" {
  description = "S3 bucket in Account B accessible by roleC."
  type        = string
  default     = "replace-with-cross-account-bucket"
}

variable "build_artifacts_bucket_name" {
  description = "S3 build-artifacts bucket in Account A."
  type        = string
  default     = "replace-with-build-artifacts-bucket"
}

variable "ecr_repository_name" {
  description = "ECR repository the CI pipeline may push to."
  type        = string
  default     = "replace-with-ecr-repository"
}

variable "ecs_cluster_name" {
  description = "ECS cluster containing the target service."
  type        = string
  default     = "replace-with-ecs-cluster"
}

variable "ecs_service_name" {
  description = "Only this ECS service may be updated by CI."
  type        = string
  default     = "replace-with-ecs-service"
}

variable "ecs_task_execution_role_arn" {
  description = "Task execution role ARN that CI may pass to ECS."
  type        = string
  default     = "arn:aws:iam::000000000000:role/ecsTaskExecutionRole"
}

variable "ecs_task_role_arn" {
  description = "Application task role ARN that CI may pass to ECS."
  type        = string
  default     = "arn:aws:iam::000000000000:role/applicationTaskRole"
}

data "aws_caller_identity" "current" {}

# Account A: programmatic identities.
resource "aws_iam_group" "group1" {
  name = "group1"
}

resource "aws_iam_user" "engine" {
  name = "engine"
}

resource "aws_iam_user" "ci" {
  name = "ci"
}

resource "aws_iam_group_membership" "group1_members" {
  name  = "group1-membership"
  group = aws_iam_group.group1.name
  users = [
    aws_iam_user.engine.name,
    aws_iam_user.ci.name
  ]
}

# Account A: console and CLI group.
resource "aws_iam_group" "group2" {
  name = "group2"
}

resource "aws_iam_user" "alex_admin" {
  name = "alex.admin"
}

resource "aws_iam_user" "sam_ops" {
  name = "sam.ops"
}

resource "aws_iam_group_membership" "group2_members" {
  name  = "group2-membership"
  group = aws_iam_group.group2.name
  users = [
    aws_iam_user.alex_admin.name,
    aws_iam_user.sam_ops.name
  ]
}

resource "aws_iam_group_policy_attachment" "group2_admin" {
  group      = aws_iam_group.group2.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# roleA: broad AWS permissions excluding IAM actions.
resource "aws_iam_role" "roleA" {
  name = "roleA"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${var.account_a_id}:root"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "roleA_admin_except_iam" {
  name = "admin-except-iam"
  role = aws_iam_role.roleA.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      NotAction = "iam:*"
      Resource  = "*"
    }]
  })
}

# roleB: its only permission is to assume roleC.
resource "aws_iam_role" "roleB" {
  name = "roleB"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${var.account_a_id}:root"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "roleB_assume_roleC" {
  name = "assume-roleC-only"
  role = aws_iam_role.roleB.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sts:AssumeRole"
      Resource = "arn:aws:iam::${var.account_b_id}:role/roleC"
    }]
  })
}

# Account B: trust only the specific roleB ARN from Account A.
resource "aws_iam_role" "roleC" {
  provider = aws.account_b
  name     = "roleC"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${var.account_a_id}:role/roleB"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Full S3 permissions, scoped to one bucket and its objects.
resource "aws_iam_role_policy" "roleC_s3" {
  provider = aws.account_b
  name     = "roleC-single-bucket-full-access"
  role     = aws_iam_role.roleC.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "FullAccessToOneBucket"
      Effect = "Allow"
      Action = "s3:*"
      Resource = [
        "arn:aws:s3:::${var.cross_account_bucket_name}",
        "arn:aws:s3:::${var.cross_account_bucket_name}/*"
      ]
    }]
  })
}

# Task 4: least-privilege policy for the CI user.
resource "aws_iam_user_policy" "ci_pipeline" {
  name = "ci-ecr-ecs-artifacts-least-privilege"
  user = aws_iam_user.ci.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrLogin"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "PushToOneEcrRepository"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "arn:aws:ecr:${var.aws_region}:${var.account_a_id}:repository/${var.ecr_repository_name}"
      },
      {
        Sid    = "RegisterAndInspectTaskDefinitions"
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:ListTaskDefinitions"
        ]
        Resource = "*"
      },
      {
        Sid    = "InspectAndUpdateOneService"
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:UpdateService"
        ]
        Resource = "arn:aws:ecs:${var.aws_region}:${var.account_a_id}:service/${var.ecs_cluster_name}/${var.ecs_service_name}"
      },
      {
        Sid    = "PassOnlyExpectedTaskRolesToEcs"
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = [
          var.ecs_task_execution_role_arn,
          var.ecs_task_role_arn
        ]
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      },
      {
        Sid      = "ReadBuildArtifacts"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::${var.build_artifacts_bucket_name}/*"
      },
      {
        Sid      = "ListBuildArtifactsBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${var.build_artifacts_bucket_name}"
      }
    ]
  })
}

# Account B provider.
# Configure authorized Account B credentials before any deployment.
provider "aws" {
  alias  = "account_b"
  region = var.aws_region

  # Example:
  # profile = "account-b-admin"
}
