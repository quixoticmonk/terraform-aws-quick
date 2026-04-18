mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/mock"
      user_id    = "AIDAMOCK"
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
  name_prefix = "test"
  region      = "us-west-2"
}

run "no_opt_in_resources_by_default" {
  command = plan

  assert {
    condition     = length(aws_quicksight_account_subscription.this) == 0
    error_message = "Subscription should not be created by default."
  }

  assert {
    condition     = length(aws_quicksight_theme.this) == 0
    error_message = "Theme should not be created by default."
  }

  assert {
    condition     = length(aws_iam_role.service) == 0
    error_message = "Service role should not be created by default."
  }

  assert {
    condition     = length(aws_quicksight_vpc_connection.this) == 0
    error_message = "VPC connection should not be created by default."
  }

  assert {
    condition     = length(aws_quicksight_group.this) == 0
    error_message = "Groups should not be created by default."
  }

  assert {
    condition     = length(aws_quicksight_key_registration.this) == 0
    error_message = "Key registration should not be created by default."
  }

  assert {
    condition     = length(aws_quicksight_ip_restriction.this) == 0
    error_message = "IP restriction should not be created by default."
  }

  assert {
    condition     = length(aws_quicksight_data_source.athena) == 0
    error_message = "No data sources should exist when data_sources is empty."
  }

  assert {
    condition     = length(aws_quicksight_data_set.custom_sql) == 0
    error_message = "No datasets should exist when datasets is empty."
  }

  assert {
    condition     = length(aws_quicksight_analysis.this) == 0
    error_message = "No analyses should exist when analyses is empty."
  }

  assert {
    condition     = length(aws_quicksight_dashboard.this) == 0
    error_message = "No dashboards should exist when dashboards is empty."
  }

  assert {
    condition     = length(aws_quicksight_folder.root) == 0
    error_message = "No root folders should exist when folders is empty."
  }

  assert {
    condition     = length(aws_quicksight_folder.child) == 0
    error_message = "No child folders should exist when folders is empty."
  }

  assert {
    condition     = length(aws_quicksight_folder_membership.this) == 0
    error_message = "No folder memberships should exist when folder_memberships is empty."
  }

  assert {
    condition     = length(aws_quicksight_refresh_schedule.this) == 0
    error_message = "No refresh schedules should exist when no dataset declares refresh_schedules."
  }
}

run "account_settings_created_by_default" {
  command = plan

  assert {
    condition     = length(aws_quicksight_account_settings.this) == 1
    error_message = "Account settings should be created by default (create_account_settings defaults to true)."
  }

  assert {
    condition     = aws_quicksight_account_settings.this[0].region == "us-west-2"
    error_message = "Account settings should be created in the module region."
  }

  assert {
    condition     = aws_quicksight_account_settings.this[0].termination_protection_enabled == false
    error_message = "Termination protection should default to false."
  }
}

run "account_settings_skipped_when_disabled" {
  command = plan

  variables {
    create_account_settings = false
  }

  assert {
    condition     = length(aws_quicksight_account_settings.this) == 0
    error_message = "Account settings should not be created when create_account_settings = false."
  }
}
