data "template_file" "master-spec" {
  count    = "${length(var.master-availability-zones)}"
  template = "${file("${path.module}/templates/ig-spec.yaml")}"

  vars {
    cluster-name            = "${var.cluster-name}"
    cloud-labels            = "${join("\n", data.template_file.master-cloud-labels.*.rendered)}"
    node-labels             = "${join("\n", data.template_file.master-node-labels.*.rendered)}"
    name                    = "master-${element(var.master-availability-zones, count.index)}"
    public                  = "false"
    additional-sgs          = ""
    image                   = "${var.master-image}"
    type                    = "${var.master-machine-type}"
    max-size                = 1
    min-size                = 1
    role                    = "Master"
    volume-size             = "${var.master-volume-size}"
    volume-provisioned-iops = "${var.master-volume-provisioned-iops == "" ? "" : var.master-volume-provisioned-iops}"
    volume-type             = "${var.master-volume-type}"
    ebs-optimized           = "${var.master-ebs-optimized}"
    max-price               = ""
    taints                  = ""
    subnets                 = "  - ${element(var.master-availability-zones, count.index)}"
    hooks                   = "${join("\n", data.template_file.master-hooks.*.rendered)}"
  }
}

data "template_file" "master-cloud-labels" {
  count = "${length(keys(var.master-cloud-labels))}"

  template = <<EOF
    $${tag}: '$${value}'
EOF

  vars {
    tag   = "${element(keys(var.master-cloud-labels), count.index)}"
    value = "${element(values(var.master-cloud-labels), count.index)}"
  }
}

data "template_file" "master-node-labels" {
  count = "${length(keys(var.master-node-labels))}"

  template = <<EOF
    $${tag}: '$${value}'
EOF

  vars {
    tag   = "${element(keys(var.master-node-labels), count.index)}"
    value = "${element(values(var.master-node-labels), count.index)}"
  }
}

data "template_file" "master-hooks" {
  count = "${length(var.master-hooks)}"

  template = <<EOF
${element(var.master-hooks, count.index)}
EOF
}

data "template_file" "bastion-spec" {
  count    = "${var.kops-topology == "private" ? 1 : 0}"
  template = "${file("${path.module}/templates/ig-spec.yaml")}"

  vars {
    cluster-name = "${var.cluster-name}"
    cloud-labels = "${join("\n", data.template_file.bastion-cloud-labels.*.rendered)}"
    node-labels  = "${join("\n", data.template_file.bastion-node-labels.*.rendered)}"
    name         = "bastions"
    public       = "false"

    additional-sgs = <<EOF
  ${length(var.bastion-additional-sgs) > 0 ? "additionalSecurityGroups:" : ""}
  ${join("\n", data.template_file.bastion-additional-sgs.*.rendered)}
EOF

    image                   = "${var.bastion-image}"
    type                    = "${var.bastion-machine-type}"
    max-size                = "${var.max-bastions}"
    min-size                = "${var.min-bastions}"
    role                    = "Bastion"
    volume-size             = "${var.bastion-volume-size}"
    volume-provisioned-iops = "${var.bastion-volume-provisioned-iops == "" ? "" : var.bastion-volume-provisioned-iops}"
    volume-type             = "${var.bastion-volume-type}"
    ebs-optimized           = "${var.bastion-ebs-optimized}"
    max-price               = ""
    taints                  = ""
    subnets                 = "${join("\n", data.template_file.minion-subnets.*.rendered)}"
    hooks                   = "${join("\n", data.template_file.bastion-hooks.*.rendered)}"
  }
}

data "template_file" "bastion-additional-sgs" {
  count = "${var.bastion-additional-sgs-count}"

  template = "  - $${sg-id}"

  vars {
    sg-id = "${element(var.bastion-additional-sgs, count.index)}"
  }
}

data "template_file" "bastion-cloud-labels" {
  count = "${length(keys(var.bastion-cloud-labels))}"

  template = <<EOF
    $${tag}: '$${value}'
EOF

  vars {
    tag   = "${element(keys(var.bastion-cloud-labels), count.index)}"
    value = "${element(values(var.bastion-cloud-labels), count.index)}"
  }
}

data "template_file" "bastion-node-labels" {
  count = "${length(keys(var.bastion-node-labels))}"

  template = <<EOF
    $${tag}: '$${value}'
EOF

  vars {
    tag   = "${element(keys(var.bastion-node-labels), count.index)}"
    value = "${element(values(var.bastion-node-labels), count.index)}"
  }
}

data "template_file" "bastion-hooks" {
  count = "${length(var.bastion-hooks)}"

  template = <<EOF
${element(var.bastion-hooks, count.index)}
EOF
}

data "template_file" "minion-spec" {
  template = "${file("${path.module}/templates/ig-spec.yaml")}"

  vars {
    cluster-name = "${var.cluster-name}"
    cloud-labels = "${join("\n", data.template_file.minion-cloud-labels.*.rendered)}"
    node-labels  = "${join("\n", data.template_file.minion-node-labels.*.rendered)}"
    name         = "${var.minion-ig-name}"
    public       = "${var.minion-ig-public}"

    additional-sgs = <<EOF
  ${length(var.minion-additional-sgs) > 0 ? "additionalSecurityGroups:" : ""}
  ${join("\n", data.template_file.minion-additional-sgs.*.rendered)}
EOF

    image                   = "${var.minion-image}"
    type                    = "${var.minion-machine-type}"
    max-size                = "${var.max-minions}"
    min-size                = "${var.min-minions}"
    role                    = "Node"
    volume-size             = "${var.minion-volume-size}"
    volume-provisioned-iops = "${var.minion-volume-provisioned-iops == "" ? "" : var.minion-volume-provisioned-iops}"
    volume-type             = "${var.minion-volume-type}"
    ebs-optimized           = "${var.minion-ebs-optimized}"
    max-price               = ""
    taints                  = "${join("\n", data.template_file.minion-taints.*.rendered)}"
    subnets                 = "${join("\n", data.template_file.minion-subnets.*.rendered)}"
    hooks                   = "${join("\n", data.template_file.minion-hooks.*.rendered)}"
  }
}

data "template_file" "minion-taints" {
  count = "${length(var.minion-taints)}"

  template = "  - ${element(var.minion-taints, count.index)}"
}

data "template_file" "minion-subnets" {
  count    = "${length(var.availability-zones)}"
  template = "  - $${az}"

  vars {
    az = "${element(var.availability-zones, count.index)}"
  }
}

data "template_file" "minion-additional-sgs" {
  count = "${var.minion-additional-sgs-count}"

  template = "  - $${sg-id}"

  vars {
    sg-id = "${element(var.minion-additional-sgs, count.index)}"
  }
}

data "template_file" "minion-cloud-labels" {
  count = "${length(keys(var.minion-cloud-labels))}"

  template = <<EOF
    $${tag}: '$${value}'
EOF

  vars {
    tag   = "${element(keys(var.minion-cloud-labels), count.index)}"
    value = "${element(values(var.minion-cloud-labels), count.index)}"
  }
}

data "template_file" "minion-node-labels" {
  count = "${length(keys(var.minion-node-labels))}"

  template = <<EOF
    $${tag}: '$${value}'
EOF

  vars {
    tag   = "${element(keys(var.minion-node-labels), count.index)}"
    value = "${element(values(var.minion-node-labels), count.index)}"
  }
}

data "template_file" "minion-hooks" {
  count = "${length(var.minion-hooks)}"

  template = <<EOF
${element(var.minion-hooks, count.index)}
EOF
}
