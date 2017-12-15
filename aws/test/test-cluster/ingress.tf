# Note: we should put the ingress controller on default nodes and deploy a single AZ database node group on which to
# spawn statefulsets (maybe an EFK monitoring stack ?) so that we can check the successful creation of stateful sets and
# - therefore - persistent volumes.
module "ingress-ig" {
  source = "../../ig"

  # Master cluster dependency hook
  master-up = "${module.kops-cluster.master-up}"

  # Global config
  name              = "ingress"
  cluster-name      = "${var.cluster-name}"
  kops-state-bucket = "${var.kops-state-bucket}"
  visibility        = "private"
  subnets           = ["${var.ingress-nodes-subnets}"]
  image             = "${var.base-ami}"
  type              = "${var.ingress-machine-type}"
  volume-size       = "30"
  volume-type       = "gp2"
  min-size          = "${var.ingress-min-nodes}"
  max-size          = "${var.ingress-max-nodes}"
  node-labels       = "${map("duty", "intake")}"

  #   hooks = [
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
