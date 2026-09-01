# Discovery Import Architecture

## Purpose

Phase 2 adds a tenant-aware discovery ingestion module to the existing modular monolith. Azure Migrate reports are retained as source evidence, staged as JSON, reconciled against canonical servers, and committed only after a user reviews the preview. The design does not create canonical database, web application, file share, or software records.

## Workflow

```text
CSV upload
  -> extension, size, UTF-8, hash and header validation
  -> generated local filename
  -> ImportBatch (Uploaded)
  -> source mapper + typed validation
  -> DiscoveryImportRow JSON staging
  -> customer + normalized hostname reconciliation
  -> Create / Update / Unchanged / Warning / Reject preview
  -> explicit commit confirmation
  -> one database transaction
       -> create/update discovery-managed Server fields
       -> preserve business-managed fields
       -> ServerDiscoverySnapshot history
       -> field-level audit events
       -> completed ImportBatch
```

Preview writes only the batch and staging tables. It never changes `Server`, `ServerDiscoverySnapshot`, or discovery commit audit rows. Commit conditionally claims a `PreviewReady` batch as `Importing`, preventing a second commit. Canonical changes, snapshots, audits and final batch status share one relational transaction. A failure rolls back those changes and marks the batch `Failed` outside the rolled-back transaction.

## Source and file abstractions

`IImportFileStorage` separates database metadata from file bytes. `LocalImportFileStorage` writes generated `.csv` names beneath configured `DiscoveryImport:LocalStoragePath` (`runtime/imports` by default), which is ignored by Git. It rejects path components in stored names and never uses the supplied filename as a path. A future `AzureBlobImportFileStorage` can implement the same save/open/delete contract using a private container, managed identity, encryption, malware scanning and lifecycle retention without changing import services.

`IDiscoveryFileReader` isolates CSV parsing from import orchestration. Phase 2 supports UTF-8 CSV with comma separation, quoted fields, embedded commas, escaped quotes, empty values, CRLF/LF and quoted newlines. XLSX is intentionally deferred because no spreadsheet package was already present and adding a package could not be validated in the restricted development environment. A future XLSX reader can implement this interface without changing reconciliation.

`AzureMigrateServerReportMapper` and `AzureMigrateAllInventoryMapper` contain source-specific header validation and typed field mapping. Column names are compared after trimming and removing non-alphanumeric characters, so case, whitespace, `/`, parentheses and `#` variations do not affect matching. Column order is irrelevant. Server Report selection conflicts with All Inventory marker columns rather than silently guessing.

## Staging and reconciliation

`ImportBatch` stores file identity, lifecycle, user, tenant/project ownership and summary counts. `DiscoveryImportRow` stores the original row as JSON plus normalized hostname, classification, validation messages, match and proposed field changes. Source columns are not expanded into a wide staging table; this preserves currently unsupported All Inventory data for later phases.

Matching uses the current tenant query filter and normalized `CustomerId + Hostname`. The import service never performs a hostname-only cross-customer query. A same-customer match in another project is rejected as unsafe. Duplicate source IDs and duplicate hostnames inside one import are rejected.

Errors yield `Reject`. Unknown but usable environment values and clearly non-server All Inventory rows yield `Warning`; warnings do not automatically reject a row. All Inventory rows participate in server reconciliation only when Workload, Category or Type clearly identifies a server/machine.

## Canonical versus discovered data

Canonical `Server` remains the current inventory view. Selected technical fields are discovery managed; manually governed migration fields remain business managed. Every safely committed server row, including unchanged rows, creates a `ServerDiscoverySnapshot`, so repeated discoveries form an immutable technical history. Original source values also remain in staging JSON.

The current discovery freshness status is calculated from `Server.LastDiscoveredAt` using `DiscoveryImport:FreshnessThresholdDays`, default 30 days:

- `Current`: last discovered within the threshold;
- `Stale`: older than the threshold;
- `Unknown`: no committed discovery date.

## Security and tenancy

- Supported source type and `.csv` extension are allow-listed.
- Maximum size is configurable and enforced before and while copying.
- Empty and invalid UTF-8 files, malformed CSV, missing expected headers and conflicting source selection are rejected.
- SHA-256 detects repeat uploads; duplicates warn but are not blocked.
- Uploaded content is parsed only as data and never executed.
- File binaries never enter SQL Server/Azure SQL.
- Generated server-side names prevent path traversal.
- EF global filters enforce `CustomerId`; services also enforce current `ProjectId` for batches, rows, commit and history.

## Audit and operational behavior

Commits create `ServerCreatedFromDiscovery`, field-level `ServerUpdatedFromDiscovery`, and one `DiscoveryImportCommitted` audit event. Unchanged rows do not create per-field audit noise. Committed history cannot be edited or recommitted. Failed and cancelled batches cannot change inventory.

## Current limitations

Phase 2 is CSV-only and uses local filesystem storage. It does not build canonical database, web app, file share or software inventory from All Inventory, nor does it provide Blob Storage, Entra production identity, malware scanning, background processing or automated dependency modelling.
