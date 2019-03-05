/*
 * Cluster public subdomain configuration
 */

resource "aws_route53_zone" "cluster" {
  name          = "${var.cluster-name}"
  force_destroy = true
}

resource "aws_route53_zone_association" "kubernetes-vpc" {
  vpc_id  = "${aws_vpc.main.id}"
  zone_id = "${aws_route53_zone.cluster.id}"
}

resource "aws_route53_record" "cluster-root" {
  count = "${var.master-lb-visibility == "Private" ? 0 : 1}"

  zone_id = "${var.main-zone-id}"
  name    = "${var.cluster-name}"
  type    = "NS"
  ttl     = "30"

  records = [
    "${aws_route53_zone.cluster.name_servers.0}",
    "${aws_route53_zone.cluster.name_servers.1}",
    "${aws_route53_zone.cluster.name_servers.2}",
    "${aws_route53_zone.cluster.name_servers.3}",
  ]
}
