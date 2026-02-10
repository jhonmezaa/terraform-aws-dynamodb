################################################################################
# Basic DynamoDB Table Example
# Simple PAY_PER_REQUEST table with hash key, TTL
################################################################################

module "dynamodb" {
  source = "../../dynamodb"

  account_name      = var.account_name
  project_name      = var.project_name
  table_name_suffix = "users"

  hash_key = "user_id"

  attributes = [
    {
      name = "user_id"
      type = "S"
    }
  ]

  ttl_enabled        = true
  ttl_attribute_name = "expires_at"

  tags_common = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
