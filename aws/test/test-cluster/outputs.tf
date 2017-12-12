output "subnets" {
  value = "${module.kops-cluster.subnets}"
}

output "nodes-sg" {
  value = "${module.kops-cluster.nodes-sg}"
}

output "vpc-id" {
  value = "${module.kops-cluster.vpc-id}"
}

output "master-up" {
  value = "${module.kops-cluster.master-up}"
}
