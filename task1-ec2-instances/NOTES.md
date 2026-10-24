# DevOps Assignment — Implementation Notes

## Before applying

1. Replace the placeholder S3 state bucket, AMI ID, S3 bucket names, ECR repository, ECS cluster/service, and IAM role ARNs with real values.
2. Create the remote-state S3 bucket and DynamoDB lock table before `terraform init`. Enable bucket versioning, block public access, and enable encryption on the bucket.
3. Ensure all five EC2 key pairs already exist in the selected region.
4. Configure AWS credentials with permission to create EC2, IAM, S3 backend, and DynamoDB resources. The `account_b` provider must authenticate to Account B; for example, set its profile to `account-b-admin` in local configuration or configure an appropriate assumed role.
5. Review the plan carefully. Do not use example IDs or bucket names in production.

## Task 1 — Multi-instance EC2 provisioning

The `instances` map is the single input that defines all five instances. `aws_instance.standard` uses `for_each` for four entries, and `aws_instance.protected` uses `for_each` for the selected protected entry. This avoids five separate hardcoded resource blocks while meeting Terraform's lifecycle limitation: `lifecycle.prevent_destroy` must be a literal/static setting and cannot be dynamically switched based on `each.value`.

The `payments-prod` instance is protected with `prevent_destroy = true` because it represents a production-like payments workload and should not be removed accidentally during a routine plan/apply. Terraform will reject a plan that destroys this resource while the lifecycle rule remains in configuration. This is not a substitute for backups or change approval. Removing the resource configuration entirely can also remove the protection, so review changes carefully.

Each instance has `Name`, `Environment`, and `Owner` tags. The `worker-dev` example uses `io1` with 3,000 IOPS; confirm the selected instance type and volume size support the requested IOPS in the target region. The sample key pair names and AMI are placeholders/examples and must exist in the chosen region.

Outputs are maps keyed by instance name: `instance_ids_by_name` and `private_ips_by_name`.

## Task 2 — Remote state and locking

The S3 backend stores the Terraform state centrally rather than in a developer's local `terraform.tfstate`. S3 versioning should be enabled to help recover prior state versions, and access to the state bucket should be restricted because state can contain sensitive values.

With local state, two operators working from different local state files can both believe they own the same infrastructure. Concurrent applies can race, create conflicting changes, or leave one operator's local state out of sync with AWS. A local state lock, where applicable, only coordinates operations sharing that same local state; it does not coordinate separate machines.

With the shared S3 backend and DynamoDB locking configured, Terraform obtains a lock for state-changing operations. A second operation using the same state waits or fails while the lock is held instead of proceeding concurrently. This reduces concurrent state writes; teams should still review plans and avoid intentionally running conflicting deployments. The DynamoDB table must exist before backend initialization.

## Task 3 — IAM groups, roles, and cross-account access

- `group1` contains `engine` and `ci`. No console passwords are created for these users. The custom pipeline policy is attached to `ci`; `engine` receives no additional permissions in this example because the assignment does not specify what the engine user must do.
- `group2` contains the example users `alex.admin` and `sam.ops` and is attached to `AdministratorAccess` to represent full console and CLI access. This is intentionally broad to match the assignment, not a recommended default for production.
- `roleA` uses `NotAction: iam:*` with `Resource: *` to allow actions outside IAM. This is broad administrative access excluding IAM API actions; permissions boundaries, SCPs, and explicit denies can still restrict it.
- `roleB` has only one permission: `sts:AssumeRole` on the exact `roleC` ARN in Account B. Its trust policy determines who may assume `roleB`; its permissions policy determines what `roleB` may do after it is assumed.
- `roleC` trusts only `arn:aws:iam::000000000000:role/roleB` and grants S3 object operations only within one named bucket in Account B. In production, narrow object actions further (for example, read-only if writes/deletes are not needed).

### 3.1 Would I use IAM users with access keys for `engine` and `ci` in production?

