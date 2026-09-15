# PH3-SQL-001 Slice 1 - Independent Test Evidence Pack

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
    - "Product Owner JP (opathre), 8 September 2026: restricted local POC implementation only."
    - "Solution Architect/TDA PT (PTArchitect), 8 September 2026: ADR-006 and ADR-007 accepted with conditions for the restricted local/non-production POC only."
    - "Information Security NTSecurity (nextgenexamprep-crypto), 8 September 2026: ADR-007 accepted with conditions for the restricted local/non-production POC only."
    - "Solution Architect/TDA PTArchitect, 10 September 2026: ADR-008 and PH3-SQL-ARCH-001 amendment approved for restricted local/non-production implementation and testing only."
    - "Information Security nextgenexamprep-crypto, 10 September 2026: ADR-008 controls approved for the same restricted scope."
    - "Product Owner opathre, 10 September 2026: SQL Inventory role-to-permission mapping confirmed for the same restricted scope."
    - "Authorised Test Authority Ashish Tester (GitHub: ashish50thbirthday-ship-it), 11 September 2026: approved PH3-SQL-001 Slice 1 SQL Server assurance against a new isolated local SQL Server Express database using synthetic data only at commit 284ebacc5633db0da940b206f6eeebf0d61447af - https://github.com/onkarpathre/lgr-transformation-migration/issues/4#issuecomment-5639746843"
    - "Authorised Test Authority Ashish (GitHub: ashish50thbirthday-ship-it), 15 September 2026: phase-level approval for PH3-SQL-001 Phase 1 SQL Server assurance recovery at exact commit 284ebacc5633db0da940b206f6eeebf0d61447af on localhost\\SQLEXPRESS, beginning with exact fresh target LgrTransformationMigration_Ph3Sql_Assurance_20260915_Retry01 - https://github.com/onkarpathre/lgr-transformation-migration/issues/4#issuecomment-5672361217"
```

## Terminal Retry05 PASS reconciliation - 15 September 2026

### Read-only scope, authority and commit binding

This Tester reconciliation inspected only retained repository and result-file
evidence. It did not connect to SQL Server, rerun or dot-source the harness,
execute a test/build/migration command, query or change a database, or modify the
application, schema, migration, harness or any prior result. The exact terminal
artifact is:

- repository-relative path:
  `TestResults/PH3_SQL_Slice1_Assurance_20260915T080434432Z/result.json`;
- artifact-recorded absolute path:
  `C:\Projects\lgr-transformation-migration\TestResults\PH3_SQL_Slice1_Assurance_20260915T080434432Z\result.json`;
- SHA-256:
  `2970498E405ACA1B339947FA59C4D1625C8A4001D860E08FF35A69D5A6B7583D`;
- length: 399,115 bytes; and
- retained file UTC modification time: `2026-09-15T08:05:15.8089146Z`.

The result records execution from `2026-09-15T08:04:34.4928085Z` to
`2026-09-15T08:05:15.7929122Z` under the phase-level Test Authority approval in
GitHub issue comment `5672361217`. Its `repository` object binds both expected
and actual branch to `feature/ph3-sql-implementation` and both expected and
actual `HEAD` to exact application subject commit
`284ebacc5633db0da940b206f6eeebf0d61447af`. Read-only Git reconciliation also
found the current branch and `HEAD` at those exact values, with no `src/` delta
from that commit. Tester-owned harness and evidence work remains uncommitted and
is not represented as application/schema content in the subject commit.

The result's exact target is `localhost\SQLEXPRESS` and the new isolated
synthetic database
`LgrTransformationMigration_Ph3Sql_Assurance_20260915_Retry05`, using Windows
Integrated Authentication. The artifact records no connection string. Q-01 is
closed only for the approved restricted local/non-production POC. Q-02, Q-06
and Q-09 remain open and continue to block their delivery, production/DPIA and
external-identity concerns; they are separable from this exact synthetic local
test hand-off. No production, deployment, release, merge or risk-acceptance
authority is inferred.

### Terminal outcome and every recorded gate

The terminal artifact outcome is `PASS`, with reason `All authorised
PH3-SQL-001 Slice 1 SQL Server and regression assurance checks passed.` All 24
recorded steps are `PASS`; there are zero `FAIL` or `SKIP` steps:

| # | Exact result gate | Reconciled result |
|---:|---|---|
| 1 | Exact SQL target arguments | PASS: exact authorised server and Retry05 database. |
| 2 | Repository branch and HEAD gate | PASS: exact branch and commit before SQL access. |
| 3 | Unicode Form C fixture smoke test | PASS: distinct composed/decomposed fixtures converged under Form C and approved normalization. |
| 4 | Binary provider-parameter preservation smoke test | PASS: binary size-8 provider value remained `System.Byte[]`. |
| 5 | Normalized provider-parameter preservation smoke test | PASS: non-empty canonical Instance and Database keys reached `NVarChar(128)` string parameters. |
| 6 | dotnet-ef version prerequisite | PASS: EF CLI `10.0.11`, exit 0. |
| 7 | EF process environment | PASS: isolated connection value remained process-only and was neither printed nor persisted. |
| 8 | Complete Release build | PASS: exit 0, 0 warnings and 0 errors. |
| 9 | Complete 169-test suite | PASS: 169/169, comprising 82 unit and 87 integration tests, with zero failures/skips. |
| 10 | Focused SQL Inventory tests | PASS: 35/35, comprising 18 unit and 17 integration tests, with zero failures/skips. |
| 11 | Focused ADR-008 tests | PASS: 79/79, comprising 32 unit and 47 integration tests, with zero failures/skips. |
| 12 | EF pending-model-change validation | PASS: no changes since the last migration. |
| 13 | Immediate pre-mutation repository gate | PASS: exact authorised branch and HEAD reconfirmed before the master `DB_ID` check. |
| 14 | SQL Server identity gate | PASS: read-only master connection to SQL Server 16.0.1000.6 Express `SQLEXPRESS` using Integrated Security. |
| 15 | Isolated database non-existence gate | PASS: parameterised master `DB_ID` check confirmed exact Retry05 did not exist. |
| 16 | Apply all EF Core migrations to new isolated database | PASS: exit 0 against the exact Retry05 target. |
| 17 | EF applied/pending migration report | PASS: exact four expected migrations applied. |
| 18 | Deterministic negative-fixture isolation | PASS: globally unique identifiers, dedicated parents/keys and explicit intended collision pairs. |
| 19 | SQL Server relationship and constraint matrix | PASS: valid ownership relationships succeeded; cross-scope, range and normalized duplicate writes were rejected. |
| 20 | Actual SQL Server execution plans | PASS: all three approved plans captured and analysed, with no missing-index recommendation. |
| 21 | Rollback rehearsal to approved previous migration boundary | PASS: exit 0 at `20260824181918_AddDiscoveryImport`. |
| 22 | Reapply all EF Core migrations after rollback | PASS: exit 0. |
| 23 | Final EF applied/pending migration report | PASS: exact four-migration history restored. |
| 24 | Rollback/reapply recovery | PASS: exact four-migration schema restored and retained fully migrated for owner inspection. |

### Provider-runtime and requirements reconciliation

The initial and post-reapply histories both contain exactly:

1. `20260823111854_InitialCreate`;
2. `20260824181918_AddDiscoveryImport`;
3. `20260909164944_AddSqlInventory`; and
4. `20260910082037_AddInternalPrincipalAuditType`.

At the approved rollback boundary, only the first two migrations remained, and
the result records Phase 3 tables, audit columns and alternate keys absent.
Post-reapply schema inspection returned the same evidence shape as the initial
full-migration inspection: 23 SQL Instance columns, 21 SQL Database columns;
the required primary/alternate keys, three composite foreign keys per resource,
one Instance and two Database check constraints, four indexes per resource,
and the `CorrelationId` and `ActorPrincipalType` audit columns. Inspected foreign
keys and check constraints are enabled and trusted. The two active normalized-
name unique indexes are unique, filtered on `IsDeleted = 0`, tenant/project
leading and parent scoped.

The relationship/constraint matrix records one valid relationship path and 11
expected SQL rejections: four cross-customer/cross-project relationship writes,
five range violations and two normalized active-name duplicates. SQL error 547
was returned for every relationship/range violation and 2601 for both duplicate
writes. SQL Server normalization evidence records default alias
`MSSQLSERVER`, converged Form C/invariant-uppercase names and 2601 rejection for
both alias and Unicode duplicates. Rowversion evidence records one update with
the current token and zero with the stale token. The repaired concurrent-create
probe records one inserted row, one SQL 2601 rejection and exactly one matching
persisted active row for `CONCURRENTINSTANCEKEY`.

Three actual plan files are retained below the Retry05 result directory. The
paged Instance and Database plans each record zero scans, two seeks and one key
lookup; the relationship plan records two scans, one seek and no key lookup.
None records a missing-index recommendation. These observations are evidence
for this synthetic dataset and do not assert a production capacity baseline.

| Requirement / assurance reference | Terminal evidence | Result |
|---|---|---|
| SQL-AC-002; F-15; NF-01; NF-02; R-02 | Composite owner FKs, cross-customer/project rejection, parent-scoped filtered uniqueness and concurrent duplicate prevention. | PASS |
| SQL-AC-012; NF-10; D-13 | Release build, complete 169-test regression, focused SQL Inventory and ADR-008 suites against the exact commit. | PASS |
| SQL-AC-013; D-11; I-06 | Named Test Authority, exact target/commit gates, provider migration history, schema inspection, plans and rollback/reapply result. | PASS for restricted local/non-production Slice 1 assurance |
| R-09; I-06 | SQL Server-specific check/FK/index/collation/rowversion/concurrency behaviour proved beyond SQLite/model-only evidence. | PASS |

The earlier same-commit frontend/dependency, authorization/isolation, paging,
audit, safe-error, default-off boundary and product-exclusion evidence remains
unchanged. The terminal run independently reconfirms the Release build, complete
regression, focused SQL Inventory, focused ADR-008 and no-pending-model gates.

### Retained Retry05 database and historical failed evidence

The result records `databaseLeftFullyMigrated=true` and
`databaseAutomaticallyDroppedOrDeleted=false`. Accordingly, exact database
`LgrTransformationMigration_Ph3Sql_Assurance_20260915_Retry05` is recorded as
retained at the full four-migration state for owner inspection. This is a
reconciliation of terminal evidence, not a new live database query. No cleanup
or later database action is recommended or authorised by this hand-off.

All eight earlier `FAIL` artifacts remain present under ignored `TestResults/`
and are retained as historical evidence. This reconciliation does not rewrite
their outcomes or treat a later pass as erasing the earlier failures:

| Historical result path | Recorded failure |
|---|---|
| `TestResults/PH3_SQL_Slice1_Assurance_20260911T204850646Z/result.json` | `Keyword not supported: 'DataSource'.` |
| `TestResults/PH3_SQL_Slice1_Assurance_20260911T212903920Z/result.json` | Outcome `FAIL`; the artifact does not populate `outcomeReason`. |
| `TestResults/PH3_SQL_Slice1_Assurance_20260914T223115630Z/result.json` | `Apply all EF Core migrations to new isolated database exited 1.` |
| `TestResults/PH3_SQL_Slice1_Assurance_20260914T231306037Z/result.json` | `Port below approved range returned SQL error 2601; expected 547.` |
| `TestResults/PH3_SQL_Slice1_Assurance_20260914T235417176Z/result.json` | Retry01: binary rowversion parameter was expanded from `Byte[]` to `Object[]`. |
| `TestResults/PH3_SQL_Slice1_Assurance_20260915T001458829Z/result.json` | Retry02: Unicode Form C normalization did not converge. |
| `TestResults/PH3_SQL_Slice1_Assurance_20260915T003326170Z/result.json` | Retry03: case-insensitive `DEFAULT` alias duplicate unexpectedly succeeded. |
| `TestResults/PH3_SQL_Slice1_Assurance_20260915T073438999Z/result.json` | Retry04: concurrent duplicate test persisted 0 matching active rows instead of exactly one. |

Each historical artifact records
`databaseAutomaticallyDroppedOrDeleted=false`; each retains its original
`databaseLeftFullyMigrated=false` terminal state. The TestResults directories,
prior evidence sections and harness are preserved.

Post-reconciliation repository validation passes: `git diff --check` exits 0
with only the existing non-failing LF-to-CRLF advisories for the two modified
Markdown evidence files. The tracked diff is limited to this Test Evidence Pack
and the Tester status note in the Implementation Work Package; `src/` has no
delta from the exact subject commit, and the pre-existing untracked
`tests/sqlserver/` harness remains present.

### Blocker closure and Tester disposition

`PH3SQL-BLK-001` is **CLOSED for the exact restricted local/non-production
Slice 1 assurance scope at commit
`284ebacc5633db0da940b206f6eeebf0d61447af`**. Named Test Authority approval,
approved Windows-integrated SQL access, exact database non-existence, full
provider-runtime constraint/concurrency/plan evidence and rollback/reapply
recovery are now present. The prior authentication and missing-runtime states
remain historical evidence; they no longer describe the terminal Retry05
outcome. I-06/D-11 is satisfied for this restricted assurance execution.

No application/schema defect or other open Tester blocker remains for this
Slice 1 hand-off. Historical Tester harness defects remain recorded with their
failed results and are closed by the terminal end-to-end pass; they were not
Developer defects. `PH3SQL-BLK-002` remains superseded by the existing
commit-bound dependency assurance. Q-02, Q-06, Q-09, production identity and
tenancy, external customer access, production/customer data, deployment,
Service Transition, PRB and human release approval remain outside Tester
authority and must be assessed by the Quality Manager/human owners for their
applicable gates.

**Tester recommendation: `PASS`.**

**Tester exit state: `READY_FOR_QUALITY_REVIEW`.** This is an evidence hand-off,
not Quality approval, release approval, merge, deployment or production action.

```yaml
handoff:
  from_agent: "tester"
  to_agent: "quality-manager"
  state: "READY_FOR_QUALITY_REVIEW"
  work_item: "PH3-SQL-001-slice-1"
  branch: "feature/ph3-sql-implementation"
  commit: "284ebacc5633db0da940b206f6eeebf0d61447af"
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
      - "Authorised Test Authority Ashish, phase-level RetryNN recovery approval: https://github.com/onkarpathre/lgr-transformation-migration/issues/4#issuecomment-5672361217"
  artefacts:
    - "docs/implementation/PH3_SQL_Slice1_Test_Evidence_Pack.md"
    - "docs/implementation/PH3_SQL_Slice1_Implementation_Work_Package.md (Tester status note only)"
    - "tests/sqlserver/PH3_SQL_Slice1_Assurance.ps1 (preserved; not changed by reconciliation)"
    - "TestResults/PH3_SQL_Slice1_Assurance_20260915T080434432Z/result.json"
    - "TestResults/PH3_SQL_Slice1_Assurance_20260915T080434432Z/execution-plans/paged-sql-instances.sqlplan"
    - "TestResults/PH3_SQL_Slice1_Assurance_20260915T080434432Z/execution-plans/paged-sql-databases.sqlplan"
    - "TestResults/PH3_SQL_Slice1_Assurance_20260915T080434432Z/execution-plans/server-instance-database-relationships.sqlplan"
  evidence:
    - "Terminal result PASS: 24/24 recorded gates passed with zero fail/skip steps."
    - "Exact result path: TestResults/PH3_SQL_Slice1_Assurance_20260915T080434432Z/result.json."
    - "Exact branch and application subject commit matched before SQL access and immediately before mutation."
    - "Release build 0 warnings/errors; complete 169/169, SQL Inventory 35/35 and ADR-008 79/79 suites passed."
    - "SQL identity/non-existence, full migration, schema, constraints, normalization, rowversion, concurrent uniqueness and actual-plan gates passed."
    - "Rollback to 20260824181918_AddDiscoveryImport and reapply to the exact four-migration state passed."
    - "Retry05 database is recorded retained fully migrated and not automatically dropped/deleted."
    - "All eight earlier failed results remain retained and unchanged as historical evidence."
    - "Post-reconciliation git diff --check passes; tracked changes are limited to the two authorised evidence/status documents and src/ has no subject-commit delta."
  decisions:
    - "Close PH3SQL-BLK-001 for the exact restricted local/non-production Slice 1 assurance scope."
    - "Treat prior Retry failures as historical Tester-harness evidence, not application/schema defects."
    - "Advance the complete Slice 1 Tester evidence to independent Quality review; do not infer release approval."
  assumptions:
    - "The retained result truthfully records the authorised execution; this reconciliation did not independently query SQL Server."
    - "Only synthetic local/non-production test identities and data were used, as recorded by the approved harness/result."
  risks:
    - "Q-02, Q-06, Q-09 and production identity/tenancy, deployment, Service Transition and human release gates remain for their named owners and Quality review."
    - "Synthetic execution-plan observations are not a production capacity baseline."
  defects: []
  blockers: []
  approvals:
    - "Restricted Product Owner, Solution Architect/TDA, Information Security and Test Authority approvals are recorded in the work packages and ADRs."
    - "No Quality, PRB, production, merge, deployment, cleanup or release approval is claimed."
  requested_action: "Quality Manager independently validates the exact commit and complete evidence chain and issues the governed Quality Gate Record; no autonomous merge, database cleanup, deployment or production action follows."
