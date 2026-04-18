# Complete example — storefront analytics

Fictional storefront BI scenario that exercises every opt-in feature: groups, theme, service role, VPC connection, and — most importantly — how `data_sources` and `datasets` reference each other. Also shows the **file-based dataset convention** suitable for real-world repos.

> **Read [`terraform.tfvars.example`](./terraform.tfvars.example) first.** It is the reference for:
> - the four data source types (ATHENA, REDSHIFT, POSTGRESQL, S3) and what fields each requires
> - the three dataset source types (`custom_sql`, `relational_table`, `s3_source`) and which data source types they pair with
> - how `datasets.<name>.data_source_key` must match a key in `data_sources`
> - when to pick `SPICE` vs `DIRECT_QUERY`
> - the file-based fallback for `sql_query` and `columns`

## File-based dataset inputs

For any dataset `<key>`, the example auto-loads:

| Convention path | Loaded into | When |
|---|---|---|
| `datasets/<key>/query.sql` | `datasets.<key>.sql_query` | `sql_query` is left `""` and `source_type = "custom_sql"` |
| `datasets/<key>/columns.json` | `datasets.<key>.columns` | `columns` is left `[]` |

Inline tfvars values always override the files. The wiring lives in `main.tf` as a `locals` merge — it is **not** part of the module, so consumers who prefer pure-tfvars can drop the locals block.

### Layout in this example

```
examples/complete/
├── main.tf
├── variables.tf
├── terraform.tfvars.example
└── datasets/
    ├── orders_last_30d/
    │   └── columns.json              # relational_table → columns only
    ├── traffic_by_channel/
    │   ├── query.sql                 # custom_sql → SQL in a file
    │   └── columns.json              # + columns in a file
    └── (campaign_costs — nothing; columns are inline in tfvars)
```

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars — replace placeholder VPC/subnet/secret ARNs
terraform init
terraform plan
```

## What gets created

For the tfvars shipped here:

| Resource | Name | References | Columns / SQL source |
|---|---|---|---|
| Data source | `warehouse` (REDSHIFT) | VPC connection | — |
| Data source | `lake` (ATHENA) | — | — |
| Data source | `exports` (S3) | — | — |
| Dataset | `orders_last_30d` (relational_table, SPICE) | `warehouse` | `datasets/orders_last_30d/columns.json` |
| Refresh schedule | `orders_last_30d:daily` | `orders_last_30d` | Daily at 03:00 America/Los_Angeles, FULL_REFRESH |
| Dataset | `traffic_by_channel` (custom_sql, DIRECT_QUERY) | `lake` | `datasets/traffic_by_channel/query.sql` + `columns.json` |
| Dataset | `campaign_costs` (s3_source, SPICE) | `exports` | inline in tfvars |
| Refresh schedule | `campaign_costs:hourly` | `campaign_costs` | Hourly, FULL_REFRESH |

## Optional: analyses and dashboards

Set `create_analyses_and_dashboards = true` and provide `sales_template_arn` to publish the example `sales-overview` analysis and dashboard from a pre-authored template. The module does **not** author the `definition` block — build the analysis in the QuickSight console, export it via `CreateTemplate`, then use this example to promote it across environments wired to the correct datasets.
