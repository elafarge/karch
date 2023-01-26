# Kops env. overrides
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

# Instance group parameters
variable "create_cluster_spec_object" {
  description = "Resource count, should be either 1 or 0. It is a workaround for group destruction that needs to be done in phased manner by first making its count 0 and the removing from config."
  type        = string
  default     = "1"
}

variable "cluster-name" {
  type        = string
  description = "The name of the Kops cluster the instance group belongs to"
}

variable "name" {
  type        = string
  description = "The name of the instance group"
}

variable "kops-state-bucket" {
  type        = string
  description = ""
}

variable "automatic-rollout" {
  type        = bool
  description = "If set to true, a rolling update of the instance group will be triggered when its spec is modified"

  default = false
}

variable "update-interval" {
  type        = number
  description = "Rolling update interval"

  default = 8
}

# Networking & Security
variable "visibility" {
  type        = string
  description = "Visibility (public|private) of the instance group (default: private)"

  default = "private"
}

variable "subnets" {
  type        = list(string)
  description = "Subnets this instance group should span"
}

variable "additional-sgs" {
  type        = list(string)
  description = "A list of additional security groups to add to this instance"

  default = []
}

# Node config
variable "image" {
  type        = string
  description = "AMI id to use for the nodes"
}

variable "type" {
  type        = string
  description = "EC2 instance type to run our nodes onto"
}

variable "volume-size" {
  type        = number
  description = "Size of our nodes' root volume, in GB (default: 10)"

  default = 10
}

variable "volume-provisioned-iops" {
  type        = string
  description = "Nodes volume provisioned IOPS, if applicable"

  default = ""
}

variable "volume-type" {
  type        = string
  description = "Nodes volume type (io1/gp2/gp3), defaults to gp3"

  default = "gp3"
}

variable "ebs-optimized" {
  type        = bool
  description = "Boolean (true or false) indicating whether our nodes should be EBS optimized"

  default = false
}

variable "max-price" {
  type        = string
  description = "If set, this group will use spot instances with the specified max-price"

  nullable = true
}

variable "hooks" {
  type        = list(map(any))
  description = "Docker/Systemd hooks to add to this instance group. https://kops.sigs.k8s.io/cluster_spec/#hooks"

  default = []
}

# ASG configuration
variable "max-size" {
  type        = number
  description = "Group max size"

  default = 5
}

variable "min-size" {
  type        = number
  description = "Group min size"

  default = 1
}

variable "external-load-balancers" {
  type        = list(map(string))
  description = "External load balancers config"
  default     = []
}

# Labels
variable "taints" {
  type        = list(string)
  description = "List of taints to add to the nodes"

  default = []
}

variable "cloud-labels" {
  type        = map(string)
  description = "(Flat) map of cloud labels"

  default = {}
}

variable "node-labels" {
  type        = map(string)
  description = "(Flat) map of node labels"

  default = {}
}

variable "rolling-update" {
  type = object({
    max-surge       = any
    max-unavailable = any
  })
  description = "Settings for rolling update. Both can be expressed as absolute numbers or percent, e.g. \"30%\""

  default = {
    max-surge       = 1
    max-unavailable = 0
  }
}

variable "warm-pool" {
  type = object({
    min-size              = number
    max-size              = number
    enable-lifecycle-hook = bool
  })
  description = "AWS WarmPool to get pre-initialized EC2 instances."

  nullable = true
}

variable "user-data" {
  type = list(map(object({
    name    = string
    type    = string
    content = string
  })))
  description = "UserData defines a user-data section to be passed to the host"
  default     = []
}
