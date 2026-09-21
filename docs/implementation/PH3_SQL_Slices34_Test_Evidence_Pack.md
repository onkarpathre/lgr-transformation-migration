# PH3-SQL-001 Slices 3 and 4 - Consolidated Test Evidence Pack

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
    - "Authorised Test Authority Ashish / ashish50thbirthday-ship-it, approved 16 September 2026 for independent synthetic Slices 2-4 testing: https://github.com/onkarpathre/lgr-transformation-migration/pull/8#pullrequestreview-5221828015"
    - "Product Owner decision supplied 21 September 2026: for this restricted local/non-production Phase 3 scope only, inability to access an interactive browser backend or external vulnerability feeds may be accepted as a documented limitation; unavailable checks remain NOT RUN and no actual product, accessibility, identity, tenant-isolation, data-integrity, security or vulnerability finding is waived."
```

## Control and recommendation

- **Role:** independent Tester Agent under `AGENTS.md`.
- **Work item:** `PH3-SQL-001-REMAINING-SLICES-3-4`.
- **Branch:** `feature/ph3-sql-remaining-implementation`.
- **Exact clean application subject:** `09276007d2dfb0a6b175a256e4a535031b5d6ced`.
- **Slice 3 implementation:** `93aada7b4b8fffcdb7bfefb2223d4974b6a9de4c`, confirmed ancestor.
- **Slice 4 implementation:** `a1df3449d3f06bdff513437e88ca5209a30a426b`, confirmed ancestor.
- **Assessment date:** 21 September 2026.
- **Immutable SQL result:** `PASS` at exact HEAD, reconciled without SQL access or
  harness re-execution.
- **Overall test recommendation:** `PASS_WITH_ACCEPTED_RISK` / `READY_FOR_QUALITY_REVIEW`,
  conditional on the restricted local/non-production scope and the documented
  environment-only limitations below.

No application defect was established by the completed lanes. The Product Owner
has accepted, for this restricted local/non-production Phase 3 scope only, the
environment-only inability to access an interactive browser backend and external
NuGet/npm vulnerability feeds. Those checks remain `NOT RUN` / `UNAVAILABLE`, not
`PASS`. This conditional acceptance does not waive or reclassify any actual
functional, accessibility, authentication, authorisation, tenant-isolation,
data-integrity, security or vulnerability finding, and it is not production or
release approval.

Both failed owner-run results remain unchanged. The first failed before migration
when Windows PowerShell 5.1 promoted dotnet's non-fatal `NU1900` advisory-feed
stderr record to a terminating error:
`TestResults/PH3_SQL_Slices34_Assurance_20260921T152242778Z/result.json` (SHA-256
`3F0092FE3F196E51D35771A6EB64E4CC8E7290E1F31C9250A31CF754FA3A96A1`).

The later exact Retry01 result passed the exact HEAD/worktree gate and the
server-side parameterised `DB_ID` gate, which returned NULL for
`LgrTransformationMigration_Ph3Sql_Slices34_Assurance_20260921_Retry01`. It then
failed before migration execution because dotnet-ef received `Slices34` as a
separate CLI argument after the connection string's spaced application-name value
was reparsed. The retained result is
`TestResults/PH3_SQL_Slices34_Assurance_20260921T153105498Z/result.json` (SHA-256
`41CDF6702C3AD2755EAA6C1F45A85C273550766A902040A259D6BCE07CECAB7B`).

The later immutable PASS result is
`TestResults/PH3_SQL_Slices34_Assurance_20260921T154742902Z/result.json`, SHA-256
`C3AF7E64A104E0ABAF8EF548E9D96A859A618A30B94B21B8DB894E93F80F3463`.
It started at `2026-09-21T15:47:42.9185812Z`, completed at
`2026-09-21T15:47:54.9033159Z`, names the approved work item and Test Authority,
and binds both expected and actual HEAD to
`09276007d2dfb0a6b175a256e4a535031b5d6ced`. All 13 recorded steps are `PASS`
and `defects` is empty.

This reconciliation made no SQL Server connection or authentication attempt and
did not run the harness. No application code, migration, production setting,
customer data, commit, push, merge, deployment or production action was changed
or started. Both failed results and the PASS result remain unchanged.

## Approval and work-package validation

The retained approval JSON records review `5221828015` as `APPROVED`, submitted by
the named Authorised Test Authority, and explicitly permits synthetic Slices 2-4
testing, Tester-authored tests, migration apply/Down/reapply on a fresh isolated
database, and repeated assurance runs. It excludes production/shared databases,
customer data, destructive cleanup, SQL security/configuration changes, deployment,
merge and release.

| Package | Independent result |
|---|---|
| Slice 3 commit ancestry | PASS: `93aada7...` is an ancestor of exact HEAD. |
| Slice 3 changed paths | PASS: the implementation commit contains the 23 paths described by its package, including the additive `AddSqlAssessments` migration, API/service/rules, ADR-008 extension and tests. |
| Slice 3 behavioural claims | PASS for non-SQL lanes: controlled values, assessment CRUD, split evidence/planning permissions, tenant/project non-enumeration, ETag concurrency, audit, feature flag and 200+ bounded inventory regression all passed. |
| Slice 3 hand-off metadata | LIMITATION: the package is the intentional interim hand-off to the Developer for Slice 4 and records `commit: null`; it is not by itself an exact-commit final Tester hand-off. The actual Slice 3 commit is independently bound above. |
| Slice 4 commit ancestry and package commit | PASS: package and Git both identify `a1df344...`, which is an ancestor of exact HEAD. |
| Slice 4 changed paths | PASS: the implementation commit contains the 34 described API/session, frontend, package-lock and developer-test paths. |
| Slice 4 verification claims | REPRODUCED where available: 274/274 .NET, baseline 15/15 frontend tests, lint, 19-route build and package tree. Connected advisory and interactive-browser checks remain NOT RUN / UNAVAILABLE and are conditionally accepted only as environment limitations for this restricted local/non-production hand-off. |

## Immutable SQL PASS reconciliation

The immutable JSON was parsed locally and reconciled by value; it was not edited.
Its expected, initial and final migration arrays are identical and contain exactly:

1. `20260823111854_InitialCreate`
2. `20260824181918_AddDiscoveryImport`
3. `20260909164944_AddSqlInventory`
4. `20260910082037_AddInternalPrincipalAuditType`
5. `20260915171019_AddSqlDiscoveryImportHistory`
6. `20260916121802_EnforceDiscoveryImportRowTenantBatchOwnership`
7. `20260917001712_AddSqlAssessments`

| SQL Server check | Immutable recorded evidence | Result |
|---|---|---|
| Candidate/freshness | Exact branch and HEAD; implementation ancestors; parameterised `DB_ID` returned NULL before migration | PASS |
| Native argument identity | Three arguments containing spaces, semicolons and `Slices34` round-tripped exactly | PASS |
| Native exit codes | Argument probe, initial apply, authorised rollback and final reapply each state `exit code 0`; apply/rollback/reapply retain six narrowly tolerated `NU1900` feed warnings | PASS |
| Outer harness exit | The immutable JSON does not persist a separate outer-shell status field. It records terminal `outcome: PASS`; the preserved harness assigns `$ExitCode = 0` only on that path and ends with `exit $ExitCode`. This is deterministic exit-code evidence, not a separately captured parent-process status. | PASS with evidence qualification |
| Assessment schema | One table, one SQL `rowversion`, five checks, three indexes, three tenant-leading `Restrict` foreign keys and eight FK columns | PASS |
| Isolation/validation | Cross-tenant target, target-XOR breach and unapproved controlled value each rejected with SQL error 547 | PASS |
| Concurrency | Current rowversion update affected 1; stale update affected 0; concurrent uniqueness produced one insert and one SQL 2601 rejection; one active database assessment remained | PASS |
| Immutable history | One database snapshot retained through composite ownership; owner-leading index `IX_SqlDatabaseDiscoverySnapshots_Owner_History` | PASS |
| Execution plans | `paged-assessment-filter.sqlplan`, 9,053 bytes, SHA-256 `3E3B2034DA51B46F1EF8E607B546608C687D1DDE8BC903ABF73B1B64273AC6CA`; `database-history.sqlplan`, 11,635 bytes, SHA-256 `601E33860A614BF65DAD306671E84AED6BFBF8B943053EB4B888277189259C0C`; neither reports a missing index | PASS |
| Rollback/reapply recovery | Two assessment rows exported and recovered; checksum before/after `-770004453`; inventory and history unchanged; final seven-migration history restored | PASS |
| Retention | `databaseLeftFullyMigrated: true`; `databaseAutomaticallyDroppedOrDeleted: false`; target also records `automaticallyDeleted: false` | PASS |

The retained local database is evidence-bearing and must not be dropped or reused
for another migration rehearsal. The browser owner may use its seeded Demo Council
scope for synthetic UI verification; any later UI mutations are post-result and
must be timestamped as such.

## Requirements-to-test matrix

| Area | Evidence | Result |
|---|---|---|
| Assessment and planning CRUD | `SqlAssessmentApiTests`, service/rules coverage, current/stale/missing ETags, archive/recreate and target protection | PASS |
| Controlled values and cross-field validation | 28 focused assessment-rule cases plus API safe-failure cases | PASS |
| Tenant/customer/project isolation | Cross-customer/project API direct-object and relationship attacks; non-enumerating reads/writes; server-derived customer context; SQL 547 composite-ownership rejection | PASS in API/SQLite and SQL Server lanes |
| ADR-008 permissions | Exact inventory/discovery/assessment role/action matrices, multi-role union, unknown/customer/platform deny, denied mutation audit | PASS |
| Concurrency | Inventory and assessment stale ETag/rowversion contract; import stale preview/commit atomicity; SQL current/stale update and two-writer uniqueness | PASS in API/SQLite and SQL Server lanes |
| Validation and safe errors | DTO/rule boundary tests, safe Problem Details, unauthenticated 401, disabled feature non-enumeration | PASS |
| Audit and immutable history | Stable actor/type/correlation audit assertions; discovery preview/commit preservation; SQL snapshot retention and owner-leading history plan | PASS in API/SQLite and SQL Server lanes |
| Feature flags | Parent/child default-deny, Development/Testing-only exposure, flags proven not to grant authorisation | PASS |
| Session capabilities | Authenticated active membership and server-derived `sql.*` permission union; caller headers cannot widen | PASS |
| Central authenticated wrapper | All nine route sources use `useApi`/`useData`; zero journey-local raw `fetch`; `no-store`; project selector; typed errors/ETags | PASS |
| Production test-header suppression | Tester regression strips caller `X-Lgr-Test-Principal` outside Development; production canary is absent from compiled `.next` output | PASS |
| Permission-aware navigation | SQL links hidden or exposed only for server-returned permissions; nested route current state | PASS component contract |
| Nine browser journeys | Tester static contract covers instance list/detail, database list/detail, import list/new/detail, assessment list/detail | 9/9 static PASS; interactive owner procedure ready in installed Chrome/Edge |
| Accessibility and keyboard | Axe representative shared-state scan, semantic page headers, live status/error, modal initial focus, Escape, focus containment and bounded pagination | PASS component contract; owner keyboard/reflow/contrast procedure ready |
| Loading/empty/error states | Shared live-region/retry/empty component tests and all nine route contracts requiring `PageHeader` + `LoadState` | PASS component/static contract; owner interactive procedure ready |
| 200+ synthetic assets | `SqlInventoryApiTests.Instance_and_database_lists_are_bounded_paged_and_filterable_above_200_assets` | PASS API lane; mixed-asset browser timing BLOCKED |
| Product boundaries | Prohibited-capability scan and assessment UI record-only/no-execution contract | PASS |

## Commands and totals

| Check | Result |
|---|---|
| `dotnet restore .\LgrTransformationMigration.sln --nologo` | PASS; all projects restored; three retained `NU1900` advisory-feed warnings. |
| Release solution build, no restore | PASS: 0 errors, 3 `NU1900` warnings. |
| Focused assessment/ADR-008 unit lane | PASS: 77/77, 0 failed/skipped. |
| Focused SQL/browser API integration lane | PASS: 104/104, 0 failed/skipped. |
| Full unit suite | PASS: 146/146, 0 failed/skipped. |
| Full integration suite | PASS: 128/128, 0 failed/skipped. |
| **Full .NET total** | **PASS: 274/274, 0 failed/skipped.** |
| Pinned `dotnet-ef` 10.0.11 pending-model validation | PASS: no model changes since the latest migration; no database command. |
| `npm.cmd ci` | PASS: 442 packages; retained `unrs-resolver` unapproved install-script warning. |
| Baseline frontend component/accessibility suite | PASS: 15/15 across 4 files. |
| Frontend suite with Tester regressions | PASS: 18/18 across 5 files. |
| Frontend lint | PASS. |
| Production build | PASS: Next.js 16.3.4, 19 routes. |
| Production suppression canary | PASS: canary absent from compiled `.next` output. |
| `npm.cmd ls --depth=0` | PASS: locked top-level dependency tree resolved. |
| Connected NuGet vulnerability check | BLOCKED: NuGet service index socket access denied; command exited 1. No clean advisory claim is made. |
| Connected npm vulnerability check | BLOCKED: npm bulk advisory endpoint failed. No clean advisory claim is made. |
| Raw journey fetch / secret-value / prohibited capability scans | PASS. Only the centralized wrapper owns frontend `fetch`; no matched secret value or prohibited executor/provisioner/AI client path. |
| SQL harness parser | PASS after native-command repair; Windows PowerShell 5.1 parser reported zero syntax errors. |
| SQL harness denied-target smoke | PASS fail-closed: unauthorized server was rejected before any SQL access, exit 2, result retained. |
| First retained failed result | FAIL before migration: Windows PowerShell promoted the non-fatal dotnet `NU1900` advisory-feed stderr record to a terminating error. Original result retained unchanged. |
| Exact Retry01 retained failed result | FAIL before migration execution or mutation: exact HEAD/worktree and server-side `DB_ID(NULL)` gates passed; dotnet-ef rejected separately parsed argument `Slices34`. Original result retained unchanged. |
| Native dotnet handling repair | PASS by static review: native arguments remain a typed string array and are splatted without joining or manual quoting; the structured connection string, including exact application name `PH3 SQL Slices34 Assurance`, is supplied through the already-set process environment instead of dotnet-ef's forwarding command line. Native exit-code enforcement and narrow `NU1900` handling are retained. Harness not executed. |
| No-SQL native-argument smoke | PASS in immutable result: child exit 0, no stderr, and all three exact arguments retained. |
| Immutable consolidated SQL run | PASS: 13/13 steps, seven initial/final migrations, schema/isolation/concurrency/history/plans and rollback/reapply recovery; database retained fully migrated and not automatically deleted. |

The jsdom canvas notice from `axe-core` is retained; the representative axe scan
completed and reported zero violations. It is not treated as browser evidence.

## Tester-owned artefacts

- `src/web/tests/TesterSqlBrowserJourneyContracts.test.tsx`
- `tests/sqlserver/PH3_SQL_Slices34_Assurance.ps1`
- `docs/implementation/PH3_SQL_Slices34_Test_Evidence_Pack.md`

The PowerShell harness is pinned to:

- branch `feature/ph3-sql-remaining-implementation`;
- HEAD `09276007d2dfb0a6b175a256e4a535031b5d6ced`;
- server `localhost\SQLEXPRESS`;
- fresh database `LgrTransformationMigration_Ph3Sql_Slices34_Assurance_20260921_Retry01`;
- all seven current migrations through `20260917001712_AddSqlAssessments`.

It permits only these three Tester-owned untracked artefacts and the verified
content-identical `next-env.d.ts` stat entry. It parameterises the master `DB_ID`
gate, refuses database reuse, applies all migrations, checks assessment table,
rowversion, five checks, three indexes and three tenant-leading Restrict FKs,
tests cross-tenant/XOR/controlled-value rejection, stale rowversion and concurrent
active-target uniqueness, retains representative discovery history, captures two
SQL Server STATISTICS XML plans, performs authorised rollback/reapply with synthetic
assessment export/recovery checksums, and retains the fully migrated database. It
contains no database drop/delete or automatic cleanup path.

The repaired native-command path retains a typed `[string[]]` and PowerShell 5.1
array splatting for every child-process call; it performs no lossy string joining
or manual quoting. A no-SQL child-process probe now proves that values containing
spaces, semicolons and `Slices34` each remain one exact argument before the first
SQL connection. The EF apply, rollback and reapply calls no longer forward the
structured connection string as a CLI value. They consume the exact
`ConnectionStrings__LgrDatabase` process environment value read by the API and
already built by `SqlConnectionStringBuilder`, with both .NET host environment
variables pinned to `Production` and restored afterward. An explicit assertion
requires `Application Name` to remain `PH3 SQL Slices34 Assurance`.

The wrapper still changes error handling only around the native process so Windows
PowerShell 5.1 can collect stderr and inspect `$LASTEXITCODE`. Exit code zero is
necessary but not sufficient: only the specific `NU1900` package-vulnerability
advisory-feed retrieval warning is tolerated, and it is retained in both
`nativeWarnings` and command-step evidence. Any other stderr or any nonzero exit
code fails the harness. No migration, schema, tenant-isolation, concurrency,
history, rollback or execution-plan assertion was changed.

## Exact owner-run browser procedure

Do **not** rerun the SQL harness. Chrome
`C:\Program Files\Google\Chrome\Application\chrome.exe` version `153.0.8010.52`
and Edge `C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe` version
`153.0.4234.32` are locally available. No separate WebDriver is required for this
manual lane. Use only synthetic data and timestamp all screenshots/HAR/notes as
post-SQL-result browser evidence.

1. From the repository root, confirm the candidate and immutable result, then start
   the LocalTest API against the retained fully migrated database in PowerShell
   window A:

   ```powershell
   git rev-parse HEAD
   Get-FileHash -Algorithm SHA256 -LiteralPath '.\TestResults\PH3_SQL_Slices34_Assurance_20260921T154742902Z\result.json'
   $env:ASPNETCORE_ENVIRONMENT='Development'
   $env:DOTNET_ENVIRONMENT='Development'
   $env:ConnectionStrings__LgrDatabase='Server=localhost\SQLEXPRESS;Database=LgrTransformationMigration_Ph3Sql_Slices34_Assurance_20260921_Retry01;Trusted_Connection=True;TrustServerCertificate=True;Application Name=PH3 SQL Browser Assurance;'
   dotnet run --project '.\src\api\LgrTransformationMigration.Api.csproj' --no-launch-profile --urls 'http://localhost:5000'
   ```

   Require HEAD `09276007d2dfb0a6b175a256e4a535031b5d6ced`, hash
   `C3AF7E64A104E0ABAF8EF548E9D96A859A618A30B94B21B8DB894E93F80F3463`,
   API startup without migration application, and HTTP 200 from
   `http://localhost:5000/swagger`.

