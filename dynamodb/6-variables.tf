################################################################################
# Naming & Convention Variables
################################################################################

variable "account_name" {
  description = "Account name for resource naming convention"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming convention"
  type        = string
}

variable "region_prefix" {
  description = "Override for the auto-detected region prefix (e.g., 'ause1' for us-east-1)"
  type        = string
  default     = null
}

variable "table_name_suffix" {
  description = "Optional suffix appended to the generated table name. Used when deploying multiple tables."
  type        = string
  default     = null
}

variable "name" {
  description = "Name of the DynamoDB table. If provided, overrides the auto-generated name completely."
  type        = string
  default     = null
}

################################################################################
# Table Configuration
################################################################################

variable "create_table" {
  description = "Controls if DynamoDB table and associated resources are created"
  type        = bool
  default     = true
}

variable "attributes" {
  description = "List of nested attribute definitions. Only required for hash_key, range_key, and index keys. Each element must have 'name' and 'type' (S, N, or B)."
  type        = list(map(string))
  default     = []
}

variable "hash_key" {
  description = "The attribute to use as the hash (partition) key. Must also be defined in attributes."
  type        = string
  default     = null
}

variable "range_key" {
  description = "The attribute to use as the range (sort) key. Must also be defined in attributes."
  type        = string
  default     = null
}

variable "billing_mode" {
  description = "Controls how you are charged for read and write throughput. Valid values: PROVISIONED or PAY_PER_REQUEST."
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PROVISIONED", "PAY_PER_REQUEST"], var.billing_mode)
    error_message = "billing_mode must be either 'PROVISIONED' or 'PAY_PER_REQUEST'."
  }
}

variable "read_capacity" {
  description = "The number of read units for this table. Required if billing_mode is PROVISIONED."
  type        = number
  default     = null
}

variable "write_capacity" {
  description = "The number of write units for this table. Required if billing_mode is PROVISIONED."
  type        = number
  default     = null
}

variable "table_class" {
  description = "The storage class of the table. Valid values: STANDARD or STANDARD_INFREQUENT_ACCESS."
  type        = string
  default     = null

  validation {
    condition     = var.table_class == null || contains(["STANDARD", "STANDARD_INFREQUENT_ACCESS"], coalesce(var.table_class, "STANDARD"))
    error_message = "table_class must be either 'STANDARD' or 'STANDARD_INFREQUENT_ACCESS'."
  }
}

variable "deletion_protection_enabled" {
  description = "Enables deletion protection for the table"
  type        = bool
  default     = null
}

################################################################################
# TTL
################################################################################

variable "ttl_enabled" {
  description = "Indicates whether TTL is enabled"
  type        = bool
  default     = false
}

variable "ttl_attribute_name" {
  description = "The name of the table attribute to store the TTL timestamp in"
  type        = string
  default     = ""
}

################################################################################
# Point-in-Time Recovery
################################################################################

variable "point_in_time_recovery_enabled" {
  description = "Whether to enable point-in-time recovery"
  type        = bool
  default     = false
}

variable "point_in_time_recovery_period_in_days" {
  description = "Number of preceding days for which continuous backups are maintained (default 35 if PITR enabled)"
  type        = number
  default     = null
}

################################################################################
# Streams
################################################################################

variable "stream_enabled" {
  description = "Indicates whether DynamoDB Streams is enabled on the table"
  type        = bool
  default     = false
}

variable "stream_view_type" {
  description = "When an item in the table is modified, what information is written to the stream. Valid values: KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES."
  type        = string
  default     = null
}

################################################################################
# Server-Side Encryption
################################################################################

variable "server_side_encryption_enabled" {
  description = "Whether to enable encryption at rest using an AWS managed KMS customer master key (CMK)"
  type        = bool
  default     = false
}

variable "server_side_encryption_kms_key_arn" {
  description = "The ARN of the CMK that should be used for the AWS KMS encryption. Requires server_side_encryption_enabled = true."
  type        = string
  default     = null
}

################################################################################
# Global Secondary Indexes
################################################################################

variable "global_secondary_indexes" {
  description = "Describe a GSI for the table. Attributes: name, hash_key, projection_type (required); range_key, read_capacity, write_capacity, non_key_attributes, on_demand_throughput, warm_throughput (optional)."
  type        = any
  default     = []
}

################################################################################
# Local Secondary Indexes
################################################################################

