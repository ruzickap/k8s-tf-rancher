terraform {
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.73.0"
    }
    rancher2 = {
      source  = "rancher/rancher2"
      version = "1.22.2"
    }
  }
  required_version = ">= 1.0.0"
}

locals {
  vpc_name              = var.cluster_fqdn
  cluster_iam_role_name = "${var.cluster_name}-policy"
  # Merging tfvars file when running terraform is not possible therefore I'm doing it here
  # (https://stackoverflow.com/questions/64615552/merge-more-than-2-tfvars-file-contents)
  aws_default_tags = merge(
    var.aws_tags_group_level,
    var.aws_tags_cluster_level,
  )
}

provider "aws" {
  # specify default tags that will be applied to ALL resources: https://www.hashicorp.com/blog/default-tags-in-the-terraform-aws-provider
  default_tags {
    tags = local.aws_default_tags
  }
  region = var.aws_default_region
}

provider "rancher2" {
  api_url   = var.rancher_api_url
  token_key = var.rancher_token_key
}
