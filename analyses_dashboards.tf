################################################################################
# Analyses — from a source template
################################################################################

resource "aws_quicksight_analysis" "this" {
  for_each = var.analyses

  analysis_id = "${var.name_prefix}-${each.key}"
  name        = "${var.name_prefix}-${each.key}"
  region      = var.region
  theme_arn   = each.value.theme_arn != "" ? each.value.theme_arn : null

  source_entity {
    source_template {
      arn = each.value.source_template_arn

      dynamic "data_set_references" {
        for_each = each.value.data_set_references

        content {
          data_set_arn         = data_set_references.value.data_set_arn != "" ? data_set_references.value.data_set_arn : local.dataset_arns[data_set_references.value.data_set_key]
          data_set_placeholder = data_set_references.value.placeholder
        }
      }
    }
  }

  dynamic "permissions" {
    for_each = local.analysis_permissions_per_entry[each.key]

    content {
      actions   = permissions.value
      principal = permissions.key
    }
  }
}

################################################################################
# Dashboards — from a source template
################################################################################

resource "aws_quicksight_dashboard" "this" {
  for_each = var.dashboards

  dashboard_id        = "${var.name_prefix}-${each.key}"
  name                = "${var.name_prefix}-${each.key}"
  region              = var.region
  theme_arn           = each.value.theme_arn != "" ? each.value.theme_arn : null
  version_description = each.value.version_description

  source_entity {
    source_template {
      arn = each.value.source_template_arn

      dynamic "data_set_references" {
        for_each = each.value.data_set_references

        content {
          data_set_arn         = data_set_references.value.data_set_arn != "" ? data_set_references.value.data_set_arn : local.dataset_arns[data_set_references.value.data_set_key]
          data_set_placeholder = data_set_references.value.placeholder
        }
      }
    }
  }

  dynamic "permissions" {
    for_each = local.dashboard_permissions_per_entry[each.key]

    content {
      actions   = permissions.value
      principal = permissions.key
    }
  }
}
