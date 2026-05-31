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

  eks_managed_node_groups = {
    clinic_nodes = {
      instance_types = [var.node_instance_type]
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size

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

  tags = local.tags
}
