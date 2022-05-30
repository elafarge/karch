variable "aws-region" {
  description = "The AWS region in which to deploy your cluster & VPC."
  type        = string
}

# Networking & Security
variable "vpc-networking" {
  type = object(
    {
      vpc-id                 = string
      vpc-cidr-block         = string
      nat-gateways           = list(string)
      vpc-public-subnet-ids  = list(string)
      vpc-private-subnet-ids = list(string)
      vpc-private-cidrs      = list(string)
      vpc-public-cidrs       = list(string)
    }
  )
}

variable "extra-subnets" {
  type = list(object({
    cidr   = string
    name   = string
    type   = string
    zone   = string
    id     = string
    egress = string
  }))
  default = []
}

variable "additional-network-cidrs" {
  type        = set(string)
  description = "Additional CIDRs defined for VPC"
}

variable "availability-zones" {
  type        = list(string)
  description = "Availability zones to span (for HA master deployments, see master-availability-zones)"
}

variable "kops-topology" {
  type        = string
  description = "Kops topolopy (public|private), (default: private)"
  default     = "private"
}

variable "api-cidrs" {
  type        = list(string)
  description = "CIDR whitelist for Kubernetes master HTTPs access (default: 0.0.0.0/0)"

  default = ["0.0.0.0/0"]
}

variable "ssh-cidrs" {
  type        = list(string)
  description = "CIDR whitelist for bastion SSH access (default: 0.0.0.0/0)"

  default = ["0.0.0.0/0"]
}

variable "admin-ssh-public-key-path" {
  type        = string
  description = "Path to the cluster admin's public SSH key (default: ~/.ssh/id_rsa.pub)"

  default = "~/.ssh/id_rsa.pub"
}

## DNS
variable "main-zone-id" {
  description = "Route53 main zone ID (optional if the cluster zone is private)"
  type        = string

  default = ""
}

variable "cluster-name" {
  description = "Cluster domain name (i.e. mycluster.example.com)"
  type        = string
}

variable "kube-dns" {
  type = object({
    domain    = string
    provider  = string
    server-ip = string
  })
  default = {
    domain    = "cluster.local"
    provider  = "CoreDNS"
    server-ip = "100.64.0.10"
  }
}

# kube-proxy
variable "kube-proxy-params" {
  type = object({
    clusterCIDR      = string
    cpuRequest       = string
    hostnameOverride = string
  })
  default = {
    clusterCIDR      = "100.96.0.0/11"
    cpuRequest       = "100m"
    hostnameOverride = "@aws"
  }
}

variable "kube-proxy-enabled" {
  type    = bool
  default = false
}

# https://kops.sigs.k8s.io/addons/#node-local-dns-cache
# Available since kops 1.18, K8s 1.15
variable "node-local-dns-cache" {
  type = object({
    enabled = bool
    localIP = string
    resources = object({
      requests = object({
        cpu    = string
        memory = string
      })
    })
  })
  default = {
    enabled = true
    resources = {
      requests = {
        cpu    = "25m"
        memory = "5Mi"
      }
    }
  }
}

variable "coredns" {
  type = object({
    corefile = string
  })
  default = {
    corefile = null
  }
}

# Kops & Kubernetes
variable "nodeup-url-env" {
  type        = string
  description = "NODEUP_URL env. variable override for testing custom builds of nodeup"

  default = ""
}

variable "aws-profile" {
  type        = string
  description = "Name of the AWS profile in ~/.aws/credentials or ~/.aws/config to use"

  default = "default"
}

variable "kops-state-bucket" {
  type        = string
  description = "Name of the bucket in which kops stores its state (must be created prior to cluster turnup)"
}

# https://github.com/kubernetes/kops/blob/1ae09e86a5e48e16cb885b8d001023cd1894d59e/docs/addons.md
# https://github.com/kubernetes/kops/issues/3554#issuecomment-658694934
# Example:
# {
#   kube-router = {
#     "1.0" = {
#       manifest = "..."
#       kubernetes-version = "<=0.6"
#     }
#     "2.0" = {
#       manifest = "..."
#       kubernetes-version = ">0.6"
#     }
#   }
# }
variable "kops-static-addons" {
  type = map(map(object({
    kubernetes-version = string
    manifest           = string
  })))
  description = "Map of addon manifests (kubernetes charts to be deployed to the cluster by protokube). Not to be mistaken for managed addons like cert-manager."

  default = {}
}

