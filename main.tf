locals {
  catalogs_config_mapped = { for object in var.catalog_config : object.catalog_name => object }

  schemas_config_mapped = {
    for config in flatten([for object in var.catalog_config : [for schema in object.schema_configs : {
      catalog       = object.catalog_name
      schema        = schema.schema_name
      schema_owner  = schema.schema_owner
      schema_grants = try(coalescelist(schema.schema_custom_grants, object.schema_default_grants), [])
    }]]) : "${config.catalog}:${config.schema}" => config
  }
}

# Catalog creation
resource "databricks_catalog" "this" {
  for_each = local.catalogs_config_mapped

  name           = each.value.catalog_name
  owner          = each.value.catalog_owner
  storage_root   = each.value.catalog_storage_root
  isolation_mode = each.value.catalog_isolation_mode
  comment        = lookup(each.value, "catalog_comment", "default comment")
  properties     = lookup(each.value, "catalog_properties", {})
  force_destroy  = true
}

# Catalog grants
resource "databricks_grants" "catalog" {
  for_each = { for k, v in local.catalogs_config_mapped : k => v if length(v.catalog_grants) != 0 }

  catalog = databricks_catalog.this[each.key].name

  dynamic "grant" {
    for_each = each.value.catalog_grants
    content {
      principal  = grant.value.principal
      privileges = grant.value.privileges
    }
  }
}

# Schema creation
resource "databricks_schema" "this" {
  for_each = local.schemas_config_mapped

  catalog_name  = databricks_catalog.this[each.value.catalog].name
  name          = each.value.schema
  owner         = each.value.schema_owner
  comment       = each.value.schema_comment
  properties    = each.value.schema_properties
  force_destroy = true
}

# Schema grants
resource "databricks_grants" "schema" {
  for_each = { for k, v in local.schemas_config_mapped : k => v if length(v.schema_grants) != 0 }

  schema = databricks_schema.this[each.key].id

  dynamic "grant" {
    for_each = each.value.schema_grants
    content {
      principal  = grant.value.principal
      privileges = grant.value.privileges
    }
  }
}

# ISOLATED Catalogs binding
resource "databricks_workspace_binding" "this" {
  for_each = { for object in var.isolated_unmanaged_catalog_bindings : object.catalog_name => object }

  workspace_id   = var.workspace_id
  securable_name = each.value.catalog_name
  binding_type   = each.value.binding_type
}
