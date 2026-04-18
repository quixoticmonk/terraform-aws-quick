################################################################################
# Data Sources
################################################################################

resource "aws_quicksight_data_source" "redshift" {
  for_each = local.redshift_sources

  data_source_id = "${var.name_prefix}-${each.key}"
  name           = "${var.name_prefix}-${each.key}"
  region         = var.region
  type           = "REDSHIFT"

  credentials {
    secret_arn = each.value.credential_secret_arn
  }

  parameters {
    redshift {
      database = each.value.database
      host     = each.value.host
      port     = each.value.port
    }
  }

  dynamic "permission" {
    for_each = local.ds_permissions_per_entry[each.key]

    content {
      actions   = permission.value
      principal = permission.key
    }
  }

  ssl_properties {
    disable_ssl = false
  }

  dynamic "vpc_connection_properties" {
    for_each = each.value.use_vpc && var.create_vpc_connection ? [1] : []

    content {
      vpc_connection_arn = aws_quicksight_vpc_connection.this[0].arn
    }
  }
}

resource "aws_quicksight_data_source" "athena" {
  for_each = local.athena_sources

  data_source_id = "${var.name_prefix}-${each.key}"
  name           = "${var.name_prefix}-${each.key}"
  region         = var.region
  type           = "ATHENA"

  parameters {
    athena {
      work_group = each.value.work_group
    }
  }

  dynamic "permission" {
    for_each = local.ds_permissions_per_entry[each.key]

    content {
      actions   = permission.value
      principal = permission.key
    }
  }

  ssl_properties {
    disable_ssl = false
  }
}

resource "aws_quicksight_data_source" "postgresql" {
  for_each = local.postgresql_sources

  data_source_id = "${var.name_prefix}-${each.key}"
  name           = "${var.name_prefix}-${each.key}"
  region         = var.region
  type           = "POSTGRESQL"

  credentials {
    secret_arn = each.value.credential_secret_arn
  }

  parameters {
    postgresql {
      database = each.value.database
      host     = each.value.host
      port     = each.value.port
    }
  }

  dynamic "permission" {
    for_each = local.ds_permissions_per_entry[each.key]

    content {
      actions   = permission.value
      principal = permission.key
    }
  }

  ssl_properties {
    disable_ssl = false
  }
}

resource "aws_quicksight_data_source" "s3" {
  for_each = local.s3_sources

  data_source_id = "${var.name_prefix}-${each.key}"
  name           = "${var.name_prefix}-${each.key}"
  region         = var.region
  type           = "S3"

  parameters {
    s3 {
      manifest_file_location {
        bucket = each.value.s3_bucket
        key    = each.value.s3_key
      }

      role_arn = each.value.role_arn != "" ? each.value.role_arn : null
    }
  }

  dynamic "permission" {
    for_each = local.ds_permissions_per_entry[each.key]

    content {
      actions   = permission.value
      principal = permission.key
    }
  }
}
