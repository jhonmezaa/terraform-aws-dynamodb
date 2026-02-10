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
  source = "./dynamodb"

  account_name = "dev"
  project_name = "myapp"
  table_name_suffix = "users"

  hash_key = "user_id"

  attributes = [
    { name = "user_id", type = "S" }
  ]

  tags_common = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

### Provisioned Table with Autoscaling

```hcl
module "dynamodb" {
  source = "./dynamodb"

  account_name = "prod"
  project_name = "myapp"
  table_name_suffix = "orders"

  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "order_id"
  range_key      = "created_at"

  attributes = [
    { name = "order_id",   type = "S" },
    { name = "created_at", type = "N" },
    { name = "user_id",    type = "S" }
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
      read_max_capacity  = 50
      write_max_capacity = 50
    }
  }
}
```

## Naming Convention

Table names follow the monorepo convention:

```
{region_prefix}-dynamodb-{account_name}-{project_name}[-{table_name_suffix}]
```

Example: `ause1-dynamodb-dev-myapp-users`

Override with `name` variable to use a custom name.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.7 |
| aws | >= 5.0 |

## License

MIT Licensed. See [LICENSE](LICENSE) for full details.
