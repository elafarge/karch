# AWS provider config
variable "aws-region" {
  description = "The region to spawn this Kubernetes cluster into"
  type        = "string"
}

# Networking & Security
variable "vpc-name" {
  description = "Arbitrary name to give to your VPC"
  type        = "string"
}

variable "vpc-cidr" {
  description = "The (created) Kubernetes VPC CIDR."
  type        = "string"
}

variable "availability-zones" {
  type        = "list"
  description = "Availability zones to span (for HA master deployments, see master-availability-zones)"
}

variable "trusted-cidrs" {
  type        = "list"
  description = "CIDR whitelist for Kubernetes master HTTPs & bastion SSH access (default: 0.0.0.0/0)"

  default = ["0.0.0.0/0"]
}

variable "admin-ssh-public-key-path" {
  type        = "string"
  description = "Path to the cluster admin's public SSH key (default: ~/.ssh/id_rsa.pub)"

  default = "~/.ssh/id_rsa.pub"
}

## DNS
variable "main-zone-id" {
  description = "Route53 main zone ID"
  type        = "string"
}

variable "cluster-name" {
  description = "Cluster domain name (i.e. mycluster.example.com)"
  type        = "string"
}

variable "kube-dns-domain" {
  type        = "string"
  description = "Domain enforced in our cluster by kube-dns (default: local, ex.: cluster.local)"
}

# Kops & Kubernetes
variable "kops-state-bucket" {
  type        = "string"
  description = ""
}

variable "kops-channel" {
  type        = "string"
  description = "Channel to use for our Kops cluster (default stable)"
  default     = "stable"
}

variable "kubernetes-version" {
  type        = "string"
  description = "Kubernetes version to use for Core components (default: v1.7.4)"
  default     = "v1.7.4"
}

variable "cloud-labels" {
  type        = "map"
  description = "(Flat) map of kops cloud labels to apply to all resource in cluster"

  default = {}
}

variable "base-ami" {
  type        = "string"
  description = "Base AMI ID to use for all of our nodes"
}

# Master instance group(s)
variable "master-availability-zones" {
  type        = "list"
  description = "Availability zones in which to create master instance groups"
}

variable "master-machine-type" {
  type        = "string"
  description = "EC2 instance type to run our masters onto (default: m3.medium)"

  default = "m4.large"
}

variable "master-volume-size" {
  type        = "string"
  description = "Size of our master's root volume, in GB (default: 10)"

  default = "30"
}

variable "master-volume-type" {
  type        = "string"
  description = "Master volume type (io1/gp2), defaults to gp2"

  default = "gp2"
}

# Initial minion instance group
variable "cluster-base-minion-ig-name" {
  type        = "string"
  description = "Name to give to the ig created along with the cluster (default: default)"

  default = "default"
}

variable "cluster-base-minion-machine-type" {
  type        = "string"
  description = "EC2 instance type to run our minions onto (default: t2.medium)"

  default = "m4.large"
}

variable "cluster-base-minions-min" {
  type        = "string"
  description = "Cluster base minion ASG min size (default: 1)"

  default = 1
}

variable "cluster-base-minions-max" {
  type        = "string"
  description = "Cluster base minion ASG max size (default: 3)"

  default = 3
}

# Hypothetical nodes targeted at welcoming our ingress controllers
variable "ingress-nodes-subnets" {
  type        = "list"
  description = "Subnets (aka AZs) the ingress-nodes should span"
}

variable "ingress-machine-type" {
  type        = "string"
  description = "EC2 instance type to run our ingress nodes onto (default: t2.medium)"

  default = "m4.large"
}

variable "ingress-min-nodes" {
  type        = "string"
  description = "Ingress ASG min size (default: 1)"

  default = 2
}

variable "ingress-max-nodes" {
  type        = "string"
  description = "Ingress ASG max size (default: 3)"

  default = 3
}
