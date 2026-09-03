# PH3-SQL-001 Phase 3 Approval Pack

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

**Work item:** PH3-SQL-001  
**Current quality gate:** `PHASE 3 BLOCKED`  
**Purpose:** Present the existing Phase 3 scope, proposed decisions, source contracts and test approach for named human approval. This pack records no approval and authorises no implementation.

## A. Product Owner / PRB approval

### Business objective

Provide a governed, tenant-isolated record of discovered Microsoft SQL Server instances and databases, their hosting relationships, and human-reviewed assessment and migration-planning decisions. The capability must improve inventory quality and readiness evidence without moving data, executing migration or provisioning Azure resources.

### Phase 3 scope

- Paged, filterable SQL Instance and SQL Database inventory linked to existing same-project Servers.
- Separate versioned SQL Instance and SQL Database CSV upload, validation, preview, explicit commit, reconciliation and append-only discovery history.
- Human-managed instance/database assessment, readiness, findings, blockers, target platform/version, migration approach and notes.
- Tenant/project-authorised REST APIs and browser journeys with safe errors, audit evidence, bounded queries and synthetic 200+ asset assurance.
- Preservation of protected business fields and existing Phase 1/2 behaviour.

### Out of scope

- Database migration or data movement; Azure Database Migration Service orchestration.
- SSIS, SSRS or linked-server discovery, assessment or migration.
- AI recommendations, autonomous decisions, remediation or script execution.
- Azure provisioning, production deployment, direct discovery APIs or multi-cloud targets.
- A Phase 3 tenancy refactor or approval of a production tenancy topology.

### Acceptance criteria summary

| ID | Approval intent |
|---|---|
| SQL-AC-001 | Authorised CRUD and bounded list/filter for SQL Instances and Databases, with Problem Details and no partial invalid change. |
| SQL-AC-002 | Same-project Server-to-Instance-to-Database relationships; reject cross-tenant/project links and duplicate normalised names. |
| SQL-AC-003 | Approved synthetic CSVs upload and preview without canonical mutation before explicit commit. |
| SQL-AC-004 | Deterministic Create/Update/Unchanged results and row/field evidence for warnings or rejects. |
| SQL-AC-005 | Idempotent re-import and byte-for-byte preservation of protected human-managed fields. |
| SQL-AC-006 | DBA-managed instance/database assessment, readiness, target, approach, blockers, findings, notes and assessed time. |
| SQL-AC-007 | Only six approved target outcomes; none initiates migration, remediation, DMS or Azure creation. |
| SQL-AC-008 | Every SQL API/import/assessment/history path proves customer/project isolation and resists direct-object enumeration. |
| SQL-AC-009 | Significant inventory, relationship, import and assessment changes produce tenant-scoped actor/UTC audit evidence. |
| SQL-AC-010 | Accessible browser journeys cover navigation plus loading, empty, error, CRUD, import and assessment states. |
| SQL-AC-011 | Synthetic 200+ total-asset evidence proves bounded/paged behaviour without leakage or redesign. |
| SQL-AC-012 | Existing Phase 1/2 API, import, isolation, build and frontend gates remain green on the same commit. |
| SQL-AC-013 | Approved contracts/fixtures plus implementation, rollback and requirements-to-test evidence are stored with the work item. |
| SQL-AC-014 | Search and tests prove no database-execution, DMS, AI, remediation or production-deployment path was added. |
| SQL-AC-015 | Safe committed rows create append-only scoped history; only separately approved non-sensitive service-account metadata is allowed, and credential-like data is rejected and never logged. |

### Key risks

- R-01/I-03: variable formats and ambiguous names can create incorrect relationships.
- R-02: incomplete tenant constraints could expose sensitive infrastructure metadata.
- R-03: incomplete DBA/SME input can make readiness or target decisions unreliable.
- R-06: scope could expand into execution, automation, SSIS or SSRS.
- R-09/I-06: SQLite-only evidence can miss SQL Server constraint, collation, migration and concurrency defects.
- R-11/I-08: unapproved or drifting framework choices can undermine supportability and reproducibility.

### Dependencies

- D-01 Product Owner/PRB scope, investment and phasing approval.
- Solution Architect/TDA approval of ADR-006 and closure of Q-01/HLD OD-07.
- TDA/Information Security approval of ADR-007 for the non-production increment, with production tenancy separately governed.
- Product Owner, Architect and DBA/Discovery SME approval of both CSV v1 contracts and synthetic fixtures.
- Test-authority agreement for frontend and SQL Server tools, environments and entry/exit criteria.
- Green same-commit baseline evidence, or a documented environment-only restore blocker that is resolved before implementation evidence is accepted.

