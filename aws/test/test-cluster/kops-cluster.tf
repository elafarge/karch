/*
 * Cluster configuration
 */
module "kops-cluster" {
  source = "../../cluster"

  aws-region = "${var.aws-region}"

  # Networking & connectivity
  vpc-name                  = "${var.vpc-name}"
  vpc-cidr                  = "${var.vpc-cidr}"
  availability-zones        = ["${var.availability-zones}"]
  kops-topology             = "private"
  trusted-cidrs             = "${var.trusted-cidrs}"
  admin-ssh-public-key-path = "${var.admin-ssh-public-key-path}"

  # DNS
  main-zone-id    = "${var.main-zone-id}"
  cluster-name    = "${var.cluster-name}"
  kube-dns-domain = "${var.kube-dns-domain}"

  # Kops & Kuberntetes
  kops-state-bucket  = "${var.kops-state-bucket}"
  disable-sg-ingress = "false"
  channel            = "${var.kops-channel}"
  kubernetes-version = "${var.kubernetes-version}"
  cloud-labels       = "${var.cloud-labels}"
  rbac               = "true"

  # Kubelet/Container Runtime & system resource reservations
  kube-reserved-cpu      = "100m"
  system-reserved-cpu    = "100m"
  kube-reserved-memory   = "256Mi"
  system-reserved-memory = "256Mi"

  # Master
  master-availability-zones = ["${var.master-availability-zones}"]
  master-lb-visibility      = "Public"
  master-lb-idle-timeout    = "1200"
  master-image              = "${var.base-ami}"
  master-machine-type       = "${var.master-machine-type}"
  master-volume-size        = "${var.master-volume-size}"
  master-volume-type        = "${var.master-volume-type}"

  # Bastion
  bastion-image        = "${var.base-ami}"
  bastion-machine-type = "t2.micro"
  bastion-volume-size  = "10"
  bastion-volume-type  = "gp2"

  # First minion instance group
  minion-ig-name      = "${var.cluster-base-minion-ig-name}"
  minion-ig-public    = "false"
  minion-image        = "${var.base-ami}"
  minion-machine-type = "${var.cluster-base-minion-machine-type}"
  minion-volume-size  = "30"
  minion-volume-type  = "gp2"
  min-minions         = "${var.cluster-base-minions-min}"
  max-minions         = "${var.cluster-base-minions-max}"
  minion-node-labels  = "${map("duty", "webserver")}"

  # Hooks enforced on all nodes
  hooks = [
    # Disable locksmith auto upgrades and reboots on all nodes
    <<EOF
  - name: locksmithd.service
    disabled: true
EOF
    ,

    <<EOF
  - name: disable-locksmithd.service
    before:
    - locksmithd.service
    manifest: |
      Type=oneshot
      ExecStart=/usr/bin/systemctl stop locksmithd.service
EOF
    ,
  ]

  #   minion-hooks = [
  #     <<EOF
  #   - name: tune-kernel.service
  #     manifest: |
  #       Type = oneshot
  # ${join("\n", data.template_file.webserver-sysctl-parameters.*.rendered)},
  #       ExecStart=/usr/bin/echo 'Kernel Configured'
  # EOF
  #     ,
  #   ]
}
