data "aws_autoscaling_groups" "ig" {
  filter {
    name = "auto-scaling-group"

    // The second value simply is a way to make sure this data source will
    // only be provisioned once these subnets have been created by kops
    values = ["${var.name}.${var.cluster-name}", null_resource.ig-update.id]
  }
}
