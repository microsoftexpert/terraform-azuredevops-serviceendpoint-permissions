###############################################################################
# tf_mod_azuredevops_serviceendpoint_permissions — outputs
#
# Primary output is `id`. The remaining outputs are passthroughs of the
# securable's identity (project, endpoint, principal) for audit and access
# review. No secrets are involved — nothing here is sensitive.
###############################################################################

output "id" {
 description = "The ID of the service-endpoint permissions assignment."
 value = azuredevops_serviceendpoint_permissions.this.id
}

output "serviceendpoint_permissions_id" {
 description = "The service-endpoint permissions resource ID — the resource-specific identifier (same value as `id`) for downstream references and audit."
 value = azuredevops_serviceendpoint_permissions.this.id
}

output "project_id" {
 description = "The project ID the permissions assignment belongs to."
 value = azuredevops_serviceendpoint_permissions.this.project_id
}

output "serviceendpoint_id" {
 description = "The specific service endpoint ID the permissions are scoped to, or null when the assignment is project-wide across all service endpoints."
 value = try(azuredevops_serviceendpoint_permissions.this.serviceendpoint_id, null)
}

output "principal" {
 description = "The group principal descriptor the permissions were assigned to."
 value = azuredevops_serviceendpoint_permissions.this.principal
}