```

## Retry05 concurrent duplicate parameter recovery - 15 September 2026

### Tester scope, authority and immutable predecessor

This Tester-only diagnosis remains bound to branch
`feature/ph3-sql-implementation`, exact application `HEAD`
`284ebacc5633db0da940b206f6eeebf0d61447af`, exact server
`localhost\SQLEXPRESS` and synthetic data. The governing traceability is
SQL-AC-002, F-15, NF-01, NF-02, R-09 and I-06. Q-01 is closed only for the
restricted local/non-production POC. Q-02, Q-06 and Q-09 remain open but are
separable because this recovery changes only the Tester-owned harness and this
evidence pack. It makes no delivery, external-identity, production, deployment,
release or Quality-approval claim.

The immutable failed result is
`TestResults/PH3_SQL_Slice1_Assurance_20260915T073438999Z/result.json`. It
records:

- exact database
  `LgrTransformationMigration_Ph3Sql_Assurance_20260915_Retry04`;
- exact branch and application HEAD match;
- outcome `FAIL` with reason `Concurrent duplicate test persisted 0 active
  rows; expected exactly one.`;
- 169/169 complete tests, 35/35 focused SQL Inventory tests and 79/79 focused
  ADR-008 tests passed with zero failures or skips;
- all four expected migrations in the initial full-migration history and the
  expected SQL Instance/Database filtered unique indexes in runtime schema
  inspection;
- rowversion evidence showing one current-token update and zero stale-token
  updates;
- normalization evidence showing canonical `MSSQLSERVER` and Form C `CAFÉ`
  values, while both recorded 2601 messages display a blank final normalized-key
  component; and
- `databaseAutomaticallyDroppedOrDeleted=false` and
  `databaseLeftFullyMigrated=false`. The latter means final rollback/reapply was
  not reached; it does not mean the applied schema or fixtures were removed.

Retry04 and every earlier assurance database and `TestResults` directory remain
excluded and retained. This diagnosis did not connect to SQL Server, query or
modify a database, execute or dot-source the harness, run an EF migration, or
perform cleanup. No application source, migration, EF model, snapshot,
historical result, commit or remote branch was changed.

### Exact Retry04 failure diagnosis

Both `Get-InstanceParameters` and `Get-DatabaseParameters` declared the optional
override as `[AllowNull()][string] $NormalizedOverride = $null`, then selected
the normalizer only when `$null -eq $NormalizedOverride`. Under the authorised
Windows PowerShell 5.1 runtime, an omitted typed string default is coerced to an
empty `System.String`, not retained as null. A standalone no-harness/no-SQL
reproduction returned `IsNull=false`, `RuntimeType=System.String` and
`Length=0`.

Consequently, calls that omitted `-NormalizedOverride` took the override branch
and assigned `''` to `@NormalizedInstanceName` or `@NormalizedName`. That
explains the blank final key component in Retry04's two retained 2601 messages.
It also reconstructs the concurrent failure without database access:

1. Both asynchronous writers received the same owner/server scope and the same
   empty normalized key.
2. Because the final failure occurred after the writer-count assertions, one
   `EndExecuteNonQuery` returned exactly one affected row and the other produced
   an expected 2601/2627 unique-index rejection.
3. The persisted-row query did not use the faulty factory branch. It called
   `ConvertTo-ApprovedInstanceName` directly and searched for exact
   `CONCURRENTINSTANCEKEY`.
4. The inserted row carried `''`, so the correctly scoped count for
   `CONCURRENTINSTANCEKEY` returned zero.

The zero count therefore does not show that SQL Server lost or rolled back the
successful insert. It shows that the harness inserted one unintended empty
system-derived key and then asserted against a different canonical key.

### Connections, transactions, errors and row count

The concurrency orchestration itself remains suitable for the approved physical
uniqueness probe:

- each writer owns a separate exact-database `SqlConnection` and `SqlCommand`;
- both connections are opened through the complete literal database target and
  independently verify `SELECT DB_NAME()` before use;
- no explicit, ambient or shared transaction is created by the harness; each
  direct insert is an autocommit command on its own connection;
- both commands use the same one-second SQL `WAITFOR` gate and are completed
  through matching `BeginExecuteNonQuery`/`EndExecuteNonQuery` calls before the
  count begins;
- SQL exceptions are unwrapped through `InnerException`; non-SQL exceptions are
  rethrown, and only 2601/2627 counts as the required uniqueness rejection;
- the row count uses a third exact-database connection and parameterised
  CustomerId, ProjectId, ServerId, normalized name and active-row predicate;
  and
- all commands/connections are disposed in `finally`. There is no cleanup,
  delete or rollback of the successful concurrent insert.

The previous harness attached concurrent evidence only after the persisted-row
assertion, so Retry04's machine-readable result does not contain the writer
outcomes even though reaching that assertion proves their two preceding exact
assertions passed. The repair records writer outcomes before those assertions
and adds the persisted count before its assertion, preserving future failure
evidence without weakening the gate.

### Architecture/schema comparison and ownership

PH3-SQL-ARCH-001 requires invariant application normalization plus physical
concurrent uniqueness. It defines exact unique index
`UX_SqlInstances_Owner_Server_NormalizedName_Active` on `(CustomerId,
ProjectId, ServerId, NormalizedInstanceName)` with filter `IsDeleted = 0`.
`AppDbContext`, migration `20260909164944_AddSqlInventory`, its designers and
the model snapshot implement that ordered unique key and filter. Retry04 runtime
schema inspection confirms the index is present, unique and filtered. The
Retry04 failure position further proves that the index admitted one writer and
rejected one competing writer as required.

Application normalizers and the passing unit/API suites do not use the
Tester-only nullable override parameter. The harness issued direct SQL and
bypassed application/service normalization. No application or schema deviation
is demonstrated.

**Classification: Tester harness parameter/assertion defect.** Ownership remains
with the Tester. `RETURN_TO_DEVELOPER` is not appropriate, and no application,
schema or migration change is authorised or made.

### Tester-only repair

Only `tests/sqlserver/PH3_SQL_Slice1_Assurance.ps1` and this evidence pack were
changed:

- both unused `NormalizedOverride` parameters and branches were removed;
  parameter factories now always call the approved normalizer;
- a no-connection smoke test requires exact non-empty canonical Instance and
  Database strings to reach `NVarChar(128)` `SqlParameter.Value` before any SQL
  access;
- the concurrent test computes one exact canonical key, confirms that both
  writer provider parameters contain it ordinally, and reuses it for the
  persisted-row count;
- the assertions remain exact: one affected-row insert, one 2601/2627 rejection
  and one matching persisted active row;
- partial writer and persisted-count evidence is attached before a corresponding
  assertion can stop the harness; and
- recovery metadata now names immutable Retry04 and pins only exact
  `LgrTransformationMigration_Ph3Sql_Assurance_20260915_Retry05`.

No Retry05 result directory exists in repository evidence. In accordance with
the no-SQL diagnosis boundary, database non-existence is not inferred. The
existing parameterised `DB_ID` pre-mutation gate must establish it when an
authorised operator performs the one permitted run.

### Static and no-SQL validation

The following checks parsed repository source and, where stated, executed only
selected no-connection function ASTs. They did not run or dot-source the harness
and did not construct or open a `SqlConnection`:

| Check | Result |
|---|---|
| Windows PowerShell 5.1 syntax | PASS: 5.1.26100.9444 parser reports zero errors. |
| Typed-string failure reproduction | PASS: omitted `[string] = $null` becomes a non-null empty `System.String`, exactly selecting the faulty override branch. |
| Normalized provider-parameter smoke | PASS: exact canonical `MSSQLSERVER` and Form C/invariant-uppercase `CAFÉ` reach `NVarChar(128)` provider values as non-empty `System.String`; one PASS step is produced with no connection. |
| Parameter-path audit | PASS: zero `NormalizedOverride` declarations/calls remain; both parameter factories assign normalized keys directly through the approved normalizers. |
| Concurrent assertion integrity | PASS: exactly one insert-success-count assertion (`1`), one expected uniqueness rejection-count assertion (`1`, errors 2601/2627) and one persisted active-row assertion (`1`) remain. Both writer provider keys must equal the single canonical count key ordinally. |
| Connections/transactions/count | PASS: two writer connections/commands plus a separately opened parameterised scalar-count connection; matching Begin/End calls; zero explicit transaction/commit/rollback statements in the concurrent function; deterministic disposal remains. |
| Exact Retry05 pin | PASS: one authoritative `$ExpectedDatabase` assignment, one ordinal complete-value database argument gate, exact Retry04 predecessor database/result assignments, and zero prefix/wildcard/regex database gates. |
| Prohibited operations | PASS: `DROP DATABASE` 0, `DELETE FROM` 0, `TRUNCATE TABLE` 0, login mutation 0, role mutation 0, server-configuration mutation 0, `Remove-Item` 0 and `Clear-Content` 0. The previously approved migration-boundary rollback/reapply logic remains present but was not executed. |
| Historical evidence preservation | PASS: all eight prior `result.json` files remain present under ignored `TestResults/`; Retry04 is 229,327 bytes, retains UTC modification time `2026-09-15T07:35:19.6896468Z`, and has SHA-256 `1CC9C133B7C17AD16F38CE0E17260446E2458617D535E42131CBA7A2C9C3D2F6`. No Retry05 result directory exists. |
| Repository whitespace | PASS: `git diff --check` exits 0; the untracked harness separately has zero trailing-whitespace lines and ends with LF. Existing LF-to-CRLF advisories for the two already modified implementation documents are non-failing. |

**Recovery gate decision: `READY_FOR_AUTHORISED_RERUN` for exact Retry05 only.**
This is not `READY_FOR_QUALITY_REVIEW`; execution-plan and rollback/reapply
evidence after the Retry04 stop remains incomplete until Retry05 finishes.

The exact command for the separately authorised operator, not executed during
this diagnosis, is:

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
  -NoLogo -NoProfile -NonInteractive `
  -File .\tests\sqlserver\PH3_SQL_Slice1_Assurance.ps1 `
  -Server 'localhost\SQLEXPRESS' `
  -Database 'LgrTransformationMigration_Ph3Sql_Assurance_20260915_Retry05'
```

```yaml
handoff:
  from_agent: "tester"
  to_agent: "tester"
  state: "READY_FOR_AUTHORISED_RERUN"
  work_item: "PH3-SQL-001-slice-1-sql-server-runtime-assurance"
  branch: "feature/ph3-sql-implementation"
  commit: "284ebacc5633db0da940b206f6eeebf0d61447af"
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
      - "Authorised Test Authority Ashish, phase-level RetryNN recovery approval: https://github.com/onkarpathre/lgr-transformation-migration/issues/4#issuecomment-5672361217"
  artefacts:
    - "tests/sqlserver/PH3_SQL_Slice1_Assurance.ps1"
    - "docs/implementation/PH3_SQL_Slice1_Test_Evidence_Pack.md"
    - "TestResults/PH3_SQL_Slice1_Assurance_20260915T073438999Z/result.json (immutable Retry04 evidence)"
  evidence:
    - "Retry04 result proves one concurrent affected-row insert and one expected unique rejection completed before the mismatched persisted-row assertion."
    - "Retry04 2601 messages expose blank normalized-key components, matching the Windows PowerShell typed-string default reproduction."
    - "Approved architecture, migration/model source and Retry04 runtime inspection retain the required filtered unique index."
    - "PowerShell syntax, no-connection provider normalization, exact target, assertion integrity, prohibited-operation and whitespace checks pass."
  decisions:
    - "Classify Retry04 as a Tester harness parameter/assertion defect; do not modify application/schema code or raise a Developer defect."
    - "Remove the unused bypass and require exact approved canonical keys at the provider and persisted-row assertion boundaries."
    - "Keep Retry04 and all earlier databases/results immutable."
    - "Advance only to exact Retry05 under the phase-level approval."
  assumptions:
    - "The authorised operator will execute from the repository root within the same approved local synthetic-test boundary."
    - "The existing harness pre-mutation DB_ID gate, not this static review, will establish Retry05 database non-existence."
  risks:
    - "Mandatory SQL Server execution-plan and rollback/reapply evidence after the Retry04 stop remains incomplete until Retry05 finishes."
  defects:
    - "Tester harness defect: omitted nullable typed-string override parameters became empty strings and bypassed canonical normalization."
  blockers: []
  approvals:
    - "Issue comment 5672361217 authorises the next unused RetryNN after the recorded Retry04 failure."
    - "No Quality approval, merge, deployment, cleanup or release approval is claimed."
  requested_action: "Authorised Tester executes the exact Retry05 command once, retains the database and result, then independently assesses the complete evidence without merge, deployment or cleanup."
