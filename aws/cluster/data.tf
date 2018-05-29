data "aws_security_group" "nodes" {
  vpc_id = "${var.vpc-id}"

  filter {
    name = "tag:Name"

    // Same remark as above
    values = ["nodes.${var.cluster-name}", "${null_resource.master-up.id}"]
  }
}

data "aws_security_group" "masters" {
  vpc_id = "${var.vpc-id}"

  filter {
    name = "tag:Name"

    // Same remark as above
    values = ["masters.${var.cluster-name}", "${null_resource.master-up.id}"]
  }
}
