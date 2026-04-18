################################################################################
# QuickSight Groups (optional)
################################################################################

resource "aws_quicksight_group" "this" {
  for_each = var.create_groups ? toset(compact([var.admin_group, var.author_group, var.reader_group])) : toset([])

  group_name = each.key
  namespace  = "default"
}
