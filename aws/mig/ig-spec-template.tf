data "template_file" "ig-spec" {
  template = file("${path.module}/templates/spec.yaml")

  vars = {
    cluster-name = var.cluster-name
    cloud-labels = join("\n", data.template_file.cloud-labels.*.rendered)
    node-labels  = join("\n", data.template_file.node-labels.*.rendered)
    name         = var.name
    public       = var.visibility == "public" ? "true" : "false"

    additional-sgs = <<EOF
  ${length(var.additional-sgs) > 0 ? "additionalSecurityGroups:" : ""}
  ${join("\n", data.template_file.additional-sgs.*.rendered)}
EOF

    image                               = var.image
    type                                = var.type
    max-size                            = var.max-size
    min-size                            = var.min-size
    role                                = "Node"
    volume-size                         = var.volume-size
    volume-provisioned-iops             = var.volume-provisioned-iops == "" ? "" : var.volume-provisioned-iops
    volume-type                         = var.volume-type
    ebs-optimized                       = var.ebs-optimized
    taints                              = join("\n", data.template_file.taints.*.rendered)
    subnets                             = join("\n", data.template_file.subnets.*.rendered)
    hooks                               = join("\n", data.template_file.hooks.*.rendered)
    additional_types                    = join("\n", data.template_file.policy-instances.*.rendered)
    policy_ondemand_base                = var.policy_ondemand_base
    policy_ondemand_above_base          = var.policy_ondemand_above_base
    policy_ondemand_allocation_strategy = var.policy_ondemand_allocation_strategy
    policy_spot_instance_pools          = var.policy_spot_instance_pools
    policy_spot_allocation_strategy     = var.policy_spot_allocation_strategy
  }
}

data "template_file" "additional-sgs" {
  count = var.additional-sgs-count

  template = "  - $${sg-id}"

  vars = {
    sg-id = element(var.additional-sgs, count.index)
  }
}

data "template_file" "cloud-labels" {
  count = length(keys(var.cloud-labels))

  template = <<EOF
    $${tag}: '$${value}'
EOF

  vars = {
    tag   = element(keys(var.cloud-labels), count.index)
    value = element(values(var.cloud-labels), count.index)
  }
}

data "template_file" "node-labels" {
  count = length(keys(var.node-labels))

  template = <<EOF
    $${tag}: '$${value}'
EOF

  vars = {
    tag   = element(keys(var.node-labels), count.index)
    value = element(values(var.node-labels), count.index)
  }
}

data "template_file" "taints" {
  count = length(var.taints)

  template = <<EOF
  - $${taint}
EOF

  vars = {
    taint = element(var.taints, count.index)
  }
}

data "template_file" "subnets" {
  count = length(var.subnets)

  template = <<EOF
  - $${subnet}
EOF

  vars = {
    subnet = element(var.subnets, count.index)
  }
}

data "template_file" "hooks" {
  count = length(var.hooks)

  template = <<EOF
${element(var.hooks, count.index)}
EOF
}

data "template_file" "policy-instances" {
  count = length(var.additional_types)

  template = "    - $${type}"

  vars = {
    type = element(var.additional_types, count.index)
  }
}
