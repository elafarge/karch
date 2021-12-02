output "created" {
  value = null_resource.ig.id
}

// Name of the AWS autoscaling group corresponding to this kops instance group
output "asg-name" {
  value = data.aws_autoscaling_group.ig.name
}
