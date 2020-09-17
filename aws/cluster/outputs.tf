# Lifecycle hooks
output "master-up" {
  value = null_resource.master-up.id
}

output "cluster-created" {
  value = null_resource.kops-cluster.id
}

# DNS zone for the cluster subdomain
output "cluster-zone-id" {
  value = aws_route53_zone.cluster.id
}

output "route53-cluster-zone-id" {
  value = aws_route53_zone.cluster.id
}

output "vpc-id" {
  value = var.vpc-networking["vpc-id"]
}

// Nodes security groups (to direct ELB traffic to hostPort pods)
output "nodes-sg" {
  value = element(split("/", data.aws_security_group.nodes.arn), 1)
}

output "masters-sg" {
  value = element(split("/", data.aws_security_group.masters.arn), 1)
}

output "etcd-volume-ids" {
  value = data.aws_ebs_volume.etcd-volumes.*.id
}

output "etcd-event-volume-ids" {
  value = data.aws_ebs_volume.etcd-event-volumes.*.id
}
