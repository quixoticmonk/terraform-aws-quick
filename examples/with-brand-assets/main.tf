terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

locals {
  bucket_name = coalesce(var.bucket_name, "${var.name_prefix}-quick-assets-${data.aws_caller_identity.current.account_id}-${var.region}")
}

module "quick" {
  source = "../.."

  name_prefix  = var.name_prefix
  region       = var.region
  create_theme = true
}

################################################################################
# Brand assets bucket — hardened: BPA, versioning, KMS SSE, TLS-only policy
################################################################################

resource "aws_s3_bucket" "brand_assets" {
  bucket = local.bucket_name
}

resource "aws_s3_bucket_public_access_block" "brand_assets" {
  bucket = aws_s3_bucket.brand_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "brand_assets" {
  bucket = aws_s3_bucket.brand_assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "brand_assets" {
  bucket = aws_s3_bucket.brand_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

data "aws_iam_policy_document" "brand_assets_tls" {
  statement {
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.brand_assets.arn, "${aws_s3_bucket.brand_assets.arn}/*"]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}

resource "aws_s3_bucket_policy" "brand_assets" {
  bucket = aws_s3_bucket.brand_assets.id
  policy = data.aws_iam_policy_document.brand_assets_tls.json
}

resource "aws_s3_object" "brand_asset" {
  for_each = var.brand_assets

  bucket       = aws_s3_bucket.brand_assets.id
  content_type = each.value.content_type
  etag         = filemd5(each.value.source_path)
  key          = each.key
  source       = each.value.source_path
}

output "brand_assets_bucket" {
  description = "Name of the brand assets bucket."
  value       = aws_s3_bucket.brand_assets.id
}

output "brand_assets_s3_uris" {
  description = "Map of asset key to s3:// URI. Paste these into the QuickSight theme/branding console."
  value       = { for k, _ in aws_s3_object.brand_asset : k => "s3://${aws_s3_bucket.brand_assets.id}/${k}" }
}
