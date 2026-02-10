################################################################################
# Complete DynamoDB Table Example
# Provisioned table with autoscaling, GSI, LSI, TTL, PITR, Streams, KMS SSE,
# resource policy, table class, deletion protection
################################################################################

data "aws_caller_identity" "current" {}

################################################################################
# KMS Key for Encryption
################################################################################

resource "aws_kms_key" "dynamodb" {
  description             = "KMS key for DynamoDB encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "dynamodb-example-kms-key"
  }
}

################################################################################
# DynamoDB Table with All Features
################################################################################

module "dynamodb" {
  source = "../../dynamodb"

  account_name      = var.account_name
  project_name      = var.project_name
  table_name_suffix = "orders"

  # Provisioned billing with autoscaling
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "order_id"
  range_key      = "created_at"

  # Attributes (must include all keys used in table, GSI, and LSI)
  attributes = [
    { name = "order_id", type = "S" },
    { name = "created_at", type = "N" },
    { name = "user_id", type = "S" },
    { name = "status", type = "S" },
  ]

  # Global Secondary Indexes
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

  # Local Secondary Index
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

  # Point-in-Time Recovery
  point_in_time_recovery_enabled = true

  # DynamoDB Streams
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  # KMS Encryption
  server_side_encryption_enabled     = true
  server_side_encryption_kms_key_arn = aws_kms_key.dynamodb.arn

  # Table class
  table_class = "STANDARD"

  # Deletion protection (disabled for example purposes)
  deletion_protection_enabled = false

  # Resource-based policy (uses __DYNAMODB_TABLE_ARN__ template)
  resource_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
        ]
        Resource = "__DYNAMODB_TABLE_ARN__"
      }
    ]
  })

  # Autoscaling
  autoscaling_enabled = true

  autoscaling_read = {
    max_capacity       = 100
    target_value       = 70
    scale_in_cooldown  = 60
    scale_out_cooldown = 30
  }

  autoscaling_write = {
    max_capacity       = 100
    target_value       = 70
    scale_in_cooldown  = 60
    scale_out_cooldown = 30
  }

  # Per-index autoscaling
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

  # Custom timeouts
  timeouts = {
    create = "15m"
    update = "60m"
    delete = "15m"
  }

  # Tags
  tags_common = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  tags = {
    Service = "orders"
    Tier    = "backend"
  }
}
