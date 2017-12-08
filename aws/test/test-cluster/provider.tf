/*
 * AWS cloud provider & terraform user definition (spans the entire Morpheo Org.)
 */

// Default AWS provider, used for worldwide resources (IAM assets, main DNS zone...)
provider "aws" {
  region = "${var.aws-region}"
}
