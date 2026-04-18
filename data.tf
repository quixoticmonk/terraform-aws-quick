data "aws_caller_identity" "current" {}

data "aws_ssoadmin_instances" "this" {
  count = local.lookup_identity_center ? 1 : 0
}
