output "analysis_arns" {
  description = "Map of analysis key to ARN."
  value       = { for k, v in aws_quicksight_analysis.this : k => v.arn }
}

output "dashboard_arns" {
  description = "Map of dashboard key to ARN."
  value       = { for k, v in aws_quicksight_dashboard.this : k => v.arn }
}

output "data_source_arns" {
  description = "Map of data source key to ARN."
  value       = local.data_source_arns
}

output "dataset_arns" {
  description = "Map of dataset key to ARN."
  value       = local.dataset_arns
}

output "refresh_schedule_arns" {
  description = "Map of '<dataset_key>:<schedule_key>' to refresh schedule ARN."
  value       = { for k, v in aws_quicksight_refresh_schedule.this : k => v.arn }
}

output "folder_arns" {
  description = "Map of folder key to ARN."
  value = merge(
    { for k, v in aws_quicksight_folder.root : k => v.arn },
    { for k, v in aws_quicksight_folder.child : k => v.arn },
  )
}

output "group_names" {
  description = "QuickSight groups created by the module."
  value       = [for g in aws_quicksight_group.this : g.group_name]
}

output "identity_center_instance_arn" {
  description = "Resolved IAM Identity Center instance ARN used for the subscription. Empty when auth method is not IAM_IDENTITY_CENTER."
  value       = local.needs_identity_center ? local.identity_center_instance_arn : ""
}

output "service_role_arn" {
  description = "ARN of the QuickSight service IAM role. Empty when create_service_role is false."
  value       = try(aws_iam_role.service[0].arn, "")
}

output "subscription_status" {
  description = "Status of the QuickSight account subscription. 'existing' when create_subscription is false."
  value       = try(aws_quicksight_account_subscription.this[0].account_subscription_status, "existing")
}

output "theme_arn" {
  description = "ARN of the QuickSight theme. Empty when create_theme is false."
  value       = try(aws_quicksight_theme.this[0].arn, "")
}

output "vpc_connection_arn" {
  description = "ARN of the QuickSight VPC connection. Empty when create_vpc_connection is false."
  value       = try(aws_quicksight_vpc_connection.this[0].arn, "")
}