2. In PowerShell window B, start the web application as the allow-listed synthetic
   Discovery Analyst, then open a fresh Chrome window:

   ```powershell
   Set-Location 'C:\Projects\lgr-transformation-migration\src\web'
   $env:NEXT_PUBLIC_API_BASE_URL='http://localhost:5000'
   $env:NEXT_PUBLIC_LGR_TEST_PRINCIPAL='analyst-project-a'
   npm.cmd run dev
   ```

   ```powershell
   Start-Process -FilePath 'C:\Program Files\Google\Chrome\Application\chrome.exe' -ArgumentList '--incognito','--new-window','http://localhost:3000/discovery/imports'
   ```

3. Verify journeys 5-7 in order:

   - **5, import list** `/discovery/imports`: heading `Imports`, Demo Council / LGR
     Azure Transformation Programme context, safe list or empty state, and `New import`.
   - **6, new import** `/discovery/imports/new`: choose `SQL instance CSV v1`, upload
     `C:\Projects\lgr-transformation-migration\tests\TestData\sql-discovery\SQLI-V1-POS-01.csv`,
     then select `Upload and preview`. Confirm the page says preview does not change
     canonical inventory.
   - **7, reconciliation detail** `/discovery/imports/<generated-id>`: confirm the
     summary totals, classifications and validation are rendered; open `Review row`,
     close it with Escape, accept `Commit import`, and confirm the committed status,
     success announcement and absence of a second commit action. Save the generated
     import URL.