variable "disable-sg-ingress" {
  type        = bool
  description = "Boolean that indicates whether or not to create and attach a security group to instance nodes and load balancers for each LoadBalancer service (default: false)"

  default = false
}

variable "etcd-backup-enabled" {
  type        = bool
  description = "Set to true to enable backup to S3 on etcd containers (default: false)"

  default = false
}

variable "etcd-backup-s3-bucket" {
  type        = string
  description = "S3 bucket to use to store etcd backups assuming etcd-backup-enabled has been set to true"

  default = ""
}

variable "etcd-mode" {
  type        = string
  description = "Set this to Manager if your want to manage your etcd cluster using etcd-manager, and to Legacy to enable the legacy etcd provider"

  default = "Manager"
}

variable "container-networking" {
  type        = string
  description = "Set the container CNI networking layer (https://github.com/kubernetes/kops/blob/master/docs/networking.md)"

  default = "kuberouter"
}

variable "container-networking-params-amazonvpc" {
  type = object({
    env = list(object({
      name  = string
      value = string
    }))
  })
  description = "AmazonVPC CNI params"

  default = {
    env = []
  }
}

variable "container-networking-params-calico" {
  type = object({
    crossSubnet                     = bool
    bpfEnabled                      = bool
    bpfExternalServiceMode          = string
    bpfLogLevel                     = string
    encapsulationMode               = string
    mtu                             = number
    typhaReplicas                   = number
    wireguardEnabled                = bool
    logSeverityScreen               = string
    prometheusMetricsEnabled        = bool
    prometheusGoMetricsEnabled      = bool
    prometheusProcessMetricsEnabled = bool
    prometheusMetricsPort           = number
    typhaPrometheusMetricsEnabled   = bool
    typhaPrometheusMetricsPort      = number
  })
  description = "Calico CNI params"

  default = {
    crossSubnet                     = true
    bpfEnabled                      = false
    bpfExternalServiceMode          = "Tunnel"
    bpfLogLevel                     = "Off"
    encapsulationMode               = "ipip"
    mtu                             = 8981
    typhaReplicas                   = 3
    wireguardEnabled                = false
    logSeverityScreen               = "error"
    prometheusMetricsEnabled        = false
    prometheusGoMetricsEnabled      = false
    prometheusProcessMetricsEnabled = false
    prometheusMetricsPort           = 9091
    typhaPrometheusMetricsEnabled   = false
    typhaPrometheusMetricsPort      = 9093
  }
}

variable "container-networking-params-cilium" {
  type = object({
    disableMasquerade = bool
    enableEncryption  = bool
    enableNodePort    = bool
    etcdManaged       = bool
    ipam              = string
  })
  description = "Cilium CNI params"

  default = {
    disableMasquerade = false
    enableEncryption  = false
    enableNodePort    = false
    etcdManaged       = false
    ipam              = null
  }
}

variable "container-networking-params-flannel" {
  type = object({
    iptablesResyncSeconds = number
  })
  description = "Flannel CNI params"

  default = {
    iptablesResyncSeconds = 360
  }
}

variable "container-networking-params-kuberouter" {
  type        = map(string)
  description = "Kuberouter CNI params"

  default = {}
}

variable "rbac" {
  type        = bool
  description = "Boolean indicating whether to enable RBAC authorization (default: false)"

  default = false
}

variable "apiserver-runtime-flags" {
  type        = map(string)
  description = "Map describing the --runtime-config parameter passed to the API server, useful to enable certain alphav2 APIs that aren't integrated in the API server by default, such a batch/v1alpha2 that introduces CronJobs (default: {}). Note: the RBAC flag is automatically set if you enabled RBAC with the 'rbac' variable above"

  default = {}
}