```

## Retry04 collation-independent DEFAULT/default recovery - 15 September 2026

### Tester scope, authority and immutable predecessor

This Tester-only diagnosis is bound to branch
`feature/ph3-sql-implementation`, exact application `HEAD`
`284ebacc5633db0da940b206f6eeebf0d61447af`, exact server
`localhost\SQLEXPRESS` and synthetic data. The governing traceability remains
SQL-AC-002, F-15, NF-01, NF-02, R-09 and I-06. Q-01 is closed only for the
restricted local/non-production POC. Q-02, Q-06 and Q-09 remain open but are
separable because this recovery changes only a Tester-owned fixture/assertion
and this evidence pack; it makes no delivery, external-identity, production,
deployment or release claim.

The immutable Retry03 result is
`TestResults/PH3_SQL_Slice1_Assurance_20260915T003326170Z/result.json`. It records:

- exact target
  `LgrTransformationMigration_Ph3Sql_Assurance_20260915_Retry03`;
- exact branch and HEAD match;
- outcome `FAIL` with reason
  `Case-insensitive DEFAULT alias duplicate unexpectedly succeeded.`;
- all four expected migrations in the initial full-migration history;
- the inspected SQL Instance filtered unique index as present, unique and
  filtered;
- 17 recorded PASS steps through deterministic negative-fixture isolation;
- `databaseAutomaticallyDroppedOrDeleted=false`; and
- `databaseLeftFullyMigrated=false`, meaning the final rollback/reapply recovery
  step was not reached, not that the applied schema or inserted fixtures were
  reversed.

Retry03 and every earlier assurance database and `TestResults` directory remain
immutable. This diagnosis did not connect to or inspect SQL Server, run or
dot-source the harness, apply or roll back a migration, query or modify any
database, or perform cleanup. No application source, migration, model, snapshot,
commit or remote branch was changed.

### Retry03 fixture-key and filtered-index reconstruction

The failed label abbreviated a DEFAULT-alias case test. The actual Retry03
display fixtures were `default` and `(Default)`. Repository source proves the
two successful direct SQL Instance writes used different primary IDs but the
same complete filtered unique-index scope:

| Field | Baseline row | Attempt row | Equivalent for unique key/filter |
|---|---|---|---|
| `Id` | `93000000-0000-0000-0000-000000000106` | `93000000-0000-0000-0000-000000000207` | No; deliberately distinct PKs and not part of the tested unique key. |
| `CustomerId` | `93000000-0000-0000-0000-000000000001` (`CustomerA`) | Same | Yes. |
| `ProjectId` | `93000000-0000-0000-0000-000000000012` (`ProjectA2`) | Same | Yes. |
| `ServerId` | `93000000-0000-0000-0000-000000000037` (`ServerAlias`) | Same | Yes. |
| Display `InstanceName` | `default` | `(Default)` | Not part of the unique index. |
| `NormalizedInstanceName` | `MSSQLSERVER`, produced by the approved-equivalent harness normalizer | `mssqlserver`, forced by `-NormalizedOverride` | Different only by case; the attempt bypassed the approved canonical invariant. |
| `IsDeleted` | literal `0` in `$InstanceInsertSql` | literal `0` in the same statement | Yes; both satisfy the active-row filter. |

`SqlInstanceId` is not applicable because these are SQL Instance rows. For the
corresponding SQL Database unique index, the parent component would be
`SqlInstanceId` instead of `ServerId`.

The complete relevant schema key is
`UX_SqlInstances_Owner_Server_NormalizedName_Active`: unique
`(CustomerId, ProjectId, ServerId, NormalizedInstanceName)` with model/migration
filter `[IsDeleted] = 0`. Retry03 runtime inspection reports the equivalent SQL
Server filter form `([IsDeleted]=(0))`. The application model, migration and
snapshot each contain the same ordered key, uniqueness and filter exactly once.
The two Retry03 writes therefore both met the filter and differed within the
unique key only in the letter case of a value that application code never emits.

### Architecture, collation and defect ownership

The approved contract does not require SQL Server collation to reject arbitrary
case variants inserted directly into a system-derived normalized column:

- the Product Work Package requires identity uniqueness *after approved
  normalisation* and rejection of duplicate normalized names (business rules
  3-5 and SQL-AC-002);
- PH3-SQL-ARCH-001 defines normalization as trim, Unicode Form C and invariant
  uppercase, with case-insensitive `MSSQLSERVER`, `DEFAULT` and `(DEFAULT)` all
  becoming exact canonical `MSSQLSERVER`;
- the architecture assigns normalized columns in domain/service code for
  deterministic SQL Server/SQLite behaviour, says database collation is not the
  only uniqueness control, and requires a SQL Server lane for
  `collation-independent normalization`;
- `SqlInventoryNormalizer`, `SqlInventoryService`, the unit alias theory and the
  API duplicate test implement and exercise that contract; and
- `AppDbContext`, `20260909164944_AddSqlInventory`, both migration designers and
  `AppDbContextModelSnapshot` contain no `UseCollation`, `HasCollation`,
  `Relational:Collation` or `collation:` schema annotation. The nullable
  `SqlDatabase.Collation` business property is discovery metadata, not a schema
  collation configuration.

Retry03 queried the current database collation and separately asserted a
case-insensitive literal comparison, but its result envelope leaves
`normalizationEvidence.sqlServer` null because the function failed before it
could return that evidence. The exact collation name is therefore not recorded
in immutable Retry03 evidence. Resolving the apparent provider behaviour would
require prohibited database access and is unnecessary for the approved
contract: the lowercase `mssqlserver` override is not an application-normalized
value.

**Classification: Tester fixture/assertion defect.** The probe bypassed the
normalizer and treated environment-dependent database collation as a required
schema guarantee. No application/schema defect is demonstrated and no Developer
defect is raised. `RETURN_TO_DEVELOPER` is not appropriate.

### Tester-only repair and retained case-insensitivity assurance

Only `tests/sqlserver/PH3_SQL_Slice1_Assurance.ps1` was repaired:

- the display pair is now exact `DEFAULT` / `default`, proving ordinally
  different inputs that differ only by case;
- pre-SQL fixture validation requires both values to become the exact ordinal
  canonical value `MSSQLSERVER`;
- the second SQL Instance write no longer supplies `-NormalizedOverride`; both
  direct rows therefore carry the exact approved canonical normalized key;
- the unique-index rejection remains mandatory with SQL error 2601/2627 and
  exact index-name evidence, so the test still proves case-insensitive business
  identity plus physical duplicate prevention without relying on collation;
- database collation and its observed literal case-comparison behaviour remain
  evidence fields, but a case-sensitive environment is no longer failed merely
  for being case-sensitive; and
- recovery metadata now names the Retry03 failure/result and pins the sole next
  target to exact
  `LgrTransformationMigration_Ph3Sql_Assurance_20260915_Retry04`.

No Retry04 result directory exists in repository evidence. SQL Server database
non-existence is deliberately not inferred; the harness must prove that at its
existing pre-mutation gate when an authorised operator runs it.

### Static validation only

The following checks read repository files and parsed the harness; none opened a
SQL connection or executed the harness:

| Check | Result |
|---|---|
| Windows PowerShell 5.1 syntax | PASS: 5.1.26100.9444 parser reports zero errors. |
| Exact Retry04 pin | PASS: one exact `$ExpectedDatabase` assignment, one ordinal complete-value argument gate, exact Retry03 predecessor database/result assignments once each, and zero prefix/wildcard/regex database gates. |
| DEFAULT/default fixture semantics | PASS: inputs are ordinally different, equal under `OrdinalIgnoreCase`, and both normalize to exact ordinal `MSSQLSERVER`; the attempt has zero `-NormalizedOverride` arguments. |
| Fixture-key equivalence | PASS: both writes use `CustomerA + ProjectA2 + ServerAlias`; their resolved GUIDs are identical for `CustomerId`, `ProjectId` and `ServerId`; `$InstanceInsertSql` fixes `IsDeleted` to `0`. The PK IDs alone differ. |
| Filtered-index applicability | PASS: migration, model and snapshot each specify exactly one unique `(CustomerId, ProjectId, ServerId, NormalizedInstanceName)` block with `[IsDeleted] = 0`; Retry03 runtime evidence reports the same four columns and equivalent `([IsDeleted]=(0))` filter. |
| Collation traceability | PASS: zero deterministic database/column collation annotations across `AppDbContext`, the SQL Inventory migration, both current designers and the model snapshot; architecture requires application-canonical, collation-independent normalization. |
| Prohibited-operation source counts | PASS: `DROP DATABASE` 0, `DELETE FROM` 0, `TRUNCATE TABLE` 0, login mutation 0, role mutation 0, server-configuration mutation 0, `Remove-Item` 0 and `Clear-Content` 0. The previously approved rollback/reapply logic remains present but was not executed. |
| Repository whitespace | PASS: `git diff --check` exits 0; line-ending conversion advisories only. |

**Recovery gate decision: `READY_FOR_AUTHORISED_RERUN` for exact Retry04 only.**
This is not `READY_FOR_QUALITY_REVIEW`; runtime normalization, concurrent-create,
execution-plan and rollback/reapply evidence after the Retry03 stop remains
incomplete.

The exact command for the separately authorised operator, not executed during
this diagnosis, is:

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
  -NoLogo -NoProfile -NonInteractive `
  -File .\tests\sqlserver\PH3_SQL_Slice1_Assurance.ps1 `
  -Server 'localhost\SQLEXPRESS' `
  -Database 'LgrTransformationMigration_Ph3Sql_Assurance_20260915_Retry04'
```

```yaml
handoff:
  from_agent: "tester"
  to_agent: "tester"
  state: "READY_FOR_AUTHORISED_RERUN"
  work_item: "PH3-SQL-001-slice-1-sql-server-runtime-assurance"
  branch: "feature/ph3-sql-implementation"
  commit: "284ebacc5633db0da940b206f6eeebf0d61447af"
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
      - "Authorised Test Authority Ashish, phase-level RetryNN recovery approval: https://github.com/onkarpathre/lgr-transformation-migration/issues/4#issuecomment-5672361217"
  artefacts:
    - "tests/sqlserver/PH3_SQL_Slice1_Assurance.ps1"
    - "docs/implementation/PH3_SQL_Slice1_Test_Evidence_Pack.md"
    - "TestResults/PH3_SQL_Slice1_Assurance_20260915T003326170Z/result.json (immutable Retry03 evidence)"
  evidence:
    - "Retry03 result, fixture arguments, runtime index inspection and migration history reconstruct the exact failed probe without database access."
    - "Both Retry03 active rows used the same CustomerId, ProjectId and ServerId; forced normalized values MSSQLSERVER/mssqlserver differed only by case."
    - "Approved architecture and application code require exact invariant-uppercase canonical values and do not pin a schema collation."
    - "PowerShell syntax, exact target, fixture equivalence, filtered-index applicability, collation traceability, prohibited-operation counts and git diff checks pass."
  decisions:
    - "Classify Retry03 as a Tester fixture/assertion defect; do not modify application/schema code or raise a Developer defect."
    - "Retain a collation-independent DEFAULT/default case-insensitivity test using exact canonical MSSQLSERVER values."
    - "Keep Retry03 and all earlier databases/results immutable."
    - "Advance only to exact Retry04 under the phase-level approval."
  assumptions:
    - "The authorised operator will run from the repository root within the same approved local synthetic-test boundary."
    - "The existing harness pre-mutation gate, not this static review, will establish Retry04 database non-existence."
  risks:
    - "Mandatory SQL Server evidence after the Retry03 stop remains incomplete until Retry04 finishes."
  defects:
    - "Tester harness defect: a forced lowercase system-derived normalized value asserted an unapproved database-collation guarantee."
  blockers: []
  approvals:
    - "Issue comment 5672361217 authorises the next unused RetryNN after the recorded Retry03 failure."
    - "No Quality approval, merge, deployment, cleanup or release approval is claimed."
  requested_action: "Authorised Tester executes the exact Retry04 command once, retains the database and result, then independently assesses the complete evidence without merge, deployment or cleanup."
```

## Retry03 Unicode Form C harness recovery - 15 September 2026

### Retry02 result, authority and retained state

This Tester-only diagnosis remains bound to branch
`feature/ph3-sql-implementation`, exact application `HEAD`
`284ebacc5633db0da940b206f6eeebf0d61447af`, exact server
`localhost\SQLEXPRESS` and synthetic data. The Product/Architecture packages
retain `SQL-AC-002`, F-15, NF-01, NF-02 and R-09 traceability. Q-01 is closed
only for this restricted local/non-production POC; Q-02, Q-06 and Q-09 remain
open but are separable because this correction changes only a Tester-owned
synthetic fixture and assertion. It makes no delivery, production-data,
external-identity, tenancy-topology, deployment or release claim.

The failed Retry02 result was inspected only at
`TestResults/PH3_SQL_Slice1_Assurance_20260915T001458829Z/result.json`. It is
retained unchanged and records:

- exact branch and HEAD gates passed;
- exact target
  `LgrTransformationMigration_Ph3Sql_Assurance_20260915_Retry02`;
- 169/169 complete tests, 35/35 focused SQL Inventory tests and 79/79 focused
  ADR-008 tests passed with no failures or skips;
- all four migrations applied, migration history and schema inspection passed,
  and deterministic fixture isolation passed;
- relationship/range/filtered-uniqueness execution completed before the
  normalization function, and rowversion evidence records an eight-byte token
  change from `00000000000007D1` to `00000000000007E6`, one current-token
  update and zero stale-token updates;
- outcome `FAIL` with reason `Unicode Form C normalization did not converge
  composed and decomposed names.`; and
- `normalizationEvidence=null`, `databaseLeftFullyMigrated=false` and
  `databaseAutomaticallyDroppedOrDeleted=false`. The false fully-migrated flag
  means the final rollback/reapply recovery step was not reached; it is not
  evidence that the applied migrations were reversed.

The Retry02 database exists and must remain untouched. This diagnosis did not
connect to or inspect SQL Server, run the harness, apply or roll back a
migration, query or modify any database, or open any other historical result.
The excluded 20260911, Retry01 and Retry02 databases, and all historical
`TestResults` evidence, were not modified or deleted. No application source,
application test, migration, schema, commit or remote branch was changed.

Phase-level Authorised Test Authority comment `5672361217` permits the next
unused RetryNN target after a recorded predecessor failure. Retry02 is the
recorded failed predecessor, so exact Retry03 is within that authority after a
Tester-only repair and static validation.

### Contract and application assessment

The approved architecture states that normalized identity is trimmed Unicode
Form C followed by invariant uppercase, with normalized values used for
deterministic comparison and uniqueness. `SQL-AC-002` requires duplicate
normalized SQL Instance/Database names to be rejected.

The application meets this contract:

- `SqlInventoryNormalizer.RequiredDisplayValue` performs `Trim().Normalize(
  NormalizationForm.FormC)`;
- `NormalizeInstanceName` and `NormalizeDatabaseName` apply invariant uppercase
  after that helper, and the instance path retains the approved default-alias
  mapping;
- `SqlInventoryService` recomputes the normalized key on both instance and
  database writes; and
- `SqlInventoryRulesTests.Business_names_are_trimmed_normalized_to_form_c_and_case_folded`
  supplies `U+0065 U+0301` and expects the composed uppercase result. The
  integration uniqueness test separately proves normalized duplicate rejection
  within the correct parent. Both are within the 169/169 passing Retry02 suite.

No application normalization defect is demonstrated, so no Developer defect is
raised and `RETURN_TO_DEVELOPER` is not appropriate.

### Exact Windows PowerShell 5.1 failure diagnosis

The harness is UTF-8 without a BOM. Its failed composed fixture was authored as
a raw non-ASCII source literal whose bytes around the intended character were
`C3 A9`. Windows PowerShell 5.1.26100.9444 treated the no-BOM file as the legacy
code page, so the two bytes became two characters instead of U+00E9. A
parse-only 5.1 inspection and isolated expression reproduction recorded:

| Value/stage | Exact code points |
|---|---|
| Failed composed fixture before normalization | `U+0043 U+0061 U+0066 U+00C3 U+00A9` |
| Failed decomposed fixture before normalization | `U+0043 U+0061 U+0066 U+0065 U+0301` |
| Failed composed fixture after Form C and invariant uppercase | `U+0043 U+0041 U+0046 U+00C3 U+00A9` |
| Failed decomposed fixture after Form C and invariant uppercase | `U+0043 U+0041 U+0046 U+00C9` |

This exactly reproduces the recorded non-convergence without invoking SQL or
application code.

The requested alternative-cause checks are resolved as follows:

- the harness did not use a literal backslash-`u` escape; PowerShell does not
  interpret C#-style `\uNNNN` string escapes, and static inspection finds zero
  such harness sequences;
- the decomposed fixture used a single `[char] 0x0301` interpolation and was not
  an expanded character array; its exact runtime suffix was U+0065 followed by
  U+0301;
- the harness helpers called Form C before invariant uppercase and before the
  failed comparison; comparison was not applied to the unnormalized values;
  and
- PowerShell `-ceq`/`-cne` is culture-aware, so it is unsuitable for proving
  that canonically equivalent inputs are initially different. The repaired
  smoke and substantive convergence assertion use
  `StringComparison.Ordinal`.

Classification: **Tester harness fixture/assertion defect** caused by a raw
non-ASCII literal in a no-BOM script executed by Windows PowerShell 5.1, with an
additional culture-aware comparison weakness. The application implementation
is not the owner.

### Tester-only repair

Only `tests/sqlserver/PH3_SQL_Slice1_Assurance.ps1` was changed:

- `New-UnicodeFormCFixture` now constructs the composed character from the
  ASCII-only expression `[char] 0x00E9` and the decomposed suffix from explicit
  `[char] 0x0065` and `[char] 0x0301` expressions; no raw non-ASCII source
  literal, literal `\u` sequence or `[char[]]` expansion is used;
- `Assert-UnicodeFormCFixture` runs after the exact branch/HEAD gate and before
  the first SQL access. It requires the values to be ordinally different before
  normalization, requires ordinal convergence after Form C, requires
  convergence after the complete approved normalization and records exact code
  points at every stage;
- the SQL collation/normalization test uses the same fixture factory. Its
  substantive normalization assertion and database duplicate-rejection probe
  remain present, with the convergence comparison strengthened to ordinal;
- `normalizationEvidence.fixtureSmoke` is populated before SQL access and
  `normalizationEvidence.sqlServer` remains null until the runtime SQL probe
  succeeds; and
- recovery metadata now identifies Retry02 and its immutable result as the
  failed predecessor and pins the sole authorised target to
  `LgrTransformationMigration_Ph3Sql_Assurance_20260915_Retry03`.

The repaired fixture produces:

| Value/stage | Exact code points |
|---|---|
| Composed before Form C | `U+0043 U+0061 U+0066 U+00E9` |
| Decomposed before Form C | `U+0043 U+0061 U+0066 U+0065 U+0301` |
| Composed after Form C | `U+0043 U+0061 U+0066 U+00E9` |
| Decomposed after Form C | `U+0043 U+0061 U+0066 U+00E9` |
| Composed after approved Form C + invariant-uppercase normalization | `U+0043 U+0041 U+0046 U+00C9` |
| Decomposed after approved Form C + invariant-uppercase normalization | `U+0043 U+0041 U+0046 U+00C9` |

### Static and no-SQL validation

Validation extracted and executed only the relevant function ASTs in child
Windows PowerShell. It did not dot-source or run the harness and did not
construct or open a SQL connection.

| Check | Result |
|---|---|
| PowerShell 5.1 syntax | PASS: Windows PowerShell 5.1.26100.9444 reports zero parse errors. |
| No-SQL Unicode smoke | PASS: composed includes U+00E9; decomposed includes U+0065 followed by U+0301; inputs are ordinally different; both converge to U+00E9 after Form C and U+00C9 after approved invariant uppercase. One PASS step was produced. |
| Unsafe Unicode construction audit | PASS: raw U+00E9 source characters 0, literal `\uNNNN` sequences 0 and Unicode `[char[]]` fixture constructions 0. |
| Fixture uniqueness | PASS: 50 identifiers are globally unique; 4 single-constraint Instance names, 5 single-constraint Database names and 14 negative-test parents are distinct; only the 3 existing deliberate normalized collision pairs share their tested keys. |
| Exact Retry03 recovery gate | PASS: one authoritative Retry03 database assignment, one ordinal case-sensitive complete-value argument gate, Retry02 and the exact Retry02 result recorded once as predecessor, and zero database prefix/wildcard/regex gates. |
| Prohibited operations | PASS: `DROP DATABASE` 0, `DELETE FROM` 0, `TRUNCATE TABLE` 0, login mutation 0, role mutation 0, server-configuration mutation 0, `Remove-Item` 0 and `Clear-Content` 0. The approved rollback/reapply rehearsal remains present but was not executed. |
| Git-ignore coverage | PASS: `TestResults/` covers the retained Retry02 result path and a representative future Retry03 result path. No historical result content was opened for this check. |
| Repository whitespace | PASS: harness trailing-whitespace lines 0, final LF present and `git diff --check` exits 0. Existing LF-to-CRLF advisory warnings for the two already modified implementation documents are non-failing. |

**Recovery gate decision: `READY_FOR_AUTHORISED_RERUN` for exact Retry03 only.**
This is not `READY_FOR_QUALITY_REVIEW`; SQL Server normalization, subsequent
concurrent-create, execution-plan and rollback/reapply evidence remains
incomplete until the authorised full harness run finishes and its result is
independently assessed.

The exact child-Windows-PowerShell Retry03 command, to be launched from the
repository root by the authorised operator, is:

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
  -NoLogo -NoProfile -NonInteractive `
  -File .\tests\sqlserver\PH3_SQL_Slice1_Assurance.ps1 `
  -Server 'localhost\SQLEXPRESS' `
  -Database 'LgrTransformationMigration_Ph3Sql_Assurance_20260915_Retry03'
