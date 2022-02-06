# Cluster Name should only consist alphanumeric character and '-'
cluster_name        = "ruzickap-eks"
cluster_fqdn        = "ruzickap-eks.test.k8s.mylabs.dev"
cluster_description = "Amazon EKS test cluster owned by petr.ruzicka@gmail.com"

aws_account_id      = "729560437327"
aws_vpc_cidr        = "10.0.0.0/21"
aws_private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
aws_public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

aws_tags_cluster_level = {
  owner = "petr.ruzicka@gmail.com"
}


# Parameters in these maps can not be added / removed without changing the TF code
rancher_cluster = {
  enable_cluster_alerting   = false
  cluster_monitoring_input  = false
  enable_cluster_monitoring = false
  enable_network_policy     = false
}

eks_config_v2 = {
  private_access = true
  public_access  = true
  # TF destroy will not remove the Log Group from CloudWatch
  # It is also set to "non-expire" by default
  logging_types = ["audit"]
}

# In terrafrom it is not asy to do the deep merge of map of maps and it is not
# possible to use them as block in rancher2 provisioner (in case of multile node_groups)
# https://discuss.hashicorp.com/t/use-block-variables/5527/3
# https://github.com/rancher/terraform-provider-rancher2/issues/836
# HCL Dynamic blocks do not help in case of using "variable" maps
# Therefore I'm using separate variables :-(

# https://github.com/rancher/terraform-provider-rancher2/blob/master/rancher2/structure_cluster_eks_config_v2.go
eks_config_v2_node_groups = [
  {
    desired_size = 2
    disk_size    = 29
    gpu          = false
    # amazon-eks-node-1.21-v20220123 | bottlerocket-aws-k8s-1.21-x86_64-v1.5.3-f37bd7cb
    # image_id = "ami-020452378df41ab4b"
    instance_type = "t2.medium"
    max_size      = 2
    min_size      = 2
    name          = "ruzickap-eks-ng01"
    resource_tags = {
      additional_tag = "123456"
    }
  },
  # {
  #   desired_size = 2
  #   disk_size    = 19
  #   gpu          = false
  #   # amazon-eks-node-1.21-v20220123 | bottlerocket-aws-k8s-1.21-x86_64-v1.5.3-f37bd7cb
  #   # image_id = "ami-020452378df41ab4b"
  #   instance_type = "t3.medium"
  #   max_size      = 2
  #   min_size      = 2
  #   name          = "ruzickap-eks-ng02"
  #   resource_tags = {
  #     additional_tag111 = "3333333"
  #   }
  # },
]
