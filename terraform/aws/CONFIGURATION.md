# Complete Configuration Reference

## 📋 Variable Definitions & Defaults

This document provides a comprehensive reference for all Terraform variables used in the Clinic Appointment AWS infrastructure.

### General AWS Configuration

#### `aws_region`

- **Type**: `string`
- **Default**: `"us-east-1"`
- **Description**: AWS region for all resources
- **Valid Values**: Any AWS region (us-east-1, us-west-2, eu-west-1, etc.)
- **Example**:
  ```hcl
  aws_region = "us-west-2"
  ```

#### `environment`

- **Type**: `string`
- **Default**: `"dev"`
- **Description**: Environment for all resources (used in resource naming)
- **Valid Values**: `"dev"`, `"prod"`, `"staging"`, etc.
- **Example**:
  ```hcl
  environment = "prod"
  ```

---

## 🌐 VPC Configuration

### Network Settings

#### `vpc_name`

- **Type**: `string`
- **Default**: `"clinic-appointment-vpc"`
- **Description**: Name of the VPC
- **Naming**: Should be descriptive and unique per region
- **Example**:
  ```hcl
  vpc_name = "clinic-vue-east-1"
  ```

#### `vpc_cidr_block`

- **Type**: `string`
- **Default**: `"10.0.0.0/16"`
- **Description**: CIDR block for the VPC (provides 65,536 IP addresses)
- **Important**:
  - Used by private subnets, public subnets, and VPC endpoints
  - Should not overlap with on-premises networks (for VPN connectivity)
  - /16 provides sufficient space for growth
- **Example**:
  ```hcl
  vpc_cidr_block = "172.16.0.0/16"
  ```

### Availability Zones

#### `availability_zones`

- **Type**: `list(string)`
- **Default**: N/A (must be provided)
- **Description**: List of Availability Zones for subnet deployment
- **Min Count**: 2 (for high availability)
- **Max Count**: 3
- **Important**: Must exist in the selected region
- **Example**:
  ```hcl
  availability_zones = ["us-east-1a", "us-east-1b"]
  ```

### Public Subnets

#### `public_subnet_cidrs`

- **Type**: `list(string)`
- **Default**: `["10.0.1.0/24"]`
- **Description**: CIDR blocks for public subnets
- **Count**: Should match number of AZs for HA
- **Hosts per Subnet**: 256 IPs - 5 reserved = 251 usable
- **Important**: Hosts internet gateway route
- **Example**:
  ```hcl
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  ```

#### `map_public_ip_on_launch`

- **Type**: `bool`
- **Default**: `false`
- **Description**: Whether EC2 instances automatically receive public IPs
- **Use Cases**:
  - `true`: Bastion hosts, NAT gateway, public-facing resources
  - `false`: Prefer elastic IPS or specific assignment
- **Example**:
  ```hcl
  map_public_ip_on_launch = true
  ```

### Private Subnets

#### `private_subnet_cidrs`

- **Type**: `list(string)`
- **Default**: `["10.0.2.0/24"]`
- **Description**: CIDR blocks for private subnets
- **Count**: Should match number of AZs for HA
- **Hosts per Subnet**: 256 IPs - 5 reserved = 251 usable
- **Important**: Hosts EKS nodes, RDS database
- **Example**:
  ```hcl
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  ```

### Internet & NAT Configuration

#### `create_igw`

- **Type**: `bool`
- **Default**: `false`
- **Description**: Whether to create an Internet Gateway
- **Dependencies**: Required for public subnet internet access
- **Use When**: You have public subnets and want external connectivity
- **Example**:
  ```hcl
  create_igw = true
  ```

#### `create_nat_gateway`

- **Type**: `bool`
- **Default**: `true`
- **Description**: Whether to create NAT Gateway(s) for private subnets
- **Costs**: ~$32/month per NAT gateway + data processing charges
- **Use When**: Private resources need outbound internet or AWS API access (pull images, updates, package downloads)
- **Project Usage**: Enabled in `common.tfvars` so Jenkins and EKS nodes can reach AWS services and the internet from private subnets
- **Alternative**: Optional VPC endpoints can be enabled for selected AWS APIs, but they are disabled by default to reduce cost and complexity
- **Example**:
  ```hcl
  create_nat_gateway = true
  ```

#### `single_nat_gateway`

