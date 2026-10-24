

\# Task 4 – Least-Privilege IAM Policy



\## Objective



The custom IAM policy allows the CI pipeline to push Docker images to one ECR repository, register and inspect ECS task definitions, update one specified ECS service, and read build artifacts from one S3 bucket.



\## Permissions Included



\- ECR: Allows authentication and the image-layer upload and image-push operations required for the specified repository.

\- ECS: Allows task-definition registration and inspection, plus describing and updating the specified service.

\- IAM: Allows passing only the designated ECS task execution and application task roles to the ECS tasks service.

\- S3: Allows reading objects from the designated build-artifacts bucket and listing that bucket.



\## Permissions Deliberately Excluded



\- No broad managed policy such as AdministratorAccess or PowerUserAccess.

\- No ECR repository creation or image deletion permissions.

\- No S3 object upload, deletion, or bucket administration permissions.

\- No permission to update arbitrary ECS services.

\- No unrestricted iam:PassRole permission.

\- No IAM user, role, or policy administration permissions.



ECR authentication uses Resource "\*" because the authorization-token action does not support repository-level resource scoping. Task-definition registration and listing also use Resource "\*" where required by the relevant ECS actions.



\## Placeholders



Replace the example AWS account ID, ECR repository, ECS cluster, ECS service, task-role ARNs, and S3 bucket with the actual deployment values before use.



\## Validation



The policy JSON should be syntax-checked before submission. AWS IAM Access Analyzer or the IAM policy simulator can be used for additional policy validation. No permissions have been deployed by this task.



