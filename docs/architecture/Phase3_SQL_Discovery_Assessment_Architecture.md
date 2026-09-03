# Phase 3 SQL Discovery and Assessment - Architecture Work Package

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-02", "C-03", "C-04", "C-06"]
  functional_requirements: ["F-03", "F-04", "F-05", "F-07", "F-15"]
  non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-04", "NF-05", "NF-06", "NF-08", "NF-09", "NF-10", "NF-11", "NF-12", "NF-13"]
  risks: ["R-01", "R-02", "R-03", "R-06", "R-09", "R-11"]
  assumptions: ["A-01", "A-02", "A-05", "A-06", "A-08", "A-11", "A-13", "A-15", "A-16", "A-18"]
  dependencies: ["D-01", "D-03", "D-04", "D-05", "D-07", "D-08", "D-10", "D-11", "D-13"]
  issues: ["I-01", "I-02", "I-03", "I-04", "I-06", "I-08"]
  open_questions: ["Q-01", "Q-06", "Q-09"]
  approvals: []
```

## Control and outcome

- **Architecture package:** PH3-SQL-ARCH-001
- **Incoming work item:** PH3-SQL-001
- **Architecture exit state:** `BLOCKED_ARCHITECTURE_DECISION`
- **Reason:** the architecture is implementation-ready as a proposal, but Q-01/OD-07, the ADR-001/HLD DD-05 tenancy conflict, D-01 product/PRB scope approval and I-06 test-service agreement lack named human approval evidence. `AGENTS.md` prohibits agents from closing those gates unilaterally.
- **Roadmap baseline:** `docs/product/PRODUCT_GAP_ANALYSIS_AND_ROADMAP.md` is present in the current branch. Its terminology confirms this is Roadmap Phase 3 within Product Specification Phase 1 MVP; its presence does not close any pending product, architecture, security or test approval gate.

## Repository findings

The Phase 1/2 system is a modular monolith comprising one ASP.NET Core API, one Next.js application and one relational schema. The API targets .NET 10, EF Core 10 and SQL Server; the web package locks Next.js 16, React 19 and TypeScript. DTOs, Problem Details, immutable GUIDs, tenant query filters, project-aware services and async EF operations are established conventions.

Phase 2 supplies reusable file storage, UTF-8 CSV parsing, source mapper resolution, validation, JSON staging, preview/commit reconciliation, protected discovery/business field separation, duplicate-hash warning, transaction/audit behaviour and isolated API integration tests. `DiscoveryImportRow.MatchedEntityId` is currently a foreign key to `Server`; it cannot safely become an untyped/polymorphic SQL match.

The current fast integration suite replaces SQL Server with in-memory SQLite. That is useful for API and relational regression, but cannot prove SQL Server filtered-index, collation, check-constraint, migration or concurrent uniqueness behaviour. The web project has lint and production build scripts but no configured application test framework.

## Q-01 / OD-07 technology decision

The selected architectural recommendation is:

- Backend: .NET 10, ASP.NET Core, EF Core 10, SQL Server locally and Azure SQL-compatible persistence.
- Frontend: Next.js 16 App Router, React 19 and TypeScript.
- Structure: modular monolith with DTO-based REST APIs.
- Azure posture: deployable through a future approved Bicep/IaC pipeline; no Azure resource creation or production deployment in this work item.

This matches the HLD direction and current repository. [ADR-006](ADR-006-application-technology-stack.md) records the rationale and upgrade policy. Its status is Proposed because approval evidence is absent. Q-01/OD-07 therefore remains formally open and blocks implementation.

## Tenancy decision

The selected recommendation for this increment is the implemented shared database/shared schema, with mandatory `CustomerId` and `ProjectId` ownership and layered application/database controls. Phase 3 must not refactor tenancy as a side effect.

HLD DD-05 instead selects database-per-customer for production. [ADR-007](ADR-007-phase3-tenancy-alignment.md) records the conflict, security controls and migration implications. TDA must approve whether the shared model supersedes DD-05 or remains a non-production interim model. Until then, the decision is not effective for implementation or production.

## Component boundaries

```text
Next.js SQL inventory/assessment/import routes
              |
              | tenant-authorised JSON REST / multipart CSV
              v
