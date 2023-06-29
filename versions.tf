terraform {
  required_version = ">=1.0.0"

  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = ">=1.14.2"
    }
  }
}
