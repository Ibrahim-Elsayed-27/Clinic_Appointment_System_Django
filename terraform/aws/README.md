# AWS Terraform: Infrastructure Reference

This folder contains Terraform configurations that provision the AWS infrastructure for the Clinic Appointment project. Use this README as a reference to understand the purpose of each file, the high-level architecture, and basic usage notes for working with the configuration.

## Overview

- Purpose: Create a reproducible AWS environment used by the application (networking, compute, container registry, database, CI components, and load-balancing).
- Main components:
  - VPC, subnets, NAT routing, and optional private API endpoints: defined in [vpc.tf](vpc.tf)
  - EKS (Kubernetes) cluster: defined in [eks.tf](eks.tf)
  - ECR (container registry): defined in [ecr.tf](ecr.tf)
  - Application images and related resources: [images.tf](images.tf)
  - AWS Load Balancer Controller IRSA role: [alb.tf](alb.tf)
  - RDS (Postgres) database: [rds.tf](rds.tf)
  - EFS shared media storage and EFS CSI driver: [efs.tf](efs.tf)
  - Secrets Manager database credential lookup: [secrets.tf](secrets.tf)
  - Jenkins infrastructure: [jenkins.tf](jenkins.tf)
  - Bastion host: [bastion.tf](bastion.tf)
  - Outputs for access and automation: [outputs.tf](outputs.tf)
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

1. Networking (VPC, subnets, route tables) provides isolated networking per environment.
2. EKS cluster runs the Django app and other Kubernetes workloads per environment.
3. ECR stores Docker images built from the `app/` directory. The repository is intentionally shared and should be created by only one environment state.
4. ALB exposes services running in EKS to the internet.
5. EFS provides ReadWriteMany media storage for Kubernetes pods.
6. RDS hosts the production application database; dev can use the Helm-managed PostgreSQL StatefulSet.
7. Jenkins runs CI/CD per environment and receives EKS admin access through an EKS access entry.
8. Private subnets use NAT for outbound internet/AWS API access; private VPC endpoints are available but disabled by default to reduce cost and operational complexity.

## Prerequisites

- Install and configure the AWS CLI with credentials that have permissions to create the resources used here.
- Install Terraform (version constrained by `provider.tf`—check the file for exact version requirements).
- (Optional) kubectl and aws-iam-authenticator for cluster access.

## Typical Workflow

1. Create or choose environment variable files, usually `common.tfvars` plus either `dev.tfvars` or `prod.tfvars`.
   - For available variables, defaults, and examples, see [CONFIGURATION.md](CONFIGURATION.md).
2. Initialize Terraform (this uses the backend defined in `backend.tf`):

```bash
terraform init -upgrade
```

3. Select or create the Terraform workspace for the target environment:

```bash
terraform workspace select dev || terraform workspace new dev
```

4. Review plan:

```bash
terraform plan -var-file="common.tfvars" -var-file="dev.tfvars"
```

5. Apply:

```bash
terraform apply -var-file="common.tfvars" -var-file="dev.tfvars"
```

6. After EKS is created, use the Terraform outputs for automation and access details:

```bash
terraform output cluster_name
terraform output eks_endpoint
terraform output efs_file_system_id
terraform output jenkins_private_ip
terraform output bastion_public_ip
terraform output -raw bastion_private_key
```

7. Run the Ansible playbook to configure Jenkins when the Jenkins instance is reachable through the bastion/private network. The playbook installs Java 21, AWS CLI v2, Helm, latest stable `kubectl`, Jenkins plugins, and JCasC Kubernetes cloud configuration.

## State and Backends

- Remote state is configured in `backend.tf` with `workspace_key_prefix = "envs"`. Use one workspace per environment, such as `dev` and `prod`, so each stack keeps separate state.
- Resource names are environment-prefixed through `local.name_prefix`, for example `dev-clinic-appointment-jenkins` and `prod-clinic-appointment-jenkins`.

## Variables and Secrets

- Keep sensitive values out of checked-in files. Production RDS credentials are read from AWS Secrets Manager using the `clinic/db-credentials-${environment}` naming pattern.
- Use [CONFIGURATION.md](CONFIGURATION.md) when creating or updating environment-specific `.tfvars` files.

## Notes & Tips

- Review `outputs.tf` to see useful values to interact with created resources (EKS cluster endpoint, ALB DNS, RDS endpoint, etc.).
- The EC2 key pair name is environment-scoped as `${environment}-bastion-key`; Terraform generates the private key and exposes it as the sensitive `bastion_private_key` output.
- The EFS file system ID is exposed as `efs_file_system_id` and should be passed to Helm as `efs.fileSystemId` during CD.
- The shared ECR repository is named `clinic-appointment`; set `create_ecr = true` in only one environment state to avoid duplicate repository creation.
- NAT is enabled by default. Private API endpoints require both `enable_private_api_endpoints = true` and the relevant `enable_endpoint_* = true` flags.
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

Generated on: 2026-06-17
