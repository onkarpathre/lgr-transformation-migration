# ADR-005: Discovery-managed and business-managed server fields

Status: Accepted for Phase 2

## Decision

Discovery imports may create and maintain these current technical Server fields when the corresponding source value is present:

- `ExternalSourceId`
- `Environment`
- `OperatingSystem`
- `IpAddress` (first syntactically valid discovered address; all addresses remain in the snapshot)
- `VCores`
- `MemoryMb`
- `AllocatedStorageGb`
- `PowerStatus`
- `OsFamily`
- `OsArchitecture`
- `Processor`
- `HypervisorType`
- `Host`
- `SupportStatus`
- `DiscoveryMethod`
- `FirstDiscoveredAt`
- `LastDiscoveredAt`
- `LastImportBatchId`
- `LastImportedAt`

Discovery imports must not change business-managed fields or related business models, including:

- `MigrationScope`
- `MigrationStrategy`
- `MigrationStatus`
- migration decisions and waves
- Azure targets and IP allocation lifecycle
- business comments, readiness checks and runbooks
- application/server associations

`Migration Intent` from Azure Migrate is evidence in `ServerDiscoverySnapshot`; it is not interpreted as an approved migration strategy.

Blank/missing source fields do not clear current technical values. Unknown environment values are preserved with a warning. Field-level proposed changes are reviewed before commit and field-level audit events record old/new values.

## Consequences

Discovery remains authoritative for observed technical facts without becoming authoritative for governance decisions. A snapshot retains the richer report even where the current canonical Server model has only a selected subset. New discovery-managed fields require an explicit amendment to this ADR and corresponding reconciliation/audit tests.
