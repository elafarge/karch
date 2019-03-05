# Lifecycle hooks
output "master-up" {
  value = "${null_resource.master-up.id}"
}

output "cluster-created" {
  value = "${null_resource.kops-cluster.id}"
}

# DNS zone for the cluster subdomain
output "cluster-zone-id" {
  value = "${aws_route53_zone.cluster.id}"
}

output "route53-cluster-zone-id" {
  value = "${aws_route53_zone.cluster.id}"
}

output "vpc-id" {
  value = "${var.vpc-id}"
}

// Nodes security groups (to direct ELB traffic to hostPort pods)
output "nodes-sg" {
  value = "${element(split("/", data.aws_security_group.nodes.arn), 1)}"
}

output "masters-sg" {
  value = "${element(split("/", data.aws_security_group.masters.arn), 1)}"
}

output "etcd-volume-ids" {
  value = "${data.aws_ebs_volume.etcd-volumes.*.id}"
}

output "etcd-event-volume-ids" {
  value = "${data.aws_ebs_volume.etcd-event-volumes.*.id}"
}

output "cluster-cidr-block" {
  value = "${aws_vpc.main.cidr_block}"
}

// List of utility (public) subnets
output "utility-subnets" {
  value = ["${aws_subnet.utility.*.id}"]
}

// Standard IG subnets
output "subnets" {
  value = ["${aws_subnet.private.*.id}"]
}

// Utility (public) route tables
output "utility-route-tables" {
  value = ["${aws_route_table.utility.*.id}"]
}

// Standard route tables
output "route-tables" {
  value = ["${aws_route_table.private.*.id}"]
}
