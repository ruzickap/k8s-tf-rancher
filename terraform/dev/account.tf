# ---------------------------------------------------------------------------------------------------------------------
# Rancher Access
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_user" "rancher" {
  name = "rancher-${var.cluster_fqdn}"
}

resource "aws_iam_user_policy_attachment" "rancher" {
  user       = aws_iam_user.rancher.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_access_key" "rancher" {
  user = aws_iam_user.rancher.name
}

resource "rancher2_cloud_credential" "rancher_aws_account" {
  name        = "aws-${var.aws_account_id}-rancher-${var.cluster_fqdn}"
  description = "Access to AWS account ${var.aws_account_id} for ${var.cluster_fqdn}"
  amazonec2_credential_config {
    access_key = aws_iam_access_key.rancher.id
    secret_key = aws_iam_access_key.rancher.secret
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CloudWatch - log group
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 1
}

# ---------------------------------------------------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------------------------------------------------

module "vpc" {
  # This is needed, because Terraform rancher module doesn't wait for destroying the EKS
  depends_on = [rancher2_cloud_credential.rancher_aws_account, aws_cloudwatch_log_group.eks_cluster]
  source     = "terraform-aws-modules/vpc/aws"
  version    = "3.11.3"

  name = local.vpc_name
  cidr = var.aws_vpc_cidr

  azs            = ["${var.aws_default_region}a", "${var.aws_default_region}b", "${var.aws_default_region}c"]
  public_subnets = var.aws_public_subnets

  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = 1
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Create the cluster's KMS key
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_kms_key" "eks-kms_key" {
  description             = "${var.cluster_fqdn} Amazon EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}"
  target_key_id = aws_kms_key.eks-kms_key.key_id
}

# ---------------------------------------------------------------------------------------------------------------------
# Launch Template
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_launch_template" "eks" {
  name                   = "${var.cluster_name}-lt"
  description            = "Amazon EKS managed node group launch template for ${var.cluster_fqdn}"
  update_default_version = true

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 4
      volume_type           = "gp3"
      delete_on_termination = true
      # Disk encryption doesn't work at all - ec2 are not created
      # encrypted             = true
      # kms_key_id            = aws_kms_key.eks-kms_key.arn
    }
  }

  block_device_mappings {
    device_name = "/dev/xvdb"
    ebs {
      volume_size           = 21
      volume_type           = "gp3"
      delete_on_termination = true
      # Disk encryption doesn't work at all - ec2 are not created
      # encrypted             = true
      # kms_key_id            = aws_kms_key.eks-kms_key.arn
    }
  }

  # Needs to be disabled, otherwise Node group will not be created  :-(
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  network_interfaces {
    description                 = "NIC for ${var.cluster_fqdn}"
    associate_public_ip_address = true
    delete_on_termination       = true
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.aws_default_tags, { Name = var.cluster_name })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(local.aws_default_tags, { Name = var.cluster_name })
  }

  tag_specifications {
    resource_type = "network-interface"
    tags          = merge(local.aws_default_tags, { Name = var.cluster_name })
  }

  lifecycle {
    create_before_destroy = true
  }
}
