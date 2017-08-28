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

Getting started
---------------
#### Requirements
You'll only need `kops`, `kubectl`, `sh`, `awk` and the `aws-cli` (or at
least, an AWS account configured `accordingly` under `~/.aws/credentials`).

#### Creating a Kubernetes cluster

#### Creating instance groups

#### Mainting your cluster
You can entirely rely on Terraform to update your cluster on `terraform apply`.
Please note that we never run `kops rolling-update` for cluster updates. You'll
need to run it manually. However, rolling updates can be automatically applied
for instance groups, with a configurable node rollout time interval.

TODO
----
 * Expose generated kops cluster variables, such as `kops` cluster domains, vpc
   IDs...

Maintainers
-----------
 * Étienne Lafarge <etienne.lafarge _at_ gmail.com>
