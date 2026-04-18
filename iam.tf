################################################################################
# Service IAM role (optional)
################################################################################

data "aws_iam_policy_document" "quicksight_assume" {
  count = var.create_service_role || var.create_vpc_connection ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["quicksight.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "service" {
  count = var.create_service_role ? 1 : 0

  name               = "${var.name_prefix}-quick-service"
  assume_role_policy = data.aws_iam_policy_document.quicksight_assume[0].json
}

data "aws_iam_policy_document" "service" {
  count = var.create_service_role ? 1 : 0

  dynamic "statement" {
    for_each = length(var.s3_bucket_names) > 0 ? [1] : []

    content {
      actions = ["s3:GetObject", "s3:ListBucket"]
      resources = flatten([
        for name in var.s3_bucket_names : [
          "arn:aws:s3:::${name}",
          "arn:aws:s3:::${name}/*",
        ]
      ])
    }
  }

  statement {
    actions = [
      "athena:BatchGetQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetWorkGroup",
      "athena:ListQueryExecutions",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution",
    ]
    resources = ["arn:aws:athena:${var.region}:${local.account_id}:workgroup/*"]
  }

  statement {
    actions   = ["redshift:DescribeClusters", "redshift-serverless:GetCredentials"]
    resources = ["*"]
  }

  statement {
    actions = ["redshift:GetClusterCredentials"]
    resources = length(var.redshift_cluster_arns) > 0 ? [
      for arn in var.redshift_cluster_arns : "${arn}/*"
    ] : ["arn:aws:redshift:${var.region}:${local.account_id}:dbuser:*/*"]
  }

  statement {
    actions = [
      "redshift-data:DescribeStatement",
      "redshift-data:ExecuteStatement",
      "redshift-data:GetStatementResult",
      "redshift-data:ListStatements",
    ]
    resources = length(var.redshift_cluster_arns) > 0 ? var.redshift_cluster_arns : ["arn:aws:redshift:${var.region}:${local.account_id}:cluster:*"]
  }

  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:${var.region}:${local.account_id}:secret:*"]
  }
}

resource "aws_iam_role_policy" "service" {
  count = var.create_service_role ? 1 : 0

  name   = "data-access"
  policy = data.aws_iam_policy_document.service[0].json
  role   = aws_iam_role.service[0].id
}
