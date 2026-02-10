################################################################################
# Complete DynamoDB Table Example
# Provisioned table with autoscaling, GSI, LSI, TTL, PITR, Streams, SSE
################################################################################

provider "aws" {
  region = "us-east-1"
}

################################################################################
# KMS Key for Encryption
################################################################################

resource "aws_kms_key" "dynamodb" {
  description             = "KMS key for DynamoDB encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

################################################################################
# DynamoDB Table with All Features
################################################################################

module "dynamodb" {
  source = "../../dynamodb"

  account_name      = "prod"
  project_name      = "example"
  table_name_suffix = "orders"

  # Provisioned billing with autoscaling
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "order_id"
  range_key      = "created_at"

  # Attributes
  attributes = [
    { name = "order_id", type = "S" },
    { name = "created_at", type = "N" },
    { name = "user_id", type = "S" },
    { name = "status", type = "S" },
  ]

  # GSI
  global_secondary_indexes = [
    {
      name            = "UserIndex"
      hash_key        = "user_id"
      range_key       = "created_at"
      projection_type = "ALL"
      read_capacity   = 5
      write_capacity  = 5
    },
    {
      name            = "StatusIndex"
      hash_key        = "status"
      projection_type = "KEYS_ONLY"
      read_capacity   = 3
      write_capacity  = 3
    }
  ]

  # LSI
  local_secondary_indexes = [
    {
      name            = "StatusLocalIndex"
      range_key       = "status"
      projection_type = "ALL"
    }
  ]

  # TTL
  ttl_enabled        = true
  ttl_attribute_name = "expires_at"

  # PITR
  point_in_time_recovery_enabled = true

  # Streams
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  # Encryption
  server_side_encryption_enabled     = true
  server_side_encryption_kms_key_arn = aws_kms_key.dynamodb.arn

  # Table class
  table_class = "STANDARD"

  # Deletion protection
  deletion_protection_enabled = false

  # Autoscaling
  autoscaling_enabled = true

  autoscaling_read = {
    max_capacity = 100
    target_value = 70
  }

  autoscaling_write = {
    max_capacity = 100
    target_value = 70
  }

  autoscaling_indexes = {
    UserIndex = {
      read_max_capacity  = 50
      write_max_capacity = 50
    }
    StatusIndex = {
      read_max_capacity  = 30
      write_max_capacity = 30
    }
  }

  tags_common = {
    Environment = "prod"
    ManagedBy   = "Terraform"
  }

  tags = {
    Service = "orders"
  }
}

################################################################################
# Outputs
################################################################################

output "table_name" {
  value = module.dynamodb.dynamodb_table_name
}

output "table_arn" {
  value = module.dynamodb.dynamodb_table_arn
}

output "table_stream_arn" {
  value = module.dynamodb.dynamodb_table_stream_arn
}
