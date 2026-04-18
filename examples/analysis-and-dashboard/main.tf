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

module "quick" {
  source = "../.."

  name_prefix  = var.name_prefix
  region       = var.region
  admin_group  = var.admin_group
  author_group = var.author_group
  reader_group = var.reader_group

  data_sources = {
    lake = {
      type       = "ATHENA"
      work_group = "primary"
    }
  }

  datasets = {
    orders = {
      import_mode     = "SPICE"
      data_source_key = "lake"
      source_type     = "relational_table"
      catalog         = "AwsDataCatalog"
      schema          = "storefront"
      table_name      = "orders"
      columns = [
        { name = "order_id", type = "STRING" },
        { name = "customer_id", type = "STRING" },
        { name = "order_total", type = "DECIMAL" },
      ]
    }
  }

  # Both the analysis and the dashboard come from the same source template.
  # The template's dataset placeholder `orders_placeholder` is bound to this
  # deployment's `orders` dataset by key.
  analyses = {
    orders-overview = {
      source_template_arn = var.orders_template_arn
      data_set_references = [
        { placeholder = "orders_placeholder", data_set_key = "orders" },
      ]
    }
  }

  dashboards = {
    orders-overview = {
      source_template_arn = var.orders_template_arn
      version_description = "Published from Terraform"
      data_set_references = [
        { placeholder = "orders_placeholder", data_set_key = "orders" },
      ]

      # Executives get owner; marketing just gets to view.
      # These are additive on top of the module-level admin/author/reader grants.
      extra_permissions = [
        { principal_arn = "arn:aws:quicksight:us-west-2:111111111111:group/default/execs", role = "owner" },
        { principal_arn = "arn:aws:quicksight:us-west-2:111111111111:group/default/marketing-readers", role = "reader" },
      ]
    }
  }
}

output "analysis_arn" {
  description = "ARN of the published analysis."
  value       = module.quick.analysis_arns["orders-overview"]
}

output "dashboard_arn" {
  description = "ARN of the published dashboard."
  value       = module.quick.dashboard_arns["orders-overview"]
}

output "dataset_arn" {
  description = "ARN of the backing dataset."
  value       = module.quick.dataset_arns["orders"]
}
