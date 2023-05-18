# Azure Unity Catalog Terraform module
Terraform module for creation Azure Unity Catalog

## Usage
```hcl
# Prerequisite resources

# Configure Databricks Provider
data "azurerm_databricks_workspace" "example" {
  name                = "example-workspace"
  resource_group_name = "example-rg"
}

provider "databricks" {
  alias                       = "main"
  host                        = data.databricks_workspace.example.workspace_url
  azure_workspace_resource_id = data.databricks_workspace.example.id
}

# Databricks Access Connector (managed identity)
resource "azurerm_databricks_access_connector" "example" {
  name                = "example-resource"
  resource_group_name = "example-rg"
  location            = "eastus"

  identity {
    type = "SystemAssigned"
  }
}

# Storage Account
data "azurerm_storage_account" "example" {
  name                = "example-storage-account"
  resource_group_name = "example-rg"
}

locals {
  catalog = {
    example_catalog = {
      catalog_grants = {
        "example@username.com" = ["USE_CATALOG", "USE_SCHEMA", "CREATE_SCHEMA", "CREATE_TABLE", "SELECT", "MODIFY"]
      }
      schema_name = ["raw", "refined", "data_product"]
    }
  }
}

module "unity_catalog" {
  source = "../environment/modules/unity"

  project               = "datahq"
  env                   = "example"
  location              = "eastus"
  access_connector_id   = azurerm_databricks_access_connector.example.id
  storage_account_id    = data.azurerm_storage_account.example.id
  storage_account_name  = data.azurerm_storage_account.example.name
  catalog               = local.catalog

  providers = {
    databricks = databricks.main
  }
}
```
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name                                                                      | Version   |
| ------------------------------------------------------------------------- | --------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform)    | >= 1.0.0  |
| <a name="requirement_databricks"></a> [databricks](#requirement\_databricks) | >= 1.14.2  |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm)          | >= 3.40.0 |

## Providers

| Name                                                          | Version   |
| ------------------------------------------------------------- | --------- |
| <a name="provider_databricks"></a> [databricks](#provider\_databricks) | 1.14.2   |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm)          | 3.40.0  |

## Modules

No modules.

## Resources

| Name                                                                                                                                                    | Type     |
| ------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| [azurerm_storage_data_lake_gen2_filesystem.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_data_lake_gen2_filesystem) | resource |
| [databricks_metastore.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/metastore)                                          | resource |
| [databricks_grants.metastore](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/grants)                                           | resource |
| [databricks_metastore_data_access.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/metastore_data_access)                  | resource |
| [databricks_catalog.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/catalog)                                              | resource |
| [databricks_grants.catalog](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/grants)                                             | resource |
| [databricks_schema.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/sql_endpoint)                                          | resource |
| [databricks_grants.schema](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/schema)                                              | resource |

## Inputs

| Name                                                                                   | Description                                                                                     | Type           | Default | Required |
| -------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- | -------------- | ------- | :------: |
| <a name="input_project"></a> [project](#input\_project)                                | Project name                                                                                    | `string`       | n/a     |   yes    |
| <a name="input_env"></a> [env](#input\_env)                                            | Environment name                                                                                | `string`       | n/a     |   yes    |
| <a name="input_location"></a> [location](#input\_location)                             | Azure location                                                                                  | `string`       | n/a     |   yes    |
| <a name="input_suffix"></a> [suffix](#input\_suffix)                             | Optional suffix that would be added to the end of resources names. | `string`       | " "     |   no    |
| <a name="input_create_metastore"></a> [create\_metastore](#input\_create\_metastore)         | Boolean flag for Unity Catalog Metastore current in this environment. One Metastore per region | `bool`  | true  |   no    |
| <a name="input_access_connector_id"></a> [access\_connector\_id](#input\_access\_connector\_id) | Databricks Access Connector Id that lets you to connect managed identities to an Azure Databricks account. Provides an ability to access Unity Catalog with assigned identity  | `string` | " " |    no    |
| <a name="input_storage_account_id"></a> [storage\_account\_id](#input\_storage\_account\_id) | Storage Account Id where Unity Catalog Metastore would be provisioned | `string` | " "  |    no    |
| <a name="input_storage_account_name"></a> [storage\_account\_name](#input\_storage\_account\_name) | Storage Account Name where Unity Catalog Metastore would be provisioned   | `string` | " "   |    no    |
| <a name="input_external_metastore_id"></a> [external\_metastore\_id](#input\_external\_metastore\_id) | Unity Catalog Metastore Id that is located in separate environment. Provide this value to associate Databricks Workspace with target Metastore | `string` | " " | no |
| <a name="input_catalog"></a> [catalog](#input\_catalog)  | Map of objects which parameters refers to certain catalog and schema attributes | <pre> map(object({ <br>   catalog_grants     = optional(map(list(string))) <br>   catalog_comment    = optional(string) <br>   catalog_properties = optional(map(string)) <br>   schema_name        = optional(list(string)) <br>   schema_grants      = optional(map(list(string))) <br>   schema_comment     = optional(string) <br>   schema_properties  = optional(map(string))<br>})) </pre> | {} | no |
| <a name="input_metastore_grants"></a> [metastore\_grants](#input\_metastore\_grants) | Permissions to give on metastore to group  | `map(list(string))` | {} | no |
| <a name="input_custom_databricks_metastore_name"></a> [custom\_databricks\_metastore\_name](#input\_custom\_databricks\_metastore\_name) | The name to provide for your Databricks Metastore | `string` | null | no |

## Outputs

| Name                                                                       | Description                            |
| -------------------------------------------------------------------------- | -------------------------------------- |
| <a name="output_metastore_id"></a> [metastore\_id](#output\_metastore\_id)                                 | Unity Catalog Metastore Id. |
| <a name="output_data_lake_gen2_file_system_id"></a> [data\_lake\_gen2\_file\_syste_id](#output\_data\_lake\_gen2\_file\_syste_id)   | The ID of the Data Lake Gen2 File System.  |
<!-- END_TF_DOCS -->

## License

Apache 2 Licensed. For more information please see [LICENSE](https://github.com/data-platform-hq/terraform-databricks-unity-catalog/tree/master/LICENSE)
