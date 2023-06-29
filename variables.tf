variable "env" {
  type        = string
  description = "Environment name"
}

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
  description = "Permissions to give on metastore to group"
  default     = []
}

variable "catalog" {
  type = map(object({
    catalog_grants     = optional(map(list(string)))
    catalog_comment    = optional(string)
    catalog_properties = optional(map(string))
    schema_name        = optional(list(string))
    schema_grants      = optional(map(list(string)))
    schema_comment     = optional(string)
    schema_properties  = optional(map(string))
  }))
  description = "Map of catalog name and its parameters"
  default     = {}
}
