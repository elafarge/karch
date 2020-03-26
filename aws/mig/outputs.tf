output "created" {
  value = "${null_resource.ig.id}"
}

// ID of the AWS autoscaling group corresponding to this kops instance group
output "asg-name" {
  value = "${element(data.aws_autoscaling_groups.ig.names, 0)}"
}