variable "featuregates-flags" {
  type        = map(string)
  description = "Map describing the --feature-gates parameter passed to the API server, useful to enable certain alphav2 APIs that aren't integrated in the API server by default, such a batch/v1alpha2 that introduces CronJobs (default: {}). Note: the RBAC flag is automatically set if you enabled RBAC with the 'rbac' variable above"

  default = {
    ExpandPersistentVolumes = true
    PodPriority             = true
  }
}

variable "enable-admission-plugins" {
  type        = list(string)
  description = "List of enabled admission plugins"

  default = [
    "DefaultStorageClass",
    "DefaultTolerationSeconds",
    "DenyEscalatingExec",
    "LimitRanger",
    "MutatingAdmissionWebhook",
    "NamespaceLifecycle",
    "NodeRestriction",
    "PersistentVolumeClaimResize",
    "PersistentVolumeLabel",
    "PodSecurityPolicy",
    "Priority",
    "ResourceQuota",
    "ServiceAccount",
    "ValidatingAdmissionWebhook",
  ]
}

variable "hpa-sync-period" {
  type        = string
  description = "The frequency at which HPA are evaluated and reconciled"

  default = "30s"
}

variable "hpa-scale-downscale-stabilization" {
  type        = string
  description = "After an downscale, wait at least for this duration before the next downscale"

  default = "5m"
}

variable "oidc-issuer-url" {
  type        = string
  description = "Setting this to an OIDC Issuer URL will enable OpenID auth with the configured provider"

  default = ""
}

variable "oidc-ca-file" {
  type        = string
  description = "If using OpendID Connect, the oidc CA file on the APIServer pod"

  default = "/srv/kubernetes/ca.crt"
}

variable "oidc-client-id" {
  type        = string
  description = "If using OpendID Connect, the oidc client ID"

  default = "example-app"
}

variable "oidc-username-claim" {
  type        = string
  description = "If using OpendID Connect, the oidc username claim"

  default = "email"
}

variable "oidc-groups-claim" {
  type        = string
  description = "If using OpendID Connect, the oidc group claim"

  default = "groups"
}

variable "channel" {
  type        = string
  description = "Channel to use for our Kops cluster (default stable)"
  default     = "stable"
}

variable "kubernetes-version" {
  type        = string
  description = "Kubernetes version to use for Core components (default: 1.15.12)"
  default     = "1.15.12"
}

variable "cloud-labels" {
  type        = map(string)
  description = "(Flat) map of kops cloud labels to apply to all resources in cluster"

  default = {}
}

variable "controller-manager-kube-api-qps" {
  default     = 20
  description = "Limit of queries per second to use when Kube Controller Manager is talking to Kubernetes API server."
}

variable "controller-manager-kube-api-burst" {
  default     = 30
  description = "Allowed burst in queries per second to use when Kube Controller Manager is talking to Kubernetes API server."
}

# Resource reservation on our nodes for Kubernetes daemons & the OS
variable "kubelet-eviction-flag" {
  type        = string
  description = "Kubelet flag that configure node memory/storage pod eviction threshold"

  default = "memory.available<100Mi,nodefs.available<10%,nodefs.inodesFree<5%,imagefs.available<10%,imagefs.inodesFree<5%"
}

variable "kube-reserved-cpu" {
  type        = string
  description = "Amount of CPU reserved for the container runtime & kubelet (default: 50m)"

  default = "50m"
}

variable "kube-reserved-memory" {
  type        = string
  description = "Amount of CPU reserved for the container runtime & kubelet (default: 256Mi)"

  default = "256Mi"
}

variable "system-reserved-cpu" {
  type        = string
  description = "Amount of CPU reserved for the operating system (default: 50m)"

  default = "50m"
}

variable "system-reserved-memory" {
  type        = string
  description = "Amount of CPU reserved for the operating system (default: 100Mi)"

  default = "256Mi"
}

# Systemd/Docker hooks
variable "hooks" {
  type        = list(map(any))
  description = "Docker/Systemd hooks to add to this instance group. https://kops.sigs.k8s.io/cluster_spec/#hooks"

  default = []
}

# Master instance group(s)
variable "master-availability-zones" {
  type        = list(string)
  description = "Availability zones in which to create master instance groups"
}

