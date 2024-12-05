variable "catalog_config" {
  type = list(object({

    # Catalog config
    catalog_name           = string
    catalog_owner          = optional(string)         # Username/groupname/sp application_id of the catalog owner.
    catalog_storage_root   = optional(string)         # Location in cloud storage where data for managed tables will be stored
    catalog_isolation_mode = optional(string, "OPEN") # Whether the catalog is accessible from all workspaces or a specific set of workspaces. Can be ISOLATED or OPEN.
    catalog_comment        = optional(string)         # User-supplied free-form text
    catalog_properties     = optional(map(string))    # Extensible Catalog Tags.
    catalog_grants = optional(list(object({           # List of objects to set catalog permissions
      principal  = string                             # Account level group name, user or service principal app ID
      privileges = list(string)
    })), [])

    # Schemas
    schema_default_grants = optional(list(object({ # Sets default grants for each schema created by 'schema_configs' block w/o 'schema_custom_grants' parameter set
      principal  = string                          # Account level group name, user or service principal app ID
      privileges = list(string)
    })), [])

    schema_configs = optional(list(object({
      schema_name       = string
      schema_owner      = optional(string)
      schema_comment    = optional(string)
      schema_properties = optional(map(string))
      schema_custom_grants = optional(list(object({ # Overwrites 'schema_default_grants'
        principal  = string                         # Account level group name, user or service principal app ID
        privileges = list(string)
      })), [])
    })), [])
  }))
  description = <<DESCRIPTION


  DESCRIPTION
  default     = []
}

variable "isolated_unmanaged_catalog_bindings" {
  type = list(object({
    catalog_name = string                                      # Name of ISOLATED catalog
    binding_type = optional(string, "BINDING_TYPE_READ_WRITE") # Binding mode. Possible values are BINDING_TYPE_READ_ONLY, BINDING_TYPE_READ_WRITE
  }))
  description = <<DESCRIPTION

  DESCRIPTION
  default     = []
}

variable "workspace_id" {
  type        = string
  description = "ID of the target workspace."
  default     = null
}
