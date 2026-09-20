output "catalog_name" {
  description = "Name of the created catalog"
  value       = databricks_catalog.this.name
}

output "schema_names" {
  description = "Full list of schemas created in this catalog"
  value       = [for s in databricks_schema.this : s.name]
}

output "landing_volume_path" {
  description = "Fully qualified UC path to the landing volume, e.g. for use in Dagster/dbt config"
  value       = "/Volumes/${databricks_catalog.this.name}/${var.landing_schema}/${var.landing_volume_name}"
}
