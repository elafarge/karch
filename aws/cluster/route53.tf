/*
 * Cluster public subdomain configuration
 */

locals {
  dns_soa_hostmaster   = "awsdns-hostmaster.amazon.com"
  dns_soa_refresh_time = 7200
  dns_soa_retry_time   = 900
  dns_soa_expire_time  = 1209600
  dns_soa_negative_ttl = 60
  dns_soa_appendix     = "${local.dns_soa_hostmaster}. 1 ${local.dns_soa_refresh_time} ${local.dns_soa_retry_time} ${local.dns_soa_expire_time} ${local.dns_soa_negative_ttl}"
}

resource "aws_route53_zone" "cluster" {
  name          = "${var.cluster-name}"
  force_destroy = true
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

resource "aws_route53_record" "cluster-soa" {
  zone_id = "${aws_route53_zone.cluster.id}"
  name    = "${aws_route53_zone.cluster.name}"
  type    = "SOA"
  ttl     = "60"
  records = ["${aws_route53_zone.cluster.name_servers.0}. ${local.dns_soa_appendix}"]

  allow_overwrite = true
}
