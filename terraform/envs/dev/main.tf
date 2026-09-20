terraform {
  required_version = ">= 1.5"

  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.55"
    }
  }
}

# Empty block on purpose: the provider reads DATABRICKS_HOST and
# DATABRICKS_TOKEN from your shell environment. Nothing sensitive
# ever gets written into a .tf file this way.
provider "databricks" {}

module "dev_env" {
  source = "../../modules/databricks_env"

  catalog_name    = "dev"
  catalog_comment = "Synthetic-data environment for local development and CI"
}

output "dev_catalog" {
  value = module.dev_env.catalog_name
}

output "dev_schemas" {
  value = module.dev_env.schema_names
}

output "dev_landing_volume_path" {
  value = module.dev_env.landing_volume_path
}
