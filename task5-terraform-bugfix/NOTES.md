

\# Task 5 – Find and Fix the Terraform Bugs



\## Bug 1: Incorrect Trust Policy Principal



\### Original problem



The trust policy used:



`arn:aws:iam::000000000000:user/roleB`



This ARN identifies an IAM user named `roleB`, but the assignment requires `roleB` to be an IAM role.



\### Fix



The corrected principal is:



`arn:aws:iam::000000000000:role/roleB`



The `user/` component was replaced with `role/`. This allows the intended role in Account A to be the trusted principal for assuming `roleC` in Account B.



The caller must also have permission to call `sts:AssumeRole` on `roleC`.



\## Bug 2: Overly Broad S3 Permissions



\### Original problem



The original permissions policy used:



\- Action: `s3:\*`

\- Resource: `\*`



This grants broad S3 permissions across resources instead of restricting access to the intended bucket.



\### Fix



The corrected policy scopes bucket-level actions to:



`arn:aws:s3:::replace-with-cross-account-bucket`



Object-level actions are scoped to:



`arn:aws:s3:::replace-with-cross-account-bucket/\*`



The policy grants bucket listing and location lookup, along with object retrieval, upload, and deletion. It does not grant access to unrelated S3 buckets.



\## Validation and Deployment



The Terraform configuration should be formatted and validated before use.



The account ID and bucket name are placeholders. Replace them with real values and configure authorized Account B credentials before deployment.



This configuration has not been applied to AWS.



