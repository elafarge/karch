locals {
  apiserver-nodes-ff = "+APIServerNodes"
}

// Cluster manifest on S3 and cluster destroy-time provisioner
resource "aws_s3_bucket_object" "cluster-spec" {
  bucket = var.kops-state-bucket
  key    = "/karch-specs/${var.cluster-name}/master-cluster-spec.yml"

  content = <<EOF
${join("\n---\n", concat(
  [yamlencode(local.cluster_spec)],
  [for spec in local.master_spec : yamlencode(spec)],
  [for spec in local.apiserver_nodes_spec : yamlencode(spec)],
  [for spec in local.bastion_spec : yamlencode(spec)],
  [yamlencode(local.minion_spec)],
))}
EOF

tags = merge({
  nodeup-url-env     = var.nodeup-url-env
  aws-profile        = var.aws-profile
  kops-state-bucket  = var.kops-state-bucket
  cluster-name       = var.cluster-name
}, var.apiserver-nodes-enabled ? {
  kops-feature-flags = local.apiserver-nodes-ff
} : {})

// On destroy, remove the cluster first, if it exists
provisioner "local-exec" {
  when    = destroy
  command = "(test -z \"$(${self.tags["nodeup-url-env"]} KOPS_FEATURE_FLAGS=${try(self.tags["kops-feature-flags"], "")} AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=${self.tags["aws-profile"]} kops --state=s3://${self.tags["kops-state-bucket"]} get cluster | grep ${self.tags["cluster-name"]})\" ) || ${self.tags["nodeup-url-env"]} KOPS_FEATURE_FLAGS=${try(self.tags["kops-feature-flags"], "")} AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=${self.tags["aws-profile"]} kops --state=s3://${self.tags["kops-state-bucket"]} delete cluster --yes ${self.tags["cluster-name"]}"
}

depends_on = [aws_route53_record.cluster-root, aws_s3_bucket_object.addons-list]
}

resource "aws_s3_bucket_object" "addons-list" {
  for_each = var.kops-static-addons
  bucket   = var.kops-state-bucket
  key      = "/terraform-addons/${var.cluster-name}/${each.key}.yaml"
  content = yamlencode({
    kind = "Addons"
    metadata = {
      name = each.key
    }
    spec = {
      addons = [
        for version, addon in each.value : {
          version = version
          selector = {
            k8s-addon = "${each.key}.addons.k8s.io"
          }
          manifest          = "${each.key}_v${version}.yaml"
          kubernetesVersion = addon.kubernetes-version
        }
      ]
    }
  })
  depends_on = [aws_s3_bucket_object.addons-manifests]
}

resource "aws_s3_bucket_object" "addons-manifests" {
  for_each = {
    for i in flatten([
      for name, versions in var.kops-static-addons : [
        for version, addon in versions : [
          { "${name}_v${version}" : addon }
        ]
      ]
    ]) : keys(i)[0] => values(i)[0]
  }
  bucket  = var.kops-state-bucket
  key     = "/terraform-addons/${var.cluster-name}/${each.key}.yaml"
  content = each.value.manifest
}

// Cluster create-time provisioner
resource "null_resource" "kops-cluster" {
  // Let's dump the cluster spec in a conf file
  provisioner "local-exec" {
    command = <<FILEDUMP
      cat <<EOF > ${path.module}/${var.cluster-name}-cluster-spec.yml
${aws_s3_bucket_object.cluster-spec.content}
EOF
FILEDUMP
  }

  // Let's wait for our newly created DNS zone to propagate
  provisioner "local-exec" {
    command = <<EOF
      until test ! -z "$(dig NS ${var.cluster-name} | grep "ANSWER SECTION")"
      do
        echo "DNS zone ${var.cluster-name} isn't available yet, retrying in 5s"
        sleep 5s
      done
EOF
  }

  // Let's register our Kops cluster into remote state
  provisioner "local-exec" {
    command = "${var.nodeup-url-env} KOPS_FEATURE_FLAGS=${var.apiserver-nodes-enabled ? local.apiserver-nodes-ff : ""} AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=${var.aws-profile} kops --state=s3://${var.kops-state-bucket} create -f ${path.module}/${var.cluster-name}-cluster-spec.yml"
  }

  // Let's remove the cluster spec file from disk
  provisioner "local-exec" {
    command = "rm ${path.module}/${var.cluster-name}-cluster-spec.yml"
  }

  // Do not forget to add our public SSH key over there
  provisioner "local-exec" {
    command = "${var.nodeup-url-env} KOPS_FEATURE_FLAGS=${var.apiserver-nodes-enabled ? local.apiserver-nodes-ff : ""} AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=${var.aws-profile} kops --state=s3://${var.kops-state-bucket} create secret --name ${var.cluster-name} sshpublickey admin -i ${var.admin-ssh-public-key-path}"
  }

  // Run initial cluster provisioning
  provisioner "local-exec" {
    command = "${var.nodeup-url-env} KOPS_FEATURE_FLAGS=${var.apiserver-nodes-enabled ? local.apiserver-nodes-ff : ""} AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=${var.aws-profile} kops --state=s3://${var.kops-state-bucket} update cluster ${var.cluster-name} --yes"
  }

  depends_on = [aws_s3_bucket_object.cluster-spec]
}

// Hook that triggers cluster updates when the manifest changes
resource "null_resource" "kops-update" {
  triggers = {
    cluster_spec = aws_s3_bucket_object.cluster-spec.content
  }

  provisioner "local-exec" {
    command = <<FILEDUMP
      cat <<EOF > ${path.module}/${var.cluster-name}-cluster-spec.yml
${aws_s3_bucket_object.cluster-spec.content}
EOF
FILEDUMP
  }

  provisioner "local-exec" {
    command = <<EOF
      KOPS_FEATURE_FLAGS="${var.apiserver-nodes-enabled ? local.apiserver-nodes-ff : ""}" ${var.nodeup-url-env} AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=${var.aws-profile} kops --state=s3://${var.kops-state-bucket} \
        replace -f ${path.module}/${var.cluster-name}-cluster-spec.yml

      rm -f ${path.module}/${var.cluster-name}-cluster-spec.yml
EOF
  }

  depends_on = [null_resource.kops-cluster]
}

resource "null_resource" "docker-auth-config" {
  count = var.docker-auth-creds != {} ? 1 : 0
  triggers = {
    config     = jsonencode(local.docker-auth-config)
    local_path = "${path.module}/${var.cluster-name}-docker-config.yml"
  }

  provisioner "local-exec" {
    command = <<FILEDUMP
      cat <<EOF > ${self.triggers.local_path}
${self.triggers.config}
EOF
FILEDUMP
  }

  provisioner "local-exec" {
    command = <<EOF
      KOPS_FEATURE_FLAGS="${var.apiserver-nodes-enabled ? local.apiserver-nodes-ff : ""}" ${var.nodeup-url-env} AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=${var.aws-profile} kops --state=s3://${var.kops-state-bucket} --name ${var.cluster-name} \
        create secret dockerconfig -f ${self.triggers.local_path} --force && \

      rm -f ${self.triggers.local_path}
EOF
  }

  depends_on = [null_resource.kops-cluster]
}