4. Stop only the web process with Ctrl+C in window B, change the alias, and restart
   it on the same origin; do not stop the API:

   ```powershell
   $env:NEXT_PUBLIC_LGR_TEST_PRINCIPAL='dba-project-a'
   npm.cmd run dev
   ```

5. Refresh Chrome and verify journeys 1-4 and 8-9 in order:

   - **1, instance list** `/inventory/sql-instances`: heading `SQL instances`, search
     `SYNTH-CREATE`, status filter and `50`-row bounded page; open `View details`.
   - **2, instance detail** `/inventory/sql-instances/<id>`: facts, linked-database
     state and immutable discovery history from the committed import; open `Edit`,
     verify focus enters the dialog, validation is safe, then close with Escape.
   - **3, database list** `/inventory/sql-databases`: select `Add SQL database`, choose
     `DC-HOU-SQL01 / SYNTH-CREATE`, enter database name
     `OWNER-BROWSER-DB-20260921`, size `128`, compatibility `160`, recovery `Full`,
     status `Online`, and save; search it and open `View details`.
   - **4, database detail** `/inventory/sql-databases/<id>`: confirm parent-instance
     link, facts and safe empty history; open/close `Edit` using keyboard only.
   - **8, assessment list** `/assessment/sql`: select `Create assessment`, target type
     `Database`, choose `OWNER-BROWSER-DB-20260921`, create it, and confirm the list
     filters/count before opening `Review assessment`.
   - **9, assessment detail** `/assessment/sql/<id>`: save evidence as `InProgress` /
     `AtRisk` with synthetic blocker/finding/note text; save planning as
     `AzureSqlManagedInstance` / `Offline`; confirm both success announcements and
     that the page explicitly says values cannot execute migration or provision Azure.

