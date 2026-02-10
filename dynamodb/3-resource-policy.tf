################################################################################
# DynamoDB Resource-Based Policy
#
# Supports template variable __DYNAMODB_TABLE_ARN__ which gets replaced with
# the actual table ARN, allowing self-referencing in the policy document.
################################################################################

resource "aws_dynamodb_resource_policy" "this" {
  count = var.create_table && var.resource_policy != null ? 1 : 0

  resource_arn = local.table_arn
  policy       = replace(var.resource_policy, "__DYNAMODB_TABLE_ARN__", local.table_arn)
}