- **Type**: `bool`
- **Default**: `false`
- **Description**: Use single NAT gateway for all private subnets (vs multi-AZ)
- **Trade-offs**:
  - `true`: Lower cost (~$32/month), single point of failure
  - `false`: Higher availability, higher cost (~$64/month for 2 AZs)
- **Recommendation**: `false` for production, `true` for dev/test
- **Example**:
  ```hcl
  single_nat_gateway = true
  ```

---

## ⚙️ EKS Cluster Configuration

#### `node_instance_type`

- **Type**: `string`
- **Default**: `"t3.medium"`
- **Description**: EC2 instance type for EKS worker nodes
- **Common Types**:
  - `t3.small`: 2 vCPU, 2 GB RAM (~$0.014/hour) - dev/test
  - `t3.medium`: 2 vCPU, 4 GB RAM (~$0.028/hour) - small prod
  - `t3.large`: 2 vCPU, 8 GB RAM (~$0.056/hour) - medium prod
  - `m6i.large`: 2 vCPU, 8 GB RAM (~$0.096/hour) - performance critical
- **Recommendation**: t3 family for burstable workloads, m6i for consistent
- **Example**:
  ```hcl
  node_instance_type = "t3.large"
  ```

#### `node_min_size`

- **Type**: `number`
- **Default**: `1`
- **Description**: Minimum number of nodes in auto-scaling group
- **Consideration**: Minimum 1 for any environment
- **Example**:
  ```hcl
  node_min_size = 1
  ```

#### `node_max_size`

- **Type**: `number`
- **Default**: `2`
- **Description**: Maximum number of nodes in auto-scaling group
- **Scaling**: Cluster can grow to this size based on demand
- **Cost Control**: Limits maximum monthly cost
- **Example**:
  ```hcl
  node_max_size = 5
  ```

#### `node_desired_size`

- **Type**: `number`
- **Default**: `1`
- **Description**: Desired number of nodes at launch
- **Typical**:
  - Dev: 1-2 nodes
  - Prod: 2-3+ nodes
- **Note**: Must be between min_size and max_size
- **Example**:
  ```hcl
  node_desired_size = 3
  ```

### EKS Access Configuration

#### `enable_eks_endpoint_public_access`

- **Type**: `bool`
- **Default**: `false`
- **Description**: Allow public internet access to EKS API endpoint
- **Security**:
  - `true`: Anyone can attempt to access (need valid credentials)
  - `false`: Only VPC-internal and IAM-authorized access
- **Use Cases**:
  - `true`: Remote kubectl access, CI/CD from external systems
  - `false`: Maximum security (private cluster)
- **Recommendation**: `false` for security, `true` only if needed
- **Example**:
  ```hcl
  enable_eks_endpoint_public_access = true
  ```

#### `enable_eks_bootstrap_cluster_creator_admin_permissions`

- **Type**: `bool`
- **Default**: `false`
- **Description**: Grant cluster creator admin permissions at bootstrap
- **IAM**: Using new EKS Access Entries feature (replaces aws-auth ConfigMap)
- **Project Usage**: `common.tfvars` sets this to `true` so the cluster creator keeps admin access during bootstrap
- **Use When**: You want cluster creator to automatically have admin role
- **Recommendation**: Use `true` during initial setup if the creator needs immediate admin access; set `false` when all access is managed through explicit EKS access entries
- **Example**:
  ```hcl
  enable_eks_bootstrap_cluster_creator_admin_permissions = true
  ```

---

## 🗄️ RDS Database Configuration

#### `enable_rds`

- **Type**: `bool`
- **Default**: `false`
- **Description**: Create RDS instance (vs in-cluster PostgreSQL StatefulSet)
- **Dev Strategy**: `false` - Use StatefulSet in cluster
- **Prod Strategy**: `true` - Use managed RDS
- **Costs**:
  - RDS: ~$25/month for db.t3.micro
  - StatefulSet: Free (uses node resources)
- **Example**:
  ```hcl
  enable_rds = true
  ```

#### `db_identifier`

- **Type**: `string`
- **Default**: `"clinic-db"`
- **Description**: Unique name for RDS instance in AWS region
- **Naming**: Must be lowercase, alphanumeric + hyphens
- **Note**: Used in endpoint URL: `{identifier}.xxxxx.rds.amazonaws.com`
- **Example**:
  ```hcl
  db_identifier = "clinic-db-prod"
  ```

