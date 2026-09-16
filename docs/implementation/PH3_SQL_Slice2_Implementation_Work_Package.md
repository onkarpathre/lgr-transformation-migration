# PH3-SQL-001 Slice 2 - Implementation Work Package

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
    - "Product Owner scope decision by onkarpathre, 15 September 2026, exact approved package commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a."
    - "Architect/TDA approval by opathre, 15 September 2026, exact approved package commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a."
    - "Information Security approval by ashish50thbirthday-ship-it, 15 September 2026, exact approved package commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a."
    - "DBA/Discovery SME approval by nextgenexamprep-crypto, 15 September 2026, exact approved package commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a."
```

## Control and implementation state

- **Role:** Developer under `AGENTS.md`.
- **Work item:** `PH3-SQL-001-REMAINING`, Slice 2 only.
- **Requested branch:** `feature/ph3-sql-remaining-implementation`.
- **Exact clean starting baseline:** `a53cf3fd9f49a0f4ee1d9705aa8aca0b16279fd6`.
- **Approved architecture package:** `PH3-SQL-ARCH-REMAINING-001` at `7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a`, confirmed as an ancestor of the starting baseline.
- **Implementation status:** complete in the working tree and intentionally uncommitted/unpushed.
- **Developer exit state:** `READY_FOR_TEST` for restricted local/non-production independent verification.

The implementation uses only synthetic fixtures and the existing internal LocalTest identities. It adds no migration execution, Azure provisioning, DMS orchestration, AI, remediation, direct discovery API, multi-cloud, production identity, customer-data access or production-deployment path.

## Behaviour implemented

### CSV envelope, staging and validation

- Added the exact `SqlInstanceCsv/v1` and `SqlDatabaseCsv/v1` source types and canonical `/api/v1/discovery/imports` API surface.
- Enforced `.csv`, 25 MiB, 50,000 data-row and 64-column limits; strict UTF-8, BOM, CRLF/LF, RFC-style quoted values and quoted line breaks remain supported.
- Rejects empty files, NUL, malformed/unclosed quotes, duplicate normalised headers, extra row values, unsupported source contracts, invalid ranges/timestamps, combined server/instance values, formula-like cells, control content and credential-like fields.
- Applies the approved instance/default/status/recovery/database normalisation and exact project-scoped parent matching rules. Unknown columns, safe unknown statuses and repeat hashes produce deterministic warnings.
- Stages raw evidence only after credential-field redaction and stores normalised keys, scoped matches, proposed action/field changes and a bounded SHA-256 reconciliation fingerprint.
- Marks every occurrence of an in-file duplicate business key as Reject, so row order cannot select a winner.

### Reconciliation, commit and history

- Preview requires the current opaque batch ETag, replaces only the uncommitted batch's derived evidence and makes no canonical inventory change.
- Commit requires both the preview ETag and caller-generated `Idempotency-Key`; only the key's SHA-256 hash and a bounded count summary are persisted.
- Same-key retry on a committed batch returns the stored outcome. Different-key replay, cross-request key reuse, missing preconditions and stale state are rejected without mutation.
- Commit re-resolves all parents/current records in bounded project queries and verifies fingerprints inside one database transaction before applying any canonical, snapshot or audit change.
- Instance imports can change only the approved discovery-managed fields; `ServiceAccountName` is neither mapped nor cleared. Blank optional `Port`, `LastDiscoveredAt` and database `Collation` cells never clear current values.
- Every safe committed Create, Update, Unchanged or Warning row creates exactly one typed snapshot. Reject rows create none. Snapshot entities are tenant-filtered, owner-constrained and application-enforced append-only.
- Instance/database discovery-history APIs are newest-first, stable, paged at default 50/maximum 200 and return typed facts rather than raw staged JSON.
- A failed transaction leaves the batch safely at `PreviewReady`, records no partial canonical/snapshot/audit mutation and requires refreshed review before retry.

### ADR-008, errors and audit

- Added exact deny-by-default permissions `sql.discovery.read`, `sql.discovery.prepare`, `sql.discovery.commit` and `sql.discovery.cancel` with additive multi-role union.
- All five approved roles can read batches/summaries/typed history; only `DiscoveryAnalyst` can upload, preview, commit and cancel. Raw staged detail is additionally restricted to `DatabaseSme` and `DiscoveryAnalyst`.
- Every query and relationship uses server-derived customer/project context and explicit project predicates. Missing and cross-scope identifiers share the same non-enumerating 404 contract.
- The `SqlDiscoveryImport` child feature is default-off, local/test-only and requires the existing `SqlDiscoveryAssessment` parent flag.
- Safe Problem Details cover 400/401/403/404/409/412/413/415/422/428/500/503 without provider, path, credential or raw-row detail.
- Upload, preview, cancel, commit, canonical field change and denied high-risk mutation events include stable actor, principal type, derived customer/project, UTC time and correlation ID. General logs do not receive filenames, raw cells or SQL names.

## Database migration assessment

Migration `20260915171019_AddSqlDiscoveryImportHistory` is the single Slice 2 expand-only EF Core migration after the accepted Slice 1 migrations.

`Up` contains:

- nine additive columns: three batch concurrency/idempotency columns and six nullable staging/reconciliation columns;
- SQL Server `rowversion` on `ImportBatches`;
- `SqlInstanceDiscoverySnapshots` and `SqlDatabaseDiscoverySnapshots` with typed lengths/checks;
- eight owner-leading/staging/history/idempotency indexes;
- tenant-leading composite foreign keys from staging matches and both snapshot types to canonical records/batches, all `Restrict` for committed evidence.

Static inspection found no `Drop*`, rename, `AlterColumn`, `DeleteData` or `UpdateData` operation in `Up`. `Down` removes only the additive Slice 2 objects, but the approved operational rollback is data-preserving: disable `SqlDiscoveryImport`, use the preceding compatible application and forward-fix while leaving schema/history intact. No migration was applied and no database was accessed or changed.

The generated 1,905-line idempotent SQL script was inspected in memory and contains the Slice 2 history guard, both snapshot tables, batch rowversion, composite snapshot foreign keys and owner/idempotency indexes. The script was not written or executed.

## Synthetic fixtures and automated coverage

`tests/TestData/sql-discovery/fixture-manifest.json` records the approved stable scenario identifiers. Eight physical CSVs cover positive, warning, negative and boundary cases for both contracts; `SQL-RECON-01`, `SQL-HISTORY-01` and `SQL-RBAC-01` are implemented through deterministic automated tests.

Coverage includes:

- parser/header/value/alias/normalisation, UTF-8/CSV structure, formula/control/credential rejection and safety limits;
- Create/Update/Unchanged/Warning/Reject classification and proposed actions;
- no-mutation preview, duplicate keys, parent matching, protected-field byte preservation and blank optional values;
- missing/stale ETags, required/reused/different idempotency keys, stale fingerprints, rollback and retry state;
- snapshot-per-safe-row, no snapshot for Reject, paging/order and append-only enforcement;
- exact ADR-008 role matrix, multi-role union, raw-row restriction, denied-action audit and feature-disabled handling;
- cross-project direct-object attempts and safe error/media/source-contract responses;
- EF metadata and SQL Server generated-DDL assertions for rowversion, checks, composite FKs and filtered owner-leading indexes;
- complete Phase 1/2 and Slice 1 regression.

## Developer verification

| Command/check | Result |
|---|---|
| Branch/baseline/worktree entry | PASS: exact requested branch and baseline; clean before editing. |
| `dotnet restore LgrTransformationMigration.sln` | PASS: all three projects restored; three retained `NU1900` warnings because the NuGet advisory service index is unreachable. |
| Release build | PASS: 0 errors; only the same three `NU1900` advisory-feed warnings after restore. |
| Complete solution tests | PASS: 110 unit + 98 integration = 208 passed, 0 failed, 0 skipped. |
| Focused SQL CSV/ADR-008 unit lane | PASS: 60 passed, 0 failed, 0 skipped. |
| Focused SQL discovery/import, existing discovery and SQL authorisation integration lane | PASS: 73 passed, 0 failed, 0 skipped. |
| Focused post-audit Slice 2 integration rerun | PASS: 11 passed, 0 failed, 0 skipped. |
| `dotnet-ef 10.0.11 migrations has-pending-model-changes` | PASS: no pending model changes. |
| Idempotent migration SQL generation/inspection | PASS: expected guard, tables, rowversion, composite FKs and index present; generated only, not applied. |
| Frontend lint | PASS. |
| Frontend Next.js 16.3.4 production build | PASS: 16 routes. An initial Windows `EBUSY` from a pre-existing locked `.next/standalone` was retained; the rerun used an isolated ignored `.next` subdirectory and source/config files were restored exactly. |
| Scoped `dotnet format whitespace --verify-no-changes` | PASS after formatting the Slice 2 changes. |
| Migration additive-operation, forbidden-capability and credential/private-key diff scans | PASS: no destructive `Up`, prohibited capability or credential/private-key pattern found. |
| `git diff --check` | PASS; no whitespace errors. Repository line-ending conversion notices only. |
| NuGet/npm vulnerability queries | BLOCKED: outbound advisory endpoints are inaccessible. No dependency changed and no clean connected-feed assertion is made. |

### Resumed verification - 16 September 2026

The interrupted Developer session was resumed on the unchanged baseline and existing uncommitted working tree. No completed implementation was restarted or rewritten. Inspection found no incomplete marker or inconsistent Slice 2 source requiring a code change; the existing implementation and fixtures passed the following fresh checks:

- restore and Release build: PASS, zero errors, with the same three `NU1900` advisory-feed warnings;
- focused SQL CSV/ADR-008 unit lane: 60/60 PASS;
- focused SQL discovery import API lane: 11/11 PASS;
- complete solution suite: 110 unit + 98 integration = 208/208 PASS, zero skipped;
- EF pending-model validation: PASS; no model drift and no database access or migration application;
- idempotent SQL generation in memory: PASS; the Slice 2 guard, both history tables, SQL Server `rowversion`, composite owner foreign keys and idempotency index are present;
- frontend lint: PASS;
- frontend production compilation/type checking/static generation: PASS with 16 routes in an isolated copy using the supported webpack builder. The normal source-tree Turbopack build could not remove a pre-existing locked `.next/standalone` directory (`EBUSY`); no process was terminated and no source/configuration file was changed to bypass the lock;
- Slice 2-only whitespace verification and `git diff --check`: PASS. A full-solution whitespace probe reports pre-existing debt in unchanged files and was not used to expand this slice.

No SQL Server connection was opened, no migration was applied, and no commit, push, merge or deployment was performed.

## Environment, compatibility and residual evidence

- Tests use SQLite only as a supplementary isolated integration provider plus SQL Server model/generated-DDL assertions. The requested no-apply control means no SQL Server migration, transaction, rowversion or query-plan runtime evidence was produced by the Developer.
- The named Test Authority and authorised isolated SQL Server lane remain required for formal independent provider execution, including empty/prior-migration `Up`, concurrency/rollback, constraint/index inspection, plans and any separately authorised disposable `Down`/reapply.
- The worktree is deliberately uncommitted, so Tester evidence cannot yet bind to a candidate commit. A permitted repository owner must create that binding without altering the implementation before independent test.
- Connected NuGet/npm vulnerability evidence remains unavailable. This is retained as an assurance limitation, not an accepted risk.
- Q-02, Q-06, Q-09, production tenancy, external identity, Service Transition, PRB and human release authority remain outside this restricted implementation and are not claimed.

## Hand-off

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_TEST"
  work_item: "PH3-SQL-001-REMAINING-SLICE-2"
  branch: "feature/ph3-sql-remaining-implementation"
  commit: null
  baseline_commit: "a53cf3fd9f49a0f4ee1d9705aa8aca0b16279fd6"
  approved_architecture_commit: "7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a"
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
    - "docs/implementation/PH3_SQL_Slice2_Implementation_Work_Package.md"
    - "src/api/Infrastructure/Migrations/20260915171019_AddSqlDiscoveryImportHistory.cs"
    - "tests/TestData/sql-discovery/fixture-manifest.json"
    - "tests/api.unit/SqlDiscoveryCsvContractTests.cs"
    - "tests/api.integration/SqlDiscoveryImportApiTests.cs"
  evidence:
    - "Release build completed with zero errors."
    - "Complete automated suite: 208 passed, zero failed/skipped."
    - "Focused lanes: 60 unit and 73 integration passed; post-audit Slice 2 rerun 11/11 passed."
    - "EF pending-model validation passed and idempotent SQL was generated/inspected without execution."
    - "Frontend lint and isolated production build passed; source/config restored exactly."
    - "Additive migration, forbidden-capability, credential-pattern and diff checks passed."
  decisions:
    - "Reuse the accepted Slice 1 tenancy, ETag, audit, safe-error and feature-filter patterns."
    - "Keep canonical SQL import routes versioned; legacy Phase 2 routes cannot enumerate or mutate SQL batches."
    - "Enforce append-only typed history in both schema relationships and AppDbContext mutation checks."
  assumptions:
    - "Only repository synthetic identities and approved synthetic fixtures were used."
    - "The no-commit instruction means this working tree is not commit-bound independent evidence."
  risks:
    - "R-02 requires independent tenant/project/permission abuse testing against the eventual candidate commit."
    - "R-09/I-06 SQL Server runtime migration/transaction/concurrency evidence remains for the authorised Tester lane."
    - "R-11 production stack/tenancy decisions remain unresolved and outside this package."
  defects: []
  blockers: []
  approvals:
    - "Commit-bound Product Owner, Architect/TDA, Information Security and DBA/Discovery SME package approvals are evidenced."
    - "Named Test Authority approval is still required before formal independent implementation evidence is accepted."
    - "No production, external identity, customer-data, deployment, merge or release approval is claimed."
  requested_action: "A permitted owner should bind the unchanged working tree to a candidate commit, then the independent Tester should execute the approved Slice 2 matrix and authorised SQL Server provider lane. No merge, deployment, production migration or customer-data action follows."
```
