################################################################################
# Encryption — Customer-managed KMS key registration (optional)
################################################################################

resource "aws_quicksight_key_registration" "this" {
  count = var.create_key_registration ? 1 : 0

  region = var.region

  dynamic "key_registration" {
    for_each = var.kms_key_arns

    content {
      default_key = key_registration.value.default
      key_arn     = key_registration.key
    }
  }

  depends_on = [aws_quicksight_account_subscription.this]
}

################################################################################
# Account IP / VPC restrictions (optional)
################################################################################

resource "aws_quicksight_ip_restriction" "this" {
  count = var.create_ip_restriction ? 1 : 0

  enabled                              = var.ip_restriction_enabled
  ip_restriction_rule_map              = var.ip_restriction_cidrs
  region                               = var.region
  vpc_endpoint_id_restriction_rule_map = var.ip_restriction_vpc_endpoint_ids
  vpc_id_restriction_rule_map          = var.ip_restriction_vpc_ids

  depends_on = [aws_quicksight_account_subscription.this]
}
