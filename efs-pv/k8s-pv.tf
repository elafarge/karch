resource "null_resource" "master-up" {
  // Let's wait for the Kubernetes API to be available
  provisioner "local-exec" {
    command = "echo \"Master available: ${var.master-up}', let's register our persistent volume ${var.name}\""
  }
}

resource "kubernetes_persistent_volume" "kubernetes-pv" {
  metadata {
    name   = "${var.name}"
    labels = "${var.labels}"
  }

  spec {
    access_modes = ["ReadWriteMany"]

    capacity {
      storage = "${var.size}Gi"
    }

    persistent_volume_reclaim_policy = "Delete"

    persistent_volume_source {
      nfs {
        path   = "/${var.name}"
        server = "${var.efs-server-id}.efs.${data.aws_region.main.name}.amazonaws.com"
      }
    }
  }

  depends_on = ["null_resource.master-up"]
}
