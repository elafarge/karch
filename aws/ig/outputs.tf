output "created" {
  value = null_resource.ig-update.id
}

output "ig-spec" {
  value = yamlencode(local.ig_spec)
}
