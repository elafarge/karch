# AWS account information
data "aws_caller_identity" "current" {}

data "aws_region" "main" {
  current = true
}

# CoreOS base AMI
variable "coreos-ami-owner-id" {
  description = "The ID of the owner of the CoreOS image you want to use on the AWS marketplace (or yours if you're using your own AMI)."

  # CoreOS' official AWS id
  default = "595879546273"
  type    = "string"
}

variable "coreos-ami-pattern" {
  description = "The AMI pattern to use (it can be a full name or contain wildcards, default to the last release of CoreOS on the stable channel)."

  # Useful to change that to also run tests against the beta and alpha version of Container Linux
  default = "CoreOS-stable-*"
  type    = "string"
}

data "aws_ami" "coreos-stable" {
  most_recent = true

  filter {
    name   = "name"
    values = ["${var.coreos-ami-pattern}"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.coreos-ami-owner-id}"]
}

data "aws_route53_zone" "test" {
  name         = "${var.domain}"
  private_zone = "false"
}
