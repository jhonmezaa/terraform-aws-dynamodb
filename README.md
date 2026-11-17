# terraform-aws-dynamodb

Terraform module for managing AWS DynamoDB tables with full feature support.

## Features

- **3 Table Variants**: Mutually exclusive resources for proper lifecycle management with autoscaling
- **Billing Modes**: PAY_PER_REQUEST and PROVISIONED
- **Indexes**: Global Secondary Indexes (GSI) and Local Secondary Indexes (LSI)
- **TTL**: Time-to-Live attribute support
- **PITR**: Point-in-Time Recovery with configurable retention
- **Streams**: DynamoDB Streams (KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES)
- **Encryption**: Server-side encryption with AWS managed or custom KMS keys
- **Autoscaling**: Application Auto Scaling for table and index read/write capacity
- **Global Tables**: Multi-region replicas with per-replica configuration
- **Resource Policy**: Resource-based IAM policies with ARN template support
- **S3 Import**: Import data from S3 during table creation
- **Table Class**: STANDARD and STANDARD_INFREQUENT_ACCESS
- **Deletion Protection**: Prevent accidental table deletion
- **On-Demand/Warm Throughput**: Advanced throughput configuration

## Usage

### Basic Table (PAY_PER_REQUEST)

```hcl
module "dynamodb" {
  source = "github.com/jhonmezaa/terraform-aws-dynamodb//dynamodb?ref=v1.2.0"

  account_name      = "dev"
  project_name      = "myapp"
  table_name_suffix = "users"

  hash_key = "user_id"

  attributes = [
    { name = "user_id", type = "S" }
  ]

  tags_common = {
    Environment = "dev"
  }
}
```

### Provisioned Table with Autoscaling

```hcl
module "dynamodb" {
  source = "github.com/jhonmezaa/terraform-aws-dynamodb//dynamodb?ref=v1.2.0"

  account_name      = "prod"
  project_name      = "myapp"
  table_name_suffix = "orders"

  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "order_id"
  range_key      = "created_at"

  attributes = [
    { name = "order_id", type = "S" },
    { name = "created_at", type = "N" },
    { name = "user_id", type = "S" }
  ]

  global_secondary_indexes = [
    {
      name            = "UserIndex"
      hash_key        = "user_id"
      range_key       = "created_at"
      projection_type = "ALL"
      read_capacity   = 5
      write_capacity  = 5
    }
  ]

  autoscaling_enabled = true

  autoscaling_read = {
    max_capacity = 100
  }

  autoscaling_write = {
    max_capacity = 100
  }

  autoscaling_indexes = {
    UserIndex = {
      read_min_capacity  = 5 # optional, defaults to read_capacity
      read_max_capacity  = 50
      write_min_capacity = 5 # optional, defaults to write_capacity
      write_max_capacity = 50
    }
  }
}
```

### Import from S3

Both the upstream-compatible flat form and the nested `s3_bucket_source` form are accepted:

```hcl
  import_table = {
    input_format           = "CSV"
    input_compression_type = "NONE"
    bucket                 = "my-import-bucket"
    key_prefix             = "import/"
    input_format_options = {
      csv = { delimiter = ";" }
    }
  }
```

## Examples

- [basic](examples/basic) - PAY_PER_REQUEST table with a hash key and TTL
- [complete](examples/complete) - Provisioned table with GSI, LSI, autoscaling (table and indexes), PITR, streams, KMS encryption and a resource policy

## Naming Convention

Table names follow the convention:

```
{region_prefix}-dynamodb-{account_name}-{project_name}[-{table_name_suffix}]
```

Example: `ause1-dynamodb-dev-myapp-users`

- `region_prefix` is derived from the provider region (`data.aws_region.current.region`), or set explicitly with `region_prefix`.
- Set `use_region_prefix = false` to omit the region prefix.
- Set `name` to override the generated name completely.

Every table gets the tags `merge(tags_common, tags, { Name = <table name>, ManagedBy = "Terraform" })`.

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | >= 1.3  |
| aws       | >= 6.30 |

AWS provider 6.30 is the first release that accepts the `key_schema` blocks used for GSIs.

## Resources

