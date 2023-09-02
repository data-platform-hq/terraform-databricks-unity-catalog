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
  metastore_id = "10000000-0000-0000-0000-0000000000"
  
  metastore_grants = [
    { principal = "<user1@email.com>", privileges = ["CREATE_CATALOG","CREATE_EXTERNAL_LOCATION"] }, 
    { principal = "<user2@epam.com>", privileges = ["CREATE_SHARE", "CREATE_RECIPIENT", "CREATE_PROVIDER"] }
  ]
  
  catalog = {
    example_catalog = {
      catalog_grants = {
        "example@username.com" = ["USE_CATALOG", "USE_SCHEMA", "CREATE_SCHEMA", "CREATE_TABLE", "SELECT", "MODIFY"]
      }
      schema_name = ["raw", "refined", "data_product"]
    }
  }
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
  version = "~> 1.1.0"

  env              = "example"
  metastore_id     = local.metastore_id
  metastore_grants = local.metastore_grants
  catalog          = local.catalog

  providers = {
    databricks = databricks.workspace
  }
  
  depends_on = [module.metastore_assignment]
}
```
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name                                                                      | Version   |
| ------------------------------------------------------------------------- | --------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform)    | >= 1.0.0  |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | >= 1.14.2 |


## Providers

| Name                                                          | Version   |
| ------------------------------------------------------------- | --------- |
| <a name="provider_databricks"></a> [databricks](#provider\_databricks) | 1.14.2 |


## Modules

No modules.

## Resources

| Name                                                                                                                                                    | Type     |
| ------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| [databricks_grants.metastore](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/grants)                               | resource |
| [databricks_catalog.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/catalog)                                  | resource |
| [databricks_grants.catalog](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/grants)                                 | resource |
| [databricks_schema.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/schema)                                    | resource |
| [databricks_grants.schema](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/grants)                                  | resource |


## Inputs

| Name                                                                                   | Description                                                                                     | Type           | Default | Required |
| -------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- | -------------- | ------- | :------: |
| <a name="input_env"></a> [env](#input\_project)| Environment name | `string`| n/a |   yes    |
| <a name="input_metastore_id"></a> [metastore\_id](#input\_metastore\_id)| Unity Catalog Metastore Id that is located in separate environment. Provide this value to associate Databricks Workspace with target Metastore| `string` | n/a |   yes    |
| <a name="input_metastore_grants"></a> [metastore\_grants](#input\_metastore\_grants)| Permissions to give on metastore to group | <pre>set(object({<br>  principal  = string<br>  privileges = list(string)<br>}))</pre>| [] |   no    |
| <a name="input_catalog"></a> [catalog](#input\_catalog)| Map of catalog name and its parameters | <pre>map(object({<br>  catalog_grants     = optional(map(list(string)))<br>  catalog_comment    = optional(string)<br>  catalog_properties = optional(map(string))<br>  schema_name        = optional(list(string))<br>  schema_grants      = optional(map(list(string)))<br>  schema_comment     = optional(string)<br>  schema_properties  = optional(map(string))<br>  catalog_owner      = optional(string)<br>  schema_owner       = optional(string)<br>}))</pre>|{} |  no  |


## Outputs

| Name                                                                       | Description                            |
| -------------------------------------------------------------------------- | -------------------------------------- |

No outputs.
<!-- END_TF_DOCS -->

## License

Apache 2 Licensed. For more information please see [LICENSE](https://github.com/data-platform-hq/terraform-databricks-unity-catalog/tree/master/LICENSE)
