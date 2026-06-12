# Infrastructure Architecture Documentation

## 🏗️ High-Level Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS Account                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  VPC (10.0.0.0/16)                                  │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │ Public Subnets (10.0.1.0/24, 10.0.2.0/24)  │   │  │
│  │  │ ┌─────────────────────────┐                │   │  │
│  │  │ │ Bastion Host (t3.micro) │                │   │  │
│  │  │ └─────────────────────────┘                │   │  │
│  │  │ Internet Gateway                            │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  │                     ↓                                │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │ Private Subnets (10.0.11.0/24, 10.0.12.0/24) │  │  │
│  │  │ ┌────────────────────────────────────────┐   │  │  │
│  │  │ │ Jenkins (t3.small)                    │   │  │  │
│  │  │ │ EKS Cluster (v1.33)                   │   │  │  │
│  │  │ │ ├─ Control Plane (Managed by AWS)     │   │  │  │
│  │  │ │ └─ Worker Nodes (Auto Scaling Group)  │   │  │  │
│  │  │ │    ├─ Min: 1, Max: 2, Desired: 2     │   │  │  │
│  │  │ │    └─ Instance Type: t3.small         │   │  │  │
│  │  │ ├────────────────────────────────────────┤   │  │  │
│  │  │ │ Database                               │   │  │  │
│  │  │ │ ├─ Dev: PostgreSQL on K8s StatefulSet │   │  │  │
│  │  │ │ └─ Prod: AWS RDS PostgreSQL 16        │   │  │  │
│  │  │ └────────────────────────────────────────┘   │  │  │
│  │  │ NAT Gateway (optional)                        │  │  │
│  │  │ VPC Endpoints (optional)                      │  │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Additional AWS Services                            │  │
│  │ ├─ ECR: clinic-appointment repository              │  │
│  │ ├─ IAM: Service roles and policies                 │  │
│  │ ├─ Secrets Manager: Database credentials           │  │
│  │ ├─ S3: Terraform state bucket                      │  │
│  │ └─ CloudWatch: Cluster logs and metrics            │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 🌐 Network Architecture

### VPC Design

```
VPC: clinic-vpc (10.0.0.0/16)
├── Availability Zone: us-east-1a
│   ├── Public Subnet: 10.0.1.0/24 (clinic-appointment-public-us-east-1a)
│   │   └── Resources: Bastion, NAT Gateway
│   └── Private Subnet: 10.0.11.0/24 (clinic-appointment-private-us-east-1a)
│       └── Resources: Jenkins, EKS Nodes, RDS
│
└── Availability Zone: us-east-1b
    ├── Public Subnet: 10.0.2.0/24 (clinic-appointment-public-us-east-1b)
    │   └── Resources: NAT Gateway (optional, single-AZ config)
    └── Private Subnet: 10.0.12.0/24 (clinic-appointment-private-us-east-1b)
        └── Resources: EKS Nodes, RDS
```

### Subnet Configuration

#### Public Subnets (10.0.1.0/24, 10.0.2.0/24)

- **Route to**: Internet Gateway (IGW)
- **Public IP**: Automatically assigned (map_public_ip_on_launch: true)
- **Hosts**: Bastion, NAT Gateway
- **Connectivity**: Direct internet access

#### Private Subnets (10.0.11.0/24, 10.0.12.0/24)

- **Route to**: NAT Gateway (if enabled) or local only
- **Public IP**: No automatic assignment
- **Hosts**: Jenkins (CI/CD), EKS Worker Nodes, RDS Database
- **Connectivity**: AWS service endpoints via VPC endpoints
- **Kubernetes Tags**: Internal ELB role (for AWS Load Balancer Controller)

### Network Flow

```
Internet (External)
   ↓
Internet Gateway
   ↓
Public Subnets (Bastion)
   ↓
Bastion Host (SSH/SSM Gateway)
   ↓
Private Subnets (Jenkins, EKS Nodes, RDS)
   ↓
NAT Gateway (optional - for outbound internet)
   ↓
VPC Endpoints (optional - for AWS services)
   ↓
AWS Services (S3, ECR, Secrets Manager, etc.)
```

