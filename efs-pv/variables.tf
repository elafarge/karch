variable "master-up" {
  type        = "string"
  description = "Dependency hook to be sure that the Kubernetes master is up"
}

variable "size" {
  type        = "string"
  description = "Size of the created Kubernetes persistent volume to create, in Gigabytes"
}

variable "efs-server-id" {
  type        = "string"
  description = "ID (fs-xxxxxxx) of the EFS server backing your Kubernetes persistent volume"
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
