variable "admin_group" {
  description = "QuickSight admin group name."
  type        = string
}

variable "author_group" {
  description = "QuickSight author group name."
  type        = string
}

variable "create_analyses_and_dashboards" {
  description = "Whether to publish the example analysis and dashboard from var.sales_template_arn."
  type        = bool
  default     = false
}

variable "create_groups" {
  description = "Create QuickSight groups in the default namespace."
  type        = bool
  default     = true
}

variable "create_service_role" {
  description = "Create the QuickSight service IAM role."
  type        = bool
  default     = true
}

variable "create_theme" {
  description = "Create a custom QuickSight theme."
  type        = bool
  default     = true
}

variable "create_vpc_connection" {
  description = "Create a QuickSight VPC connection."
  type        = bool
  default     = true
}

variable "data_sources" {
  description = <<-EOT
    Map of QuickSight data sources. The key is referenced from datasets (datasets.<name>.data_source_key).
    Supported types: REDSHIFT, ATHENA, POSTGRESQL, S3.
  EOT
  type = map(object({
    type                  = string
    credential_secret_arn = optional(string, "")
    database              = optional(string, "")
    host                  = optional(string, "")
    port                  = optional(number, 0)
    role_arn              = optional(string, "")
    s3_bucket             = optional(string, "")
    s3_key                = optional(string, "manifests/manifest.json")
    use_vpc               = optional(bool, false)
    work_group            = optional(string, "primary")
  }))
}

variable "datasets" {
  description = <<-EOT
    Map of QuickSight datasets. Each dataset's data_source_key MUST match a key in var.data_sources.
    source_type = custom_sql      → supply sql_query; columns optional
    source_type = relational_table → supply catalog/schema/table_name + columns (>= 1)
    source_type = s3_source       → references an S3-type data source; supply columns (>= 1)
  EOT
  type = map(object({
    import_mode     = string
    data_source_key = string
    source_type     = string
    sql_query       = optional(string, "")
    catalog         = optional(string, "")
    schema          = optional(string, "")
    table_name      = optional(string, "")
    s3_format       = optional(string, "CSV")
    s3_delimiter    = optional(string, ",")
    columns = optional(list(object({
      name = string
      type = string
    })), [])
  }))
}

variable "name_prefix" {
  description = "Prefix for all resource names."
  type        = string
}

variable "reader_group" {
  description = "QuickSight reader group name."
  type        = string
}

variable "redshift_cluster_arns" {
  description = "Redshift cluster ARNs granted to the service role."
  type        = list(string)
  default     = []
}

variable "region" {
  description = "AWS region for QuickSight resources."
  type        = string
}

variable "s3_bucket_names" {
  description = "S3 bucket names the service role can read."
  type        = list(string)
  default     = []
}

variable "sales_template_arn" {
  description = "ARN of a pre-authored QuickSight template used to publish the example analysis and dashboard. Leave empty when create_analyses_and_dashboards is false."
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnet IDs for the QuickSight VPC connection."
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for the QuickSight VPC connection."
  type        = string
}
