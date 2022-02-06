output "rancher_cluster" {
  sensitive = true
  value     = rancher2_cluster.cluster
}
