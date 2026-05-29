# ── Bastion ────────────────────────────────────────────────────

resource "aws_security_group" "bastion" {
  name        = "${local.tags.Project}-bastion-sg"
  description = "Bastion — SSH from trusted IPs only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.bastion_allowed_cidrs
    description = "SSH from trusted IPs"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.bastion.key_name

  tags = merge(local.tags, { Name = "${local.tags.Project}-bastion" })
}


resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion" {
  key_name   = "${local.tags.Project}-bastion-key"
  public_key = tls_private_key.bastion.public_key_openssh
}
