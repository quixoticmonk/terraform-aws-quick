################################################################################
# Refresh Schedules — flattened from var.datasets.*.refresh_schedules
################################################################################
# Schedules are nested inside each dataset entry; this resource flattens them
# into a single for_each map keyed by "<dataset_key>:<schedule_key>".
# Only valid for SPICE datasets — the precondition rejects DIRECT_QUERY.
################################################################################

locals {
  refresh_schedules_flat = merge([
    for dk, d in var.datasets : {
      for sk, s in d.refresh_schedules : "${dk}:${sk}" => merge(s, {
        dataset_key  = dk
        schedule_key = sk
        import_mode  = d.import_mode
      })
    }
  ]...)
}

resource "aws_quicksight_refresh_schedule" "this" {
  for_each = local.refresh_schedules_flat

  data_set_id = "${var.name_prefix}-${each.value.dataset_key}"
  region      = var.region
  schedule_id = each.value.schedule_key

  schedule {
    refresh_type          = each.value.refresh_type
    start_after_date_time = each.value.start_after != "" ? each.value.start_after : null

    schedule_frequency {
      interval        = each.value.interval
      time_of_the_day = each.value.time_of_day != "" ? each.value.time_of_day : null
      timezone        = each.value.timezone

      dynamic "refresh_on_day" {
        for_each = each.value.day_of_week != "" || each.value.day_of_month != "" ? [1] : []

        content {
          day_of_week  = each.value.day_of_week != "" ? each.value.day_of_week : null
          day_of_month = each.value.day_of_month != "" ? each.value.day_of_month : null
        }
      }
    }
  }

  depends_on = [
    aws_quicksight_data_set.custom_sql,
    aws_quicksight_data_set.relational,
    aws_quicksight_data_set.s3_source,
  ]

  lifecycle {
    precondition {
      condition     = each.value.import_mode == "SPICE"
      error_message = "Refresh schedule '${each.value.schedule_key}' is defined on dataset '${each.value.dataset_key}' which has import_mode = '${each.value.import_mode}'. Only SPICE datasets support refresh schedules."
    }

    precondition {
      condition     = each.value.interval != "WEEKLY" || each.value.day_of_week != ""
      error_message = "Schedule '${each.value.schedule_key}' on dataset '${each.value.dataset_key}' has interval = WEEKLY and must supply day_of_week."
    }

    precondition {
      condition     = each.value.interval != "MONTHLY" || each.value.day_of_month != ""
      error_message = "Schedule '${each.value.schedule_key}' on dataset '${each.value.dataset_key}' has interval = MONTHLY and must supply day_of_month."
    }

    precondition {
      condition     = contains(["HOURLY", "MINUTE15", "MINUTE30"], each.value.interval) || each.value.time_of_day != ""
      error_message = "Schedule '${each.value.schedule_key}' on dataset '${each.value.dataset_key}' has interval = '${each.value.interval}' and must supply time_of_day (HH:MM)."
    }
  }
}
