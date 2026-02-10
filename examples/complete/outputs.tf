output "table_name" {
  description = "Name of the DynamoDB table"
  value       = module.dynamodb.dynamodb_table_name
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = module.dynamodb.dynamodb_table_arn
}

output "table_id" {
  description = "ID of the DynamoDB table"
  value       = module.dynamodb.dynamodb_table_id
}

output "table_stream_arn" {
  description = "Stream ARN of the DynamoDB table"
  value       = module.dynamodb.dynamodb_table_stream_arn
}

output "table_stream_label" {
  description = "Stream label of the DynamoDB table"
  value       = module.dynamodb.dynamodb_table_stream_label
}

output "kms_key_arn" {
  description = "KMS key ARN used for encryption"
  value       = aws_kms_key.dynamodb.arn
}