## 🔐 Security Group Architecture

### Bastion Security Group (`clinic-appointment-bastion-sg`)

```
Ingress:
├─ Port 22 (SSH)
│  ├─ Source: bastion_allowed_cidrs (default: 0.0.0.0/0)
│  └─ Protocol: TCP

Egress:
└─ All traffic (0-65535) to 0.0.0.0/0
```

### Jenkins Security Group (`clinic-appointment-jenkins-sg`)

```
Ingress:
├─ Port 8080 (HTTP/UI)
│  ├─ Source: Bastion Security Group
│  └─ Protocol: TCP
├─ Port 22 (SSH)
│  ├─ Source: Bastion Security Group
│  └─ Protocol: TCP


Egress:
└─ All traffic (0-65535) to 0.0.0.0/0
```

### RDS Security Group (`clinic-appointment-rds-sg`)

```
Ingress:
├─ Port 5432 (PostgreSQL)
│  ├─ Source: EKS Node Security Group
│  └─ Protocol: TCP

Egress:
└─ All traffic (0-65535) to 0.0.0.0/0
```

### Private API Endpoints Security Group (`clinic-appointment-private-api-endpoints-sg`)

```
Ingress:
├─ Port 443 (HTTPS)
│  ├─ Source: VPC CIDR (10.0.0.0/16)
│  └─ Protocol: TCP

Egress:
└─ All traffic (0-65535) to 0.0.0.0/0
```

## ☸️ Kubernetes Cluster Architecture

### EKS Cluster Configuration

```
Cluster: dev-clinic-cluster (or prod-clinic-cluster)
├── Control Plane
│   ├── Kubernetes Version: 1.36
│   ├── Endpoint: Private
│   ├── Certificate Authority: AWS managed
│   └── Status: Managed by AWS
│
├── Worker Nodes (Auto Scaling Group)
│   ├── Instance Type: t3.small
│   ├── Min Nodes: 1
│   ├── Max Nodes: 2
│   ├── Desired Nodes: 2 (dev), configurable
│   ├── Launch Type: On-Demand
│   ├── AMI: Amazon Linux 2023
│   └── Networking: Private subnets, multi-AZ
│
├── Node Security Group
│   ├── Label: aws:eks:cluster-name=dev-clinic-cluster
│   └── Managed by AWS EKS
│
├── Access Entries (IAM)
│   └── Jenkins Role: Administrator access to cluster
│
└── Add-ons (auto-managed)
    ├── vpc-cni: Pod networking
    ├── kube-proxy: Networking proxy
    └── coredns: Service discovery
```

### Node Group Details

- **Name**: clinic_nodes
- **Scaling Policy**: Auto Scaling based on demand
- **Termination Protection**: Configurable
- **AMI**: Latest Amazon Linux 2023 (al2023-ami-\*)
- **EBS Volume**: gp3 (default)

## 🗄️ Database Architecture

### Development Environment (Kubernetes StatefulSet)

```
┌─ Kubernetes Cluster ─┐
│                      │
│  ┌──────────────┐   │
│  │ PostgreSQL   │   │
│  │ StatefulSet  │   │
│  │              │   │
│  │ Port: 5432   │   │
│  │ Storage: PVC │   │
│  └──────────────┘   │
│                      │
└──────────────────────┘
```

**Characteristics:**

- Database runs inside Kubernetes (Pod)
- Data persisted via PersistentVolumes
- Suitable for development and testing
- No separate RDS costs
- Easy database resets

### Production Environment (AWS RDS)

```
┌─ AWS RDS ─────────────────┐
│                            │
│  ┌─────────────────────┐  │
│  │ PostgreSQL 16       │  │
│  │                     │  │
│  │ Instance: db.t3.micro  │
│  │ Storage: 20GB (gp3) │  │
│  │ Port: 5432          │  │
│  │                     │  │
│  │ Multi-AZ: Optional  │  │
│  │ Encryption: On      │  │
│  │                     │  │
│  │ Backups: 7 days     │  │
│  │ Deletion Protected  │  │
│  └─────────────────────┘  │
│                            │
└────────────────────────────┘
    ↓
RDS Security Group
    ↓
Private Subnets (us-east-1a, us-east-1b)
```

