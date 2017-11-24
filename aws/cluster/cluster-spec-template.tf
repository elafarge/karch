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

    # CPU and Memory reservation for system/orchestration processes (soft)
    kubelet-eviction-flag  = "${var.kubelet-eviction-flag}"
    kube-reserved-cpu      = "${var.kube-reserved-cpu}"
    kube-reserved-memory   = "${var.kube-reserved-memory}"
    system-reserved-cpu    = "${var.system-reserved-cpu}"
    system-reserved-memory = "${var.system-reserved-memory}"

    kops-authorization-mode      = "${var.rbac == "true" ? "rbac": "alwaysAllow"}"
    apiserver-authorization-mode = "${var.rbac == "true" ? "RBAC": "AlwaysAllow"}"
    rbac-super-user              = "${var.rbac == "true" ? "authorizationRbacSuperUser: ${var.rbac-super-user}" : ""}"

    apiserver-runtime-config      = "${join("\n", data.template_file.apiserver-runtime-configs.*.rendered)}"
    apiserver-rbac-runtime-config = "${var.rbac == "true" ? "rbac.authorization.k8s.io/v1alpha1: 'true'": ""}"

    oidc-config = "${join("\n", data.template_file.oidc-apiserver-conf.*.rendered)}"

    kubernetes-version = "${var.kubernetes-version}"
    vpc-cidr           = "${var.vpc-cidr-block}"
    vpc-id             = "${var.vpc-id}"
    trusted-cidrs      = "${join("\n", data.template_file.trusted-cidrs.*.rendered)}"
    subnets            = "${join("\n", data.template_file.subnets.*.rendered)}"
  }
}

data "template_file" "etcd-member" {
  count = "${length(var.master-availability-zones)}"

  template = <<EOF
    - encryptedVolume: true
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
    private-cidr = "${cidrsubnet(var.vpc-cidr-block, 8, count.index + 20)}"
    public-cidr  = "${cidrsubnet(var.vpc-cidr-block, 8, count.index + 30)}"
  }
}

data "template_file" "oidc-apiserver-conf" {
  count = "${var.oidc-issuer-url == "" ? 0 : 1}"

  template = <<EOF
    oidcCAFile: ${var.oidc-ca-file}
    oidcClientID: ${var.oidc-client-id}
    oidcGroupsClaim: ${var.oidc-groups-claim}
    oidcIssuerURL: ${var.oidc-issuer-url}
    oidcUsernameClaim: ${var.oidc-username-claim}
EOF
}

data "template_file" "apiserver-runtime-configs" {
  count = "${length(var.apiserver-runtime-flags)}"

  template = "      ${element(keys(var.apiserver-runtime-flags), count.index)}: '${element(values(var.apiserver-runtime-flags), count.index)}'"
}
