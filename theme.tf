################################################################################
# QuickSight Theme (optional)
#
# Only data_color_palette is always emitted (QuickSight requires it).
# ui_color_palette / typography / sheet blocks are only rendered when the
# corresponding input is non-empty.
################################################################################

resource "aws_quicksight_theme" "this" {
  count = var.create_theme ? 1 : 0

  base_theme_id = var.theme_base_id
  name          = "${var.name_prefix}-theme"
  region        = var.region
  theme_id      = "${var.name_prefix}-theme"

  configuration {
    data_color_palette {
      colors           = var.theme_data_colors
      empty_fill_color = "#E5E7EB"
      min_max_gradient = ["#DCE7E5", "#2F474C"]
    }

    dynamic "ui_color_palette" {
      for_each = length(var.theme_ui_color_palette) > 0 ? [var.theme_ui_color_palette] : []

      content {
        accent               = try(ui_color_palette.value.accent, null)
        accent_foreground    = try(ui_color_palette.value.accent_foreground, null)
        danger               = try(ui_color_palette.value.danger, null)
        danger_foreground    = try(ui_color_palette.value.danger_foreground, null)
        dimension            = try(ui_color_palette.value.dimension, null)
        dimension_foreground = try(ui_color_palette.value.dimension_foreground, null)
        measure              = try(ui_color_palette.value.measure, null)
        measure_foreground   = try(ui_color_palette.value.measure_foreground, null)
        primary_background   = try(ui_color_palette.value.primary_background, null)
        primary_foreground   = try(ui_color_palette.value.primary_foreground, null)
        secondary_background = try(ui_color_palette.value.secondary_background, null)
        secondary_foreground = try(ui_color_palette.value.secondary_foreground, null)
        success              = try(ui_color_palette.value.success, null)
        success_foreground   = try(ui_color_palette.value.success_foreground, null)
        warning              = try(ui_color_palette.value.warning, null)
        warning_foreground   = try(ui_color_palette.value.warning_foreground, null)
      }
    }

    dynamic "typography" {
      for_each = length(var.theme_font_families) > 0 ? [1] : []

      content {
        dynamic "font_families" {
          for_each = var.theme_font_families

          content {
            font_family = font_families.value
          }
        }
      }
    }

    dynamic "sheet" {
      for_each = var.theme_sheet_tile_border_show != null || var.theme_sheet_gutter_show != null || var.theme_sheet_margin_show != null ? [1] : []

      content {
        dynamic "tile" {
          for_each = var.theme_sheet_tile_border_show != null ? [1] : []

          content {
            border {
              show = var.theme_sheet_tile_border_show
            }
          }
        }

        dynamic "tile_layout" {
          for_each = var.theme_sheet_gutter_show != null || var.theme_sheet_margin_show != null ? [1] : []

          content {
            dynamic "gutter" {
              for_each = var.theme_sheet_gutter_show != null ? [1] : []

              content {
                show = var.theme_sheet_gutter_show
              }
            }

            dynamic "margin" {
              for_each = var.theme_sheet_margin_show != null ? [1] : []

              content {
                show = var.theme_sheet_margin_show
              }
            }
          }
        }
      }
    }
  }
}