variable "master-lb-visibility" {
  type        = string
  description = "Visibility (Public|Private) for our Kubernetes masters' ELB (default: Public)"

  default = "Public"
}

variable "master-lb-idle-timeout" {
  type        = number
  description = "Idle timeout for Kubernetes masters' ELB (default: 300s), in seconds"
  default     = 300
}

variable "master-image" {
  type        = string
  description = "AMI id to use for the master nodes"
}

variable "master-machine-type" {
  type        = string
  description = "EC2 instance type to run our masters onto (default: m3.medium)"

  default = "c4.large"
}

variable "master-volume-size" {
  type        = number
  description = "Size of our master's root volume, in GB (default: 10)"

  default = 10
}

variable "master-volume-provisioned-iops" {
  type        = string
  description = "Master volume provisioned IOPS, if applicable"

  default = ""
}

variable "master-volume-type" {
  type        = string
  description = "Master volume type (io1/gp2/gp3), defaults to gp3"

  default = "gp3"
}

variable "master-ebs-optimized" {
  type        = bool
  description = "Boolean (true or false) indicating whether our masters should be EBS optimized"
  default     = false
}

variable "master-update-interval" {
  type        = number
  description = "Interval (in minutes) between rolling updates of master nodes (default: 8)"

  default = 8
}

variable "master-cloud-labels" {
  type        = map(string)
  description = "(Flat) map of EC2 tags to add to master instances"

  default = {}
}

variable "master-node-labels" {
  type        = map(string)
  description = "(Flat) map of Kubernetes node labels to add to master instances"

  default = {}
}

variable "master-taints" {
  type        = list(string)
  description = "List of taints (under the form key=value) to add to master instances"

  default = []
}

variable "master-hooks" {
  type        = list(map(any))
  description = "Docker/Systemd hooks to add to the master instances. https://kops.sigs.k8s.io/cluster_spec/#hooks"

  default = []
}

variable "master-additional-sgs" {
  type        = list(string)
  description = "A list of additional security groups to add to master instances"

  default = []
}

# Apiserver instance group(s)
variable "apiserver-nodes-enabled" {
  type        = bool
  description = "Enables apiserver nodes"
  default     = false
}

variable "apiserver-availability-zones" {
  type        = list(string)
  description = "Availability zones in which to create apiserver instance groups"
}

variable "apiserver-lb-visibility" {
  type        = string
  description = "Visibility (Public|Private) for our Kubernetes apiservers' ELB (default: Public)"

  default = "Public"
}

variable "apiserver-lb-idle-timeout" {
  type        = number
  description = "Idle timeout for Kubernetes apiservers' ELB (default: 300s), in seconds"
  default     = 300
}

variable "apiserver-image" {
  type        = string
  description = "AMI id to use for the apiserver nodes"
}

variable "apiserver-machine-type" {
  type        = string
  description = "EC2 instance type to run our apiservers onto (default: m3.medium)"

  default = "c4.large"
}

variable "apiserver-volume-size" {
  type        = number
  description = "Size of our apiserver's root volume, in GB (default: 10)"

  default = 10
}

variable "apiserver-volume-provisioned-iops" {
  type        = string
  description = "apiserver volume provisioned IOPS, if applicable"

  default = ""
}

variable "apiserver-volume-type" {
  type        = string
  description = "apiserver volume type (io1/gp2/gp3), defaults to gp3"

  default = "gp3"
}

variable "apiserver-ebs-optimized" {
  type        = bool
  description = "Boolean (true or false) indicating whether our apiservers should be EBS optimized"
  default     = false
}

variable "apiserver-update-interval" {
  type        = number
  description = "Interval (in minutes) between rolling updates of apiserver nodes (default: 8)"

  default = 8
}

variable "apiserver-cloud-labels" {
  type        = map(string)
  description = "(Flat) map of EC2 tags to add to apiserver instances"

  default = {}
}

variable "apiserver-node-labels" {
  type        = map(string)
  description = "(Flat) map of Kubernetes node labels to add to apiserver instances"

  default = {}
}

variable "apiserver-taints" {
  type        = list(string)
  description = "List of taints (under the form key=value) to add to apiserver instances"

  default = []
}

