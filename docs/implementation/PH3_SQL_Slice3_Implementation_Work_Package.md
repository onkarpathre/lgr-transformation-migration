# Phase 3 SQL Slice 3 Implementation Work Package

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-01", "C-03", "C-04", "C-06"]
  functional_requirements: ["F-01", "F-02", "F-04", "F-05", "F-07", "F-15"]
  non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-04", "NF-05", "NF-06", "NF-08", "NF-09", "NF-10", "NF-11", "NF-12", "NF-13"]
  risks: ["R-02", "R-03", "R-06", "R-09", "R-11"]
  assumptions: ["A-01", "A-02", "A-03", "A-05", "A-06", "A-08", "A-11", "A-13", "A-15", "A-16", "A-18"]
  dependencies: ["D-01", "D-03", "D-04", "D-05", "D-07", "D-08", "D-10", "D-11", "D-13"]
  issues: ["I-01", "I-02", "I-04", "I-06", "I-08"]
  open_questions: ["Q-01", "Q-02", "Q-06", "Q-09"]
  approvals:
    - "Product Owner scope decision by onkarpathre, 15 September 2026, approved package commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a."
    - "Architect/TDA approval by opathre, 15 September 2026, approved package commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a."
    - "Information Security approval by ashish50thbirthday-ship-it, 15 September 2026, approved package commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a."
    - "DBA/Discovery SME approval by nextgenexamprep-crypto, 15 September 2026, approved package commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a."