```

```yaml
handoff:
  from_agent: "tester"
  to_agent: "tester"
  state: "READY_FOR_AUTHORISED_RERUN"
  work_item: "PH3-SQL-001-slice-1-sql-server-runtime-assurance"
  branch: "feature/ph3-sql-implementation"
  commit: "284ebacc5633db0da940b206f6eeebf0d61447af"
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
      - "Authorised Test Authority Ashish, phase-level RetryNN recovery approval: https://github.com/onkarpathre/lgr-transformation-migration/issues/4#issuecomment-5672361217"
  artefacts:
    - "tests/sqlserver/PH3_SQL_Slice1_Assurance.ps1"
    - "docs/implementation/PH3_SQL_Slice1_Test_Evidence_Pack.md"
    - "TestResults/PH3_SQL_Slice1_Assurance_20260915T001458829Z/result.json (retained Retry02 evidence; unchanged)"
  evidence:
    - "Retry02 result proves the failure occurred at the Unicode convergence assertion after the earlier recorded gates and checks."
    - "Application Form C implementation and existing passing unit/integration coverage satisfy the approved normalization contract."
    - "Windows PowerShell 5.1 parse-only reproduction records the failed fixture as U+00C3 U+00A9 instead of U+00E9."
    - "No-SQL smoke records exact before/after code points, ordinal initial difference and Form C/approved-normalization convergence."
    - "Exact Retry03 gate, fixture isolation, prohibited-operation counts, ignore coverage and whitespace checks pass."
  decisions:
    - "Classify the failure as a Tester harness defect; do not modify application code or raise a Developer defect."
    - "Preserve the substantive runtime normalization/duplicate assertion and strengthen string comparison to ordinal."
    - "Retain all existing assurance databases and historical TestResults evidence untouched."
    - "Advance only the complete pinned target from failed Retry02 to unused Retry03 under the phase-level approval."
  assumptions:
    - "The authorised operator will execute from the repository root under the same approved local synthetic-test boundary."
  risks:
    - "Mandatory post-normalization SQL Server runtime evidence remains incomplete until Retry03 finishes."
  defects:
    - "Tester harness defect: Windows PowerShell 5.1 decoded a raw U+00E9 UTF-8 literal in a no-BOM script as U+00C3 U+00A9; culture-aware comparison was also unsuitable for the initial-difference proof."
  blockers: []
  approvals:
    - "Issue comment 5672361217 authorises Retry03 after the recorded Retry02 failure."
    - "No Quality approval, merge, deployment, cleanup or release approval is claimed."
  requested_action: "Authorised Tester executes the exact child-Windows-PowerShell Retry03 command once, retains the database and result, then independently assesses the complete evidence without merge, deployment or cleanup."
```

## Retry02 rowversion-parameter recovery - 15 September 2026

### Failed predecessor, authority and retained state

This Tester-only recovery remains bound to branch
`feature/ph3-sql-implementation`, exact application `HEAD`
`284ebacc5633db0da940b206f6eeebf0d61447af`, exact server
`localhost\SQLEXPRESS` and synthetic data. Phase-level Authorised Test Authority
comment `5672361217` permits the next unused RetryNN target only after the
preceding attempt fails.

The failed predecessor is recorded unchanged at
`TestResults/PH3_SQL_Slice1_Assurance_20260914T235417176Z/result.json`. Its
machine-readable evidence identifies exact database
`LgrTransformationMigration_Ph3Sql_Assurance_20260915_Retry01` and outcome
`FAIL`. Retry01 passed the branch/HEAD, SQL Server identity and exact database
non-existence gates; created the database; applied all four expected
migrations; verified the applied migration history and initial schema; passed
deterministic fixture isolation; and completed the relationship, range and
normalized-duplicate constraint probes. The next operation, the rowversion
optimistic-concurrency update, failed with:

`Failed to convert parameter value from a Object[] to a Byte[].`

No rowversion/concurrency PASS, normalization/collation PASS,
concurrent-create PASS, execution-plan evidence or rollback/reapply PASS is
claimed from Retry01. Its `databaseLeftFullyMigrated=false` value records that
the final recovery path was not reached; it is not evidence that migrations
were reversed. `databaseAutomaticallyDroppedOrDeleted=false` confirms the
harness did not remove it. The Retry01 database must remain untouched and
retained.

The older
`LgrTransformationMigration_Ph3Sql_Assurance_20260911` database likewise
remains excluded and retained. This recovery did not connect to, inspect,
modify, clean, roll back or delete either existing database. No SQL Server
connection was opened, no harness run or migration command was executed, and
no application code, migration, historical result, commit or remote branch was
changed.

### Exact failure analysis and Tester harness repair

The failed operation is the first conditional rowversion update in
`Invoke-RowVersionTest`. The provider returned the `rowversion` scalar as
`System.Byte[]`. Two PowerShell enumeration hazards existed:

1. `Invoke-SqlScalar` returned the byte array through an ordinary pipeline
   expression, which enumerated it as objects before the typed caller rebuilt a
   byte array.
2. More decisively, `Add-SqlParameters` assigned `SqlParameter.Value` from an
   inline `if` expression. Windows PowerShell enumerated the `System.Byte[]`
   stored in the parameter specification and materialized `System.Object[]`
   immediately before provider assignment. An isolated reproduction produced
   `System.Object[]` on this exact form, matching the Retry01 exception.

The assurance harness itself uses `System.Data.SqlClient.SqlParameter`; the EF
design-time child process separately uses `Microsoft.Data.SqlClient`. The
failure occurred on the Tester harness parameter path, so no application or EF
provider change was warranted.

Only `tests/sqlserver/PH3_SQL_Slice1_Assurance.ps1` was repaired:

- scalar and row readers now detect provider-returned `System.Byte[]`, retain a
  typed local and use a unary-comma scalar return where PowerShell would
  otherwise enumerate the bytes;
- binary parameter specifications accept only `System.Byte[]` or null for
  `Binary`, `VarBinary` and `Image` types;
- provider values are assigned in explicit branches, with a typed
  `System.Byte[]` local and no inline conditional expression or array wrapper;
- both rowversion write paths remain exactly `SqlDbType.Binary`, size 8;
- a no-connection provider-parameter smoke test now executes after the exact
  branch/HEAD gate and before any SQL access. It requires `Value.GetType()` to
  equal `System.Byte[]`, `SqlDbType.Binary`, size 8 and byte-for-byte equality;
- the rowversion test still requires an eight-byte initial/current token,
  exactly one current-token update, a changed token, and zero rows from the
  stale-token update. No assertion was skipped or weakened.

The binary-path audit found no other binary input parameters. The two business
paths are `@RowVersion` and `@StaleRowVersion`; both pass through the repaired
specification and assignment helpers. The generic query-row path was also
repaired because paged SQL Instance/Database plan queries read `RowVersion`
columns even though those values are not subsequently used as parameters.

### Static and non-SQL validation

Validation used child Windows PowerShell for syntax and the in-memory
`System.Data.SqlClient.SqlParameter` smoke test. It parsed/executed only the
relevant function ASTs; it did not dot-source or execute the harness and did
not construct or open a SQL connection.

| Check | Result |
|---|---|
| PowerShell syntax | PASS: Windows PowerShell reports zero parse errors. |
| Binary provider parameter | PASS: `Value` is exactly `System.Byte[]`, `SqlDbType` is `Binary`, size is 8 and the bytes are unchanged; it is not `System.Object[]`. |
| Binary/rowversion path audit | PASS: two business binary parameters, both `Binary(8)`; scalar and row reads preserve `System.Byte[]`; current-update=1, token-changed and stale-update=0 assertions remain present once each. |
| Exact Retry02 target | PASS: one authoritative database assignment to `LgrTransformationMigration_Ph3Sql_Assurance_20260915_Retry02`, one ordinal case-sensitive `-cne` argument gate and zero wildcard/prefix/regex database gates. |
| Failed predecessor record | PASS: Retry01 database, `FAIL` outcome, immutable result path, retention flag and Retry02 target are recorded in the result envelope under `recovery`. |
| Fixture uniqueness | PASS: 50 identifiers, 50 distinct GUIDs and 50/50 referenced IDs resolve; 25/25 fixture-name references resolve. |
| Constraint isolation | PASS: 4 single-constraint Instance names, 5 single-constraint Database names and 14 negative-test parents are distinct; only the 3 deliberate normalized-collision pairs share their tested key. |
| Prohibited operations | PASS: `DROP DATABASE` 0, `DELETE FROM` 0, `TRUNCATE TABLE` 0, login mutation 0, role mutation 0, server-configuration mutation 0, `Remove-Item` 0 and `Clear-Content` 0. The approved rollback/reapply rehearsal remains present but was not executed. |
| Git-ignore coverage | PASS: all five historical `result.json` files remain present and ignored; `TestResults/` also covers a representative future Retry02 result path. |
| Repository whitespace | PASS: `git diff --check` reports no whitespace errors; the untracked harness separately has zero trailing-whitespace findings. |

The harness is pinned to the single exact fresh target
`LgrTransformationMigration_Ph3Sql_Assurance_20260915_Retry02`. Retry01 is the
failed predecessor required by the phase-level approval; neither a RetryNN
prefix nor an operator-selected alternative target is accepted.

**Recovery gate decision: `READY_FOR_AUTHORISED_RERUN` for exact Retry02 only.**
This is not `READY_FOR_QUALITY_REVIEW`; SQL Server runtime evidence after the
Retry01 failure remains incomplete until the authorised full harness run
finishes and its new result is independently assessed.

The exact child-Windows-PowerShell Retry02 command, to be launched from the
repository root by the authorised operator, is:

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
  -NoLogo -NoProfile -NonInteractive `
  -File .\tests\sqlserver\PH3_SQL_Slice1_Assurance.ps1 `
  -Server 'localhost\SQLEXPRESS' `
  -Database 'LgrTransformationMigration_Ph3Sql_Assurance_20260915_Retry02'
```

```yaml
handoff:
  from_agent: "tester"
  to_agent: "tester"
  state: "READY_FOR_AUTHORISED_RERUN"
  work_item: "PH3-SQL-001-slice-1-sql-server-runtime-assurance"
  branch: "feature/ph3-sql-implementation"
  commit: "284ebacc5633db0da940b206f6eeebf0d61447af"
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
      - "Authorised Test Authority Ashish, phase-level RetryNN recovery approval: https://github.com/onkarpathre/lgr-transformation-migration/issues/4#issuecomment-5672361217"
  artefacts:
    - "tests/sqlserver/PH3_SQL_Slice1_Assurance.ps1"
    - "docs/implementation/PH3_SQL_Slice1_Test_Evidence_Pack.md"
    - "TestResults/PH3_SQL_Slice1_Assurance_20260914T235417176Z/result.json (retained predecessor; unchanged)"
  evidence:
    - "Windows PowerShell syntax PASS."
    - "No-connection provider-parameter smoke PASS: System.Byte[], Binary, size 8, bytes unchanged."
    - "Exact Retry02 target, fixtures, constraint isolation, prohibited-operation counts, ignore coverage and whitespace checks PASS."
  decisions:
    - "Repair only the Tester-owned binary transport path; do not change application code, migrations or the rowversion assertion."
    - "Retain Retry01 untouched and advance the one exact target to Retry02 under the phase-level approval."
  assumptions:
    - "The authorised operator will execute from the repository root under the same approved local synthetic-test boundary."
  risks:
    - "Mandatory provider-runtime evidence remains incomplete until Retry02 finishes."
  defects:
    - "Tester harness defect: PowerShell inline conditional assignment expanded System.Byte[] to System.Object[]; repaired and non-SQL smoke-tested."
  blockers: []
  approvals:
    - "Issue comment 5672361217 authorises Retry02 after the recorded Retry01 failure."
  requested_action: "Authorised Tester executes the exact child-Windows-PowerShell Retry02 command once, retains the database and result, then assesses the complete evidence without merge, deployment or cleanup."
