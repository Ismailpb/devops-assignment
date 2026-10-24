

\# Task 2 – Remote Terraform State



\## Configuration



\- Backend: Amazon S3

\- S3 bucket: devops-tfstate-641471776140-ap-southeast-2

\- State key: task2/terraform.tfstate

\- AWS Region: ap-southeast-2

\- Encryption: Enabled

\- S3 versioning: Enabled

\- Public access: Blocked

\- State locking: DynamoDB table terraform-state-locks

\- DynamoDB billing: On-demand



\## Why Local State Is Risky



When multiple engineers or CI/CD pipelines use separate local Terraform state files, their state can become outdated or inconsistent. This can cause conflicting changes, unexpected infrastructure modifications, and difficult recovery.



A shared S3 backend allows authorized users to work with the same state file. State locking helps prevent simultaneous Terraform operations from modifying that state. S3 versioning provides previous state versions that can help with recovery.



Terraform state may contain sensitive infrastructure information or secrets. Access should be restricted using least-privilege IAM permissions, and the state must be kept private and encrypted.



Note: DynamoDB locking is configured to meet the assignment requirement. Recent Terraform versions also support native S3 lockfiles.



