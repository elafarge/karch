data "template_file" "cluster-spec" {
  template = "${file("${path.module}/templates/cluster-spec.yaml")}"

  vars {
    # Generic cluster configuration
    cluster-name       = "${var.cluster-name}"
    kubernetes-version = "${var.kubernetes-version}"
    channel            = "${var.channel}"
    cloud-labels       = "${join("\n", data.template_file.cloud-labels.*.rendered)}"
    kube-dns-domain    = "${var.kube-dns-domain}"
    kops-state-bucket  = "${var.kops-state-bucket}"

    # Control plane HA mode and network exposure configuration
    master-lb-visibility     = "${var.master-lb-visibility == "Private" ? "Internal" : "Public"}"
    master-lb-dns-visibility = "${var.master-lb-visibility}"
    master-count             = "${length(var.master-availability-zones)}"
    master-lb-idle-timeout   = "${var.master-lb-idle-timeout}"

    # Cloud provider networking configuration
    vpc-cidr      = "${aws_vpc.main.cidr_block}"
    vpc-id        = "${aws_vpc.main.id}"
    trusted-cidrs = "${join("\n", data.template_file.trusted-cidrs.*.rendered)}"
    subnets       = "${join("\n", data.template_file.subnets.*.rendered)}"

    # DNS provider to use
    dns-provider = "${var.dns-provider}"

    # Kube proxy mode
    kube-proxy-mode = "${var.kube-proxy-mode}"

    # CNI plugin to use
    container-networking = "${var.container-networking}"
    networking-config    = "${data.template_file.networking-config.rendered}"

    # Extra systemd hooks for all nodes in our cluster
    hooks = "${join("\n", data.template_file.hooks.*.rendered)}"

    # ETCD cluster parameters
    etcd-clusters = <<EOF
  - etcdMembers:
${join("\n", data.template_file.etcd-member.*.rendered)}
    name: main
    enableEtcdTLS: ${var.etcd-enable-tls ? "true" : "false"}
    version: ${var.etcd-version}
  - etcdMembers:
${join("\n", data.template_file.etcd-member.*.rendered)}
    name: events
    enableEtcdTLS: ${var.etcd-enable-tls}
    version: ${var.etcd-version}
EOF

    # Kubelet configuration
    # CPU and Memory reservation for system/orchestration processes (soft)
    kubelet-eviction-flag = "${var.kubelet-eviction-flag}"

    kube-reserved-cpu      = "${var.kube-reserved-cpu}"
    kube-reserved-memory   = "${var.kube-reserved-memory}"
    system-reserved-cpu    = "${var.system-reserved-cpu}"
    system-reserved-memory = "${var.system-reserved-memory}"

    # APIServer configuration
    apiserver-storage-backend    = "etcd${substr(var.etcd-version, 0, 1)}"
    kops-authorization-mode      = "${var.rbac == "true" ? "rbac": "alwaysAllow"}"
    apiserver-authorization-mode = "${var.rbac == "true" ? "RBAC": "AlwaysAllow"}"

    apiserver-runtime-config = "${join("\n", data.template_file.apiserver-runtime-configs.*.rendered)}"
    oidc-config              = "${join("\n", data.template_file.oidc-apiserver-conf.*.rendered)}"

    # kube-controller-manager configuration
    hpa-sync-period      = "${var.hpa-sync-period}"
    hpa-scale-down-delay = "${var.hpa-scale-down-delay}"
    hpa-scale-up-delay   = "${var.hpa-scale-up-delay}"

    # Additional IAM policies for masters and nodes
    master-additional-policies = "${length(var.master-additional-policies) == 0 ? "" : format("master: |\n      %s", indent(6, var.master-additional-policies))}"
    node-additional-policies   = "${length(var.node-additional-policies) == 0 ? "" : format("node: |\n      %s", indent(6, var.node-additional-policies))}"

    # Log level for all master & kubelet components
    log-level = "${var.log-level}"

    # Should LoadBalancer service create their own security groups and add a rule in the "nodes" security group... or
    # should we rather leave the use configure one security group for all LoadBalancer services (and leave the nodes
    # security group alone !)
    disable-sg-ingress = "${var.disable-sg-ingress}"

    elb-security-group = "${var.lb-security-group == "" ? "" : "elbSecurityGroup: ${var.lb-security-group}"}"
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
    id: $${private-subnet-id}
    egress: $${nat-gateway-id}
  - cidr: $${public-cidr}
    name: utility-$${az}
    type: Utility
    zone: $${az}
    id: $${public-subnet-id}
EOF

  vars {
    az                = "${element(var.availability-zones, count.index)}"
    private-cidr      = "${element(aws_subnet.private.*.cidr_block, count.index)}"
    public-cidr       = "${element(aws_subnet.utility.*.cidr_block, count.index)}"
    public-subnet-id  = "${element(aws_subnet.utility.*.id, count.index)}"
    private-subnet-id = "${element(aws_subnet.private.*.id, count.index)}"
    nat-gateway-id    = "${element(aws_nat_gateway.natgw.*.id, count.index)}"
  }
}

data "template_file" "oidc-apiserver-conf" {
  count = "${var.oidc-issuer-url == "" ? 0 : 1}"

  template = <<EOF
    oidcIssuerURL: ${var.oidc-issuer-url}
    oidcClientID: ${var.oidc-client-id}
    oidcUsernameClaim: ${var.oidc-username-claim}

    ${var.oidc-ca-file == "" ? "" : "oidcCAFile: ${var.oidc-ca-file}"}
    ${var.oidc-groups-claim == "" ? "" : "oidcGroupsClaim: ${var.oidc-groups-claim}"}
EOF
}

data "template_file" "apiserver-runtime-configs" {
  count = "${length(var.apiserver-runtime-flags)}"

  template = "      ${element(keys(var.apiserver-runtime-flags), count.index)}: '${element(values(var.apiserver-runtime-flags), count.index)}'"
}

data "template_file" "hooks" {
  count = "${length(var.hooks)}"

  template = <<EOF
${element(var.hooks, count.index)}
EOF
}

data "template_file" "networking-config" {
  template = <<EOF
${
  var.container-networking == "calico" ?
  indent(6, "\ncrossSubnet: true\nprometheusMetricsEnabled: true \nprometheusGoMetricsEnabled: true\nprometheusProcessMetricsEnabled: true\nmajorVersion: v3\n")
  : ""
}
EOF
}
