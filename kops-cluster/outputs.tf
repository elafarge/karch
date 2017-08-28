output "master-up" {
  value = "${null_resource.master-up.id}"
}

output "cluster-created" {
  value = "${null_resource.kops-cluster.id}"
}

output "vpc-id" {
  value = "${aws_vpc.main.id}"
}

output "route53-cluster-zone-id" {
  value = "${aws_route53_zone.cluster.id}"
}