#### `db_family`

- **Type**: `string`
- **Default**: `"postgres16"`
- **Description**: Database parameter group family
- **Versions**:
  - postgres16: Latest (2024)
  - postgres15: Previous
  - postgres14: Older (EOL soon)
- **Recommendation**: Use latest stable (postgres16)
- **Example**:
  ```hcl
  db_family = "postgres16"
  ```

#### `db_engine`

- **Type**: `string`
- **Default**: `"postgres"`
- **Description**: Database engine type
- **Options**:
  - postgres: Open source PostgreSQL
  - mysql: MySQL
  - mariadb: MariaDB
  - oracle: Oracle
  - sqlserver: SQL Server
- **Note**: Clinic appointment system uses PostgreSQL
- **Example**:
  ```hcl
  db_engine = "postgres"
  ```

#### `db_engine_version`

- **Type**: `string`
- **Default**: `"16.4"`
- **Description**: Specific version of database engine
- **Format**: Major.Minor (16.4) or just Major (16)
- **Recommendation**: Use minor versions for bug fixes
- **Example**:
  ```hcl
  db_engine_version = "16.4"
  ```

#### `db_instance_class`

- **Type**: `string`
- **Default**: `"db.t3.micro"`
- **Description**: RDS instance type (compute/memory)
- **Common Classes**:
  - db.t3.micro: 1 vCPU, 1 GB RAM (~$0.012/hour) - dev/test
  - db.t3.small: 1 vCPU, 2 GB RAM (~$0.024/hour)
  - db.t3.medium: 2 vCPU, 4 GB RAM (~0.049/hour) - small prod
  - db.t4g.small: ARM-based, more efficient (~$0.018/hour)
- **Recommendation**: t3.micro for dev, t3.medium+ for prod
- **Example**:
  ```hcl
  db_instance_class = "db.t3.medium"
  ```

#### `db_allocated_storage`

- **Type**: `number`
- **Default**: `20`
- **Description**: Initial allocated storage in GB
- **Pricing**: ~$0.115 per GB-month for gp3
- **Auto-scaling**: Can enable automatic storage scaling
- **Recommendation**: 20-50 GB for typical clinic use
- **Example**:
  ```hcl
  db_allocated_storage = 50
  ```

#### `db_name`

- **Type**: `string`
- **Default**: `"clinicdb"`
- **Description**: Name of default database created
- **Note**: Must be created at instance initialization
- **Constraints**: Alphanumeric, max 63 characters
- **Example**:
  ```hcl
  db_name = "clinicdb"
  ```

#### `db_username`

- **Type**: `string`
- **Default**: `"clinicadmin"`
- **Description**: Master username for database
- **Constraints**:
  - Must start with letter
  - Cannot be reserved word (admin, root, etc.)
  - Length: 1-16 characters
- **Best Practice**: Use separate app user, not master user
- **Example**:
  ```hcl
  db_username = "clinicadmin"
  ```

#### `db_port`

- **Type**: `number`
- **Default**: `5432`
- **Description**: Database connection port
- **Standard**: 5432 for PostgreSQL
- **Only Change**: If connecting through restricted firewall
- **Example**:
  ```hcl
  db_port = 5432
  ```

#### `db_multi_az`

- **Type**: `bool`
- **Default**: `false`
- **Description**: Enable Multi-AZ deployment (failover replica)
- **Costs**: ~2x monthly cost for redundant database
- **HA**: Automatic failover in case of AZ failure
- **Recommendation**:
  - `false` for dev/test (cost optimization)
  - `true` for production (high availability)
- **Example**:
  ```hcl
  db_multi_az = true
  ```

---

## 🐳 Container Registry Configuration

#### `create_ecr`

- **Type**: `bool`
- **Default**: `false`
- **Description**: Create Elastic Container Registry repository
- **Repository Name**: `clinic-appointment`
- **Image Scanning**: Enabled automatically
- **Costs**: ~$0.07 per GB-month for storage
- **Alternative**: Use Docker Hub, GitHub Container Registry
- **Example**:
  ```hcl
  create_ecr = true
  ```

---

## 🚀 Jenkins Configuration

#### `jenkins_secret_arns`

