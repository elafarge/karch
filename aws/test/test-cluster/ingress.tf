resource "aws_security_group" "ingress" {
  name        = "https"
  description = "[Managed by Terraform] Opens up ports 80, 443"
  vpc_id      = "${module.kops-cluster.vpc-id}"

  # HTTPs
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "ingress" {
  cross_zone_load_balancing   = true
  name                        = "ingress-${var.vpc-name}"
  security_groups             = ["${aws_security_group.ingress.id}", "${module.kops-cluster.nodes-sg}"]
  subnets                     = ["${module.kops-cluster.utility-subnets}"]
  internal                    = false
  idle_timeout                = 600
  connection_draining         = "true"
  connection_draining_timeout = "300"

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 80
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    target              = "TCP:80"
    interval            = 10
  }
}

# NOTE: with the new AWS network ELB, we shouldn't need that any more... should be investigated
resource "aws_proxy_protocol_policy" "ingress" {
  load_balancer  = "${aws_elb.ingress.name}"
  instance_ports = ["80", "443"]
}

# And instances backing the pure TCP proxy protocoled ELB
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
}

# Let's attach our instance group to the ingress ELB once it is created
resource "aws_autoscaling_attachment" "ingress_lb_attachment" {
  autoscaling_group_name = "${module.ingress-ig.asg-name}"
  elb                    = "${aws_elb.ingress.id}"
}
