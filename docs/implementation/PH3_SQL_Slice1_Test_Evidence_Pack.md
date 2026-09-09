# PH3-SQL-001 Slice 1 - Independent Test Evidence Pack

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
    - "Product Owner JP (opathre), 8 September 2026: restricted local POC implementation only."
    - "Solution Architect/TDA PT (PTArchitect), 8 September 2026: ADR-006 and ADR-007 accepted with conditions for the restricted local/non-production POC only."
    - "Information Security NTSecurity (nextgenexamprep-crypto), 8 September 2026: ADR-007 accepted with conditions for the restricted local/non-production POC only."
```

## Test control

- Tester role: independent Tester Agent under `AGENTS.md`.
- Test date: 9 September 2026.
- Requested branch: `feature/ph3-sql-implementation`.
- Actual requested-branch commit: `5d3e9b02bc57989d79ee47a133ab35ad4a31d3f8`.
- Implementation commit tested: `abd466a014aebcfe02b0f72e4322328df12e203a` (`Implement Phase 3 SQL inventory slice 1`).
- Implementation commit parent/comparison baseline: `5d3e9b02bc57989d79ee47a133ab35ad4a31d3f8`, also the current `origin/main` and requested-feature-branch commit.
- Actual branch containing the implementation commit: local `main` only; `git branch --contains abd466a --all` returns only `main`.
- Environment: Windows 10.0.26200, .NET SDK 10.0.400, .NET/ASP.NET Core runtime 10.0.11, EF CLI 10.0.11, SQLite in-memory API integration provider, Next.js 16.2.12.
- Test data: repository synthetic fixtures and tester-created synthetic values only.
- Deployment/database actions: none. No migration was applied and no database was created, altered, dropped or seeded by this test run.

## Entry and decision-gate validation

The Product Owner, ADR-006 and ADR-007 records permit only restricted local/non-production POC work. They do not grant PRB, production-tenancy, production, merge, deployment or release approval.

The incoming Implementation Work Package is not a valid `READY_FOR_TEST` hand-off. At the tested commit it declares `BLOCKED_IMPLEMENTATION`, `branch: null`, `commit: null`, and explicitly requests that the Tester not accept it as ready. The later commit exists only on local `main`; it was not bound to the requested feature branch and the hand-off was not corrected by the Developer.

I-06/D-11 named test-authority approval and an approved isolated SQL Server test environment remain absent. Q-06, Q-09, production tenancy/HLD DD-05 reconciliation, PRB, Managed Services and human release decisions remain open and are not inferred.

## Commands and results

| Check | Result |
|---|---|
| Git identity/ref validation | `abd466a` is the implementation commit and direct child of `5d3e9b0`; only local `main` contains it. `feature/ph3-sql-implementation` and `origin/main` both remain at `5d3e9b0`. |
| Changed-file inspection | 18 files changed from `5d3e9b0` to `abd466a`: application, migration, tests and the Implementation Work Package were reviewed. |
| `dotnet restore LgrTransformationMigration.sln --force --no-cache` | PASS, exit 0; all three solution projects restored. |
| `dotnet build LgrTransformationMigration.sln --configuration Release --no-restore` | PASS, exit 0; 0 warnings, 0 errors. |
| Committed solution suite before tester additions | PASS, exit 0; 50 unit + 37 integration = 87 passed, 0 failed, 0 skipped. |
| Tester-strengthened solution suite | FAIL, exit 1; 50/50 unit passed and 37/38 integration passed: 87 passed, 1 failed, 0 skipped, 88 total. |
| Phase 1/2 regression filter (`FullyQualifiedName!~SqlInventory`) | PASS, exit 0; 32 unit + 23 integration = 55 passed, 0 failed, 0 skipped. |
| SQL Inventory filter (`FullyQualifiedName~SqlInventory`) | FAIL, exit 1; 18 unit passed and 14/15 integration passed: 32 passed, 1 failed, 0 skipped, 33 total. |
| EF manifest command before tool restoration | BLOCKED; the manifest tool was not locally available. |
| `dotnet tool restore` | BLOCKED, exit 1; outbound access to `api.nuget.org:443` is forbidden. |
| Global pinned EF CLI version | PASS; `dotnet-ef 10.0.11`. |
| EF `migrations has-pending-model-changes` using pinned CLI | PASS, exit 0; no model changes since the last migration. |
| EF migration list with no connection | PASS; the three migrations, including `20260909164944_AddSqlInventory`, are present. |
| EF migration list with configured SQL Server connection | BLOCKED; database access failed and applied/pending status could not be determined. No retry or mutation was attempted. |
| Phase 3 delta migration script generation | PASS, exit 0; 95 lines, with no `DROP TABLE`, `DROP COLUMN`, rename, alter-column, data delete, data update or seed-data statements. |
| Full idempotent script generation | PASS, exit 0; required Phase 3 rowversion, owner-leading keys/FKs, check constraints and filtered unique indexes are present. Existing Phase 2 seed-update statements are outside the Phase 3 delta. |
| SQL Server runtime migration/constraint/concurrency lane | NOT RUN; no approved isolated SQL Server database/test authority was supplied, and configured SQL Server access was unavailable. |
| `npm.cmd run lint` | PASS, exit 0. |
| `npm.cmd run build` | PASS, exit 0; 16 routes generated. The build-only rewrite of tracked `next-env.d.ts` was restored to the tested commit without changing application behaviour. |
| .NET and npm vulnerability-feed checks | BLOCKED; outbound NuGet/npm advisory endpoints were unavailable. |
| Product-boundary repository search | PASS for the implementation delta; no migration executor, DMS orchestration, AI inference, remediation, raw SQL execution or Azure resource-manager/provisioning path was added. |
| Tester-owned test-file whitespace verification | PASS, exit 0. |

## Independent test change

`tests/api.integration/SqlInventoryApiTests.cs` was strengthened without changing application behaviour:

- service-account CRUD/audit evidence now proves that a synthetic display value is returned to its authorised request while the audit old/new value is redacted; and
- `Dto_validation_returns_the_approved_problem_details_contract` enforces the PH3-SQL-ARCH-001 safe-error contract.

The latter test fails reproducibly. A DataAnnotations failure returns:

```json
{"type":"https://tools.ietf.org/html/rfc9110#section-15.5.1","title":"One or more validation errors occurred.","status":400,"errors":{"Port":["The field Port must be between 1 and 65535."]},"traceId":"..."}
```

The response omits the required `detail`, `instance`, `errorCode` and `correlationId` members because automatic `[ApiController]` validation bypasses `ApiExceptionHandler`.

## Requirements-to-test matrix

| Requirement / criterion | Evidence | Result |
|---|---|---|
| SQL-PO-001, SQL-PO-002; C-03/F-04 | Paged list tests use 205 synthetic instances and 205 synthetic databases; default/capped paging plus parent/status/search filtering inspected and exercised. | PASS on SQLite/API; SQL Server query-plan/timing evidence remains absent. |
| SQL-PO-003, SQL-PO-004; SQL-AC-002; F-15/NF-01/NF-02/R-02 | API negative tests, SQLite physical FK rejection, EF metadata inspection, migration/script inspection and static service predicates prove owner-leading Project/Server/Instance relationships and normalized active uniqueness. | PARTIAL: application/SQLite/static checks pass; mandatory SQL Server runtime FK/filtered-unique/concurrent-create proof is blocked. |
| SQL-PO-005; SQL-AC-001 | Positive instance/database create, retrieve, update, archive, ETag/precondition, dependent-delete, re-parent, duplicate and invalid-value tests. | FAIL overall because DTO validation does not return the approved Problem Details contract. |
| SQL-PO-015; SQL-AC-008; F-15/NF-01/NF-02/R-02 | Cross-customer, cross-project, mismatched-context, list/detail/write/archive and relationship-ID tests pass; non-local environments ignore development headers and fail closed by static inspection. | FAIL/PARTIAL: record isolation tests pass, but no authentication/authorization registration, endpoint policy or project-role check exists; possession of a valid synthetic customer/project header grants full local/test CRUD. |
| SQL-PO-016; SQL-AC-009; NF-06 | Create/update/relationship/archive audit assertions verify tenant/project, actor, UTC timestamp and correlation ID; tester-added service-account assertion proves `[REDACTED]` audit values. | PASS for Slice 1 CRUD. |
| SQL-PO-017; NF-10/NF-13 | DTO-only controller/service inspection, ETag/status tests and independent invalid-DTO response test. | FAIL: automatic DTO-validation errors omit four mandatory safe Problem Details members. |
| SQL-PO-019; SQL-AC-011; NF-08 | 410 synthetic SQL assets (205 instances + 205 databases), capped page size 200 and filters. | PARTIAL: bounded behaviour passes on SQLite; SQL Server timings/query plans and runtime evidence are absent. |
| SQL-PO-020; SQL-AC-014; A-11/A-13/R-06 | Delta/full-tree search and route/service inspection. | PASS: record/planning only; no executor, DMS, remediation, AI or Azure-provisioning path added. |
| SQL-PO-021; applicable manual subset of SQL-AC-015; NF-04/NF-06 | Unit allow-list/rejection tests, CRUD response and redacted audit assertion using synthetic metadata. | PASS for manual CRUD subset; import/history portions are explicitly deferred. |
| SQL-AC-012; NF-10/D-13 | Same-source Release build, complete solution execution, explicit Phase 1/2 filter, frontend lint/build. | PASS for regression; the strengthened overall suite fails only the new Phase 3 Problem Details check. |
| SQL-PO-006..014, SQL-PO-018, SQL-PO-022; SQL-AC-003..007, SQL-AC-010, remaining SQL-AC-013/015 | Implementation Work Package explicitly defers CSV import/reconciliation/history, assessment and browser journeys. | NOT APPLICABLE to Slice 1; no pass is claimed. |

## Migration assessment

Migration `20260909164944_AddSqlInventory` is expand-only in `Up`: it adds nullable audit correlation metadata, owner-leading alternate keys, and new SQL Instance/Database tables, rowversion columns, composite FKs, check constraints and filtered indexes. It does not alter or remove existing columns/tables or update existing/seed data. The EF snapshot matches the runtime model and the Phase 3 delta script is non-destructive.

This is static/generated-script assurance only. PH3-SQL-ARCH-001 and ADR-006 require an isolated SQL Server runtime lane for empty and baseline databases, actual Up/Down rehearsal in an authorised disposable environment, collation-independent uniqueness, composite/check constraints, rowversion/ETag behaviour, concurrent duplicate creation and query plans. That mandatory evidence is absent, so additive migration safety is not fully proven.

The architecture also requires deployment with `SqlDiscoveryAssessment` default off. No feature-flag registration, configuration or endpoint gating exists in `src` or `tests`; this is an architecture/deployment-control deviation even though no deployment was performed.

## Defects and blockers

| ID | Severity | Type | Finding / expected result | Disposition |
|---|---|---|---|---|
| PH3SQL-TST-001 | High | Repository/handoff control | The implementation is not on `feature/ph3-sql-implementation`; it is committed only to local protected `main`. The incoming package still says `BLOCKED_IMPLEMENTATION`, branch/commit null. Expected: a dedicated working branch, exact commit and Developer `READY_FOR_TEST` hand-off. | Open; return to Developer/repository owner. |
| PH3SQL-TST-002 | High | Authorisation/architecture | SQL endpoints register no authentication/authorization policy and perform no actor/project-role check. Record-level customer/project filters pass, and Production fails closed, but SQL-PO-015/ADR-007's authorised-project rule is not implemented. | Open; requires Developer fix under Architect/Q-09 boundaries. |
| PH3SQL-TST-003 | Medium | API contract | Automatic DTO validation omits `detail`, `instance`, `errorCode`, `correlationId`, violating SQL-PO-017/SQL-AC-001/NF-13 and the approved safe-error contract. | Open; reproducible failing independent test retained. |
| PH3SQL-TST-004 | Medium | Architecture/deployment | Required `SqlDiscoveryAssessment` default-off feature toggle is absent; versioned SQL routes are always mapped. | Open; return to Developer/Architect if the control is intentionally deferred. |
| PH3SQL-BLK-001 | Release-blocking evidence gap | Environment/human gate | Mandatory SQL Server runtime migration, constraints, rowversion, collation, concurrent uniqueness and query-plan evidence cannot be produced without an approved isolated SQL Server test environment and I-06/D-11 test-authority approval. | Blocked pending named human/environment decision. |
| PH3SQL-BLK-002 | Release-blocking evidence gap | Dependency assurance | NuGet/npm vulnerability advisory feeds are inaccessible, so required vulnerability evidence is unavailable. | Blocked pending approved feed/network/CI evidence. |

No critical/high cross-tenant data disclosure or data-loss event was observed because only synthetic isolated SQLite data was used. PH3SQL-TST-002 remains a high assurance defect because authorisation is an immutable product boundary and its absence prevents acceptance.

## Exact gate decision

**Recommendation:** `FAIL`

**Tester exit state:** `BLOCKED` (`RETURN_TO_DEVELOPER`; not `READY_FOR_QUALITY_REVIEW`)

```yaml
handoff:
  from_agent: "tester"
  to_agent: "developer"
  state: "BLOCKED"
  work_item: "PH3-SQL-001-slice-1"
  branch: "feature/ph3-sql-implementation (requested, but still at 5d3e9b02bc57989d79ee47a133ab35ad4a31d3f8)"
  commit: "abd466a014aebcfe02b0f72e4322328df12e203a (tested implementation; local main only)"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-02", "C-03", "C-04", "C-06"]
    functional_requirements: ["F-03", "F-04", "F-05", "F-07", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-04", "NF-05", "NF-06", "NF-08", "NF-09", "NF-10", "NF-11", "NF-12", "NF-13"]
  artefacts:
    - "docs/implementation/PH3_SQL_Slice1_Test_Evidence_Pack.md"
    - "tests/api.integration/SqlInventoryApiTests.cs (uncommitted tester-only strengthening)"
  evidence:
    - "Commit suite: 87 passed, 0 failed, 0 skipped."
    - "Strengthened suite: 87 passed, 1 failed, 0 skipped; 88 total."
    - "Phase 1/2 regression: 55 passed, 0 failed, 0 skipped."
    - "Release build: 0 warnings, 0 errors."
    - "EF pending-model check: no pending changes."
    - "Phase 3 delta script: non-destructive by operation inspection."
  decisions:
    - "Do not advance to Quality Manager while open defects and mandatory SQL Server/dependency evidence gaps remain."
  assumptions:
    - "All exercised records and identities are synthetic."
  risks: ["R-02", "R-06", "R-09", "R-11"]
  defects: ["PH3SQL-TST-001", "PH3SQL-TST-002", "PH3SQL-TST-003", "PH3SQL-TST-004"]
  blockers: ["PH3SQL-BLK-001", "PH3SQL-BLK-002", "I-06/D-11", "Q-09 and production-tenancy gates remain open"]
  approvals:
    - "Restricted local-POC Product Owner, Architect/TDA and Information Security approvals are evidenced."
    - "Test authority, PRB, production tenancy, DPO, service transition and human release approvals are not evidenced."
  requested_action: "Developer/repository owner must place the unchanged/fixed implementation on an approved working branch, issue an exact READY_FOR_TEST hand-off, implement the authorised-project and safe-validation-error controls, resolve or obtain an Architect decision on the missing default-off feature toggle, and provide approved SQL Server plus vulnerability evidence before full independent retest."
```
