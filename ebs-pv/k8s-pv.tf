resource "null_resource" "master-up" {
  // Let's wait for the Kubernetes API to be available
  provisioner "local-exec" {
    command = "echo \"Master available: ${var.master-up}', let's register our persistent volume ${var.name}\""
  }
}

resource "kubernetes_persistent_volume" "kubernetes-pv" {
  metadata {
    name = "${var.name}"
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    capacity {
      storage = "${var.size}Gi"
    }

    persistent_volume_reclaim_policy = "Retain"

    persistent_volume_source {
      aws_elastic_block_store {
        fs_type   = "${var.fs_type}"
        volume_id = "${aws_ebs_volume.ebs-pv.id}"
      }
    }
  }

  depends_on = ["null_resource.master-up"]
}
