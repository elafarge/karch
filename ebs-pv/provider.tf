provider "aws" {
  region              = "${var.aws-region}"
  allowed_account_ids = ["${var.allowed-aws-account-ids}"]
  profile             = "${var.aws-profile}"
}
