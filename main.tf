locals {
  # This optional suffix is added to the end of resource names. 
  suffix                    = length(var.suffix) == 0 ? "" : "-${var.suffix}"
  databricks_metastore_name = var.custom_databricks_metastore_name == null ? "meta-${var.project}-${var.env}-${var.location}${local.suffix}" : var.custom_databricks_metastore_name
}

resource "azurerm_storage_data_lake_gen2_filesystem" "this" {
  count = var.create_metastore ? 1 : 0

  name               = "meta-${var.project}-${var.env}"
  storage_account_id = var.storage_account_id

  lifecycle {
    precondition {
      condition = alltrue([
        for variable in [var.storage_account_id, var.access_connector_id, var.storage_account_name] : false if length(variable) == 0
      ])
      error_message = "To create Metastore in a Region it is required to provide proper values for these variables: access_connector_id, storage_account_id, storage_account_name"
    }
  }

}

resource "databricks_metastore" "this" {
  count = var.create_metastore ? 1 : 0

  name          = local.databricks_metastore_name
  storage_root  = format("abfss://%s@%s.dfs.core.windows.net/", azurerm_storage_data_lake_gen2_filesystem.this[0].name, var.storage_account_name)
  force_destroy = true
}

resource "databricks_grants" "metastore" {
  for_each = alltrue([!var.create_metastore, length(var.external_metastore_id) == 0]) ? {} : {
    for k, v in var.metastore_grants : k => v
    if v != null
  }

  metastore = length(var.external_metastore_id) == 0 ? databricks_metastore.this[0].id : var.external_metastore_id
  grant {
    principal  = each.key
    privileges = each.value
  }
}

resource "databricks_metastore_data_access" "this" {
  count = var.create_metastore ? 1 : 0

  metastore_id = databricks_metastore.this[0].id
  name         = "data-access-${var.project}-${var.env}-${var.location}${local.suffix}"
  azure_managed_identity {
    access_connector_id = var.access_connector_id
  }
  is_default = true
}

resource "databricks_metastore_assignment" "this" {
  count = alltrue([!var.create_metastore, length(var.external_metastore_id) == 0, !var.metastore_assignment_enabled]) ? 0 : 1

  workspace_id         = var.workspace_id
  metastore_id         = length(var.external_metastore_id) == 0 ? databricks_metastore.this[0].id : var.external_metastore_id
  default_catalog_name = "hive_metastore"
}

# Catalog
resource "databricks_catalog" "this" {
  for_each = alltrue([!var.create_metastore, length(var.external_metastore_id) == 0]) ? {} : var.catalog

  metastore_id  = length(var.external_metastore_id) == 0 ? databricks_metastore.this[0].id : var.external_metastore_id
  name          = each.key
  comment       = lookup(each.value, "catalog_comment", "default comment")
  properties    = merge(lookup(each.value, "catalog_properties", {}), { env = var.env })
  force_destroy = true

  depends_on = [databricks_metastore_assignment.this[0]]
}

# Catalog grants
resource "databricks_grants" "catalog" {
  for_each = alltrue([!var.create_metastore, length(var.external_metastore_id) == 0]) ? {} : {
    for name, params in var.catalog : name => params.catalog_grants
    if params.catalog_grants != null
  }

  catalog = databricks_catalog.this[each.key].name
  dynamic "grant" {
    for_each = each.value
    content {
      principal  = grant.key
      privileges = grant.value
    }
  }
}

# Schema
locals {
  schema = flatten([
    for catalog, params in var.catalog : [
      for schema in params.schema_name : {
        catalog    = catalog,
        schema     = schema,
        comment    = lookup(params, "schema_comment", "default comment"),
        properties = lookup(params, "schema_properties", {})
      }
    ] if params.schema_name != null
  ])
}

resource "databricks_schema" "this" {
  for_each = alltrue([!var.create_metastore, length(var.external_metastore_id) == 0]) ? {} : {
    for entry in local.schema : "${entry.catalog}.${entry.schema}" => entry
  }

  catalog_name  = databricks_catalog.this[each.value.catalog].name
  name          = each.value.schema
  comment       = each.value.comment
  properties    = merge(each.value.properties, { env = var.env })
  force_destroy = true
}

# Schema grants
locals {
  schema_grants = flatten([
    for catalog, params in var.catalog : [for schema in params.schema_name : [for principal in flatten(keys(params.schema_grants)) : {
      catalog    = catalog,
      schema     = schema,
      principal  = principal,
      permission = flatten(values(params.schema_grants)),
    }]] if params.schema_grants != null
  ])
}

resource "databricks_grants" "schema" {
  for_each = alltrue([!var.create_metastore, length(var.external_metastore_id) == 0]) ? {} : {
    for entry in local.schema_grants : "${entry.catalog}.${entry.schema}.${entry.principal}" => entry
  }

  schema = databricks_schema.this["${each.value.catalog}.${each.value.schema}"].id
  grant {
    principal  = each.value.principal
    privileges = each.value.permission
  }
}
