data "aws_security_group" "nodes" {
  vpc_id = "${aws_vpc.main.id}"

  filter {
    name = "tag:Name"

    // The second value is just a hacky dependency hooks on our cluster being created
    values = ["nodes.${var.cluster-name}", "${null_resource.master-up.id}"]
  }
}

data "aws_security_group" "masters" {
  vpc_id = "${aws_vpc.main.id}"

  filter {
    name = "tag:Name"

    // The second value is just a hacky dependency hooks on our cluster being created
    values = ["masters.${var.cluster-name}", "${null_resource.master-up.id}"]
  }
}