- **Type**: `list(string)`
- **Default**: `["*"]`
- **Description**: ARNs of Secrets Manager secrets Jenkins can access
- **Use Case**: Store credentials (GitHub tokens, Docker credentials, etc.)
- **Security**:
  - `["*"]`: Jenkins can access all secrets (less secure)
  - `["arn:aws:secretsmanager:..."]`: Specific secrets only (recommended)
- **Example**:
  ```hcl
  jenkins_secret_arns = [
    "arn:aws:secretsmanager:us-east-1:123456789012:secret:github-token-*",
    "arn:aws:secretsmanager:us-east-1:123456789012:secret:docker-creds-*"
  ]
  ```

---

## 🔌 Networking & API Endpoints

#### `enable_private_api_endpoints`

- **Type**: `bool`
- **Default**: `false`
- **Description**: Global switch for optional VPC endpoints inside the VPC
- **Endpoint Selection**: This must be `true` and the matching `enable_endpoint_*` flag must also be `true` before an endpoint is created
- **Available Endpoints**: S3 gateway endpoint plus interface endpoints for ECR API, ECR Docker, EC2, EKS, STS, SSM, SSM Messages, EC2 Messages, and Secrets Manager
- **Benefits**:
  - Data stays in VPC (enhanced security)
  - Lower latency to AWS services
- **Costs**: Interface endpoints have hourly and data processing costs per endpoint and AZ
- **Project Usage**: Disabled by default; private subnets use NAT for outbound access
- **Recommendation**: Keep `false` unless stricter private AWS API access is required
- **Example**:
  ```hcl
  enable_private_api_endpoints = true
  enable_endpoint_s3          = true
  enable_endpoint_ecr_api     = true
  enable_endpoint_ecr_dkr     = true
  ```

#### Per-Endpoint Toggles

- **Type**: `bool`
- **Default**: `false` for each endpoint
- **Description**: Enable individual VPC endpoints after the global `enable_private_api_endpoints` flag is enabled
- **Variables**:
  - `enable_endpoint_s3`
  - `enable_endpoint_ecr_api`
  - `enable_endpoint_ecr_dkr`
  - `enable_endpoint_ec2`
  - `enable_endpoint_sts`
  - `enable_endpoint_eks`
  - `enable_endpoint_secretsmanager`
  - `enable_endpoint_ssm`
  - `enable_endpoint_ssmmessages`
  - `enable_endpoint_ec2messages`
- **Example**:
  ```hcl
  enable_private_api_endpoints = true
  enable_endpoint_s3           = true
  enable_endpoint_sts          = true
  enable_endpoint_ssm          = true
  enable_endpoint_ssmmessages  = true
  enable_endpoint_ec2messages  = true
  ```

#### `enable_alb_controller_irsa`

- **Type**: `bool`
- **Default**: `true`
- **Description**: Create IAM role for AWS Load Balancer Controller
- **Purpose**: Allows pods to create/manage ALB/NLB resources
- **Prerequisite**: Helm chart must be installed separately
- **Cost**: Free (IAM-only)
- **Recommendation**: `true` if using Kubernetes Ingress resources
- **Example**:
  ```hcl
  enable_alb_controller_irsa = true
  ```

---

## 🪜 Bastion Host Configuration

#### `bastion_allowed_cidrs`

- **Type**: `list(string)`
- **Default**: `["0.0.0.0/0"]`
- **Description**: CIDR blocks allowed to SSH to bastion
- **Security Levels**:
  - `["0.0.0.0/0"]`: Anyone can attempt SSH (very open)
  - `["203.0.113.0/32"]`: Single IP only
  - `["203.0.113.0/24"]`: Corporate network range
- **Recommendation**: Restrict to known IPs
- **Example**:
  ```hcl
  bastion_allowed_cidrs = [
    "203.0.113.0/32",      # Your office IP
    "198.51.100.0/24"      # VPN range
  ]
  ```

### Bastion Key Pair

- **Key Pair Name**: `bastion-key`
- **Description**: Terraform generates one RSA 4096-bit key pair and uses it for both the bastion host and EKS managed nodes
- **Jenkins Usage**: Jenkins also uses this key pair because the instance is reachable only through the bastion security group
- **Retrieval**: Use `terraform output -raw bastion_private_key` and store it securely outside the repository

---

## 📁 Environment-Specific Configurations

### Development Environment (dev.tfvars)

