# Metastore grants
locals {
  mapped_metastore_grants = {
    for object in var.metastore_grants : object.principal => object
    if object.principal != null
  }
}

resource "databricks_grants" "metastore" {
  count = length(local.mapped_metastore_grants) != 0 ? 1 : 0

  metastore = var.metastore_id
  dynamic "grant" {
    for_each = local.mapped_metastore_grants
    content {
      principal  = grant.value.principal
      privileges = grant.value.privileges
    }
  }
}

# Catalog creation
resource "databricks_catalog" "this" {
  for_each = var.catalog

  metastore_id   = var.metastore_id
  name           = each.key
  owner          = each.value.catalog_owner
  storage_root   = each.value.catalog_storage_root
  isolation_mode = each.value.catalog_isolation_mode
  comment        = lookup(each.value, "catalog_comment", "default comment")
  properties     = lookup(each.value, "catalog_properties", {})
  force_destroy  = true
}

# Catalog grants
resource "databricks_grants" "catalog" {
  for_each = {
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

# Schema creation
locals {
  schema = flatten([
    for catalog, params in var.catalog : [
      for schema in params.schema_name : {
        catalog    = catalog,
        schema     = schema,
        comment    = lookup(params, "schema_comment", "default comment"),
        properties = lookup(params, "schema_properties", {})
        owner      = lookup(params, "schema_owner", null)
      }
    ] if params.schema_name != null
  ])
}

resource "databricks_schema" "this" {
  for_each = {
    for entry in local.schema : "${entry.catalog}.${entry.schema}" => entry
  }

  catalog_name  = databricks_catalog.this[each.value.catalog].name
  name          = each.value.schema
  owner         = each.value.owner
  comment       = each.value.comment
  properties    = each.value.properties
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
  for_each = {
    for entry in local.schema_grants : "${entry.catalog}.${entry.schema}.${entry.principal}" => entry
  }

  schema = databricks_schema.this["${each.value.catalog}.${each.value.schema}"].id
  grant {
    principal  = each.value.principal
    privileges = each.value.permission
  }
}

# ISOLATED Catalogs binding
resource "databricks_catalog_workspace_binding" "this" {
  for_each = {
    for object in var.isolated_unmanaged_catalog_bindings : object.catalog_name => object
  }

  workspace_id   = var.workspace_id
  securable_name = each.value.catalog_name
  binding_type   = each.value.binding_type
}