### Approval template

```text
Decision: APPROVED / APPROVED WITH CONDITIONS / REJECTED
Approver:
Role:
Date:
Conditions:
Evidence link:
```

## B. Architecture / TDA approval

ADR-006 proposes the existing repository stack as the Phase 3 baseline:

- Backend: .NET 10, ASP.NET Core and EF Core 10.
- Persistence: SQL Server verification with SQL Server/Azure SQL-compatible schema and SQL.
- Frontend: Next.js 16 App Router, React 19 and TypeScript.
- Application shape: modular monolith with DTO-based REST APIs.
- No microservices, messaging, Azure provisioning or production deployment are authorised by this decision.

ADR-006 remains `Proposed` until the Solution Architect/TDA records a named, dated decision and durable evidence that closes Q-01/HLD OD-07 for the approved scope.

### ADR-006 approval template

```text
Decision: ACCEPTED / ACCEPTED WITH CONDITIONS / REJECTED
Approver:
Role: Solution Architect / TDA
Date:
Approved scope:
Conditions:
Q-01 / HLD OD-07 disposition:
Evidence link:
```

## C. Tenancy / Information Security approval

ADR-007 proposes retaining the current shared database/shared schema only for Phase 3 development and non-production. Every SQL inventory, assessment, staging, snapshot, audit and relationship record must be isolated by server-derived `CustomerId` and authorised `ProjectId`, with query filters, explicit project predicates, same-tenant relationship checks and database constraints.

This proposal does not approve production customer processing. The HLD database-per-customer production position remains separately governed; TDA must decide whether it remains the production target or is superseded through an approved architecture, security, recovery and offboarding process.

### ADR-007 approval template

```text
Decision: ACCEPTED / ACCEPTED WITH CONDITIONS / REJECTED
Solution Architect / TDA approver:
Information Security approver:
Date:
Approved scope: Phase 3 development/non-production shared database/shared schema
CustomerId + ProjectId isolation conditions:
Production tenancy disposition: SEPARATELY GOVERNED / other authorised decision
HLD DD-05 / ADR-001 disposition:
Conditions:
Evidence link:
```

## D. SQL source contract approval

Only synthetic UTF-8 comma-separated `.csv` fixtures are proposed for development/test. The user explicitly selects the source type; macros, spreadsheets, archives, executable content and customer data are excluded.

### `SqlInstanceCsv/v1`

All eight headers are required. Required row values are Server, Instance Name, SQL Version, Edition, Service Status and Discovery Source; Port and Last Discovered At may be blank.

| Column | Required value | Rule summary |
|---|---:|---|
| Server | Yes | Match the normalised Server hostname in the current customer/project. |
| Instance Name | Yes | Trim, Unicode Form C, max 128, invariant-uppercase match; default aliases normalise to `MSSQLSERVER`. |
| SQL Version | Yes | Trim; max 100. |
| Edition | Yes | Trim; max 100. |
| Port | No | If supplied, whole number 1-65535. |
| Service Status | Yes | Normalise approved aliases to Running, Stopped, Paused, Disabled or Unknown. |
| Discovery Source | Yes | Trim; max 100; provenance only and never executed. |
| Last Discovered At | No | ISO-8601 with offset; convert to UTC. |

Matching key: `CustomerId + ServerId + NormalizedInstanceName` after resolving Server within the current project.

### `SqlDatabaseCsv/v1`

All eight headers are required. Every row value except Collation is required; Collation may be blank.

| Column | Required value | Rule summary |
|---|---:|---|
| Server | Yes | Resolve only within the current customer/project. |
| Instance Name | Yes | Resolve with the SQL Instance normalisation rule. |
| Database Name | Yes | Trim, Unicode Form C, max 128, invariant-uppercase match. |
| Size MB | Yes | Non-negative invariant-culture whole number within `Int64`. |
| Compatibility Level | Yes | Whole number; v1 range 80-200. |
| Recovery Model | Yes | Normalise to Simple, Full or BulkLogged. |
| Collation | No | Trim; max 128; blank is null. |
| Status | Yes | Normalise approved aliases; safe unsupported values become Unknown with a warning. |

Matching key: `CustomerId + SqlInstanceId + NormalizedDatabaseName` after resolving Server and SQL Instance within the current project.

### Warning, reject and protected-field rules

