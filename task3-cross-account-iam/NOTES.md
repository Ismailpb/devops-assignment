
# Task 3 – Multi-Account IAM and Cross-Account Access

## 1. Account A – 000000000000

### IAM Groups and Users

- **group1:** Contains the `engine` and `ci` IAM users. These identities are intended for programmatic access without console passwords.
- **group2:** Contains `alex.admin` and `sam.ops`. The group has the AWS managed `AdministratorAccess` policy attached, providing broad administrative permissions.

Console passwords and long-term access keys are not created by this configuration. Credentials should be provisioned using the organization's approved identity and credential-management process.

### roleA – Administrative Access Except IAM

The `roleA` role has a custom policy that allows actions across AWS services while excluding IAM actions through `NotAction = "iam:*"`.

This is a simplified administrative policy for the assignment. In production, the policy should be reviewed carefully because excluding IAM actions alone does not necessarily address every security or privilege-escalation risk.

### roleB – Cross-Account Role Assumption

The `roleB` role has a custom permissions policy allowing `sts:AssumeRole` only on:

`arn:aws:iam::111111111111:role/roleC`

It does not grant general permissions to access other AWS services.

## 2. Account B – 111111111111

### roleC – Restricted S3 Access

The `roleC` role is configured to trust only this principal from Account A:

`arn:aws:iam::000000000000:role/roleB`

Its S3 permissions are scoped to the configured bucket name rather than all S3 buckets.

The current policy allows bucket listing and location lookup, plus object retrieval, upload, and deletion. If the assignment requires full S3 access to that one bucket, the policy should be expanded to include the required S3 actions while remaining restricted to that bucket and its objects.

### Cross-Account Trust

The trust policy controls who may assume `roleC`. The caller must also have permission to call `sts:AssumeRole` on the target role. Both sides of the cross-account relationship must therefore be configured correctly.

## 3. Production Question 1: Would I Give `engine` and `ci` IAM Users with Access Keys?

In a real production environment, I would avoid creating long-lived IAM access keys whenever possible.

I would prefer temporary credentials through IAM roles, AWS IAM Identity Center, or the workload identity integration supported by the CI/CD platform. For example, a CI pipeline could use OIDC federation to assume an AWS role without storing permanent AWS access keys as pipeline secrets.

If IAM users and access keys were unavoidable for a specific legacy requirement, I would apply least-privilege permissions, store credentials in an approved secrets manager, rotate them, monitor their use, and remove unused credentials.

## 4. Production Question 2: Why Trust `roleB` Instead of Account A Root?

Trusting the Account A root principal in a role trust policy can allow principals from that account to assume the role if they are separately authorized by their identity policies.

Trusting the specific `roleB` ARN narrows the trust relationship to that role instead of making the entire account eligible to establish the relationship. This follows the principle of least privilege and reduces the risk of unintended access.

The role trust policy alone is not sufficient: `roleB` must also have an identity policy permitting `sts:AssumeRole` on `roleC`.

## 5. Validation and Deployment Notes

- Terraform initialization and validation were completed with `terraform init -backend=false` and `terraform validate`.
- The account IDs `000000000000` and `111111111111` are assignment placeholders and must be replaced with valid account IDs before deployment.
- The Account B provider must be configured with authorized Account B credentials before any resources can be deployed.
- This configuration has been validated syntactically; it has not been applied to AWS.
- Do not commit access keys, passwords, or other secrets to source control.