**Characteristics:**

- Fully managed by AWS
- Automated backups (7-day retention)
- Encryption at rest (aws/rds KMS key)
- Secrets Manager credentials rotation
- Multi-AZ high availability (optional)
- Performance Insights available
- Enhanced Monitoring available

## 🐳 Container Registry Architecture

### ECR Repository

```
Repository Name: clinic-appointment
├── Image Scanning: Enabled (push-time scan)
├── Tag Mutability: Mutable (can overwrite tags)
├── Access: IAM-based
└── Integration: Jenkins → EKS pod deployment
```

**Access Permissions:**

- Jenkins: Full ECR permissions
- EKS Nodes: Pull images via IAM role
- VPC Endpoints: Private registry access (optional)

## 🚀 CI/CD Architecture (Jenkins)

### Jenkins Infrastructure

```
┌─ EC2 Instance (Private Subnet) ────────────────┐
│                                                │
│ Instance Type: t3.small                       │
│ AMI: Amazon Linux 2023                        │
│ Subnet: Private (10.0.11.0/24)               │
│ Key Pair: clinic-appointment-bastion-key      │
│                                                │
│ ┌──────────────────────────────────────────┐  │
│ │ Jenkins Server                           │  │
│ │ Port: 8080                               │  │
│ │ Access: Bastion → SSH/SSM to Jenkins     │  │
│ │ Access from Bastion only (SG restricted) │  │
│ └──────────────────────────────────────────┘  │
│                                                │
└────────────────────────────────────────────────┘
```

### Jenkins Permissions

```
Jenkins IAM Role: clinic-appointment-jenkins-role

Policies:
├── AWS Systems Manager Core (SSM)
│   ├── Get/Set session tokens
│   ├── Session Manager access
│   └── CloudWatch Agent support
│
├── Secrets Manager
│   ├── GetSecretValue
│   ├── DescribeSecret
│   └── ListSecrets
│
├── EKS
│   ├── DescribeCluster
│   └── ListClusters
│
└── ECR
    ├── GetAuthorizationToken
    ├── PushImage
    ├── PullImage
    └── DescribeRepositories
```

### Jenkins Access Methods (Private Subnet - Must go through Bastion)

1. **SSH via Bastion**: `ssh → bastion → ssh to Jenkins private IP`
2. **SSM Session Manager via Bastion**: Requires Bastion as jump host
3. **Jenkins UI**: SSH tunnel through Bastion to port 8080, then access via localhost:8080
4. **Direct AWS SSM**: Jenkins has AmazonSSMManagedInstanceCore policy but still in private subnet

## 🔐 IAM Architecture

### Service Roles

#### Jenkins Role (`clinic-appointment-jenkins-role`)

- **Trust Policy**: EC2 service principal
- **Attached Policies**:
  - AmazonSSMManagedInstanceCore
  - Custom policy for Secrets Manager, EKS, ECR access
- **Instance Profile**: clinic-appointment-jenkins-instance-profile

#### EKS Control Plane Role (AWS Managed)

- **Service Principal**: eks.amazonaws.com
- **Purpose**: Manage cluster resources

#### EKS Node Role (AWS Managed)

- **Service Principal**: ec2.amazonaws.com
- **Policies**:
  - AmazonEKSWorkerNodePolicy
  - AmazonEKS_CNI_Policy
  - AmazonEC2ContainerRegistryReadOnly

#### ALB Controller IRSA Role (if enabled)

```
Role: clinic-appointment-alb-controller-irsa

OIDC Provider: EKS cluster
Service Account: kube-system:aws-load-balancer-controller
Policy: AWSLoadBalancerControllerIAMPolicy

Purpose: Allow pods to manage ALB/NLB resources
```

## 🔌 VPC Endpoints Architecture

### Optional Private Endpoints

