# PH3-SQL-001 Remaining Phase - Consolidated Architecture Package

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-01", "C-02", "C-03", "C-04", "C-06"]
  functional_requirements: ["F-01", "F-02", "F-03", "F-04", "F-05", "F-07", "F-15"]
  non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-04", "NF-05", "NF-06", "NF-08", "NF-09", "NF-10", "NF-11", "NF-12", "NF-13"]
  risks: ["R-01", "R-02", "R-03", "R-06", "R-09", "R-11"]
  assumptions: ["A-01", "A-02", "A-03", "A-05", "A-06", "A-08", "A-11", "A-13", "A-15", "A-16", "A-18"]
  dependencies: ["D-01", "D-03", "D-04", "D-05", "D-07", "D-08", "D-10", "D-11", "D-13"]
  issues: ["I-01", "I-02", "I-03", "I-04", "I-06", "I-08"]
  open_questions: ["Q-01", "Q-02", "Q-06", "Q-09"]
  approvals:
    - "Existing ADR-006, ADR-007 and ADR-008 approvals apply only within their recorded restricted local/non-production boundaries."
    - "PH3-SQL-001 Slice 1 was quality-recommended at 5d5f7d9 for restricted local/non-production use; that recommendation does not approve this remaining-phase package."
    - "Product Owner decision plus Architect/TDA, Information Security and DBA/Discovery SME formal approvals are recorded against exact package commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a."
```

## Package control and outcome

- **Architecture package:** `PH3-SQL-ARCH-REMAINING-001`
- **Incoming work item:** `PH3-SQL-001-REMAINING`
- **Architecture baseline:** approved package candidate `feature/ph3-remaining-plan` at `7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a`; its incoming Product Plan baseline is `7e74f86a77df3d7e806694208784ab6238613715`.
- **Implementation baseline:** Slice 1 merged to `main` at `284c5b2`; its exact Quality Record remains authoritative for what is already accepted.
- **Product phase:** Product Specification Phase 1 MVP. “Phase 3” in this package means repository Roadmap Phase 3, not Product Specification Phase 3 AI scope.
- **Package scope:** all remaining ordered Slices 2-4 as one approval unit: SQL CSV discovery/reconciliation/history, human SQL assessment/planning records, and browser journeys/phase evidence closure.
- **Architecture state:** `READY_FOR_DEVELOPMENT` for sequential Slices 2-4 at approved architecture commit `7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a`.
- **Reason:** the Product Owner decision and the three required formal Architect/TDA, DBA/Discovery SME and Information Security approvals are all evidenced against the unchanged exact package commit. This state authorizes only the documented restricted local/non-production development scope.

This document is the implementation contract for the remaining phase after approval. It refines and supersedes the corresponding proposed future sections of `Phase3_SQL_Discovery_Assessment_Architecture.md`; it does not alter the accepted Slice 1 inventory implementation or replace ADR-006, ADR-007 or ADR-008.

## Scope and immutable boundaries

The remaining phase records, plans and provides evidence. It does not execute or orchestrate database migration, DMS, scripts, remediation, backup/restore, Azure provisioning or configuration. It adds no AI, recommendation engine, direct discovery API, SSIS, SSRS, linked-server or multi-cloud capability. Only file-based UTF-8 CSV and synthetic or properly anonymised development/test data are permitted.

The following remain outside this package: production identity configuration, external customer access, production tenancy selection, production storage/scanning/retention, production deployment, customer data, PRB funding, service transition and release authority. The package is separable from Q-02, Q-06 and Q-09 because it makes no delivery commitment and authorises only restricted local/non-production design using internal/synthetic identities and data. Wider Q-01 remains open; ADR-006 supplies only the already approved restricted stack baseline.

## Material architecture decisions

Only these remaining-phase decisions require package-level approval:

1. Adopt the exact `SqlInstanceCsv/v1` and `SqlDatabaseCsv/v1` contracts, deterministic preview/commit semantics, typed append-only discovery snapshots and fixture manifest in this document.
2. Adopt one active human assessment per SQL Instance or SQL Database, the controlled status/readiness/target/approach values, field ownership and split evidence/planning commands in this document.
3. Extend ADR-008 with explicit discovery and assessment permissions. Identity proof, server-derived customer/project context, deny-by-default handling, LocalTest restrictions, stable audit actor and non-enumerating errors remain unchanged.
4. Deliver the remaining schema as two sequential expand-only EF Core migrations, with separate default-off exposure flags and data-preserving operational rollback.
5. Use Vitest/React Testing Library for component contracts and Playwright plus automated/manual accessibility evidence for the critical browser journeys. SQL Server remains mandatory for provider, migration, constraint, transaction and concurrency evidence.

These decisions do not warrant a new ADR: they select feature contracts within the already accepted modular-monolith, technology, tenancy and identity decisions. Any change to topology, identity provider, tenant derivation, external access, background workload authority, production storage or production deployment requires a separate ADR/work item.

## Consolidated component and data flow

```text
Next.js browser module
  inventory -> import/preview -> history -> assessment/planning
        |
        | bearer/LocalTest identity + untrusted project selector
        | JSON DTOs or multipart CSV
        v
ASP.NET Core v1 controllers + ADR-008 policies
        |
        +-- SqlDiscoveryImportService
        |     +-- versioned mapper/validator
        |     +-- deterministic reconciler/field policy
        |     +-- transaction/idempotency coordinator
        |
        +-- SqlAssessmentService
        |     +-- evidence command
        |     +-- planning command
        |
        +-- SqlInventoryService (accepted Slice 1, reused)
        |
        v
EF Core / SQL Server-compatible relational schema
  existing ImportBatch + DiscoveryImportRow
  existing SqlInstance + SqlDatabase + AuditEvent
  new typed snapshots + SqlAssessment
