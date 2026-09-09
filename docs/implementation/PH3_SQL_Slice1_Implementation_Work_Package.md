# PH3-SQL-001 Slice 1 - Implementation Work Package

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
    - "Product Owner JP (opathre), 8 September 2026: local POC implementation only, subject to PR restrictions."
    - "Solution Architect/TDA PT (PTArchitect), 8 September 2026: ADR-006 and ADR-007 accepted with conditions for the local/non-production PH3-SQL-001 POC only."
    - "Information Security NTSecurity (nextgenexamprep-crypto), 8 September 2026: ADR-007 accepted with conditions for the local/non-production PH3-SQL-001 POC only."
```

## Control and outcome

- Work item: `PH3-SQL-001`, development slice 1.
- Architecture package: `PH3-SQL-ARCH-001`.
- Approved starting baseline: `main` commit `5d3e9b02bc57989d79ee47a133ab35ad4a31d3f8`; verified before editing.
- Implementation state: `BLOCKED_IMPLEMENTATION`.
- Branch/commit: none. Creating `feature/ph3-sql-inventory-slice-1` failed because the workspace denies writes under `.git/refs`; the changes remain uncommitted on the verified baseline.
- Authority: restricted local/non-production POC only. No merge, migration application, deployment, production data, customer data, Azure provisioning, migration execution or AI action was performed.

The source changes implement the bounded SQL Instance and SQL Database inventory slice. The package is not declared `READY_FOR_TEST`: external NuGet access and the vulnerability feed were unavailable, the required feature branch could not be created, and I-06/D-11 test-authority approval plus an approved isolated SQL Server test environment remain unevidenced. Cached-package build and test command results are recorded as observations, not formal test-authority acceptance.

## Requirements implemented

| Requirement | Implementation and developer evidence | Scope status |
|---|---|---|
| SQL-PO-001, SQL-PO-002, SQL-PO-005, SQL-AC-001 | Versioned REST create, retrieve, update, logical delete and bounded list endpoints for instances and databases; default page size 50, maximum 200; filters by search, parent and status; model validation; Problem Details; ETag/`If-Match` concurrency. | Implemented for slice 1 |
| SQL-PO-003, SQL-PO-004, SQL-AC-002 | Required same-owner Server-to-Instance and Instance-to-Database relationships; tenant-leading composite alternate keys and foreign keys; active-name uniqueness within each parent. | Implemented for slice 1 |
| SQL-PO-015, SQL-AC-008 | Customer/project context is server-derived; write DTOs cannot set ownership; global customer filters plus explicit project predicates; cross-customer/project direct-object and relationship attempts return safe failures; database constraints provide defence in depth. | Implemented for slice 1 |
| SQL-PO-016, SQL-AC-009 | Significant create, field update, relationship change and archive operations append scoped audit events with actor, UTC time, correlation ID and redacted sensitive values. | Implemented for slice 1 |
| SQL-PO-017 | DTO-only versioned controllers, validation, typed service layer, stable safe error codes and correlation IDs. | Implemented for slice 1 |
| SQL-PO-019, SQL-AC-011 | Synthetic integration scenario creates 205 instances and 205 databases and verifies bounded paging and filters. | Automated command observed; formal test authority outstanding |
| SQL-PO-020, SQL-AC-014 | No database-migration execution, DMS orchestration, remediation, AI inference or Azure provisioning path was added. | Implemented as an exclusion |
| SQL-PO-021, SQL-AC-015 | Optional manual service-account display metadata rejects credential-like/multiline values; audit changes are redacted. It is not part of an import contract. | Implemented for manual slice-1 CRUD only |
| SQL-AC-012 | Existing backend tests and frontend lint/build were re-run after the slice. | Command results below; formal clean-feed/test-authority acceptance outstanding |

SQL-PO-006 through SQL-PO-014, SQL-PO-018 and SQL-PO-022 are not claimed by this slice. CSV upload/reconciliation/history, assessment and browser journeys remain later slices and require their applicable approvals. SQL-AC-003 through SQL-AC-007, SQL-AC-010 and full SQL-AC-013/015 are correspondingly excluded.

## Behaviour and security controls

- `SqlInstance` is owned by `CustomerId`/`ProjectId` and must reference one `Server` with the identical ownership tuple.
- `SqlDatabase` is owned by `CustomerId`/`ProjectId` and must reference one `SqlInstance` with the identical ownership tuple.
- Names are trimmed, Unicode NFC-normalised and invariant-uppercase-normalised for uniqueness. Default-instance aliases normalise to `MSSQLSERVER`.
- Active instances are unique by `(CustomerId, ProjectId, ServerId, NormalizedName)`; active databases are unique by `(CustomerId, ProjectId, SqlInstanceId, NormalizedName)`.
- Query filters enforce current-customer visibility and logical deletion; every service query also binds the current project.
- Development/test headers and configured fallback context are accepted only in `Development` or `Testing`; other environments fail closed pending the approved identity design.
- Database port, database size and compatibility level have database check constraints as well as request validation.
- Parent deletes are restricted: an active Server cannot be archived while it owns an active SQL Instance, and an active instance cannot be archived while it owns an active database.
- Updates and deletes require an opaque `If-Match` token. Missing and stale tokens fail with 428 and 412 respectively without mutation.
- Client payloads contain relationship identifiers only; customer/project, normalised values, audit values, logical-delete values, import ownership and version tokens are server controlled.
- SQL Server uses database-generated rowversion values; the SQLite integration provider uses application-generated opaque versions without weakening SQL Server configuration.

## Files changed

### Application

- `src/api/Domain/SqlInventoryEntities.cs` - SQL Instance and SQL Database aggregates.
- `src/api/Domain/SqlInventoryRules.cs` - normalisation, controlled values and sensitive-display-name validation.
- `src/api/Domain/Entities.cs` - Server navigation and audit correlation identifier.
- `src/api/Contracts/SqlInventoryDtos.cs` - versioned request/response/page contracts and validation.
- `src/api/Services/SqlInventoryService.cs` - tenant/project-scoped CRUD, filtering, relationship validation, concurrency and audit behaviour.
- `src/api/Controllers/SqlInventoryControllers.cs` - `/api/v1/sql-instances` and `/api/v1/sql-databases` endpoints.
- `src/api/Infrastructure/AppDbContext.cs` - DbSets, ownership keys, query filters, constraints, indexes and relationships.
- `src/api/Infrastructure/TenantContext.cs` - correlation context and non-development fail-closed behaviour.
- `src/api/Infrastructure/ApiExceptionHandler.cs` - safe 400/404/409/412/428 Problem Details mappings.
- `src/api/Services/ProgrammeService.cs` - prevent logical deletion of Servers with active SQL Instances and include audit correlation IDs.
- `src/api/Program.cs` - scoped inventory service registration.

### Database

- `src/api/Infrastructure/Migrations/20260909164944_AddSqlInventory.cs`.
- `src/api/Infrastructure/Migrations/20260909164944_AddSqlInventory.Designer.cs`.
- `src/api/Infrastructure/Migrations/AppDbContextModelSnapshot.cs`.

### Tests and evidence

- `tests/api.unit/SqlInventoryRulesTests.cs`.
- `tests/api.integration/SqlInventoryApiTests.cs`.
- `tests/api.integration/LgrWebApplicationFactory.cs` - deterministic synthetic cross-customer/cross-project fixtures.
- `docs/implementation/PH3_SQL_Slice1_Implementation_Work_Package.md` - this package.

## Migration and compatibility

Migration `20260909164944_AddSqlInventory` is additive. Its `Up` operation:

1. Adds nullable `CorrelationId` to `AuditEvents`.
2. Adds tenant-leading alternate keys needed as composite principals to `Projects`, `Servers` and `ImportBatches`.
3. Creates `SqlInstances` and `SqlDatabases` with ownership, audit, provenance, logical-delete and rowversion columns.
4. Adds tenant-leading composite parent/project/import foreign keys with restrictive delete behaviour.
5. Adds filtered active-name unique indexes, lookup indexes and value-range check constraints.

The migration was generated and its SQL/script/model-drift output was inspected. It was not applied to any database and no production or customer data was read or modified. The normal generated `Down` method is reserved for explicitly authorised disposable development environments; rollback for a deployed expand-first release should first disable/revert application use while retaining the additive schema until a separately reviewed cleanup change.

## Commands executed and results

| Command/check | Observed result |
|---|---|
| `git rev-parse HEAD` / baseline status | Exact baseline `5d3e9b02bc57989d79ee47a133ab35ad4a31d3f8`; initially clean. |
| Baseline `dotnet test LgrTransformationMigration.sln --configuration Release --no-build --no-restore` | Exit 0: 32 unit and 23 integration tests. |
| `git switch -c feature/ph3-sql-inventory-slice-1` | Failed: permission denied writing `.git/refs`; no branch or commit created. |
| Cached EF CLI `migrations add AddSqlInventory` | Exit 0; migration above generated. |
| Cached EF CLI idempotent migration script generation | Exit 0; script inspected only, not executed. |
| Cached EF CLI `migrations has-pending-model-changes` | Exit 0: no pending model changes. |
| Cached EF CLI migration list with no connection | Exit 0: initial, discovery-import and SQL-inventory migrations listed. |
| Additive-operation inspection | No `DropTable`, `DropColumn`, `Rename*`, `AlterColumn`, `DeleteData` or `UpdateData` call in `Up`. |
| External `dotnet tool restore`, clean solution restore and vulnerability query | Blocked by NuGet service-index/socket access. The clean restore failed with `NU1301`; the vulnerability query could not produce evidence. |
| `dotnet restore ... --source C:\\Users\\onkar\\.nuget\\packages` | Exit 0 using exact locally cached archives; no dependency versions changed and no external source was used. |
| Final Release build with `--no-restore` | Exit 0; 0 warnings and 0 errors. |
| Final unit test assembly with `--no-build --no-restore` | Exit 0: 50 executed, 0 failed, 0 skipped. |
| Final integration test assembly with `--no-build --no-restore` | Exit 0: 37 executed, 0 failed, 0 skipped. |
| `npm.cmd run lint` | Exit 0. |
| `npm.cmd run build` | Exit 0; Next.js production build emitted 16 routes. |
| Scoped `dotnet format whitespace --verify-no-changes` for slice files | Exit 0. Full-repository format verification reports pre-existing baseline whitespace debt in unrelated files. |
| `git diff --check` | No whitespace errors; Git emitted line-ending conversion warnings only. |

Because external NuGet access is blocked, these raw cached-package command results must not be represented as a clean connected-feed, vulnerability-scanned or formally accepted test success.

## Test coverage added

- Valid instance/database CRUD, filtering and parent changes.
- Missing and stale ETag preconditions with no mutation.
- Duplicate names after normalisation; identical names allowed under different parents.
- Missing, cross-customer and cross-project relationship rejection.
- Cross-customer/project list, detail, update, delete and direct-object enumeration attempts.
- Mismatched customer/project context fails closed.
- Audit evidence for creates, field changes, relationship moves and archives; service-account values remain redacted.
- Server/instance parent-delete restrictions.
- Invalid port, compatibility, controlled status/recovery and credential-like service-account metadata.
- 205-instance and 205-database bounded-paging/filter scenarios.
- Physical composite-FK rejection, EF model metadata, filtered uniqueness and synthetic ownership preflight.
- SQL Server provider create-script assertions for rowversion, composite foreign keys and filtered indexes without opening or mutating a SQL Server database.

## Unresolved risks and blockers

1. `.git/refs` is read-only, so the Product Owner restriction requiring feature-branch development and the repository branch policy cannot be satisfied in this workspace.
2. External NuGet access is blocked. Exact cached packages were sufficient to rebuild and execute tests, but a clean approved-feed restore and dependency/vulnerability evidence are unavailable; no test success is claimed for the formal gate.
3. I-06/D-11 named test-authority approval is not evidenced. The commands above are developer observations, not an independent Test Evidence Pack.
4. No approved isolated SQL Server test database was supplied. Generated SQL Server DDL was inspected, but actual migration application/rollback, SQL Server collation, concurrency and constraint behaviour remain to be independently proven. The migration was intentionally not auto-applied.
5. Q-06/Q-09, production tenancy/HLD DD-05 reconciliation, PRB, production Information Security, service transition and release approvals remain open. This implementation is not authorised for external customer access or production.
6. CSV/source-contract, discovery history, assessment and browser work are excluded from slice 1 and must not be inferred from these APIs.

## Exact Tester Agent hand-off

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "BLOCKED_IMPLEMENTATION"
  work_item: "PH3-SQL-001-slice-1"
  branch: null
  commit: null
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
      - "PO local-POC implementation approval, 8 September 2026"
      - "ADR-006/ADR-007 conditional local-POC approvals, 8 September 2026"
  artefacts:
    - "docs/implementation/PH3_SQL_Slice1_Implementation_Work_Package.md"
    - "src/api/Infrastructure/Migrations/20260909164944_AddSqlInventory.cs"
    - "tests/api.unit/SqlInventoryRulesTests.cs"
    - "tests/api.integration/SqlInventoryApiTests.cs"
  evidence:
    - "Cached-package Release build: exit 0, 0 warnings, 0 errors"
    - "Cached-package unit command: exit 0, 50 executed, 0 failed"
    - "Cached-package integration command: exit 0, 37 executed, 0 failed"
    - "Frontend lint and production build: exit 0"
    - "EF model drift check: no pending model changes"
    - "Migration Up additive-operation inspection: no destructive operations"
  decisions:
    - "Use accepted .NET 10/EF Core 10 modular-monolith baseline."
    - "Use ADR-007 shared database/shared schema only for this restricted local/non-production POC."
    - "Keep CSV, assessment, browser and production identity/tenancy outside slice 1."
  assumptions:
    - "Only synthetic test identities and data were used."
    - "A named authority will supply the approved test environment and exact branch/commit before independent execution."
  risks:
    - "R-02 tenant isolation requires independent abuse testing."
    - "R-09/I-06 SQL Server-specific runtime and migration behaviour is not yet proven against an approved SQL Server test database."
    - "R-11 wider production technology/tenancy approval remains unresolved."
  defects: []
  blockers:
    - "Workspace denied creation of the required feature branch; changes are uncommitted on baseline main."
    - "External NuGet restore and vulnerability evidence are blocked."
    - "I-06/D-11 test-authority approval and an approved isolated SQL Server test environment are not evidenced."
  approvals:
    - "Product Owner local-POC implementation approval evidenced."
    - "Solution Architect/TDA ADR-006 and ADR-007 conditional local-POC approvals evidenced."
    - "Information Security ADR-007 conditional local-POC approval evidenced."
    - "PRB, test authority, production tenancy, DPO, service transition and release approvals not evidenced."
  requested_action: "Do not accept this package as READY_FOR_TEST. After a human/platform owner provides a writable working branch, restores approved NuGet/vulnerability access, records I-06/D-11 test authority and supplies an isolated SQL Server test environment, bind the unchanged implementation to an exact commit and independently prove CRUD, direct-object/cross-tenant/cross-project isolation, composite database constraints, duplicate-name concurrency, ETag concurrency, audit redaction, 200+ paging, migration apply/rollback and regression before returning PASS or RETURN_TO_DEVELOPER."
```

