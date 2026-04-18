mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/mock"
      user_id    = "AIDAMOCK"
    }
  }

  mock_data "aws_ssoadmin_instances" {
    defaults = {
      arns               = ["arn:aws:sso:::instance/ssoins-mock"]
      identity_store_ids = ["d-mock"]
    }
  }

  mock_data "aws_vpc" {
    defaults = {
      id         = "vpc-mock"
      cidr_block = "10.0.0.0/16"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }
}

variables {
  name_prefix  = "test"
  region       = "us-west-2"
  admin_group  = "admins"
  author_group = "authors"
  reader_group = "readers"
}

run "theme_when_enabled" {
  command = plan

  variables {
    create_theme = true
  }

  assert {
    condition     = length(aws_quicksight_theme.this) == 1
    error_message = "Theme should be created when create_theme = true."
  }

  assert {
    condition     = aws_quicksight_theme.this[0].theme_id == "test-theme"
    error_message = "Theme ID should include the name prefix."
  }
}

run "service_role_when_enabled" {
  command = plan

  variables {
    create_service_role = true
    s3_bucket_names     = ["my-bucket"]
  }

  assert {
    condition     = length(aws_iam_role.service) == 1
    error_message = "Service role should be created when create_service_role = true."
  }

  assert {
    condition     = aws_iam_role.service[0].name == "test-quick-service"
    error_message = "Service role name should include the name prefix."
  }
}

run "groups_when_enabled" {
  command = plan

  variables {
    create_groups = true
  }

  assert {
    condition     = length(aws_quicksight_group.this) == 3
    error_message = "Three groups (admin, author, reader) should be created when create_groups = true."
  }
}

run "vpc_connection_when_enabled" {
  command = plan

  variables {
    create_vpc_connection = true
    vpc_id                = "vpc-mock"
    subnet_ids            = ["subnet-a", "subnet-b"]
  }

  assert {
    condition     = length(aws_quicksight_vpc_connection.this) == 1
    error_message = "VPC connection should be created when create_vpc_connection = true."
  }

  assert {
    condition     = length(aws_security_group.vpc_connection) == 1
    error_message = "VPC connection security group should be created."
  }

  assert {
    condition     = length(aws_iam_role.vpc_connection) == 1
    error_message = "VPC connection IAM role should be created."
  }
}

run "data_sources_partitioned_by_type" {
  command = plan

  variables {
    data_sources = {
      athena-primary = {
        type       = "ATHENA"
        work_group = "primary"
      }
      redshift-main = {
        type                  = "REDSHIFT"
        credential_secret_arn = "arn:aws:secretsmanager:us-west-2:123456789012:secret:x"
        database              = "dev"
        host                  = "cluster.example.com"
        port                  = 5439
      }
    }
  }

  assert {
    condition     = length(aws_quicksight_data_source.athena) == 1
    error_message = "One Athena data source should be created."
  }

  assert {
    condition     = length(aws_quicksight_data_source.redshift) == 1
    error_message = "One Redshift data source should be created."
  }

  assert {
    condition     = length(aws_quicksight_data_source.postgresql) == 0
    error_message = "No PostgreSQL data source should be created."
  }
}

run "datasets_routed_by_source_type" {
  command = plan

  variables {
    data_sources = {
      athena = { type = "ATHENA" }
    }
    datasets = {
      sales-sql = {
        import_mode     = "SPICE"
        data_source_key = "athena"
        source_type     = "custom_sql"
        sql_query       = "SELECT 1"
      }
      sales-table = {
        import_mode     = "DIRECT_QUERY"
        data_source_key = "athena"
        source_type     = "relational_table"
        catalog         = "AwsDataCatalog"
        schema          = "analytics"
        table_name      = "sales"
        columns = [
          { name = "order_id", type = "STRING" },
        ]
      }
    }
  }

  assert {
    condition     = length(aws_quicksight_data_set.custom_sql) == 1
    error_message = "One custom_sql dataset should be created."
  }

  assert {
    condition     = length(aws_quicksight_data_set.relational) == 1
    error_message = "One relational_table dataset should be created."
  }

  assert {
    condition     = length(aws_quicksight_data_set.s3_source) == 0
    error_message = "No s3_source dataset should be created."
  }
}

run "identity_center_explicit_arn" {
  command = plan

  variables {
    create_subscription              = true
    notification_email               = "ops@example.com"
    quicksight_authentication_method = "IAM_IDENTITY_CENTER"
    admin_group                      = "admins"
    author_group                     = "authors"
    reader_group                     = "readers"
    iam_identity_center_instance_arn = "arn:aws:sso:::instance/ssoins-supplied"
  }

  assert {
    condition     = aws_quicksight_account_subscription.this[0].iam_identity_center_instance_arn == "arn:aws:sso:::instance/ssoins-supplied"
    error_message = "Explicit Identity Center ARN should be passed through to the subscription."
  }

  assert {
    condition     = output.identity_center_instance_arn == "arn:aws:sso:::instance/ssoins-supplied"
    error_message = "Output should echo the explicit ARN."
  }
}