6. On **each of the nine URLs**, use Chrome DevTools Network `Slow 3G` during first
   load to observe the loading state, then `Offline` plus reload to verify a safe
   error and `Retry`, restore `No throttling`, and activate Retry. Tab through every
   control without a mouse, require visible focus and no keyboard trap, and verify
   dialogs return focus when closed. At a `320 x 800` responsive viewport and 400%
   zoom, require readable content without page-level two-dimensional scrolling
   (bounded tables may use their own horizontal region). Run the built-in Lighthouse
   Accessibility audit on each route and retain its report; record any contrast,
   name, role, focus, reflow, console or failed-request issue as a defect rather than
   accepting it. In DevTools Network, confirm API calls are `no-store`, carry
   `X-Project-Id: 22222222-2222-2222-2222-222222222222`, and never carry caller
   customer, role or permission headers.

Stop both development processes after recording evidence. Do not drop or delete the
database; do not represent these LocalTest results as production identity evidence.

## Exact connected vulnerability commands

Run these unchanged from normal connected PowerShell. They are read-only advisory
queries; do not run `audit fix`, `--force`, package update or restore commands:

```powershell
Set-Location 'C:\Projects\lgr-transformation-migration'
dotnet list '.\LgrTransformationMigration.sln' package --vulnerable --include-transitive --no-restore
$nugetVulnerabilityExit = $LASTEXITCODE
"nugetVulnerabilityExit=$nugetVulnerabilityExit"
```

