# Lifecycle hooks
output "master-up" {
  value = "${null_resource.master-up.id}"
}

output "cluster-created" {
  value = "${null_resource.kops-cluster.id}"
}

# DNS zone for the cluster subdomain
output "route53-cluster-zone-id" {
  value = "${aws_route53_zone.cluster.id}"
}

output "vpc-id" {
  value = "${aws_vpc.main.id}"
}

// List of utility (public) subnets
output "utility-subnets" {
  value = ["${data.aws_subnet.utility-subnet.*.id}"]
}

// Standard IG subnets
output "subnets" {
  value = ["${data.aws_subnet.subnet.*.id}"]
}

// Nodes security groups (to direct ELB traffic to hostPort pods)
output "nodes-sg" {
  value = "${element(split("/", data.aws_security_group.nodes.arn), 1)}"
}
