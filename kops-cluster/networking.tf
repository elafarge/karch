/*
 * Configures a VPC on top of which we'll use kops to spawn our Kubernetes cluster
 */

// The VPC itself
resource "aws_vpc" "main" {
  cidr_block           = "10.${var.vpc-number}.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Name   = "${var.cluster-name}"
    Origin = "Terraform"
  }
}

// Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name   = "${var.cluster-name}"
    Origin = "Terraform"
  }
}
