################################################################################
# Outputs
################################################################################

locals {
  # Resolve table attributes from whichever variant was created
  table_id = try(
    aws_dynamodb_table.this[0].id,
    aws_dynamodb_table.autoscaled[0].id,
    aws_dynamodb_table.autoscaled_gsi_ignore[0].id,
    ""
  )

  table_stream_arn = try(
    aws_dynamodb_table.this[0].stream_arn,
    aws_dynamodb_table.autoscaled[0].stream_arn,
    aws_dynamodb_table.autoscaled_gsi_ignore[0].stream_arn,
    ""
  )

  table_stream_label = try(
    aws_dynamodb_table.this[0].stream_label,
    aws_dynamodb_table.autoscaled[0].stream_label,
    aws_dynamodb_table.autoscaled_gsi_ignore[0].stream_label,
    ""
  )

  # Replica information
  replicas = try(
    { for v in aws_dynamodb_table.this[0].replica[*] : v.region_name => v },
    { for v in aws_dynamodb_table.autoscaled[0].replica[*] : v.region_name => v },
    { for v in aws_dynamodb_table.autoscaled_gsi_ignore[0].replica[*] : v.region_name => v },
    {}
  )

  replica_arns = { for k, v in local.replicas : k => v.arn }

  replica_stream_arns = { for k, v in local.replicas : k => v.stream_arn }

  replica_stream_labels = { for k, v in local.replicas : k => v.stream_label }
}

################################################################################
# Table Outputs
################################################################################

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  value       = local.table_arn
}

output "dynamodb_table_id" {
  description = "ID of the DynamoDB table"
  value       = local.table_id
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = local.table_name
}

output "dynamodb_table_stream_arn" {
  description = "The ARN of the Table Stream. Only available when stream_enabled = true."
  value       = local.table_stream_arn
}

output "dynamodb_table_stream_label" {
  description = "A timestamp, in ISO 8601 format, for this stream. Only available when stream_enabled = true."
  value       = local.table_stream_label
}

################################################################################
# Replica Outputs
################################################################################

output "dynamodb_table_replicas" {
  description = "Map of DynamoDB table replicas by region"
  value       = local.replicas
}

output "dynamodb_table_replica_arns" {
  description = "Map of DynamoDB table replica ARNs by region"
  value       = local.replica_arns
}

output "dynamodb_table_replica_stream_arns" {
  description = "Map of DynamoDB table replica stream ARNs by region"
  value       = local.replica_stream_arns
}

output "dynamodb_table_replica_stream_labels" {
  description = "Map of DynamoDB table replica stream labels (timestamps) by region"
  value       = local.replica_stream_labels
}