run "identity_center_auto_lookup" {
  command = plan

  variables {
    create_subscription              = true
    notification_email               = "ops@example.com"
    quicksight_authentication_method = "IAM_IDENTITY_CENTER"
    admin_group                      = "admins"
    author_group                     = "authors"
    reader_group                     = "readers"
  }

  assert {
    condition     = aws_quicksight_account_subscription.this[0].iam_identity_center_instance_arn == "arn:aws:sso:::instance/ssoins-mock"
    error_message = "Auto-lookup should resolve to the data-source ARN."
  }
}

run "identity_center_not_needed_for_iam_auth" {
  command = plan

  variables {
    create_subscription              = true
    notification_email               = "ops@example.com"
    quicksight_authentication_method = "IAM_AND_QUICKSIGHT"
  }

  assert {
    condition     = output.identity_center_instance_arn == ""
    error_message = "Identity Center ARN output should be empty when auth method does not require it."
  }
}

run "identity_center_missing_arn_fails" {
  command = plan

  variables {
    create_subscription              = true
    notification_email               = "ops@example.com"
    quicksight_authentication_method = "IAM_IDENTITY_CENTER"
    lookup_identity_center_instance  = false
  }

  expect_failures = [
    aws_quicksight_account_subscription.this,
  ]
}

run "key_registration_when_enabled" {
  command = plan

  variables {
    create_key_registration = true
    kms_key_arns = {
      "arn:aws:kms:us-west-2:123456789012:key/aaaa" = { default = true }
      "arn:aws:kms:us-west-2:123456789012:key/bbbb" = {}
    }
  }

  assert {
    condition     = length(aws_quicksight_key_registration.this) == 1
    error_message = "Key registration should be created when create_key_registration = true."
  }
}

run "ip_restriction_when_enabled" {
  command = plan

  variables {
    create_ip_restriction = true
    ip_restriction_cidrs = {
      "10.0.0.0/8" = "Corp network"
    }
  }

  assert {
    condition     = length(aws_quicksight_ip_restriction.this) == 1
    error_message = "IP restriction should be created when create_ip_restriction = true."
  }

  assert {
    condition     = aws_quicksight_ip_restriction.this[0].enabled == true
    error_message = "IP restriction should be enabled by default."
  }
}

run "analysis_from_template" {
  command = plan

  variables {
    data_sources = {
      athena = { type = "ATHENA" }
    }
    datasets = {
      sales = {
        import_mode     = "SPICE"
        data_source_key = "athena"
        source_type     = "relational_table"
        catalog         = "AwsDataCatalog"
        schema          = "analytics"
        table_name      = "sales"
        columns         = [{ name = "order_id", type = "STRING" }]
      }
    }
    analyses = {
      sales-overview = {
        source_template_arn = "arn:aws:quicksight:us-west-2:123456789012:template/sales-template"
        data_set_references = [
          { placeholder = "sales", data_set_key = "sales" },
        ]
      }
    }
  }

  assert {
    condition     = length(aws_quicksight_analysis.this) == 1
    error_message = "Analysis should be created when analyses map has an entry."
  }

  assert {
    condition     = aws_quicksight_analysis.this["sales-overview"].analysis_id == "test-sales-overview"
    error_message = "Analysis ID should be name_prefix + map key."
  }
}

run "dashboard_from_template" {
  command = plan

  variables {
    data_sources = {
      athena = { type = "ATHENA" }
    }
    datasets = {
      sales = {
        import_mode     = "SPICE"
        data_source_key = "athena"
        source_type     = "relational_table"
        catalog         = "AwsDataCatalog"
        schema          = "analytics"
        table_name      = "sales"
        columns         = [{ name = "order_id", type = "STRING" }]
      }
    }
    dashboards = {
      sales-overview = {
        source_template_arn = "arn:aws:quicksight:us-west-2:123456789012:template/sales-template"
        data_set_references = [
          { placeholder = "sales", data_set_key = "sales" },
        ]
      }
    }
  }

  assert {
    condition     = length(aws_quicksight_dashboard.this) == 1
    error_message = "Dashboard should be created when dashboards map has an entry."
  }

  assert {
    condition     = aws_quicksight_dashboard.this["sales-overview"].version_description == "Managed by Terraform"
    error_message = "Version description should default to Managed by Terraform."
  }
}

run "folder_tree_and_membership" {
  command = plan

  variables {
    data_sources = {
      athena = { type = "ATHENA" }
    }
    datasets = {
      sales = {
        import_mode     = "SPICE"
        data_source_key = "athena"
        source_type     = "relational_table"
        catalog         = "AwsDataCatalog"
        schema          = "analytics"
        table_name      = "sales"
        columns         = [{ name = "order_id", type = "STRING" }]
      }
    }
    folders = {
      bi        = { name = "BI" }
      bi-orders = { name = "Orders", parent_key = "bi" }
    }
    folder_memberships = [
      { folder_key = "bi-orders", member_type = "DATASET", member_key = "sales" },
    ]
  }

  assert {
    condition     = length(aws_quicksight_folder.root) == 1
    error_message = "One root folder should be created."
  }

  assert {
    condition     = length(aws_quicksight_folder.child) == 1
    error_message = "One child folder should be created."
  }

  assert {
    condition     = length(aws_quicksight_folder_membership.this) == 1
    error_message = "One membership should be created."
  }

  assert {
    condition     = aws_quicksight_folder_membership.this["bi-orders:DATASET:sales"].member_id == "test-sales"
    error_message = "member_id should resolve to name_prefix + dataset key."
  }
}