```

Browser, route/query identifiers, headers, project selection, CSV metadata/content and all displayed source values are untrusted. Authentication establishes a principal; an active server-side membership resolves the project and derives the customer; a named permission authorises the operation; the service then scopes every query and relationship to that immutable context. The selected project never supplies `CustomerId` and possession of a GUID never grants access.

## Phase sequence and feature exposure

The slices remain sequential delivery checkpoints inside this one architecture package:

1. **Slice 2:** import contracts, staging extensions, reconciliation, typed snapshots and history APIs.
2. **Slice 3:** assessment domain, constraints, evidence/planning APIs and audit.
3. **Slice 4:** browser journeys and same-commit whole-phase evidence.

Use default-off `SqlDiscoveryImport`, `SqlAssessment` and `SqlBrowserJourneys` exposure flags beneath the existing default-off `SqlDiscoveryAssessment` parent. A child cannot be enabled when its prerequisite is disabled. Flags are deployment/rollback controls, never authentication or authorisation controls. Slice 4 adds no database schema unless a separately reviewed architecture amendment proves one necessary.

## ADR-008 authorisation extension

ADR-008 remains normative. Add named permissions; do not reuse the fallback “active project member” policy for these paths.

| Capability | Permission | DatabaseSme | DiscoveryAnalyst | MigrationArchitect | ProjectManager | ReviewerAuditor |
|---|---|---:|---:|---:|---:|---:|
| Import batch/list/detail/rows and SQL discovery history | `sql.discovery.read` | Allow | Allow | Allow | Allow | Allow |
| Upload and preview | `sql.discovery.prepare` | Deny | Allow | Deny | Deny | Deny |
| Commit | `sql.discovery.commit` | Deny | Allow | Deny | Deny | Deny |
| Cancel an uncommitted batch | `sql.discovery.cancel` | Deny | Allow | Deny | Deny | Deny |
| Assessment list/detail | `sql.assessment.read` | Allow | Allow | Allow | Allow | Allow |
| Create/archive assessment and edit evidence/status fields | `sql.assessment.manage` | Allow | Deny | Deny | Deny | Deny |
| Edit target platform/version and migration approach | `sql.assessment.plan` | Allow | Deny | Allow | Deny | Deny |

Permissions are additive across active project roles. Disabled/suspended principals or memberships override allows. Unknown roles, customer/platform roles and every unlisted action deny; there is no wildcard or administrator bypass. Interactive paths accept human delegated principals only. No workload permission or background importer is introduced.

History visibility follows the relevant `sql.discovery.read` permission and current project context. Raw staged row detail is additionally limited to `DatabaseSme` and `DiscoveryAnalyst`; other read roles receive batch summaries and typed canonical history, not raw source values. General inventory permissions from Slice 1 are unchanged.

## CSV file envelope and parsing contract

- Accepted content is `.csv` only, at most 25 MiB, 50,000 data rows and 64 columns, with exactly one header row.
- Encoding is strict UTF-8 with or without BOM. CRLF/LF, RFC-style quoting, embedded commas, escaped quotes and quoted line breaks are supported.
- Reject before staging on invalid UTF-8, NUL, empty file, unclosed quote, duplicate normalised header, more values than headers, or file/row/column limit breach.
- MIME type is advisory; extension, strict decoding, parser rules and explicit `sourceType` are authoritative. Macros, spreadsheets, archives and executable content are unsupported.
- Store by generated identifier under authorised customer/project metadata; original filename is display-only. Never use it as a path.
- Header matching reuses `DiscoveryColumnName.Normalize`: trim, remove non-alphanumerics and compare case-insensitively. Column order is irrelevant. Unknown columns are retained only in staged source evidence and create one batch warning.
- Raw cells remain source evidence, are output encoded, never evaluated or inserted into HTML/logs/commands, and are never exported verbatim. Export code must neutralise formula prefixes `=`, `+`, `-`, `@`, tab and carriage return after leading whitespace.

### `SqlInstanceCsv/v1`

All eight headers are required. Optional means the row cell may be blank.

| Header | Value | Exact rule |
|---|---:|---|
| `Server` | Required | Trim; resolve exact normalised hostname only inside the current customer/project. Unmatched or ambiguous is Reject. |
| `Instance Name` | Required | Trim, Unicode Form C, max 128; invariant-uppercase key. `MSSQLSERVER`, `DEFAULT` and `(DEFAULT)` map to `MSSQLSERVER`. A combined `Server\\Instance` value is Reject. |
| `SQL Version` | Required | Trim; 1-100 characters. |
| `Edition` | Required | Trim; 1-100 characters. |
| `Port` | Optional | Blank means not supplied; otherwise invariant whole number 1-65535. |
| `Service Status` | Required | Canonical `Running`, `Stopped`, `Paused`, `Disabled`, `Unknown`; `Started`/`Online` -> `Running`, `Offline` -> `Stopped`. Other safe printable value -> `Unknown` plus warning. |
| `Discovery Source` | Required | Trim; 1-100 characters; provenance text only and never executed. |
| `Last Discovered At` | Optional | ISO-8601 with explicit offset, converted to UTC; blank means not supplied. |

Match key: `(CustomerId, ProjectId, ServerId, NormalizedInstanceName)`. No partial-name, IP-address or cross-project fallback is permitted.

### `SqlDatabaseCsv/v1`

All eight headers are required; only `Collation` may be blank.

| Header | Value | Exact rule |
|---|---:|---|
| `Server` | Required | Resolve exact normalised hostname only inside current customer/project. |
| `Instance Name` | Required | Resolve using the instance rule and the resolved Server; unmatched/ambiguous parent is Reject. |
| `Database Name` | Required | Trim, Unicode Form C, max 128; invariant-uppercase key. |
| `Size MB` | Required | Invariant non-negative whole number within `Int64`. |
| `Compatibility Level` | Required | Invariant whole number 80-200. |
| `Recovery Model` | Required | Canonical `Simple`, `Full`, `BulkLogged`; `Bulk Logged` and `Bulk-Logged` map to `BulkLogged`. |
| `Collation` | Optional | Trim; max 128; blank means not supplied. |
| `Status` | Required | Canonical `Online`, `Offline`, `Restoring`, `Recovering`, `RecoveryPending`, `Suspect`, `Emergency`, `Standby`, `Unknown`; case/space/underscore/hyphen variants normalise. Other safe printable value -> `Unknown` plus warning. |

Match key: `(CustomerId, ProjectId, SqlInstanceId, NormalizedDatabaseName)`. A database contract never creates a missing instance implicitly.

## Staging, reconciliation and commit contract

Reuse the Phase 2 batch, parser and staging lifecycle. Extend `DiscoveryImportRow` with nullable `NormalizedInstanceName`, `NormalizedDatabaseName`, `MatchedSqlInstanceId`, `MatchedSqlDatabaseId` and a bounded `ReconciliationFingerprint`. Existing `MatchedEntityId` remains the Server relationship; it does not become polymorphic.

### Batch state and concurrency

The permitted state graph is:

```text
Uploaded -> PreviewReady -> Committing -> Committed
    |            |              |
    +----------> Cancelled      +-> PreviewReady (transaction failed safely)
    +----------> Rejected
