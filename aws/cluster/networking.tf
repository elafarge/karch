/*
 * Configures a VPC on top of which we'll use kops to spawn our Kubernetes cluster
 */

// Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = "${var.vpc-id}"

  tags {
    Name   = "${var.cluster-name}"
    Origin = "Terraform"
  }
}
