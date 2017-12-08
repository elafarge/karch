module "test-cluster" {
  source = "./test-cluster"

  aws-region = "${data.aws_region.main.name}"

  kubernetes-version = "${var.kubernetes-version}"

  # Networking
  vpc-name                  = "karch-test-1"
  vpc-number                = 0
  availability-zones        = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  trusted-cidrs             = ["0.0.0.0/0"]
  admin-ssh-public-key-path = "~/.ssh/terraform.pub"

  # DNS
  main-zone-id    = "${data.aws_route53_zone.test.id}"
  cluster-name    = "test.${var.domain}"
  kube-dns-domain = "cluster.karch-test-1"

  # Kops & Kuberntetes
  kops-state-bucket = "${var.kops-state-bucket}"
  cloud-labels      = "${map("karch-test", "true")}"
  base-ami          = "${data.aws_ami.coreos-stable.id}"

  # Master
  master-availability-zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  master-machine-type       = "m4.large"
  master-volume-size        = "30"
  master-volume-type        = "gp2"

  # First minion instance group (HTTP webservers of all types + kube-system pods)
  cluster-base-minion-ig-name      = "default"
  cluster-base-minion-machine-type = "t2.medium"
  cluster-base-minions-min         = 1
  cluster-base-minions-max         = 15

  # Ingress nodes
  ingress-nodes-subnets = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}
