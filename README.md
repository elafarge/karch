karch - A terraform module to spawn Kubernetes clusters
=======================================================

`karch` is a Terraform module based on
[kops](https://github.com/kubernetes/kops) aiming at managing (multiple)
Kubernetes clusters on AWS. You can see it as "Terraform bindings for kops".

It essentially aims at making it easier to share Kubernetes cluster topologies
or even entire stacks built atop Kubernetes.

Motivations
-----------
`kops` has become the standard, non-opinionated way of deploying Kubernetes
clusters on AWS and can even generate Terraform code. However, this approach has
some limits:
 * Values of resources managed by `kops`, such as the id of the cluster's VPC,
   subnets, etc... aren't really accessible from the rest of your codebase.
 * One needs one subfolder per cluster (which can be used as a Terraform
   module): creating a "cluster template" (masters + several IGs) that can
   easily be replicated accross AWS regions & shared accross teams isn't
   possible

It seemed that wrapping by wrapping the `kops` CLI itself into a Terraform
module whicch really feels like a simple Terraform module could fulfill this
need for portable, reapeatable infrastructure a bit better. Of course, keeping
the flexibilty offered by `kops`'s cluster & instance group spec available by
exposing all the parameters it provides as Terraform variables felt essential.

Therfore, `karch` aims at making it easy to encode Kubernetes cluster topologies
using Terraform infrastructure code. For instance, such a topology could be:
 - an instance group for a pool of NginX ingress controllers, mounting ports
 - one for your backend APIs
 - one for stateful apps (databases, data stores...)
 - one, with GPU instances, to run your ML pipeline
 - with Kubernetes to orchestrate all types of workloads

What `karch` is
---------------
 * A Terraform library, written in plain HCL and using essentially `kops`, `sh`
   and `awk`.
 * A set of two Terraform modules `cluster` and `ig`. The former spaws a base
   cluster, in a new VPC, the latter can be used to spawn instance groups.
 * A wrapper around `kops`, instead of using `kops` directly, you'll be using
   a terraform module to create/update/delete your `kops` clusters. When
   necessary, this module will take care of rolling out your instance groups.

What `karch` isn't
------------------
 * A Terraform provider **plugin**. Writing such a plugin would be nice, but
   would require much more time to implement.
 * For now, `karch` spawns only clusters with a `private` topology. Adding the
   ability to create `public` clusters will come next
 * For now, `karch` takes care of creating a VPC and Route53 zone for your
   cluster's subdomain. Being able to give it an already existing VPC and/or
   zone is on the roadmap

Getting started
---------------
#### Requirements
You'll only need `kops`, `kubectl`, `sh`, and the `aws-cli` (or at
least, an AWS account configured `accordingly` under `~/.aws/credentials`).

#### Creating a Kubernetes cluster

To create a Kubernetes cluster, you can use the `kops-cluster` module:
You can refer to `./kops-cluster/variables.tf` for a documented list of all the
variables you can pass to the module.
```
module "kops-cluster" {
  source  = "github.com/elafarge/karch/aws/cluster"
  version = "1.7.1"

  aws-region              = "eu-west-1"

  # Networking & connectivity
  vpc-name                  = "kube-hq"
  vpc-cidr                  = "10.70.0.0/16"
  availability-zones        = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  kops-topology             = "private"
  trusted-cidrs             = "0.0.0.0/0"
  admin-ssh-public-key-path = "~/.ssh/id_rsa.pub"

  # DNS
  main-zone-id    = "example.com"
  cluster-name    = "kube-hq.example.com"

  # Kops & Kuberntetes
  kops-state-bucket  = "example-com-kops-state"

  # Master
  master-availability-zones = ["eu-west-1a"]
  master-image              = "ami-109d6069"

  # Bastion
  bastion-image        = "ami-109d6069"

  # First minion instance group
  minion-image        = "ami-109d6069"
}
```

#### Adding instance groups to the cluster

Here as well, it boils down to simply using a Terraform module. The list of
accepted variables can be found under `./kops-ig/variables.tf`.
```
module "ingress-ig" {
  source  = "github.com/elafarge/karch/aws/ig"
  version = "1.7.1"

  aws-region              = "eu-west-1"

  # Master cluster dependency hook
  master-up = "${module.kops-cluster.master-up}"

  # Global config
  name              = "ingress"
  cluster-name      = "kube-hq.example.com"
  kops-state-bucket = "example-com-kops-state"
  visibility        = "private"
  subnets           = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  image             = "ami-109d6069"
  type              = "t2.small"
  volume-size       = "16"
  volume-type       = "gp2"
  min-size          = 2
  max-size          = 3
  node-labels       = "${map("role.node", "ingress")}"
}
```

#### Mainting your cluster
You can entirely rely on Terraform to update your cluster on `terraform apply`.
Please note that we never run `kops rolling-update` for cluster updates. You'll
need to run it manually. However, rolling updates can be automatically applied
for instance groups, with a configurable node rollout time interval.

Maintainers
-----------
 * Étienne Lafarge <etienne.lafarge _at_ gmail.com>