```

## Control and implementation state

- **Role:** Developer under `AGENTS.md`.
- **Work item:** `PH3-SQL-001-REMAINING`, Slice 3 only.
- **Branch:** `feature/ph3-sql-remaining-implementation`.
- **Exact clean starting baseline:** `baa6d6c3c7ff7adc308132a99dac929077cba9b6`.
- **Approved architecture package:** `PH3-SQL-ARCH-REMAINING-001` at `7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a`.
- **Developer state:** `READY_FOR_SLICE_4_DEVELOPMENT` within the already approved Slices 2-4 package. Independent Tester/Quality evidence and all production gates remain outstanding.

No architecture change, Slice 4 browser implementation, SQL Server access, migration application, commit, push, merge or deployment was performed.

## Behaviour implemented

- Added the current human-authored `SqlAssessment` record against exactly one in-project SQL instance or database, with one active assessment per target and logical archive only.
- Implemented the approved case-sensitive assessment, readiness, target-platform and migration-approach vocabularies plus every cross-field workflow invariant.
- Split evidence/status and planning commands. `DatabaseSme` receives read/manage/plan; `MigrationArchitect` receives read/plan; Project Manager, Discovery Analyst and Reviewer/Auditor receive read; unknown/customer/platform roles deny.
- Added paged default-50/max-200 list/detail/create/evidence/planning/archive APIs under `/api/v1/sql-assessments`, with stable newest-first sorting, allow-listed filters, no-tracking read projections, cancellation and opaque ETags.
- Added missing/stale precondition handling (428/412), safe validation/conflict/not-found errors, non-enumerating cross-customer/project behavior and server-derived ownership/actor/audit values.
- Added privacy-safe assessment create, field-change, planning-change, archive and denied-mutation audit events. Narratives remain only in the tenant-authorised audit store and are not logged by the service.
- Prevented instance/database archive while an active assessment exists. Assessment archive does not alter the target and permits a new active assessment later.
- Added the default-off `SqlAssessment` child exposure flag. It is restricted to Development/Testing and requires the existing parent flag; it is not an authorisation control.
- Preserved discovery field ownership. An integration regression proves SQL preview/commit leaves assessment evidence, planning fields and assessment ETag unchanged.
- Planning values are inert labels. No executor, Azure SDK, DMS, provisioning, migration, remediation or AI mapping/path was introduced.

## Persistence and migration

Migration `20260917001712_AddSqlAssessments` is sequential and expand-only after the accepted Slice 2 migrations. `Up` creates only `SqlAssessments`, its alternate key, SQL Server `rowversion`, tenant-leading composite `Restrict` foreign keys, XOR/controlled-value checks, filtered active-target unique indexes and the owner-leading filter index. No prior migration was edited or re-baselined.

`Down` describes removal only for a separately authorised disposable test rehearsal. Operational rollback is data-preserving: disable `SqlAssessment`, return to the preceding compatible application, leave the additive table/audit records intact and deliver a reviewed forward fix. Production `Down`, hard delete, history rewrite and automatic migration application remain prohibited.

## Synthetic fixtures and developer tests

The synthetic fixture manifest now binds `SQL-ASSESS-01`, `SQL-ASSESS-NEG-01` and the assessment portion of `SQL-RBAC-01` to deterministic unit/integration coverage. No real customer or personal data was used.

Coverage includes:

- all controlled values, valid target/approach combinations and invalid workflow combinations;
- instance/database XOR, duplicate-active target, archive/recreate and target-archive restrictions;
- narrative maxima/control content and assessed-time boundary;
- list filters/paging, ETag missing/stale/current behavior and logical archive;
- every approved role/action/field-command cell, multi-role union, unknown/admin deny and denied-action audit;
- unauthenticated routes, disabled feature, cross-customer target and cross-scope direct-object read/write/archive attempts;
- audit actor/type/time/correlation and old/new field records;
- EF checks, composite foreign keys, filtered indexes and SQL Server generated DDL;
- discovery preview/commit protection of assessment/planning bytes;
- all prior unit and integration regression.

## Developer verification

| Check | Result |
|---|---|
| `dotnet restore LgrTransformationMigration.sln` | PASS; all projects restored. NuGet advisory retrieval emitted three retained `NU1900` warnings because network access to `api.nuget.org` is blocked. |
| Release solution build | PASS: 0 errors; only the three retained advisory-feed warnings. |
| Focused Slice 3 coverage | PASS: 36 unit + 23 integration = 59 passed, 0 failed/skipped. |
| Complete solution tests | PASS: 146 unit + 121 integration = 267 passed, 0 failed/skipped. |
| EF pending-model validation | PASS: no pending model changes; cached global `dotnet-ef` 10.0.11 was used after manifest restore could not reach NuGet. |
| Idempotent migration SQL inspection | PASS: 4,139 generated characters; guard, table, rowversion, checks, both composite FKs and both filtered unique indexes present. Generated in memory only and not executed. |
| Migration `Up` additive-operation scan | PASS: no drop, alter, rename, delete-data or update-data operation. |
| Frontend lint | PASS. |
| Frontend Next.js 16.3.4 webpack production build | PASS: 16 routes. Generated `next-env.d.ts` was restored exactly; no Slice 4 source was changed. |
| Repository forbidden-capability/secret scan | PASS for the Slice 3 diff; no executor/provisioner/DMS/AI/remediation implementation or credential/private-key value was introduced. |
| `git diff --check` | PASS; repository line-ending notices only. |

The final verification commands do not connect to SQL Server. Runtime SQL Server constraint, transaction, rowversion, migration Up/authorised disposable Down/reapply and query-plan evidence remain owned by the named independent Test Authority.

## Files changed

- `src/api/Contracts/SqlAssessmentDtos.cs`
- `src/api/Controllers/SqlAssessmentsController.cs`
- `src/api/Domain/SqlAssessmentRules.cs`
- `src/api/Domain/SqlInventoryEntities.cs`
- `src/api/Infrastructure/AppDbContext.cs`
- `src/api/Infrastructure/IdentityAuthorization.cs`
- `src/api/Infrastructure/SqlDiscoveryAssessmentFeatureFilter.cs`
- `src/api/Infrastructure/Migrations/20260917001712_AddSqlAssessments.cs`
- `src/api/Infrastructure/Migrations/20260917001712_AddSqlAssessments.Designer.cs`
- `src/api/Infrastructure/Migrations/AppDbContextModelSnapshot.cs`
- `src/api/Program.cs`
- `src/api/Services/SqlAssessmentService.cs`
- `src/api/Services/SqlInventoryService.cs`
- `src/api/appsettings.json`
- `src/api/appsettings.Development.json`
- `src/api/appsettings.Testing.json`
- `src/api/appsettings.LocalTest.json`
- `tests/TestData/sql-discovery/fixture-manifest.json`
- `tests/api.unit/IdentityAuthorizationTests.cs`
- `tests/api.unit/SqlAssessmentRulesTests.cs`
- `tests/api.integration/SqlAssessmentApiTests.cs`
- `tests/api.integration/SqlDiscoveryImportApiTests.cs`
- `docs/implementation/PH3_SQL_Slice3_Implementation_Work_Package.md`

## Limitations and retained gates

- Connected NuGet/npm vulnerability evidence was unavailable because outbound advisory access is restricted. No dependency changed.
- SQLite remains supplementary. No SQL Server connection, migration application or provider runtime claim is made.
- Named Test Authority evidence is still required before formal independent acceptance.
- Q-02 commitment, Q-06/DPO, wider production Q-01, production tenancy, deployed Identity Platform/Q-09, Service Transition, PRB and human release authority remain outside this restricted implementation.

## Hand-off

```yaml
handoff:
  from_agent: "developer"
  to_agent: "developer"
  state: "READY_FOR_SLICE_4_DEVELOPMENT"
  work_item: "PH3-SQL-001-REMAINING-SLICE-3"
  branch: "feature/ph3-sql-remaining-implementation"
  commit: null
  baseline_commit: "baa6d6c3c7ff7adc308132a99dac929077cba9b6"
  approved_architecture_commit: "7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a"
  artefacts:
    - "docs/implementation/PH3_SQL_Slice3_Implementation_Work_Package.md"
    - "src/api/Infrastructure/Migrations/20260917001712_AddSqlAssessments.cs"
    - "tests/api.unit/SqlAssessmentRulesTests.cs"
    - "tests/api.integration/SqlAssessmentApiTests.cs"
  evidence:
    - "Release build passed with zero errors."
    - "Focused Slice 3 coverage passed 59/59."
    - "Complete solution suite passed 267/267 with zero failed/skipped."
    - "EF pending-model and generated idempotent SQL inspection passed without database access."
    - "Frontend lint/build and git diff checks passed."
  decisions:
    - "Implemented the approved Slice 3 contract without material architecture change."
    - "Retained split evidence/planning commands and exact ADR-008 least-privilege permissions."
    - "Operational rollback preserves additive assessment/audit data."
  assumptions:
    - "Only synthetic repository identities and fixtures are used."
  risks:
    - "R-02 requires independent abuse testing against the eventual candidate commit."
    - "R-09/I-06 SQL Server runtime migration/concurrency evidence remains for the authorised Tester lane."
    - "R-11 production stack/tenancy decisions remain unresolved and outside this package."
  defects: []
  blockers: []
  approvals:
    - "Existing phase-level Product Owner, Architect/TDA, Information Security and DBA/Discovery SME approvals remain applicable because architecture did not materially change."
  requested_action: "Continue only with the already approved Slice 4 browser journeys and phase evidence scope. Do not merge, deploy, apply production migrations or use customer data."
```
