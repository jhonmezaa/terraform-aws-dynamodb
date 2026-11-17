# Changelog

All notable changes to this project will be documented in this file.

## [v1.2.0] - 2026-11-17

### Added

- `autoscaling_indexes` accepts optional `read_min_capacity` / `write_min_capacity` per index (defaults to `read_capacity` / `write_capacity`, as before)
- `import_table` accepts the flat, upstream-compatible form (`bucket`, `bucket_owner`, `key_prefix` at the top level) in addition to the nested `s3_bucket_source` object
- `replica_regions[*].deletion_protection_enabled` is now applied in the `autoscaled` and `autoscaled_gsi_ignore` variants too (it was only applied in `this`)
- `account_name` and `project_name` validation (1-32 characters, `^[a-z0-9-]+$`)
- README: inputs, outputs, resources, examples and a versioned `source`

### Changed

- AWS provider minimum raised from `>= 6.0` to `>= 6.30` (examples: `~> 6.30`). The GSI `key_schema` blocks used since v1.0.1 do not validate with earlier provider releases
- Tags now follow `merge(tags_common, tags, { Name, ManagedBy = "Terraform" })`; `tags` can no longer override `Name`
- Removed the unused `aws_caller_identity` data source

### Fixed

- Autoscaling targets/policies and the resource policy now use `var.region`, so they are created in the same region as the table when `region` is set

### Upgrade notes

- Existing tables gain a `ManagedBy = "Terraform"` tag: in-place tag update, no recreation
- `account_name` / `project_name` values with uppercase letters, underscores or other characters now fail validation. To comply without renaming (and recreating) the table, switch them to valid values and set `name` to the current table name
- Requires AWS provider >= 6.30

## [v1.1.5] - 2026-10-27

### Changed

- Normalize CHANGELOG format: preamble moved to the top, all headings use `## [vX.Y.Z] - YYYY-MM-DD`, entries sorted by version (newest first)
- Add missing CHANGELOG entries for v1.1.0 and v1.1.1, reconstructed from git history

## [v1.1.4] - 2026-10-27

### Fixed

- Replace deprecated `data.aws_region.current.id` with `data.aws_region.current.region` (AWS provider v6)

## [v1.1.3] - 2026-10-27

### Changed

- Use minimum-only version constraints in the reusable module, per HashiCorp guidance: AWS provider `~> 6.0` -> `>= 6.0`
- Set module `required_version` to `>= 1.3` (was `~> 1.0`), the real minimum required by the use of `optional()` object attributes in variable types (Terraform 1.3+)
- Examples (root modules) keep pessimistic constraints: `required_version` `~> 1.3` and AWS provider `~> 6.0`
- Update README requirements table

## [v1.1.2] - 2026-04-25

### Changed

- Update README documentation and CHANGELOG formatting

## [v1.1.1] - 2026-02-28

### Changed

- Update README documentation and CHANGELOG formatting

## [v1.1.0] - 2026-02-28

### Added

- `use_region_prefix` variable to toggle the region prefix in table names (wires up the previously declared but unused variable via a new `name_prefix` local)

## [v1.0.4] - 2026-02-27

### Changed

- Standardize Terraform `required_version` to `~> 1.0` across module and examples

## [v1.0.3] - 2026-02-27

### Changed

- Update AWS provider constraint to `~> 6.0` across module and examples

## [v1.0.2] - 2026-02-09

### Improved

- Completed examples with full file structure (`versions.tf`, `providers.tf`, `variables.tf`, `main.tf`, `outputs.tf`, `terraform.tfvars`)
- Added resource policy and custom timeouts to complete example

## [v1.0.1] - 2026-02-09

### Fixed

- Migrated GSI `hash_key`/`range_key` to `key_schema` blocks to eliminate deprecation warnings in AWS provider >= 6.x

## [v1.0.0] - 2026-02-09

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