```

## Prior SQL Server constraint-fixture recovery - 14-15 September 2026

### Test subject, authority boundary and retained state

This Tester-only recovery remains bound to branch
`feature/ph3-sql-implementation` and application `HEAD`
`284ebacc5633db0da940b206f6eeebf0d61447af`. The traceability above remains
applicable. The work is separable from Q-02, Q-06 and Q-09 because it changes
only synthetic, non-production test-fixture design and makes no product,
identity, tenancy, privacy or release claim. No application code, EF migration,
schema definition or application test was changed.

The failed evidence is retained unchanged at
`TestResults/PH3_SQL_Slice1_Assurance_20260914T231306037Z/result.json`. It
records the following facts:

- exact branch and HEAD gates passed;
- the authorised target was
  `localhost\SQLEXPRESS/LgrTransformationMigration_Ph3Sql_Assurance_20260911`;
- the database non-existence gate passed, all four expected migrations were
  applied, the exact migration history and Phase 3 schema inspection passed,
  and deterministic synthetic parents plus the valid baseline SQL Instance and
  SQL Database were inserted;
- the harness stopped in the port-below-range negative probe with
  `Port below approved range returned SQL error 2601; expected 547.`;
- no relationship/constraint-matrix PASS, rowversion, normalization,
  concurrency, execution-plan or rollback/reapply result was produced;
- `databaseLeftFullyMigrated` is `false` because the final recovery path was
  not reached, not evidence that the applied migrations were reversed;
- `databaseAutomaticallyDroppedOrDeleted` is `false`.

The existing database
`LgrTransformationMigration_Ph3Sql_Assurance_20260911` is therefore an
existing, partially exercised evidence database. This recovery did not connect
to, inspect, modify, clean, roll back or delete it. It must remain untouched
unless separately authorised.

### Exact 2601 analysis

The retained schema inspection proves that the only unique non-constraint
index on `dbo.SqlInstances` is
`UX_SqlInstances_Owner_Server_NormalizedName_Active`, over
`(CustomerId, ProjectId, ServerId, NormalizedInstanceName)` with filter
`IsDeleted = 0`. SQL error 2601 therefore identifies that filtered unique
index, rather than `CK_SqlInstances_Port`, as the enforcement path observed
by the harness.

The exact authored port-below fixture at the failed HEAD was:

| Field | Attempted value |
|---|---|
| `Id` | `93000000-0000-0000-0000-000000000203` |
| `CustomerId` | `93000000-0000-0000-0000-000000000001` |
| `ProjectId` | `93000000-0000-0000-0000-000000000011` |
| `ServerId` | `93000000-0000-0000-0000-000000000021` |
| `InstanceName` / `NormalizedInstanceName` | `INVALIDPORT0` / `INVALIDPORT0` |
| `Port` | `0` |
| `IsDeleted` | `0` |

The only earlier active SQL Instance intentionally authored on that same
customer/project/server parent was the valid baseline key
`(93000000-0000-0000-0000-000000000001,
93000000-0000-0000-0000-000000000011,
93000000-0000-0000-0000-000000000021, PH3SQL01)`. The attempted key ended in
`INVALIDPORT0`, so the harness source did **not** intentionally reuse that
active unique key.

The failed result retained the error number but not the underlying
`SqlException.Message` or SQL Server's reported duplicate-key tuple. It is
therefore not possible to claim from retained evidence that
`INVALIDPORT0` matched a particular persisted row, and no database inspection
is authorised to reconstruct it. The defensible conclusion is that error 2601
won the observed enforcement path, the intended error 547 and
`CK_SqlInstances_Port` were not verified, and the failed probe remains
`FAIL`. Error 2601 has not been added to the accepted port-test outcomes.

### Tester harness data-design repair

Only `tests/sqlserver/PH3_SQL_Slice1_Assurance.ps1` fixture data was changed.
The approved server/database constants, expected SQL error numbers and expected
constraint/index fragments remain unchanged.

- All 50 synthetic identifiers are now globally unique.
- Every single-constraint SQL Instance negative probe has a unique ID,
  normalized instance name and dedicated Server parent.
- Every single-constraint SQL Database negative probe has a unique ID,
  normalized database name and dedicated valid SQL Instance parent, whose
  Server parent is also dedicated.
- Server hostnames and documentation-range IP addresses are unique.
- The normalized SQL Instance and SQL Database uniqueness tests now have
  dedicated baseline rows and parents; only each test's attempted row shares
  its intended normalized active key.
- The later DEFAULT-alias, Unicode Form-C and concurrent-create probes use
  dedicated parents. Their same-key values remain deliberate because filtered
  uniqueness is the exact constraint under test.
- A fail-closed pre-seed fixture audit checks global GUID uniqueness,
  single-constraint normalized-name uniqueness, dedicated parent uniqueness
  and the three literal normalization collision pairs before any synthetic row
  is inserted. Unicode convergence remains checked immediately before its
  insert pair, and concurrency uses one central deterministic name for its
  deliberate pair.

The complete negative-test collision audit is:

| Probe | Attempt ID(s) | Dedicated parent | Only intended rejection |
|---|---|---|---|
| Cross-customer Server -> Instance | `...0201` | Server `...0024` | `FK_SqlInstances_Servers_CustomerId_ProjectId_ServerId` / 547 |
| Cross-project Server -> Instance | `...0202` | Server `...0025` | `FK_SqlInstances_Servers_CustomerId_ProjectId_ServerId` / 547 |
| Port below range | `...0203` | Server `...0026` | `CK_SqlInstances_Port` / 547 |
| Port above range | `...0204` | Server `...0027` | `CK_SqlInstances_Port` / 547 |
| Cross-customer Instance -> Database | `...0301` | Instance `...0102` on Server `...0028` | `FK_SqlDatabases_SqlInstances_CustomerId_ProjectId_SqlInstanceId` / 547 |
| Cross-project Instance -> Database | `...0302` | Instance `...0103` on Server `...0029` | `FK_SqlDatabases_SqlInstances_CustomerId_ProjectId_SqlInstanceId` / 547 |
| Negative database size | `...0303` | Instance `...0104` on Server `...0030` | `CK_SqlDatabases_SizeMb` / 547 |
| Compatibility below range | `...0304` | Instance `...0105` on Server `...0031` | `CK_SqlDatabases_CompatibilityLevel` / 547 |
| Compatibility above range | `...0305` | Instance `...0107` on Server `...0032` | `CK_SqlDatabases_CompatibilityLevel` / 547 |
| Normalized Instance duplicate | baseline `...0110`, attempt `...0205` | Server `...0033` | `UX_SqlInstances_Owner_Server_NormalizedName_Active` / 2601 or 2627 |
| Normalized Database duplicate | baseline `...0403`, attempt `...0306` | Instance `...0111` on Server `...0034` | `UX_SqlDatabases_Owner_Instance_NormalizedName_Active` / 2601 or 2627 |
| DEFAULT alias duplicate | baseline `...0106`, attempt `...0207` | Server `...0037` | `UX_SqlInstances_Owner_Server_NormalizedName_Active` / 2601 or 2627 |
| Unicode Form-C Database duplicate | baseline `...0402`, attempt `...0307` | Instance `...0112` on Server `...0035` | `UX_SqlDatabases_Owner_Instance_NormalizedName_Active` / 2601 or 2627 |
| Concurrent Instance duplicate | attempts `...0108` and `...0109` | Server `...0036` | exactly one insert and one filtered-unique rejection |

Every abbreviated value has the common prefix
`93000000-0000-0000-0000-00000000`; the harness retains the full GUID
literals.

The repaired port-below fixture is now isolated as:
`Id=93000000-0000-0000-0000-000000000203`,
`CustomerId=93000000-0000-0000-0000-000000000001`,
`ProjectId=93000000-0000-0000-0000-000000000011`,
`ServerId=93000000-0000-0000-0000-000000000026`,
`NormalizedInstanceName=NEG_CHECK_PORT_BELOW`, `Port=0`. That dedicated
Server has no valid SQL Instance baseline, so a future rejection must still be
SQL error 547 naming `CK_SqlInstances_Port`; error 2601 remains a failure.

### Phase-level Test Authority approval operationalisation

The GitHub approval comment was read through the connected GitHub issue record
and validated as comment `5672361217` by `ashish50thbirthday-ship-it`. It names
Ashish as Authorised Test Authority, is dated 15 September 2026, and authorises
Tester-only harness corrections and repeated full assurance reruns for exact
application commit `284ebacc5633db0da940b206f6eeebf0d61447af` on exact SQL
instance `localhost\SQLEXPRESS`, using synthetic data only.

The first authorised fresh target is exactly
`LgrTransformationMigration_Ph3Sql_Assurance_20260915_Retry01`. The harness is
now pinned to that complete literal value. Its argument gate uses ordinal,
case-sensitive equality (`-cne`) against the one pinned constant; no RetryNN
prefix or unrestricted pattern match is accepted.

The phase-level approval also permits a subsequent RetryNN only after the
preceding attempt fails, only when that numbered target has never been used,
and only after the Tester deliberately changes the harness constant from one
complete database name to the next complete database name and repeats static
validation. It does not allow an operator to supply any database merely because
its name shares the approved prefix.

The existing
`LgrTransformationMigration_Ph3Sql_Assurance_20260911` database remains
explicitly excluded. It was not connected to, inspected, modified, rolled back,
cleaned or deleted during this operationalisation. All four historical failed
result paths remain present and ignored; their contents were not opened,
modified or deleted.

No SQL command, SQL Server connection, harness execution, migration apply,
commit or push was performed. Static validation on 15 September 2026 records:

| Check | Result |
|---|---|
| PowerShell parser | PASS: zero parse errors. |
| Fixture identifiers | PASS: 50 assignments, 50 distinct GUIDs, zero duplicates; all 50 referenced IDs resolve. |
| Negative-test isolation audit | PASS: all 25 referenced fixture names resolve; 4 single-constraint Instance names, 5 single-constraint Database names and 14 dedicated negative-test parents are distinct; the 3 literal intentional uniqueness pairs alone share their tested key; both port probes remain isolated to error 547 and `CK_SqlInstances_Port`. |
| Exact target constants | PASS: server is exactly `localhost\SQLEXPRESS`, database is exactly `LgrTransformationMigration_Ph3Sql_Assurance_20260915_Retry01`, branch is exactly `feature/ph3-sql-implementation`, and HEAD is exactly `284ebacc5633db0da940b206f6eeebf0d61447af`; each occurs as one authoritative assignment. |
| Exact-target gate | PASS: one server and one database `-cne` argument gate compare against the complete constants; zero database prefix, wildcard or regex gates. |
| Prohibited operations | PASS: `DROP DATABASE` 0, `DELETE FROM` 0, `TRUNCATE TABLE` 0, login mutation 0, role mutation 0, server-configuration mutation 0, `Remove-Item` 0 and `Clear-Content` 0. The existing approved rollback/reapply rehearsal remains present but was not executed. |
| Existing failed evidence | PASS: all four failed result paths remain present and covered by `TestResults/`; none was opened, modified or deleted. |
| Git-ignore coverage | PASS: `TestResults/` covers all four retained results and a representative future Retry01 result path. |
| Repository whitespace | PASS: `git diff --check` reports no whitespace errors. |

At that recovery point, the Tester state was `READY_FOR_AUTHORISED_RERUN` for
the exact Retry01 execution only. It was not `READY_FOR_QUALITY_REVIEW`:
mandatory SQL Server
constraint, rowversion, normalization, concurrency, execution-plan and
rollback/reapply evidence remains incomplete until the authorised harness run
produces a terminal evidence pack.

The then-authorised child-Windows-PowerShell command was:

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
  -NoLogo -NoProfile -NonInteractive `
  -File .\tests\sqlserver\PH3_SQL_Slice1_Assurance.ps1 `
  -Server 'localhost\SQLEXPRESS' `
  -Database 'LgrTransformationMigration_Ph3Sql_Assurance_20260915_Retry01'
```

That Retry01 command is now historical and withdrawn after the retained failed
run. It must not be executed again or used to access the existing Retry01
database.

Any historical rerun command below that names
`LgrTransformationMigration_Ph3Sql_Assurance_20260911` is retained only as
evidence of the earlier authorised procedure and is now withdrawn. It must not
be executed or used to access that existing database.

## SQL Server assurance harness recovery - 11-14 September 2026

This Tester-only recovery is bound to branch `feature/ph3-sql-implementation`
and exact application `HEAD` `284ebacc5633db0da940b206f6eeebf0d61447af`.
All three failed machine-readable results remain intact and ignored:

- `TestResults/PH3_SQL_Slice1_Assurance_20260911T204850646Z/result.json`
  records `FAIL` with `Keyword not supported: 'DataSource'.` Exact target
  arguments, branch/HEAD and the pinned dotnet-ef version gate passed first.
  The failure occurred while constructing the connection string, before any SQL
  connection was opened and before the mandatory parameterised `DB_ID`
  non-existence check.
- `TestResults/PH3_SQL_Slice1_Assurance_20260911T212903920Z/result.json`
  records `FAIL` with an empty `outcomeReason`. The corrected connection builder
  had already passed, as had the exact target, branch/HEAD, dotnet-ef and EF
  process-environment gates. The supplied recovery failure was `Cannot bind
  argument to parameter 'Message' because it is an empty string.` at the first
  native command's blank output line, still before SQL access or the mandatory
  database non-existence gate.
- `TestResults/PH3_SQL_Slice1_Assurance_20260914T223115630Z/result.json`
  records `FAIL` with the meaningful `outcomeReason` `Apply all EF Core
  migrations to new isolated database exited 1.` Exact target, branch, HEAD,
  pinned dotnet-ef, regression, identity and parameterised `DB_ID` non-existence
  gates passed. EF then rejected the harness-supplied process-environment value
  before database creation with `Keyword not supported: 'asynchronous
  processing'.` The result records that no database was left migrated and that
  none was automatically dropped or deleted.

The first repair remains intact. The strongly typed
`System.Data.SqlClient.SqlConnectionStringBuilder` uses the canonical supported
keys `Data Source`, `Initial Catalog`, `Integrated Security`, `Encrypt`,
`TrustServerCertificate`, `Application Name` and `Connect Timeout`. No
unsupported `DataSource` setter remains. The latest failure was Tester-owned:
the harness's `-EnableAsync` path added the legacy `Asynchronous Processing`
keyword to the value assigned to `ConnectionStrings__LgrDatabase`; the API's
design-time startup path passed that value directly to EF Core's SQL Server
provider, which uses `Microsoft.Data.SqlClient`. Application configuration does
not contain or add the keyword, so no application code or configuration was
changed. The unsupported keyword and its switch path have now been removed
without replacement. The approved server, database, Windows Integrated
Authentication, encryption/trust settings and all pre-mutation gates are
unchanged. The connection string is still neither emitted nor persisted.

Recovery inspection found that the interrupted logging repair was complete in
the harness but had not been recorded here. `Invoke-NativeCommand` retains all
captured native output in the step evidence, records the native exit code, and
passes only non-blank lines to `Write-Evidence`. The logging boundary also
normalises null, empty and whitespace-only messages. `Set-HarnessFailure`
retains the caught exception message and uses its exception type as a safe
fallback when no message exists; prefix-only harness failures retain the
original exception text in a non-empty fallback. The final result-writing path
normalises `outcomeReason` again, so a failed `result.json` cannot contain an
empty reason.

