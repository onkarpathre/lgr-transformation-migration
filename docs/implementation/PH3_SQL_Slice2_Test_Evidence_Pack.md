# PH3-SQL-001 Slice 2 - Test Evidence Pack

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
    - "Product Owner, Architect/TDA, Information Security and DBA/Discovery SME approvals for architecture commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a."
    - "Test Authority approval: https://github.com/onkarpathre/lgr-transformation-migration/pull/8#pullrequestreview-5221828015"
```

## Control and recommendation

- **Tester:** independent Tester Agent under `AGENTS.md`.
- **Work item:** `PH3-SQL-001-REMAINING-SLICE-2`.
- **Branch:** `feature/ph3-sql-remaining-implementation`.
- **Exact subject:** `7cd65a94163c2183c2ecb19d6e07d3a1d6c26920`.
- **Approval:** supplied Test Authority review above.
- **Owner-run date:** 16 September 2026 UTC to 17 September 2026 UTC.
- **Tester reconciliation date:** 17 September 2026.
- **Recommendation:** `PASS` / `READY_FOR_QUALITY_REVIEW`.

The owner-run result records exact expected and actual branch/HEAD equality before SQL access and immediately before mutation. This Tester reconciliation read the retained artefact only: it did not access SQL Server, rerun tests, execute migrations, alter or delete the retained database, change application code, commit, push, merge, deploy or start Slice 3. Changes remain confined to the three existing Tester-owned artefacts; the tenant-integrity test is retained unchanged.

Open Q-02, Q-06 and Q-09 and all production/external/release approvals remain outside this restricted synthetic local test scope.

## Prior-defect disposition

| ID | Result | Evidence |
|---|---|---|
| `PH3SQL-S2-TST-001` | **CLOSED - PASS** | The retained test passed 1/1 and the owner-run SQL constraint matrix proved the repaired composite staging-to-batch relationship: cross-scope staging/batch insertion was rejected, while the owner-leading unique row index and tenant/project-scoped FK were present before and after reapply. |
| `PH3SQL-S2-TST-002` | **CLOSED - PASS** | The result binds both expected and actual HEAD to `7cd65a94163c2183c2ecb19d6e07d3a1d6c26920`, records the approved branch, and completed with overall `PASS` and zero recorded defects. |

No new application defect was found.

## Requirements-to-test evidence

| Area | Result |
|---|---|
| Retained tenant-integrity regression | PASS: 1/1, 0 failed/skipped. |
| Focused CSV and ADR-008 unit lane | PASS: 60/60, 0 failed/skipped. |
| Focused Slice 2 import integration lane | PASS: 11/11, 0 failed/skipped. |
| Complete regression | PASS: 209/209, 0 failed/skipped: 110 unit and 99 integration. |
| Release build | PASS: 0 errors; 2 `NU1900` warnings because the NuGet advisory feed was unavailable. |
| EF validation | PASS with pinned `dotnet-ef` 10.0.11: no pending model changes; no SQL connection or migration execution. |
| Frontend lint | PASS. |
| Frontend production build | PASS in an ignored source-identical isolated copy using Next.js 16.3.4 webpack; 16 routes generated. |
| Development identity injection | PASS: configured synthetic alias is trimmed and replaces caller-controlled `X-Lgr-Test-Principal`. |
| Development missing-variable failure | PASS: missing variable throws the documented fail-closed configuration error. |
| Production suppression | PASS: production returns no test principal, deletes any caller-supplied test-principal header, and the production bundle contains no suppression canary. |
| Product boundaries | PASS by retained full regression and scoped review; no migration executor, Azure provisioner, direct discovery API, multi-cloud or AI behaviour was introduced. |

The first two in-memory Node smoke wrapper attempts failed because PowerShell native argument quoting removed JavaScript string quotes. The corrected stdin-fed execution passed all three identity cases. These were Tester command errors, not product defects.

## Owner-run SQL assurance reconciliation

Immutable source result:

- path: `TestResults/PH3_SQL_Slice2_Assurance_20260916T230623467Z/result.json`;
- SHA-256: `C455BDE2C7D90C8D00244927F217C7638A76BAE51CEE81E9C97DEEA8B53C5661`;
- size: 445,455 bytes;
- outcome: `PASS`; 24/24 recorded steps are `PASS`, zero defects are recorded, and every recorded native command completed with exit code 0;
- subject: expected and actual commit `7cd65a94163c2183c2ecb19d6e07d3a1d6c26920` on `feature/ph3-sql-remaining-implementation`;
- target: `LgrTransformationMigration_Ph3Sql_Slice2_Assurance_20260916_Retry01` on the approved local SQL Express instance.

The evidence verifies:

1. **Six-migration history:** the initial and final histories contain the same six ordered migrations, from `20260823111854_InitialCreate` through `20260916121802_EnforceDiscoveryImportRowTenantBatchOwnership`, with no pending migration.
2. **Constraints and isolation:** valid relationships succeeded; cross-scope, range and normalized-duplicate writes were rejected. Runtime evidence includes SQL error 547 for port, size, compatibility and cross-tenant canonical-FK probes, `crossScopeStagingBatchInsertAllowed=false`, zero rollback residual rows, and the repaired composite batch ownership constraint.
3. **Concurrency:** the current rowversion update affected one row and the stale update affected zero. Of two synchronized duplicate creators, exactly one inserted, one was rejected with SQL error 2601, and exactly one conflict row persisted.
4. **Plans:** six actual `.sqlplan` artefacts were captured and analysed. The history and paged-list plans recorded seeks, the relationship plan recorded a seek plus scans appropriate to the small synthetic set, and no plan contained a missing-index recommendation.
5. **Rollback/reapply:** rollback reached the approved four-migration `AddInternalPrincipalAuditType` boundary, removed Slice 2 tables/columns, retained Slice 1 inventory, then reapplied to the exact six-migration history and repeated schema inspection successfully.
6. **Retention:** `databaseLeftFullyMigrated=true` and `databaseAutomaticallyDroppedOrDeleted=false`; Retry01 remains fully migrated for owner inspection.

### Historical wording discrepancy

The immutable successful `result.json` contains two stale non-functional detail strings: `all four migrations` and `exact five-migration schema`. Its structured `expectedMigrations`, initial history and final history each correctly contain six migrations, so the discrepancy does not alter the run outcome or evidence. The original result is preserved unchanged. Only the corresponding future-run messages in the Tester harness were corrected to say six migrations.

## Tester hand-off

```yaml
handoff:
  from_agent: "tester"
  to_agent: "quality-manager"
  state: "READY_FOR_QUALITY_REVIEW"
  work_item: "PH3-SQL-001-REMAINING-SLICE-2"
  branch: "feature/ph3-sql-remaining-implementation"
  commit: "7cd65a94163c2183c2ecb19d6e07d3a1d6c26920"
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
  artefacts:
    - "docs/implementation/PH3_SQL_Slice2_Test_Evidence_Pack.md"
    - "tests/api.integration/SqlDiscoveryImportTenantIntegrityTests.cs"
    - "tests/sqlserver/PH3_SQL_Slice2_Assurance.ps1"
  evidence:
    - "Immutable result SHA-256 C455BDE2C7D90C8D00244927F217C7638A76BAE51CEE81E9C97DEEA8B53C5661; original file unchanged."
    - "Owner-run outcome PASS: 24/24 steps PASS, zero defects, recorded native-command exit codes 0."
    - "Retained/focused/full suites: 1/1, 60/60, 11/11 and 209/209 PASS."
    - "Six-migration apply/history, SQL constraints, concurrency, six actual plans, rollback to four and reapply to six: PASS."
    - "Retry01 retained fully migrated; no automatic drop or deletion."
  decisions:
    - "PH3SQL-S2-TST-001 and PH3SQL-S2-TST-002 are CLOSED - PASS at the exact subject commit."
    - "The historical four/five-migration wording is non-functional and contradicted by the correct structured six-migration evidence; result.json remains immutable."
    - "Tester recommendation is PASS and READY_FOR_QUALITY_REVIEW."
  assumptions:
    - "Only repository synthetic identities and fixtures are in scope."
  risks:
    - "Connected dependency advisory evidence remains unavailable and is not treated as a clean result or accepted risk."
  defects: []
  blockers: []
  approvals:
    - "Named Test Authority approval is supplied for this exact HEAD and Retry01 SQL assurance scope; the owner-run result references it."
    - "No Quality, merge, deployment, production, customer-data or release approval is claimed."
  requested_action: "Quality Manager to independently review the immutable owner-run evidence and this Tester reconciliation. No merge, deployment, database deletion or Slice 3 action follows."
```
