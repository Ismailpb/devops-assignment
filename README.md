# DevOps Engineering Assignment

A hands-on DevOps project demonstrating **Infrastructure as Code (IaC)**, **AWS infrastructure management**, **IAM security**, **CI/CD permissions**, and **Terraform troubleshooting**.

![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900?logo=amazonaws&logoColor=white)
![Terraform](https://img.shields.io/badge/IaC-Terraform-7B42BC?logo=terraform&logoColor=white)
![IAM](https://img.shields.io/badge/Security-AWS%20IAM-DD344C)
![Status](https://img.shields.io/badge/Status-Assignment%20%2F%20Demo-blue)

---

## Table of Contents

- [Overview](#overview)
- [Technologies Used](#technologies-used)
- [Repository Structure](#repository-structure)
- [Tasks](#tasks)
  - [Task 1: EC2 Provisioning with Terraform](#task-1-ec2-provisioning-with-terraform)
  - [Task 2: Terraform Remote State Management](#task-2-terraform-remote-state-management)
  - [Task 3: Cross-Account IAM and Access Control](#task-3-cross-account-iam-and-access-control)
  - [Task 4: Least-Privilege IAM Policy for CI/CD](#task-4-least-privilege-iam-policy-for-cicd)
  - [Task 5: Terraform IAM Bug Fix and Security Improvement](#task-5-terraform-iam-bug-fix-and-security-improvement)
- [Validation and Testing](#validation-and-testing)
- [Security Considerations](#security-considerations)
- [Deployment Status](#deployment-status)
- [Skills Demonstrated](#skills-demonstrated)
- [Conclusion](#conclusion)
- [Author](#author)

---

## Overview

This repository contains my solutions to five DevOps engineering tasks focused on:

- Provisioning AWS infrastructure with Terraform
- Configuring Terraform remote state with locking
- Implementing cross-account IAM access
- Designing least-privilege CI/CD policies
- Troubleshooting Terraform configurations

The goal is to demonstrate practical knowledge of AWS, Terraform, infrastructure automation, access control, and secure DevOps practices.

---

## Technologies Used

| Category | Technology |
|---|---|
| Cloud Platform | Amazon Web Services (AWS) |
| Infrastructure as Code | Terraform |
| Identity & Access Management | AWS IAM |
| State Management | Amazon S3 and DynamoDB |
| Container Registry | Amazon Elastic Container Registry (ECR) |
| Container Orchestration | Amazon Elastic Container Service (ECS) |
| Policy Configuration | AWS IAM JSON policies |
| Version Control | Git and GitHub |

---

## Repository Structure

```text
devops-assignment/
├── task1-ec2-instances/
│   ├── ec2.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── versions.tf
│   ├── terraform.tfvars.example
│   └── NOTES.md
│
├── task2-remote-state/
│   ├── backend.tf
│   ├── versions.tf
│   └── NOTES.md
│
├── task3-cross-account-iam/
│   ├── iam.tf
│   ├── versions.tf
│   └── NOTES.md
│
├── task4-ci-iam-policy/
│   ├── ci-policy.json
│   └── NOTES.md
│
├── task5-terraform-bugfix/
│   ├── main.tf
│   └── NOTES.md
│
└── README.md
```

> The exact files may vary slightly depending on the final repository contents.

---

## Tasks

### Task 1: EC2 Provisioning with Terraform

**Objective:** Define AWS EC2 infrastructure using Terraform.

**Implementation**

- Defined EC2 instances through reusable Terraform configuration files.
- Separated resource definitions, variables, outputs, and provider/version configuration.
- Used variable files to manage environment-specific configuration.
- Prepared the configuration to provision **five EC2 instances** in the selected AWS region.
- Reviewed the Terraform execution plan before making any infrastructure changes.

**Key Learning:** Infrastructure as Code principles, configuration organization, variable management, and reviewing changes before deployment.

---

### Task 2: Terraform Remote State Management

**Objective:** Configure centralized Terraform state storage with state locking.

**Implementation**

- Configured an **Amazon S3** bucket as the Terraform remote state backend.
- Enabled S3 **bucket versioning** to support recovery of earlier state versions.
- Enabled S3 **Block Public Access** settings.
- Configured a **DynamoDB** table for state locking, as required by the assignment.
- Initialized Terraform with the remote backend.

**Key Learning:** Remote state lets teams share infrastructure state, while versioning and locking help prevent conflicting updates and support safer collaboration.

> **Note:** This configuration uses DynamoDB-based locking to meet the assignment requirements. Newer Terraform versions also support S3-native lock files, so the locking approach should be reviewed against the Terraform version used in a real environment.

---

### Task 3: Cross-Account IAM and Access Control

**Objective:** Configure IAM roles and permissions for controlled access between AWS accounts.

**Implementation**

- Defined IAM roles and permission policies using Terraform.
- Configured cross-account role trust relationships.
- Applied resource-scoped permissions for S3 access.
- Demonstrated different access levels for users and roles.
- Documented the intended trust relationships and permission boundaries.

**Key Learning:** IAM role design, cross-account trust, and permission scoping, with an emphasis on granting only what each role needs.

---

### Task 4: Least-Privilege IAM Policy for CI/CD

**Objective:** Define an IAM policy for a CI/CD pipeline that deploys containerized applications to Amazon ECS.

**Implementation**

- Created the policy in JSON format.
- Included permissions for **ECR authentication and image publishing**.
- Included permissions to **register and inspect ECS task definitions** and **update a designated ECS service**.
- Restricted `iam:PassRole` to the intended task roles and added a service condition.
- Limited S3 read access to the intended bucket and objects.

**Key Learning:** Designing deployment permissions around a specific CI/CD workflow instead of granting broad administrative access, using resource restrictions and conditions.

---

### Task 5: Terraform IAM Bug Fix and Security Improvement

**Objective:** Identify and correct issues in an IAM configuration.

**Implementation**

- Corrected an invalid IAM trust policy principal that referenced a **user ARN** where a **role ARN** was intended.
- Replaced overly broad S3 resource access with **bucket- and object-scoped** resources.
- Reviewed the configuration for correctness and security improvements.
- Documented the identified issues and the applied corrections.

**Key Learning:** Terraform troubleshooting, IAM trust policy understanding, and limiting permissions to the resources a workload actually needs.

---

## Validation and Testing

The following checks were performed where applicable:

- [x] Terraform initialization (`terraform init`)
- [x] Terraform configuration validation (`terraform validate`)
- [x] Terraform planning for the EC2 provisioning task (`terraform plan`)
- [x] JSON syntax validation for the CI/CD IAM policy
- [x] Review of IAM policy scope and trust relationships

> `terraform validate` checks configuration structure and consistency. It does **not** prove that every permission will work in a live AWS environment.

---

## Security Considerations

- Never hardcode AWS credentials or other secrets in source code.
- Use placeholders for account IDs, ARNs, bucket names, and environment-specific values.
- Restrict IAM permissions to the required actions and resources.
- Keep Terraform state files private, as they may contain sensitive infrastructure information.
- Protect remote state storage with appropriate access controls and encryption.
- Review IAM trust policies and `iam:PassRole` permissions before using them in a real environment.
- Replace all placeholders with environment-specific values and review the policies against the target AWS accounts before deployment.

---

## Deployment Status

This repository is a **technical assignment and demonstration** of DevOps practices.

| Item | Status |
|---|---|
| Terraform configurations initialized and validated | Done (where applicable) |
| EC2 configuration reviewed with `terraform plan` | Done |
| Five EC2 instances deployed (`terraform apply`) | Not applied |
| IAM and CI/CD configurations tested in a live AWS environment | Not tested |

The IAM and CI/CD configurations should be reviewed and tested in the intended AWS environment before any production use.

---

## Skills Demonstrated

- Terraform and Infrastructure as Code
- AWS EC2 provisioning
- S3 remote state and DynamoDB state locking
- AWS IAM roles and trust policies
- Cross-account access management
- Least-privilege IAM policy design
- Amazon ECR and ECS deployment permissions
- Terraform validation and troubleshooting
- Infrastructure security and configuration management

---

## Conclusion

This assignment demonstrates my approach to building structured, maintainable, and security-conscious infrastructure configurations using Terraform and AWS. It covers core DevOps responsibilities, including infrastructure provisioning, state management, access control, CI/CD authorization, and troubleshooting.

---

## Author

**Ismail P. B.**