variable "apiserver-hooks" {
  type        = list(map(any))
  description = "Docker/Systemd hooks to add to the apiserver instances. https://kops.sigs.k8s.io/cluster_spec/#hooks"

  default = []
}

variable "apiserver-additional-sgs" {
  type        = list(string)
  description = "A list of additional security groups to add to apiserver instances"

  default = []
}

# Bastion instance group
variable "bastion-image" {
  type        = string
  description = "AMI id to use for the bastion nodes (in private topology only)"
}

variable "bastion-additional-sgs" {
  type        = list(string)
  description = "Number of security groups to add to our bastion nodes"

  default = []
}

variable "bastion-machine-type" {
  type        = string
  description = "EC2 instance type to run our bastions onto (default: t2.micro)"

  default = "t2.micro"
}

variable "bastion-volume-size" {
  type        = number
  description = "Size of our bastion's root volume, in GB (default: 10)"

  default = 10
}

variable "bastion-volume-provisioned-iops" {
  type        = string
  description = "Bastion volume provisioned IOPS, if applicable"

  default = ""
}

variable "bastion-volume-type" {
  type        = string
  description = "Bastion volume type (io1/gp2/gp3), defaults to gp3"

  default = "gp3"
}

variable "bastion-ebs-optimized" {
  type        = bool
  description = "Boolean (true or false) indicating whether our bastion should be EBS optimized"
  default     = false
}

variable "min-bastions" {
  type        = number
  description = "Bastion ASG min size (default: 1)"

  default = 1
}

variable "max-bastions" {
  type        = number
  description = "Bastion ASG max size (default: 2)"

  default = 2
}

variable "bastion-update-interval" {
  type        = string
  description = "Interval (in minutes) between rolling updates of bastion nodes (default: 5)"

  default = "5"
}

variable "bastion-cloud-labels" {
  type        = map(string)
  description = "(Flat) map of EC2 tags to add to bastion instances"

  default = {}
}

variable "bastion-node-labels" {
  type        = map(string)
  description = "(Flat) map of Kubernetes node labels to add to bastion instances"

  default = {}
}

variable "bastion-hooks" {
  type        = list(map(any))
  description = "Docker/Systemd hooks to add to bastion instances. https://kops.sigs.k8s.io/cluster_spec/#hooks"

  default = []
}

# Initial minion instance group
variable "minion-ig-name" {
  type        = string
  description = "Name to give to the ig created along with the cluster (default: nodes)"

  default = "nodes"
}

variable "minion-ig-public" {
  type        = bool
  description = "Set to true for nodes in the default minion ig to receive a public IP address"

  default = false
}

variable "minion-additional-sgs" {
  type        = list(string)
  description = "Additional security groups to add to our minion nodes"

  default = []
}

variable "minion-image" {
  type        = string
  description = "AMI id to use for the minion nodes (in private topology only)"
}

variable "minion-machine-type" {
  type        = string
  description = "EC2 instance type to run our minions onto (default: t2.medium)"

  default = "t2.medium"
}

variable "minion-volume-size" {
  type        = number
  description = "Size of our default minion ig root volume, in GB (default: 30)"

  default = 30
}

variable "minion-volume-provisioned-iops" {
  type        = string
  description = "Minion volume provisioned IOPS, if applicable"

  default = ""
}

variable "minion-volume-type" {
  type        = string
  description = "Minion volume type (io1/gp2/gp3), defaults to gp3"

  default = "gp3"
}

variable "minion-ebs-optimized" {
  type        = bool
  description = "Boolean (true or false) indicating whether our default minion ig should be EBS optimized"
  default     = false
}

variable "min-minions" {
  type        = number
  description = "Minion ASG min size (default: 1)"

  default = 1
}

variable "max-minions" {
  type        = number
  description = "Minion ASG max size (default: 3)"

  default = 3
}

variable "minion-taints" {
  type        = list(string)
  description = "List of taints (under the form key=value) to add to default minion ig"

  default = []
}

variable "minion-update-interval" {
  type        = string
  description = "Interval (in minutes) between rolling updates of minion nodes (default: 8)"

  default = "8"
}

