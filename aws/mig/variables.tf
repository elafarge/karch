# Dependency hooks
variable "master-up" {
  type        = string
  description = "Terraform dependency hook to wait for the master cluster to be up before creating instance groups"
}

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
  description = "Nodes volume type (io1/gp2), defaults to gp2"

  default = "gp2"
}

variable "ebs-optimized" {
  type        = bool
  description = "Boolean (true or false) indicating whether our nodes should be EBS optimized"

  default = false
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

variable "additional_types" {
  type        = list(string)
  default     = []
  description = "Instances is a list of instance types which we are willing to run in the EC2 fleet."
}

variable "policy_ondemand_base" {
  type        = number
  default     = 0
  description = "On demand base is the minimum amount of the Auto Scaling group's capacity that must be fulfilled by On-Demand Instances. This base portion is provisioned first as your group scales (default: 0)."
}

variable "policy_ondemand_above_base" {
  type        = number
  default     = 100
  description = "On demand above base controls the percentages of On-Demand Instances and Spot Instances for your additional capacity beyond on demand base. The range is 0–100. If youleave this parameter set to 100, the percentages are 100% for On-Demand Instances and 0% for Spot Instances. (default: 100)"
}

variable "policy_ondemand_allocation_strategy" {
  type        = string
  default     = "prioritized"
  description = "On-Demand allcoation strategy should be one of (lowest-price/prioritized) (default: prioritized)."
}

variable "policy_spot_instance_pools" {
  type        = number
  default     = 2
  description = "Spot instance pools is the number of Spot pools to use to allocate your Spot capacity (default: 2)."
}

variable "policy_spot_allocation_strategy" {
  type        = string
  default     = "lowest-price"
  description = "Spot allcoation strategy should be one of (lowest-price/capacity-optimized) more https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-fleet.html#spot-fleet-allocation-strategy (default: lowest-price)."
}