Generally, no. I would prefer short-lived credentials through IAM roles and federation. For a CI/CD system, use the CI platform's OIDC integration to assume a narrowly scoped AWS role, with trust conditions restricting the repository, branch, or workflow. For a human engineer, use AWS IAM Identity Center or the organization's identity provider and role-based access. This avoids long-lived access keys, simplifies rotation, and improves auditability.

If a legacy system absolutely requires an IAM user's access key, create it only with an approved exception, least privilege, secure storage in a secrets manager, rotation, monitoring, and a documented retirement plan. Do not place secret keys in source control or Terraform outputs/state.

### 3.2 Why trust `roleB`'s ARN rather than Account A root?

Trusting `arn:aws:iam::000000000000:root` in a role trust policy delegates trust to the AWS account. In the common cross-account pattern, an administrator in Account A can authorize principals in that account to assume the target role by granting them `sts:AssumeRole`. Trusting the specific `roleB` ARN narrows the trust relationship to that role, which better satisfies the requirement that nothing else in Account A should assume `roleC`. The caller must still have `sts:AssumeRole` permission on `roleC`, and the target trust policy must allow it.

## Task 4 — Least-privilege CI policy

The policy is included as `ci-policy.json` and as an inline policy on the `ci` user in `iam.tf`. Replace all placeholders before use.

- ECR: `ecr:GetAuthorizationToken` requires `Resource: "*"`. Image push operations are scoped to one ECR repository ARN.
- ECS: the policy permits registering and inspecting task definitions, describing the target service, and updating only the named service. Some ECS task-definition APIs do not support resource-level permissions in the same way as service APIs, so `Resource: "*"` is used only for the task-definition operations that require it.
- `iam:PassRole`: limited to the two expected task/execution role ARNs and conditioned on passing the role to `ecs-tasks.amazonaws.com`. ECS deployments commonly need this permission when registering task definitions that reference task roles.
- S3: only `s3:GetObject` for objects in the build-artifacts bucket and `s3:ListBucket` for that bucket. No write or delete permissions are granted to the artifacts bucket.

Deliberately omitted: IAM user/role creation or policy editing, unrestricted `iam:PassRole`, ECR repository administration/deletion, ECS cluster/service creation or deletion, service updates outside the target service, S3 write/delete, and broad managed policies such as `PowerUserAccess`. The exact required ECS read actions can vary with the deployment tooling; add only actions proven necessary from denied CloudTrail/API calls.

## Task 5 — Find and fix the bug

There are two separate problems in the supplied snippet:

1. **Wrong principal ARN in the trust policy.** The snippet uses `arn:aws:iam::000000000000:user/roleB`, which identifies an IAM user named `roleB`. But `roleB` is an IAM role, so its ARN must be `arn:aws:iam::000000000000:role/roleB`. The trust policy must identify the role principal that is allowed to call `sts:AssumeRole`.
2. **Overly broad S3 permissions.** The inline policy grants `s3:*` on `Resource: "*"`, which allows far more than access to one named bucket. It should grant only required S3 actions and use the bucket ARN for bucket-level actions and `bucket-arn/*` for object-level actions. The `roleC_s3` policy in this project demonstrates this scope.

A corrected minimal trust policy statement is:

```hcl
data "aws_iam_policy_document" "roleC_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::000000000000:role/roleB"]
    }
  }
}
```

A corrected bucket-scoped permissions policy should use `s3:ListBucket` against `arn:aws:s3:::replace-with-cross-account-bucket` and object actions against `arn:aws:s3:::replace-with-cross-account-bucket/*`, rather than `s3:*` on `*`.

## Validation and submission checklist

- Run `terraform fmt -recursive`.
- Run `terraform init` after configuring the remote backend.
- Run `terraform validate`.
- Run `terraform plan -var-file=terraform.tfvars` after creating a real `terraform.tfvars` from the example.
- Review IAM policies with IAM Access Analyzer and validate the JSON before applying.
- Confirm the Account B provider is authenticated to Account B and that the target bucket exists.
- Do not commit real credentials, private keys, Terraform state, or secret `.tfvars` files.