| Name | Type |
| ---- | ---- |
| `aws_dynamodb_table.this` | resource (no autoscaling) |
| `aws_dynamodb_table.autoscaled` | resource (autoscaling, ignores capacity changes) |
| `aws_dynamodb_table.autoscaled_gsi_ignore` | resource (autoscaling, also ignores GSI changes) |
| `aws_dynamodb_resource_policy.this` | resource |
| `aws_appautoscaling_target.table_read` / `table_write` / `index_read` / `index_write` | resource |
| `aws_appautoscaling_policy.table_read_policy` / `table_write_policy` / `index_read_policy` / `index_write_policy` | resource |
| `aws_region.current` | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| account_name | Account name for resource naming (1-32 chars, `^[a-z0-9-]+$`) | `string` | n/a | yes |
| project_name | Project name for resource naming (1-32 chars, `^[a-z0-9-]+$`) | `string` | n/a | yes |
| region_prefix | Override for the auto-detected region prefix | `string` | `null` | no |
| use_region_prefix | Whether to include the region prefix in the table name | `bool` | `true` | no |
| table_name_suffix | Optional suffix appended to the generated table name | `string` | `null` | no |
| name | Explicit table name; overrides the generated name | `string` | `null` | no |
| create_table | Controls if the table and associated resources are created | `bool` | `true` | no |
| attributes | Attribute definitions (`name`, `type` = S/N/B) for table and index keys | `list(map(string))` | `[]` | no |
| hash_key | Partition key attribute | `string` | `null` | no |
| range_key | Sort key attribute | `string` | `null` | no |
| billing_mode | `PROVISIONED` or `PAY_PER_REQUEST` | `string` | `"PAY_PER_REQUEST"` | no |
| read_capacity | Read units (PROVISIONED); also the autoscaling minimum | `number` | `null` | no |
| write_capacity | Write units (PROVISIONED); also the autoscaling minimum | `number` | `null` | no |
| table_class | `STANDARD` or `STANDARD_INFREQUENT_ACCESS` | `string` | `null` | no |
| deletion_protection_enabled | Enables deletion protection for the table | `bool` | `null` | no |
| ttl_enabled | Whether TTL is enabled | `bool` | `false` | no |
| ttl_attribute_name | TTL attribute name | `string` | `""` | no |
| point_in_time_recovery_enabled | Whether point-in-time recovery is enabled | `bool` | `false` | no |
| point_in_time_recovery_period_in_days | PITR retention in days | `number` | `null` | no |
| stream_enabled | Whether DynamoDB Streams is enabled | `bool` | `false` | no |
| stream_view_type | `KEYS_ONLY`, `NEW_IMAGE`, `OLD_IMAGE` or `NEW_AND_OLD_IMAGES` | `string` | `null` | no |
| server_side_encryption_enabled | Encrypt with an AWS managed or customer managed KMS key | `bool` | `false` | no |
| server_side_encryption_kms_key_arn | KMS key ARN (requires `server_side_encryption_enabled = true`) | `string` | `null` | no |
| global_secondary_indexes | GSIs: `name`, `hash_key`, `projection_type`; optional `range_key`, `read_capacity`, `write_capacity`, `non_key_attributes`, `on_demand_throughput`, `warm_throughput` | `any` | `[]` | no |
| local_secondary_indexes | LSIs: `name`, `range_key`, `projection_type`; optional `non_key_attributes` | `any` | `[]` | no |
| replica_regions | Replicas: `region_name`; optional `kms_key_arn`, `propagate_tags`, `point_in_time_recovery`, `consistency_mode`, `deletion_protection_enabled` | `any` | `[]` | no |
| import_table | S3 import configuration (see [Import from S3](#import-from-s3)) | `any` | `{}` | no |
| on_demand_throughput | `max_read_request_units`, `max_write_request_units` | `any` | `{}` | no |
| warm_throughput | `read_units_per_second`, `write_units_per_second` | `any` | `{}` | no |
| global_table_witness | Witness region for Multi-Region Strong Consistency (`this` variant only) | `object({ region_name = optional(string) })` | `null` | no |
| restore_date_time | Point-in-time recovery point to restore | `string` | `null` | no |
| restore_source_name | Name of the table to restore | `string` | `null` | no |
| restore_source_table_arn | ARN of the source table (cross-region restores) | `string` | `null` | no |
| restore_to_latest_time | Restore to the most recent recovery point | `bool` | `null` | no |
| region | Region for the table, resource policy and autoscaling resources | `string` | `null` | no |
| resource_policy | JSON resource policy; `__DYNAMODB_TABLE_ARN__` is replaced with the table ARN | `string` | `null` | no |
| ignore_changes_global_secondary_index | Ignore GSI changes (autoscaling only) | `bool` | `false` | no |
| autoscaling_enabled | Enable autoscaling (requires `PROVISIONED`) | `bool` | `false` | no |
| autoscaling_defaults | Default `scale_in_cooldown`, `scale_out_cooldown`, `target_value` | `map(string)` | `{ scale_in_cooldown = 0, scale_out_cooldown = 0, target_value = 70 }` | no |
| autoscaling_read | Table read autoscaling (`max_capacity` required) | `map(string)` | `{}` | no |
| autoscaling_write | Table write autoscaling (`max_capacity` required) | `map(string)` | `{}` | no |
| autoscaling_indexes | Per-GSI autoscaling keyed by index name: `read_max_capacity`, `write_max_capacity`; optional `read_min_capacity`, `write_min_capacity`, cooldowns, `target_value` | `map(map(string))` | `{}` | no |
| timeouts | `create`, `update`, `delete` timeouts | `map(string)` | `{ create = "10m", update = "60m", delete = "10m" }` | no |
| tags_common | Common tags applied to all resources | `map(string)` | `{}` | no |
| tags | Additional tags for this table | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| dynamodb_table_arn | ARN of the DynamoDB table |
| dynamodb_table_id | ID of the DynamoDB table |
| dynamodb_table_name | Name of the DynamoDB table |
| dynamodb_table_stream_arn | ARN of the table stream |
| dynamodb_table_stream_label | ISO 8601 timestamp of the table stream |
| dynamodb_table_replicas | Map of table replicas by region |
| dynamodb_table_replica_arns | Map of replica ARNs by region |
| dynamodb_table_replica_stream_arns | Map of replica stream ARNs by region |
| dynamodb_table_replica_stream_labels | Map of replica stream labels by region |

## License

MIT Licensed. See [LICENSE](LICENSE) for full details.
