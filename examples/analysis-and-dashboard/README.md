# Analysis + dashboard example

Focused end-to-end example that publishes a QuickSight **analysis** and **dashboard** from a pre-authored template, wired to a single Athena dataset.

Use this example as the reference when you've already authored an analysis in the console and want to promote it across environments via Terraform.

## Prerequisites — producing the template ARN

The module does not author the `definition` block; it publishes from a template. Produce one once per analysis:

```bash
# 1. Build the analysis in the QuickSight console against your dev datasets.
#    Note any dataset placeholder names you use (e.g. `orders_placeholder`).

# 2. Grab its definition.
aws quicksight describe-analysis-definition \
  --aws-account-id 111111111111 \
  --analysis-id orders-overview-dev \
  > analysis-definition.json

# 3. Turn it into a template your pipeline can reuse across environments.
aws quicksight create-template \
  --aws-account-id 111111111111 \
  --template-id orders-overview-v1 \
  --name "Orders Overview v1" \
  --source-entity file://source-entity.json   # points at the analysis ARN

# 4. Template ARN is returned — paste it into orders_template_arn below.
```

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars — replace the template ARN with yours
terraform init
terraform plan
```

## What gets created

| Resource | Name |
|---|---|
| Data source | `lake` (ATHENA, `primary` workgroup) |
| Dataset | `orders` (relational_table, SPICE) on `AwsDataCatalog.storefront.orders` |
| Analysis | `orders-overview` published from `var.orders_template_arn`, `orders_placeholder` → `orders` dataset |
| Dashboard | `orders-overview` same template, same binding, permissions for reader group |

## Key point — placeholders

The template declares dataset *placeholders* (symbolic names). Each deployment binds those placeholders to real dataset keys in `var.datasets`. In this example the placeholder `orders_placeholder` is bound to the dataset key `orders`. Change the placeholder name in `main.tf` to match whatever your template declares.
