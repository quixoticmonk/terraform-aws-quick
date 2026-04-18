################################################################################
# Folders (one level of nesting: root folders and their direct children)
################################################################################

resource "aws_quicksight_folder" "root" {
  for_each = local.root_folders

  folder_id = "${var.name_prefix}-${each.key}"
  name      = each.value.name
  region    = var.region

  dynamic "permissions" {
    for_each = local.folder_permissions_per_entry[each.key]

    content {
      actions   = permissions.value
      principal = permissions.key
    }
  }
}

resource "aws_quicksight_folder" "child" {
  for_each = local.child_folders

  folder_id         = "${var.name_prefix}-${each.key}"
  name              = each.value.name
  parent_folder_arn = aws_quicksight_folder.root[each.value.parent_key].arn
  region            = var.region

  dynamic "permissions" {
    for_each = local.folder_permissions_per_entry[each.key]

    content {
      actions   = permissions.value
      principal = permissions.key
    }
  }

  lifecycle {
    precondition {
      condition     = contains(keys(local.root_folders), each.value.parent_key)
      error_message = "folders[${each.key}].parent_key must reference a root folder (folders with parent_key = \"\"). Only one level of nesting is supported."
    }
  }
}

resource "aws_quicksight_folder_membership" "this" {
  for_each = { for m in var.folder_memberships : "${m.folder_key}:${m.member_type}:${m.member_key}" => m }

  folder_id   = try(aws_quicksight_folder.root[each.value.folder_key].folder_id, aws_quicksight_folder.child[each.value.folder_key].folder_id)
  member_id   = local.folder_member_ids[each.value.member_type][each.value.member_key]
  member_type = each.value.member_type
  region      = var.region

  lifecycle {
    precondition {
      condition     = contains(keys(var.folders), each.value.folder_key)
      error_message = "folder_memberships entry references an unknown folder key '${each.value.folder_key}'. Must match a key in var.folders."
    }

    precondition {
      condition     = contains(keys(local.folder_member_ids[each.value.member_type]), each.value.member_key)
      error_message = "folder_memberships entry references an unknown ${each.value.member_type} key '${each.value.member_key}'. Must match a key in var.datasets, var.analyses, or var.dashboards."
    }
  }
}
