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
  open_questions: ["Q-01", "Q-02", "Q-06", "Q-09"]
  approvals:
    - "Product Owner JP (GitHub reviewer: opathre), 8 September 2026: approved local POC implementation of PH3-SQL-001 subject to PR #1 restrictions; this is not architecture, TDA, Information Security, PRB, production or release approval."
```

## Control and outcome

- **Architecture package:** PH3-SQL-ARCH-001
- **Incoming work item:** PH3-SQL-001
- **Incoming approval evidence:** Product Owner JP (`opathre`), 8 September 2026, approved local POC implementation subject to GitHub PR #1 restrictions; PR #1 was merged to `main` at `579171c927905876640cdf6bcb48ee8261b6c301`.
- **Architecture exit state:** `READY_FOR_ARCHITECTURE_APPROVAL`
- **Development authority:** Not granted. This state means the proposed work package is complete enough for named human review; it is explicitly not `READY_FOR_DEVELOPMENT`.
- **Reason:** Q-01/OD-07 and ADR-006 require Solution Architect/TDA approval. ADR-007 requires Solution Architect/TDA and Information Security approval to reconcile ADR-001 with HLD DD-05. CSV contracts and the test approach also require the named approvals below. `AGENTS.md` prohibits an agent from closing those gates.
- **Roadmap baseline:** `docs/product/PRODUCT_GAP_ANALYSIS_AND_ROADMAP.md` is present in the current branch. Its terminology confirms this is Roadmap Phase 3 within Product Specification Phase 1 MVP; its presence does not close any pending product, architecture, security or test approval gate.

## Traceability reconciliation and gate assessment

The Architecture Work Package retains every capability, functional requirement, non-functional requirement, risk, assumption, dependency, issue and open question listed by PH3-SQL-001. It adds only existing Product Specification references made relevant by the architecture review:

- NF-03, NF-05, NF-11 and NF-12 for encryption/private connectivity, UK residency, security alignment and supportability;
- R-11 for the Product Specification technology-baseline conflict;
- A-15 and A-16 for Azure SQL capacity and pre-production security/privacy confirmation;
- D-03, D-04, D-05 and D-10 for identity, delivery tooling, data services and security/privacy review;
- I-01 and I-02 for unconfirmed production hosting and external identity; and
- Q-02, Q-06 and Q-09 for delivery commitments, production DPIA and external-customer identity.

No new specification identifiers are introduced. The added references do not expand PH3-SQL-001 into production hosting, identity or deployment work.

| Gate / dependency | Assessment for this package | Effect |
|---|---|---|
| Product Owner approval | Evidenced for local POC implementation only through PR #1. | Satisfies the Product Owner entry decision only. It does not supply PRB or technical approval. |
| Q-01 / HLD OD-07 / ADR-006 | Open; ADR-006 is Proposed. | Blocks development under `AGENTS.md` until a named Solution Architect/TDA decision is recorded. |
| ADR-001 versus HLD DD-05 / ADR-007 | Open; ADR-007 is Proposed. | Blocks using the shared persistence recommendation for this increment until Solution Architect/TDA and Information Security decide its scope and conditions. |
| Q-02 / D-01 | PRB budget, investment and phasing evidence is absent. | Does not block preparing this architecture; blocks asserting a committed delivery/release baseline or spending beyond the Product Owner's expressly limited local POC approval. |
| Q-06 | Open. | Does not block synthetic local development; blocks production personal-data processing pending DPO determination and any required DPIA. |
| Q-09 | Open. | Does not block domain work that remains isolated from external identity; blocks external customer access. Development headers remain local/test-only. |
| I-06 / D-11 | Test tools, environment and entry/exit criteria await the named test authority. | Must be agreed before implementation evidence can be accepted as formal system/test evidence. |

The merge commit contains the six PH3-SQL-001 product/architecture documents and no application, test or database implementation. It proves repository adoption of the approval pack, not implementation or technical approval.

## Repository findings

The Phase 1/2 system is a modular monolith comprising one ASP.NET Core API, one Next.js application and one relational schema. At baseline commit `579171c927905876640cdf6bcb48ee8261b6c301`, the API targets `net10.0` and pins EF Core SQL Server/Design `10.0.11`; the web package pins Next.js `16.2.12`, React/React DOM `19.2.8` and TypeScript `5.9.3`. `eslint-config-next` is `16.2.11` and should be aligned with the selected Next.js patch during development after dependency review. DTOs, Problem Details, immutable GUIDs, tenant query filters, project-aware services and async EF operations are established conventions.

Phase 2 supplies reusable file storage, UTF-8 CSV parsing, source mapper resolution, validation, JSON staging, preview/commit reconciliation, protected discovery/business field separation, duplicate-hash warning, transaction/audit behaviour and isolated API integration tests. `DiscoveryImportRow.MatchedEntityId` is currently a foreign key to `Server`; it cannot safely become an untyped/polymorphic SQL match.

The current fast integration suite replaces SQL Server with in-memory SQLite and creates the schema with `EnsureCreated`. That is useful for API and relational regression, but cannot prove the checked-in SQL Server migration path, `rowversion`, filtered indexes, collation, check constraints or concurrent uniqueness behaviour. The web project has lint and production build scripts but no configured component or browser test framework.

## Q-01 / OD-07 technology decision

The selected architectural recommendation is:

- Backend: .NET 10, ASP.NET Core, EF Core 10, SQL Server for provider verification and Azure SQL-compatible persistence. Remain on the latest approved `10.0.x` patch through normal dependency review.
- Frontend: Next.js 16 App Router, React 19 and TypeScript, with exact versions and the lock file committed. Align Next.js and `eslint-config-next` patch versions. Pin the build/runtime to a supported Node.js 24 LTS patch; Next.js 16 requires Node.js 20.9 or later, but Node.js 20 is already end-of-life as of this review.
- Structure: modular monolith with DTO-based REST APIs.
- Azure posture: deployable through a future approved Bicep/IaC pipeline; no Azure resource creation or production deployment in this work item.

This matches the HLD direction and current repository. Microsoft lists .NET 10 as active LTS through November 2028 and EF Core 10 as supported through November 2028. Vercel lists Next.js 16 as Active LTS, and the Node.js project lists Node.js 24 as LTS. [ADR-006](ADR-006-application-technology-stack.md) records the evidence, alternatives, consequences and upgrade policy. Its status is Proposed because approval evidence is absent. Q-01/OD-07 therefore remains formally open and blocks implementation.

## Tenancy decision

The recommendation is a two-horizon decision, not a silent replacement of either baseline:

1. For PH3-SQL-001 development and non-production only, retain the implemented shared database/shared schema with mandatory server-derived `CustomerId`, authorised `ProjectId` and layered application/database isolation. Do not introduce catalogue routing or a multi-database migration orchestrator as a side effect of this domain increment.
2. For production, retain HLD DD-05 (catalogue plus database per customer) as the proposed target pending formal TDA approval and a separately approved transition work item. The shared model is not approved for production customer processing by this package.

[ADR-007](ADR-007-phase3-tenancy-alignment.md) records the evidence, five alternatives, consequences, compensating controls and future transition requirements. Solution Architect/TDA and Information Security must approve, reject or condition this recommendation. If they prefer a shared production database, they must explicitly supersede HLD DD-05 and approve the corresponding RLS, recovery, deletion, offboarding, scale and security design. Until the human decision is recorded, ADR-007 is not effective and development is not authorised.

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
| LastImportBatchId | `Guid?`, same-tenant/project FK to `ImportBatch` | System/import provenance |
| LastImportedAt | `DateTimeOffset?` | System/import |
| CreatedAt | `DateTimeOffset`, required | System |
| UpdatedAt | `DateTimeOffset`, required | System |
| CreatedBy | `string(200)`, required | System/current actor |
| UpdatedBy | `string(200)`, required | System/current actor |
| IsDeleted | `bool`, required, default false | System/lifecycle |
| DeletedAt | `DateTimeOffset?` | System/lifecycle |
| DeletedBy | `string(200)?` | System/current actor |
| RowVersion | SQL Server `rowversion`, required concurrency token | System |

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
| LastImportBatchId | `Guid?`, same-tenant/project FK to `ImportBatch` | System/import provenance |
| LastImportedAt | `DateTimeOffset?` | System/import |
| CreatedAt | `DateTimeOffset`, required | System |
| UpdatedAt | `DateTimeOffset`, required | System |
| CreatedBy | `string(200)`, required | System/current actor |
| UpdatedBy | `string(200)`, required | System/current actor |
| IsDeleted | `bool`, required, default false | System/lifecycle |
| DeletedAt | `DateTimeOffset?` | System/lifecycle |
| DeletedBy | `string(200)?` | System/current actor |
| RowVersion | SQL Server `rowversion`, required concurrency token | System |

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
| TargetPlatform | `string(80)?`; required before assessment completion | Human-managed |
| TargetSqlVersion | `string(100)?` | Human-managed |
| MigrationApproach | `string(100)?`; required where the selected outcome calls for migration | Human-managed |
| Blockers | `string(4000)`, required, may be empty | Human-managed |
| Findings | `string(8000)`, required, may be empty | Human-managed |
| Notes | `string(4000)`, required, may be empty | Human-managed |
| AssessedAt | `DateTimeOffset?` | Human workflow |
| CreatedAt | `DateTimeOffset`, required | System |
| UpdatedAt | `DateTimeOffset`, required | System |
| CreatedBy | `string(200)`, required | System/current actor |
| UpdatedBy | `string(200)`, required | System/current actor |
| IsDeleted | `bool`, required, default false | System/lifecycle |
| DeletedAt | `DateTimeOffset?` | System/lifecycle |
| DeletedBy | `string(200)?` | System/current actor |
| RowVersion | SQL Server `rowversion`, required concurrency token | System |

Exactly one of `SqlInstanceId` or `SqlDatabaseId` is populated, enforced by `CK_SqlAssessments_ExactlyOneTarget`. One active assessment exists per instance or database, enforced by separate filtered unique indexes. Change history is carried by field-level audit events; future versioned assessments require a new approved work item.

Allowed `TargetPlatform` values are exactly:

- `AzureSqlDatabase`
- `AzureSqlManagedInstance`
- `SqlServerOnAzureVm`
- `Retain`
- `Retire`
- `Investigate`

API DTOs provide stable display labels. These values are recorded planning decisions only and have no executor/provisioner mapping. Assessment/readiness/migration-approach value lists must be central domain constants or approved lookup values, not arbitrary controller strings.

The proposed v1 status values are `NotStarted`, `InProgress`, `Complete` and `Blocked` for `AssessmentStatus`; and `NotAssessed`, `NotReady`, `AtRisk`, `ReadyWithConditions`, `Ready` and `Blocked` for `ReadinessStatus`. `TargetPlatform` and `MigrationApproach` may be null while an assessment is `NotStarted` or `InProgress`. A `Complete` assessment requires a target platform; an Azure migration target also requires a migration approach, while `Retain`, `Retire` and `Investigate` must not carry a target SQL version. These controlled values remain part of the Product Owner/Architect/DBA contract approval and are not approved merely by appearing here.

### Append-only SQL discovery history

Add `SqlInstanceDiscoverySnapshot` and `SqlDatabaseDiscoverySnapshot` rather than a polymorphic snapshot foreign key. Each has an immutable GUID, `CustomerId`, `ProjectId`, its explicit canonical parent ID, `ImportBatchId`, the discovered fields for that record and `ImportedAt`. Snapshot relationships use tenant-safe composite foreign keys and `Restrict` deletes. Snapshots are append-only after a successful commit, remain query-filtered/project-scoped, and never contain credentials or secrets. Raw source remains in the existing staging row; snapshots provide typed provenance/history without making staging the canonical model.

`SqlInstanceDiscoverySnapshot` contains exactly: `Id Guid`, `CustomerId Guid`, `ProjectId Guid`, `SqlInstanceId Guid`, `ImportBatchId Guid`, `ServerId Guid`, `InstanceName string(128)`, `SqlVersion string(100)`, `Edition string(100)`, `Port int?`, `ServiceStatus string(50)`, `DiscoverySource string(100)`, `LastDiscoveredAt DateTimeOffset?`, and `ImportedAt DateTimeOffset`. `ServiceAccountName` is deliberately excluded because CSV v1 cannot manage it.

`SqlDatabaseDiscoverySnapshot` contains exactly: `Id Guid`, `CustomerId Guid`, `ProjectId Guid`, `SqlDatabaseId Guid`, `ImportBatchId Guid`, `SqlInstanceId Guid`, `Name string(128)`, `SizeMb long`, `CompatibilityLevel int`, `RecoveryModel string(30)`, `Collation string(128)?`, `Status string(50)`, and `ImportedAt DateTimeOffset`.

### Optional service-account display metadata

`ServiceAccountName` is manual display metadata only and is excluded from both CSV v1 contracts. On write, normalize to Unicode Form C and trim; blank becomes null. A non-null value must be at most 256 characters and match `^[\p{L}\p{N}][\p{L}\p{N} ._@$\\-]{0,255}$`, supporting common `DOMAIN\account`, `account@domain` and `NT SERVICE\name` identifiers. Control characters, line breaks, tabs, `:`, `;`, `=`, quotes, URI schemes and other characters outside that allow-list reject the request. No password/token/key/connection-string field exists. The UI states "Account display name only - never enter credentials". Audit records that the field changed but does not copy its old/new value into general logs; raw request values are never logged.

## Keys, uniqueness, indexes and relationships

### Alternate keys and tenant-safe foreign keys

To prevent a valid foreign ID being paired with the wrong ownership columns, new Phase 3 relationships use tenant-leading composite principal keys and foreign keys. The immutable GUID remains the primary key; the composite alternate keys exist specifically as same-owner relationship targets.

- Project principal key: `(CustomerId, Id)`.
- Server, ImportBatch, SqlInstance and SqlDatabase principal keys: `(CustomerId, ProjectId, Id)`.
- SqlInstance project FK: `(CustomerId, ProjectId)` -> Project `(CustomerId, Id)`.
- SqlInstance server FK: `(CustomerId, ProjectId, ServerId)` -> Server `(CustomerId, ProjectId, Id)`.
- SqlDatabase project FK: `(CustomerId, ProjectId)` -> Project `(CustomerId, Id)`.
- SqlDatabase instance FK: `(CustomerId, ProjectId, SqlInstanceId)` -> SqlInstance `(CustomerId, ProjectId, Id)`.
- SqlAssessment project and optional target FKs follow the same pattern. The XOR check allows exactly one target; the populated composite FK must match that target in the same owner scope.
- Each discovery snapshot has composite FKs to both its canonical record and `ImportBatch`.
- New `DiscoveryImportRow.MatchedSqlInstanceId` and `MatchedSqlDatabaseId` relationships use composite FKs with the row's `CustomerId` and `ProjectId`. Existing `MatchedEntityId` remains the Server match and is not made polymorphic.
- Canonical `LastImportBatchId` relationships use `(CustomerId, ProjectId, LastImportBatchId)` and `Restrict` deletion.

Service validation and server-derived ownership remain mandatory; constraints are defence in depth. Before migration generation, the Developer must run a read-only synthetic/dev preflight proving existing Project, Server and ImportBatch ownership columns are internally consistent. Any inconsistency returns to the Architect; it must not be repaired by an unreviewed migration.

### Business uniqueness and query indexes

| Name | Columns / filter | Purpose |
|---|---|---|
| `UX_SqlInstances_Owner_Server_NormalizedName_Active` | Unique `(CustomerId, ProjectId, ServerId, NormalizedInstanceName)` where `IsDeleted = 0` | One active normalized instance name per hosting server and owner scope. |
| `IX_SqlInstances_Owner_Active_Name` | `(CustomerId, ProjectId, IsDeleted, NormalizedInstanceName)` | Bounded inventory/name lookup. |
| `IX_SqlInstances_Owner_Active_ServiceStatus` | `(CustomerId, ProjectId, IsDeleted, ServiceStatus)` | Status filter/dashboard. |
| `UX_SqlDatabases_Owner_Instance_NormalizedName_Active` | Unique `(CustomerId, ProjectId, SqlInstanceId, NormalizedName)` where `IsDeleted = 0` | One active normalized database name per instance and owner scope. |
| `IX_SqlDatabases_Owner_Active_Name` | `(CustomerId, ProjectId, IsDeleted, NormalizedName)` | Bounded inventory/name lookup. |
| `IX_SqlDatabases_Owner_Active_Status` | `(CustomerId, ProjectId, IsDeleted, Status)` | Status filter/dashboard. |
| `UX_SqlAssessments_CurrentInstance` | Unique `(CustomerId, ProjectId, SqlInstanceId)` where `IsDeleted = 0 AND SqlInstanceId IS NOT NULL` | One active assessment per instance. |
| `UX_SqlAssessments_CurrentDatabase` | Unique `(CustomerId, ProjectId, SqlDatabaseId)` where `IsDeleted = 0 AND SqlDatabaseId IS NOT NULL` | One active assessment per database. |
| `IX_SqlAssessments_Owner_Active_Status` | `(CustomerId, ProjectId, IsDeleted, AssessmentStatus, ReadinessStatus)` | Assessment dashboard/filter. |
| `IX_DiscoveryImportRows_Owner_Batch_InstanceName` | `(CustomerId, ProjectId, ImportBatchId, NormalizedInstanceName)` | Deterministic SQL instance preview/matching. |
| `IX_DiscoveryImportRows_Owner_Batch_DatabaseName` | `(CustomerId, ProjectId, ImportBatchId, NormalizedDatabaseName)` | Deterministic SQL database preview/matching. |
| `IX_SqlInstanceSnapshots_Owner_Entity_ImportedAt` | `(CustomerId, ProjectId, SqlInstanceId, ImportedAt DESC)` | Tenant-scoped provenance history. |
| `IX_SqlDatabaseSnapshots_Owner_Entity_ImportedAt` | `(CustomerId, ProjectId, SqlDatabaseId, ImportedAt DESC)` | Tenant-scoped provenance history. |

The new model also defines `CK_SqlInstances_Port` (`Port IS NULL OR Port BETWEEN 1 AND 65535`), `CK_SqlDatabases_SizeMb` (`SizeMb >= 0`), `CK_SqlDatabases_CompatibilityLevel` (`CompatibilityLevel BETWEEN 80 AND 200`), `CK_SqlAssessments_ExactlyOneTarget`, and `CK_SqlAssessments_TargetPlatform` (null or one of the six v1 values). Required strings are not whitespace-only after application normalization.

Normalized identity is Unicode Form C, trimmed, invariant uppercase. Case-insensitive `MSSQLSERVER`, `DEFAULT` and `(DEFAULT)` map to canonical `MSSQLSERVER`; a blank Instance Name is invalid. Display names retain the reviewed spelling. Normalized columns are assigned by domain/service code for deterministic SQL Server/SQLite behaviour; database collation is not the only uniqueness control. Changing a display name recomputes its normalized value in the same transaction.

### Delete behaviour

- API `DELETE` is a logical archive, consistent with HLD DA-05. It sets `IsDeleted`, `DeletedAt`, `DeletedBy` and the concurrency token and writes an audit event; ordinary reads and import matching exclude archived rows.
- Archiving a Server with active SqlInstances, a SqlInstance with active SqlDatabases or an active assessment, or a SqlDatabase with an active assessment returns 409. Dependants must be explicitly dealt with; there is no recursive archive.
- Physical FK behaviour is Server -> SqlInstance `Restrict`, SqlInstance -> SqlDatabase `Restrict`, and SqlInstance/SqlDatabase -> SqlAssessment `Restrict`.
- ImportBatch -> DiscoveryImportRow remains `Cascade` only for uncommitted owned staging according to existing lifecycle rules.
- Audit records and committed source evidence are not cascaded from canonical inventory.
- SqlInstance/SqlDatabase -> discovery snapshots: `Restrict`.
- ImportBatch -> committed SQL snapshots and canonical `LastImportBatchId`: `Restrict`.

No API implements hard delete, restore or bulk cascade deletion of SQL workloads in this increment. Physical deletion is reserved for a separately approved retention/offboarding process. Reusing an archived business key creates a new immutable GUID and retains the old audit/snapshot chain; a future restore capability must detect conflicts and requires a separate work item.

## Tenant isolation and authorisation

- Add EF global `CustomerId` filters to SqlInstance, SqlDatabase, SqlAssessment and both SQL snapshot entities. Canonical filters also exclude `IsDeleted`; audit/history services use explicit, separately authorised history queries rather than request-path `IgnoreQueryFilters`.
- Every scoped query and mutation also requires `ProjectId == currentContext.ProjectId`. The context resolver must first prove that the project belongs to the authenticated customer and that the actor has the required project role; possession of GUIDs is never authorisation.
- Ownership fields, normalized keys, actor names, audit timestamps and import linkage are never accepted from create/update DTOs. They come from authenticated server-side context or trusted server-side processing.
- Relationship lookup starts from the current customer/project and is backed by the composite FKs above. Cross-project or cross-customer parents are treated exactly like missing records and return a non-enumerating 404.
- Lists are paged and bounded; sort fields come from an allow-list; search/filter values are parameterised. No dynamic SQL, raw string interpolation or unbounded materialisation is permitted.
- Import matching starts from the current customer/project and cannot fall back to hostname, instance or database names in another project. No background task may execute without an immutable tenant/project scope captured from the authorised batch.
- Audit events carry current customer/project, actor, correlation ID and UTC timestamp. Raw CSV rows, names, findings, notes, validation values and service-account display values are not emitted to general logs.
- File storage uses generated names and a tenant/project-authorised metadata lookup; cache keys include customer and project. Production Blob storage, malware scanning, retention, private connectivity and managed identity remain outside this local increment and blocked by their own gates.
- API policy separates read, inventory-edit, import-commit and assessment-edit permissions. A future Platform Administrator cross-customer path requires PIM/elevation and audit; it is not introduced here.

The existing `X-Customer-Id`, `X-Project-Id` and `X-User-Name` resolver is permitted only when the host environment is Development or Testing and only with synthetic identities. Production must fail closed unless Entra-derived claims and Q-09-approved authorisation are configured. The feature flag is not an authorisation boundary.

## API contract proposal

All routes are internal to the web application, use JSON DTOs except the multipart upload, execute asynchronously and return RFC Problem Details for errors. The canonical new contract is `/api/v1`. Existing unversioned Phase 1/2 routes remain as backward-compatible aliases to the same controllers/services until a separately approved deprecation; they are not a second security or upload surface.

### Resource routes

- `GET|POST /api/v1/sql-instances`; `GET|PUT|DELETE /api/v1/sql-instances/{id}`.
- `GET|POST /api/v1/sql-databases`; `GET|PUT|DELETE /api/v1/sql-databases/{id}`.
- `GET|POST /api/v1/sql-assessments`; `GET|PUT|DELETE /api/v1/sql-assessments/{id}`.
- `GET /api/v1/sql-instances/{id}/discovery-history` and `GET /api/v1/sql-databases/{id}/discovery-history`, both paged.
- Existing discovery upload, preview, row detail, commit and cancel operations gain the additional route template `/api/v1/discovery/imports`; both route templates invoke the same tenant-authorised implementation.

List endpoints accept `page` (default 1), `pageSize` (default 50, maximum 200), `search` and allow-listed filters. Instance filters are `serverId` and `serviceStatus`; database filters are `sqlInstanceId` and `status`; assessment filters are exactly one optional target ID plus `assessmentStatus` and `readinessStatus`. Default sort is normalized name then immutable ID; the approved sort allow-list is documented in OpenAPI. Every list returns `{ items, page, pageSize, totalCount }` and never returns an unbounded collection.

### Write and response DTOs

- `SqlInstanceWriteV1`: `serverId`, `instanceName`, `sqlVersion`, `edition`, `port`, `serviceStatus`, optional `serviceAccountName`. Manual creation sets provenance to `Manual`; clients cannot set discovery/import timestamps or source linkage.
- `SqlDatabaseWriteV1`: `sqlInstanceId`, `name`, `sizeMb`, `compatibilityLevel`, `recoveryModel`, optional `collation`, `status`.
- `SqlAssessmentWriteV1`: exactly one of `sqlInstanceId`/`sqlDatabaseId`, `assessmentStatus`, `readinessStatus`, optional `targetPlatform`, optional `targetSqlVersion`, optional `migrationApproach`, `blockers`, `findings`, `notes`, optional `assessedAt`. The service applies the workflow rules above.
- Read DTOs add immutable `id`, named parent references, provenance (`lastImportBatchId`, `lastImportedAt`, `lastDiscoveredAt` where applicable), created/updated actor and UTC time, and an opaque `version`. They do not expose archived rows on ordinary endpoints.
- No write DTO accepts `CustomerId`, `ProjectId`, normalized keys, `IsDeleted`, audit actor, audit timestamps, import batch IDs, snapshot IDs or `RowVersion` bytes.

Discovery-managed technical fields remain manually correctable through authorised CRUD. A later discovery commit may update those fields only after preview. Moving an instance to another Server or a database to another instance is an explicit same-project human relationship change; CSV matching does not infer a move from names because the contracts contain no immutable external workload ID.

### Concurrency, idempotency and response semantics

- Detail and create/update responses include an `ETag` derived from the opaque `rowversion`. `PUT` and `DELETE` require `If-Match`; missing preconditions return 428 and stale versions return 412 without mutation.
- Discovery batch detail/preview uses an ETag backed by an additive `ImportBatch.RowVersion`. Commit additionally requires a caller-generated `Idempotency-Key`; repeat delivery returns the already completed result or a conflict, never a second application.
- `POST` returns 201 with `Location` and `ETag`; successful `PUT` returns 200 with the updated DTO/ETag; logical `DELETE` returns 204. Preview/commit return 200 with the batch summary. No endpoint returns raw EF entities.
- Invalid syntax/field/state returns 400; authentication failure 401; insufficient role 403; missing or inaccessible records 404; business uniqueness/dependent conflicts 409; missing/stale preconditions 428/412; oversized upload 413; unsupported media/contract 415/422; and unexpected failures 500 with no internal detail.
- Problem Details include stable `type`, `title`, `status`, safe `detail`, `instance`, `errorCode`, `correlationId` and field errors where applicable. They never reveal another tenant/project, SQL object existence, raw source values, stack traces or SQL/provider text.

The API must be described by generated OpenAPI and locked by approval tests. It remains an internal API; this work item does not approve external publication.

## SQL discovery source contract

Only synthetic UTF-8 comma-separated `.csv` fixtures are approved for development/test. Macros, spreadsheets, archives and executable content are not supported. Selection of the source type is explicit; content is never used to auto-authorise a source or tenant.

The Phase 3 local POC envelope is a `.csv` file of at most 25 MiB and 50,000 data rows, with one header row and at most 64 columns. UTF-8 with or without BOM, CRLF or LF, RFC-style quoted fields, embedded commas, escaped quotes and quoted line breaks are accepted. Invalid UTF-8, NUL characters, unclosed quotes, more values than headers, duplicate normalized headers, empty files and limit violations reject the file before canonical processing. MIME type is advisory because CSV has no reliable magic signature; the `.csv` extension, strict decoding, parser rules and selected contract are authoritative. The original filename is display metadata only; storage uses a generated identifier.

### Contract identifiers

- `SqlInstanceCsv/v1`
- `SqlDatabaseCsv/v1`

The multipart `sourceType` is exactly the full versioned identifier, so no unversioned default can drift. Column order is irrelevant. Unknown columns are retained in raw staging evidence and generate one batch warning; they are not mapped without an approved contract change. Raw staging is displayed as encoded text and is never emitted directly into HTML, logs, commands or exports.

### SQL Instance source

| Column | Required header | Required value | Validation / normalization |
|---|---:|---:|---|
| Server | Yes | Yes | Trim; resolve against normalized Server hostname in current customer/project. |
| Instance Name | Yes | Yes | Trim, Unicode Form C, max 128; invariant-uppercase matching; default aliases normalize to `MSSQLSERVER`. |
| SQL Version | Yes | Yes | Trim, max 100. |
| Edition | Yes | Yes | Trim, max 100. |
| Port | Yes | No | Blank is null; otherwise whole number 1-65535. |
| Service Status | Yes | Yes | Trim and normalize approved aliases to `Running`, `Stopped`, `Paused`, `Disabled` or `Unknown`. |
| Discovery Source | Yes | Yes | Trim, max 100; data/provenance only, never executed. |
| Last Discovered At | Yes | No | Blank is null; otherwise ISO-8601 timestamp with offset, converted to UTC. |

Instance matching is exactly `CustomerId + ServerId + NormalizedInstanceName`, after resolving `Server` in the current project. An unmatched or ambiguous server is a Reject. A cross-project/cross-customer record is a non-enumerating Reject.

Service status aliases are case-insensitive after trimming: `Started` and `Online` map to `Running`; `Offline` maps to `Stopped`; the five canonical values map to themselves. A different safe printable value maps to `Unknown` with a warning; control characters or over-length values reject. Default-instance aliases are the three values defined in the key section.

### SQL Database source

| Column | Required header | Required value | Validation / normalization |
|---|---:|---:|---|
| Server | Yes | Yes | Trim; resolve only in current customer/project. |
| Instance Name | Yes | Yes | Resolve using the SQL Instance normalization rule. |
| Database Name | Yes | Yes | Trim, Unicode Form C, max 128; invariant-uppercase matching. |
| Size MB | Yes | Yes | Invariant-culture non-negative whole number within `Int64`. |
| Compatibility Level | Yes | Yes | Whole number in the architect-approved supported range; v1 accepts 80-200 for forward-compatible capture. |
| Recovery Model | Yes | Yes | Normalize to `Simple`, `Full` or `BulkLogged`. |
| Collation | Yes | No | Trim, max 128; blank remains null. |
| Status | Yes | Yes | Normalize approved aliases; unsupported but safe values become `Unknown` with a warning and raw value retained. |

Database matching is exactly `CustomerId + SqlInstanceId + NormalizedDatabaseName`, after resolving Server and SQL Instance in the current project. An unmatched or ambiguous parent is a Reject.

Recovery model aliases are case-insensitive `Simple`, `Full`, `BulkLogged`, `Bulk Logged` and `Bulk-Logged`, normalized to the first three canonical values. Database status canonical values are `Online`, `Offline`, `Restoring`, `Recovering`, `RecoveryPending`, `Suspect`, `Emergency`, `Standby` and `Unknown`; whitespace, underscore and hyphen variants of those labels normalize to the canonical value. A different safe printable value becomes `Unknown` with a warning; control characters or over-length values reject.

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
- Formula-like prefixes (`=`, `+`, `-`, `@`, tab or carriage return after leading whitespace) are never evaluated. Raw staging retains source evidence, UI rendering encodes it, and any later CSV/Excel export must neutralise it before output; raw staging is never exported verbatim.

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
- Absence from a file never archives or deletes a canonical record. Import ignores archived canonical rows and never restores them; a safe row that matches only archived history creates a new immutable record after the user sees the Create classification.

| Ownership class | Fields | Import behaviour | Human/API behaviour |
|---|---|---|---|
| Server-derived | `CustomerId`, `ProjectId`, actor, correlation ID | Never read from CSV. | Never accepted in a DTO. |
| System-derived | IDs, normalized names, `LastImportBatchId`, `LastImportedAt`, created/updated/deleted metadata, `RowVersion` | Calculated/set by the service in the commit transaction. | Read-only to clients. |
| Instance discovery-managed | `ServerId`, `InstanceName`, `SqlVersion`, `Edition`, `Port`, `ServiceStatus`, `DiscoverySource`, `LastDiscoveredAt` | Supplied non-blank values may create/update after preview; relationship is resolved inside current project. | Authorised users may create/correct; changes are audited and may be superseded by a later reviewed import. |
| Database discovery-managed | `SqlInstanceId`, `Name`, `SizeMb`, `CompatibilityLevel`, `RecoveryModel`, `Collation`, `Status` | Supplied values may create/update after preview; parent is resolved inside current project. Blank optional Collation does not clear. | Authorised users may create/correct; changes are audited and may be superseded by a later reviewed import. |
| Human-managed/protected | `ServiceAccountName`; all SqlAssessment status, readiness, target, approach, blockers, findings, notes and assessed time; approval/governance state | Never mapped, cleared or overwritten by either v1 contract. | Changed only by an authorised human workflow with concurrency control and audit. |

Because v1 has no stable external identifier for an instance or database, discovery does not infer parent moves. A row under a different Server/Instance is a different business key and previews as Create. A human may re-parent only within the same project, subject to duplicate/dependent checks and an explicit relationship-change audit event.

### Reuse of Phase 2 staging

Extend `ImportBatch`, source resolver, parser and orchestration. Add SQL Server `rowversion` concurrency to `ImportBatch`. Extend `DiscoveryImportRow` additively with:

- `NormalizedInstanceName string(128)?`
- `NormalizedDatabaseName string(128)?`
- `MatchedSqlInstanceId Guid?`
- `MatchedSqlDatabaseId Guid?`

Keep existing `MatchedEntityId` as the Server match for existing Phase 2 behaviour and for the SQL row's resolved Server. For `SqlInstanceCsv/v1`, `MatchedSqlInstanceId` is the existing canonical instance match and `MatchedSqlDatabaseId` is null. For `SqlDatabaseCsv/v1`, `MatchedSqlInstanceId` is the resolved parent and `MatchedSqlDatabaseId` is the existing canonical database match when present. Add the composite FKs described above; do not remove the Server FK or turn one GUID into a polymorphic reference. Source-type validation permits only the match shape appropriate to that row. Existing server imports and history remain backward compatible.

## Security, privacy, audit and observability

### Trust boundaries and data handling

- Browser input, route/query IDs, headers, CSV metadata and file content are untrusted. Controllers bind allow-listed DTOs; services establish authenticated customer/project scope, validate role and business rules, and then use parameterised EF queries. No SQL, PowerShell, shell, macro, formula, DMS, Azure SDK or migration-executor path exists.
- SQL names, versions, infrastructure facts, assessments, findings and source rows are customer-confidential. Retain only approved fields; development/test use synthetic data. HTML output is encoded and no raw staging value is inserted as markup.
- The import boundary enforces authenticated permission, generated storage name, configured size/row/column limits, strict UTF-8/CSV parsing, source-contract selection, duplicate detection, validation, preview and explicit commit. Unsupported file types never reach a parser.
- `ServiceAccountName` is metadata, not an authentication secret. The API/UI rejects credential-like content, provides no password/token/key/connection-string field, does not log the submitted value, and audits only that the property changed with redacted old/new values.
- General telemetry contains correlation ID, opaque entity/batch/row IDs, counts, classifications, duration and safe outcome only. It excludes raw rows, original values, server/instance/database names, findings, blockers, notes, filenames and audit old/new content.
- Existing local file storage and development headers are development/test only. Production Blob quarantine/promotion, Defender scanning, managed identity, Key Vault, private endpoints, retention and Entra claims require their separate approved designs; this package does not claim those controls exist.
- No cache is required for PH3-SQL-001. If later introduced, its key must contain customer and project, its value must not be shared across scopes, and eviction must follow archive/commit changes.

### Audit and discovery history contract

- `AuditEvent` remains the append-only, tenant-filtered significant-change log. Add optional `CorrelationId string(100)` and index `(CustomerId, ProjectId, ChangedAt DESC)`; Phase 3 events always carry non-null ProjectId, actor and UTC time.
- Event actions cover `SqlInstanceCreated`, `SqlInstanceUpdated`, `SqlInstanceRelationshipChanged`, `SqlInstanceArchived`, the corresponding SqlDatabase actions, `SqlAssessmentCreated`, `SqlAssessmentUpdated`, `SqlAssessmentArchived`, `SqlDiscoveryImportCommitted` and field-level discovery changes.
- Manual and discovery changes record entity type/id, action and field-level old/new values. Assessment narrative old/new content remains inside tenant-authorised audit storage and never enters general logs. `ServiceAccountName` old/new values are replaced with `[REDACTED]`.
- An Unchanged discovery row creates a typed snapshot but no field-change audit noise. Every successful batch receives one commit summary event with counts and batch ID. Reject/Warning evidence stays with the batch/row; rejected rows never create canonical history.
- SQL snapshots are immutable typed source history linked by composite owner-safe FKs to canonical entity and batch. Staging raw JSON remains source evidence subject to the eventual retention decision; it is not the canonical model.
- Application services expose no update/delete operation for audit events or snapshots. Production database permissions must deny application-role UPDATE/DELETE on append-only tables, but that control is a later deployment/security approval. Physical cleanup occurs only through an approved retention/offboarding process.

### Observability

- Metrics cover upload, preview and commit success/failure/duration; row classifications; API latency/error rate; optimistic concurrency conflicts; and bounded query duration without customer-data labels.
- Security signals include repeated authorisation failures, cross-scope relationship attempts, malicious/oversized files and credential-like metadata attempts. Alert routing and retention require Information Security/Service Transition approval before production.

## Performance and supportability

- List endpoints default to 50 and cap at 200 rows.
- Preview/history/row endpoints are paged; local POC import uses the current 25 MiB upper bound plus the 50,000-row and 64-column contract limits.
- Load only current-batch parents needed for matching into normalized dictionaries; no per-row parent query/N+1 pattern.
- Use no-tracking DTO projections for read-only lists; do not return entity graphs or use lazy loading.
- Validate with at least 200 mixed assets and document query/import timings and SQL Server query plans for list, parent resolution, uniqueness and history access. HLD's 50 MB/50,000-row asynchronous target is not baselined by this local synchronous POC and requires capacity/test approval before production.
- Use central value constants, dedicated services and source-specific tests; do not expand the general `ProgrammeService` indefinitely if the SQL module has coherent boundaries.

## Compatibility, migration, deployment and rollback

The repository baseline contains `20260823111854_InitialCreate` and `20260824181918_AddDiscoveryImport`. After approval, create one reviewed additive migration, provisionally `AddSqlDiscoveryAssessment`; do not edit, squash or re-baseline those migrations.

The new migration may contain only:

1. alternate keys on Project `(CustomerId, Id)`, Server `(CustomerId, ProjectId, Id)` and ImportBatch `(CustomerId, ProjectId, Id)` after a read-only ownership preflight;
2. additive `ImportBatch.RowVersion` and nullable `AuditEvent.CorrelationId`;
3. nullable SQL staging/match columns and their owner-leading indexes/composite FKs;
4. the SqlInstance, SqlDatabase and SqlAssessment tables with immutable GUID PKs, ownership columns, logical-delete/audit/concurrency fields, check constraints, composite FKs and filtered business/current indexes; and
5. the two typed append-only snapshot tables with composite canonical/batch FKs and history indexes.

It must not drop/rename a table or column, rewrite existing migration history, backfill customer facts from names, change existing Phase 1/2 source types, add production seed/customer data, introduce a catalogue/customer database, or weaken an existing constraint/filter. The database-per-customer transition is a separate architecture and migration work item.

Before hand-off, the Developer must inspect the generated migration and SQL Server idempotent script, confirm provider-specific filtered-index and `rowversion` SQL, apply Up to a new isolated synthetic SQL Server database and to a copy at the current baseline migration, verify all constraints/indexes, run `has-pending-model-changes`, and rehearse the permitted development-only Down path against an explicitly verified disposable database. No application startup path auto-applies production migrations.

Deployment ordering is expand-first: apply and verify the additive schema, deploy the backward-compatible application with `SqlDiscoveryAssessment` default off, run tenant/constraint/smoke checks, then enable only in the authorised environment. The flag controls exposure, not authorisation.

Operational rollback is data-preserving: disable the flag, roll the application back to the preceding compatible build, and leave additive tables/columns and committed audit/snapshot data intact for a reviewed forward fix. Do not run Down in production. If a production schema/data restore is ever required, a named human change/release authority must approve a database-specific backup/restore plan; agents cannot invoke it. A failed commit transaction rolls back its canonical/snapshot/audit changes and preserves a safe failed-batch record according to the existing lifecycle.

Bicep requires no PH3-SQL-001 change because no Azure resource is introduced. Production schema deployment, tenancy transition and Azure deployment remain out of scope.

## Proposed test approach

### API and domain

- xUnit unit tests for normalization, validation, field ownership, relationship moves, logical-delete rules, reconciliation and domain value/state rules.
- Existing in-memory SQLite `WebApplicationFactory` tests for fast HTTP, DTO, customer/project and regression coverage. SQLite evidence is supplementary and must not claim SQL Server provider assurance.
- A mandatory SQL Server integration lane using SQL Server Express in an approved developer/test environment or an ephemeral SQL Server service/container in CI. Each run uses a uniquely named isolated synthetic database, migrates both empty and existing-baseline cases, tests composite FKs, check constraints, filtered indexes, collation-independent normalization, `rowversion`, concurrent uniqueness, transaction rollback and idempotent commit, and cleans up only its pre-validated test database.
- Contract tests lock OpenAPI route/version, DTO, paging, ETag/precondition, Problem Details and status-code behaviour.
- Never point tests at production or customer databases. A missing SQL Server endpoint is an environment blocker, not evidence of a product pass or defect.

### Frontend

- ESLint and `next build` remain mandatory static/build gates.
- Add Vitest with React Testing Library and user-event for component/page state, forms, accessible names, validation, loading/empty/error behaviour and API mocking.
- Add Playwright for critical browser journeys: tenant/project context, SQL list/detail/CRUD, import preview/commit and assessment. Run against a synthetic isolated test API/database.
- Include automated accessibility checks in critical views where the approved toolchain permits; complete keyboard/manual checks in independent testing.
- Verify the supported Next.js 16 browser baseline and Node.js runtime in CI; lock the exact dependency tree and scan licences/vulnerabilities.

This is the architecture/tester recommendation. I-06 closes only when Agilisys Test Services or the named test authority records agreement, environments and entry/exit criteria.

## Required independent test conditions

The Tester must prove:

- SQL Instance and Database positive/negative CRUD and safe errors;
- unique normalized business keys, including concurrent create/commit on SQL Server;
- same-tenant/project Server -> Instance -> Database relationships and cross-tenant/project direct-object rejection;
- logical archive, restricted parent/dependent behaviour, active-key reuse and append-only history;
- assessment XOR target constraint, status/target workflow, allowed target platforms, optimistic concurrency and protected fields;
- both CSV contracts, all-required-header/optional-value distinction, aliases, header/row normalization, warning/reject policy, 25 MiB/50,000-row/64-column boundaries and malicious/oversized/malformed inputs;
- deterministic Create/Update/Unchanged preview and transactional reconciliation;
- stale-preview/repeat-commit/idempotency protection, typed snapshots and audit evidence;
- versioned routes plus legacy alias equivalence, bounded API queries, DTO boundaries, non-enumerating errors and Phase 1/2 regression;
- frontend component/browser/a11y behaviour plus lint/build; and
- the absence of DMS, migration execution, AI recommendation, remediation and Azure provisioning paths.

## Acceptance-criteria architecture and test traceability

| Acceptance criterion | Architecture control | Required evidence |
|---|---|---|
| SQL-AC-001 | Versioned DTO APIs, same-owner relationships, logical archive, Problem Details and ETag preconditions. | CRUD, validation, dependency conflict and concurrency contract/integration tests. |
| SQL-AC-002 | Composite owner FKs, active normalized unique indexes and deterministic normalization. | SQL Server FK/unique/concurrency tests plus cross-project direct-object tests. |
| SQL-AC-003 | Existing governed upload surface, versioned source identifiers and preview-before-commit. | Positive contract upload/preview test proving no canonical mutation. |
| SQL-AC-004 | Explicit header/value/range/alias/duplicate/parent rules and row evidence. | Negative/boundary fixture matrix with deterministic Warning/Reject outcomes. |
| SQL-AC-005 | Idempotent match keys, blank-does-not-clear policy and protected-field matrix. | Re-import tests and byte-for-byte protected-field assertions. |
| SQL-AC-006 | Assessment XOR model, controlled states/targets and human-only write DTO. | Instance/database assessment workflow, validation, ETag and audit tests. |
| SQL-AC-007 | Six-value target constraint with no executor/provisioner mapping. | Allowed/rejected value tests and repository/behavioural absence checks. |
| SQL-AC-008 | Server-derived customer/project scope, composite FKs, query filters and non-enumerating errors. | Horizontal/vertical access tests for list/detail/write/import/history/assessment and relationship IDs. |
| SQL-AC-009 | Append-only AuditEvent contract plus typed snapshots and actor/UTC metadata. | Significant-change, field-change, archive and commit-summary audit assertions. |
| SQL-AC-010 | Next.js module using the internal v1 API with accessible states and controls. | Lint/build, component, Playwright, keyboard and accessibility evidence. |
| SQL-AC-011 | Bounded queries, owner-leading indexes and no N+1 parent resolution. | Synthetic 200+ mixed-asset run with timings/query plans and leakage checks. |
| SQL-AC-012 | Additive schema/routes and preserved Phase 1/2 aliases/behaviour. | Same-commit full regression, migration and frontend gates. |
| SQL-AC-013 | Versioned contracts, synthetic fixtures, migration/rollback rules and this matrix. | Reviewed artefact inventory and linked Implementation Work Package. |
| SQL-AC-014 | Immutable product boundary: records/plans/evidence only. | Repository search plus behavioural tests proving no execution, DMS, AI, remediation or Azure deployment path. |
| SQL-AC-015 | Typed append-only snapshots and protected/validated service-account display metadata. | Safe-row snapshot tests, Unchanged snapshot test, credential-like rejection and no-log assertions. |

## Human decisions and approvals required

The existing Product Owner approval permits only the stated local POC scope. It is recorded as evidence but does not approve this architecture. The exact next decisions are:

1. **Solution Architect/TDA:** accept, condition or reject ADR-006 and explicitly close or retain Q-01/HLD OD-07 for the named PH3-SQL-001 scope.
2. **Solution Architect/TDA and Information Security:** jointly accept, condition or reject ADR-007, including the shared non-production baseline, mandatory isolation controls and the disposition of HLD DD-05/ADR-001. No shared production processing is implied.
3. **Named Product Owner, human Architect and DBA/Discovery SME:** approve the two v1 CSV contracts, controlled assessment values and synthetic fixture set. Information Security must additionally approve any later `ServiceAccountName` source-contract amendment.
4. **Agilisys Test Services or named test authority:** approve the SQL Server/frontend tools, isolated environment, synthetic data, entry/exit criteria and the division between SQLite fast tests and mandatory SQL Server evidence (I-06/D-11).
5. **PRB:** approve scope investment/phasing before a committed delivery/release baseline or expenditure outside the limited local POC authority is asserted (D-01/Q-02).
6. **Before production only:** Data Protection/DPO decides Q-06 and retention; Solution Architect/Information Security closes Q-09 for external identity; Managed Services/Service Transition approves support/operability; human release authority approves deployment. None is claimed here.

Each approval must record decision, named person/role, date, exact scope, conditions and durable evidence. ADR-006 and ADR-007 remain Proposed until their own required evidence is added.

## Hand-off

```yaml
handoff:
  from_agent: "architect"
  to_agent: "architect"
  human_reviewers: ["Solution Architect / TDA", "Information Security"]
  state: "READY_FOR_ARCHITECTURE_APPROVAL"
  work_item: "PH3-SQL-001"
  branch: "feature/ph3-sql-architecture"
  commit: null
  baseline_commit: "579171c927905876640cdf6bcb48ee8261b6c301"
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
    open_questions: ["Q-01", "Q-02", "Q-06", "Q-09"]
  artefacts:
    - "docs/product/Phase3_SQL_Discovery_Assessment_Work_Item.md"
    - "docs/product/PH3_SQL_Approval_Pack.md"
    - "docs/architecture/Phase3_SQL_Discovery_Assessment_Architecture.md"
    - "docs/architecture/ADR-006-application-technology-stack.md"
    - "docs/architecture/ADR-007-phase3-tenancy-alignment.md"
  evidence:
    - "Product Specification V0.1 and HLD V0.1 complete structural review; HLD approval/readiness fields contain no completed approval evidence."
    - "GitHub PR #1 Product Owner approval record and merge commit 579171c927905876640cdf6bcb48ee8261b6c301."
    - "Baseline repository application, persistence, migrations, import implementation, tests and package-lock inspection."
    - "Primary vendor lifecycle evidence linked from ADR-006."
  decisions:
    - "Proposed application stack recorded in ADR-006; approval pending."
    - "Proposed two-horizon tenancy alignment recorded in ADR-007; approval pending."
    - "Proposed domain, relationship, key/index, API, CSV, ownership, audit, migration, rollback and test contracts recorded in PH3-SQL-ARCH-001; approval pending."
  assumptions:
    - "Only synthetic CSV data is used."
    - "No PH3-SQL-001 implementation, migration or database change occurs in this architecture run."
  risks: ["R-01", "R-02", "R-03", "R-06", "R-09", "R-11"]
  defects: []
  blockers:
    - "Q-01/OD-07 and ADR-006 TDA approval evidence missing."
    - "ADR-001 versus HLD DD-05 requires TDA/Information Security decision."
    - "Versioned CSV contracts, controlled assessment values and synthetic fixtures require named Product Owner/human Architect/DBA approval."
    - "I-06 frontend and SQL Server test approach requires test-authority agreement."
    - "PRB investment/phasing approval remains absent for any committed delivery or release baseline beyond the limited local POC authority."
  approvals:
    - "Product Owner JP (opathre), 8 September 2026: local POC implementation only, subject to PR #1 restrictions."
  requested_action: "Named Solution Architect/TDA and Information Security reviewers must review PH3-SQL-ARCH-001, ADR-006 and ADR-007 and record accept/reject/conditions with names, roles, date, scope and durable evidence; do not hand off to the Developer until the applicable approvals are recorded and this package is reissued as READY_FOR_DEVELOPMENT."
```
