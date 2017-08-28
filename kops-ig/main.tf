resource "aws_s3_bucket_object" "ig-spec" {
  bucket = "${var.kops-state-bucket}"
  key    = "/karch-specs/${var.cluster-name}/${var.name}-ig-spec.yml"

  content = "${data.template_file.ig-spec.rendered}"

  // On destroy, remove the cluster first :)
  provisioner "local-exec" {
    when    = "destroy"
    command = "kops --state=s3://${var.kops-state-bucket} delete ig --yes ${var.name}"
  }
}

resource "null_resource" "ig" {
  // Let's wait for the Kubernetes API to be available
  provisioner "local-exec" {
    command = "echo \"Master available: ${var.master-up}', let's use kops to create our instance group\""
  }

  // Let's dump the ig spec on disk
  provisioner "local-exec" {
    command = "echo \"${aws_s3_bucket_object.ig-spec.content}\" > ${path.module}/${var.cluster-name}-${var.name}-ig-spec.yml"
  }

  // Let's register our Kops cluster into remote state
  provisioner "local-exec" {
    command = <<EOF
      while test -f ${path.root}/.kops-ig-lock
      do
        echo "Waiting for other instance group update to finish"
        sleep $[ ( $RANDOM % 10 )  + 10 ]s
      done
      echo 'locked' > ${path.root}/.kops-ig-lock
      kops --state=s3://${var.kops-state-bucket} create -f ${path.module}/${var.cluster-name}-${var.name}-ig-spec.yml
      rm ${path.root}/.kops-ig-lock
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
    command = "echo \"${data.template_file.ig-spec.rendered}\" > ${path.module}/${var.cluster-name}-${var.name}-ig-spec.yml"
  }

  provisioner "local-exec" {
    command = <<EOF
      while test -f ${path.root}/.kops-ig-lock
      do
        echo "Waiting for other instance group update to finish"
        sleep $[ ( $RANDOM % 10 )  + 10 ]s
      done
      echo 'locked' > ${path.root}/.kops-ig-lock

      kops --state=s3://${var.kops-state-bucket} \
        replace -f ${path.module}/${var.cluster-name}-${var.name}-ig-spec.yml

      rm -f ${path.module}/${var.cluster-name}-${var.name}-ig-spec.yml

      kops --state=s3://${var.kops-state-bucket} \
        update cluster ${var.cluster-name} --yes

      KOPS_FEATURE_FLAGS="+DrainAndValidateRollingUpdate" \
      kops --state=s3://${var.kops-state-bucket} \
        rolling-update cluster ${var.cluster-name} \
          --node-interval="${var.update-interval}m" ${var.automatic-rollout == "true" ? "--yes" : ""}\
          --instance-group="${var.name}"

      rm ${path.root}/.kops-ig-lock
EOF
  }

  depends_on = ["null_resource.ig"]
}