ASP.NET Core controllers (DTOs only)
              |
              +-- SqlInventoryService
              +-- SqlAssessmentService
              +-- DiscoveryImportService orchestration
                     +-- SQL source mappers/validators
                     +-- SQL reconcilers/field policies
              |
              v
EF Core AppDbContext
  SqlInstances / SqlDatabases / SqlAssessments
  ImportBatch / DiscoveryImportRow / AuditEvent
              |
              v
SQL Server / Azure SQL-compatible schema
```

Controllers remain thin. SQL inventory and assessment rules belong in scoped services. Source-specific mapping, validation, reconciliation and protected-field policy remain separate testable components. Raw EF entities never cross the API boundary.

## Proposed domain model

All IDs are immutable application-generated GUIDs. All timestamps are `DateTimeOffset` stored as UTC. String lengths are explicit. `SqlDatabase` is the .NET entity/table stem to avoid ambiguity with framework `Database` APIs; the user-facing term remains Database.

### SqlInstance

| Field | Type / constraints | Ownership |
|---|---|---|
| Id | `Guid`, primary key, immutable | System |
| CustomerId | `Guid`, required | Server-side context |
| ProjectId | `Guid`, required | Server-side context |
| ServerId | `Guid`, required | User/source relationship, tenant validated |
| InstanceName | `string(128)`, required | Discovery-managed technical field |
| NormalizedInstanceName | `string(128)`, required | System-derived identity |
| SqlVersion | `string(100)`, required | Discovery-managed |
| Edition | `string(100)`, required | Discovery-managed |
| Port | `int?`, 1-65535 when present | Discovery-managed |
| ServiceStatus | `string(50)`, required | Discovery-managed |
| DiscoverySource | `string(100)`, required | Discovery-managed provenance |
| ServiceAccountName | `string(256)?`, optional non-sensitive display metadata; credentials/secrets prohibited | Human-managed unless a later source-contract amendment is approved |
| LastDiscoveredAt | `DateTimeOffset?` | Discovery-managed |
| LastImportedAt | `DateTimeOffset?` | System/import |
| CreatedAt | `DateTimeOffset`, required | System |
| UpdatedAt | `DateTimeOffset`, required | System |

### SqlDatabase

| Field | Type / constraints | Ownership |
|---|---|---|
| Id | `Guid`, primary key, immutable | System |
| CustomerId | `Guid`, required | Server-side context |
| ProjectId | `Guid`, required | Server-side context |
| SqlInstanceId | `Guid`, required | User/source relationship, tenant validated |
| Name | `string(128)`, required | Discovery-managed technical field |
| NormalizedName | `string(128)`, required | System-derived identity |
| SizeMb | `long`, required, non-negative | Discovery-managed |
| CompatibilityLevel | `int`, required, approved range | Discovery-managed |
| RecoveryModel | `string(30)`, required | Discovery-managed |
| Collation | `string(128)?` | Discovery-managed |
| Status | `string(50)`, required | Discovery-managed |
| CreatedAt | `DateTimeOffset`, required | System |
| UpdatedAt | `DateTimeOffset`, required | System |

### SqlAssessment

| Field | Type / constraints | Ownership |
|---|---|---|
| Id | `Guid`, primary key, immutable | System |
| CustomerId | `Guid`, required | Server-side context |
| ProjectId | `Guid`, required | Server-side context |
| SqlInstanceId | `Guid?` | Human-selected target |
| SqlDatabaseId | `Guid?` | Human-selected target |
| AssessmentStatus | `string(50)`, required | Human-managed |
| ReadinessStatus | `string(50)`, required | Human-managed |
| TargetPlatform | `string(80)`, required | Human-managed |
| TargetSqlVersion | `string(100)?` | Human-managed |
| MigrationApproach | `string(100)`, required | Human-managed |
| Blockers | `string(4000)`, required, may be empty | Human-managed |
| Findings | `string(8000)`, required, may be empty | Human-managed |
| Notes | `string(4000)`, required, may be empty | Human-managed |
| AssessedAt | `DateTimeOffset?` | Human workflow |
| CreatedAt | `DateTimeOffset`, required | System |
| UpdatedAt | `DateTimeOffset`, required | System |

Exactly one of `SqlInstanceId` or `SqlDatabaseId` is populated, enforced by a check constraint. One current assessment exists per instance or database, enforced by separate filtered unique indexes. Change history is carried by field-level audit events; future versioned assessments require a new approved work item.

Allowed `TargetPlatform` values are exactly:

- `AzureSqlDatabase`
- `AzureSqlManagedInstance`
- `SqlServerOnAzureVm`
- `Retain`
- `Retire`
- `Investigate`

API DTOs provide stable display labels. These values are recorded planning decisions only and have no executor/provisioner mapping. Assessment/readiness/migration-approach value lists must be central domain constants or approved lookup values, not arbitrary controller strings.

### Append-only SQL discovery history

Add `SqlInstanceDiscoverySnapshot` and `SqlDatabaseDiscoverySnapshot` rather than a polymorphic snapshot foreign key. Each has an immutable GUID, `CustomerId`, `ProjectId`, its explicit canonical parent ID, `ImportBatchId`, the discovered fields for that record and `ImportedAt`. Snapshot relationships use tenant-safe composite foreign keys and `Restrict` deletes. Snapshots are append-only after a successful commit, remain query-filtered/project-scoped, and never contain credentials or secrets. Raw source remains in the existing staging row; snapshots provide typed provenance/history without making staging the canonical model.

`SqlInstanceDiscoverySnapshot` contains exactly: `Id Guid`, `CustomerId Guid`, `ProjectId Guid`, `SqlInstanceId Guid`, `ImportBatchId Guid`, `ServerId Guid`, `InstanceName string(128)`, `SqlVersion string(100)`, `Edition string(100)`, `Port int?`, `ServiceStatus string(50)`, `DiscoverySource string(100)`, `LastDiscoveredAt DateTimeOffset?`, and `ImportedAt DateTimeOffset`. `ServiceAccountName` is deliberately excluded because CSV v1 cannot manage it.

`SqlDatabaseDiscoverySnapshot` contains exactly: `Id Guid`, `CustomerId Guid`, `ProjectId Guid`, `SqlDatabaseId Guid`, `ImportBatchId Guid`, `SqlInstanceId Guid`, `Name string(128)`, `SizeMb long`, `CompatibilityLevel int`, `RecoveryModel string(30)`, `Collation string(128)?`, `Status string(50)`, and `ImportedAt DateTimeOffset`.

### Optional service-account display metadata

`ServiceAccountName` is manual display metadata only and is excluded from both CSV v1 contracts. On write, normalize to Unicode Form C and trim; blank becomes null. A non-null value must be at most 256 characters and match `^[\p{L}\p{N}][\p{L}\p{N} ._@$\\-]{0,255}$`, supporting common `DOMAIN\account`, `account@domain` and `NT SERVICE\name` identifiers. Control characters, line breaks, tabs, `:`, `;`, `=`, quotes, URI schemes and other characters outside that allow-list reject the request. No password/token/key/connection-string field exists. The UI states "Account display name only - never enter credentials". Audit records that the field changed but does not copy its old/new value into general logs; raw request values are never logged.

## Keys, uniqueness, indexes and relationships

### Alternate keys and tenant-safe foreign keys

To prevent a valid foreign ID being paired with the wrong ownership columns, new Phase 3 relationships use composite alternate keys/foreign keys where EF Core and both target providers support them:

- Server alternate key: `(Id, CustomerId, ProjectId)`.
- SqlInstance alternate key: `(Id, CustomerId, ProjectId)`.
- SqlDatabase alternate key: `(Id, CustomerId, ProjectId)`.
- SqlInstance FK: `(ServerId, CustomerId, ProjectId)` -> Server alternate key.
- SqlDatabase FK: `(SqlInstanceId, CustomerId, ProjectId)` -> SqlInstance alternate key.
- SqlAssessment instance FK: `(SqlInstanceId, CustomerId, ProjectId)` -> SqlInstance alternate key when populated.
- SqlAssessment database FK: `(SqlDatabaseId, CustomerId, ProjectId)` -> SqlDatabase alternate key when populated.

Service validation remains mandatory; constraints are defence in depth. The migration design must confirm that adding the Server alternate key is additive and valid for existing data before generation.

### Business uniqueness and query indexes

- Unique `UX_SqlInstances_CustomerId_ServerId_NormalizedInstanceName` on `(CustomerId, ServerId, NormalizedInstanceName)`.
- Unique `UX_SqlDatabases_CustomerId_SqlInstanceId_NormalizedName` on `(CustomerId, SqlInstanceId, NormalizedName)`.
- Index `(CustomerId, ProjectId, ServerId)` for instance lists/joins.
- Index `(CustomerId, ProjectId, ServiceStatus)` for inventory filtering.
- Index `(CustomerId, ProjectId, SqlInstanceId)` for database lists/joins.
- Index `(CustomerId, ProjectId, Status)` for database filtering.
- Filtered unique indexes for current assessment target IDs.
- Index `(CustomerId, ProjectId, AssessmentStatus, ReadinessStatus)` for assessment dashboards.
- Import staging indexes described below for batch row order, classification and normalized SQL matching values.
- Snapshot indexes `(CustomerId, ProjectId, SqlInstanceId, ImportedAt)` and `(CustomerId, ProjectId, SqlDatabaseId, ImportedAt)`.

Normalized identity is Unicode Form C, trimmed, invariant uppercase. `MSSQLSERVER` is the canonical default-instance name. Display names retain the reviewed spelling. Normalized columns are assigned by domain/service code for deterministic SQL Server/SQLite behaviour; database collation is not the only uniqueness control.

### Delete behaviour

- Server -> SqlInstance: `Restrict`.
- SqlInstance -> SqlDatabase: `Restrict`.
- SqlInstance/SqlDatabase -> SqlAssessment: `Restrict` for direct target deletion; the user must explicitly remove/archive the assessment first.
- ImportBatch -> DiscoveryImportRow remains `Cascade` only for uncommitted owned staging according to existing lifecycle rules.
- Audit records and committed source evidence are not cascaded from canonical inventory.
- SqlInstance/SqlDatabase -> discovery snapshots: `Restrict`.

No API implements bulk cascade deletion of SQL workloads in this increment.

## Tenant isolation and authorisation

- Add EF global `CustomerId` filters to all three entities.
- Every scoped service query also requires `ProjectId == currentContext.ProjectId`.
- Ownership fields are never accepted from create/update DTOs; they come from authenticated server-side context.
- Relationship lookup uses the same customer query filter plus explicit current project predicate.
- Inaccessible IDs return 404 without identifying the owning tenant/project.
- Lists are paged and bounded; search strings are parameters, never dynamic SQL.
- Import matching starts from the current tenant/project and cannot fall back to hostname/instance/database name across projects.
- Audit events carry current customer/project and actor. Raw CSV rows and validation errors must not be logged.
- File storage uses generated names and a tenant/project-authorised metadata lookup. Production file storage/identity remains outside scope and blocked by its own gates.

The existing development-header context is permitted only in local development/test. It is not production authentication or tenant authorisation.

## API contract proposal

All routes use DTOs, asynchronous EF operations, validation and RFC Problem Details.

- `GET /api/sql-instances?page=&pageSize=&search=&serverId=&serviceStatus=`
- `GET /api/sql-instances/{id}`
- `POST /api/sql-instances`
- `PUT /api/sql-instances/{id}`
- `DELETE /api/sql-instances/{id}`
- `GET /api/sql-databases?page=&pageSize=&search=&sqlInstanceId=&status=`
- `GET /api/sql-databases/{id}`
- `POST /api/sql-databases`
- `PUT /api/sql-databases/{id}`
- `DELETE /api/sql-databases/{id}`
- `GET /api/sql-assessments?sqlInstanceId=&sqlDatabaseId=&assessmentStatus=&readinessStatus=`
- `GET /api/sql-assessments/{id}`
- `POST /api/sql-assessments`
- `PUT /api/sql-assessments/{id}`
- `DELETE /api/sql-assessments/{id}` subject to audit/relationship policy

Existing `/api/discovery/imports` upload, preview, rows, detail, commit and cancel endpoints remain the import boundary. Add source types `SqlInstanceCsv` and `SqlDatabaseCsv`; do not create a second ungoverned upload surface.

Write DTOs contain only editable business fields and relationship IDs. Response DTOs contain named server/instance references and audit/provenance timestamps. No DTO accepts `CustomerId`, `ProjectId`, normalized keys, discovery import IDs or audit actor.

Conflicts such as normalized duplicates return 409. Invalid values/state return 400. Missing/inaccessible records return 404. Concurrency/stale-preview failures request a new read/preview and do not partially commit.

## SQL discovery source contract

Only synthetic UTF-8 comma-separated `.csv` fixtures are approved for development/test. Macros, spreadsheets, archives and executable content are not supported. Selection of the source type is explicit; content is never used to auto-authorise a source or tenant.

### Contract identifiers

- `SqlInstanceCsv/v1`
- `SqlDatabaseCsv/v1`

The selected source type supplies the contract version. Column order is irrelevant. Unknown columns are retained in raw staging evidence and generate one batch warning; they are not mapped without an approved contract change.

### SQL Instance source

| Column | Required header | Required value | Validation / normalization |
|---|---:|---:|---|
| Server | Yes | Yes | Trim; resolve against normalized Server hostname in current customer/project. |
| Instance Name | Yes | Yes | Trim, Unicode Form C, max 128; invariant-uppercase matching; default aliases normalize to `MSSQLSERVER`. |
| SQL Version | Yes | Yes | Trim, max 100. |
| Edition | Yes | Yes | Trim, max 100. |
| Port | No | No | Whole number 1-65535 when supplied. |
| Service Status | Yes | Yes | Trim and normalize approved aliases to `Running`, `Stopped`, `Paused`, `Disabled` or `Unknown`. |
| Discovery Source | Yes | Yes | Trim, max 100; data/provenance only, never executed. |
| Last Discovered At | No | No | ISO-8601 timestamp with offset; convert to UTC. |

Instance matching is exactly `CustomerId + ServerId + NormalizedInstanceName`, after resolving `Server` in the current project. An unmatched or ambiguous server is a Reject. A cross-project/cross-customer record is a non-enumerating Reject.

### SQL Database source

| Column | Required header | Required value | Validation / normalization |
|---|---:|---:|---|
| Server | Yes | Yes | Trim; resolve only in current customer/project. |
| Instance Name | Yes | Yes | Resolve using the SQL Instance normalization rule. |
| Database Name | Yes | Yes | Trim, Unicode Form C, max 128; invariant-uppercase matching. |
| Size MB | Yes | Yes | Invariant-culture non-negative whole number within `Int64`. |
| Compatibility Level | Yes | Yes | Whole number in the architect-approved supported range; v1 accepts 80-200 for forward-compatible capture. |
| Recovery Model | Yes | Yes | Normalize to `Simple`, `Full` or `BulkLogged`. |
| Collation | No | No | Trim, max 128; blank remains null. |
| Status | Yes | Yes | Normalize approved aliases; unsupported but safe values become `Unknown` with a warning and raw value retained. |

Database matching is exactly `CustomerId + SqlInstanceId + NormalizedDatabaseName`, after resolving Server and SQL Instance in the current project. An unmatched or ambiguous parent is a Reject.

### Header normalization

Reuse Phase 2 `DiscoveryColumnName.Normalize`: trim, remove non-alphanumeric characters and compare case-insensitively. Thus `Instance Name`, `instance_name` and `INSTANCE-NAME` map to the same contract name. Two source headers that collapse to one normalized name reject the file. Blank/duplicate mandatory headers, invalid UTF-8, empty files and row-width overflow reject the file.

### Row normalization and matching

- Trim outer whitespace; retain raw staged values.
- Use Unicode Form C before invariant case normalization for business keys.
- Do not use mutable names as primary keys.
- Do not infer a Server from a partial name, IP address or cross-project match.
- Do not automatically split `Server\\Instance` in the Instance Name column. If a fully-qualified instance is supplied, it must be rejected with guidance to place values in the two defined columns; this avoids ambiguous parsing.
- Blank optional values do not clear existing canonical fields.
- Timestamps convert to UTC; displayed values retain no authority over tenant context.

### Duplicate, warning and reject policy

All rows that share a normalized business key within one file are Rejects; rejecting every occurrence avoids order-dependent winners. A repeated file hash warns but does not by itself block an intentional re-run.

Warnings include:

- unknown extra columns;
- a safe service/database status alias mapped to `Unknown`;
- a source value that is valid but outside the currently recognised display vocabulary; and
- a repeat-file hash.

Rejects include:

- missing required header or value;
- duplicate normalized header or row business key;
- unmatched/ambiguous/cross-project parent;
- invalid UTF-8/CSV structure;
- invalid/out-of-range port, size, compatibility level or timestamp;
- over-length identity or technical value; and
- a row whose source type does not match the selected contract.

Warnings may commit only when identity and relationships are safe. Reject rows never change canonical data.

### Reconciliation and protected fields

- No canonical mutation occurs during upload or preview.
- Create builds a new canonical record only when required values and parent relationships are valid.
- Update lists field-level differences only for discovery-managed technical fields.
- Unchanged means all supplied discovery-managed values are equivalent after normalization.
- Commit conditionally claims a preview-ready batch, revalidates current parents/old values and applies one relational transaction.
- A stale parent or changed old value fails the whole commit and requests re-preview.
- SQL Assessment fields, target platform/version, migration approach, blockers, findings, notes and approval/governance state are always protected from discovery.
- `ServiceAccountName` is protected from CSV v1 import. A later amendment may map only a non-sensitive display name after Product Owner/DBA/Information Security approval; credential-like values always reject.
- Field-level audit records cover changed technical values; significant creates and the batch commit receive summary events.
- Every committed safe SQL row creates the appropriate typed append-only discovery snapshot, including Unchanged rows, matching the established server-history pattern.

### Reuse of Phase 2 staging

Extend `ImportBatch`, source resolver, parser and orchestration. Extend `DiscoveryImportRow` additively with:

- `NormalizedInstanceName string(128)?`
- `NormalizedDatabaseName string(128)?`
- `MatchedSqlInstanceId Guid?`
- `MatchedSqlDatabaseId Guid?`

Keep existing `MatchedEntityId` as the Server match for existing Phase 2 behaviour. Add explicit foreign keys for each new match; do not remove its Server FK or turn one GUID into a polymorphic reference. A source-type/check rule permits only the match columns appropriate to that row. Existing server imports and history remain backward compatible.

## Security, privacy, audit and observability

- Treat files and values as untrusted data; no SQL, PowerShell, shell, macro or formula execution path exists.
- Retain only fields required for inventory, assessment and audit; use synthetic test data.
- Do not emit raw rows, database names or findings to general application logs. Operational logs use batch/row IDs, counts, result and correlation ID.
- Audit actor, tenant/project, entity/action, UTC timestamp and field-level old/new values subject to redaction/length controls.
- Metrics cover upload/preview/commit success/failure/duration and row classifications without customer-data labels.
- Existing local file storage remains development-only; production Blob, malware scanning, retention, private connectivity and managed identity require separate approval.

## Performance and supportability

- List endpoints default to 50 and cap at 200 rows.
- Preview/row endpoints are paged; source size uses the existing configured upper bound.
- Load only current-batch parents needed for matching into normalized dictionaries; no per-row parent query/N+1 pattern.
- Use no-tracking queries for read-only lists and explicit includes/projections.
- Validate with at least 200 mixed assets and document timings; larger import/background processing is a later architecture decision.
- Use central value constants, dedicated services and source-specific tests; do not expand the general `ProgrammeService` indefinitely if the SQL module has coherent boundaries.

## Compatibility, migration, deployment and rollback

- Create one additive EF migration, provisionally `AddSqlDiscoveryAssessment`, containing the three canonical tables, two typed snapshot tables, ownership constraints/indexes and additive staging columns/FKs.
- Before generation, validate existing Server `(Id, CustomerId, ProjectId)` uniqueness and provider support for the alternate key.
- Migration `Down` may remove only the newly added structures in development; production rollback must use reviewed forward-fix/data-preserving procedures and backup/restore planning.
- The application must not auto-apply migrations in production.
- Gate SQL navigation/API exposure behind a default-off configuration feature flag until schema deployment and verification complete. The flag is not a security boundary.
- Bicep requires no Phase 3 change because no Azure resource is introduced. Production deployment remains out of scope.

## Agreed test approach proposal

### API and domain

- xUnit unit tests for normalization, validation, field ownership, reconciliation and domain value/state rules.
- Existing in-memory SQLite `WebApplicationFactory` tests for fast HTTP, DTO, tenant/project and regression coverage.
- A mandatory SQL Server integration lane using SQL Server Express in an approved developer/test environment or an ephemeral SQL Server service/container in CI. Each run uses an isolated synthetic database, applies the checked-in migration, tests constraints/collation/concurrency/transactions, and cleans up only its verified test database.
- Never point tests at production or customer databases. A missing SQL Server endpoint is an environment blocker, not evidence of a product pass or defect.

### Frontend

- ESLint and `next build` remain mandatory static/build gates.
- Add Vitest with React Testing Library and user-event for component/page state, forms, accessible names, validation, loading/empty/error behaviour and API mocking.
- Add Playwright for critical browser journeys: tenant/project context, SQL list/detail/CRUD, import preview/commit and assessment. Run against a synthetic isolated test API/database.
- Include automated accessibility checks in critical views where the approved toolchain permits; complete keyboard/manual checks in independent testing.

This is the architecture/tester recommendation. I-06 closes only when Agilisys Test Services or the named test authority records agreement, environments and entry/exit criteria.

## Required independent test conditions

The Tester must prove:

- SQL Instance and Database positive/negative CRUD and safe errors;
- unique normalized business keys, including concurrent create/commit on SQL Server;
- same-tenant/project Server -> Instance -> Database relationships and cross-tenant/project direct-object rejection;
- assessment XOR target constraint, allowed target platforms and protected fields;
- both CSV contracts, header/row normalization, warning/reject policy and malicious/oversized/malformed inputs;
- deterministic Create/Update/Unchanged preview and transactional reconciliation;
- stale-preview/repeat-commit protection and audit evidence;
- bounded API queries, DTO boundaries and regression;
- frontend component/browser/a11y behaviour plus lint/build; and
- the absence of DMS, migration execution, AI recommendation, remediation and Azure provisioning paths.

## Human approvals required before implementation

1. Product Owner/PRB: PH3-SQL-001 scope/phasing (D-01).
2. Solution Architect/TDA: ADR-006 and closure of Q-01/OD-07.
3. Solution Architect/TDA and Information Security: ADR-007 tenancy alignment and HLD/ADR disposition.
4. Product Owner, Architect and DBA/Discovery SME: `SqlInstanceCsv/v1` and `SqlDatabaseCsv/v1` contract/fixture approval.
5. Agilisys Test Services or named test authority: frontend and SQL Server environments, tools, entry/exit criteria (I-06/D-11).

## Hand-off

```yaml
handoff:
  from_agent: "architect"
  to_agent: "developer"
  state: "BLOCKED_ARCHITECTURE_DECISION"
  work_item: "PH3-SQL-001"
  branch: null
  commit: null
  traceability:
    capabilities: ["C-02", "C-03", "C-04", "C-06"]
    functional_requirements: ["F-03", "F-04", "F-05", "F-07", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-04", "NF-06", "NF-08", "NF-09", "NF-10", "NF-13"]
  artefacts:
    - "docs/product/Phase3_SQL_Discovery_Assessment_Work_Item.md"
    - "docs/architecture/Phase3_SQL_Discovery_Assessment_Architecture.md"
    - "docs/architecture/ADR-006-application-technology-stack.md"
    - "docs/architecture/ADR-007-phase3-tenancy-alignment.md"
  evidence:
    - "Product Specification V0.1 and HLD V0.1"
    - "Phase 1/2 source, migration, test and frontend package inspection"
  decisions:
    - "Proposed application stack recorded in ADR-006; approval pending."
    - "Proposed Phase 3 shared-tenancy alignment recorded in ADR-007; approval pending."
  assumptions:
    - "Only synthetic CSV data is used."
    - "No Phase 3 implementation begins in this run."
  risks: ["R-01", "R-02", "R-03", "R-06", "R-09", "R-11"]
  defects: []
  blockers:
    - "D-01 Product Owner/PRB approval evidence missing."
    - "Q-01/OD-07 and ADR-006 TDA approval evidence missing."
    - "ADR-001 versus HLD DD-05 requires TDA/Information Security decision."
    - "Synthetic CSV contracts/fixtures require named human approval."
    - "I-06 frontend and SQL Server test approach requires test-authority agreement."
  approvals: []
  requested_action: "Do not implement; produce a scoped implementation plan and expected file/migration inventory for review after the blocking approvals are obtained."
```