run "extra_permissions_adds_principal" {
  command = plan

  variables {
    admin_group  = "admins"
    author_group = "authors"
    reader_group = "readers"

    data_sources = {
      lake = { type = "ATHENA" }
    }
    datasets = {
      sales = {
        import_mode     = "SPICE"
        data_source_key = "lake"
        source_type     = "relational_table"
        catalog         = "AwsDataCatalog"
        schema          = "analytics"
        table_name      = "sales"
        columns         = [{ name = "order_id", type = "STRING" }]
        extra_permissions = [
          { principal_arn = "arn:aws:quicksight:us-west-2:123456789012:group/default/marketing", role = "reader" },
        ]
      }
    }
  }

  # Base grants add 3 principals (admin/author/reader); +1 extra principal = 4.
  assert {
    condition     = length(local.dataset_permissions_per_entry["sales"]) == 4
    error_message = "extra_permissions should add one principal on top of the three base principals."
  }

  assert {
    condition     = contains(keys(local.dataset_permissions_per_entry["sales"]), "arn:aws:quicksight:us-west-2:123456789012:group/default/marketing")
    error_message = "Extra principal ARN should appear in the merged permission map."
  }
}

run "extra_permissions_owner_beats_reader_on_same_principal" {
  command = plan

  variables {
    admin_group  = "admins"
    author_group = "authors"
    reader_group = "readers"

    data_sources = {
      lake = { type = "ATHENA" }
    }
    datasets = {
      sales = {
        import_mode     = "SPICE"
        data_source_key = "lake"
        source_type     = "relational_table"
        catalog         = "AwsDataCatalog"
        schema          = "analytics"
        table_name      = "sales"
        columns         = [{ name = "order_id", type = "STRING" }]
        # admin_group is ALREADY base=owner. Re-supplying it as reader should be ignored.
        extra_permissions = [
          { principal_arn = "arn:aws:quicksight:us-west-2:123456789012:group/default/admins", role = "reader" },
        ]
      }
    }
  }

  # admin principal should retain owner actions (dataset_role_actions.owner has 10 items; reader has 3).
  assert {
    condition     = length(local.dataset_permissions_per_entry["sales"]["arn:aws:quicksight:us-west-2:123456789012:group/default/admins"]) == 10
    error_message = "Admin (base=owner) should stay owner even when extra_permissions lists them as reader."
  }
}

run "extra_permissions_upgrades_reader_to_owner" {
  command = plan

  variables {
    admin_group  = "admins"
    author_group = "authors"
    reader_group = "readers"

    data_sources = {
      lake = { type = "ATHENA" }
    }
    datasets = {
      sales = {
        import_mode     = "SPICE"
        data_source_key = "lake"
        source_type     = "relational_table"
        catalog         = "AwsDataCatalog"
        schema          = "analytics"
        table_name      = "sales"
        columns         = [{ name = "order_id", type = "STRING" }]
        # reader_group is base=reader. Extra=owner for the same principal should upgrade it.
        extra_permissions = [
          { principal_arn = "arn:aws:quicksight:us-west-2:123456789012:group/default/readers", role = "owner" },
        ]
      }
    }
  }

  assert {
    condition     = length(local.dataset_permissions_per_entry["sales"]["arn:aws:quicksight:us-west-2:123456789012:group/default/readers"]) == 10
    error_message = "Reader group should be upgraded to owner when extra_permissions supplies role=owner for the same principal."
  }
}

run "theme_with_optional_blocks" {
  command = plan

  variables {
    create_theme        = true
    theme_font_families = ["Amazon Ember", "sans-serif"]
    theme_ui_color_palette = {
      accent             = "#219FD7"
      accent_foreground  = "#FFFFFF"
      primary_background = "#F5F5F3"
    }
    theme_sheet_tile_border_show = true
    theme_sheet_gutter_show      = true
    theme_sheet_margin_show      = false
  }

  assert {
    condition     = length(aws_quicksight_theme.this) == 1
    error_message = "Theme should be created."
  }
}

run "refresh_schedule_on_spice_dataset" {
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
        schema          = "analytics"
        table_name      = "sales"
        columns         = [{ name = "order_id", type = "STRING" }]
        refresh_schedules = {
          daily = {
            interval    = "DAILY"
            time_of_day = "03:00"
            timezone    = "UTC"
          }
        }
      }
    }
  }

  assert {
    condition     = length(aws_quicksight_refresh_schedule.this) == 1
    error_message = "One refresh schedule should be created."
  }

  assert {
    condition     = aws_quicksight_refresh_schedule.this["sales:daily"].schedule_id == "daily"
    error_message = "schedule_id should equal the schedule map key."
  }
}
