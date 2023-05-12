variable "project" {
  type        = string
  description = "Project name"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "location" {
  type        = string
  description = "Azure location"
}

variable "suffix" {
  type        = string
  description = "Optional suffix that would be added to the end of resources names."
  default     = ""
}

# Unity Catalog variables
variable "create_metastore" {
  type        = bool
  description = "Boolean flag for Unity Catalog Metastore current in this environment. One Metastore per region"
  default     = true
}

variable "access_connector_id" {
  type        = string
  description = "Databricks Access Connector Id that lets you to connect managed identities to an Azure Databricks account. Provides an ability to access Unity Catalog with assigned identity"
  default     = ""
}

variable "storage_account_id" {
  type        = string
  description = "Storage Account Id where Unity Catalog Metastore would be provisioned"
  default     = ""
}

variable "storage_account_name" {
  type        = string
  description = "Storage Account Name where Unity Catalog Metastore would be provisioned"
  default     = ""
}

variable "external_metastore_id" {
  type        = string
  description = "Unity Catalog Metastore Id that is located in separate environment. Provide this value to associate Databricks Workspace with target Metastore"
  default     = ""
  validation {
    condition     = length(var.external_metastore_id) == 36 || length(var.external_metastore_id) == 0
    error_message = "UUID has to be either in nnnnnnnn-nnnn-nnnn-nnnn-nnnnnnnnnnnn format or empty string"
  }
}

variable "workspace_id" {
  type        = string
  description = "Id of Azure Databricks workspace"
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

variable "metastore_grants" {
  type        = map(list(string))
  description = "Permissions to give on metastore to group"
  default     = {}
  validation {
    condition = values(var.metastore_grants) != null ? alltrue([
      for item in toset(flatten([for group, params in var.metastore_grants : params if params != null])) : contains([
        "CREATE_CATALOG", "CREATE_EXTERNAL_LOCATION", "CREATE_SHARE", "CREATE_RECIPIENT", "CREATE_PROVIDER"
      ], item)
    ]) : true
    error_message = "Metastore permission validation. The only possible values for permissions are: CREATE_CATALOG, CREATE_EXTERNAL_LOCATION, CREATE_SHARE, CREATE_RECIPIENT, CREATE_PROVIDER"
  }
}
