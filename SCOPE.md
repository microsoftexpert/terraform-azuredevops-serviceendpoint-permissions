# SCOPE — terraform-azuredevops-serviceendpoint-permissions

Single-resource module. Manages one Azure DevOps **service-endpoint permissions** assignment —
a single ACE on the project's `ServiceEndpoints` security namespace
(ID `49b48001-ca20-4adc-8111-5b60c903a50c`), granting a **group** principal a typed set of
service-connection permissions either for one specific endpoint or project-wide.

## In scope
- `azuredevops_serviceendpoint_permissions.this`

## Out of scope (consumed by ID / managed elsewhere)
- `azuredevops_serviceendpoint_*` — the service connections themselves (sibling modules
  `terraform-azuredevops-serviceendpoint-azure` / `_scm` / `_containers` / `_artifacts` / `_security`
  / `_generic`). This module sets permissions on an endpoint; it does not create it.
- `azuredevops_project` — the owning project (sibling `terraform-azuredevops-project`).
- `azuredevops_group` — the principal being granted (sibling `terraform-azuredevops-group`, or the
  `azuredevops_group` data source for built-in groups). Only the group **descriptor** is consumed.
- Pipeline-level service-connection authorization (`azuredevops_pipeline_authorization` /
  per-pipeline "Open access" / "Restrict access") — a separate concern, not modelled here.
- Cross-project service-connection **sharing** — an org-level manual action, not a provider resource.

## Consumes
| Input | Type | Source module |
|---|---|---|
| `project_id` | string | `terraform-azuredevops-project` (`project_id` output) — **IMMUTABLE** |
| `serviceendpoint_id` | string | `terraform-azuredevops-serviceendpoint-*` (`service_endpoint_id` / `id`), optional — **IMMUTABLE**; `null` ⇒ project-wide |
| `principal` | string | `terraform-azuredevops-group` (`descriptor`) or `azuredevops_group` data source — **IMMUTABLE**; **group** only |
| `permissions` | map(string) | Caller — keys ∈ {Use, Administer, Create, ViewAuthorization, ViewEndpoint}; states ∈ {Allow, Deny, NotSet} |
| `replace` | bool | Caller — `true` (default) replace / `false` merge |

## Required Azure DevOps scopes / auth
| Scope / Role | PAT scope | Service-principal role | Required for |
|---|---|---|---|
| Service connection security | Service Connections (Read, Query & Manage) (`vso.serviceendpoint_manage`) | **Endpoint Administrators** (project group) — or **Project Administrators** | Reading/writing the ACE on the `ServiceEndpoints` namespace for a specific endpoint |
| Project-level endpoint security | Service Connections (Read, Query & Manage) | **Project Administrators** | Editing project-wide endpoint security (when `serviceendpoint_id` is omitted), incl. the `Create` right |
| Project read | Project and Team (Read) | Project member (Reader) | Resolving `project_id` |
| Principal lookup | Graph (Read) | Project / Reader | Resolving the group `descriptor` (via the `azuredevops_group` data source) |

> ⚠️ **Project-level (all-endpoints) security requires Project Administrators.** Omitting
> `serviceendpoint_id` targets the project's service-connection node, which governs every
> endpoint and the project-only `Create` right — Azure DevOps requires **Project Administrators**
> membership to change project-level resource permissions. Scoping to a single `serviceendpoint_id`
> requires only **Administrator** on that endpoint (e.g. **Endpoint Administrators**). The default
> role assignments are: `[project]\Endpoint Administrators` ⇒ Administrator, `[project]\Endpoint
> Creators` ⇒ Creator.

## Emits
| Output | Description | Typically consumed by |
|---|---|---|
| `id` / `serviceendpoint_permissions_id` | The permissions assignment ID (primary output) | Audit / access-review inventory; downstream references |
| `project_id` | Owning project ID | Sibling project-scoped modules; audit |
| `serviceendpoint_id` | Scoped endpoint ID, or `null` when project-wide | Correlation back to the endpoint module |
| `principal` | The granted group descriptor | Audit / access review |

> No sensitive outputs — this resource exposes no secrets, tokens, or keys. The secrets live on
> the endpoint resources, not on their ACLs. `principal` is a non-secret group descriptor.

## Provider gotchas (discovered during authoring)
- **Project-scoped:** `project_id` is **required** — this is not an org-scoped resource.
- **Three immutable fields:** `project_id`, `serviceendpoint_id`, and `principal` are force-new —
  changing any destroys/recreates the ACE. Labelled `# IMMUTABLE` in the variable heredocs.
- **Group principals only:** the provider accepts a **group** `descriptor`, not individual users.
- **Closed permission-key set:** valid keys are exactly `Use`, `Administer`, `Create`,
  `ViewAuthorization`, `ViewEndpoint` (validated, case-insensitive). States are `Allow`/`Deny`/`NotSet`.
- **`serviceendpoint_id` is optional and dual-scope:** set ⇒ one endpoint; `null` ⇒ the project-level
  node (all endpoints + `Create`). Same five actions at both scopes; object roles inherit from project.
- **`replace` semantics:** `true` (default) is authoritative — unlisted actions reset to inherited/
  `NotSet`; `false` merges onto existing ACEs. Authoritative is the safer default for drift-free ACLs.
- **No default `permissions`:** least-privilege — at least one explicit `ACTION => state` entry required.
- **Eventual consistency:** newly created endpoints/groups may be briefly unreadable; the provider's
  default timeouts absorb this. `timeouts` (create/read/update/delete) is exposed.
- **No secrets, no `tags`:** carries no credentials (those live on the endpoints) and Azure DevOps
  resources don't support azurerm-style tags.
- **Import:** the provider does not document an import syntax for this `*_permissions` resource —
  manage the ACE declaratively (recreate via configuration rather than `terraform import`).
