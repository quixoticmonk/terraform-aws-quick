################################################################################
# VPC Connection (optional)
################################################################################

data "aws_vpc" "this" {
  count = var.create_vpc_connection ? 1 : 0

  id = var.vpc_id
}

resource "aws_security_group" "vpc_connection" {
  count = var.create_vpc_connection ? 1 : 0

  description = "QuickSight VPC connection egress"
  name        = "${var.name_prefix}-quick-vpc"
  region      = var.region
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "vpc_connection_https" {
  count = var.create_vpc_connection ? 1 : 0

  cidr_ipv4         = data.aws_vpc.this[0].cidr_block
  description       = "HTTPS to VPC"
  from_port         = 443
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.vpc_connection[0].id
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "vpc_connection_redshift" {
  count = var.create_vpc_connection ? 1 : 0

  cidr_ipv4         = data.aws_vpc.this[0].cidr_block
  description       = "Redshift"
  from_port         = 5439
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.vpc_connection[0].id
  to_port           = 5439
}

resource "aws_iam_role" "vpc_connection" {
  count = var.create_vpc_connection ? 1 : 0

  name               = "${var.name_prefix}-quick-vpc"
  assume_role_policy = data.aws_iam_policy_document.quicksight_assume[0].json
}

data "aws_iam_policy_document" "vpc_connection" {
  count = var.create_vpc_connection ? 1 : 0

  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:ModifyNetworkInterfaceAttribute",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "vpc_connection" {
  count = var.create_vpc_connection ? 1 : 0

  name   = "vpc-network-interface"
  policy = data.aws_iam_policy_document.vpc_connection[0].json
  role   = aws_iam_role.vpc_connection[0].id
}

resource "aws_quicksight_vpc_connection" "this" {
  count = var.create_vpc_connection ? 1 : 0

  name               = "${var.name_prefix}-quick-vpc"
  region             = var.region
  role_arn           = aws_iam_role.vpc_connection[0].arn
  security_group_ids = [aws_security_group.vpc_connection[0].id]
  subnet_ids         = var.subnet_ids
  vpc_connection_id  = "${var.name_prefix}-quick-vpc"
}
