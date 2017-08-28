data "template_file" "ig-spec" {
  template = "${file("${path.module}/templates/spec.yaml")}"

  vars {
    cluster-name            = "${var.cluster-name}"
    cloud-labels            = "${join("\n", data.template_file.cloud-labels.*.rendered)}"
    node-labels             = "${join("\n", data.template_file.node-labels.*.rendered)}"
    name                    = "${var.name}"
    public                  = "${var.visibility == "public" ? "true" : "false"}"
    image                   = "${var.image}"
    type                    = "${var.type}"
    max-size                = "${var.max-size}"
    min-size                = "${var.min-size}"
    role                    = "Node"
    volume-size             = "${var.volume-size}"
    volume-provisioned-iops = "${var.volume-provisioned-iops == "" ? "" : var.volume-provisioned-iops}"
    volume-type             = "${var.volume-type}"
    ebs-optimized           = "${var.ebs-optimized}"
    max-price               = "maxPrice: '${var.max-price}'"
    taints                  = "${join("\n", data.template_file.taints.*.rendered)}"
    subnets                 = "${join("\n", data.template_file.subnets.*.rendered)}"
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

data "template_file" "node-labels" {
  count = "${length(keys(var.node-labels))}"

  template = <<EOF
    $${tag}: '$${value}'
EOF

  vars {
    tag   = "${element(keys(var.node-labels), count.index)}"
    value = "${element(values(var.node-labels), count.index)}"
  }
}

data "template_file" "taints" {
  count = "${length(var.taints)}"

  template = <<EOF
  - $${taint}
EOF

  vars {
    taint = "${element(var.taints, count.index)}"
  }
}

data "template_file" "subnets" {
  count = "${length(var.subnets)}"

  template = <<EOF
  - $${subnet}
EOF

  vars {
    subnet = "${element(var.subnets, count.index)}"
  }
}
