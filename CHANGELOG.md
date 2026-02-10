# Changelog

All notable changes to this project will be documented in this file.

## [1.0.1] - 2026-02-09

### Fixed

- Migrated GSI `hash_key`/`range_key` to `key_schema` blocks to eliminate deprecation warnings in AWS provider >= 6.x

## [1.0.0] - 2026-02-09

### Added

- DynamoDB table with 3 mutually exclusive variants for lifecycle management:
  - `this` - Standard table without autoscaling
  - `autoscaled` - Table with autoscaling (ignores read/write capacity changes)
  - `autoscaled_gsi_ignore` - Table with autoscaling + ignore GSI changes
- Billing mode support (PAY_PER_REQUEST / PROVISIONED)
- Hash key and range key configuration
- Dynamic attributes (S, N, B types)
- Global Secondary Indexes with on-demand and warm throughput support
- Local Secondary Indexes
- TTL (Time-to-Live) configuration
- Point-in-Time Recovery (PITR) with configurable retention
- DynamoDB Streams support
- Server-side encryption (AWS managed / custom KMS)
- Table class support (STANDARD / STANDARD_INFREQUENT_ACCESS)
- Deletion protection
- S3 import for table data
- On-demand throughput configuration
- Warm throughput configuration
- Global table witness for multi-region strong consistency
- Application Auto Scaling for table and index read/write capacity
- Replica support for Global Tables (multi-region)
- Resource-based policy with `__DYNAMODB_TABLE_ARN__` template support
- Restore from Point-in-Time Recovery
- Region override support
- Configurable timeouts (create, update, delete)
- Monorepo naming convention: `{region_prefix}-dynamodb-{account_name}-{project_name}[-{suffix}]`
- Region prefix auto-detection from 29 AWS regions
- Common tags support with per-table tag overrides
