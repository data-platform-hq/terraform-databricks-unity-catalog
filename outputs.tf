output "metastore_id" {
  value       = var.create_metastore ? databricks_metastore.this[0].id : ""
  description = "Unity Catalog Metastore Id"
}

output "data_lake_gen2_file_system_id" {
  value       = var.create_metastore ? azurerm_storage_data_lake_gen2_filesystem.this[0].id : ""
  description = "The ID of the Data Lake Gen2 File System."
}
