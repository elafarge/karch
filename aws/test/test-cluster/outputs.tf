output "ingress-elb-dns-name" {
  value = "${aws_elb.ingress.dns_name}"
}

output "ingress-elb-zone-id" {
  value = "${aws_elb.ingress.zone_id}"
}

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
