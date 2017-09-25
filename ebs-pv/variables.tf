variable "master-up" {
  type        = "string"
  description = "Dependency hook to be sure that the Kubernetes master is up"
}

variable "availability-zone" {
  type        = "string"
  description = "The AZ to spawn your EBS volume into."
}

variable "type" {
  type        = "string"
  description = "EBS volume type (gp2, io1...). Defaults to GP2"

  default = "gp2"
}

variable "size" {
  type        = "string"
  description = "Size of the EBS volume to create, in Gigabytes"
}

variable "iops" {
  type        = "string"
  description = "If using the 'io1' volume type, amount of IOPS to provision for this volume"

  default = ""
}

variable "snapshot-id" {
  type        = "string"
  description = "ID of the snapshot to create this volumes from (leave blank to create an empty volume)"

  default = ""
}

variable "kms-key-id" {
  type        = "string"
  description = "KMS key ID to encryt the volume with, leave blank to create an unencrypted volume"

  default = ""
}

variable "name" {
  type        = "string"
  description = "Name of the Kubernetes persistent volume to create"
}

variable "labels" {
  type        = "map"
  description = "Labels to add to the created Kubernetes Persistent Volume"

  default = {}
}

variable "fs_type" {
  type        = "string"
  description = "FS type to use for this persistent volume (default: ext4)"

  default = "ext4"
}