## Tester Agent evidence update - 9 September 2026

The independent test record is `docs/implementation/PH3_SQL_Slice1_Test_Evidence_Pack.md`.

- Implementation commit tested: `abd466a014aebcfe02b0f72e4322328df12e203a`.
- Comparison baseline: `5d3e9b02bc57989d79ee47a133ab35ad4a31d3f8`.
- Branch discrepancy: the tested commit exists only on local `main`; requested branch `feature/ph3-sql-implementation` remains at the baseline and contains no Slice 1 implementation.
- Restore: PASS for all three solution projects.
- Release build: PASS, 0 warnings and 0 errors.
- Committed tests: PASS, 87/87 (50 unit, 37 integration).
- Tester-strengthened tests: FAIL, 87 passed and 1 failed of 88; the failing test proves automatic DTO validation omits four mandatory Problem Details members.
- Phase 1/2 regression: PASS, 55/55 (32 unit, 23 integration).
- EF pending-model-change validation: PASS with pinned EF CLI 10.0.11.
- Phase 3 delta migration inspection: no destructive schema or data operation; SQL Server runtime migration/provider validation remains blocked and unevidenced.
- Exact Tester state: `BLOCKED` / `RETURN_TO_DEVELOPER`; not `READY_FOR_QUALITY_REVIEW`.

Open defects are PH3SQL-TST-001 (branch/handoff mismatch), PH3SQL-TST-002 (missing authenticated/project-role authorisation policy), PH3SQL-TST-003 (incomplete DTO-validation Problem Details) and PH3SQL-TST-004 (missing architecture-required default-off feature toggle). Mandatory SQL Server runtime evidence, I-06/D-11 test-authority approval and dependency vulnerability-feed evidence remain blocked. The original Developer hand-off state therefore remains `BLOCKED_IMPLEMENTATION`; this Tester update does not rewrite it or invent a Developer/human approval.
