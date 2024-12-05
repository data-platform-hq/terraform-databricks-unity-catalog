# Databricks Unity Catalog Terraform module
Terraform module for creation Databricks Unity Catalog

## Usage
This module manages Unity Catalog resources like Catalogs, Schemas. In addition, it is possible to manage permissions within Metastore, Catalog and Schemas.
```hcl
# Configure Databricks Provider
data "azurerm_databricks_workspace" "example" {
  name                = "example-workspace"
  resource_group_name = "example-rg"
}

provider "databricks" {
  alias                       = "workspace"
  host                        = data.databricks_workspace.example.workspace_url
  azure_workspace_resource_id = data.databricks_workspace.example.id
}

locals {
  catalog_config = [

    # Catalog w/o grants
    {
      catalog_name = "catalog_with_no_grants"
    },

    # Catalog with grants
    {
      catalog_name = "catalog_with_grants"
      catalog_grants = [
        { principal = "account users", privileges = ["USE_CATALOG", "APPLY_TAG", "CREATE_SCHEMA", "SELECT"] }
      ]
    },

    # Catalog with grants and schemas
    {
      catalog_name = "catalog_with_schemas"
      catalog_grants = [{ principal = "account users", privileges = ["USE_CATALOG", "APPLY_TAG", "SELECT"] }]
      schema_configs = [
        { schema_name = "schema_01" },
        { schema_name = "schema_02" }
      ]
    },

    # Catalog with schemas where 'schema_01' and 'schema_02' have a default set of grants from 'schema_default_grants' parameter
    # and 'schema_03' has its own set of grants managed with 'schema_custom_grants' parameter
    {
      catalog_name = "catalog_custom_schema_grants"
      catalog_grants = [{ principal = "account users", privileges = ["USE_CATALOG", "APPLY_TAG"] }]
      schema_default_grants = [{ principal = "account users", privileges = ["CREATE_TABLE", "SELECT"] }]
      schema_configs = [
        { schema_name = "schema_01" },
        { schema_name = "schema_02" },
        { 
          schema_name = "schema_03", 
          schema_custom_grants = [
            { principal = "account users", privileges = ["CREATE_VOLUME", "READ_VOLUME", "WRITE_VOLUME", "SELECT"] },
          ]
        },
      ]
    },
  ]
}

# Prerequisite module.
# NOTE! It is required to assign Metastore to Workspace before creating Unity Catalog resources.
module "metastore_assignment" {
  source  = "data-platform-hq/metastore-assignment/databricks"
  version = "~> 1.0.0"

  workspace_id = data.databricks_workspace.example.id
  metastore_id = local.metastore_id

  providers = {
    databricks = databricks.workspace
  }
}

module "unity_catalog" {
  source  = "data-platform/unity-catalog/databricks"
  version = "~> 2.0.0"

  catalog_config = local.catalog_config

  providers = {
    databricks = databricks.workspace
  }
  
  depends_on = [module.metastore_assignment]
}
```
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.0.0 |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | ~>1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_databricks"></a> [databricks](#provider\_databricks) | ~>1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [databricks_catalog.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/catalog) | resource |
| [databricks_grants.catalog](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/grants) | resource |
| [databricks_grants.metastore](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/grants) | resource |
| [databricks_grants.schema](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/grants) | resource |
| [databricks_schema.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/schema) | resource |
| [databricks_workspace_binding.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/workspace_binding) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_catalog"></a> [catalog](#input\_catalog) | Map of catalog name and its parameters | <pre>map(object({<br/>    catalog_grants         = optional(map(list(string)))<br/>    catalog_owner          = optional(string)         # Username/groupname/sp application_id of the catalog owner.<br/>    catalog_storage_root   = optional(string)         # Location in cloud storage where data for managed tables will be stored<br/>    catalog_isolation_mode = optional(string, "OPEN") # Whether the catalog is accessible from all workspaces or a specific set of workspaces. Can be ISOLATED or OPEN.<br/>    catalog_comment        = optional(string)         # User-supplied free-form text<br/>    catalog_properties     = optional(map(string))    # Extensible Catalog Tags.<br/>    schema_name            = optional(list(string))   # List of Schema names relative to parent catalog.<br/>    schema_grants          = optional(map(list(string)))<br/>    schema_owner           = optional(string) # Username/groupname/sp application_id of the schema owner.<br/>    schema_comment         = optional(string)<br/>    schema_properties      = optional(map(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_isolated_unmanaged_catalog_bindings"></a> [isolated\_unmanaged\_catalog\_bindings](#input\_isolated\_unmanaged\_catalog\_bindings) | List of objects with parameters to configure Catalog Bindings | <pre>list(object({<br/>    catalog_name = string                                      # Name of ISOLATED catalog<br/>    binding_type = optional(string, "BINDING_TYPE_READ_WRITE") # Binding mode. Possible values are BINDING_TYPE_READ_ONLY, BINDING_TYPE_READ_WRITE<br/>  }))</pre> | `[]` | no |
| <a name="input_metastore_grants"></a> [metastore\_grants](#input\_metastore\_grants) | Permissions to give on metastore to user, group or service principal | <pre>set(object({<br/>    principal  = string<br/>    privileges = list(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_metastore_id"></a> [metastore\_id](#input\_metastore\_id) | Unity Catalog Metastore Id that is located in separate environment. Provide this value to associate Databricks Workspace with target Metastore | `string` | n/a | yes |
| <a name="input_workspace_id"></a> [workspace\_id](#input\_workspace\_id) | ID of the target workspace. | `string` | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

## License

Apache 2 Licensed. For more information please see [LICENSE](https://github.com/data-platform-hq/terraform-databricks-unity-catalog/tree/master/LICENSE)
