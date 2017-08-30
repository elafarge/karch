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

// Internet Gatewo
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name   = "${var.cluster-name}"
    Origin = "Terraform"
  }
}

// VPC endpoint to connect to S3 while bypassing the expensive NAT device
resource "aws_vpc_endpoint" "s3_endpoint" {
  service_name = "com.amazonaws.${var.aws-region}.s3"
  vpc_id       = "${aws_vpc.main.id}"
}
