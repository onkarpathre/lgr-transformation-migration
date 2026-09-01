# ADR-004: Discovery staging and explicit reconciliation

Status: Accepted for Phase 2

## Decision

Store uploaded file metadata in `ImportBatch`, source rows as JSON in `DiscoveryImportRow`, and file bytes behind `IImportFileStorage`. Use source-specific mappers and a two-stage preview/commit workflow. Preview calculates tenant-safe hostname matches, classifications, validation messages and field changes without touching canonical inventory. Commit conditionally claims the batch and applies all canonical changes, snapshots and audit events in one database transaction.

Use SHA-256 for duplicate detection but warn rather than block. Preserve rejected, warning and unchanged rows in import history. Preserve discovered server history as append-only `ServerDiscoverySnapshot` records.

## Consequences

Users can inspect exactly what will change and no report can silently overwrite inventory. JSON staging accommodates Azure report evolution and retains unsupported All Inventory fields without a wide sparse table. Transactional commit and immutable status prevent partial or repeat imports. Querying JSON for analytics is deliberately not optimized; later canonical workload models will be populated through new reviewed reconciliation policies.