- Warnings: unknown extra columns, safe status aliases mapped to Unknown, valid values outside recognised display vocabulary and repeat-file hashes. Warnings may commit only when identity and relationships remain safe.
- Rejects: missing required headers/values; duplicate normalised headers or business keys; unmatched, ambiguous or cross-project parents; invalid CSV/UTF-8; invalid/out-of-range technical values; over-length values; or source/contract mismatch. Every duplicate occurrence is rejected; reject rows never change canonical data.
- Matching never uses partial names, IP addresses or cross-project records. Fully qualified `Server\\Instance` content in Instance Name is rejected instead of split automatically.
- Protected from discovery: assessment/readiness state, target platform/version, migration approach, blockers, findings, notes and approval/governance state. Blank optional source values do not clear canonical fields.
- `ServiceAccountName` is excluded from CSV v1 and remains protected. A future amendment requires Product Owner, DBA and Information Security approval; credential-like content always rejects and is never logged.
- Development and automated-test fixtures must contain synthetic or properly anonymised data only; these proposed approvals cover synthetic data only.

### Product Owner approval

```text
Decision: APPROVED / APPROVED WITH CONDITIONS / REJECTED
Approver:
Role: Product Owner
Date:
Contracts/fixtures reviewed:
Conditions:
Evidence link:
```

### Architect approval

```text
Decision: APPROVED / APPROVED WITH CONDITIONS / REJECTED
Approver:
Role: Solution Architect / Architect
Date:
Contracts/fixtures reviewed:
Conditions:
Evidence link:
```

### DBA / Discovery SME approval

```text
Decision: APPROVED / APPROVED WITH CONDITIONS / REJECTED
Approver:
Role: DBA / Discovery SME
Date:
Contracts/fixtures reviewed:
Conditions:
Evidence link:
```

## E. Test authority approval

### Proposed backend approach

- xUnit for domain, validation, reconciliation and service tests.
- SQLite `WebApplicationFactory` integration tests for fast API, DTO, tenant/project and regression feedback.
- A separate SQL Server-specific integration lane using an approved isolated synthetic database to prove provider-specific constraints, collation, concurrency, transactions and migration behaviour.

### Proposed frontend approach

- Mandatory `npm` lint and production build gates.
- Vitest, React Testing Library and user-event for components, page states, forms, accessible names, validation and API mocking.
- Playwright for critical tenant/project, inventory, CRUD, import preview/commit and assessment browser journeys.
- Automated accessibility checks where supported, plus independent keyboard/manual checks.

No test may use production credentials, production/customer data or a production database.

### Test-authority approval template

```text
Decision: APPROVED / APPROVED WITH CONDITIONS / REJECTED
Test authority:
Environment:
Tools:
Entry criteria:
Exit criteria:
Date:
Conditions:
Evidence link:
```

## Baseline retry evidence

**Evidence recorded:** 2026-09-03T20:24:07Z  
**Branch:** `feature/sql-discovery-assessment`  
**Commit:** `1ab5b62ca454a45931c886717b085323ea0e6673`  
**Change context:** The working-tree changes covered by this pack are documentation-only.

### .NET baseline

- SDK: .NET SDK `10.0.400`.
- Command: `dotnet restore .\LgrTransformationMigration.sln`.
- Result: **FAILED - ENVIRONMENT-ONLY RESTORE BLOCKER**.
- Configured feed: enabled `nuget.org` at `https://api.nuget.org/v3/index.json`; no repository NuGet configuration or package lock file was found.
- Affected projects: `src/api/LgrTransformationMigration.Api.csproj`, `tests/api.integration/LgrTransformationMigration.Api.IntegrationTests.csproj` and `tests/api.unit/LgrTransformationMigration.Api.UnitTests.csproj`.
- Exact common error:

```text
error NU1301: Unable to load the service index for source https://api.nuget.org/v3/index.json.
error NU1301:   An attempt was made to access a socket in a way forbidden by its access permissions. (api.nuget.org:443)
error NU1301:   An attempt was made to access a socket in a way forbidden by its access permissions.
```

The socket-access failure occurred while contacting the configured external feed and supports an environment-only classification for this restore attempt. It does not establish that the source baseline passes. `dotnet build` and `dotnet test` were not run because restore did not succeed; same-commit .NET restore/build/test evidence remains missing.

### Frontend baseline

- Toolchain: Node.js `v24.18.0`, npm `11.16.0`, Next.js `16.2.12`.
- `npm.cmd run lint`: **PASS**, exit code 0.
- `npm.cmd run build`: **PASS**, exit code 0; optimized production build completed and emitted 16 routes.
- The working directory was returned to the repository root after the commands. The build-generated `next-env.d.ts` delta was removed so the approval-preparation change set remains documentation-only.

## Approval record status

No named human approval has been entered in this pack. Until the required approvers complete the relevant templates and durable evidence is linked from the authoritative work package/ADRs, the quality gate remains `PHASE 3 BLOCKED` and implementation must not begin.
