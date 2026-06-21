# ── EFS for shared media storage ────────────────────────────────
resource "aws_security_group" "efs" {
  name        = "${var.environment}-clinic-efs-sg"
  description = "Allow NFS from EKS nodes only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_efs_file_system" "media" {
  encrypted = true
  tags      = merge(local.tags, { Name = "${var.environment}-clinic-media" })
}

resource "aws_efs_mount_target" "media" {
  for_each = {
    az1 = module.vpc.private_subnets[0]
    az2 = module.vpc.private_subnets[1]
  }
  file_system_id  = aws_efs_file_system.media.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

module "efs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"

  name = "${var.environment}-efs-csi-irsa"

  attach_efs_csi_policy = true

  oidc_providers = {
    eks = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
    }
  }
}

resource "aws_eks_addon" "efs_csi_driver" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-efs-csi-driver"
  service_account_role_arn = module.efs_csi_irsa_role.arn

  depends_on = [module.eks]
}

output "efs_file_system_id" {
  value = aws_efs_file_system.media.id
}