variable "minion-cloud-labels" {
  type        = map(string)
  description = "(Flat) map of EC2 tags to add to minion instances"

  default = {}
}

variable "minion-node-labels" {
  type        = map(string)
  description = "(Flat) map of Kubernetes node labels to add to minion instances"

  default = {}
}

variable "minion-hooks" {
  type        = list(map(any))
  description = "Docker/Systemd hooks to add to minions. https://kops.sigs.k8s.io/cluster_spec/#hooks"

  default = []
}

variable "master-additional-policies" {
  type        = string
  description = "Additional IAM policies to add to our master instance role: https://github.com/kubernetes/kops/blob/master/docs/iam_roles.md#adding-additional-policies"
  default     = ""
}

variable "node-additional-policies" {
  type        = string
  description = "Additional IAM policies to add to our node instance role: https://github.com/kubernetes/kops/blob/master/docs/iam_roles.md#adding-additional-policies"
  default     = ""
}

variable "external-policies" {
  type = object({
    node    = list(string)
    master  = list(string)
    bastion = list(string)
  })
  default = {
    node    = []
    master  = []
    bastion = []
  }
}

variable "log-level" {
  type        = number
  description = "V-Log log level of all infrastructure components (APIServer, controller-manager, etc.)"
  default     = 0
}

variable "kubernetes-cpu-cfs-quota-enabled" {
  type        = bool
  description = "Boolean (true or false) enable or disable cpuCFSQuota (cpu-cfs-quota)"
  default     = true
}

variable "kubernetes-cpu-cfs-quota-period" {
  type        = string
  description = "Set a time period for cpuCFSQuotaPeriod (cpu-cfs-quota-period)"
  default     = "100ms"
}

variable "serialize-image-pulls-enabled" {
  type        = bool
  description = "Boolean (true or false) enable or disable serializeImagePulls (serialize-image-pulls). If disabled Docker default download concurrency is 3."
  default     = true
}

variable "image-pull-progress-deadline" {
  type        = string
  description = "Set a time period for imagePullProgressDeadline (image-pull-progress-deadline)"
  default     = "1m"
}

variable "allowed-unsafe-sysctls" {
  type        = list(string)
  description = "List of sysctls to allow override - allowedUnsafeSysctls (allowed-unsafe-sysctls)"
  default     = []
}

variable "docker-auth-creds" {
  type = map(object({
    username = string
    password = string
  }))
  description = "Credentials for Docker repositories indexed by repository hostname"
  default     = {}
}

variable "iam" {
  type = object({
    allowContainerRegistry = bool
  })
  description = "IAM settings for the cluster"
  default = {
    allowContainerRegistry = true
  }
}

variable "cluster-autoscaler" {
  type = object({
    enabled                       = bool
    expander                      = string
    balanceSimilarNodeGroups      = bool
    scaleDownUtilizationThreshold = string
    scaleDownDelayAfterAdd        = string
    skipNodesWithLocalStorage     = bool
    skipNodesWithSystemPods       = bool
    cpuRequest                    = string
    memoryRequest                 = string
    image                         = string
  })
  default = {
    enabled                       = false
    expander                      = "least-waste"
    balanceSimilarNodeGroups      = false
    scaleDownUtilizationThreshold = "0.5"
    scaleDownDelayAfterAdd        = "10m0s"
    skipNodesWithLocalStorage     = false
    skipNodesWithSystemPods       = true
    cpuRequest                    = "100m"
    memoryRequest                 = "300Mi"
    image                         = null
  }
}

variable "metrics-server" {
  type = object({
    enabled  = bool
    insecure = bool
  })
  default = {
    enabled  = false
    insecure = false
  }
}

variable "aws-ebs-csi-driver" {
  type = object({
    enabled = bool
  })
  default = {
    enabled = false
  }
}

variable "aws-load-balancer-controller" {
  type = object({
    enabled = bool
  })
  default = {
    enabled = false
  }
}

variable "cert-manager" {
  type = object({
    enabled = bool
  })
  default = {
    enabled = false
  }
}

variable "containerd-log-level" {
  type    = string
  default = "warn"
}
