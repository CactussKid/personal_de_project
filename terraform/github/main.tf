terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  owner = "CactussKid"
}

resource "github_repository" "this" {
  name        = "personal_de_project"
  description = "Dagster + dbt + Databricks learning pipeline"
  visibility  = "private"

  has_issues   = true
  has_projects = false
  has_wiki     = false

  delete_branch_on_merge = true

  auto_init = false   # <- changed from true
}