```powershell
Set-Location 'C:\Projects\lgr-transformation-migration\src\web'
npm.cmd audit --audit-level=low
$npmVulnerabilityExit = $LASTEXITCODE
"npmVulnerabilityExit=$npmVulnerabilityExit"
```

Retain complete stdout/stderr. Closure requires exit 0 and no reported
vulnerabilities. An unavailable feed or nonzero exit must not be reported as a
clean result; under the Product Owner decision it remains an explicit untested
limitation for this restricted local/non-production hand-off and would still block
any broader or production claim. The inspected sources are enabled nuget.org
`https://api.nuget.org/v3/index.json` and npm
`https://registry.npmjs.org/`.

## Defects, blockers and untested scope

- Application defects found: none in completed lanes.
- `PH3SQL-S34-TST-B01`: CONDITIONALLY ACCEPTED ENVIRONMENT LIMITATION for this
  restricted local/non-production scope. Installed Chrome and Edge and the exact
  owner procedure are documented, but an interactive browser backend was
  unavailable; interactive journey/accessibility results and browser-side 200+
  timing remain NOT RUN and are not PASS.
- `PH3SQL-S34-TST-B02`: CLOSED by the immutable PASS result. Both preceding failed
  results remain unchanged as diagnostic history.
- `PH3SQL-S34-TST-B03`: CONDITIONALLY ACCEPTED ENVIRONMENT LIMITATION for this
  restricted local/non-production scope. NuGet and npm advisory endpoints were
  unreachable; the checks remain UNAVAILABLE, and no clean vulnerability result
  or absence-of-vulnerability claim is made.
