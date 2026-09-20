# One Unity Catalog catalog per environment (dev/qa/prod).
# "OPEN" isolation means any workspace attached to the metastore can use it.
# On Free Edition there's only one workspace anyway, but OPEN is also the
# right default for when you later bind prod to its own workspace, per the
# plan's metastore-sharing approach.
resource "databricks_catalog" "this" {
  name           = var.catalog_name
  comment        = var.catalog_comment
  isolation_mode = "OPEN"

  # Deleting a catalog with objects in it fails by default. force_destroy
  # lets `terraform destroy` clean up a throwaway dev/learning catalog.
  force_destroy = true

  lifecycle {
    # storage_root is auto-assigned by Databricks for Default Storage
    # catalogs (Free Edition serverless workspaces) and is force-new if
    # changed. We never set it ourselves, so without this, Terraform sees
    # "real value -> null" on every plan and wants to destroy/recreate the
    # catalog. Ignoring it tells Terraform: this field is managed by
    # Databricks, not by us — leave it alone.
    ignore_changes = [storage_root]
  }
}

# One schema resource per entry in var.schemas (bronze, silver, gold by
# default). for_each over a set means each schema is tracked individually
# in state — safe to add/remove one later without touching the others.
resource "databricks_schema" "this" {
  for_each = toset(var.schemas)

  catalog_name = databricks_catalog.this.name
  name         = each.value
  comment      = "${each.value} layer for ${var.catalog_name}"
  force_destroy = true
}

# The managed volume your Dagster asset uploads raw files into, and that
# dbt's bronze model reads from via read_files(). "MANAGED" means Databricks
# owns the underlying storage location for you (simplest option on Free
# Edition — no external storage credential to configure).
resource "databricks_volume" "landing" {
  catalog_name = databricks_catalog.this.name
  schema_name  = databricks_schema.this[var.landing_schema].name
  name         = var.landing_volume_name
  volume_type  = "MANAGED"
  comment      = "Landing zone for raw files pushed from Dagster"

  # Explicit dependency: Terraform can usually infer this from the
  # schema_name reference above, but being explicit here makes the
  # ordering obvious when you're reading the code, not just the graph.
  depends_on = [databricks_schema.this]
}
