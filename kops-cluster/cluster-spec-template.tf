data "template_file" "cluster-spec" {
  template = "${file("${path.module}/templates/cluster-spec.yaml")}"

  vars {
    cluster-name       = "${aws_route53_record.cluster-root.name}"
    channel            = "${var.channel}"
    disable-sg-ingress = "${var.disable-sg-ingress}"
    cloud-labels       = "${join("\n", data.template_file.cloud-labels.*.rendered)}"
    kube-dns-domain    = "${var.kube-dns-domain}"
    kops-state-bucket  = "${var.kops-state-bucket}"

    etcd-clusters = <<EOF
  - etcdMembers:
${join("\n", data.template_file.etcd-member.*.rendered)}
    name: main
  - etcdMembers:
${join("\n", data.template_file.etcd-member.*.rendered)}
    name: events
EOF

    master-lb-visibility   = "${var.master-lb-visibility}"
    master-count           = "${length(var.master-availability-zones)}"
    master-lb-idle-timeout = "${var.master-lb-idle-timeout}"
    kubernetes-version     = "${var.kubernetes-version}"
    vpc-cidr               = "${aws_vpc.main.cidr_block}"
    vpc-id                 = "${aws_vpc.main.id}"
    trusted-cidrs          = "${join("\n", data.template_file.trusted-cidrs.*.rendered)}"
    subnets                = "${join("\n", data.template_file.subnets.*.rendered)}"
  }
}

data "template_file" "etcd-member" {
  count = "${length(var.master-availability-zones)}"

  template = <<EOF
    - entcryptedVolume: true
      instanceGroup: master-$${az}
      name: $${az}
EOF

  vars {
    az = "${element(var.master-availability-zones, count.index)}"
  }
}

data "template_file" "trusted-cidrs" {
  count = "${length(var.trusted-cidrs)}"

  template = <<EOF
  - $${cidr}
EOF

  vars {
    cidr = "${element(var.trusted-cidrs, count.index)}"
  }
}

data "template_file" "cloud-labels" {
  count = "${length(keys(var.cloud-labels))}"

  template = <<EOF
    $${tag}: '$${value}'
EOF

  vars {
    tag   = "${element(keys(var.cloud-labels), count.index)}"
    value = "${element(values(var.cloud-labels), count.index)}"
  }
}

data "template_file" "subnets" {
  count = "${length(var.availability-zones)}"

  template = <<EOF
  - cidr: $${private-cidr}
    name: $${az}
    type: Private
    zone: $${az}
  - cidr: $${public-cidr}
    name: utility-$${az}
    type: Utility
    zone: $${az}
EOF

  vars {
    az           = "${element(var.availability-zones, count.index)}"
    private-cidr = "${cidrsubnet(aws_vpc.main.cidr_block, 3, count.index+1)}"
    public-cidr  = "${cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)}"
  }
}
