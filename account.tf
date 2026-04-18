################################################################################
# QuickSight Account
################################################################################

resource "aws_quicksight_account_subscription" "this" {
  count = var.create_subscription ? 1 : 0

  account_name          = "${var.name_prefix}-quick"
  authentication_method = var.quicksight_authentication_method
  edition               = var.quicksight_edition
  notification_email    = var.notification_email
  region                = var.region

  admin_group                      = var.admin_group != "" ? [var.admin_group] : null
  author_group                     = var.author_group != "" ? [var.author_group] : null
  iam_identity_center_instance_arn = local.needs_identity_center ? local.identity_center_instance_arn : null
  reader_group                     = var.reader_group != "" ? [var.reader_group] : null

  lifecycle {
    precondition {
      condition     = !local.needs_identity_center || local.identity_center_instance_arn != ""
      error_message = "quicksight_authentication_method = IAM_IDENTITY_CENTER requires an Identity Center instance. Provide iam_identity_center_instance_arn or enable lookup_identity_center_instance (the AWS account must already have an Identity Center instance — Terraform cannot create one)."
    }
  }
}

resource "aws_quicksight_account_settings" "this" {
  count = var.create_account_settings ? 1 : 0

  region                         = var.region
  termination_protection_enabled = var.termination_protection_enabled

  depends_on = [aws_quicksight_account_subscription.this]
}
