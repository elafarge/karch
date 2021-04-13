locals {
  cluster_spec = {
    apiVersion = "kops.k8s.io/v1alpha2"
    kind       = "Cluster"
    metadata = {
      name = var.cluster-name
    }
    spec = {
      api = {
        loadBalancer = {
          type               = var.master-lb-visibility == "Private" ? "Internal" : "Public"
          idleTimeoutSeconds = var.master-lb-idle-timeout
        }
      }
      addons = [{
        manifest = "s3://${var.kops-state-bucket}/terraform-addons/${var.cluster-name}/addons.yaml"
      }]
      authorization = {
        (var.rbac ? "rbac" : "alwaysAllow") = {}
      }
      channel = var.channel
      cloudConfig = {
        disableSecurityGroupIngress = var.disable-sg-ingress
      }
      cloudLabels      = length(keys(var.cloud-labels)) == 0 ? null : var.cloud-labels
      cloudProvider    = "aws"
      clusterDNSDomain = var.kube-dns.domain
      configBase       = "s3://${var.kops-state-bucket}/${var.cluster-name}"
      configStore      = "s3://${var.kops-state-bucket}/${var.cluster-name}"
      dnsZone          = var.cluster-name
      etcdClusters = [
        for etcd_cluster in ["main", "events"] : merge({
          name          = etcd_cluster
          enableEtcdTLS = var.etcd-enable-tls
          etcdMembers = [
            for az in var.master-availability-zones : {
              encryptedVolume = true
              instanceGroup   = "master-${az}"
              name            = az
            }
          ]
          provider = var.etcd-mode
          version  = var.etcd-version
          }, var.etcd-backup-enabled ? {
          backups = {
            backupStore = "s3://${var.etcd-backup-s3-bucket == "" ? var.kops-state-bucket : var.etcd-backup-s3-bucket}/${var.cluster-name}/backups/etcd/${etcd_cluster}/"
          }
        } : {})
      ]
      keyStore = "s3://${var.kops-state-bucket}/${var.cluster-name}/pki"
      kubeAPIServer = merge({
        insecureBindAddress          = "127.0.0.1"
        enableAdmissionPlugins       = var.enable-admission-plugins
        anonymousAuth                = false
        apiServerCount               = length(var.master-availability-zones)
        authorizationMode            = var.rbac ? "RBAC" : "AlwaysAllow"
        cloudProvider                = "aws"
        etcdServers                  = ["http://127.0.0.1:4001"]
        etcdServersOverrides         = ["/events#http://127.0.0.1:4002"]
        insecurePort                 = 8080
        kubeletPreferredAddressTypes = ["InternalIP", "Hostname", "ExternalIP"]
        logLevel                     = var.log-level
        securePort                   = 443
        serviceClusterIPRange        = "100.64.0.0/13"
        storageBackend               = "etcd${substr(var.etcd-version, 0, 1)}"
        runtimeConfig                = var.apiserver-runtime-flags
        featureGates                 = var.featuregates-flags
        }, var.oidc-issuer-url == "" ? {} : {
        oidcCAFile        = var.oidc-ca-file == "" ? null : var.oidc-ca-file
        oidcClientID      = var.oidc-client-id
        oidcGroupsClaim   = var.oidc-groups-claim
        oidcIssuerURL     = var.oidc-issuer-url
        oidcUsernameClaim = var.oidc-username-claim
      })
      kubeControllerManager = {
        allocateNodeCIDRs               = true
        attachDetachReconcileSyncPeriod = "1m0s"
        cloudProvider                   = "aws"
        clusterCIDR                     = "100.96.0.0/11"
        clusterName                     = var.cluster-name
        configureCloudRoutes            = false
        leaderElection = {
          leaderElect = true
        }
        logLevel                                      = var.log-level
        useServiceAccountCredentials                  = true
        horizontalPodAutoscalerSyncPeriod             = var.hpa-sync-period
        horizontalPodAutoscalerDownscaleStabilization = var.hpa-scale-downscale-stabilization
        kubeAPIQPS                                    = var.controller-manager-kube-api-qps
        kubeAPIBurst                                  = var.controller-manager-kube-api-burst
        featureGates                                  = var.featuregates-flags
      }
      kubeDNS = {
        domain           = var.kube-dns.domain
        serverIP         = var.kube-dns.server-ip
        provider         = var.kube-dns.provider
        coreDNSImage     = var.coredns.image
        externalCoreFile = var.coredns.corefile
        nodeLocalDNS = {
          enabled       = var.node-local-dns-cache.enabled
          cpuRequest    = var.node-local-dns-cache.resources.requests.cpu
          memoryRequest = var.node-local-dns-cache.resources.requests.memory
        }
      }
      kubeProxy = {
        enabled          = var.kube-proxy-enabled
        clusterCIDR      = var.kube-proxy-params.clusterCIDR
        cpuRequest       = var.kube-proxy-params.cpuRequest
        hostnameOverride = var.kube-proxy-params.hostnameOverride
        image            = "gcr.io/google_containers/kube-proxy:v${var.kubernetes-version}" # From upstream
        logLevel         = var.log-level
      }
      kubeScheduler = {
        leaderElection = {
          leaderElect = true
        }
        logLevel = var.log-level
      }
      kubelet = {
        allowedUnsafeSysctls      = var.allowed-unsafe-sysctls
        anonymousAuth             = true
        cpuCFSQuota               = var.kubernetes-cpu-cfs-quota-enabled
        cpuCFSQuotaPeriod         = var.kubernetes-cpu-cfs-quota-period
        serializeImagePulls       = var.serialize-image-pulls-enabled
        imagePullProgressDeadline = var.image-pull-progress-deadline
        cgroupRoot                = "/"
        cloudProvider             = "aws"
        clusterDNS                = var.kube-dns.server-ip
        clusterDomain             = var.kube-dns.domain
        enableDebuggingHandlers   = true
        evictionHard              = var.kubelet-eviction-flag
        hostnameOverride          = "@aws"
        kubeconfigPath            = "/var/lib/kubelet/kubeconfig"
        logLevel                  = var.log-level
        networkPluginName         = "cni"
        nonMasqueradeCIDR         = "100.64.0.0/10"
        podManifestPath           = "/etc/kubernetes/manifests"
        kubeReserved = {
          cpu    = var.kube-reserved-cpu
          memory = var.kube-reserved-memory
        }
        systemReserved = {
          cpu    = var.system-reserved-cpu
          memory = var.system-reserved-memory
        }
        enforceNodeAllocatable = "pods"
        featureGates           = var.featuregates-flags
      }
      kubernetesApiAccess = var.trusted-cidrs
      kubernetesVersion   = var.kubernetes-version
      masterInternalName  = "api.internal.${var.cluster-name}"
      masterKubelet = {
        cgroupRoot              = "/"
        cloudProvider           = "aws"
        clusterDNS              = var.kube-dns.server-ip
        clusterDomain           = var.kube-dns.domain
        enableDebuggingHandlers = true
        evictionHard            = "memory.available<100Mi,nodefs.available<10%,nodefs.inodesFree<5%,imagefs.available<10%,imagefs.inodesFree<5%"
        hostnameOverride        = "@aws"
        kubeconfigPath          = "/var/lib/kubelet/kubeconfig"
        logLevel                = var.log-level
        networkPluginName       = "cni"
        nonMasqueradeCIDR       = "100.64.0.0/10"
        podManifestPath         = "/etc/kubernetes/manifests"
        registerSchedulable     = false
      }
      masterPublicName = "api.${var.cluster-name}"
      networkCIDR      = var.vpc-networking.vpc-cidr-block
      networkID        = var.vpc-networking.vpc-id
      networking = {
        (var.container-networking) = var.container-networking-params
      }
      nonMasqueradeCIDR     = "100.64.0.0/10"
      secretStore           = "s3://${var.kops-state-bucket}/${var.cluster-name}/secrets"
      serviceClusterIPRange = "100.64.0.0/13"
      sshAccess             = var.trusted-cidrs
      subnets = flatten([
        for idx in range(length(var.availability-zones)) : [
          {
            cidr   = var.vpc-networking.vpc-private-cidrs[idx]
            name   = var.availability-zones[idx]
            type   = "Private"
            zone   = var.availability-zones[idx]
            id     = var.vpc-networking.vpc-private-subnet-ids[idx]
            egress = var.vpc-networking.nat-gateways[idx]
          },
          {
            cidr = var.vpc-networking.vpc-public-cidrs[idx]
            name = "utility-${var.availability-zones[idx]}"
            type = "Utility"
            zone = var.availability-zones[idx]
            id   = var.vpc-networking.vpc-public-subnet-ids[idx]
          },
        ]
      ])
      topology = {
        bastion = {
          bastionPublicName = "bastion.${var.cluster-name}"
        }
        dns = {
          type = var.master-lb-visibility
        }
        masters = "private"
        nodes   = "private"
      }
      hooks = length(var.hooks) > 0 ? var.hooks : null
      additionalPolicies = merge(
        { master = jsonencode(jsondecode(data.aws_iam_policy_document.master-additional.json).Statement) },
        length(var.node-additional-policies) == 0 ? {} : { node = var.node-additional-policies }
      )
    }
  }
  master_spec = [
    for az in var.master-availability-zones : {
      apiVersion = "kops.k8s.io/v1alpha2"
      kind       = "InstanceGroup"
      metadata = {
        labels = {
          "kops.k8s.io/cluster" : var.cluster-name
        }
        name = "master-${az}"
      }
      spec = merge({
        cloudLabels            = length(keys(var.master-cloud-labels)) == 0 ? null : var.master-cloud-labels
        nodeLabels             = length(var.master-node-labels) > 0 ? var.master-node-labels : null
        associatePublicIp      = false
        image                  = var.master-image
        machineType            = var.master-machine-type
        maxSize                = 1
        minSize                = 1
        role                   = "Master"
        rootVolumeSize         = var.master-volume-size
        rootVolumeType         = var.master-volume-type
        rootProvisionedIops    = var.master-volume-provisioned-iops == "" ? null : var.master-volume-provisioned-iops
        rootVolumeOptimization = var.master-ebs-optimized
        taints                 = length(var.master-taints) > 0 ? var.master-taints : null
        subnets                = [az]
        hooks                  = length(var.master-hooks) > 0 ? var.master-hooks : null
      }, length(var.master-additional-sgs) > 0 ? { additionalSecurityGroups = var.master-additional-sgs } : {})
    }
  ]
  bastion_spec = var.kops-topology != "private" ? [] : [{
    apiVersion = "kops.k8s.io/v1alpha2"
    kind       = "InstanceGroup"
    metadata = {
      labels = {
        "kops.k8s.io/cluster" : var.cluster-name
      }
      name = "bastions"
    }
    spec = merge({
      cloudLabels            = length(keys(var.bastion-cloud-labels)) == 0 ? null : var.bastion-cloud-labels
      nodeLabels             = length(var.bastion-node-labels) > 0 ? var.bastion-node-labels : null
      associatePublicIp      = false
      image                  = var.bastion-image
      machineType            = var.bastion-machine-type
      maxSize                = var.max-bastions
      minSize                = var.min-bastions
      role                   = "Bastion"
      rootVolumeSize         = var.bastion-volume-size
      rootVolumeType         = var.bastion-volume-type
      rootProvisionedIops    = var.bastion-volume-provisioned-iops == "" ? null : var.bastion-volume-provisioned-iops
      rootVolumeOptimization = var.bastion-ebs-optimized
      taints                 = null
      subnets                = var.availability-zones
      hooks                  = length(var.bastion-hooks) > 0 ? var.bastion-hooks : null
    }, length(var.bastion-additional-sgs) > 0 ? { additionalSecurityGroups = var.bastion-additional-sgs } : {})
  }]
  minion_spec = {
    apiVersion = "kops.k8s.io/v1alpha2"
    kind       = "InstanceGroup"
    metadata = {
      labels = {
        "kops.k8s.io/cluster" : var.cluster-name
      }
      name = var.minion-ig-name
    }
    spec = merge({
      cloudLabels            = length(keys(var.minion-cloud-labels)) == 0 ? null : var.minion-cloud-labels
      nodeLabels             = length(var.minion-node-labels) > 0 ? var.minion-node-labels : null
      associatePublicIp      = false
      image                  = var.minion-image
      machineType            = var.minion-machine-type
      maxSize                = var.max-minions
      minSize                = var.min-minions
      role                   = "Node"
      rootVolumeSize         = var.minion-volume-size
      rootVolumeType         = var.minion-volume-type
      rootProvisionedIops    = var.minion-volume-provisioned-iops == "" ? null : var.minion-volume-provisioned-iops
      rootVolumeOptimization = var.minion-ebs-optimized
      taints                 = length(var.minion-taints) > 0 ? var.minion-taints : null
      subnets                = var.availability-zones
      hooks                  = length(var.minion-hooks) > 0 ? var.minion-hooks : null
    }, length(var.minion-additional-sgs) > 0 ? { additionalSecurityGroups = var.minion-additional-sgs } : {})
  }
}

data "aws_iam_policy_document" "master-additional" {
  source_json = var.master-additional-policies

  statement {
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::${var.kops-state-bucket}/terraform-addons/${var.cluster-name}/*"
    ]
  }

  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.kops-state-bucket}"
    ]
  }
}
