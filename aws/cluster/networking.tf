/*
 * Configures a VPC on top of which we'll use kops to spawn our Kubernetes cluster
 */

// The VPC itself
resource "aws_vpc" "main" {
  cidr_block           = "${var.vpc-cidr}"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Name   = "${var.cluster-name}"
    Origin = "Terraform"
  }

  lifecycle {
    ignore_changes = ["tags"]
  }
}

// Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name   = "${var.cluster-name}"
    Origin = "Terraform"
  }
}

resource "aws_subnet" "utility" {
  count = "${length(var.availability-zones)}"

  vpc_id                  = "${aws_vpc.main.id}"
  availability_zone       = "${element(var.availability-zones, count.index)}"
  map_public_ip_on_launch = true

  cidr_block = "${cidrsubnet(
    cidrsubnet(aws_vpc.main.cidr_block, 2, 0),
    3, count.index
  )}"

  tags {
    Name   = "utility-${element(var.availability-zones, count.index)}.${var.cluster-name}"
    Origin = "Terraform"
  }

  lifecycle {
    ignore_changes = ["tags"]
  }
}

resource "aws_route_table" "utility" {
  count = "${length(var.availability-zones)}"

  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name   = "utility-${element(var.availability-zones, count.index)}.${var.cluster-name}"
    Origin = "Terraform"
  }
}

resource "aws_route" "utility-to-internet" {
  count = "${length(var.availability-zones)}"

  route_table_id         = "${element(aws_route_table.utility.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
}

resource "aws_route_table_association" "utility" {
  count = "${length(var.availability-zones)}"

  subnet_id      = "${element(aws_subnet.utility.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.utility.*.id, count.index)}"
}

##################################
## Private subnets (one per AZ) ##
##################################
resource "aws_subnet" "private" {
  count = "${length(var.availability-zones)}"

  vpc_id = "${aws_vpc.main.id}"

  cidr_block = "${cidrsubnet(aws_vpc.main.cidr_block, 3, 2 + count.index)}"

  availability_zone = "${element(var.availability-zones, count.index)}"

  map_public_ip_on_launch = false

  tags {
    Name   = "${element(var.availability-zones, count.index)}.${var.cluster-name}"
    Origin = "Terraform"
  }

  lifecycle {
    ignore_changes = ["tags"]
  }
}

resource "aws_eip" "nat-device" {
  count = "${length(var.availability-zones)}"

  vpc = true
}

resource "aws_nat_gateway" "natgw" {
  count = "${length(var.availability-zones)}"

  allocation_id = "${element(aws_eip.nat-device.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.utility.*.id, count.index)}"
}

resource "aws_route_table" "private" {
  count = "${length(var.availability-zones)}"

  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name   = "${element(var.availability-zones, count.index)}.${var.cluster-name}"
    Origin = "Terraform"
  }
}

resource "aws_route" "private-to-internet" {
  count = "${length(var.availability-zones)}"

  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.natgw.*.id, count.index)}"
}

resource "aws_route_table_association" "private" {
  count = "${length(var.availability-zones)}"

  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}
