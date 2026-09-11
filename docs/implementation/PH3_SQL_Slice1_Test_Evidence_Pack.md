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