Recovery validation on 14 September 2026 passed: PowerShell syntax has zero
parse errors; an isolated non-SQL child-Windows-PowerShell smoke test exercised
blank and whitespace-only native output plus non-empty output at exit codes 0
and 7, producing two step records, both non-empty payloads, both exit codes and
zero blank logger messages; empty-message and prefix-only exception cases both
produced non-empty fallback reasons. An additional isolated net10 offline smoke
test constructed the final harness EF value and parsed it successfully with
`Microsoft.Data.SqlClient.SqlConnectionStringBuilder` without constructing or
opening a connection and without displaying the value. It confirmed the five
required target/security properties and zero `Asynchronous Processing`
occurrences in both the active factory and generated value. Exact server,
database, branch and HEAD assignments, argument gates, immediate pre-mutation
branch/HEAD gate and parameterised `DB_ID` non-existence gate remain present
once each. Prohibited database-drop, login, role and server-configuration
operation counts remain zero. All three retained result files and future
`TestResults` paths remain ignored, and `git diff --check` reports no whitespace
error.

Per the recovery instruction then in force, the complete harness was not
executed, SQL Server was not accessed, no migration was applied, and no database
or application code was changed. SQL Server runtime assurance therefore
remained `BLOCKED`/not run after those harness repairs; no provider-runtime PASS
was claimed. The following child-Windows-PowerShell command is retained only as
historical procedure evidence and is now withdrawn because its 20260911 target
exists and is explicitly excluded by the later phase-level approval:

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
  -NoLogo -NoProfile -NonInteractive `
  -File .\tests\sqlserver\PH3_SQL_Slice1_Assurance.ps1 `
  -Server 'localhost\SQLEXPRESS' `
  -Database 'LgrTransformationMigration_Ph3Sql_Assurance_20260911'
```

## Prior SQL Server runtime assurance attempt - 11 September 2026

This is the prior Tester-owned, commit-bound assurance record for exact repository commit
284ebacc5633db0da940b206f6eeebf0d61447af. It supersedes the SQL-runtime and
test-authority blocker status in the earlier sections only to the extent recorded below.
The frontend-remediation and ADR-008 evidence for their named commits remains historical,
valid evidence and is not represented as re-execution of SQL Server runtime checks.

### Test authority, role and boundaries

- Tester role: independent Tester Agent under AGENTS.md.
- Approval evidence: https://github.com/onkarpathre/lgr-transformation-migration/issues/4#issuecomment-5639746843.
- Named approver: Ashish Tester, Authorised Test Authority, 11 September 2026.
- Approved repository commit: 284ebacc5633db0da940b206f6eeebf0d61447af.
- Approved SQL target: localhost\SQLEXPRESS only.
- Approved database name: LgrTransformationMigration_Ph3Sql_Assurance_20260911.
- Approved operations: create a new isolated database; apply and roll back EF migrations; test constraints, rowversion, collation, concurrent uniqueness and query plans; use synthetic identities/data only.
- Exclusions retained: no existing/shared/customer/production database, real customer data, deployment, merge, release or production-migration action.

### Entry-gate and environment evidence

| Check | Result |
|---|---|
| Branch / HEAD / clean worktree at entry, 2026-09-11T19:52:33.1123293Z | PASS: feature/ph3-sql-implementation; exact HEAD 284ebacc5633db0da940b206f6eeebf0d61447af; tracked and untracked status empty. |
| Commit ancestry | PASS: application commit dc31d60303525da7727d92acba455007fd24ef9a and security-remediation commit fdf85a24844e9d0b060a6dbdedb09cbb832a2812 are ancestors of the tested HEAD. |
| Required artefacts | PASS: AGENTS.md, PH3-SQL-ARCH-001, ADR-006, ADR-007, ADR-008, the Implementation Work Package, this Test Evidence Pack and the linked approval comment were read before SQL access. |
| Server target resolution | PASS for target selection: the literal DataSource is exactly localhost\SQLEXPRESS; localhost resolves only to loopback addresses ::1 and 127.0.0.1; Windows service MSSQL$SQLEXPRESS is Running; registry instance is MSSQL16.SQLEXPRESS. |
| Installed SQL Server metadata, 2026-09-11T20:00:12.9858860Z | Registry/service evidence reports Microsoft SQL Server 2022 Express Edition, version/patch level 16.0.1000.6. SERVERPROPERTY confirmation was not possible because authentication failed before a query executed. |
| Tool/runtime versions, 2026-09-11T20:02:28.0631200Z | .NET SDK 10.0.400; dotnet-ef 10.0.11; Node.js v24.18.0; npm 11.16.0; Next.js build output 16.3.4. |
| Connection-string handling | PASS: the isolated application connection string was set only in the child process environment as ConnectionStrings__LgrDatabase, parsed back to the exact approved DataSource/database, never printed, and restored/removed when each process ended. Repository configuration was not changed. |

### Database existence precondition and blocker

The mandatory non-existence check could not complete. The decisive read-only,
parameterised DB_ID check against master started at
2026-09-11T20:01:20.0008661Z and ended at
2026-09-11T20:01:20.2247085Z. System.Data.SqlClient failed while opening the
connection with "The target principal name is incorrect. Cannot generate SSPI
context." QueryExecuted was false, so DB_ID was not evaluated and the database's
existence remains unknown.

A separate read-only sqlcmd probe against the same exact target and master ran
from 2026-09-11T20:02:10.3561587Z to
2026-09-11T20:02:10.3890949Z. It exited 1 before executing SELECT because ODBC
Driver 17 reported encryption/SSL credential negotiation failure.

The EF migration-list command used the isolated target through the process
environment from 2026-09-11T20:01:33.4819643Z to
2026-09-11T20:01:35.5791120Z. It enumerated the four compiled migration IDs but
reported that it could not access the database or determine applied/pending
status because the same SSPI error occurred. The CLI returned 0 after continuing
without database information; that exit code is not treated as a database pass.

Because database non-existence could not be proven, the Tester stopped all
database mutation. No CREATE DATABASE, migration Up/Down, seed, INSERT, UPDATE,
DELETE, rollback, reapply, query-plan collection or cleanup command was issued.
No SQL statement executed against master or any user database.

### Requested SQL Server assurance matrix

| Requested assurance | Current result |
|---|---|
| Create the new isolated database by applying every EF migration | NOT RUN: non-existence/authentication precondition failed. No database was created. |
| Verify __EFMigrationsHistory | NOT RUN: database access was unavailable. |
| Expected compiled migrations | PARTIAL static evidence only: 20260823111854_InitialCreate, 20260824181918_AddDiscoveryImport, 20260909164944_AddSqlInventory and 20260910082037_AddInternalPrincipalAuditType were enumerated; applied status was not determined. |
| EF pending model changes | PASS offline at 2026-09-11T19:58:50.8594071Z to 2026-09-11T19:58:53.0868970Z: no changes have been made to the model since the last migration; exit 0. This is model/snapshot evidence, not database migration-state evidence. |
| Tenant-leading composite foreign keys and check constraints | NOT RUN on SQL Server. Existing API/SQLite/static tests remain supplementary only. |
| Filtered active-name uniqueness | NOT RUN on SQL Server. |
| Rowversion optimistic concurrency | NOT RUN on SQL Server. Existing API/SQLite opaque-version tests do not prove provider rowversion behaviour. |
| Approved case-insensitive collation behaviour | NOT RUN. Database collation was not queried or changed. |
| Concurrent conflicting create | NOT RUN on SQL Server; no conflicting operation result can be claimed. |
| Cross-customer and cross-project FK/reference rejection | NOT RUN on SQL Server. Focused API/SQLite suites passed, but database defence-in-depth evidence remains absent. |
| SQL Inventory execution plans | NOT RUN; no actual plans, table/index scans, key lookups or missing-index recommendations were available to inspect. Query-plan finding: unavailable due the connection blocker, not a clean plan result. |
| Approved rollback and migration reapply | NOT RUN; no migration was applied or reversed. Recovery was not verified. |
| Database retained for owner inspection | No assurance database was created by this run. The Tester did not delete or modify any database. |

### Commands, timestamps and executable results

| Command | UTC interval on 11 September 2026 | Result |
|---|---|---|
| dotnet restore LgrTransformationMigration.sln | 19:52:42.3896906-19:52:49.7239411 | PASS, exit 0. All three projects restored; three NU1900 warnings because NuGet vulnerability metadata was inaccessible. |
| dotnet build LgrTransformationMigration.sln --configuration Release --no-restore | 19:52:56.0464266-19:53:04.2913828 | PASS, exit 0; 0 errors, 3 NU1900 warnings. |
| dotnet test LgrTransformationMigration.sln --configuration Release --no-build --no-restore | 19:54:00.1820125-19:55:40.5583569 | PASS, exit 0: 82 unit + 87 integration = 169 passed, 0 failed, 0 skipped. |
| Focused SqlInventoryRulesTests or SqlInventoryApiTests | 19:56:01.4168378-19:56:41.3372727 | PASS, exit 0: 18 unit + 17 integration = 35 passed, 0 failed, 0 skipped. |
| Focused IdentityAuthorizationTests or SqlInventoryAuthorizationTests | 19:56:50.1346539-19:58:31.3535502 | PASS, exit 0: 32 unit + 47 integration = 79 passed, 0 failed, 0 skipped. |
| dotnet-ef migrations has-pending-model-changes with isolated process environment | 19:58:50.8594071-19:58:53.0868970 | PASS, exit 0: no pending model changes; two NU1900 warnings; no database mutation. |
| npm.cmd run lint | 19:59:01.9170976-19:59:29.8794800 | PASS, exit 0. |
| npm.cmd run build | 19:59:37.0199174-19:59:47.1219455 | PASS, exit 0; Next.js 16.3.4 compiled and generated 16/16 routes. The generated next-env.d.ts delta was restored to the exact committed content. |
| Parameterised DB_ID existence check against master | 20:01:20.0008661-20:01:20.2247085 | BLOCKED, exit 1 before query execution: SSPI context failure. |
| dotnet-ef migrations list with isolated process environment | 20:01:33.4819643-20:01:35.5791120 | PARTIAL only: four compiled IDs listed; database applied/pending status unavailable due SSPI; CLI exit 0 is not a database pass. |
| sqlcmd read-only SELECT probe against master | 20:02:10.3561587-20:02:10.3890949 | BLOCKED, exit 1 before query execution: ODBC encryption/SSL credential negotiation failure. |

Focused totals are repeat executions and are not added to the complete-suite total.

### Defects, residual risks, cleanup and gate

- No new application defect was found in the executable build, model or automated test scope.
- PH3SQL-BLK-001 remains open but is narrowed: named Test Authority approval is now evidenced; the exact local SQL Server target is installed and running; however the Tester process identity cannot authenticate, so database non-existence and all provider-runtime evidence remain unavailable.
- R-09/I-06 SQL Server migration, constraint, rowversion, collation, concurrency, cross-scope database enforcement and query-plan evidence remain unresolved.
- The three NU1900 build warnings are retained. The prior owner-supplied connected vulnerability evidence remains bound to commit 284ebacc through its committed evidence record; this run did not refresh connected advisory data.
- Identity Platform/deployed membership, Q-06/Q-09, production identity/tenancy, customer-data use, Service Transition, deployment and release decisions remain outside this assurance.
- Cleanup recommendation: do not delete any database automatically. No database was created by this run. An authorised owner should first connect under an approved Windows identity and repeat the read-only DB_ID check. If the named database already exists, stop without modifying or deleting it as required; otherwise grant/execute the assurance through an identity authorised only for this isolated test database, then retain it for inspection until the owner separately approves cleanup.

**Executable non-SQL result:** PASS.

**SQL Server runtime result:** BLOCKED; no provider-runtime pass is claimed.

**Gate decision:** BLOCKED. This is not RETURN_TO_DEVELOPER because no
implementation defect was demonstrated; it is not READY_FOR_QUALITY_REVIEW
because mandatory provider evidence is absent.

```yaml
handoff:
  from_agent: "tester"
  to_agent: "quality-manager"
  state: "BLOCKED"
  work_item: "PH3-SQL-001-slice-1-sql-server-runtime-assurance"
  branch: "feature/ph3-sql-implementation"
  commit: "284ebacc5633db0da940b206f6eeebf0d61447af"
  application_commit: "dc31d60303525da7727d92acba455007fd24ef9a"
  security_remediation_commit: "fdf85a24844e9d0b060a6dbdedb09cbb832a2812"
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
      - "Authorised Test Authority Ashish Tester, 11 September 2026, exact commit and isolated localhost SQL Express assurance scope: https://github.com/onkarpathre/lgr-transformation-migration/issues/4#issuecomment-5639746843"
      - "Restricted local/non-production Product Owner, Solution Architect/TDA and Information Security approvals recorded in ADR-006, ADR-007, ADR-008 and PH3-SQL-ARCH-001."
  artefacts:
    - "docs/implementation/PH3_SQL_Slice1_Test_Evidence_Pack.md (uncommitted Tester update)"
    - "docs/implementation/PH3_SQL_Slice1_Implementation_Work_Package.md (uncommitted Tester status note)"
  evidence:
    - "Entry branch/HEAD/clean status and implementation/security-remediation ancestry pass."
    - "Exact approved target localhost\\SQLEXPRESS; running MSSQL$SQLEXPRESS service; registry installation metadata: SQL Server 2022 Express 16.0.1000.6."
    - "Database existence is unknown because both managed and ODBC clients failed before query execution; no database was created or modified."
    - "Compiled migrations: InitialCreate, AddDiscoveryImport, AddSqlInventory and AddInternalPrincipalAuditType; applied/pending database status unavailable."
    - "Offline EF pending-model validation passes."
    - "Release build passes with 0 errors and 3 NU1900 warnings; complete suite 169/169."
    - "Focused SQL Inventory 35/35; focused ADR-008 authorization 79/79."
    - "Frontend lint/build pass; 16/16 routes generated; generated source delta restored."
  decisions:
    - "Stop before every database mutation because mandatory non-existence validation did not complete."
    - "Do not treat EF migration-list exit 0 as applied/pending evidence after EF explicitly reported database access failure."
    - "Do not infer SQL Server constraint, rowversion, collation, concurrency, cross-scope or query-plan results from SQLite/API/static evidence."
  assumptions:
    - "All executed application tests used repository synthetic identities and isolated test fixtures."
    - "Registry/service metadata accurately identifies the installed local SQLEXPRESS instance; SQL SERVERPROPERTY confirmation remains unavailable."
  risks:
    - "R-09/I-06 mandatory provider-runtime assurance remains absent."
    - "R-11 wider production technology/tenancy approval remains unresolved."
  defects: []
  blockers:
    - "PH3SQL-BLK-001: the Tester process identity cannot establish Windows integrated authentication to localhost\\SQLEXPRESS; database non-existence and provider-runtime evidence cannot be established."
    - "No __EFMigrationsHistory, constraint, rowversion, collation, concurrent-create, cross-scope FK, execution-plan or rollback/reapply result exists."
  approvals:
    - "Authorised Test Authority approval is commit-bound and evidenced by the issue-comment URL."
    - "No database cleanup, Quality approval, merge, deployment, production or release approval is claimed."
  requested_action: "Quality Manager should retain BLOCKED for this exact commit. The environment owner must provide an approved Windows identity able to connect only to localhost\\SQLEXPRESS and the named isolated database context, then return the unchanged commit and these uncommitted evidence files to the Tester to repeat the non-existence check and execute the complete provider-runtime matrix. No merge, deployment, release or automatic database cleanup follows."
```

## Frontend security-remediation independent retest - 11 September 2026

