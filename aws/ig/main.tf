resource "aws_s3_bucket_object" "ig-spec" {
  bucket = "${var.kops-state-bucket}"
  key    = "/karch-specs/${var.cluster-name}/${var.name}-ig-spec.yml"

  content = "${data.template_file.ig-spec.rendered}"

  // On destroy, remove the IG, if it exists
  provisioner "local-exec" {
    when    = "destroy"
    command = "(test -z \"$(${var.nodeup-url-env} ${var.aws-profile-env-override} kops --state=s3://${var.kops-state-bucket} get cluster | grep ${var.cluster-name})\" ) || ${var.nodeup-url-env} ${var.aws-profile-env-override} kops --state=s3://${var.kops-state-bucket} delete ig --name ${var.cluster-name} --yes ${var.name}"
  }
}

resource "null_resource" "ig" {
  // Let's wait for the Kubernetes API to be available
  provisioner "local-exec" {
    command = "echo \"Master available: ${var.master-up}', let's use kops to create our instance group\""
  }

  // Let's dump the ig spec on disk
  provisioner "local-exec" {
    command = <<FILEDUMP
      cat <<EOF > ${path.module}/${var.cluster-name}-${var.name}-ig-spec.yml
${aws_s3_bucket_object.ig-spec.content}
EOF
FILEDUMP
  }

  // Let's register our Kops cluster into remote state
  provisioner "local-exec" {
    command = <<EOF
      until mkdir ${path.root}/.kops-ig-lock
      do
        echo "Waiting for other instance group update to finish"
        sleep 5s
      done
      echo 'locked' > ${path.root}/.kops-ig-lock

      ${var.nodeup-url-env} ${var.aws-profile-env-override} kops --state=s3://${var.kops-state-bucket} create -f ${path.module}/${var.cluster-name}-${var.name}-ig-spec.yml

      rmdir ${path.root}/.kops-ig-lock
EOF
  }

  // Let's remove the ig spec from disk
  provisioner "local-exec" {
    command = "rm -f ${path.module}/${var.cluster-name}-${var.name}-ig-spec.yml"
  }

  depends_on = ["aws_s3_bucket_object.ig-spec"]
}

resource "null_resource" "ig-update" {
  triggers {
    cluster_spec = "${data.template_file.ig-spec.rendered}"
  }

  provisioner "local-exec" {
    command = <<FILEDUMP
      cat <<EOF > ${path.module}/${var.cluster-name}-${var.name}-ig-spec.yml
${data.template_file.ig-spec.rendered}
EOF
FILEDUMP
  }

  provisioner "local-exec" {
    command = <<EOF
      until mkdir ${path.root}/.kops-ig-lock
      do
        echo "Waiting for other instance group update to finish"
        sleep 5s
      done
      echo 'locked' > ${path.root}/.kops-ig-lock

      ${var.nodeup-url-env} ${var.aws-profile-env-override} kops --state=s3://${var.kops-state-bucket} \
        replace -f ${path.module}/${var.cluster-name}-${var.name}-ig-spec.yml

      rm -f ${path.module}/${var.cluster-name}-${var.name}-ig-spec.yml

      ${var.nodeup-url-env} ${var.aws-profile-env-override} kops --state=s3://${var.kops-state-bucket} \
        update cluster ${var.cluster-name} --yes

      KOPS_FEATURE_FLAGS="+DrainAndValidateRollingUpdate" \
      ${var.nodeup-url-env} ${var.aws-profile-env-override} kops --state=s3://${var.kops-state-bucket} \
        rolling-update cluster ${var.cluster-name} \
          --node-interval="${var.update-interval}m" ${var.automatic-rollout == "true" ? "--yes" : ""}\
          --instance-group="${var.name}"

      rmdir ${path.root}/.kops-ig-lock
EOF
  }

  depends_on = ["null_resource.ig"]
}
