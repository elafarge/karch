output "ebs-id" {
  value = "${aws_ebs_volume.ebs-pv.id}"
}
