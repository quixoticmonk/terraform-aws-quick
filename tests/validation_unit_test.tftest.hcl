variables {
  name_prefix = "test"
  region      = "us-west-2"
}

mock_provider "aws" {}

run "invalid_authentication_method" {
  command = plan

  variables {
    quicksight_authentication_method = "INVALID"
  }

  expect_failures = [
    var.quicksight_authentication_method,
  ]
}

run "invalid_edition" {
  command = plan

  variables {
    quicksight_edition = "FREE"
  }

  expect_failures = [
    var.quicksight_edition,
  ]
}

run "invalid_data_source_type" {
  command = plan

  variables {
    data_sources = {
      bad = {
        type = "MYSQL"
      }
    }
  }

  expect_failures = [
    var.data_sources,
  ]
}

run "invalid_dataset_import_mode" {
  command = plan

  variables {
    data_sources = {
      athena = { type = "ATHENA" }
    }
    datasets = {
      bad = {
        import_mode     = "CACHE"
        data_source_key = "athena"
        source_type     = "relational_table"
      }
    }
  }

  expect_failures = [
    var.datasets,
  ]
}

run "invalid_dataset_source_type" {
  command = plan

  variables {
    data_sources = {
      athena = { type = "ATHENA" }
    }
    datasets = {
      bad = {
        import_mode     = "SPICE"
        data_source_key = "athena"
        source_type     = "parquet"
      }
    }
  }

  expect_failures = [
    var.datasets,
  ]
}

run "invalid_theme_data_colors_too_few" {
  command = plan

  variables {
    theme_data_colors = ["#000000", "#111111", "#222222"]
  }

  expect_failures = [
    var.theme_data_colors,
  ]
}

run "invalid_kms_multiple_defaults" {
  command = plan

  variables {
    kms_key_arns = {
      "arn:aws:kms:us-west-2:123456789012:key/aaaa" = { default = true }
      "arn:aws:kms:us-west-2:123456789012:key/bbbb" = { default = true }
    }
  }

  expect_failures = [
    var.kms_key_arns,
  ]
}

run "invalid_dashboard_missing_dataset_ref" {
  command = plan

  variables {
    dashboards = {
      bad = {
        source_template_arn = "arn:aws:quicksight:us-west-2:123456789012:template/t"
        data_set_references = [
          { placeholder = "x" }, # neither data_set_key nor data_set_arn
        ]
      }
    }
  }

  expect_failures = [
    var.dashboards,
  ]
}

run "invalid_folder_membership_type" {
  command = plan

  variables {
    folder_memberships = [
      { folder_key = "f", member_type = "TEMPLATE", member_key = "x" },
    ]
  }

  expect_failures = [
    var.folder_memberships,
  ]
}

run "invalid_extra_permissions_role" {
  command = plan

  variables {
    data_sources = {
      lake = { type = "ATHENA" }
    }
    datasets = {
      bad = {
        import_mode     = "SPICE"
        data_source_key = "lake"
        source_type     = "relational_table"
        catalog         = "AwsDataCatalog"
        schema          = "x"
        table_name      = "y"
        columns         = [{ name = "c", type = "STRING" }]
        extra_permissions = [
          { principal_arn = "arn:aws:quicksight:...", role = "admin" }, # not owner/reader
        ]
      }
    }
  }

  expect_failures = [
    var.datasets,
  ]
}

run "refresh_schedule_rejected_on_direct_query" {
  command = plan

  variables {
    data_sources = {
      lake = { type = "ATHENA" }
    }
    datasets = {
      live = {
        import_mode     = "DIRECT_QUERY"
        data_source_key = "lake"
        source_type     = "custom_sql"
        sql_query       = "SELECT 1"
        refresh_schedules = {
          daily = {
            interval    = "DAILY"
            time_of_day = "03:00"
          }
        }
      }
    }
  }

  expect_failures = [
    aws_quicksight_refresh_schedule.this,
  ]
}

run "refresh_schedule_weekly_requires_day_of_week" {
  command = plan

  variables {
    data_sources = {
      lake = { type = "ATHENA" }
    }
    datasets = {
      sales = {
        import_mode     = "SPICE"
        data_source_key = "lake"
        source_type     = "relational_table"
        catalog         = "AwsDataCatalog"
        schema          = "x"
        table_name      = "y"
        columns         = [{ name = "c", type = "STRING" }]
        refresh_schedules = {
          weekly = {
            interval    = "WEEKLY"
            time_of_day = "03:00"
            # day_of_week missing
          }
        }
      }
    }
  }

  expect_failures = [
    aws_quicksight_refresh_schedule.this,
  ]
}