- Q-02, Q-06, Q-09, production identity/tenancy, Service Transition, PRB, Quality,
  merge, deployment and human release approval remain outside this test scope.

## Hand-off

```yaml
handoff:
  from_agent: "tester"
  to_agent: "quality-manager"
  state: "READY_FOR_QUALITY_REVIEW"
  work_item: "PH3-SQL-001-REMAINING-SLICES-3-4"
  branch: "feature/ph3-sql-remaining-implementation"
  commit: "09276007d2dfb0a6b175a256e4a535031b5d6ced"
  artefacts:
    - "docs/implementation/PH3_SQL_Slices34_Test_Evidence_Pack.md"
    - "src/web/tests/TesterSqlBrowserJourneyContracts.test.tsx"
    - "tests/sqlserver/PH3_SQL_Slices34_Assurance.ps1"
  evidence:
    - "274/274 full .NET tests passed; focused lanes 77/77 and 104/104 passed."
    - "18/18 frontend component/static Tester tests passed; lint and 19-route production build passed."
    - "EF model validation and production suppression/prohibited scans passed without SQL access."
    - "Both implementation commits are ancestors of the exact clean application subject."
    - "Both failed results remain unchanged: NU1900 failure SHA-256 3F0092FE3F196E51D35771A6EB64E4CC8E7290E1F31C9250A31CF754FA3A96A1; exact Retry01 argument failure SHA-256 41CDF6702C3AD2755EAA6C1F45A85C273550766A902040A259D6BCE07CECAB7B."
    - "Immutable SQL PASS SHA-256 C3AF7E64A104E0ABAF8EF548E9D96A859A618A30B94B21B8DB894E93F80F3463: 13/13 steps, seven migrations initial/final, schema/isolation/concurrency/history/plans and rollback/reapply recovery passed."
    - "The PASS result records databaseLeftFullyMigrated true and databaseAutomaticallyDroppedOrDeleted false."
    - "Chrome 153.0.8010.52 and Edge 153.0.4234.32 are locally available; exact LocalTest owner procedure is recorded."
  decisions:
    - "Product Owner conditionally accepts the two environment-only limitations for the restricted local/non-production Phase 3 scope, so READY_FOR_QUALITY_REVIEW is issued."
    - "Interactive browser/accessibility and connected vulnerability-feed checks remain NOT RUN / UNAVAILABLE, not PASS."
    - "No actual functional, accessibility, authentication, authorisation, tenant-isolation, data-integrity, security or vulnerability finding is waived."
    - "No application defect is raised solely for unavailable browser/advisory infrastructure."
  assumptions:
    - "Only repository synthetic data and allow-listed local identities are used."
  risks:
    - "R-02 and R-09 interactive-browser coverage remains an explicit untested limitation; SQL Server runtime and component/static evidence passed."
    - "R-11 connected advisory evidence remains unavailable; no clean vulnerability assertion is made."
  defects: []
  blockers: []
  limitations:
    - "PH3SQL-S34-TST-B01: interactive browser backend unavailable; journey/accessibility and browser-side 200+ timing checks NOT RUN."
    - "PH3SQL-S34-TST-B03: NuGet/npm advisory feeds unavailable; vulnerability checks UNAVAILABLE and not clean PASS."
  approvals:
    - "Authorised Test Authority review 5221828015 applies to unchanged Slices 2-4 scope."
    - "Product Owner conditional environment-limitation decision supplied 21 September 2026 applies only to this restricted local/non-production Phase 3 scope."
    - "No Quality, merge, deployment, production or release approval is claimed."
  requested_action: "Quality Manager to review the conditional Tester evidence pack, preserve the two NOT RUN / UNAVAILABLE limitations, and determine the independent quality-gate recommendation."
```
