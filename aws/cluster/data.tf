data "aws_security_group" "bastion" {
  vpc_id = var.vpc-networking["vpc-id"]

  filter {
    name = "tag:Name"

    // The second value is just a hacky dependency hooks on our cluster being created
    values = [
      "bastion.${var.cluster-name}",
      null_resource.kops-cluster.id,
    ]
  }
}

data "aws_security_group" "nodes" {
  vpc_id = var.vpc-networking["vpc-id"]

  filter {
    name = "tag:Name"

    // The second value is just a hacky dependency hooks on our cluster being created
    values = [
      "nodes.${var.cluster-name}",
      null_resource.kops-cluster.id,
    ]
  }
}

data "aws_security_group" "masters" {
  vpc_id = var.vpc-networking["vpc-id"]

  filter {
    name = "tag:Name"

    // The second value is just a hacky dependency hooks on our cluster being created
    values = [
      "masters.${var.cluster-name}",
      null_resource.kops-cluster.id,
    ]
  }
}

data "aws_ebs_volume" "etcd-volumes" {
  count = length(var.availability-zones)

  filter {
    name = "tag:Name"

    values = [
      "${element(var.availability-zones, count.index)}.etcd-main.${var.cluster-name}",
      null_resource.kops-cluster.id,
    ]
  }
}

data "aws_ebs_volume" "etcd-event-volumes" {
  count = length(var.availability-zones)

  filter {
    name = "tag:Name"

    values = [
      "${element(var.availability-zones, count.index)}.etcd-events.${var.cluster-name}",
      null_resource.kops-cluster.id,
    ]
  }
}
