variable "admin_group" {
  description = "QuickSight admin group name for owner permissions on data sources and datasets."
  type        = string
  default     = ""
}

variable "analyses" {
  description = <<-EOT
    Map of QuickSight analyses to create from a source template.
    Each entry supplies a template ARN and a list of dataset references
    (placeholder → dataset key in var.datasets OR an explicit ARN).
    Only source_template mode is supported; author the template elsewhere.
  EOT
  type = map(object({
    source_template_arn = string
    theme_arn           = optional(string, "")
    data_set_references = list(object({
      placeholder  = string
      data_set_key = optional(string, "")
      data_set_arn = optional(string, "")
    }))
    extra_permissions = optional(list(object({
      principal_arn = string
      role          = string # "owner" or "reader"
    })), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for _, a in var.analyses : alltrue([
        for r in a.data_set_references : (r.data_set_key != "" || r.data_set_arn != "")
      ])
    ])
    error_message = "Each analyses.*.data_set_references entry must supply either data_set_key or data_set_arn."
  }

  validation {
    condition     = alltrue(flatten([for a in var.analyses : [for p in a.extra_permissions : contains(["owner", "reader"], p.role)]]))
    error_message = "analyses.*.extra_permissions[].role must be 'owner' or 'reader'."
  }
}

variable "author_group" {
  description = "QuickSight author group name for write permissions on data sources and datasets."
  type        = string
  default     = ""
}

variable "create_account_settings" {
  description = "Whether to manage aws_quicksight_account_settings. Set false when consuming an existing QuickSight account to avoid overwriting termination protection."
  type        = bool
  default     = true
}

variable "create_groups" {
  description = "Whether to create QuickSight groups (admin, author, reader) in the default namespace."
  type        = bool
  default     = false
}

variable "create_ip_restriction" {
  description = "Whether to manage QuickSight account IP/VPC restrictions via aws_quicksight_ip_restriction."
  type        = bool
  default     = false
}

variable "create_key_registration" {
  description = "Whether to register customer-managed KMS keys for QuickSight encryption via aws_quicksight_key_registration."
  type        = bool
  default     = false
}

variable "create_service_role" {
  description = "Whether to create the QuickSight service IAM role with scoped policies for S3, Athena, Redshift, and Secrets Manager."
  type        = bool
  default     = false
}

variable "create_subscription" {
  description = "Whether to create a new QuickSight account subscription. Set false when a subscription already exists."
  type        = bool
  default     = false
}

variable "create_theme" {
  description = "Whether to create a custom QuickSight theme."
  type        = bool
  default     = false
}

variable "create_vpc_connection" {
  description = "Whether to create a QuickSight VPC connection (security group, IAM role, and VPC connection) for private data source access."
  type        = bool
  default     = false
}

variable "dashboards" {
  description = <<-EOT
    Map of QuickSight dashboards to publish from a source template.
    Each entry supplies a template ARN and a list of dataset references
    (placeholder → dataset key in var.datasets OR an explicit ARN).
    Only source_template mode is supported; author the template elsewhere.
  EOT
  type = map(object({
    source_template_arn = string
    theme_arn           = optional(string, "")
    version_description = optional(string, "Managed by Terraform")
    data_set_references = list(object({
      placeholder  = string
      data_set_key = optional(string, "")
      data_set_arn = optional(string, "")
    }))
    extra_permissions = optional(list(object({
      principal_arn = string
      role          = string # "owner" or "reader"
    })), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for _, d in var.dashboards : alltrue([
        for r in d.data_set_references : (r.data_set_key != "" || r.data_set_arn != "")
      ])
    ])
    error_message = "Each dashboards.*.data_set_references entry must supply either data_set_key or data_set_arn."
  }

  validation {
    condition     = alltrue(flatten([for d in var.dashboards : [for p in d.extra_permissions : contains(["owner", "reader"], p.role)]]))
    error_message = "dashboards.*.extra_permissions[].role must be 'owner' or 'reader'."
  }
}

variable "data_sources" {
  description = "Map of QuickSight data sources. Key becomes the data source ID suffix. Types: REDSHIFT, ATHENA, POSTGRESQL, S3."
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
    extra_permissions = optional(list(object({
      principal_arn = string
      role          = string # "owner" or "reader"
    })), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for ds in var.data_sources : contains(["REDSHIFT", "ATHENA", "POSTGRESQL", "S3"], ds.type)])
    error_message = "Data source type must be one of REDSHIFT, ATHENA, POSTGRESQL, or S3."
  }

  validation {
    condition     = alltrue(flatten([for ds in var.data_sources : [for p in ds.extra_permissions : contains(["owner", "reader"], p.role)]]))
    error_message = "data_sources.*.extra_permissions[].role must be 'owner' or 'reader'."
  }
}

