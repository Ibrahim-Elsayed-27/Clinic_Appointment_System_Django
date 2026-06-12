# AWS Terraform: Infrastructure Reference

This folder contains Terraform configurations that provision the AWS infrastructure for the Clinic Appointment project. Use this README as a reference to understand the purpose of each file, the high-level architecture, and basic usage notes for working with the configuration.

## Overview

- Purpose: Create a reproducible AWS environment used by the application (networking, compute, container registry, database, CI components, and load-balancing).
- Main components:
  - VPC, subnets, routing: defined in [vpc.tf](vpc.tf)
  - EKS (Kubernetes) cluster: defined in [eks.tf](eks.tf)
  - ECR (container registry): defined in [ecr.tf](ecr.tf)
  - Application images and related resources: [images.tf](images.tf)
  - Application Load Balancer and routing: [alb.tf](alb.tf)
  - RDS (Postgres) database: [rds.tf](rds.tf)
  - Jenkins infrastructure: [jenkins.tf](jenkins.tf)
  - Bastion host: [bastion.tf](bastion.tf)
  - Provider and backend definitions: [provider.tf](provider.tf), [backend.tf](backend.tf)
  - Variables and environment tfvars: [variables.tf](variables.tf)

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) — Detailed infrastructure design, network layout, security groups, EKS, database, and CI/CD architecture.
- [CONFIGURATION.md](CONFIGURATION.md) — Complete Terraform variable reference with defaults, examples, and environment-specific guidance.

## Files and Roles

- `main.tf` — Root composition that wires modules/resources together. See [main.tf](main.tf).
- `provider.tf` — AWS provider config and required provider versions.
- `backend.tf` — Remote state configuration (S3 backend + state locking). Review before `terraform init`.
- `variables.tf` — Inputs for this environment. Check defaults and required values.
- `*.tf` files — Each file generally groups related resources (vpc, eks, rds, alb, etc.).
- `*.tfvars` — Optional environment-specific variable files you can create locally.

## High-level Architecture

For the full architecture reference, including diagrams and component-level details, see [ARCHITECTURE.md](ARCHITECTURE.md).

1. Networking (VPC, subnets, route tables) provides isolated networking for EKS and RDS.
2. EKS cluster runs the Django app and other Kubernetes workloads.
3. ECR stores Docker images built from the `app/` directory.
4. ALB exposes services running in EKS to the internet.
5. RDS hosts the application database (Postgres).
6. Jenkins (optional) can run CI/CD and is provisioned with its own resources if enabled.

## Prerequisites

- Install and configure the AWS CLI with credentials that have permissions to create the resources used here.
- Install Terraform (version constrained by `provider.tf`—check the file for exact version requirements).
- (Optional) kubectl and aws-iam-authenticator for cluster access.

## Typical Workflow

1. Create or choose an environment variable file, such as `local.tfvars`.
   - For available variables, defaults, and examples, see [CONFIGURATION.md](CONFIGURATION.md).
2. Initialize Terraform (this uses the backend defined in `backend.tf`):

```bash
terraform init -upgrade
```

3. Review plan:

```bash
terraform plan -var-file="local.tfvars"
```

4. Apply:

```bash
terraform apply -var-file="local.tfvars"
```

5. After EKS is created, configure `kubectl` to use the new cluster (the EKS module may output kubeconfig details in `outputs.tf`).

## State and Backends

- Remote state is configured in `backend.tf`. Confirm the S3 bucket, key, and DynamoDB lock table before running `terraform init` for the first time.

## Variables and Secrets

- Keep sensitive values out of checked-in files. Use environment variables, Vault, or encrypted secrets for production secrets.
- Use [CONFIGURATION.md](CONFIGURATION.md) when creating or updating environment-specific `.tfvars` files.

## Notes & Tips

- Review `outputs.tf` to see useful values to interact with created resources (EKS cluster endpoint, ALB DNS, RDS endpoint, etc.).
- If you plan to destroy resources, be cautious with `terraform destroy` as it will remove data (RDS) and networking components.
- For CI/CD, confirm IAM roles/policies used by Jenkins or automation systems have least privilege required.

## Where to look next

- Architecture guide: [ARCHITECTURE.md](ARCHITECTURE.md)
- Configuration reference: [CONFIGURATION.md](CONFIGURATION.md)
- Terraform entry: [main.tf](main.tf)
- Networking: [vpc.tf](vpc.tf)
- Kubernetes/EKS: [eks.tf](eks.tf)
- Database: [rds.tf](rds.tf)
- CI/CD: [jenkins.tf](jenkins.tf)

---

Generated on: 2026-06-11
