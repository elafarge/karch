variable "aws-account-id" {
  type        = "string"
  description = "AWS account ID for your org."
}

variable "kops-policies" {
  description = "IAM policies necessary for kops to work"
  type        = "list"

  default = [
    "AmazonEC2FullAccess",
    "AmazonRoute53FullAccess",
    "AmazonS3FullAccess",
    "IAMFullAccess",
    "AmazonVPCFullAccess",
  ]
}

variable "domain" {
  type        = "string"
  description = "Main domain name for the organization (ex.: example.com)"
}

variable "kops-state-bucket" {
  description = "Name of the S3 bucket that will hold the Kops state files"
  type        = "string"
}

variable "kubernetes-version" {
  type        = "string"
  description = "Kubernetes version to use for Core components (default: v1.7.4)"
}
