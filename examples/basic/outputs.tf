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