This section is the current commit-bound evidence for the frontend dependency remediation at `fdf85a24844e9d0b060a6dbdedb09cbb832a2812`. The 10 September implementation retest and all 9 September evidence below are preserved as historical evidence. They remain authoritative for their named commits but are not presented as execution against this remediation commit.

### Test control, scope and entry gates

- Tester role: independent Tester Agent under `AGENTS.md`.
- Test branch and exact immutable commit: `feature/ph3-sql-implementation` at `fdf85a24844e9d0b060a6dbdedb09cbb832a2812`.
- Previous Tester-evidence commit: `d97f044c2212b1ae1559dc878dc08f58e181a6b8`; verified as the direct parent and an ancestor of the tested commit.
- Application implementation commit: `dc31d60303525da7727d92acba455007fd24ef9a`; verified as an ancestor of the tested commit.
- Architecture baseline: `7f2d6aa12c7f1cffd3d6d9215955bac0b8eca600`; verified as an ancestor of the tested commit.
- Entry state: branch and `HEAD` matched exactly, and tracked and untracked status were empty before testing.
- Exact delta review: only `src/web/package.json`, `src/web/package-lock.json` and the Developer-owned `docs/implementation/PH3_SQL_Slice1_Implementation_Work_Package.md` changed from `d97f044...` to `fdf85a2...` (501 insertions, 208 deletions). No application code, test, migration, identity/RBAC, environment configuration or `next-env.d.ts` source changed.
- Approved test scope: restricted local/non-production POC only under ADR-006 and ADR-008. Repository synthetic identities/data and isolated SQLite integration fixtures only were used. No migration was applied, no shared or production database was accessed, and no commit, push, merge, deployment or approval action occurred.
- Environment observed for this retest: Windows; .NET SDK `10.0.400`; .NET runtime/test host `10.0.11`; pinned global EF CLI `10.0.11`; Node.js `v24.18.0`; npm `11.16.0`; Next.js `16.3.4`.

### Package and lockfile verification

The version-3 lockfile, installed package graph and direct manifest pins agree:

| Package / lock path | Exact tested version | Independent result |
|---|---:|---|
| `next` / `node_modules/next` | `16.3.4` | PASS: direct manifest, lock root, installed graph and Next CLI agree. |
| `eslint-config-next` / `node_modules/eslint-config-next` | `16.3.4` | PASS: aligned exactly with Next.js. |
| `react` / `node_modules/react` | `19.2.8` | PASS: unchanged from `d97f044...`. |
| `react-dom` / `node_modules/react-dom` | `19.2.8` | PASS: unchanged from `d97f044...`. |
| `node_modules/brace-expansion` | `1.1.18` | PASS: ESLint/minimatch 3 path resolves to the patched 1.x line. |
| `node_modules/@typescript-eslint/typescript-estree/node_modules/brace-expansion` | `5.0.9` | PASS: TypeScript ESLint/minimatch 10 path resolves to the patched 5.x line. |
| `node_modules/js-yaml` | `4.3.2` | PASS. |
| `node_modules/nanoid` | `3.3.19` | PASS. |
| `node_modules/postcss` | `8.5.23` | PASS. |
| `node_modules/sharp` | `0.35.4` | PASS. |

The package delta contains no `.npmrc`, `allowScripts`, `npm approve-scripts`, `audit fix --force` or `--force` change. No `allowScripts` key exists in either package file. The owner-run npm debug record for the remediation contains `argv "audit" "fix"` without `--force` and exit 0; the subsequent connected record contains `argv "audit" "--audit-level" "high"`, an empty audit report and exit 0. The `unrs-resolver` allow-scripts warning did not result in repository approval or configuration.

### Manually supplied connected evidence

Onkar supplied the following results as commands manually executed in normal PowerShell against exact commit `fdf85a24844e9d0b060a6dbdedb09cbb832a2812`:

| Manually executed check | Supplied result |
|---|---|
| `dotnet list .\LgrTransformationMigration.sln package --vulnerable --include-transitive` | PASS: NuGet source `https://api.nuget.org/v3/index.json`; no vulnerable packages in `LgrTransformationMigration.Api`, `LgrTransformationMigration.Api.UnitTests` or `LgrTransformationMigration.Api.IntegrationTests`; exit code 0. |
| `npm audit --audit-level=high` | PASS: 0 vulnerabilities, exit code 0. |
| Frontend lint | PASS: exit code 0. |
| Next.js production build | PASS: Next.js `16.3.4`, exit code 0. |
| Production route generation | PASS: all 16 routes generated. |

This table is manually supplied connected evidence, not a claim that Codex executed those commands. For the connected .NET vulnerability scan, Onkar also verified that `HEAD` remained `fdf85a24844e9d0b060a6dbdedb09cbb832a2812` and the working tree contained only the pre-existing uncommitted Test Evidence Pack update. Codex independently reran lint and production build below. Codex inspected the local npm debug command records but did not independently execute either connected vulnerability scan. The earlier Codex-run `NU1900` warnings are retained below as environment-specific history; the subsequent connected normal-PowerShell scan passed.

### Independent commands and results

| Command/check | Current-run result |
|---|---|
| Branch, exact `HEAD`, clean tracked/untracked status | PASS at entry: `feature/ph3-sql-implementation`, exact `fdf85a24844e9d0b060a6dbdedb09cbb832a2812`, empty status. |
| Commit ancestry and `d97f044...fdf85a2` changed-file/diff review | PASS: previous evidence, application and architecture commits are ancestors; the delta is limited to the two package files and Developer evidence. |
| Manifest/lock/installed graph assertions and targeted offline `npm ls ... --all --offline` | PASS, exit 0; all exact versions in the package table resolve without invalid/extraneous entries. |
| Next CLI version | PASS: `Next.js v16.3.4`. |
| Repository/package audit-fix and install-script approval inspection | PASS: no forced audit-fix or `allowScripts`/`approve-scripts` repository change. The owner-run debug `argv` records contain no `--force`. |
| `npm.cmd run lint` | PASS, exit 0. |
| `npm.cmd run build` | PASS, exit 0; Next.js `16.3.4` compiled successfully and generated 16/16 routes. |
| `dotnet build LgrTransformationMigration.sln --configuration Release` | PASS, exit 0; 0 errors. Six `NU1900` warnings were emitted because `api.nuget.org:443` vulnerability-data access is forbidden in this environment. |
| Complete solution tests with `--no-build --no-restore` | PASS, exit 0: 82 unit + 87 integration = 169 passed, 0 failed, 0 skipped. |
| Focused `IdentityAuthorizationTests` | PASS, exit 0: 32 passed, 0 failed, 0 skipped. |
| Focused `SqlInventoryAuthorizationTests` | PASS, exit 0: 47 passed, 0 failed, 0 skipped. |
| Phase 1/2 filter `FullyQualifiedName!~SqlInventory&FullyQualifiedName!~IdentityAuthorization` | PASS, exit 0: 32 unit + 23 integration = 55 passed, 0 failed, 0 skipped. |
| Manifest EF tool availability | The repository manifest pins `dotnet-ef 10.0.11`, but the local manifest tool is not restored. No tool restore was attempted. |
| Global pinned `dotnet-ef 10.0.11 migrations has-pending-model-changes ... --configuration Release --no-build` | PASS, exit 0: `No changes have been made to the model since the last migration.` NuGet vulnerability-data warnings were emitted; no migration was applied and no database runtime lane was opened. |
| `src/web/next-env.d.ts` cleanup | PASS final state: the build-generated route-import delta was inspected and restored to the exact committed content; normalized working-file hash equals the committed blob and final file diff is zero. The first Git restore attempt could not create the sandboxed `.git/index.lock`; no Git metadata changed, and the validated single-file content was restored through the index's targeted checkout conversion. |
| Pre-evidence `git diff --check` | PASS, exit 0. |

### Identity/RBAC and Phase 1/2 regression assessment

The dependency-only delta does not modify the ADR-008 implementation or tests. Independent execution confirms the prior security behaviours remain intact:

- all 32 token, immutable-principal, claim-validation, role-mapping and LocalTest environment unit cases pass;
- all 47 SQL authorization integration cases pass, including the exact role/method matrix, server-derived customer/project membership, non-enumerating cross-scope denials, header/private-claim injection resistance, production-like fail-closed behaviour, app-only rejection, fallback policy, safe errors, stable audit actor and correlation metadata;
- `DatabaseSme` retains read/create/update/logical-delete; `MigrationArchitect`, `ProjectManager`, `DiscoveryAnalyst` and `ReviewerAuditor` remain read-only; Customer Administrator, Platform Administrator and unknown roles receive no SQL Inventory permission; and
- all 55 explicit Phase 1/2 regression cases pass with no failure or skip.

This verifies no observed dependency-remediation regression in the ADR-008 local/API/SQLite scope. It does not infer deployed Entra, persistent membership, external identity, production tenancy or SQL Server runtime approval.

### Security-remediation disposition and remaining blockers

- Frontend dependency remediation: **PASS** for the approved restricted local/non-production scope at exact commit `fdf85a24844e9d0b060a6dbdedb09cbb832a2812`. The requested versions, independent lint/build, all-route generation and complete application regression pass. No new application defect was found.
- Connected dependency vulnerability evidence: **PASS as manually supplied commit-bound evidence** from Onkar. The normal-PowerShell .NET scan used `https://api.nuget.org/v3/index.json`, reported no vulnerable packages for the API, unit-test or integration-test projects, and exited 0; the retained npm audit result is 0 vulnerabilities with exit 0. Codex did not execute either connected scan. Historical `PH3SQL-BLK-002` is superseded for this exact commit. Earlier Codex-run `NU1900` warnings remain recorded as environment-specific history and do not override the subsequent connected scan result.
- Remaining blocker 1: I-06/D-11 named test-authority approval is absent.
- Remaining blocker 2: approved isolated SQL Server runtime evidence is absent for migration rehearsal, constraints, rowversion, collation, concurrency and query-plan assurance.
- Identity Platform/deployed membership confirmation, Q-06/Q-09, production identity/tenancy, external customer access, customer-data use, Service Transition, deployment and human release approvals remain outside this Tester authority and are not blockers for this exact commit-bound gate.

**Tester recommendation for the frontend security remediation:** `PASS`.

**Tester recommendation for complete Slice 1 release evidence:** `FAIL` because I-06/D-11 named test-authority approval and the approved isolated SQL Server runtime evidence remain absent; no risk acceptance is inferred.

**One gate decision:** `BLOCKED` for the wider Slice 1 quality/release gate. This is not `RETURN_TO_DEVELOPER` because no remediation or application defect remains.

```yaml
handoff:
  from_agent: "tester"
  to_agent: "quality-manager"
  state: "BLOCKED"
  work_item: "PH3-SQL-001-frontend-dependency-remediation"
  branch: "feature/ph3-sql-implementation"
  commit: "fdf85a24844e9d0b060a6dbdedb09cbb832a2812"
  baseline_commit: "d97f044c2212b1ae1559dc878dc08f58e181a6b8"
  application_commit: "dc31d60303525da7727d92acba455007fd24ef9a"
  architecture_commit: "7f2d6aa12c7f1cffd3d6d9215955bac0b8eca600"
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
      - "Restricted local/non-production Product Owner, Solution Architect/TDA and Information Security approvals recorded in ADR-006, ADR-007, ADR-008 and PH3-SQL-ARCH-001."
  artefacts:
    - "docs/implementation/PH3_SQL_Slice1_Test_Evidence_Pack.md (uncommitted Tester update)"
    - "src/web/package.json (tested, unchanged by Tester)"
    - "src/web/package-lock.json (tested, unchanged by Tester)"
    - "docs/implementation/PH3_SQL_Slice1_Implementation_Work_Package.md (Developer evidence at tested commit; unchanged by Tester)"
  evidence:
    - "Exact entry branch/HEAD/clean state and ancestry checks pass."
    - "Delta from d97f044 to fdf85a2 is limited to package.json, package-lock.json and Developer evidence."
    - "Resolved graph: Next.js/eslint-config-next 16.3.4; React/React DOM 19.2.8; brace-expansion 1.1.18 and 5.0.9; js-yaml 4.3.2; nanoid 3.3.19; postcss 8.5.23; sharp 0.35.4."
    - "Onkar manually supplied connected .NET vulnerability evidence from normal PowerShell: api.nuget.org source; no vulnerable packages in the API, unit-test or integration-test projects; exit 0; exact HEAD retained; only this pre-existing uncommitted evidence update remained. Codex did not execute the scan."
    - "Onkar manually supplied connected npm audit evidence: 0 vulnerabilities, exit 0; Codex did not execute it."
    - "Independent frontend lint/build pass; Next.js 16.3.4 generated 16 routes."
    - "Independent Release build passes with 0 errors; its six NU1900 warnings are retained as Codex-environment-specific history and were followed by the passing connected normal-PowerShell scan."
    - "Complete suite: 169/169; focused identity: 32/32; focused SQL authorization: 47/47; Phase 1/2 regression: 55/55."
    - "EF pending-model validation: no changes since the last migration; no migration or database runtime action."
    - "No forced npm audit fix or allowScripts approval was introduced; next-env.d.ts restored; git diff --check passes."
  decisions:
    - "Accept the frontend dependency remediation as passing for the restricted local/non-production scope at the exact tested commit."
    - "Do not advance the wider Slice 1 quality/release gate while mandatory SQL Server and named test-authority evidence remains absent."
  assumptions:
    - "Onkar's supplied connected .NET and npm vulnerability results accurately report the manual command output against the named exact commit."
    - "Only repository synthetic identities and data were exercised."
  risks:
    - "R-09/I-06 provider-specific SQL Server and formal test-authority evidence remain absent."
    - "R-11 wider production technology/tenancy approval remains unresolved."
  defects: []
  blockers:
    - "I-06/D-11 named test-authority approval is absent."
    - "Approved isolated SQL Server runtime evidence is absent for migration rehearsal, constraints, rowversion, collation, concurrency and query-plan assurance."
  approvals:
    - "Restricted local/non-production Product Owner, Solution Architect/TDA and Information Security approvals are evidenced."
    - "No I-06/D-11 named test-authority approval or approved isolated SQL Server runtime evidence is claimed."
  requested_action: "Hold the wider Slice 1 Quality/release review until I-06/D-11 named test-authority approval is recorded and an approved isolated SQL Server runtime lane provides migration-rehearsal, constraint, rowversion, collation, concurrency and query-plan evidence. The frontend security remediation itself may be treated as independently regression-tested at the exact commit; no merge, migration application, deployment, production action or approval follows."
```

## Current independent retest - 10 September 2026

This section is the current-run evidence for implementation commit `dc31d60303525da7727d92acba455007fd24ef9a`. All 9 September evidence below is preserved as historical context only and is not counted as evidence for this retest.

### Test control and entry gates

- Tester role: independent Tester Agent under `AGENTS.md`.
- Test branch: `feature/ph3-sql-implementation`.
- Exact immutable implementation commit tested: `dc31d60303525da7727d92acba455007fd24ef9a`.
- Approved architecture baseline: `7f2d6aa12c7f1cffd3d6d9215955bac0b8eca600`; verified as an ancestor of the implementation commit.
- Previous implementation baseline: `3650852bb91a8b8ca89a92d1de6ed352b37dde79`; verified as the direct implementation starting baseline and an ancestor of the tested commit.
- Entry state: branch and `HEAD` matched exactly and both tracked and untracked status were empty before testing.
- Environment: Windows, .NET SDK `10.0.400`, .NET/ASP.NET Core runtime `10.0.11`, EF CLI `10.0.11`, Node.js `v24.18.0`, npm `11.16.0`, SQLite in-memory API integration provider, Next.js `16.2.12`.
- Data: repository synthetic fixtures and Tester-created synthetic identifiers/names only.
- Prohibited actions: no migration was applied; no shared/production database was accessed or modified; nothing was deployed, pushed or merged.
- Commit binding after Tester strengthening: application, migration, configuration and frontend sources remain byte-for-byte at the immutable commit. Only the two test files and this evidence documentation are intentionally uncommitted for owner review.

