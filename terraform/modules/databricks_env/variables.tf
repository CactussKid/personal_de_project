variable "catalog_name" {
  description = "Name of the Unity Catalog catalog for this environment (e.g. dev, qa, prod)"
  type        = string
}

variable "catalog_comment" {
  description = "Human-readable description shown in the Catalog Explorer UI"
  type        = string
  default     = "Environment catalog managed by Terraform"
}

variable "schemas" {
  description = "Schemas to create inside the catalog"
  type        = list(string)
  default     = ["bronze", "silver", "gold"]
}

variable "landing_schema" {
  description = "Which schema the landing volume lives in (must be one of var.schemas)"
  type        = string
  default     = "bronze"
}

variable "landing_volume_name" {
  description = "Name of the managed volume used for landing raw files"
  type        = string
  default     = "landing"
}
