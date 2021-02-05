// Cluster manifest on S3 and cluster destroy-time provisioner
resource "aws_s3_bucket_object" "cluster-spec" {
  count  = var.create_cluster_spec_object
  bucket = var.kops-state-bucket
  key    = "/karch-specs/${var.cluster-name}/master-cluster-spec.yml"

  content = <<EOF
${join("\n---\n", concat(
  list(yamlencode(local.cluster_spec)),
  [for spec in local.master_spec : yamlencode(spec)],
  [for spec in local.bastion_spec : yamlencode(spec)],
  list(yamlencode(local.minion_spec)),
))}
EOF

tags = {
  nodeup-url-env    = var.nodeup-url-env
  aws-profile       = var.aws-profile
  kops-state-bucket = var.kops-state-bucket
  cluster-name      = var.cluster-name
}

// On destroy, remove the cluster first, if it exists
provisioner "local-exec" {
  when    = destroy
  command = "(test -z \"$(${self.tags["nodeup-url-env"]} AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=${self.tags["aws-profile"]} kops --state=s3://${self.tags["kops-state-bucket"]} get cluster | grep ${self.tags["cluster-name"]})\" ) || ${self.tags["nodeup-url-env"]} AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=${self.tags["aws-profile"]} kops --state=s3://${self.tags["kops-state-bucket"]} delete cluster --yes ${self.tags["cluster-name"]}"
}

depends_on = [aws_route53_record.cluster-root, aws_s3_bucket_object.addons-list]
}

resource "aws_s3_bucket_object" "addons-list" {
  bucket = var.kops-state-bucket
  key    = "/terraform-addons/${var.cluster-name}/addons.yaml"
  content = yamlencode({
    kind = "Addons"
    metadata = {
      name = "terraform-addons"
    }
    spec = {
      addons = [
        for name, addon in var.kops-static-addons : {
          version = addon.version
          selector = {
            k8s-addon = "${name}.addons.k8s.io"
          }
          manifest = "${name}_v${addon.version}.yaml"
        }
      ]
    }
  })
  depends_on = [aws_s3_bucket_object.addons-manifests]
}

resource "aws_s3_bucket_object" "addons-manifests" {
  for_each = var.kops-static-addons
  bucket   = var.kops-state-bucket
  key      = "/terraform-addons/${var.cluster-name}/${each.key}_v${each.value.version}.yaml"
  content  = each.value.manifest
}

// Cluster create-time provisioner
resource "null_resource" "kops-cluster" {
  // Let's dump the cluster spec in a conf file
  provisioner "local-exec" {
    command = <<FILEDUMP
      cat <<EOF > ${path.module}/${var.cluster-name}-cluster-spec.yml
${aws_s3_bucket_object.cluster-spec[0].content}
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
    command = "${var.nodeup-url-env} AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=${var.aws-profile} kops --state=s3://${var.kops-state-bucket} create -f ${path.module}/${var.cluster-name}-cluster-spec.yml"
  }

  // Let's remove the cluster spec file from disk
  provisioner "local-exec" {
    command = "rm ${path.module}/${var.cluster-name}-cluster-spec.yml"
  }

  // Do not forget to add our public SSH key over there
  provisioner "local-exec" {
    command = "${var.nodeup-url-env} AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=${var.aws-profile} kops --state=s3://${var.kops-state-bucket} create secret --name ${var.cluster-name} sshpublickey admin -i ${var.admin-ssh-public-key-path}"
  }

  depends_on = [aws_s3_bucket_object.cluster-spec]
}

// Hook for other modules (like instance groups) to wait for the master to be available
resource "null_resource" "master-up" {
  provisioner "local-exec" {
    command = <<EOF
      until ${var.nodeup-url-env} AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=${var.aws-profile} kops --state=s3://${var.kops-state-bucket} validate cluster --name ${var.cluster-name}
      do
        echo "Cluster isn't available yet"
        sleep 5s
      done
EOF
  }

  depends_on = [null_resource.kops-cluster]
}

// Hook that triggers cluster updates when the manifest changes
resource "null_resource" "kops-update" {
  count = var.create_cluster_spec_object
  triggers = {
    cluster_spec = aws_s3_bucket_object.cluster-spec[0].content
  }

  provisioner "local-exec" {
    command = <<FILEDUMP
      cat <<EOF > ${path.module}/${var.cluster-name}-cluster-spec.yml
${aws_s3_bucket_object.cluster-spec[0].content}
EOF
FILEDUMP
  }

  provisioner "local-exec" {
    command = <<EOF
      ${var.nodeup-url-env} AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=${var.aws-profile} kops --state=s3://${var.kops-state-bucket} \
        replace -f ${path.module}/${var.cluster-name}-cluster-spec.yml

      rm -f ${path.module}/${var.cluster-name}-cluster-spec.yml

      ${var.nodeup-url-env} AWS_SDK_LOAD_CONFIG=1 AWS_PROFILE=${var.aws-profile} kops --state=s3://${var.kops-state-bucket} \
        update cluster ${var.cluster-name} --yes
EOF
  }

  depends_on = [null_resource.kops-cluster]
}

// Cluster Docker Login Configuration on S3
// Short version of https://github.com/kubernetes/kops/blob/master/docs/cli/kops_create_secret_dockerconfig.md
// Kops version currently subject to bugs and doesn't trigger rolling upgrade so no need to complicate as per cluster-spec.
resource "aws_s3_bucket_object" "docker-auth-config" {
  count  = var.docker-auth-config != "" ? 1 : 0
  bucket = var.kops-state-bucket
  key    = "/${var.cluster-name}/secrets/dockerconfig"

  content = <<EOF
{"Data":"${var.docker-auth-config}"}
EOF

  depends_on = [null_resource.kops-cluster]
}