The architecture and security approvals remain limited to local/non-production implementation and testing. Q-06, Q-09, production identity/tenancy, external customer access, customer data, deployment and release remain outside this test authority. I-06/D-11 named test-authority approval, Identity Platform configuration confirmation and an approved isolated SQL Server runtime are still absent.

### Commands and current-run results

| Command/check | Current-run result |
|---|---|
| `git branch --show-current`; `git rev-parse HEAD`; clean status checks | PASS: `feature/ph3-sql-implementation`; exact `dc31d60303525da7727d92acba455007fd24ef9a`; no tracked or untracked change at entry. |
| Architecture/baseline ancestry checks | PASS: `7f2d6aa...` and `3650852...` are ancestors of `dc31d60...`. |
| `dotnet restore LgrTransformationMigration.sln` | PASS, exit 0; all projects up to date. |
| Initial immutable-commit Release build | PASS, exit 0; 0 warnings and 0 errors. |
| Initial immutable-commit complete solution suite | PASS: 73 unit + 85 integration = 158 passed, 0 failed, 0 skipped. |
| Initial committed focused ADR-008 unit/integration suites | PASS: 23 unit + 45 integration = 68 passed, 0 failed, 0 skipped. |
| Tester-strengthened Release build | PASS, exit 0; 0 warnings and 0 errors. One earlier Tester-only build attempt failed because the new helper lacked a namespace import; the test import was corrected without changing application code. |
| Tester-strengthened complete solution suite | PASS: 82 unit + 87 integration = 169 passed, 0 failed, 0 skipped. |
| Focused `IdentityAuthorizationTests` after strengthening | PASS: 32 passed, 0 failed, 0 skipped. |
| Focused `SqlInventoryAuthorizationTests` after strengthening | PASS: 47 passed, 0 failed, 0 skipped. |
| Focused `SqlInventoryApiTests` | PASS: 17 passed, 0 failed, 0 skipped. |
| Focused DTO-validation Problem Details tests | PASS: 2 passed, 0 failed, 0 skipped. |
| Focused default-off feature-gate test | PASS: 1 passed, 0 failed, 0 skipped. |
| Phase 1/2 regression filter `FullyQualifiedName!~SqlInventory&FullyQualifiedName!~IdentityAuthorization` | PASS: 32 unit + 23 integration = 55 passed, 0 failed, 0 skipped. |
| Repository-manifest `dotnet ef migrations has-pending-model-changes ...` | Environment limitation: local manifest tool was not restored and requested `dotnet tool restore`. |
| Global pinned `dotnet-ef 10.0.11 migrations has-pending-model-changes ...` | PASS, exit 0: `No changes have been made to the model since the last migration.` No database action occurred. |
| `dotnet-ef migrations script 20260909164944_AddSqlInventory 20260910082037_AddInternalPrincipalAuditType ...` | PASS, exit 0; generated one nullable `ALTER TABLE` plus EF history insert inside a transaction. Script was inspected only and not applied. |
| `npm.cmd run lint` | PASS, exit 0. |
| `npm.cmd run build` | PASS, exit 0; Next.js production build generated 16 routes. The build-only `next-env.d.ts` change was restored to the immutable commit content. |
| `dotnet list LgrTransformationMigration.sln package --vulnerable --include-transitive --no-restore` | BLOCKED, exit 1: NuGet service-index access to `api.nuget.org:443` was denied by socket policy; no advisory result was produced. |
| `npm.cmd audit --audit-level=low` | BLOCKED, exit 1: the npm advisory endpoint request failed; no advisory result was produced. |
| `gitleaks` / `trivy` availability | Not installed. No dependency manifest or lockfile changed in the ADR-008 delta. |
| Scoped Tester-test formatting and whitespace checks | PASS; no formatting or whitespace error. |

### Independent test strengthening

The Tester changed tests only:

- extended required Entra claim tests for missing/malformed `tid` and `azp`, missing `sub`, and existing `oid`, version and tenant cases;
- proved the application principal ID and canonical audit actor do not change with mutable display-name or subject claims;
- proved LocalTest configuration is accepted by the validator only for `Development` and `Testing`, and rejected for `Production`;
- proved an unauthenticated request receives 401 before missing project context can produce a 400 authorization result;
- added database-level cross-customer and cross-project list/detail/update/archive non-enumeration, comparing inaccessible detail responses with genuinely missing records; and
- injected every supported identity/customer/role/permission test header into a valid production-like bearer request and proved it cannot widen a read-only membership.

### ADR-008 verification matrix

| ADR-008 control | Independent current-run evidence | Result |
|---|---|---|
| Entra signature, signing key, issuer, audience and lifetime validation | Focused unit suite covers valid signed v2 token plus wrong issuer/audience, expiry, not-before and invalid signature. | PASS |
| Required principal claims and stable `InternalPrincipal` | Missing/malformed tenant, object and client IDs; missing subject; wrong tenant; v1 token; stable principal/audit actor despite mutable display/subject claims. | PASS |
| Delegated API access and human/workload separation | Missing scope, disallowed client, app-only workload, mixed delegated/workload claims and injected private permission claim all fail without widening access. Interactive SQL routes reject app-only identities. | PASS |
| Exact SQL Inventory role matrix | For both SQL Instance and SQL Database, all list/detail/create/update/logical-delete actions were executed for `DatabaseSme`, `MigrationArchitect`, `ProjectManager`, `DiscoveryAnalyst`, `ReviewerAuditor`, a multi-role reader, Customer Administrator, Platform Administrator and an unknown role. `DatabaseSme` alone has all four permissions; all four other approved roles are read-only; unlisted/admin roles have none. | PASS |
| Missing/disabled/time-invalid membership and cache revocation | Unassigned, disabled membership, disabled principal, expired and not-yet-valid fixtures return safe 404; live membership revocation is observed on the next request. | PASS |
| LocalTest environment boundary | Testing end-to-end aliases succeed only through the allow-list; arbitrary alias, GUID, role and email-shaped inputs return 401. Options validation permits exact Development/Testing and rejects Production; production-like LocalTest startup fails. | PASS |
| Production identity/header safety | Production-like Entra startup fails when incomplete. Missing/invalid bearer authentication never falls back to headers. With a valid bearer and server-side read-only membership, identity, customer, test-principal, role and permission headers cannot authorize POST. `X-Project-Id` remains only an untrusted selector and membership resolution supplies customer/project authority. | PASS |
| Authentication before authorization | Middleware order is `UseAuthentication` then `UseAuthorization`; request evidence distinguishes anonymous 401 from authenticated/missing-project 400. SQL named policies run before MVC feature filters/services. | PASS |
| Non-enumerating isolation | Customer A/project A cannot list, detail, update, archive or relate instance/database IDs from customer B/project B or customer A/project A2. Missing and inaccessible details return the same safe 404 title/detail/error code with no counts, ETags or existence signal. | PASS on API/SQLite; SQL Server defence-in-depth runtime evidence remains blocked. |
| Problem Details and correlation | Current integration assertions require `application/problem+json`, `type`, `title`, `status`, safe `detail`, `instance`, `errorCode` and non-empty `correlationId` for 400, 401, both 403 codes, 404 and 503. 401 includes `WWW-Authenticate: Bearer`. | PASS |
| Audit actor and metadata | Successful mutations record stable canonical actor, `Human` principal type, server-derived customer/project, UTC timestamp and non-empty correlation ID; service-account audit values remain redacted. | PASS |
| Fallback authorization and regression | An unannotated Phase 1/2 route is protected, `/health` is the single explicit anonymous data-free endpoint, and all 55 Phase 1/2 regression cases pass. | PASS |

### Acceptance criteria and product traceability

| Reference | Current result | Evidence / limitation |
|---|---|---|
| SQL-AC-001; C-03/F-04/NF-13 | PASS for Slice 1 | CRUD, validation, ETag/precondition, safe errors and logical archive pass; DTO-validation contract passes. |
| SQL-AC-002; F-15/NF-01/NF-02/R-02 | PARTIAL | API/SQLite ownership, composite relationship, filtered-index metadata and non-enumeration pass. Mandatory isolated SQL Server runtime FK/rowversion/filtered uniqueness/concurrency evidence is unavailable. |
| SQL-AC-008; C-01/F-01/F-02/F-15/NF-01/NF-02/R-02; ADR-008 | PASS for the approved restricted local/non-production scope | Authentication, immutable principal, server-side membership, every role/method combination, deny-by-default, LocalTest/production guards and direct-object abuse tests pass. This does not approve or exercise deployed/production Entra or external identity. |
| SQL-AC-009; C-06/F-07/NF-06 | PASS for Slice 1 CRUD | Stable actor, principal type, tenant/project, UTC and correlation metadata are asserted for mutations. |
| SQL-AC-011; NF-08 | PARTIAL | 205 instances plus 205 databases and bounded paging/filtering pass on SQLite; SQL Server timing/query-plan evidence remains absent. |
| SQL-AC-012; NF-10/D-13 | PASS | Same-source Release build, complete suite, explicit Phase 1/2 regression, frontend lint/build and EF model-drift check pass. |
| SQL-AC-014; A-11/A-13/R-06 | PASS | Source/delta inspection found no migration execution, DMS orchestration, AI inference, remediation or Azure provisioning path; `DMS` search hits are synthetic hostname text only. |
| Manual Slice 1 subset of SQL-AC-015; NF-04/NF-06 | PASS | Synthetic service-account display metadata validation and audit redaction pass. Import/snapshot portions remain intentionally out of Slice 1. |
| SQL-AC-003..007, SQL-AC-010 and deferred portions of SQL-AC-013/015 | NOT APPLICABLE to Slice 1 | CSV reconciliation/history, assessment and browser journeys remain later approved slices; no pass is inferred. |

### PH3SQL defect disposition

| Defect | Current independent disposition |
|---|---|
| PH3SQL-TST-001 | CLOSED for this retest: requested branch, exact immutable commit and clean entry state all pass. |
| PH3SQL-TST-002 | CLOSED for the approved restricted local/non-production implementation at `dc31d603...`: the full identity, permission, every-role/method, isolation, LocalTest/production-guard, error and audit matrix passes. Production Identity Platform and persistent membership approval remain separate blockers, not closure evidence. |
| PH3SQL-TST-003 | CLOSED: both focused DTO-validation Problem Details cases pass. |
| PH3SQL-TST-004 | CLOSED: default-off/non-local feature protection and no-mutation test pass. |

No new application defect was found. The transient Tester test-helper compile error was corrected in the uncommitted test code and did not alter the implementation.

### Migration assessment

`20260910082037_AddInternalPrincipalAuditType` is additive and backward compatible in `Up`: it adds only nullable `AuditEvents.ActorPrincipalType nvarchar(20)` with a maximum length of 20. Existing rows remain valid, the prior application can ignore the new nullable column, no table/column is altered or renamed, and no data is backfilled, deleted or rewritten. The EF snapshot matches the runtime model and the generated delta contains no other application-schema operation.

The generated `Down` drops the new column and would discard newly recorded principal-type metadata; it is suitable only for an expressly authorised disposable environment and was not run. No migration was applied. Mandatory empty/baseline database migration rehearsal, SQL Server constraints/rowversion/collation/concurrent uniqueness and query-plan evidence remain unavailable without an approved isolated SQL Server test environment and named test authority.

### Remaining blockers and gate

- `PH3SQL-BLK-001`: I-06/D-11 named test-authority approval and an approved isolated SQL Server test environment are absent. Mandatory SQL Server migration/runtime, rowversion, constraint, collation, concurrent uniqueness and query-plan evidence was not run.
- `PH3SQL-BLK-002`: NuGet and npm advisory endpoints are inaccessible. The available vulnerability commands produced no vulnerability result; `gitleaks` and `trivy` are not installed. No clean-feed assurance is claimed.
- Identity Platform confirmation and a separately approved persistent membership provider remain required before Entra mode is used in a deployed environment.
- Q-06/Q-09, production identity/tenancy, external customer access, customer-data use, Service Transition, deployment and human release approvals remain open and out of scope.

**Executable restricted-scope result:** PASS.

**Tester recommendation:** FAIL for complete release evidence because mandatory environment/human evidence remains absent and no named owner has accepted that risk.

**One gate decision:** `BLOCKED`.

```yaml
handoff:
  from_agent: "tester"
  to_agent: "quality-manager"
  state: "BLOCKED"
  work_item: "PH3-SQL-001-slice-1-remediation-PH3SQL-TST-002"
  branch: "feature/ph3-sql-implementation"
  commit: "dc31d60303525da7727d92acba455007fd24ef9a"
  baseline_commit: "3650852bb91a8b8ca89a92d1de6ed352b37dde79"
  architecture_commit: "7f2d6aa12c7f1cffd3d6d9215955bac0b8eca600"
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
      - "Restricted local/non-production Product Owner, Solution Architect/TDA and Information Security approvals recorded in ADR-006, ADR-007, ADR-008 and PH3-SQL-ARCH-001."
  artefacts:
    - "docs/implementation/PH3_SQL_Slice1_Test_Evidence_Pack.md"
    - "docs/implementation/PH3_SQL_Slice1_Implementation_Work_Package.md"
    - "tests/api.unit/IdentityAuthorizationTests.cs (uncommitted Tester strengthening)"
    - "tests/api.integration/SqlInventoryAuthorizationTests.cs (uncommitted Tester strengthening)"
  evidence:
    - "Immutable-commit suite: 158 passed, 0 failed, 0 skipped."
    - "Tester-strengthened suite: 169 passed, 0 failed, 0 skipped."
    - "Focused identity/permission: 32 passed; focused SQL authorization: 47 passed; SQL Inventory API: 17 passed."
    - "Phase 1/2 regression: 55 passed, 0 failed, 0 skipped."
    - "Release build: 0 warnings, 0 errors; frontend lint/build pass; EF model has no pending changes."
    - "Migration delta is one nullable additive audit column; inspected only, never applied."
  decisions:
    - "PH3SQL-TST-001 through PH3SQL-TST-004 are independently closed for the exact restricted local/non-production implementation commit."
    - "Do not advance to a quality/release approval while mandatory SQL Server, test-authority and dependency-advisory evidence is absent."
  assumptions:
    - "Only repository synthetic data and identities were used."
    - "Uncommitted Tester changes modify tests/evidence only; implementation sources remain at the exact commit."
  risks:
    - "R-02 is satisfied for the exercised local/API/SQLite identity and isolation scope but production identity/tenancy assurance is not inferred."
    - "R-09/I-06 provider-specific SQL Server and formal test-authority evidence remain absent."
    - "R-11 wider production technology and tenancy approval remains unresolved."
  defects: []
  blockers:
    - "PH3SQL-BLK-001: named test authority and approved isolated SQL Server runtime evidence absent."
    - "PH3SQL-BLK-002: NuGet/npm advisory feeds inaccessible; gitleaks/trivy unavailable."
    - "Identity Platform/deployed membership authority, Q-06/Q-09, production tenancy, customer data, Service Transition, deployment and human release approvals remain outstanding."
  approvals:
    - "Restricted local/non-production Product Owner, Solution Architect/TDA and Information Security approvals are evidenced."
    - "No named test-authority, Identity Platform, PRB, production-tenancy, DPO, Service Transition or human release approval is claimed."
  requested_action: "Hold the Quality review. A named test authority must approve/provide an isolated SQL Server lane and connected dependency-advisory evidence; after those blockers are resolved, return this exact commit and the uncommitted Tester evidence to the Tester for the remaining provider/assurance run. No merge, migration application, deployment or production action follows."
```

## Historical test control - 9 September 2026

The following evidence is retained unchanged as historical context and is not current-run evidence for `dc31d60303525da7727d92acba455007fd24ef9a`.

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
