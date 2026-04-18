# terraform-aws-quick

Terraform module for provisioning Amazon QuickSight resources with conditional, opt-in components. Built on the `hashicorp/aws` provider (preferred over AWSCC for QuickSight coverage).

## Features

Each piece is gated by a boolean flag so you compose only what you need:

| Flag | Default | Creates |
|------|---------|---------|
| `create_subscription` | `false` | `aws_quicksight_account_subscription` |
| `create_account_settings` | `true` | `aws_quicksight_account_settings` (set `false` when consuming an existing account) |
| `create_groups` | `false` | `aws_quicksight_group` for each of admin/author/reader |
| `create_theme` | `false` | Custom `aws_quicksight_theme` |
| `create_service_role` | `false` | IAM role + scoped inline policy (S3, Athena, Redshift, Secrets Manager) |
| `create_key_registration` | `false` | `aws_quicksight_key_registration` — registers customer-managed KMS keys for encryption at rest |
| `create_ip_restriction` | `false` | `aws_quicksight_ip_restriction` — account IP/VPC allow-list |
| `create_vpc_connection` | `false` | Security group, IAM role, and `aws_quicksight_vpc_connection` |
| `data_sources` (map) | `{}` | `aws_quicksight_data_source` per entry (REDSHIFT, ATHENA, POSTGRESQL, S3) |
| `datasets` (map) | `{}` | `aws_quicksight_data_set` per entry (custom_sql, relational_table, s3_source). Each dataset may declare one or more `refresh_schedules` (SPICE only) — produces `aws_quicksight_refresh_schedule` resources. |
| `analyses` (map) | `{}` | `aws_quicksight_analysis` per entry, published from a `source_template` |
| `dashboards` (map) | `{}` | `aws_quicksight_dashboard` per entry, published from a `source_template` |
| `folders` (map) | `{}` | `aws_quicksight_folder` per entry; supports one level of nesting via `parent_key` |
| `folder_memberships` (list) | `[]` | `aws_quicksight_folder_membership` — binds module-managed datasets/analyses/dashboards to folders |

`aws_quicksight_account_settings` is created by default (the module owns termination protection for the region). Set `create_account_settings = false` when the module is running against an account whose settings are managed elsewhere.

## Analyses and dashboards

The module supports `aws_quicksight_analysis` and `aws_quicksight_dashboard` **only via `source_entity.source_template`**. You supply a template ARN plus a list of dataset references (by key into `var.datasets`, or an explicit ARN) and the module publishes the analysis/dashboard wired to those datasets.

**Why not `definition`?** The `definition` block is a 3000+ attribute tree that describes every visual, filter, parameter, and sheet layout. No generic map-driven API can model it. Author the analysis in the QuickSight console, promote it to a template via `CreateTemplate`, then use this module to publish downstream analyses/dashboards across environments.

```hcl
dashboards = {
  sales-overview = {
    source_template_arn = "arn:aws:quicksight:us-west-2:111111111111:template/sales-overview-v3"
    data_set_references = [
      { placeholder = "sales", data_set_key = "orders_last_30d" },
      { placeholder = "costs", data_set_arn = "arn:aws:quicksight:...:dataset/external" },
    ]
  }
}
```

## Identity Center

When `quicksight_authentication_method = "IAM_IDENTITY_CENTER"` the subscription needs an Identity Center instance ARN. The module handles three paths:

| Scenario | How |
|---|---|
| Supply an existing instance explicitly | Set `iam_identity_center_instance_arn = "arn:aws:sso:::instance/ssoins-..."` |
| Auto-discover the account's instance | Leave `iam_identity_center_instance_arn` empty (default); `lookup_identity_center_instance = true` queries `aws_ssoadmin_instances` |
| Disable auto-discovery | Set `lookup_identity_center_instance = false` and supply the ARN explicitly |

Identity Center instances **cannot be created by Terraform** — the AWS provider does not expose a `CreateInstance` resource. Enable Identity Center once via AWS Organizations (or enable an account instance from the IAM Identity Center console), then this module consumes it.

## Usage

```hcl
module "quick" {
  source = "github.com/your-org/terraform-aws-quick"

  name_prefix = "acme-dev"
  region      = "us-west-2"

  # Opt into what you need
  create_theme        = true
  create_service_role = true

  admin_group  = "quick.admins"
  author_group = "quick.authors"
  reader_group = "quick.readers"

  data_sources = {
    athena = {
      type       = "ATHENA"
      work_group = "primary"
    }
  }

  datasets = {
    sales = {
      import_mode     = "SPICE"
      data_source_key = "athena"
      source_type     = "relational_table"
      catalog         = "AwsDataCatalog"
      schema          = "analytics"
      table_name      = "sales"
    }
  }
}
```

