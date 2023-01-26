locals {
  ig_spec = {
    apiVersion = "kops.k8s.io/v1alpha2"
    kind       = "InstanceGroup"
    metadata = {
      labels = {
        "kops.k8s.io/cluster" = var.cluster-name
      }
      name = var.name
    }
    spec = merge({
      cloudLabels            = var.cloud-labels
      nodeLabels             = var.node-labels
      associatePublicIp      = var.visibility == "public"
      image                  = var.image
      machineType            = var.type
      maxSize                = var.max-size
      minSize                = var.min-size
      externalLoadBalancers  = var.external-load-balancers
      additionalUserData     = var.user-data
      role                   = "Node"
      rootVolumeSize         = var.volume-size
      rootVolumeType         = var.volume-type
      rootProvisionedIops    = var.volume-provisioned-iops == "" ? null : var.volume-provisioned-iops
      rootVolumeOptimization = var.ebs-optimized
      maxPrice               = var.max-price
      taints                 = length(var.taints) > 0 ? var.taints : null
      subnets                = var.subnets
      hooks                  = length(var.hooks) > 0 ? var.hooks : null
      warmPool = var.warm-pool != null ? {
        minSize             = var.warm-pool.min-size
        maxSize             = var.warm-pool.max-size
        enableLifecycleHook = var.warm-pool.enable-lifecycle-hook
      } : null
      rollingUpdate = {
        maxSurge       = var.rolling-update.max-surge
        maxUnavailable = var.rolling-update.max-unavailable
      }
    }, length(var.additional-sgs) > 0 ? { additionalSecurityGroups = var.additional-sgs } : {})
  }
}

resource "aws_s3_bucket_object" "ig-spec" {
  count  = var.create_cluster_spec_object
  bucket = var.kops-state-bucket
  key    = "/karch-specs/${var.cluster-name}/${var.name}-ig-spec.yml"

  content = yamlencode(local.ig_spec)

  tags = {
    nodeup-url-env    = var.nodeup-url-env
    aws-profile       = var.aws-profile
    kops-state-bucket = var.kops-state-bucket
    cluster-name      = var.cluster-name
    name              = var.name
  }

  // On destroy, remove the IG, if it exists
  provisioner "local-exec" {
    when    = destroy
    command = "(test -z \"$(${self.tags["nodeup-url-env"]} AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=${self.tags["aws-profile"]} kops --state=s3://${self.tags["kops-state-bucket"]} get cluster | grep ${self.tags["cluster-name"]})\" ) || ${self.tags["nodeup-url-env"]} AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=${self.tags["aws-profile"]} kops --state=s3://${self.tags["kops-state-bucket"]} delete ig --name ${self.tags["cluster-name"]} --yes ${self.tags["name"]}"
  }
}

resource "null_resource" "ig" {
  // Let's dump the ig spec on disk
  provisioner "local-exec" {
    command = <<FILEDUMP
      cat <<EOF > ${path.module}/${var.cluster-name}-${var.name}-ig-spec.yml
${aws_s3_bucket_object.ig-spec[0].content}
EOF
FILEDUMP
  }

  // Let's register our Kops cluster into remote state
  provisioner "local-exec" {
    command = <<EOF
      ${var.nodeup-url-env} AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=${var.aws-profile} kops --state=s3://${var.kops-state-bucket} \
        create -f ${path.module}/${var.cluster-name}-${var.name}-ig-spec.yml
EOF
  }

  // Let's remove the ig spec from disk
  provisioner "local-exec" {
    command = "rm -f ${path.module}/${var.cluster-name}-${var.name}-ig-spec.yml"
  }

  depends_on = [aws_s3_bucket_object.ig-spec]
}

resource "null_resource" "ig-update" {
  triggers = {
    cluster_spec = yamlencode(local.ig_spec)
  }

  provisioner "local-exec" {
    command = <<FILEDUMP
      cat <<EOF > ${path.module}/${var.cluster-name}-${var.name}-ig-spec.yml
${yamlencode(local.ig_spec)}
EOF
FILEDUMP
  }

  provisioner "local-exec" {
    command = <<EOF
      ${var.nodeup-url-env} AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=${var.aws-profile} kops --state=s3://${var.kops-state-bucket} \
        replace -f ${path.module}/${var.cluster-name}-${var.name}-ig-spec.yml

      rm -f ${path.module}/${var.cluster-name}-${var.name}-ig-spec.yml
EOF
  }

  depends_on = [null_resource.ig]
}
