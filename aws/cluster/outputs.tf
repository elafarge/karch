# Lifecycle hooks
output "cluster-created" {
  value = null_resource.kops-cluster.id
}

output "cluster-spec" {
  value = aws_s3_bucket_object.cluster-spec.content
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
  value = data.aws_security_group.nodes.id
}

output "masters-sg" {
  value = data.aws_security_group.masters.id
}

output "bastion-sg" {
  value = data.aws_security_group.bastion.id
}

output "etcd-volume-ids" {
  value = data.aws_ebs_volume.etcd-volumes.*.id
}

output "etcd-event-volume-ids" {
  value = data.aws_ebs_volume.etcd-event-volumes.*.id
}
