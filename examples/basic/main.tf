################################################################################
# Basic DynamoDB Table Example
# Simple PAY_PER_REQUEST table with hash key only
################################################################################

provider "aws" {
  region = "us-east-1"
}

module "dynamodb" {
  source = "../../dynamodb"

  account_name      = "dev"
  project_name      = "example"
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
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

output "table_name" {
  value = module.dynamodb.dynamodb_table_name
}

output "table_arn" {
  value = module.dynamodb.dynamodb_table_arn
}