variable "datasets" {
  description = "Map of QuickSight datasets. Key becomes the dataset ID suffix. source_type: custom_sql, relational_table, or s3_source."
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
    extra_permissions = optional(list(object({
      principal_arn = string
      role          = string # "owner" or "reader"
    })), [])
    refresh_schedules = optional(map(object({
      interval     = string                           # MINUTE15 | MINUTE30 | HOURLY | DAILY | WEEKLY | MONTHLY
      refresh_type = optional(string, "FULL_REFRESH") # FULL_REFRESH | INCREMENTAL_REFRESH
      time_of_day  = optional(string, "")             # HH:MM — required for all intervals except HOURLY / MINUTE*
      timezone     = optional(string, "UTC")
      day_of_week  = optional(string, "") # required when interval = WEEKLY
      day_of_month = optional(string, "") # required when interval = MONTHLY
      start_after  = optional(string, "") # YYYY-MM-DDTHH:MM:SS
    })), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for d in var.datasets : contains(["SPICE", "DIRECT_QUERY"], d.import_mode)])
    error_message = "Dataset import_mode must be SPICE or DIRECT_QUERY."
  }

  validation {
    condition     = alltrue([for d in var.datasets : contains(["custom_sql", "relational_table", "s3_source"], d.source_type)])
    error_message = "Dataset source_type must be custom_sql, relational_table, or s3_source."
  }

  validation {
    condition     = alltrue([for d in var.datasets : d.source_type == "custom_sql" || length(d.columns) > 0])
    error_message = "Datasets with source_type relational_table or s3_source require at least one column in columns."
  }

  validation {
    condition     = alltrue(flatten([for d in var.datasets : [for p in d.extra_permissions : contains(["owner", "reader"], p.role)]]))
    error_message = "datasets.*.extra_permissions[].role must be 'owner' or 'reader'."
  }

  validation {
    condition     = alltrue(flatten([for d in var.datasets : [for s in d.refresh_schedules : contains(["MINUTE15", "MINUTE30", "HOURLY", "DAILY", "WEEKLY", "MONTHLY"], s.interval)]]))
    error_message = "datasets.*.refresh_schedules.*.interval must be one of MINUTE15, MINUTE30, HOURLY, DAILY, WEEKLY, MONTHLY."
  }

  validation {
    condition     = alltrue(flatten([for d in var.datasets : [for s in d.refresh_schedules : contains(["FULL_REFRESH", "INCREMENTAL_REFRESH"], s.refresh_type)]]))
    error_message = "datasets.*.refresh_schedules.*.refresh_type must be FULL_REFRESH or INCREMENTAL_REFRESH."
  }
}

variable "folder_memberships" {
  description = <<-EOT
    List of folder membership bindings. Each entry places a module-managed
    dataset/analysis/dashboard into a folder declared in var.folders.
    member_type must be DATASET, ANALYSIS, or DASHBOARD.
    folder_key must match a key in var.folders.
    member_key must match a key in var.datasets / var.analyses / var.dashboards
    depending on member_type.
  EOT
  type = list(object({
    folder_key  = string
    member_type = string
    member_key  = string
  }))
  default = []

  validation {
    condition     = alltrue([for m in var.folder_memberships : contains(["DATASET", "ANALYSIS", "DASHBOARD"], m.member_type)])
    error_message = "folder_memberships.*.member_type must be DATASET, ANALYSIS, or DASHBOARD."
  }
}

variable "folders" {
  description = <<-EOT
    Map of QuickSight folders. Key becomes the folder_id suffix.
    parent_key references another key in this map to build hierarchies;
    leave empty for root-level folders.
  EOT
  type = map(object({
    name       = string
    parent_key = optional(string, "")
    extra_permissions = optional(list(object({
      principal_arn = string
      role          = string # "owner" or "reader"
    })), [])
  }))
  default = {}

  validation {
    condition     = alltrue(flatten([for f in var.folders : [for p in f.extra_permissions : contains(["owner", "reader"], p.role)]]))
    error_message = "folders.*.extra_permissions[].role must be 'owner' or 'reader'."
  }
}

variable "iam_identity_center_instance_arn" {
  description = "IAM Identity Center instance ARN. When empty and quicksight_authentication_method is IAM_IDENTITY_CENTER, the module auto-discovers the account's instance via a data source. Identity Center instances cannot be created by Terraform — this must already exist."
  type        = string
  default     = ""
}

variable "ip_restriction_cidrs" {
  description = "Map of allowed IPv4 CIDR to description. Used only when create_ip_restriction is true."
  type        = map(string)
  default     = {}
}

variable "ip_restriction_enabled" {
  description = "Whether the IP restriction rules are enforced. Used only when create_ip_restriction is true."
  type        = bool
  default     = true
}

variable "ip_restriction_vpc_endpoint_ids" {
  description = "Map of allowed VPC endpoint ID to description. Used only when create_ip_restriction is true."
  type        = map(string)
  default     = {}
}

