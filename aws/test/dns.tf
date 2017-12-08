resource "aws_route53_record" "pong" {
  zone_id = "${data.aws_route53_zone.test.id}"
  name    = "pong"
  type    = "A"

  alias {
    name                   = "${module.test-cluster.ingress-elb-dns-name}"
    zone_id                = "${module.test-cluster.ingress-elb-zone-id}"
    evaluate_target_health = "false"
  }
}
