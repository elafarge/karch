data "aws_autoscaling_group" "ig" {
  name       = "${var.name}.${var.cluster-name}"
  depends_on = [null_resource.ig-update]
}
