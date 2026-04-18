variable "brand_assets" {
  description = "Map of S3 object key to local file path and content type. Files must exist on disk before plan."
  type = map(object({
    source_path  = string
    content_type = optional(string, "image/png")
  }))
}

variable "bucket_name" {
  description = "Override for the brand assets bucket name. Leave empty to derive it from name_prefix + account + region."
  type        = string
  default     = ""
}

variable "name_prefix" {
  description = "Prefix for all resource names."
  type        = string
}

variable "region" {
  description = "AWS region for the bucket and QuickSight resources."
  type        = string
}
