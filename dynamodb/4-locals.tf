################################################################################
# Local Values
################################################################################

locals {
  ############################################################################
  # Region Prefix Map
  ############################################################################

  region_prefix_map = {
    "us-east-1"      = "ause1"
    "us-east-2"      = "ause2"
    "us-west-1"      = "usw1"
    "us-west-2"      = "usw2"
    "af-south-1"     = "afs1"
    "ap-east-1"      = "ape1"
    "ap-south-1"     = "aps1"
    "ap-south-2"     = "aps2"
    "ap-southeast-1" = "apse1"
    "ap-southeast-2" = "apse2"
    "ap-southeast-3" = "apse3"
    "ap-southeast-4" = "apse4"
    "ap-northeast-1" = "apne1"
    "ap-northeast-2" = "apne2"
    "ap-northeast-3" = "apne3"
    "ca-central-1"   = "cac1"
    "ca-west-1"      = "caw1"
    "eu-central-1"   = "euc1"
    "eu-central-2"   = "euc2"
    "eu-west-1"      = "euw1"
    "eu-west-2"      = "euw2"
    "eu-west-3"      = "euw3"
    "eu-south-1"     = "eus1"
    "eu-south-2"     = "eus2"
    "eu-north-1"     = "eun1"
    "il-central-1"   = "ilc1"
    "me-south-1"     = "mes1"
    "me-central-1"   = "mec1"
    "sa-east-1"      = "sae1"
  }

  region_prefix = var.region_prefix != null ? var.region_prefix : lookup(
    local.region_prefix_map,
    data.aws_region.current.id,
    "unknown"
  )

  ############################################################################
  # Table Naming
  ############################################################################

  # If var.name is provided, use it directly.
  # Otherwise, generate: {region_prefix}-dynamodb-{account_name}-{project_name}[-{table_name_suffix}]
  generated_name = var.table_name_suffix != null ? (
    "${local.region_prefix}-dynamodb-${var.account_name}-${var.project_name}-${var.table_name_suffix}"
  ) : "${local.region_prefix}-dynamodb-${var.account_name}-${var.project_name}"

  table_name = var.name != null ? var.name : local.generated_name

  ############################################################################
  # Table ARN (resolved from whichever variant was created)
  ############################################################################

  table_arn = try(
    aws_dynamodb_table.this[0].arn,
    aws_dynamodb_table.autoscaled[0].arn,
    aws_dynamodb_table.autoscaled_gsi_ignore[0].arn,
    ""
  )

  ############################################################################
  # Tags
  ############################################################################

  tags = merge(
    var.tags_common,
    {
      Name = local.table_name
    },
    var.tags
  )
}
