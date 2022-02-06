# Multitenant+Multicluster management using GitHub Actions, Terraform and Rancher

[![Build Status](https://github.com/ruzickap/k8s-tf-rancher/actions/workflows/mdbook-build-check-deploy.yml/badge.svg)](https://github.com/ruzickap/k8s-tf-rancher/actions/workflows/mdbook-build-check-deploy.yml)

* GitHub repository: [https://github.com/ruzickap/k8s-tf-rancher](https://github.com/ruzickap/k8s-tf-rancher)
* Web Pages: [https://ruzickap.github.io/k8s-tf-rancher](https://ruzickap.github.io/k8s-tf-rancher)

## Rancher notes

Very limited amount of settings for Amazon EKS. The following features
are missing:

* You can only re-use "public" subnets [Subnet](https://rancher.com/docs/rancher/v2.6/en/cluster-admin/editing-clusters/eks-config-reference/#subnet).
  I'm not sure if I can use/define private subnets.
* Encrypted worker nodes disk(s) can be only configured using launch template
* Disks, EC2, subnets, VPCs, security groups are not tagged
* Subnet / EC2 names can not be set
* Default security groups are set to "allow all everywhere"
* IRSA ?
* It is not trivial to change the CloudWatch Retention (where EKS stores it's
  logs)
* The terraform destroy doesn't wait for "real" cluster deletion... - this is
  causing problems in case of deleing the CloudWatch Log Group
* [terraform destroy doesn't work properly for Amazon EKS cluster](https://github.com/rancher/terraform-provider-rancher2/issues/858)
* Using Terraform `rancher2_cluster` resource does't work when specifying
  `image_id`.
* Launch template is not deleted when destroying the Amazon EKS (which then
  prevents to create the same cluster again)
