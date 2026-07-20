###############################################################################
# tf_mod_azuredevops_serviceendpoint_permissions — resource
#
# SINGLE-RESOURCE module: one azuredevops_serviceendpoint_permissions named
# `this`. main.tf is a thin, total renderer of the typed input — no business
# logic. serviceendpoint_id is passed through verbatim (null = project-wide
# service-connection permissions); timeouts is rendered only when set.
###############################################################################

resource "azuredevops_serviceendpoint_permissions" "this" {
 project_id = var.project_id
 serviceendpoint_id = var.serviceendpoint_id
 principal = var.principal
 permissions = var.permissions
 replace = var.replace

 dynamic "timeouts" {
 for_each = length([for v in values(var.timeouts): v if v != null]) > 0 ? [var.timeouts]: []
 content {
 create = try(timeouts.value.create, null)
 read = try(timeouts.value.read, null)
 update = try(timeouts.value.update, null)
 delete = try(timeouts.value.delete, null)
 }
 }
}