```hcl
environment = "dev"

# Database: Use in-cluster PostgreSQL to save costs
enable_rds = false

# Container Registry
create_ecr = true

# Cluster Settings
node_instance_type = "t3.small"
node_min_size      = 1
node_max_size      = 2
node_desired_size  = 2

# Security: More permissive for development
enable_eks_endpoint_public_access = false
bastion_allowed_cidrs = ["0.0.0.0/0"]
```

### Production Environment (prod.tfvars)

```hcl
environment = "prod"

# Database: Use managed RDS for production
enable_rds           = true
db_identifier        = "clinic-db-prod"
db_instance_class    = "db.t3.micro"
db_allocated_storage = 20
db_name              = "clinicdb"
db_username          = "clinicadmin"
db_multi_az          = false  # Set to true for active-passive HA

# Container Registry
create_ecr = true

# Cluster Settings
node_instance_type = "t3.small"
node_min_size      = 2
node_max_size      = 5
node_desired_size  = 2

# Security: Restrictive for production
enable_eks_endpoint_public_access = false
bastion_allowed_cidrs = ["203.0.113.0/32"]  # Your IP
enable_private_api_endpoints = false
```

### Common Configuration (common.tfvars)

```hcl
# Applied to both dev and prod
aws_region = "us-east-1"

# VPC Settings
vpc_name             = "clinic-vpc"
vpc_cidr_block       = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]

create_igw              = true
create_nat_gateway      = true
single_nat_gateway      = true
map_public_ip_on_launch = true

# Jenkins
jenkins_secret_arns = ["*"]

# Networking
enable_private_api_endpoints = false
enable_alb_controller_irsa   = true

# EKS Access
enable_eks_endpoint_public_access                      = false
enable_eks_bootstrap_cluster_creator_admin_permissions = true
```

---

## 🔗 Variable Dependencies

```
┌─────────────────────────────────────────────┐
│ aws_region                                  │
│ ├─ Determines available AZs                 │
│ └─ Used by all regional services            │
└─────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────┐
│ availability_zones                          │
│ ├─ Must exist in aws_region                 │
│ └─ Must match length of subnet CIDR lists   │
└─────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────┐
│ VPC Configuration                           │
│ ├─ vpc_cidr_block (base)                   │
│ ├─ public_subnet_cidrs (must be in VPC)    │
│ └─ private_subnet_cidrs (must be in VPC)   │
└─────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────┐
│ VPC Features                                │
│ ├─ create_igw ← needed if public subnets   │
│ ├─ create_nat_gateway ← for private egress │
│ └─ enable_private_api_endpoints ← optional │
└─────────────────────────────────────────────┘
```

---

## 📊 Quick Reference Table

| Variable                     | Type | Default     | Dev Value   | Prod Value  |
| ---------------------------- | ---- | ----------- | ----------- | ----------- |
| aws_region                   | str  | us-east-1   | us-east-1   | us-east-1   |
| environment                  | str  | dev         | dev         | prod        |
| vpc_cidr_block               | str  | 10.0.0.0/16 | 10.0.0.0/16 | 10.0.0.0/16 |
| node_instance_type           | str  | t3.medium   | t3.small    | t3.small    |
| node_desired_size            | num  | 1           | 1           | 2+          |
| enable_rds                   | bool | false       | false       | true        |
| db_instance_class            | str  | db.t3.micro | N/A         | db.t3.micro |
| db_multi_az                  | bool | false       | N/A         | false       |
| create_ecr                   | bool | false       | true        | true        |
| enable_private_api_endpoints | bool | false       | false       | false       |
| enable_alb_controller_irsa   | bool | true        | true        | true        |
| create_nat_gateway           | bool | true        | true        | true        |
| single_nat_gateway           | bool | false       | true        | false       |

---

## 🔄 Modifying Variables

### Safe Modifications

- ✅ Increase `node_max_size`
- ✅ Increase `node_desired_size`
- ✅ Add bastion_allowed_cidrs entries
- ✅ Modify `bastion_allowed_cidrs` completely

### Careful Modifications (may cause downtime)

- ⚠️ Change `vpc_cidr_block` (requires VPC replacement)
- ⚠️ Change subnet CIDRs (requires subnet replacement)
- ⚠️ Change `db_instance_class` (requires modification window)
- ⚠️ Change `db_engine_version` (requires modification window)

### Not Recommended

- ❌ Decrease `node_min_size` below 1
- ❌ Set `node_desired_size` > `node_max_size`
- ❌ Enable RDS with wrong credentials
