data "template_file" "cluster-spec" {
  template = "${file("${path.module}/templates/cluster-spec.yaml")}"

  vars {
    # Generic cluster configuration
    cluster-name       = "${aws_route53_record.cluster-root.name}"
    channel            = "${var.channel}"
    disable-sg-ingress = "${var.disable-sg-ingress}"
    cloud-labels       = "${join("\n", data.template_file.cloud-labels.*.rendered)}"
    kube-dns-domain    = "${var.kube-dns-domain}"
    kube-dns-provider  = "${var.kube-dns-provider}"
    kops-state-bucket  = "${var.kops-state-bucket}"

    master-lb-visibility     = "${var.master-lb-visibility == "Private" ? "Internal" : "Public"}"
    master-lb-dns-visibility = "${var.master-lb-visibility}"
    master-count             = "${length(var.master-availability-zones)}"
    master-lb-idle-timeout   = "${var.master-lb-idle-timeout}"

    kubernetes-version                = "${var.kubernetes-version}"
    vpc-cidr                          = "${var.vpc-cidr-block}"
    vpc-id                            = "${var.vpc-id}"
    trusted-cidrs                     = "${join("\n", data.template_file.trusted-cidrs.*.rendered)}"
    subnets                           = "${join("\n", data.template_file.subnets.*.rendered)}"
    container-networking              = "${var.container-networking}"
    container-networking-params-empty = "${length(keys(var.container-networking-params)) == 0 ? "{}" : ""}"
    container-networking-params       = "${join("\n", data.template_file.container-networking-params.*.rendered)}"

    hooks = "${join("\n", data.template_file.hooks.*.rendered)}"

    # ETCD cluster parameters
    etcd-clusters = <<EOF
  - etcdMembers:
${join("\n", data.template_file.etcd-member.*.rendered)}
    name: main
    enableEtcdTLS: ${var.etcd-enable-tls}
    version: ${var.etcd-version}
    provider: ${var.etcd-mode}
${join("\n", data.template_file.backup-main.*.rendered)}
  - etcdMembers:
${join("\n", data.template_file.etcd-member.*.rendered)}
    name: events
    enableEtcdTLS: ${var.etcd-enable-tls}
    version: ${var.etcd-version}
    provider: ${var.etcd-mode}
${join("\n", data.template_file.backup-events.*.rendered)}
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
    featuregates-config      = "${join("\n", data.template_file.featuregates-configs.*.rendered)}"
    oidc-config              = "${join("\n", data.template_file.oidc-apiserver-conf.*.rendered)}"

    # kube-controller-manager configuration
    hpa-sync-period                     = "${var.hpa-sync-period}"
    hpa-scale-downscale-stabilization   = "${var.hpa-scale-downscale-stabilization}"

    # Additional IAM policies for masters and nodes
    master-additional-policies = "${length(var.master-additional-policies) == 0 ? "" : format("master: |\n      %s", indent(6, var.master-additional-policies))}"
    node-additional-policies   = "${length(var.node-additional-policies) == 0 ? "" : format("node: |\n      %s", indent(6, var.node-additional-policies))}"

    # Log level for all master & kubelet components
    log-level = "${var.log-level}"

    # Set cpuCFSQuota and cpuCFSQuotaPeriod to improve
    kubernetes-worker-cpu-cfs-quota-enabled = "${var.kubernetes-worker-cpu-cfs-quota-enabled}"
    kubernetes-worker-cpu-cfs-quota-period  = "${var.kubernetes-worker-cpu-cfs-quota-period}"
    kubernetes-master-cpu-cfs-quota-enabled = "${var.kubernetes-master-cpu-cfs-quota-enabled}"
    kubernetes-master-cpu-cfs-quota-period  = "${var.kubernetes-master-cpu-cfs-quota-period}"
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

data "template_file" "backup-main" {
  count = "${var.etcd-backup-enabled ? 1 : 0}"

  template = <<EOF
    backups:
      backupStore: s3://${var.etcd-backup-s3-bucket == "" ? var.kops-state-bucket : var.etcd-backup-s3-bucket}/${var.cluster-name}/backups/etcd/main/
EOF
}

data "template_file" "backup-events" {
  count = "${var.etcd-backup-enabled ? 1 : 0}"

  template = <<EOF
    backups:
      backupStore: s3://${var.etcd-backup-s3-bucket == "" ? var.kops-state-bucket : var.etcd-backup-s3-bucket}/${var.cluster-name}/backups/etcd/events/
EOF
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
    private-cidr      = "${element(var.vpc-private-cidrs, count.index)}"
    public-cidr       = "${element(var.vpc-public-cidrs, count.index)}"
    public-subnet-id  = "${element(var.vpc-public-subnet-ids, count.index)}"
    private-subnet-id = "${element(var.vpc-private-subnet-ids, count.index)}"
    nat-gateway-id    = "${element(var.nat-gateways, count.index)}"
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

data "template_file" "featuregates-configs" {
  count = "${length(var.featuregates-flags)}"

  template = "      ${element(keys(var.featuregates-flags), count.index)}: '${element(values(var.featuregates-flags), count.index)}'"
}

data "template_file" "hooks" {
  count = "${length(var.hooks)}"

  template = <<EOF
${element(var.hooks, count.index)}
EOF
}

data "template_file" "container-networking-params" {
  count = "${length(keys(var.container-networking-params))}"

  template = <<EOF
      $${tag}: $${value}
EOF

  vars {
    tag   = "${element(keys(var.container-networking-params), count.index)}"
    value = "${element(values(var.container-networking-params), count.index)}"
  }
}
