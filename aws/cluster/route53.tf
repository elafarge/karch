/*
 * Cluster public subdomain configuration
 */

resource "aws_route53_zone" "cluster" {
  name          = "${var.cluster-name}"
  force_destroy = true

  vpc {
    vpc_id = "${aws_vpc.main.id}"
  }

  lifecycle {
    ignore_changes = ["vpc"]
  }
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
