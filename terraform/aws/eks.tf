# ── EKS ────────────────────────────────────────────────────────
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name                                     = "${var.environment}-clinic-cluster"
  kubernetes_version                       = "1.33"
  enable_cluster_creator_admin_permissions = var.enable_eks_bootstrap_cluster_creator_admin_permissions

  endpoint_public_access  = var.enable_eks_endpoint_public_access
  endpoint_private_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  addons = {
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }
    coredns = {
      most_recent    = true
      before_compute = true
    }
    kube-proxy = {
      most_recent    = true
      before_compute = true
    }
  }

  eks_managed_node_groups = {
    clinic_nodes = {
      instance_types = [var.node_instance_type]
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size
      key_name       = aws_key_pair.bastion.key_name

    }
  }



  access_entries = {
    jenkins = {
      principal_arn = aws_iam_role.jenkins.arn

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  encryption_config = {
    provider_key_arn = aws_kms_key.eks_secrets.arn
    resources        = ["secrets"]
  }


  tags = local.tags


}


resource "aws_kms_key" "eks_secrets" {
  description             = "EKS secrets encryption - ${var.environment}"
  deletion_window_in_days = 7
  tags                    = local.tags
}

resource "aws_kms_alias" "eks_secrets" {
  name          = "alias/${var.environment}-eks-secrets"
  target_key_id = aws_kms_key.eks_secrets.key_id
}

resource "aws_security_group_rule" "eks_api_from_jenkins" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  description              = "Jenkins to EKS API server"
  security_group_id        = module.eks.cluster_security_group_id
  source_security_group_id = aws_security_group.jenkins.id
}


resource "aws_security_group_rule" "nodes_allow_http_internal" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = module.eks.node_security_group_id
  source_security_group_id = module.eks.node_security_group_id
  description              = "Allow ingress-nginx controller to reach app pods"
}