See `examples/minimal`, `examples/complete`, `examples/analysis-and-dashboard`, and `examples/with-brand-assets` for full scenarios.

## Provider choice

The AWS provider is used throughout because it provides richer and more stable coverage for QuickSight resources (analyses, dashboards, themes, VPC connections) than AWSCC. No resource in this module falls back to AWSCC.

## Testing

```bash
terraform test               # unit tests (plan mode with mocks)
terraform test -verbose      # detailed output
```

Test files live in `tests/`:
- `validation_unit_test.tftest.hcl` — variable validation (plan mode, no mocks needed)
- `defaults_unit_test.tftest.hcl` — default-off behavior (plan mode with mocked AWS provider)
- `conditional_unit_test.tftest.hcl` — conditional resource creation (plan mode with mocked AWS provider)

## Reference

Everything below this line is generated by [`terraform-docs`](https://terraform-docs.io). Run `terraform-docs .` after changing inputs/outputs/resources.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.41.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.vpc_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.vpc_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_quicksight_account_settings.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_account_settings) | resource |
| [aws_quicksight_account_subscription.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_account_subscription) | resource |
| [aws_quicksight_analysis.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_analysis) | resource |
| [aws_quicksight_dashboard.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_dashboard) | resource |
| [aws_quicksight_data_set.custom_sql](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_data_set) | resource |
| [aws_quicksight_data_set.relational](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_data_set) | resource |
| [aws_quicksight_data_set.s3_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_data_set) | resource |
| [aws_quicksight_data_source.athena](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_data_source) | resource |
| [aws_quicksight_data_source.postgresql](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_data_source) | resource |
| [aws_quicksight_data_source.redshift](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_data_source) | resource |
| [aws_quicksight_data_source.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_data_source) | resource |
| [aws_quicksight_folder.child](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_folder) | resource |
| [aws_quicksight_folder.root](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_folder) | resource |
| [aws_quicksight_folder_membership.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_folder_membership) | resource |
| [aws_quicksight_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_group) | resource |
| [aws_quicksight_ip_restriction.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_ip_restriction) | resource |
| [aws_quicksight_key_registration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_key_registration) | resource |
| [aws_quicksight_refresh_schedule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_refresh_schedule) | resource |
| [aws_quicksight_theme.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_theme) | resource |
| [aws_quicksight_vpc_connection.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_vpc_connection) | resource |
| [aws_security_group.vpc_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.vpc_connection_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.vpc_connection_redshift](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.quicksight_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vpc_connection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_ssoadmin_instances.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssoadmin_instances) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_group"></a> [admin\_group](#input\_admin\_group) | QuickSight admin group name for owner permissions on data sources and datasets. | `string` | `""` | no |
| <a name="input_analyses"></a> [analyses](#input\_analyses) | Map of QuickSight analyses to create from a source template.<br/>Each entry supplies a template ARN and a list of dataset references<br/>(placeholder → dataset key in var.datasets OR an explicit ARN).<br/>Only source\_template mode is supported; author the template elsewhere. | <pre>map(object({<br/>    source_template_arn = string<br/>    theme_arn           = optional(string, "")<br/>    data_set_references = list(object({<br/>      placeholder  = string<br/>      data_set_key = optional(string, "")<br/>      data_set_arn = optional(string, "")<br/>    }))<br/>    extra_permissions = optional(list(object({<br/>      principal_arn = string<br/>      role          = string # "owner" or "reader"<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_author_group"></a> [author\_group](#input\_author\_group) | QuickSight author group name for write permissions on data sources and datasets. | `string` | `""` | no |
| <a name="input_create_account_settings"></a> [create\_account\_settings](#input\_create\_account\_settings) | Whether to manage aws\_quicksight\_account\_settings. Set false when consuming an existing QuickSight account to avoid overwriting termination protection. | `bool` | `true` | no |
| <a name="input_create_groups"></a> [create\_groups](#input\_create\_groups) | Whether to create QuickSight groups (admin, author, reader) in the default namespace. | `bool` | `false` | no |
| <a name="input_create_ip_restriction"></a> [create\_ip\_restriction](#input\_create\_ip\_restriction) | Whether to manage QuickSight account IP/VPC restrictions via aws\_quicksight\_ip\_restriction. | `bool` | `false` | no |
| <a name="input_create_key_registration"></a> [create\_key\_registration](#input\_create\_key\_registration) | Whether to register customer-managed KMS keys for QuickSight encryption via aws\_quicksight\_key\_registration. | `bool` | `false` | no |
| <a name="input_create_service_role"></a> [create\_service\_role](#input\_create\_service\_role) | Whether to create the QuickSight service IAM role with scoped policies for S3, Athena, Redshift, and Secrets Manager. | `bool` | `false` | no |
| <a name="input_create_subscription"></a> [create\_subscription](#input\_create\_subscription) | Whether to create a new QuickSight account subscription. Set false when a subscription already exists. | `bool` | `false` | no |
| <a name="input_create_theme"></a> [create\_theme](#input\_create\_theme) | Whether to create a custom QuickSight theme. | `bool` | `false` | no |
| <a name="input_create_vpc_connection"></a> [create\_vpc\_connection](#input\_create\_vpc\_connection) | Whether to create a QuickSight VPC connection (security group, IAM role, and VPC connection) for private data source access. | `bool` | `false` | no |
| <a name="input_dashboards"></a> [dashboards](#input\_dashboards) | Map of QuickSight dashboards to publish from a source template.<br/>Each entry supplies a template ARN and a list of dataset references<br/>(placeholder → dataset key in var.datasets OR an explicit ARN).<br/>Only source\_template mode is supported; author the template elsewhere. | <pre>map(object({<br/>    source_template_arn = string<br/>    theme_arn           = optional(string, "")<br/>    version_description = optional(string, "Managed by Terraform")<br/>    data_set_references = list(object({<br/>      placeholder  = string<br/>      data_set_key = optional(string, "")<br/>      data_set_arn = optional(string, "")<br/>    }))<br/>    extra_permissions = optional(list(object({<br/>      principal_arn = string<br/>      role          = string # "owner" or "reader"<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_data_sources"></a> [data\_sources](#input\_data\_sources) | Map of QuickSight data sources. Key becomes the data source ID suffix. Types: REDSHIFT, ATHENA, POSTGRESQL, S3. | <pre>map(object({<br/>    type                  = string<br/>    credential_secret_arn = optional(string, "")<br/>    database              = optional(string, "")<br/>    host                  = optional(string, "")<br/>    port                  = optional(number, 0)<br/>    role_arn              = optional(string, "")<br/>    s3_bucket             = optional(string, "")<br/>    s3_key                = optional(string, "manifests/manifest.json")<br/>    use_vpc               = optional(bool, false)<br/>    work_group            = optional(string, "primary")<br/>    extra_permissions = optional(list(object({<br/>      principal_arn = string<br/>      role          = string # "owner" or "reader"<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_datasets"></a> [datasets](#input\_datasets) | Map of QuickSight datasets. Key becomes the dataset ID suffix. source\_type: custom\_sql, relational\_table, or s3\_source. | <pre>map(object({<br/>    import_mode     = string<br/>    data_source_key = string<br/>    source_type     = string<br/>    sql_query       = optional(string, "")<br/>    catalog         = optional(string, "")<br/>    schema          = optional(string, "")<br/>    table_name      = optional(string, "")<br/>    s3_format       = optional(string, "CSV")<br/>    s3_delimiter    = optional(string, ",")<br/>    columns = optional(list(object({<br/>      name = string<br/>      type = string<br/>    })), [])<br/>    extra_permissions = optional(list(object({<br/>      principal_arn = string<br/>      role          = string # "owner" or "reader"<br/>    })), [])<br/>    refresh_schedules = optional(map(object({<br/>      interval     = string                           # MINUTE15 | MINUTE30 | HOURLY | DAILY | WEEKLY | MONTHLY<br/>      refresh_type = optional(string, "FULL_REFRESH") # FULL_REFRESH | INCREMENTAL_REFRESH<br/>      time_of_day  = optional(string, "")             # HH:MM — required for all intervals except HOURLY / MINUTE*<br/>      timezone     = optional(string, "UTC")<br/>      day_of_week  = optional(string, "") # required when interval = WEEKLY<br/>      day_of_month = optional(string, "") # required when interval = MONTHLY<br/>      start_after  = optional(string, "") # YYYY-MM-DDTHH:MM:SS<br/>    })), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_folder_memberships"></a> [folder\_memberships](#input\_folder\_memberships) | List of folder membership bindings. Each entry places a module-managed<br/>dataset/analysis/dashboard into a folder declared in var.folders.<br/>member\_type must be DATASET, ANALYSIS, or DASHBOARD.<br/>folder\_key must match a key in var.folders.<br/>member\_key must match a key in var.datasets / var.analyses / var.dashboards<br/>depending on member\_type. | <pre>list(object({<br/>    folder_key  = string<br/>    member_type = string<br/>    member_key  = string<br/>  }))</pre> | `[]` | no |
| <a name="input_folders"></a> [folders](#input\_folders) | Map of QuickSight folders. Key becomes the folder\_id suffix.<br/>parent\_key references another key in this map to build hierarchies;<br/>leave empty for root-level folders. | <pre>map(object({<br/>    name       = string<br/>    parent_key = optional(string, "")<br/>    extra_permissions = optional(list(object({<br/>      principal_arn = string<br/>      role          = string # "owner" or "reader"<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_iam_identity_center_instance_arn"></a> [iam\_identity\_center\_instance\_arn](#input\_iam\_identity\_center\_instance\_arn) | IAM Identity Center instance ARN. When empty and quicksight\_authentication\_method is IAM\_IDENTITY\_CENTER, the module auto-discovers the account's instance via a data source. Identity Center instances cannot be created by Terraform — this must already exist. | `string` | `""` | no |
| <a name="input_ip_restriction_cidrs"></a> [ip\_restriction\_cidrs](#input\_ip\_restriction\_cidrs) | Map of allowed IPv4 CIDR to description. Used only when create\_ip\_restriction is true. | `map(string)` | `{}` | no |
| <a name="input_ip_restriction_enabled"></a> [ip\_restriction\_enabled](#input\_ip\_restriction\_enabled) | Whether the IP restriction rules are enforced. Used only when create\_ip\_restriction is true. | `bool` | `true` | no |
| <a name="input_ip_restriction_vpc_endpoint_ids"></a> [ip\_restriction\_vpc\_endpoint\_ids](#input\_ip\_restriction\_vpc\_endpoint\_ids) | Map of allowed VPC endpoint ID to description. Used only when create\_ip\_restriction is true. | `map(string)` | `{}` | no |
| <a name="input_ip_restriction_vpc_ids"></a> [ip\_restriction\_vpc\_ids](#input\_ip\_restriction\_vpc\_ids) | Map of allowed VPC ID to description. Used only when create\_ip\_restriction is true. | `map(string)` | `{}` | no |
| <a name="input_kms_key_arns"></a> [kms\_key\_arns](#input\_kms\_key\_arns) | KMS key ARNs to register for QuickSight encryption. Exactly one entry may set default = true. Used only when create\_key\_registration is true. | <pre>map(object({<br/>    default = optional(bool, false)<br/>  }))</pre> | `{}` | no |
| <a name="input_lookup_identity_center_instance"></a> [lookup\_identity\_center\_instance](#input\_lookup\_identity\_center\_instance) | Whether to auto-discover the IAM Identity Center instance via the aws\_ssoadmin\_instances data source when iam\_identity\_center\_instance\_arn is empty. | `bool` | `true` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used for resource naming and IDs. | `string` | n/a | yes |
| <a name="input_notification_email"></a> [notification\_email](#input\_notification\_email) | Email address for QuickSight account notifications. Required when create\_subscription is true. | `string` | `""` | no |
| <a name="input_quicksight_authentication_method"></a> [quicksight\_authentication\_method](#input\_quicksight\_authentication\_method) | QuickSight authentication method used when creating a subscription. | `string` | `"IAM_AND_QUICKSIGHT"` | no |
| <a name="input_quicksight_edition"></a> [quicksight\_edition](#input\_quicksight\_edition) | QuickSight edition used when creating a subscription. | `string` | `"ENTERPRISE"` | no |
| <a name="input_reader_group"></a> [reader\_group](#input\_reader\_group) | QuickSight reader group name for read-only permissions on data sources and datasets. | `string` | `""` | no |
| <a name="input_redshift_cluster_arns"></a> [redshift\_cluster\_arns](#input\_redshift\_cluster\_arns) | Redshift cluster ARNs granted to the service role. Empty grants account-wide access in the region. | `list(string)` | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region for QuickSight resources. Enables multi-region without provider aliases. | `string` | n/a | yes |
| <a name="input_s3_bucket_names"></a> [s3\_bucket\_names](#input\_s3\_bucket\_names) | S3 bucket names the service role can read. Only applied when create\_service\_role is true. | `list(string)` | `[]` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnet IDs for the QuickSight VPC connection. Required when create\_vpc\_connection is true. | `list(string)` | `[]` | no |
| <a name="input_termination_protection_enabled"></a> [termination\_protection\_enabled](#input\_termination\_protection\_enabled) | Whether QuickSight account termination protection is enabled. | `bool` | `false` | no |
| <a name="input_theme_base_id"></a> [theme\_base\_id](#input\_theme\_base\_id) | Base theme ID used when creating the theme (CLASSIC, MIDNIGHT, or SEASIDE). | `string` | `"CLASSIC"` | no |
| <a name="input_theme_data_colors"></a> [theme\_data\_colors](#input\_theme\_data\_colors) | Data palette hex colors for the custom theme. QuickSight requires 8 to 20 entries. | `list(string)` | <pre>[<br/>  "#2F474C",<br/>  "#6BAED6",<br/>  "#D6A77A",<br/>  "#8B5E3C",<br/>  "#7C8F8A",<br/>  "#A3A3A3",<br/>  "#4C6A92",<br/>  "#BFA27A"<br/>]</pre> | no |
| <a name="input_theme_font_families"></a> [theme\_font\_families](#input\_theme\_font\_families) | Optional list of font-family names for the theme typography block. Emits a typography block only when non-empty. Max 5 entries. | `list(string)` | `[]` | no |
| <a name="input_theme_sheet_gutter_show"></a> [theme\_sheet\_gutter\_show](#input\_theme\_sheet\_gutter\_show) | Optional: show gutter space between sheet tiles. null omits the setting. | `bool` | `null` | no |
| <a name="input_theme_sheet_margin_show"></a> [theme\_sheet\_margin\_show](#input\_theme\_sheet\_margin\_show) | Optional: show sheet margins. null omits the setting. | `bool` | `null` | no |
| <a name="input_theme_sheet_tile_border_show"></a> [theme\_sheet\_tile\_border\_show](#input\_theme\_sheet\_tile\_border\_show) | Optional: show borders on visual tiles. null omits the setting. | `bool` | `null` | no |
| <a name="input_theme_ui_color_palette"></a> [theme\_ui\_color\_palette](#input\_theme\_ui\_color\_palette) | Optional map of UI color overrides for the theme. Any subset of keys:<br/>accent, accent\_foreground, danger, danger\_foreground, dimension,<br/>dimension\_foreground, measure, measure\_foreground, primary\_background,<br/>primary\_foreground, secondary\_background, secondary\_foreground, success,<br/>success\_foreground, warning, warning\_foreground.<br/>Leave empty {} to skip the ui\_color\_palette block. | `map(string)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID for the QuickSight VPC connection security group. Required when create\_vpc\_connection is true. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_analysis_arns"></a> [analysis\_arns](#output\_analysis\_arns) | Map of analysis key to ARN. |
| <a name="output_dashboard_arns"></a> [dashboard\_arns](#output\_dashboard\_arns) | Map of dashboard key to ARN. |
| <a name="output_data_source_arns"></a> [data\_source\_arns](#output\_data\_source\_arns) | Map of data source key to ARN. |
| <a name="output_dataset_arns"></a> [dataset\_arns](#output\_dataset\_arns) | Map of dataset key to ARN. |
| <a name="output_folder_arns"></a> [folder\_arns](#output\_folder\_arns) | Map of folder key to ARN. |
| <a name="output_group_names"></a> [group\_names](#output\_group\_names) | QuickSight groups created by the module. |
| <a name="output_identity_center_instance_arn"></a> [identity\_center\_instance\_arn](#output\_identity\_center\_instance\_arn) | Resolved IAM Identity Center instance ARN used for the subscription. Empty when auth method is not IAM\_IDENTITY\_CENTER. |
| <a name="output_refresh_schedule_arns"></a> [refresh\_schedule\_arns](#output\_refresh\_schedule\_arns) | Map of '<dataset\_key>:<schedule\_key>' to refresh schedule ARN. |
| <a name="output_service_role_arn"></a> [service\_role\_arn](#output\_service\_role\_arn) | ARN of the QuickSight service IAM role. Empty when create\_service\_role is false. |
| <a name="output_subscription_status"></a> [subscription\_status](#output\_subscription\_status) | Status of the QuickSight account subscription. 'existing' when create\_subscription is false. |
| <a name="output_theme_arn"></a> [theme\_arn](#output\_theme\_arn) | ARN of the QuickSight theme. Empty when create\_theme is false. |
| <a name="output_vpc_connection_arn"></a> [vpc\_connection\_arn](#output\_vpc\_connection\_arn) | ARN of the QuickSight VPC connection. Empty when create\_vpc\_connection is false. |
<!-- END_TF_DOCS -->

