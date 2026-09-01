# Discovery Import Functional Scope

## Included journey

The Phase 2 journey is: upload Azure Migrate report -> validate source and file -> stage rows -> preview classifications and field differences -> explicitly commit -> view inventory changes, snapshots, import history and audit evidence.

## Supported sources

- **Azure Migrate Server Report**: full server parsing, validation, preview and canonical reconciliation.
- **Azure Migrate All Inventory Report**: upload, validation, JSON staging, preview and source tracking. Rows clearly marked as server/machine can reconcile to Server Inventory. Other workload rows remain staged warnings for later phases.

CSV is supported. XLSX is a reader-abstraction follow-up. No paid dependency is used.

## Preview behavior

Upload records file name, generated storage name, SHA-256, size, selected source, customer/project, user and time. Header validation must agree with the selected source. Preview parses each row and displays Total, Create, Update, Unchanged, Warning and Reject counts.

An Update row exposes field-level old/new technical values. A Warning row remains potentially importable where safe. A Reject row never changes inventory. Preview itself cannot create or update a Server.

## Commit behavior

Commit requires explicit confirmation and a `PreviewReady` batch with at least one valid row. It creates missing servers, updates only approved technical fields on matched servers, records a discovery snapshot for every safe server row, updates last-import metadata and writes audit events. The operation is transactional and can occur only once.

If a matched server changes after preview, commit fails and asks the user to preview again. This prevents stale proposed changes from silently overwriting newer data. Failed and cancelled imports cannot commit.

## Pages

- `/discovery/imports`: persistent project import history.
- `/discovery/imports/new`: current customer/project, source and CSV selection.
- `/discovery/imports/{id}`: summary, classification filter, staged rows, validation, raw source values and field differences.
- `/inventory/servers`: discovery source, last discovered/imported, support status, freshness and discovery history.
- dashboard: concise latest-discovery panel.

## API

The module exposes list/detail, multipart upload, preview, paginated/filterable rows, row detail, commit and cancel beneath `/api/discovery/imports`, plus `/api/servers/{id}/discovery-history`. Existing development tenant/project/user headers, DTO boundaries, async EF usage and Problem Details behavior remain in force.

## Business rules

- Server matching is `CustomerId + normalized hostname`; hostname is never a primary key.
- Known environment values normalize to Prod, Dev or UAT. Unknown values are preserved with a warning.
- Invalid mandatory hostname, numeric/date values or IP syntax reject a server row.
- Duplicate hash warns and permits intentional rerun.
- Discovery must never overwrite migration scope, strategy, status, decisions, targets, readiness, comments, waves or runbooks.
- A second import of the same unchanged discovery data classifies safe server rows as Unchanged; inherent source warnings and rejects remain visible.

## Excluded

Canonical SQL instance/database, SSIS, SSRS, linked server, web app, file share and software imports; automatic dependencies; Blob integration; production Entra; migration execution; Azure VM deployment; ServiceNow/CMDB; AI; billing; Power BI; microservices and Kubernetes are excluded.