variable "ip_restriction_vpc_ids" {
  description = "Map of allowed VPC ID to description. Used only when create_ip_restriction is true."
  type        = map(string)
  default     = {}
}

variable "kms_key_arns" {
  description = "KMS key ARNs to register for QuickSight encryption. Exactly one entry may set default = true. Used only when create_key_registration is true."
  type = map(object({
    default = optional(bool, false)
  }))
  default = {}

  validation {
    condition     = length([for k, v in var.kms_key_arns : k if v.default]) <= 1
    error_message = "At most one KMS key may be marked default = true."
  }
}

variable "lookup_identity_center_instance" {
  description = "Whether to auto-discover the IAM Identity Center instance via the aws_ssoadmin_instances data source when iam_identity_center_instance_arn is empty."
  type        = bool
  default     = true
}

variable "name_prefix" {
  description = "Prefix used for resource naming and IDs."
  type        = string
}

variable "notification_email" {
  description = "Email address for QuickSight account notifications. Required when create_subscription is true."
  type        = string
  default     = ""
}

variable "quicksight_authentication_method" {
  description = "QuickSight authentication method used when creating a subscription."
  type        = string
  default     = "IAM_AND_QUICKSIGHT"

  validation {
    condition     = contains(["IAM_AND_QUICKSIGHT", "IAM_ONLY", "IAM_IDENTITY_CENTER", "ACTIVE_DIRECTORY"], var.quicksight_authentication_method)
    error_message = "Must be IAM_AND_QUICKSIGHT, IAM_ONLY, IAM_IDENTITY_CENTER, or ACTIVE_DIRECTORY."
  }
}

variable "quicksight_edition" {
  description = "QuickSight edition used when creating a subscription."
  type        = string
  default     = "ENTERPRISE"

  validation {
    condition     = contains(["STANDARD", "ENTERPRISE", "ENTERPRISE_AND_Q"], var.quicksight_edition)
    error_message = "Must be STANDARD, ENTERPRISE, or ENTERPRISE_AND_Q."
  }
}

variable "reader_group" {
  description = "QuickSight reader group name for read-only permissions on data sources and datasets."
  type        = string
  default     = ""
}

variable "redshift_cluster_arns" {
  description = "Redshift cluster ARNs granted to the service role. Empty grants account-wide access in the region."
  type        = list(string)
  default     = []
}

variable "region" {
  description = "AWS region for QuickSight resources. Enables multi-region without provider aliases."
  type        = string
}

variable "s3_bucket_names" {
  description = "S3 bucket names the service role can read. Only applied when create_service_role is true."
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "Subnet IDs for the QuickSight VPC connection. Required when create_vpc_connection is true."
  type        = list(string)
  default     = []
}

variable "termination_protection_enabled" {
  description = "Whether QuickSight account termination protection is enabled."
  type        = bool
  default     = false
}

variable "theme_base_id" {
  description = "Base theme ID used when creating the theme (CLASSIC, MIDNIGHT, or SEASIDE)."
  type        = string
  default     = "CLASSIC"
}

variable "theme_data_colors" {
  description = "Data palette hex colors for the custom theme. QuickSight requires 8 to 20 entries."
  type        = list(string)
  default = [
    "#2F474C", "#6BAED6", "#D6A77A", "#8B5E3C",
    "#7C8F8A", "#A3A3A3", "#4C6A92", "#BFA27A",
  ]

  validation {
    condition     = length(var.theme_data_colors) >= 8 && length(var.theme_data_colors) <= 20
    error_message = "theme_data_colors must contain between 8 and 20 hex color strings."
  }
}

variable "theme_font_families" {
  description = "Optional list of font-family names for the theme typography block. Emits a typography block only when non-empty. Max 5 entries."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.theme_font_families) <= 5
    error_message = "theme_font_families accepts at most 5 entries."
  }
}

variable "theme_sheet_gutter_show" {
  description = "Optional: show gutter space between sheet tiles. null omits the setting."
  type        = bool
  default     = null
}

variable "theme_sheet_margin_show" {
  description = "Optional: show sheet margins. null omits the setting."
  type        = bool
  default     = null
}

variable "theme_sheet_tile_border_show" {
  description = "Optional: show borders on visual tiles. null omits the setting."
  type        = bool
  default     = null
}

variable "theme_ui_color_palette" {
  description = <<-EOT
    Optional map of UI color overrides for the theme. Any subset of keys:
    accent, accent_foreground, danger, danger_foreground, dimension,
    dimension_foreground, measure, measure_foreground, primary_background,
    primary_foreground, secondary_background, secondary_foreground, success,
    success_foreground, warning, warning_foreground.
    Leave empty {} to skip the ui_color_palette block.
  EOT
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID for the QuickSight VPC connection security group. Required when create_vpc_connection is true."
  type        = string
  default     = ""
}
