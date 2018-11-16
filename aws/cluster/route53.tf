/*
 * Cluster public subdomain configuration
 */

resource "aws_route53_zone" "cluster" {
  count         = "${var.create-dns-zone == "true" ? 1 : 0}"
  name          = "${var.cluster-name}"
  vpc_id        = "${var.master-lb-visibility == "Private" ? aws_vpc.main.id : ""}"
  force_destroy = true
}

resource "aws_route53_record" "cluster-root" {
  count = "${var.master-lb-visibility != "Private" && var.create-dns-zone == "true" ? 1 : 0}"

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
