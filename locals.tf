locals {
  account_id = data.aws_caller_identity.current.account_id

  # Identity Center resolution: explicit ARN wins; fall back to data-source lookup when auth method requires it.
  needs_identity_center        = var.quicksight_authentication_method == "IAM_IDENTITY_CENTER"
  lookup_identity_center       = local.needs_identity_center && var.iam_identity_center_instance_arn == "" && var.lookup_identity_center_instance
  identity_center_instance_arn = var.iam_identity_center_instance_arn != "" ? var.iam_identity_center_instance_arn : try(tolist(data.aws_ssoadmin_instances.this[0].arns)[0], "")

  # Data source partitioning by type
  redshift_sources   = { for k, v in var.data_sources : k => v if v.type == "REDSHIFT" }
  athena_sources     = { for k, v in var.data_sources : k => v if v.type == "ATHENA" }
  postgresql_sources = { for k, v in var.data_sources : k => v if v.type == "POSTGRESQL" }
  s3_sources         = { for k, v in var.data_sources : k => v if v.type == "S3" }

  # Group ARNs used as base permission principals
  admin_group_arn  = var.admin_group != "" ? "arn:aws:quicksight:${var.region}:${local.account_id}:group/default/${var.admin_group}" : ""
  author_group_arn = var.author_group != "" ? "arn:aws:quicksight:${var.region}:${local.account_id}:group/default/${var.author_group}" : ""
  reader_group_arn = var.reader_group != "" ? "arn:aws:quicksight:${var.region}:${local.account_id}:group/default/${var.reader_group}" : ""

  ########################################################################
  # Role → actions (per asset family)
  ########################################################################
  ds_role_actions = {
    owner = [
      "quicksight:DeleteDataSource",
      "quicksight:DescribeDataSource",
      "quicksight:DescribeDataSourcePermissions",
      "quicksight:PassDataSource",
      "quicksight:UpdateDataSource",
      "quicksight:UpdateDataSourcePermissions",
    ]
    reader = [
      "quicksight:DescribeDataSource",
      "quicksight:DescribeDataSourcePermissions",
      "quicksight:PassDataSource",
    ]
  }

  dataset_role_actions = {
    owner = [
      "quicksight:CancelIngestion",
      "quicksight:CreateIngestion",
      "quicksight:DeleteDataSet",
      "quicksight:DescribeDataSet",
      "quicksight:DescribeDataSetPermissions",
      "quicksight:DescribeIngestion",
      "quicksight:ListIngestions",
      "quicksight:PassDataSet",
      "quicksight:UpdateDataSet",
      "quicksight:UpdateDataSetPermissions",
    ]
    reader = [
      "quicksight:DescribeDataSet",
      "quicksight:DescribeDataSetPermissions",
      "quicksight:PassDataSet",
    ]
  }

  analysis_role_actions = {
    owner = [
      "quicksight:DeleteAnalysis",
      "quicksight:DescribeAnalysis",
      "quicksight:DescribeAnalysisPermissions",
      "quicksight:QueryAnalysis",
      "quicksight:RestoreAnalysis",
      "quicksight:UpdateAnalysis",
      "quicksight:UpdateAnalysisPermissions",
    ]
    reader = [
      "quicksight:DescribeAnalysis",
      "quicksight:QueryAnalysis",
    ]
  }

  dashboard_role_actions = {
    owner = [
      "quicksight:DeleteDashboard",
      "quicksight:DescribeDashboard",
      "quicksight:DescribeDashboardPermissions",
      "quicksight:ListDashboardVersions",
      "quicksight:QueryDashboard",
      "quicksight:UpdateDashboard",
      "quicksight:UpdateDashboardPermissions",
      "quicksight:UpdateDashboardPublishedVersion",
    ]
    reader = [
      "quicksight:DescribeDashboard",
      "quicksight:ListDashboardVersions",
      "quicksight:QueryDashboard",
    ]
  }

  folder_role_actions = {
    owner = [
      "quicksight:CreateFolder",
      "quicksight:CreateFolderMembership",
      "quicksight:DeleteFolder",
      "quicksight:DeleteFolderMembership",
      "quicksight:DescribeFolder",
      "quicksight:DescribeFolderPermissions",
      "quicksight:UpdateFolder",
      "quicksight:UpdateFolderPermissions",
    ]
    reader = [
      "quicksight:DescribeFolder",
    ]
  }

  ########################################################################
  # Base principal → role for every asset, derived from module-level groups.
  # admin and author both get "owner"; reader gets "reader".
  # Empty-arn entries are dropped.
  ########################################################################
  base_principal_roles = {
    for arn, role in {
      (local.admin_group_arn)  = "owner"
      (local.author_group_arn) = "owner"
      (local.reader_group_arn) = "reader"
    } : arn => role if arn != ""
  }

  # Role ranking: owner > reader. Used to dedup a principal appearing at multiple roles.
  role_rank = {
    owner  = 2
    reader = 1
  }

  ########################################################################
  # Per-entry permission maps: { map_key => { principal_arn => actions } }
  # Merges base_principal_roles with entry.extra_permissions, picking the
  # higher role per principal, then translating to the family's action list.
  ########################################################################
  ds_permissions_per_entry = {
    for k, v in var.data_sources : k => {
      for arn, role in {
        for arn in distinct(concat(keys(local.base_principal_roles), [for p in v.extra_permissions : p.principal_arn])) :
        arn => (
          local.role_rank[
            try(local.base_principal_roles[arn], "reader")
            ] >= local.role_rank[
            try([for p in v.extra_permissions : p.role if p.principal_arn == arn][0], "reader")
          ]
          ? try(local.base_principal_roles[arn], [for p in v.extra_permissions : p.role if p.principal_arn == arn][0])
          : [for p in v.extra_permissions : p.role if p.principal_arn == arn][0]
        )
      } : arn => local.ds_role_actions[role]
    }
  }

  dataset_permissions_per_entry = {
    for k, v in var.datasets : k => {
      for arn, role in {
        for arn in distinct(concat(keys(local.base_principal_roles), [for p in v.extra_permissions : p.principal_arn])) :
        arn => (
          local.role_rank[
            try(local.base_principal_roles[arn], "reader")
            ] >= local.role_rank[
            try([for p in v.extra_permissions : p.role if p.principal_arn == arn][0], "reader")
          ]
          ? try(local.base_principal_roles[arn], [for p in v.extra_permissions : p.role if p.principal_arn == arn][0])
          : [for p in v.extra_permissions : p.role if p.principal_arn == arn][0]
        )
      } : arn => local.dataset_role_actions[role]
    }
  }

  analysis_permissions_per_entry = {
    for k, v in var.analyses : k => {
      for arn, role in {
        for arn in distinct(concat(keys(local.base_principal_roles), [for p in v.extra_permissions : p.principal_arn])) :
        arn => (
          local.role_rank[
            try(local.base_principal_roles[arn], "reader")
            ] >= local.role_rank[
            try([for p in v.extra_permissions : p.role if p.principal_arn == arn][0], "reader")
          ]
          ? try(local.base_principal_roles[arn], [for p in v.extra_permissions : p.role if p.principal_arn == arn][0])
          : [for p in v.extra_permissions : p.role if p.principal_arn == arn][0]
        )
      } : arn => local.analysis_role_actions[role]
    }
  }

  dashboard_permissions_per_entry = {
    for k, v in var.dashboards : k => {
      for arn, role in {
        for arn in distinct(concat(keys(local.base_principal_roles), [for p in v.extra_permissions : p.principal_arn])) :
        arn => (
          local.role_rank[
            try(local.base_principal_roles[arn], "reader")
            ] >= local.role_rank[
            try([for p in v.extra_permissions : p.role if p.principal_arn == arn][0], "reader")
          ]
          ? try(local.base_principal_roles[arn], [for p in v.extra_permissions : p.role if p.principal_arn == arn][0])
          : [for p in v.extra_permissions : p.role if p.principal_arn == arn][0]
        )
      } : arn => local.dashboard_role_actions[role]
    }
  }

  folder_permissions_per_entry = {
    for k, v in var.folders : k => {
      for arn, role in {
        for arn in distinct(concat(keys(local.base_principal_roles), [for p in v.extra_permissions : p.principal_arn])) :
        arn => (
          local.role_rank[
            try(local.base_principal_roles[arn], "reader")
            ] >= local.role_rank[
            try([for p in v.extra_permissions : p.role if p.principal_arn == arn][0], "reader")
          ]
          ? try(local.base_principal_roles[arn], [for p in v.extra_permissions : p.role if p.principal_arn == arn][0])
          : [for p in v.extra_permissions : p.role if p.principal_arn == arn][0]
        )
      } : arn => local.folder_role_actions[role]
    }
  }

  # Unified data source ARN lookup
  data_source_arns = merge(
    { for k, v in aws_quicksight_data_source.redshift : k => v.arn },
    { for k, v in aws_quicksight_data_source.athena : k => v.arn },
    { for k, v in aws_quicksight_data_source.postgresql : k => v.arn },
    { for k, v in aws_quicksight_data_source.s3 : k => v.arn },
  )

  # Unified dataset ARN lookup — used to resolve analyses/dashboards data_set_references by key
  dataset_arns = merge(
    { for k, v in aws_quicksight_data_set.custom_sql : k => v.arn },
    { for k, v in aws_quicksight_data_set.relational : k => v.arn },
    { for k, v in aws_quicksight_data_set.s3_source : k => v.arn },
  )

  # Resolved member IDs per type — folder_membership needs the resource ID, not the ARN.
  # All module-managed IDs follow the pattern "${name_prefix}-${map_key}".
  folder_member_ids = {
    DATASET   = { for k in keys(var.datasets) : k => "${var.name_prefix}-${k}" }
    ANALYSIS  = { for k in keys(var.analyses) : k => "${var.name_prefix}-${k}" }
    DASHBOARD = { for k in keys(var.dashboards) : k => "${var.name_prefix}-${k}" }
  }

  # Root vs child folder partitioning (one level of nesting supported)
  root_folders  = { for k, v in var.folders : k => v if v.parent_key == "" }
  child_folders = { for k, v in var.folders : k => v if v.parent_key != "" }
}