variable "local_secondary_indexes" {
  description = "Describe an LSI on the table. Can only be created at table creation time. Attributes: name, range_key, projection_type (required); non_key_attributes (optional)."
  type        = any
  default     = []
}

################################################################################
# Replicas (Global Tables)
################################################################################

variable "replica_regions" {
  description = "Region names for creating replicas for a global DynamoDB table. Each element: region_name (required); kms_key_arn, propagate_tags, point_in_time_recovery, consistency_mode, deletion_protection_enabled (optional)."
  type        = any
  default     = []
}

################################################################################
# S3 Import
################################################################################

variable "import_table" {
  description = "Configurations for importing S3 data into a new table. Keys: input_format (required), s3_bucket_source (required: bucket, bucket_owner, key_prefix), input_compression_type, input_format_options."
  type        = any
  default     = {}
}

################################################################################
# On-Demand & Warm Throughput
################################################################################

variable "on_demand_throughput" {
  description = "Sets the maximum number of read and write units for on-demand tables. Keys: max_read_request_units, max_write_request_units."
  type        = any
  default     = {}
}

variable "warm_throughput" {
  description = "Sets the warm throughput (read/write units per second) for the table. Keys: read_units_per_second, write_units_per_second."
  type        = any
  default     = {}
}

################################################################################
# Global Table Witness
################################################################################

variable "global_table_witness" {
  description = "Witness Region in a Multi-Region Strong Consistency deployment. Only applicable for the 'this' (non-autoscaled) variant."
  type = object({
    region_name = optional(string)
  })
  default = null
}

################################################################################
# Restore from Point-in-Time
################################################################################

variable "restore_date_time" {
  description = "Time of the point-in-time recovery point to restore"
  type        = string
  default     = null
}

variable "restore_source_name" {
  description = "Name of the table to restore. Must be in the same account and region."
  type        = string
  default     = null
}

variable "restore_source_table_arn" {
  description = "ARN of the source table for cross-region restores"
  type        = string
  default     = null
}

variable "restore_to_latest_time" {
  description = "If set, restores table to the most recent point-in-time recovery point"
  type        = bool
  default     = null
}

################################################################################
# Region Override
################################################################################

variable "region" {
  description = "Region where this DynamoDB table resource will be managed. Defaults to provider region."
  type        = string
  default     = null
}

################################################################################
# Resource Policy
################################################################################

variable "resource_policy" {
  description = "JSON resource-based policy to attach to the DynamoDB table. Use __DYNAMODB_TABLE_ARN__ as a placeholder for the table ARN."
  type        = string
  default     = null
}

################################################################################
# Lifecycle Control
################################################################################

variable "ignore_changes_global_secondary_index" {
  description = "Whether to ignore changes for global secondary index (useful for provisioned tables with autoscaling on indexes)"
  type        = bool
  default     = false
}

################################################################################
# Autoscaling
################################################################################

variable "autoscaling_enabled" {
  description = "Whether or not to enable autoscaling. Requires billing_mode = PROVISIONED."
  type        = bool
  default     = false
}

variable "autoscaling_defaults" {
  description = "A map of default autoscaling settings. Keys: scale_in_cooldown, scale_out_cooldown, target_value."
  type        = map(string)
  default = {
    scale_in_cooldown  = 0
    scale_out_cooldown = 0
    target_value       = 70
  }
}

variable "autoscaling_read" {
  description = "A map of read autoscaling settings. max_capacity is required. Optional: scale_in_cooldown, scale_out_cooldown, target_value."
  type        = map(string)
  default     = {}
}

variable "autoscaling_write" {
  description = "A map of write autoscaling settings. max_capacity is required. Optional: scale_in_cooldown, scale_out_cooldown, target_value."
  type        = map(string)
  default     = {}
}

variable "autoscaling_indexes" {
  description = "A map of index autoscaling configurations. Keys are GSI names. Each value must have read_max_capacity and write_max_capacity. Optional: scale_in_cooldown, scale_out_cooldown, target_value."
  type        = map(map(string))
  default     = {}
}

################################################################################
# Timeouts
################################################################################

variable "timeouts" {
  description = "Terraform resource management timeouts. Keys: create, update, delete."
  type        = map(string)
  default = {
    create = "10m"
    update = "60m"
    delete = "10m"
  }
}

################################################################################
# Tags
################################################################################

variable "tags_common" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags specific to this table (merged with tags_common)"
  type        = map(string)
  default     = {}
}
