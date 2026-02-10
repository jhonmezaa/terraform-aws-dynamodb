################################################################################
# DynamoDB Table - 3 Mutually Exclusive Variants
#
# Why 3 resources?
# Terraform's lifecycle.ignore_changes does NOT support dynamic expressions.
# When autoscaling is enabled, we must ignore read/write capacity changes
# (autoscaling modifies them outside Terraform). If GSI ignore is also needed,
# we must ignore global_secondary_index as well. Each combination requires a
# separate resource block with static lifecycle configuration.
#
# Variant 1: this                  - No autoscaling (no lifecycle ignore)
# Variant 2: autoscaled            - Autoscaling enabled (ignore capacity)
# Variant 3: autoscaled_gsi_ignore - Autoscaling + ignore GSI changes
################################################################################

################################################################################
# Variant 1: No Autoscaling (standard table)
################################################################################

resource "aws_dynamodb_table" "this" {
  count = var.create_table && !var.autoscaling_enabled ? 1 : 0

  name                        = local.table_name
  billing_mode                = var.billing_mode
  hash_key                    = var.hash_key
  range_key                   = var.range_key
  read_capacity               = var.read_capacity
  write_capacity              = var.write_capacity
  stream_enabled              = var.stream_enabled
  stream_view_type            = var.stream_view_type
  table_class                 = var.table_class
  deletion_protection_enabled = var.deletion_protection_enabled
  region                      = var.region
  restore_date_time           = var.restore_date_time
  restore_source_name         = var.restore_source_name
  restore_source_table_arn    = var.restore_source_table_arn
  restore_to_latest_time      = var.restore_to_latest_time

  ttl {
    enabled        = var.ttl_enabled
    attribute_name = var.ttl_attribute_name
  }

  point_in_time_recovery {
    enabled                 = var.point_in_time_recovery_enabled
    recovery_period_in_days = var.point_in_time_recovery_period_in_days
  }

  dynamic "attribute" {
    for_each = var.attributes

    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "local_secondary_index" {
    for_each = var.local_secondary_indexes

    content {
      name               = local_secondary_index.value.name
      range_key          = local_secondary_index.value.range_key
      projection_type    = local_secondary_index.value.projection_type
      non_key_attributes = lookup(local_secondary_index.value, "non_key_attributes", null)
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes

    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      projection_type    = global_secondary_index.value.projection_type
      range_key          = lookup(global_secondary_index.value, "range_key", null)
      read_capacity      = lookup(global_secondary_index.value, "read_capacity", null)
      write_capacity     = lookup(global_secondary_index.value, "write_capacity", null)
      non_key_attributes = lookup(global_secondary_index.value, "non_key_attributes", null)

      dynamic "on_demand_throughput" {
        for_each = try([global_secondary_index.value.on_demand_throughput], [])

        content {
          max_read_request_units  = try(on_demand_throughput.value.max_read_request_units, null)
          max_write_request_units = try(on_demand_throughput.value.max_write_request_units, null)
        }
      }

      dynamic "warm_throughput" {
        for_each = try([global_secondary_index.value.warm_throughput], [])

        content {
          read_units_per_second  = try(warm_throughput.value.read_units_per_second, null)
          write_units_per_second = try(warm_throughput.value.write_units_per_second, null)
        }
      }
    }
  }

  dynamic "replica" {
    for_each = var.replica_regions

    content {
      region_name                 = replica.value.region_name
      kms_key_arn                 = lookup(replica.value, "kms_key_arn", null)
      propagate_tags              = lookup(replica.value, "propagate_tags", null)
      point_in_time_recovery      = lookup(replica.value, "point_in_time_recovery", null)
      consistency_mode            = lookup(replica.value, "consistency_mode", null)
      deletion_protection_enabled = lookup(replica.value, "deletion_protection_enabled", null)
    }
  }

  server_side_encryption {
    enabled     = var.server_side_encryption_enabled
    kms_key_arn = var.server_side_encryption_kms_key_arn
  }

  dynamic "import_table" {
    for_each = length(var.import_table) > 0 ? [var.import_table] : []

    content {
      input_compression_type = lookup(import_table.value, "input_compression_type", null)
      input_format           = import_table.value.input_format

      dynamic "input_format_options" {
        for_each = try([import_table.value.input_format_options], [])

        content {
          dynamic "csv" {
            for_each = try([input_format_options.value.csv], [])

            content {
              delimiter   = try(csv.value.delimiter, null)
              header_list = try(csv.value.header_list, null)
            }
          }
        }
      }

      s3_bucket_source {
        bucket       = import_table.value.s3_bucket_source.bucket
        bucket_owner = lookup(import_table.value.s3_bucket_source, "bucket_owner", null)
        key_prefix   = lookup(import_table.value.s3_bucket_source, "key_prefix", null)
      }
    }
  }

  dynamic "on_demand_throughput" {
    for_each = length(var.on_demand_throughput) > 0 ? [var.on_demand_throughput] : []

    content {
      max_read_request_units  = try(on_demand_throughput.value.max_read_request_units, null)
      max_write_request_units = try(on_demand_throughput.value.max_write_request_units, null)
    }
  }

  dynamic "warm_throughput" {
    for_each = length(var.warm_throughput) > 0 ? [var.warm_throughput] : []

    content {
      read_units_per_second  = try(warm_throughput.value.read_units_per_second, null)
      write_units_per_second = try(warm_throughput.value.write_units_per_second, null)
    }
  }

  dynamic "global_table_witness" {
    for_each = var.global_table_witness != null ? [var.global_table_witness] : []

    content {
      region_name = global_table_witness.value.region_name
    }
  }

  tags = local.tags

  timeouts {
    create = lookup(var.timeouts, "create", "10m")
    update = lookup(var.timeouts, "update", "60m")
    delete = lookup(var.timeouts, "delete", "10m")
  }
}

################################################################################
# Variant 2: Autoscaling Enabled (ignore read/write capacity changes)
################################################################################

resource "aws_dynamodb_table" "autoscaled" {
  count = var.create_table && var.autoscaling_enabled && !var.ignore_changes_global_secondary_index ? 1 : 0

  name                        = local.table_name
  billing_mode                = var.billing_mode
  hash_key                    = var.hash_key
  range_key                   = var.range_key
  read_capacity               = var.read_capacity
  write_capacity              = var.write_capacity
  stream_enabled              = var.stream_enabled
  stream_view_type            = var.stream_view_type
  table_class                 = var.table_class
  deletion_protection_enabled = var.deletion_protection_enabled
  region                      = var.region
  restore_date_time           = var.restore_date_time
  restore_source_name         = var.restore_source_name
  restore_source_table_arn    = var.restore_source_table_arn
  restore_to_latest_time      = var.restore_to_latest_time

  ttl {
    enabled        = var.ttl_enabled
    attribute_name = var.ttl_attribute_name
  }

  point_in_time_recovery {
    enabled                 = var.point_in_time_recovery_enabled
    recovery_period_in_days = var.point_in_time_recovery_period_in_days
  }

  dynamic "attribute" {
    for_each = var.attributes

    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "local_secondary_index" {
    for_each = var.local_secondary_indexes

    content {
      name               = local_secondary_index.value.name
      range_key          = local_secondary_index.value.range_key
      projection_type    = local_secondary_index.value.projection_type
      non_key_attributes = lookup(local_secondary_index.value, "non_key_attributes", null)
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes

    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      projection_type    = global_secondary_index.value.projection_type
      range_key          = lookup(global_secondary_index.value, "range_key", null)
      read_capacity      = lookup(global_secondary_index.value, "read_capacity", null)
      write_capacity     = lookup(global_secondary_index.value, "write_capacity", null)
      non_key_attributes = lookup(global_secondary_index.value, "non_key_attributes", null)

      dynamic "on_demand_throughput" {
        for_each = try([global_secondary_index.value.on_demand_throughput], [])

        content {
          max_read_request_units  = try(on_demand_throughput.value.max_read_request_units, null)
          max_write_request_units = try(on_demand_throughput.value.max_write_request_units, null)
        }
      }

      dynamic "warm_throughput" {
        for_each = try([global_secondary_index.value.warm_throughput], [])

        content {
          read_units_per_second  = try(warm_throughput.value.read_units_per_second, null)
          write_units_per_second = try(warm_throughput.value.write_units_per_second, null)
        }
      }
    }
  }

  dynamic "replica" {
    for_each = var.replica_regions

    content {
      region_name            = replica.value.region_name
      kms_key_arn            = lookup(replica.value, "kms_key_arn", null)
      propagate_tags         = lookup(replica.value, "propagate_tags", null)
      point_in_time_recovery = lookup(replica.value, "point_in_time_recovery", null)
      consistency_mode       = lookup(replica.value, "consistency_mode", null)
    }
  }

  server_side_encryption {
    enabled     = var.server_side_encryption_enabled
    kms_key_arn = var.server_side_encryption_kms_key_arn
  }

  dynamic "import_table" {
    for_each = length(var.import_table) > 0 ? [var.import_table] : []

    content {
      input_compression_type = lookup(import_table.value, "input_compression_type", null)
      input_format           = import_table.value.input_format

      dynamic "input_format_options" {
        for_each = try([import_table.value.input_format_options], [])

        content {
          dynamic "csv" {
            for_each = try([input_format_options.value.csv], [])

            content {
              delimiter   = try(csv.value.delimiter, null)
              header_list = try(csv.value.header_list, null)
            }
          }
        }
      }

      s3_bucket_source {
        bucket       = import_table.value.s3_bucket_source.bucket
        bucket_owner = lookup(import_table.value.s3_bucket_source, "bucket_owner", null)
        key_prefix   = lookup(import_table.value.s3_bucket_source, "key_prefix", null)
      }
    }
  }

  dynamic "on_demand_throughput" {
    for_each = length(var.on_demand_throughput) > 0 ? [var.on_demand_throughput] : []

    content {
      max_read_request_units  = try(on_demand_throughput.value.max_read_request_units, null)
      max_write_request_units = try(on_demand_throughput.value.max_write_request_units, null)
    }
  }

  dynamic "warm_throughput" {
    for_each = length(var.warm_throughput) > 0 ? [var.warm_throughput] : []

    content {
      read_units_per_second  = try(warm_throughput.value.read_units_per_second, null)
      write_units_per_second = try(warm_throughput.value.write_units_per_second, null)
    }
  }

  tags = local.tags

  timeouts {
    create = lookup(var.timeouts, "create", "10m")
    update = lookup(var.timeouts, "update", "60m")
    delete = lookup(var.timeouts, "delete", "10m")
  }

  lifecycle {
    ignore_changes = [read_capacity, write_capacity]
  }
}

################################################################################
# Variant 3: Autoscaling + Ignore GSI Changes
################################################################################

resource "aws_dynamodb_table" "autoscaled_gsi_ignore" {
  count = var.create_table && var.autoscaling_enabled && var.ignore_changes_global_secondary_index ? 1 : 0

  name                        = local.table_name
  billing_mode                = var.billing_mode
  hash_key                    = var.hash_key
  range_key                   = var.range_key
  read_capacity               = var.read_capacity
  write_capacity              = var.write_capacity
  stream_enabled              = var.stream_enabled
  stream_view_type            = var.stream_view_type
  table_class                 = var.table_class
  deletion_protection_enabled = var.deletion_protection_enabled
  region                      = var.region
  restore_date_time           = var.restore_date_time
  restore_source_name         = var.restore_source_name
  restore_source_table_arn    = var.restore_source_table_arn
  restore_to_latest_time      = var.restore_to_latest_time

  ttl {
    enabled        = var.ttl_enabled
    attribute_name = var.ttl_attribute_name
  }

  point_in_time_recovery {
    enabled                 = var.point_in_time_recovery_enabled
    recovery_period_in_days = var.point_in_time_recovery_period_in_days
  }

  dynamic "attribute" {
    for_each = var.attributes

    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "local_secondary_index" {
    for_each = var.local_secondary_indexes

    content {
      name               = local_secondary_index.value.name
      range_key          = local_secondary_index.value.range_key
      projection_type    = local_secondary_index.value.projection_type
      non_key_attributes = lookup(local_secondary_index.value, "non_key_attributes", null)
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes

    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      projection_type    = global_secondary_index.value.projection_type
      range_key          = lookup(global_secondary_index.value, "range_key", null)
      read_capacity      = lookup(global_secondary_index.value, "read_capacity", null)
      write_capacity     = lookup(global_secondary_index.value, "write_capacity", null)
      non_key_attributes = lookup(global_secondary_index.value, "non_key_attributes", null)
    }
  }

  dynamic "replica" {
    for_each = var.replica_regions

    content {
      region_name            = replica.value.region_name
      kms_key_arn            = lookup(replica.value, "kms_key_arn", null)
      propagate_tags         = lookup(replica.value, "propagate_tags", null)
      point_in_time_recovery = lookup(replica.value, "point_in_time_recovery", null)
      consistency_mode       = lookup(replica.value, "consistency_mode", null)
    }
  }

  server_side_encryption {
    enabled     = var.server_side_encryption_enabled
    kms_key_arn = var.server_side_encryption_kms_key_arn
  }

  tags = local.tags

  timeouts {
    create = lookup(var.timeouts, "create", "10m")
    update = lookup(var.timeouts, "update", "60m")
    delete = lookup(var.timeouts, "delete", "10m")
  }

  lifecycle {
    ignore_changes = [global_secondary_index, read_capacity, write_capacity]
  }
}