```

`ImportBatch.RowVersion` supplies an opaque ETag. Preview requires the current batch ETag and makes no canonical change. Commit requires both the preview ETag in `If-Match` and a caller-generated `Idempotency-Key`; the server stores only its SHA-256 hash and a bounded result summary. Missing/stale preconditions are 428/412. The same key on the same committed batch returns the stored result; a different key on a committed batch or a key reused for an incompatible request returns 409 without mutation.

Preview replaces only that uncommitted batch’s derived staging/reconciliation evidence, then updates its ETag. It resolves all parents/current matches in bounded project-scoped queries and stores a fingerprint of the material parent IDs, current canonical version and compared discovery-managed values. Commit atomically claims `PreviewReady`, re-resolves parents, revalidates keys and fingerprints, and refuses the whole batch as stale if any safe row changed. Database uniqueness constraints remain the final concurrent-write defence.

### Row outcomes

Each row has one `classification`: `Create`, `Update`, `Unchanged`, `Warning` or `Reject`. A Warning also carries `proposedAction` of `Create`, `Update` or `Unchanged`; warning rows may commit only when identity, parent and values remain safe. Reject has no proposed action and never mutates canonical data. Every occurrence of an in-file duplicate business key is Reject so row order cannot select a winner.

Warnings are limited to unknown extra columns, repeat-file hash, safe unrecognised status normalised to `Unknown`, or an explicitly documented safe alias. Rejects include missing headers/values, duplicate headers/keys, source-type mismatch, unsafe/control/over-length content, invalid ranges/timestamps, malformed CSV/UTF-8 and unmatched, ambiguous or out-of-project parents.

Create and Update copy only allowed discovery-managed fields. Blank optional source cells mean “not supplied” and never clear a canonical value. Unchanged means all supplied values are equivalent after contract normalisation. Absence from a file never archives, deletes or restores inventory. Matching excludes archived rows; a key found only in archived history previews as Create with a new GUID.

Commit is one SQL transaction covering the batch claim/result, every safe canonical insert/update, provenance link, typed snapshot and audit event. One conflict fails all canonical/snapshot/audit changes. The batch retains a safe failure outcome and can be re-previewed; no partial canonical application is permitted.

### Field ownership

| Owner | Fields | Import rule |
|---|---|---|
| Server context | Customer/project, actor, correlation | Never read from CSV or client DTO. |
| System | IDs, normalised keys, audit/lifecycle values, row versions, batch/snapshot links | Computed in trusted services. |
| Instance discovery | Server, name, SQL version, edition, port, service status, discovery source, last discovered time | May create/update after preview. |
| Database discovery | Instance, name, size, compatibility, recovery model, collation, status | May create/update after preview. |
| Human protected | `ServiceAccountName`; all assessment/readiness/target/approach/findings/blockers/notes/assessed fields and governance state | Never mapped, cleared or overwritten by either v1 CSV. |

`ServiceAccountName` remains excluded. Therefore this package does not invoke the plan’s conditional Information Security review for a service-account CSV amendment. Credential-like data is rejected if encountered and is never logged.

## Typed discovery history

Add separate append-only tables; do not create a polymorphic snapshot reference.

`SqlInstanceDiscoverySnapshot` contains `Id`, `CustomerId`, `ProjectId`, `SqlInstanceId`, `ImportBatchId`, `ServerId`, `InstanceName`, `SqlVersion`, `Edition`, `Port`, `ServiceStatus`, `DiscoverySource`, `LastDiscoveredAt`, `ImportedAt`.

`SqlDatabaseDiscoverySnapshot` contains `Id`, `CustomerId`, `ProjectId`, `SqlDatabaseId`, `ImportBatchId`, `SqlInstanceId`, `Name`, `SizeMb`, `CompatibilityLevel`, `RecoveryModel`, `Collation`, `Status`, `ImportedAt`.

Every successfully committed safe row creates exactly one typed snapshot, including Warning and Unchanged rows. Reject rows do not. Snapshots use immutable GUIDs, tenant-leading composite FKs to the canonical record and batch, `Restrict` deletes, no update/delete application API, and indexes `(CustomerId, ProjectId, canonicalId, ImportedAt DESC, Id)`. They contain normalised/validated typed source facts, never raw JSON, assessment fields, service-account data or credentials.

History API results are paged (default 50, maximum 200), newest first with immutable ID as tie-breaker, and include batch ID/source type/imported UTC time plus typed facts. Raw staged evidence remains batch-authorised and subject to future retention; it is not canonical history.

## Human assessment domain contract

`SqlAssessment` is a human-authored current record, not discovered data or an automated recommendation. It contains immutable `Id`, `CustomerId`, `ProjectId`, exactly one of `SqlInstanceId`/`SqlDatabaseId`, the fields below, creation/update/archive actor and UTC timestamps, and SQL Server `rowversion`.

| Field | Type / maximum | Rule |
|---|---|---|
| `AssessmentStatus` | controlled string(50) | `NotStarted`, `InProgress`, `Complete`, `Blocked`. |
| `ReadinessStatus` | controlled string(50) | `NotAssessed`, `NotReady`, `AtRisk`, `ReadyWithConditions`, `Ready`, `Blocked`. |
| `TargetPlatform` | controlled string(80), nullable | `AzureSqlDatabase`, `AzureSqlManagedInstance`, `SqlServerOnAzureVm`, `Retain`, `Retire`, `Investigate`. |
| `TargetSqlVersion` | string(100), nullable | Human planning text; allowed only for `SqlServerOnAzureVm`; no command or SKU semantics. |
| `MigrationApproach` | controlled string(50), nullable | `Offline`, `Online`, `ToBeDetermined`, `NotApplicable`. Planning label only. |
| `Blockers` | string(4000) | Required property; empty permitted. |
| `Findings` | string(8000) | Required property; empty permitted. |
| `Notes` | string(4000) | Required property; empty permitted. |
| `AssessedAt` | UTC instant, nullable | Human-recorded evidence time; required for `Complete`, not later than server time plus five minutes. System audit time remains distinct. |

Exactly one target FK is populated, enforced by `CK_SqlAssessments_ExactlyOneTarget` and tenant-leading composite FKs. Separate filtered unique indexes permit only one active assessment per instance and one per database. Ordinary queries exclude archived rows. Archive is logical and requires `If-Match`; there is no restore/hard-delete API.

Workflow invariants:

- `NotStarted` requires `NotAssessed`, null target/version/approach and null `AssessedAt`.
- `InProgress` may carry provisional planning values; `Ready` is not valid while in progress.
- `Blocked` assessment status requires `Blocked` readiness and non-blank Blockers.
- `Complete` requires `AssessedAt`, a target platform and a readiness value other than `NotAssessed`.
- An Azure target requires approach `Offline`, `Online` or `ToBeDetermined`. Only `SqlServerOnAzureVm` may carry `TargetSqlVersion`.
- `Retain` and `Retire` require `NotApplicable`; `Investigate` requires `ToBeDetermined`; all three require null `TargetSqlVersion`.
- `ReadyWithConditions` requires non-blank Blockers or Notes. `Ready` requires blank Blockers.

The database enforces XOR, allowed controlled values and one-active-record constraints. Cross-field workflow is enforced centrally in the domain service and contract-tested. Values are display-mapped in DTOs; storage values are stable and case-sensitive at the domain boundary. None maps to an executor, Azure SDK, DMS command, script or provisioning instruction.

Evidence/status and planning updates are distinct commands so permissions remain least-privilege. `DatabaseSme` may create, archive and change evidence/status plus planning. `MigrationArchitect` may change only `TargetPlatform`, `TargetSqlVersion` and `MigrationApproach` on an existing assessment. Each command requires the current ETag; field ownership is enforced server-side, not by hiding browser controls.

## API contracts

Canonical internal routes use `/api/v1`; any retained unversioned alias invokes the identical controller/service/policy and is covered by equivalence tests.

### Discovery and history

- `GET /api/v1/discovery/imports` and `GET /api/v1/discovery/imports/{id}`.
- `POST /api/v1/discovery/imports/upload` (`multipart/form-data`: `sourceType`, `file`).
- `POST /api/v1/discovery/imports/{id}/preview` with `If-Match`.
- `GET /api/v1/discovery/imports/{id}/rows?page&pageSize&classification` and row detail.
- `POST /api/v1/discovery/imports/{id}/commit` with `If-Match` and `Idempotency-Key`.
- `POST /api/v1/discovery/imports/{id}/cancel` with `If-Match`.
- `GET /api/v1/sql-instances/{id}/discovery-history?page&pageSize`.
- `GET /api/v1/sql-databases/{id}/discovery-history?page&pageSize`.

Batch/row DTOs expose safe counts, states, warnings/errors, proposed field names and encoded values according to raw-row permission. They never expose storage paths, other-scope IDs, credentials, exception/provider text or raw EF entities.

### Assessments

- `GET /api/v1/sql-assessments?page&pageSize&targetType&targetId&assessmentStatus&readinessStatus`.
- `GET /api/v1/sql-assessments/{id}`.
- `POST /api/v1/sql-assessments` creates one target-bound assessment.
- `PUT /api/v1/sql-assessments/{id}/evidence` updates status/readiness/blockers/findings/notes/assessed time.
- `PUT /api/v1/sql-assessments/{id}/planning` updates target platform/version/approach.
- `DELETE /api/v1/sql-assessments/{id}` logically archives.

POST returns 201 with `Location` and ETag. PUT returns the updated DTO and ETag. DELETE returns 204. PUT/DELETE require `If-Match`: 428 missing and 412 stale. Lists use default 50/max 200, allow-listed sort/filter values, no-tracking projections and stable ID tie-breakers.

All errors use approved Problem Details with safe `errorCode` and `correlationId`. Preserve ADR-008 400/401/403/404/503 behaviour. Use 409 for state/uniqueness/dependent/idempotency conflicts, 413 for size, 415 for media type, 422 for a recognised but unsupported source contract, and 500 without internal detail. Missing and inaccessible resources remain indistinguishable.

OpenAPI is generated and contract-tested. These APIs remain internal; external publication is not approved.

## Browser journeys

Add navigable pages using the existing Next.js App Router and design conventions:

- `/inventory/sql-instances` and `/inventory/sql-instances/[id]`, with linked paged databases and discovery history.
- `/inventory/sql-databases` and `/inventory/sql-databases/[id]`, with parent instance and discovery history.
- Existing `/discovery/imports`, `/discovery/imports/new` and `/discovery/imports/[id]` gain the two explicit SQL source types, preview/reconciliation, paged row evidence, ETag-aware commit/cancel and terminal result states.
- `/assessment/sql` provides filterable assessment status/readiness; `/assessment/sql/[id]` provides evidence and planning sections governed by server permissions.

The critical journey is project selection -> SQL inventory -> upload -> preview outcomes/warnings/rejects -> explicit commit -> typed history -> create/revise assessment -> human planning value -> audit-visible completion. There is no “migrate”, “execute”, “provision”, “remediate” or AI recommendation action.

Every page has a discoverable navigation label, breadcrumb/title, loading skeleton/status, empty state with permitted next action, inline validation summary linked to fields, safe 401/403/404/409/412/413/422/503 states, retry that does not repeat a mutation, and confirmation before commit/archive. A stale ETag causes refresh/review, never silent overwrite. Commit controls display counts and make clear that rejected rows will not apply.

Accessibility contract: semantic landmarks/headings/table captions, associated labels/instructions, keyboard-operable controls and row detail, visible focus, status/error announcements using appropriate live regions, no colour-only classification, focus moved to validation/confirmation outcome, and WCAG 2.2 AA contrast/reflow expectations. Supported-browser evidence follows the approved Next.js/browser baseline.

Customer-confidential values are not placed in URLs, browser telemetry or persistent browser storage. API data is fetched for the active authorised project with `no-store` semantics; cache/query keys include project and are cleared on project change/logout. Rendering escapes source/narrative text. The browser never supplies roles, permissions, customer ID, actors, audit time or canonical ownership.

## Security, privacy, audit and observability

- Reuse the accepted ADR-007 shared-schema local/non-production controls: customer global filters, explicit project predicates, tenant-leading constraints, same-owner relationship checks and synthetic-data restriction.
- Reuse ADR-008 authentication, active membership, server-derived customer, LocalTest allow-list, production-like startup guard, human/workload distinction, audit actor and denial/error rules. A feature flag or browser-hidden control is never authorisation.
- CSV and narrative values are customer-confidential. General logs contain only correlation ID, opaque IDs, counts, classification/status, duration and safe outcome. They exclude raw rows, filenames, server/instance/database names, findings, blockers, notes, old/new narrative and authentication material.
- Audit events are append-only and include customer, project, stable actor/principal type, UTC event time, correlation ID, entity/batch ID and action. Events include upload, preview, cancel, commit summary, SQL discovery field changes, assessment create/evidence change/planning change/archive and denied high-risk actions. Unchanged import rows create snapshots but no field-change noise.
- Assessment old/new values may exist only in the tenant-authorised audit store; general telemetry records changed field names, not narrative. `ServiceAccountName` remains redacted.
- Metrics cover bounded API latency/errors, upload/preview/commit duration and counts, stale/idempotency/concurrency outcomes, assessment workflow outcomes and browser errors without customer-data labels. Security signals cover repeated denials, cross-scope relationship attempts, malicious/oversized files and credential-like values.
- No new cache is required. Any later cache must include customer/project/membership version and evict on membership, commit, archive and project change.

Production Blob quarantine/scanning, private networking, managed identity, Key Vault, retention, alert routing and DPO decisions are not claimed by this package.

## Data model, keys and delete behaviour

All new IDs are application-generated GUIDs; timestamps are `DateTimeOffset` stored as UTC; lengths are explicit. All relationships use existing alternate keys `(CustomerId, ProjectId, Id)` and composite FKs. No raw database entity crosses the API.

Slice 2 adds:

- `ImportBatch.RowVersion`, `CommitIdempotencyKeyHash` (nullable fixed SHA-256 representation) and bounded `CommitResultJson` without raw values.
- The four nullable SQL staging/match/fingerprint columns described above and owner-leading matching indexes.
- Two typed snapshot tables and history indexes.

Slice 3 adds `SqlAssessment` plus:

- `CK_SqlAssessments_ExactlyOneTarget`.
- allowed-value checks for assessment status, readiness, target and approach.
- tenant-leading composite FKs to Project and optional target, all `Restrict`.
- filtered unique active-instance and active-database indexes.
- `(CustomerId, ProjectId, IsDeleted, AssessmentStatus, ReadinessStatus, Id)` for bounded filtering.
- SQL Server `rowversion`, logical archive/audit columns and no physical-delete API.

Snapshot/batch/canonical/audit evidence uses `Restrict`; no committed evidence cascades. Existing uncommitted staging lifecycle may retain its current batch-owned cascade. An instance/database with an active assessment cannot be archived. An assessment archive never archives its target. Physical retention/offboarding deletion is a separate human-approved capability.

## Migrations, deployment compatibility and rollback

Create two reviewed additive migrations after the existing Slice 1 migrations; never edit, squash or re-baseline migration history:

1. `AddSqlDiscoveryImportHistory`: batch concurrency/idempotency fields, nullable staging columns, composite FKs/indexes, typed snapshot tables and indexes.
2. `AddSqlAssessments`: assessment table, checks, composite FKs, filtered unique/query indexes and rowversion.

Before generating either migration, run a read-only synthetic/dev ownership preflight. Any inconsistent existing owner columns return to Architecture; the migration must not guess or repair them. Each migration and its idempotent SQL script must be inspected for exact SQL Server types, filters, constraints and rollback operations.

Provider evidence must apply Up to both an empty isolated synthetic SQL Server database and a copy at the immediately preceding checked-in migration, confirm no pending model changes, inspect constraints/indexes, and rehearse Down/reapply only on a pre-validated disposable test database under named authority. Tests must prove `rowversion`, filtered uniqueness, composite FK isolation, transaction rollback, stale preview and concurrent commit. SQLite remains supplementary and cannot prove provider behaviour.

Expand-first deployment order in an authorised non-production environment is schema -> backward-compatible application with all child flags off -> smoke/isolation checks -> enable Slice 2 -> verify -> enable Slice 3 -> verify -> enable Slice 4. No application startup auto-applies migrations. No Bicep/Azure resource change is required.

Operational rollback is data-preserving: disable the affected child flag, roll back to a preceding compatible application, leave additive schema/audit/snapshot/assessment data intact, and use a reviewed forward fix. Do not run Down or delete batches/history in production. A failed commit transaction rolls back canonical/snapshot/audit changes and records only a safe failed batch outcome. Any production restore/data correction requires a separate named human plan and authority.

## Performance and support contract

- All lists/history/rows default to 50 and cap at 200; stable server-side sorting and allow-listed filters are mandatory.
- Resolve import parents/current matches in bounded set queries/dictionaries; no per-row lookup or lazy loading.
- Use async EF operations, cancellation tokens and no-tracking DTO projections for reads. Do not materialise entity graphs.
- The phase evidence estate contains at least 200 mixed assets in one synthetic project and a second customer/project for leakage tests. Record API, preview, commit and history timings and SQL Server execution plans for owner-leading list, match, uniqueness and history queries.
- The 25 MiB/50,000-row limit is a safety envelope, not a production performance promise. Production capacity/SLA remains subject to Q-02, Q-08 and approved non-production performance evidence.

## Synthetic fixture contract

The approved fixture set must contain no real names or personal/customer data and must retain these stable scenario IDs. Developers may split physical files, but may not change inputs/expected outcomes without phase-level contract reapproval.

| Fixture ID | Required content and expected outcome |
|---|---|
| `SQLI-V1-POS-01` | Instance Create, Update and Unchanged rows, blank optional cells, default alias and status aliases; exact counts asserted. |
| `SQLI-V1-WARN-01` | Unknown column, safe unknown status and repeat hash; Warning plus underlying proposed action asserted. |
| `SQLI-V1-NEG-01` | Missing/duplicate headers, duplicate keys, combined server-instance, unmatched/ambiguous/cross-project parent, invalid range/time, over-length/control/formula-like content; deterministic Reject/no mutation. |
| `SQLI-V1-BOUND-01` | Accepted maxima and one-over file/row/column/value/port limits; boundary decisions asserted. |
| `SQLD-V1-POS-01` | Database Create, Update and Unchanged, blank collation, recovery/status aliases and correct parent resolution. |
| `SQLD-V1-WARN-01` | Unknown column, safe unknown status and repeat hash; exact Warning/proposed action. |
| `SQLD-V1-NEG-01` | Duplicate key, missing instance, cross-project parent, invalid size/compatibility/recovery/status structure, malformed CSV/UTF-8 and unsafe content; Reject/no mutation. |
| `SQLD-V1-BOUND-01` | Accepted maxima and one-over limits, including `Int64`, compatibility and string lengths. |
| `SQL-RECON-01` | Preview no-mutation, protected fields byte-identical, stale fingerprint, repeated/same and different idempotency keys, concurrent commit, rollback and retry. |
| `SQL-HISTORY-01` | One snapshot per committed Create/Update/Unchanged/Warning safe row; none for Reject; ordering, immutability, scope and paging. |
| `SQL-ASSESS-01` | Each status/readiness/target/approach transition, instance/database XOR, planning/evidence field permissions, ETag, archive and audit. |
| `SQL-ASSESS-NEG-01` | Invalid controlled/cross-field values, two/no targets, duplicate active assessment, cross-project IDs, stale ETag and narrative boundaries. |
| `SQL-RBAC-01` | Every role/action cell, multi-role union, disabled membership, unknown/admin non-bypass, raw-row restriction and delegated/workload confusion. |
| `SQL-SCALE-200-01` | At least 200 mixed assets, multiple parents/statuses, import/history/assessment records, plus isolated second-project/customer attack data. |

Expected row counts, generated IDs, timestamps and ETags must be deterministic or controlled by test clocks/factories. Credential-like strings exist only as negative inputs and must be redacted from retained logs/results.

## Independent test contract

All evidence must bind to the same candidate commit and preserve failed/retry artefacts rather than rewriting history.

### Slice 2 exit evidence

- Parser/header/value/alias/normalisation and complete fixture matrix.
- Preview produces deterministic classifications and zero canonical change.
- Commit atomicity, protected byte-for-byte fields, snapshot-per-safe-row, append-only history, stale preview, cancel, repeat and concurrent idempotency.
- SQL Server composite FKs, indexes, rowversion, transactions, migration Up/authorised disposable Down/reapply and query plans.
- Full ADR-008 authentication/membership/permission/direct-object matrix on every batch/row/history route, including legacy alias equivalence and no raw-value logs.
- Existing Phase 1/2 and Slice 1 regression, build, dependency/vulnerability and product-boundary checks.

### Slice 3 exit evidence

- Instance/database XOR, one-active assessment, controlled values and every workflow invariant at API, domain and SQL constraint levels where applicable.
- Full role/permission and field-level command matrix, cross-customer/project targets, non-enumerating errors, ETag conflicts, archive restrictions and audit/redaction.
- Proof discovery preview/commit cannot change assessment or planning bytes.
- SQL Server migration/constraint/index/rowversion/rollback evidence and full prior regression.
- Repository and behavioural proof that planning values have no executor/provisioner/DMS/AI/remediation mapping.

### Slice 4/phase exit evidence

- Vitest/React Testing Library component coverage for loading, empty, validation, safe error, permission and stale-state behaviour.
- Playwright critical journeys for permitted roles and negative journeys for denied roles, project switch, direct URLs, stale commit/update and retry safety.
- Automated accessibility scan plus independent keyboard/focus/reflow/contrast review on critical pages in the approved supported browsers.
- API/UI/SQL Server/migrations/security/dependencies and all Phase 1/2/Slice 1-3 regression against one commit.
- `SQL-SCALE-200-01` timing, bounded paging, query-count/plan and leakage evidence.
- Requirements-to-test matrix for SQL-AC-003..015 as applicable, retained fixture/contract inventory and absence checks for every prohibited capability.

Any authentication bypass, cross-tenant/project disclosure, privilege escalation, partial commit, protected-field overwrite, history mutation/data loss, migration-execution/provisioning path, or critical/high dependency/security finding is release-blocking and cannot be accepted by an agent.

## Acceptance traceability

| Criterion | Consolidated architecture control | Primary slice |
|---|---|---|
| SQL-AC-003/004 | Versioned CSV envelope, exact schemas, deterministic staging/outcomes and no-mutation preview. | 2 |
| SQL-AC-005 | Protected ownership matrix, fingerprints, atomic/idempotent commit and no duplicate canonical records. | 2/3 |
| SQL-AC-006/007 | XOR assessment, controlled workflow, split human commands and no executor mapping. | 3 |
| SQL-AC-008 | ADR-007/008 reuse, exact permission extension, composite FKs and abuse tests on all routes/browser paths. | 2-4 |
| SQL-AC-009/015 | Stable actor/UTC/correlation audit and typed append-only snapshot per safe row. | 2/3 |
| SQL-AC-010 | Defined Next.js journeys, states, browser and accessibility contracts. | 4 |
| SQL-AC-011 | Bounded APIs/set-based matching and `SQL-SCALE-200-01` SQL/browser evidence. | 2-4 |
| SQL-AC-012/013 | Sequential migrations, same-commit regression, fixture manifest and retained evidence chain. | 2-4 |
| SQL-AC-014 | Explicit boundary plus repository and behavioural absence checks. | 2-4 |

## Package-level approvals and gates

Approvals are requested once for this complete package, not separately for each slice. Each record must name person/role, decision, date, exact package commit, scope, conditions and durable evidence.

Required before `READY_FOR_DEVELOPMENT`:

1. **Product Owner:** approve the consolidated scope, exact business role/action mapping, controlled assessment vocabulary/workflow and fixture expectations for restricted local/non-production delivery.
2. **Solution Architect/TDA:** approve this package as the remaining-phase implementation contract and confirm it stays within ADR-006/007/008 conditions.
3. **DBA / Discovery SME:** approve both CSV schemas/aliases/ranges/match rules, assessment vocabulary/workflow and the synthetic fixture manifest.
4. **Information Security:** approve only the material ADR-008 permission extension and raw-row visibility boundary. No service-account CSV field, new identity provider, production identity or external access is requested.

Required before implementation evidence is accepted, but not a reason to duplicate slice architecture approval:

5. **Named Test Authority:** approve Vitest/React Testing Library, Playwright/accessibility tools, isolated SQL Server/browser environment, synthetic fixture set, entry/exit criteria, evidence retention and authority for disposable Down/reapply. This can be recorded with the phase package before or during development, but must precede formal independent acceptance.

Existing Slice 1 approvals and Quality recommendation are reused only for the unchanged inventory, tenancy and ADR-008 foundation. They do not approve the new contracts above. Q-02/PRB blocks funded dates/release commitment, not restricted architecture/development after the four approvals. Q-06/DPO, wider Q-01, production tenancy, Identity Platform/deployed Entra, Q-09, Service Transition and human production release remain exact production/external blockers and are not being sought here.

No separate Information Security approval is needed for `ServiceAccountName` because it remains protected and excluded. Adding it to either CSV or changing the raw-row boundary reopens Information Security and package approval.

### Commit-bound approval reconciliation

`docs/approvals/PH3_SQL_PR6_Approvals.json` was parsed successfully and reconciled to Pull Request 6. All four records target `7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a`, which is the current branch `HEAD` and contains this complete architecture package plus the remaining-phase plan. The scope and restrictions in each review are consistent with this package's restricted local/non-production boundary.

| Gate role | Reviewer name (GitHub login) | Decision/date | Scope and conditions | Permalink | Status |
|---|---|---|---|---|---|
| Product Owner | `onkarpathre` | Exact-commit `COMMENTED`, 2026-09-15T12:08:46Z | Approves ordered Slices 2-4, priorities, acceptance criteria, controlled-value ownership and phase approach; restricted local/non-production only. | [Review 5209736362](https://github.com/onkarpathre/lgr-transformation-migration/pull/6#pullrequestreview-5209736362) | Satisfies the Product Owner decision: the body says “Approved as Product Owner,” and GitHub does not permit the PR author to formally approve their own PR. It is not PRB approval. |
| Architect / TDA | `opathre` | Formal exact-commit `APPROVED`, 2026-09-15T12:09:43Z | Approves the consolidated remaining-phase architecture for ordered Slices 2-4 within ADR-006/007/008 and the documented restricted local/non-production conditions. | [Review 5209749102](https://github.com/onkarpathre/lgr-transformation-migration/pull/6#pullrequestreview-5209749102) | Architecture gate satisfied for the unchanged approved package commit. |
| Information Security | `ashish50thbirthday-ship-it` | Formal exact-commit `APPROVED`, 2026-09-15T12:11:06Z | Approves the ADR-008 permission extension, deny-by-default isolation, raw-row boundary, audit, safe errors and synthetic-data constraints; excludes production identity, customer data, external access, deployment and release. | [Review 5209763769](https://github.com/onkarpathre/lgr-transformation-migration/pull/6#pullrequestreview-5209763769) | Gate 4 satisfied for the unchanged approved package commit. |
| DBA / Discovery SME | `nextgenexamprep-crypto` | Formal exact-commit `APPROVED`, 2026-09-15T12:13:03Z | Approves CSV v1 contracts/values/fixtures, staging/reconciliation, idempotency/history, SQL constraints, additive migrations and data-preserving rollback; excludes production schema/data and destructive operations. | [Review 5209781297](https://github.com/onkarpathre/lgr-transformation-migration/pull/6#pullrequestreview-5209781297) | Gate 3 satisfied for the unchanged approved package commit. |

The approved architecture commit is [`7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a`](https://github.com/onkarpathre/lgr-transformation-migration/commit/7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a). The four commit-bound decisions satisfy the approval gates for restricted local/non-production development of sequential Slices 2-4. Any material package change requires proportionate reapproval. Named Test Authority approval remains required before formal independent implementation evidence is accepted, and all production/external gates remain unchanged.

## Architecture audit summary

The original package was created after read-only inspection of `AGENTS.md`, the remaining Product Plan, existing Markdown architecture/ADRs, Slice 1 Quality Record, Git baseline metadata and current source contract shapes. On 15 September 2026 the approval JSON was parsed, its four roles/bodies, timestamps, commit IDs, scope restrictions and permalinks were reconciled to current `HEAD`, and documentation metadata was updated. No DOCX was reread. No application code, test, SQL, migration, database, environment, Git history or remote state was changed. No commit or push was performed.

## Hand-off

```yaml
handoff:
  from_agent: "architect"
  to_agent: "developer"
  state: "READY_FOR_DEVELOPMENT"
  work_item: "PH3-SQL-001-REMAINING"
  branch: "feature/ph3-remaining-plan"
  commit: "7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a"
  approved_architecture_commit: "7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a"
  incoming_plan_commit: "7e74f86a77df3d7e806694208784ab6238613715"
  delivery_slices: ["Slice 2", "Slice 3", "Slice 4"]
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-01", "C-02", "C-03", "C-04", "C-06"]
    functional_requirements: ["F-01", "F-02", "F-03", "F-04", "F-05", "F-07", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-04", "NF-05", "NF-06", "NF-08", "NF-09", "NF-10", "NF-11", "NF-12", "NF-13"]
    risks: ["R-01", "R-02", "R-03", "R-06", "R-09", "R-11"]
    assumptions: ["A-01", "A-02", "A-03", "A-05", "A-06", "A-08", "A-11", "A-13", "A-15", "A-16", "A-18"]
    dependencies: ["D-01", "D-03", "D-04", "D-05", "D-07", "D-08", "D-10", "D-11", "D-13"]
    issues: ["I-01", "I-02", "I-03", "I-04", "I-06", "I-08"]
    open_questions: ["Q-01", "Q-02", "Q-06", "Q-09"]
    approvals:
      - "Product Owner scope decision: onkarpathre, 2026-09-15T12:08:46Z, commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a, https://github.com/onkarpathre/lgr-transformation-migration/pull/6#pullrequestreview-5209736362"
      - "Architect/TDA formal approval: opathre, 2026-09-15T12:09:43Z, commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a, https://github.com/onkarpathre/lgr-transformation-migration/pull/6#pullrequestreview-5209749102"
      - "Information Security: ashish50thbirthday-ship-it, 2026-09-15T12:11:06Z, commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a, https://github.com/onkarpathre/lgr-transformation-migration/pull/6#pullrequestreview-5209763769"
      - "DBA/Discovery SME: nextgenexamprep-crypto, 2026-09-15T12:13:03Z, commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a, https://github.com/onkarpathre/lgr-transformation-migration/pull/6#pullrequestreview-5209781297"
  artefacts:
    - "docs/product/PH3_SQL_Remaining_Phase_Plan.md"
    - "docs/architecture/PH3_SQL_Remaining_Phase_Architecture.md"
    - "docs/architecture/Phase3_SQL_Discovery_Assessment_Architecture.md"
    - "docs/architecture/ADR-006-application-technology-stack.md"
    - "docs/architecture/ADR-007-phase3-tenancy-alignment.md"
    - "docs/architecture/ADR-008-internal-authentication-project-rbac.md"
    - "docs/quality/PH3_SQL_Slice1_Quality_Gate_Record.md"
    - "docs/approvals/PH3_SQL_PR6_Approvals.json"
  evidence:
    - "All supplied approval records target exact package commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a, which equals current branch HEAD and contains the plan and architecture package."
    - "The supplied records evidence the Product Owner decision and formal Architect/TDA, Information Security and DBA/Discovery SME approvals at the exact approved architecture commit."
    - "Slice 1 Quality Record recommends only the restricted inventory increment and preserves the remaining contract/SME approvals."
    - "The consolidated package defines all Slices 2-4 without rereading DOCX sources or changing implementation artefacts."
  decisions:
    - "Retain the remaining phase as one contract: two CSV imports/history, one human assessment model, browser journeys and a same-commit phase evidence contract."
    - "Reuse ADR-006/007/008; extend only named discovery/assessment permissions and preserve every local/non-production condition."
    - "Use two sequential expand-only migrations and default-off child flags with data-preserving rollback."
  assumptions:
    - "The accepted Slice 1 implementation and Quality Record remain unchanged."
    - "Only internal/synthetic identities and synthetic or properly anonymised data are used."
  risks:
    - "R-01/I-03 source ambiguity remains controlled by explicit contract, parent match and preview."
    - "R-02 remains release-blocking until every API/browser path passes independent isolation and permission tests."
    - "R-03/I-04 assessment quality remains human-owned; DBA/Discovery SME contract approval is recorded, while implementation must still produce independent evidence."
    - "R-09/R-11 remain controlled by same-commit SQL Server/browser/dependency evidence."
  defects: []
  blockers: []
  approvals:
    - "Existing ADR-006/007/008 and Slice 1 approvals are inherited only for unchanged restricted controls."
    - "Product Owner, Architect/TDA, Information Security and DBA/Discovery SME decisions are satisfied only for unchanged package commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a and their recorded restricted scopes."
  requested_action: "Implement sequential Slices 2-4 against approved architecture commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a within the documented restricted local/non-production scope. Obtain named Test Authority approval before formal independent implementation evidence is accepted. Production/external blockers remain wider Q-01, Q-02 commitment, Q-06/DPO, production tenancy, deployed Identity Platform/Q-09, Service Transition and human release authority; no merge, deployment, production migration, customer-data use or production action follows."
```
