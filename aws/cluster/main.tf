// Cluster manifest on S3 and cluster destroy-time provisioner
resource "aws_s3_bucket_object" "cluster-spec" {
  bucket = "${var.kops-state-bucket}"
  key    = "/karch-specs/${var.cluster-name}/master-cluster-spec.yml"

  content = <<EOF
${join("\n---\n", concat(
  list(data.template_file.cluster-spec.rendered),
  data.template_file.master-spec.*.rendered,
  data.template_file.bastion-spec.*.rendered,
  list(data.template_file.minion-spec.rendered),
))}
EOF

  // On destroy, remove the cluster first, if it exists
  provisioner "local-exec" {
    when    = "destroy"
    command = "(test -z \"$(${var.nodeup-url-env} ${var.aws-profile-env-override} kops --state=s3://${var.kops-state-bucket} get cluster | grep ${var.cluster-name})\" ) || ${var.nodeup-url-env} ${var.aws-profile-env-override} kops --state=s3://${var.kops-state-bucket} delete cluster --yes ${var.cluster-name}"
  }

  depends_on = ["aws_route53_record.cluster-root", "aws_vpc.main"]
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
    command = "${var.nodeup-url-env} ${var.aws-profile-env-override} kops --state=s3://${var.kops-state-bucket} create -f ${path.module}/${var.cluster-name}-cluster-spec.yml"
  }

  // Let's remove the cluster spec file from disk
  provisioner "local-exec" {
    command = "rm ${path.module}/${var.cluster-name}-cluster-spec.yml"
  }

  // Do not forget to add our public SSH key over there
  provisioner "local-exec" {
    command = "${var.nodeup-url-env} ${var.aws-profile-env-override} kops --state=s3://${var.kops-state-bucket} create secret --name ${var.cluster-name} sshpublickey admin -i ${var.admin-ssh-public-key-path}"
  }

  depends_on = ["aws_s3_bucket_object.cluster-spec"]
}

// Hook for other modules (like instance groups) to wait for the master to be available
resource "null_resource" "master-up" {
  provisioner "local-exec" {
    command = <<EOF
      until ${var.nodeup-url-env} ${var.aws-profile-env-override} kops --state=s3://${var.kops-state-bucket} validate cluster --name ${var.cluster-name}
      do
        echo "Cluster isn't available yet"
        sleep 5s
      done
EOF
  }

  depends_on = ["null_resource.kops-cluster"]
}

// Hook that triggers cluster updates when the manifest changes
resource "null_resource" "kops-update" {
  triggers {
    cluster_spec = "${aws_s3_bucket_object.cluster-spec.content}"
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
      ${var.nodeup-url-env} ${var.aws-profile-env-override} kops --state=s3://${var.kops-state-bucket} \
        replace -f ${path.module}/${var.cluster-name}-cluster-spec.yml

      rm -f ${path.module}/${var.cluster-name}-cluster-spec.yml

      ${var.nodeup-url-env} ${var.aws-profile-env-override} kops --state=s3://${var.kops-state-bucket} \
        update cluster ${var.cluster-name} --yes
EOF
  }

  depends_on = ["null_resource.kops-cluster"]
}