When `enable_private_api_endpoints: true`:

```
Private Subnets
    ↓
VPC Endpoints (Interface Type)
    ├── EC2
    ├── EKS
    ├── STS (Security Token Service)
    ├── STS Messages
    ├── Systems Manager (SSM)
    ├── SSM Messages
    ├── SecretsManager
    │
    └── S3 (Gateway Type)
```

**Benefits:**

- No internet access needed for private resources
- Enhanced security (no data leaves VPC)
- Reduced NAT gateway costs
- Dedicated network bandwidth

**Route Configuration:**

- S3 Endpoint: Routes via route table
- Interface Endpoints: Private DNS (alias records)

## 🎯 Bastion Host Architecture

### Bastion Configuration

```
Instance Type: t3.micro
AMI: Amazon Linux 2023 (latest)
Subnet: Public (us-east-1a)
Public IP: Yes (via IGW)
Session Manager: Available
SSH Access: Via key pair

Key Pair: clinic-appointment-bastion-key
├── Private Key: Generated by Terraform (show via tf output)
├── Public Key: Stored in EC2 Key Pairs
└── Algorithm: RSA 4096-bit
```

### Bastion Security

```
Access Methods:
1. AWS Systems Manager Session Manager (preferred)
   - No SSH key needed
   - IAM-based
   - Encrypted connection
   - Auditable in CloudTrail

2. SSH (direct, if opened)
   - SSH key required
   - Source: bastion_allowed_cidrs (default: 0.0.0.0/0)
   - Port: 22

From Bastion:
└─ Access Jenkins UI (port 8080)
└─ Access private VPC resources
└─ Direct access to RDS (if needed)
```

## 🔄 Data Flow

### Application Deployment Flow

```
Developer
    ↓
Git Repository
    ↓
Jenkins (CI Pipeline)
    ↓
Build Docker Image
    ↓
Push to ECR
    ↓
Deploy to EKS
    ↓
Pods running in Kubernetes
    ↓
Connect to Database
    └─ Dev: Kubernetes PostgreSQL StatefulSet
    └─ Prod: AWS RDS PostgreSQL
```

### API Request Flow

```
Client
    ↓
AWS Load Balancer (if ALB enabled)
    ├── DNS: Created by AWS ALB Controller
    └── Target: Kubernetes Service/Ingress
    ↓
Kubernetes Service
    ↓
Application Pods (EKS Nodes)
    ↓
Database (RDS or StatefulSet)
```

## 📊 Resource Tagging

All resources are tagged for organization and cost allocation:

```
tags {
  Project   = "clinic-appointment"
  ManagedBy = "terraform"
  CreatedBy = "terraform"
  Environment = "dev" or "prod" (from Terraform)
}
```

**Additional Tags per Resource:**

- VPC: Kubernetes tags for ALB/NLB routing
- Subnets: kubernetes.io/role/\* tags
- EC2 Instances: Name tag with resource type

## 🔗 Inter-Component Communication

```
Jenkins ──HTTP──> Kubernetes API (via IAM)
Jenkins ──HTTP──> ECR (API endpoint)
EKS Nodes ──TCP:5432──> RDS / PostgreSQL StatefulSet
EKS Nodes ──PULL──> ECR (Docker images)
ALB Control Plane ──API──> EKS (manage load balancers)
Bastion ──SSH──> Jenkins, EKS Nodes (via SSM or direct SSH)
```

## 🎓 Module Dependencies

### Terraform Module Order (Automatically Resolved)

```
local.tags
    ↓
provider (aws)
    ↓
data.aws_ami (al2023)
    ↓
vpc ──┐
      ├──> eks ──┐
      │          ├──> alb_controller_irsa
      ├──> rds ──┤
      │          ├──> jenkins
      ├──> jenkins
      │
      └──> bastion
```

**Note**: Terraform automatically handles dependencies defined in HCL references.

---

**Note**: This architecture is designed for scale, security, and operational excellence. All resources follow AWS best practices and are production-ready with proper monitoring, backup, and high availability configurations.
