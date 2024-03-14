variable "metastore_id" {
  type        = string
  description = "Unity Catalog Metastore Id that is located in separate environment. Provide this value to associate Databricks Workspace with target Metastore"

  validation {
    condition     = length(var.metastore_id) == 36
    error_message = "Create Metastore or connect to existing one in Init Layer using Private Endpoint. In case Unity Catalog is not required, remove 'databricks_catalog' variable from tfvars file."
  }
}

# Metastore grants
variable "metastore_grants" {
  type = set(object({
    principal  = string
    privileges = list(string)
  }))
  description = "Permissions to give on metastore to user, group or service principal"
  default     = []
}

variable "catalog" {
  type = map(object({
    catalog_grants         = optional(map(list(string)))
    catalog_owner          = optional(string)         # Username/groupname/sp application_id of the catalog owner.
    catalog_storage_root   = optional(string)         # Location in cloud storage where data for managed tables will be stored
    catalog_isolation_mode = optional(string, "OPEN") # Whether the catalog is accessible from all workspaces or a specific set of workspaces. Can be ISOLATED or OPEN.
    catalog_comment        = optional(string)         # User-supplied free-form text
    catalog_properties     = optional(map(string))    # Extensible Catalog Tags.
    schema_name            = optional(list(string))   # List of Schema names relative to parent catalog.
    schema_grants          = optional(map(list(string)))
    schema_owner           = optional(string) # Username/groupname/sp application_id of the schema owner.
    schema_comment         = optional(string)
    schema_properties      = optional(map(string))
  }))
  description = "Map of catalog name and its parameters"
  default     = {}
}

variable "isolated_unmanaged_catalog_bindings" {
  type = list(object({
    catalog_name = string                                      # Name of ISOLATED catalog
    binding_type = optional(string, "BINDING_TYPE_READ_WRITE") # Binding mode. Possible values are BINDING_TYPE_READ_ONLY, BINDING_TYPE_READ_WRITE
  }))
  description = "List of objects with parameters to configure Catalog Bindings"
  default     = []
}

variable "workspace_id" {
  type        = string
  description = "ID of the target workspace."
  default     = null
}
