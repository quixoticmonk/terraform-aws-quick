variable "admin_group" {
  description = "QuickSight admin group name."
  type        = string
}

variable "author_group" {
  description = "QuickSight author group name."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for all resource names."
  type        = string
}

variable "orders_template_arn" {
  description = "ARN of a pre-authored QuickSight template whose dataset placeholder is named 'orders_placeholder'."
  type        = string
}

variable "reader_group" {
  description = "QuickSight reader group name."
  type        = string
}

variable "region" {
  description = "AWS region for QuickSight resources."
  type        = string
}
