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

resource "github_branch_protection" "main" {
  repository_id = github_repository.this.node_id
  pattern       = "main"

  required_pull_request_reviews {
    required_approving_review_count = 0
  }

  required_status_checks {
    strict   = true
    contexts = ["ci"]
  }

  enforce_admins = false
  allows_force_pushes = false
}

resource "github_branch" "qa" {
  repository = github_repository.this.name
  branch     = "qa"
}

resource "github_branch_protection" "qa" {
  repository_id = github_repository.this.node_id
  pattern       = "qa"

  required_pull_request_reviews {
    required_approving_review_count = 0
  }

  allows_force_pushes = false

  depends_on = [github_branch.qa]
}

resource "github_repository_environment" "qa" {
  repository  = github_repository.this.name
  environment = "qa"

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "qa_branch" {
  repository     = github_repository.this.name
  environment    = github_repository_environment.qa.environment
  branch_pattern = "qa"
}

resource "github_repository_environment" "prod" {
  repository  = github_repository.this.name
  environment = "prod"

  reviewers {
    users = [165947361] 
  }

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "prod_branch" {
  repository     = github_repository.this.name
  environment    = github_repository_environment.prod.environment
  branch_pattern = "main"
}