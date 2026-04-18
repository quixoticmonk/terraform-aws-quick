# Brand assets example

QuickSight reads custom branding images (logo, favicon) from S3. The AWS API has no "upload a logo" operation — you upload the file to S3 and reference the `s3://` URI in the QuickSight branding configuration.

This example stands up:

- The QuickSight module (theme enabled, nothing else)
- A hardened S3 bucket for the assets (public-access-block, versioning, `aws:kms` SSE, TLS-only bucket policy)
- `aws_s3_object` uploads for every entry in `var.brand_assets`

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars — point source_path entries at real image files
mkdir -p assets
cp /path/to/your/logo.png    assets/logo.png
cp /path/to/your/favicon.png assets/favicon.png

terraform init
terraform apply
terraform output brand_assets_s3_uris
```

Use the emitted URIs when you configure the QuickSight account-level branding (currently console-only — no Terraform resource manages the `UpdateAccountCustomization` API for logo/favicon).

## Why this lives in an example, not the module

- The bucket and objects are **consumer-specific** (their own image files, their own bucket naming).
- The module stays focused on QuickSight API resources.
- Consumers who don't need custom branding don't pay for an extra bucket.
