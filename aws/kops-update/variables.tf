variable "nodeup-url-env" {
  type        = string
  description = "NODEUP_URL env. variable override for testing custom builds of nodeup"

  default = ""
}

variable "aws-profile" {
  type        = string
  description = "Name of the AWS profile in ~/.aws/credentials or ~/.aws/config to use"

  default = "default"
}

variable "kops-state-bucket" {
  type        = string
  description = "Name of the bucket in which kops stores its state (must be created prior to cluster turnup)"
}

variable "cluster-name" {
  description = "Cluster domain name (i.e. mycluster.example.com)"
  type        = string
}

variable "triggers" {
  type = map(string)
}

variable "rolling-update" {
  type    = bool
  default = false
}

variable "apiserver-nodes-enabled" {
  type = string
  default = false
}
