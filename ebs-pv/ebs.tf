resource "aws_ebs_volume" "ebs-pv" {
  availability_zone = "${var.availability-zone}"
  type              = "${var.type}"
  size              = "${var.size}"
  snapshot_id       = "${var.snapshot-id}"

  encrypted  = "${var.kms-key-id == "" ? "false" : "true"}"
  kms_key_id = "${var.kms-key-id}"

  tags {
    Name = "${var.name}"
  }
}
