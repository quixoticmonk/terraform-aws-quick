################################################################################
# Datasets
################################################################################

resource "aws_quicksight_data_set" "custom_sql" {
  for_each = { for k, v in var.datasets : k => v if v.source_type == "custom_sql" }

  data_set_id = "${var.name_prefix}-${each.key}"
  import_mode = each.value.import_mode
  name        = "${var.name_prefix}-${each.key}"
  region      = var.region

  physical_table_map {
    physical_table_map_id = each.key

    custom_sql {
      data_source_arn = local.data_source_arns[each.value.data_source_key]
      name            = each.key
      sql_query       = each.value.sql_query

      dynamic "columns" {
        for_each = each.value.columns

        content {
          name = columns.value.name
          type = columns.value.type
        }
      }
    }
  }

  dynamic "permissions" {
    for_each = local.dataset_permissions_per_entry[each.key]

    content {
      actions   = permissions.value
      principal = permissions.key
    }
  }

  lifecycle {
    precondition {
      condition     = contains(keys(local.data_source_arns), each.value.data_source_key)
      error_message = "Dataset references a data_source_key that is not defined in var.data_sources."
    }
  }
}

resource "aws_quicksight_data_set" "relational" {
  for_each = { for k, v in var.datasets : k => v if v.source_type == "relational_table" }

  data_set_id = "${var.name_prefix}-${each.key}"
  import_mode = each.value.import_mode
  name        = "${var.name_prefix}-${each.key}"
  region      = var.region

  physical_table_map {
    physical_table_map_id = each.key

    relational_table {
      catalog         = each.value.catalog
      data_source_arn = local.data_source_arns[each.value.data_source_key]
      name            = each.value.table_name
      schema          = each.value.schema

      dynamic "input_columns" {
        for_each = each.value.columns

        content {
          name = input_columns.value.name
          type = input_columns.value.type
        }
      }
    }
  }

  dynamic "permissions" {
    for_each = local.dataset_permissions_per_entry[each.key]

    content {
      actions   = permissions.value
      principal = permissions.key
    }
  }

  lifecycle {
    precondition {
      condition     = contains(keys(local.data_source_arns), each.value.data_source_key)
      error_message = "Dataset references a data_source_key that is not defined in var.data_sources."
    }
  }
}

resource "aws_quicksight_data_set" "s3_source" {
  for_each = { for k, v in var.datasets : k => v if v.source_type == "s3_source" }

  data_set_id = "${var.name_prefix}-${each.key}"
  import_mode = each.value.import_mode
  name        = "${var.name_prefix}-${each.key}"
  region      = var.region

  physical_table_map {
    physical_table_map_id = each.key

    s3_source {
      data_source_arn = local.data_source_arns[each.value.data_source_key]

      upload_settings {
        contains_header = true
        delimiter       = each.value.s3_delimiter
        format          = each.value.s3_format
        start_from_row  = 1
        text_qualifier  = "DOUBLE_QUOTE"
      }

      dynamic "input_columns" {
        for_each = each.value.columns

        content {
          name = input_columns.value.name
          type = input_columns.value.type
        }
      }
    }
  }

  dynamic "permissions" {
    for_each = local.dataset_permissions_per_entry[each.key]

    content {
      actions   = permissions.value
      principal = permissions.key
    }
  }

  lifecycle {
    precondition {
      condition     = contains(keys(local.data_source_arns), each.value.data_source_key)
      error_message = "Dataset references a data_source_key that is not defined in var.data_sources."
    }
  }
}
