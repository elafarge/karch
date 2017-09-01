data "aws_subnet" "utility-subnet" {
  count = "${length(var.availability-zones)}"

  vpc_id            = "${aws_vpc.main.id}"
  availability_zone = "${element(var.availability-zones, count.index)}"

  filter {
    name = "tag:Name"

    // The second value simply is a way to make sure this data source will
    // only be provisioned once these subnets have been created by kops
    values = ["utility-${element(var.availability-zones, count.index)}.${var.cluster-name}", "${null_resource.master-up.id}"]
  }
}

data "aws_subnet" "subnet" {
  count = "${length(var.availability-zones)}"

  vpc_id            = "${aws_vpc.main.id}"
  availability_zone = "${element(var.availability-zones, count.index)}"

  filter {
    name = "tag:Name"

    // Same remark as above
    values = ["${element(var.availability-zones, count.index)}.${var.cluster-name}", "${null_resource.master-up.id}"]
  }
}

data "aws_security_group" "nodes" {
  vpc_id = "${aws_vpc.main.id}"

  filter {
    name = "tag:Name"

    // Same remark as above
    values = ["nodes.${var.cluster-name}", "${null_resource.master-up.id}"]
  }
}
