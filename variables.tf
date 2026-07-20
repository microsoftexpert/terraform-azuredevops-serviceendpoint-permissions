###############################################################################
# tf_mod_azuredevops_serviceendpoint_permissions — variables
#
# SINGLE-RESOURCE module wrapping azuredevops_serviceendpoint_permissions.this.
# Assigns service-connection (service endpoint) permissions to a GROUP principal,
# either for one specific endpoint or project-wide across all endpoints.
#
# Variable order: project_id (parent reference) → serviceendpoint_id (identity
# ref) → principal / permissions (the grant) → replace (optional config) →
# timeouts (universal tail).
###############################################################################

variable "project_id" {
 description = <<EOT
The ID of the Azure DevOps project whose service-endpoint permissions are being
assigned. IMMUTABLE — changing this forces destroy/recreate. Wire from
tf_mod_azuredevops_project (project_id output).
EOT
 type = string

 validation {
 condition = length(trimspace(var.project_id)) > 0
 error_message = "project_id must be a non-empty string."
 }
}

variable "serviceendpoint_id" {
 description = <<EOT
The ID of the specific service endpoint (service connection) to scope the
permissions to. IMMUTABLE — changing this forces destroy/recreate.

- Set to a single endpoint ID (e.g. the `service_endpoint_id` / `id` output of a
 tf_mod_azuredevops_serviceendpoint_* module) to manage the ACL for THAT endpoint.
- Leave null (default) to manage the PROJECT-WIDE service-endpoint permissions
 for the principal — i.e. the "Service connections" security node that governs
 all endpoints in the project (including who may Create new ones).
EOT
 type = string
 default = null
}

variable "principal" {
 description = <<EOT
The descriptor of the GROUP principal that receives the permissions. IMMUTABLE —
changing this forces destroy/recreate.

- Must be a GROUP descriptor (e.g. the `descriptor` output of
 tf_mod_azuredevops_group), NOT an individual user. The provider only supports
 group principals for this resource.
- Discover built-in group descriptors with the azuredevops_group data source.
EOT
 type = string

 validation {
 condition = length(trimspace(var.principal)) > 0
 error_message = "principal must be a non-empty group descriptor string."
 }
}

variable "permissions" {
 description = <<EOT
The service-endpoint permissions to assign to the principal, as a map of
ACTION => state. At least one entry is required.

{
 "<ACTION>" = "Allow" | "Deny" | "NotSet" # state is case-insensitive
}

Available ACTION keys (closed set):
 Use - Use service endpoint
 Administer - Full control over service endpoints
 Create - Create service endpoints
 ViewAuthorization - View authorizations
 ViewEndpoint - View service endpoint properties

Least-privilege: there is no default — every grant is explicit. Omit an action
(rather than setting "NotSet") to leave it inherited.
EOT
 type = map(string)

 validation {
 condition = length(var.permissions) > 0
 error_message = "permissions must contain at least one ACTION => state entry."
 }

 validation {
 condition = alltrue([
 for k in keys(var.permissions):
 contains(["use", "administer", "create", "viewauthorization", "viewendpoint"], lower(k))
 ])
 error_message = "permissions keys must be one of: Use, Administer, Create, ViewAuthorization, ViewEndpoint (case-insensitive)."
 }

 validation {
 condition = alltrue([
 for v in values(var.permissions): contains(["allow", "deny", "notset"], lower(v))
 ])
 error_message = "Every permissions value must be one of: Allow, Deny, NotSet (case-insensitive)."
 }
}

variable "replace" {
 description = <<EOT
Whether to replace (true) or merge (false) the principal's existing ACEs for this
securable.

- true (default): the supplied `permissions` map is the authoritative set — any
 action not listed is reset to its inherited/NotSet state.
- false: the supplied permissions are merged on top of whatever the principal
 already has, leaving unlisted actions untouched.
EOT
 type = bool
 default = true
}

variable "timeouts" {
 description = <<EOT
Optional Terraform operation timeouts for this resource.
{
 create = optional(string)
 read = optional(string)
 update = optional(string)
 delete = optional(string)
}
EOT
 type = object({
 create = optional(string)
 read = optional(string)
 update = optional(string)
 delete = optional(string)
 })
 default = {}
}
