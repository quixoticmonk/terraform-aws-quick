terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Convention: datasets/<key>/query.sql   → auto-loaded into sql_query when unset
#             datasets/<key>/columns.json → auto-loaded into columns when unset
# Inline values in var.datasets always take precedence over file-based fallbacks.
locals {
  datasets = {
    for k, v in var.datasets : k => merge(v, {
      sql_query = v.source_type == "custom_sql" && v.sql_query == "" ? try(file("${path.module}/datasets/${k}/query.sql"), "") : v.sql_query
      columns   = length(v.columns) == 0 ? try(jsondecode(file("${path.module}/datasets/${k}/columns.json")), []) : v.columns
    })
  }
}

module "quick" {
  source = "../.."

  name_prefix = var.name_prefix
  region      = var.region

  # Account + groups
  admin_group   = var.admin_group
  author_group  = var.author_group
  reader_group  = var.reader_group
  create_groups = var.create_groups

  # Theme
  create_theme = var.create_theme

  # Service role with scoped access
  create_service_role   = var.create_service_role
  s3_bucket_names       = var.s3_bucket_names
  redshift_cluster_arns = var.redshift_cluster_arns

  # VPC connection for private data sources
  create_vpc_connection = var.create_vpc_connection
  vpc_id                = var.vpc_id
  subnet_ids            = var.subnet_ids

  # Data sources and datasets are passed through from tfvars.
  # See terraform.tfvars.example for the map shape and how dataset.data_source_key
  # references a key in data_sources.
  data_sources = var.data_sources
  datasets     = local.datasets

  # Analyses and dashboards — only when create_analyses_and_dashboards = true.
  # Both use the same pre-authored template, wired to two datasets by key.
  analyses = var.create_analyses_and_dashboards ? {
    sales-overview = {
      source_template_arn = var.sales_template_arn
      data_set_references = [
        { placeholder = "orders", data_set_key = "orders_last_30d" },
        { placeholder = "traffic", data_set_key = "traffic_by_channel" },
      ]
    }
  } : {}

  dashboards = var.create_analyses_and_dashboards ? {
    sales-overview = {
      source_template_arn = var.sales_template_arn
      version_description = "Initial publish from Terraform"
      data_set_references = [
        { placeholder = "orders", data_set_key = "orders_last_30d" },
        { placeholder = "traffic", data_set_key = "traffic_by_channel" },
      ]
    }
  } : {}
}

output "data_source_arns" {
  description = "Map of data source key to ARN."
  value       = module.quick.data_source_arns
}

output "dataset_arns" {
  description = "Map of dataset key to ARN."
  value       = module.quick.dataset_arns
}

output "theme_arn" {
  description = "ARN of the custom theme."
  value       = module.quick.theme_arn
}

output "analysis_arns" {
  description = "Map of analysis key to ARN."
  value       = module.quick.analysis_arns
}

output "dashboard_arns" {
  description = "Map of dashboard key to ARN."
  value       = module.quick.dashboard_arns
}

output "vpc_connection_arn" {
  description = "ARN of the VPC connection."
  value       = module.quick.vpc_connection_arn
}
