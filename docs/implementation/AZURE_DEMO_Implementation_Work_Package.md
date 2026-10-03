# Restricted Azure Management Demo - Implementation Work Package

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-01", "C-02", "C-03", "C-04", "C-05", "C-06", "C-07", "C-08", "C-09", "C-10", "C-11"]
  functional_requirements: ["F-01", "F-02", "F-03", "F-04", "F-05", "F-06", "F-07", "F-08", "F-09", "F-10", "F-11", "F-12", "F-13", "F-14", "F-15"]
  non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-04", "NF-05", "NF-06", "NF-07", "NF-08", "NF-09", "NF-10", "NF-11", "NF-12", "NF-13"]
  risks: ["R-01", "R-02", "R-04", "R-07", "R-08", "R-09", "R-11", "R-12"]
  assumptions: ["A-01", "A-02", "A-03", "A-04", "A-05", "A-10", "A-11", "A-12", "A-13", "A-14", "A-15", "A-16", "A-18"]
  dependencies: ["D-01", "D-02", "D-03", "D-04", "D-05", "D-06", "D-10", "D-11", "D-13"]
  issues: ["I-01", "I-02", "I-03", "I-04", "I-06", "I-08"]
  open_questions: ["Q-01", "Q-02", "Q-03", "Q-06", "Q-07", "Q-08", "Q-09", "Q-10"]
  approvals:
    - "Product/PRB authority opathre APPROVED exact package commit b8800e1eda014eef1421a1af5427aaea41393496 on 2026-09-29."
    - "Independent TDA PTArchitect APPROVED exact package commit b8800e1eda014eef1421a1af5427aaea41393496 on 2026-09-29."
    - "Information Security ashish50thbirthday-ship-it APPROVED exact package commit b8800e1eda014eef1421a1af5427aaea41393496 on 2026-09-29."
    - "Test Services nextgenexamprep-crypto APPROVED exact package commit b8800e1eda014eef1421a1af5427aaea41393496 on 2026-09-29."
```

## Control and implementation state

- **Role:** Developer under `AGENTS.md`.
- **Work item:** `AZURE-DEMO-001`; architecture package `AZURE-DEMO-ARCH-001`.
- **Branch:** `release/azure-demo-v1`.
- **Original Azure demo implementation candidate:** `38add95edf8b63a552a29a6d6625336de92ea896`.
- **Monitoring and rollback repair:** `a5d683c7336d5938e274cb2c9460a2b6e4da6542`.
- **Previous evidence successor:** `0c5122c7deee7629a08625cd30b15ffd84067e6c`.
- **Technical monitoring repair (final Defender `ScanResults` repair):** `1ae167d73bd0ae7adcac697c521177ff033563c1`.
- **Final monitoring evidence:** `3a017ccc44e3603c23d54d4c27469cacf0cda1d2`.
- **Evidence-status correction:** `c69508ca66c05ddcf8bb09d384cdb49051be30ba`.
- **Migration workload-identity repair baseline:** branch `fix/mtp-azure-demo-reconciliation`, commit `7f8f8b5978420e21adefdf0051d9726bc7c7b031`, initially clean on 2026-10-02.
- **SQLCMD variable-precedence repair baseline:** branch `fix/mtp-azure-demo-reconciliation`, commit `523ff0a365018652d26db4ea80681bd321c53455`, initially clean on 2026-10-02.
- **Azure SQL EXEC compilation repair baseline:** branch `fix/mtp-azure-demo-reconciliation`, commit `208b80580329e0e88407e1c8d4886a356cf20ff3`, initially clean on 2026-10-02.
- **Secure evidence-delivery repair baseline:** branch `fix/mtp-azure-demo-reconciliation`, commit `85ddcec346e5b322420e7749cb840f740b977731`, initially clean and aligned with local GitHub/Azure DevOps refs on 2026-10-02.
- **App Service native-runtime repair baseline:** branch `fix/mtp-azure-demo-reconciliation`, commit `8f10616a7325ba0808370bd3f711bb34314059ce`, initially clean with an empty index and aligned local `origin`/`azure` remote-tracking refs on 2026-10-03.
- **Previous repair scope:** commit `1ae167d` resolves the final Tester monitoring defect `AZD-TST-001`; `AZD-TST-003` is limited to stable reconciliation wording in this evidence document and does not change that earlier technical implementation or its results.
- **Data/environment boundary:** local and isolated validation using synthetic data only.
- **Developer state:** `READY_FOR_COMPILED_SUBNET_REGRESSION_RETEST`.

```yaml
candidate_reconciliation:
  technicalCandidateCommit: "1ae167d73bd0ae7adcac697c521177ff033563c1"
  evidenceParentCommit: "c69508ca66c05ddcf8bb09d384cdb49051be30ba"
  reconciliationCandidate: "EXACT_GIT_HEAD_AT_TESTER_INVOCATION"
```

The immutable reconciliation candidate is the exact Git HEAD supplied to the Independent Tester at invocation time. Git branch, HEAD, upstream alignment, ancestry and changed-file evidence are authoritative. This evidence document intentionally does not attempt to contain the SHA of the commit that contains itself.

Commits after `1ae167d73bd0ae7adcac697c521177ff033563c1` are evidence-only unless independent Git diff verification shows otherwise.

The four exact-package decisions authorise controlled implementation and local or isolated testing only. Q-01 is closed for this package. Q-09 external identity remains excluded and is separable. Azure Platform/Operations approval remains `PENDING_PRE_DEPLOYMENT`; no Azure, Azure SQL, Key Vault, Entra, App Service, Azure DevOps, resource-group or other cloud action was performed.

## Migration workload-identity reconciliation

- Infrastructure deployment, what-if, resource inspection, PITR metadata inspection, slot operations and App Service ZIP deployment retain `sc-mtp-azure-demo-dev`. Database migration and seed do not use that connection.
- The EF bundle and seed reconciliation each run inside a separate `AzureCLI@2` task bound literally to `sc-mtp-azure-demo-migration-dev`. Each task independently establishes authentication; no Azure CLI context or token is assumed to cross a task boundary.
- The external migration identity is `id-mtp-migration-dev-uks-001`, client ID `f77b1931-0954-4ae9-8f6b-de5f9cfdb2e7`, object ID `9b984b84-7ebe-45ca-9441-7b2f41fd8f6c`. Read-only pipeline variables and the runtime guard validate all three values and the service-connection name.
- Before SQL access, each task validates its authenticated client ID, the SQL access-token `azp`/`appid`, `oid`, `tid` and audience, the exact approved tenant, release branch, full release commit, resource group, SQL server/database and commit-bound migration manifest/artifact hashes.
- SQL uses `Authentication=Active Directory Workload Identity` with the exact client ID. The Azure DevOps federated assertion is written only to a task-local permission-restricted temporary file, is never printed, and is deleted in `finally`; the associated workload-identity environment is also removed. This prevents fallback to an ambient agent, managed-identity or developer login.
- Deployment and rollback remain opt-in parameters with `default: false`.

### Mandatory external SQL bootstrap prerequisite

The pipeline does not execute `Configure-AzureDemoDatabasePrincipals.sql`. The migration identity cannot create its own contained user before it has database access. Before deployment, an independently approved Entra SQL administrator/bootstrap identity must execute the exact reviewed script and publish protected `sql-bootstrap.json` evidence. The existing schema remains unchanged: `sourceCommit` now means the immutable provenance commit at which the bootstrap was executed. Evidence must retain `schemaVersion: 1`, `status: PASS`, the exact SQL server/database, migration identity name/client/object IDs, executing administrator object ID, non-empty evidence/approval references, an unambiguous UTC timestamp and the exact SHA-256 of the current grants script.

`sql-bootstrap.json` is supplied to `mtp-azure-demo-deploy` as the Azure DevOps Secure File named exactly `sql-bootstrap.json`. Every pipeline job that consumes the file or `AZDEMO_SMOKE_PREREQUISITE_EVIDENCE` independently downloads the Secure File, copies it as `sql-bootstrap.json` into a job-local directory beneath `$(Agent.TempDirectory)`, binds the job-scoped evidence-directory variable, and removes only that directory under `condition: always()`. The database job checks out complete history and uses local `git merge-base --is-ancestor` without fetching. Exit 0 accepts equal/ancestor provenance; exit 1 rejects non-ancestry; malformed/missing objects, shallow history, missing Git and every other Git failure reject. Evidence expires after 90 days, with only five minutes of clock-skew tolerance. A changed target, migration identity, executor, grants script/hash, expiry or revocation requires regenerated SQL evidence; unrelated descendant application, Bicep, DNS, subnet, packaging, diagnostic or documentation changes do not.

SQL-bootstrap approval approves only the database principal/grant contract. Release approval separately protects the exact `Build.SourceVersion`, release branch, immutable package and migration manifests, deployment environment and human decision. The SQL-bootstrap `approvalReference` cannot substitute for a fresh per-release approval. Operationally, reuse valid SQL evidence across descendant releases while its contract and age remain valid; obtain a fresh release approval for each final deployment commit; regenerate SQL evidence only when its target/security contract changes, expires or is revoked.

### SQLCMD variable-precedence repair

The seven internal `:setvar <name> "REQUIRED"` assignments were removed because SQLCMD gives script-level assignments precedence over values supplied with `-v`. Each of the seven externally supplied variables is now bound exactly once at the start of the SQL guard. The guard verifies the connected and supplied database names, exact physical principal names, and three non-empty, non-zero, distinct GUID object IDs before any contained-user or permission statement can execute. The object IDs remain externally supplied; no identity object ID is hard-coded in the grants script. The exact existing MTP names and least-privilege `GRANT`/`DENY` statements are unchanged.

The prior grants-script SHA-256 `9e3dc3c4cb947e35613fef0d29c80d92689f13abf803267ed8dd0023c97c55e3` is superseded by `ce2557aa39f939c634d94c2776d673426b85b807619a4d52e336c2e15620c790`. Existing bootstrap evidence bound to the prior hash is intentionally invalid for the repaired script and must not be reused. `Assert-AzureDemoSqlBootstrapEvidence.ps1` and its regression test calculate the hash from the supplied grants-script path, so no hard-coded hash contract required a code change.

| SQLCMD repair verification | Result |
|---|---|
| Exact baseline | PASS: branch `fix/mtp-azure-demo-reconciliation`, HEAD `523ff0a365018652d26db4ea80681bd321c53455`, initially clean. |
| SQLCMD/guard regression | PASS: all seven supplied values reached the guard unchanged; exact database accepted; wrong connected/supplied databases, missing/unresolved/empty/`REQUIRED` values, wrong principal names, malformed/zero/overlength/duplicate object IDs rejected across 30 negative cases. |
| Override regression | PASS: zero `:setvar` statements remain; the contract checks every named `:setvar ... REQUIRED` override cannot return and each required SQLCMD token is bound exactly once. |
| Principal/permission contract | PASS: exact MTP database and three principal names, contained-user statements, API grants/denials and migration grants/denials retained; object IDs remain external. |
| Bootstrap evidence/hash | PASS: one current-hash evidence record accepted and six stale/substituted records rejected; repaired SHA-256 recorded above. |
| Pipeline and safety | PASS: seven ordered stages; offline SQLCMD contract executes exactly once; SQL bootstrap remains external; deployment and rollback remain `default: false`. |
| Diff and PowerShell | PASS: `git diff --check`; 24/24 PowerShell files parse under Windows PowerShell 5.1. |
| Locked restore and Release build | Initial restore using the incomplete sandbox cache failed with `NU1101`; exact rerun from the complete read-only local cache PASS. The first no-restore build consequently failed, then the post-restore Release build PASS with 0 errors and four `NU1900` warnings because online vulnerability advisory retrieval is unavailable. |
| Focused and complete .NET tests | PASS: 27/27 focused Azure-demo tests; 350/350 complete tests (205 unit, 145 integration). |
| SBOM and source/security | PASS: deterministic 107-package NuGet and 522-package npm SBOM regression; source/security boundary scan passed 170 files. |

No Azure, SQL or Azure DevOps service was accessed. Successful dependency restore/build work used only the local package cache; attempted NuGet advisory retrieval was blocked by the restricted environment. Nothing was staged, committed, pushed, deployed, migrated, seeded, provisioned or rolled back. Independent execution against the controlled Azure SQL target remains the requested next action.

### Azure SQL EXEC compilation repair

The controlled Azure SQL bootstrap failed with error 156, `Incorrect syntax near the keyword CONVERT`, because each of the three `EXEC` character-string expressions called `CONVERT(nvarchar(36), <validated uniqueidentifier>)` inline. T-SQL's `EXECUTE` character-string grammar supports concatenated constants and local variables for this shape, but not a function call in that concatenation position.

The repair converts each already validated `uniqueidentifier` into its own `nvarchar(36)` local variable after the database, exact principal-name, GUID-format, non-zero and distinct-ID guards and before the first `CREATE USER`. Each `EXEC` now concatenates only its exact `CREATE USER ... FROM EXTERNAL PROVIDER WITH OBJECT_ID` literal, the corresponding precomputed GUID-text variable and its closing literal. The three exact MTP principal names, external SQLCMD object IDs, all `IF NOT EXISTS` checks, grants and denials are unchanged. No object ID is hard-coded.

The prior grants-script SHA-256 `ce2557aa39f939c634d94c2776d673426b85b807619a4d52e336c2e15620c790` is superseded by `749e6631e15afe0613114529e2dd2a21e39b0c582ab5af0fecca586c41d47402`. Existing bootstrap evidence bound to the prior hash is intentionally invalid for this repaired script and must not be reused.

| Azure SQL EXEC repair verification | Result |
|---|---|
| Exact baseline | PASS: branch `fix/mtp-azure-demo-reconciliation`, HEAD `208b80580329e0e88407e1c8d4886a356cf20ff3`, initially clean. |
| Defect removal | PASS: zero `CAST` or `CONVERT` calls occur inside `EXEC` concatenation; three dedicated `nvarchar(36)` variables are computed from the validated `uniqueidentifier` values. |
| Structural syntax regression | PASS: exactly three `EXEC` statements match the supported `EXEC(N'literal' + @precomputedGuidText + N'literal')` expression shape and exact physical principals. Missing/substituted principals, missing precomputed variables, inline function calls, or additional/substituted `EXEC` statements fail the regression. |
| Fail-closed/least-privilege contract | PASS: exact database and principal-name guards, GUID parsing/length/null/non-zero/distinct guards, three `IF NOT EXISTS` checks, API grants/denials and migration grants/denials are pinned. The last guard precedes GUID-text precomputation, which precedes the first mutation. |
| True engine compilation | NOT RUN and not claimed: the repair was explicitly prohibited from accessing Azure or SQL, and no compatible standalone T-SQL parser is installed. Independent controlled Azure SQL compile/execute retest remains required. |
| Pipeline and safety | PASS: seven ordered stages retained; `deployAzureDemo` and `rollbackAzureDemo` remain `default: false`; SQL bootstrap remains an external approved DBA action. |
| Diff and PowerShell | PASS: `git diff --check`; 24/24 PowerShell scripts parse under Windows PowerShell 5.1. |
| Locked restore and Release build | PASS: locked restore succeeded; Release build succeeded with 0 errors. Each emitted four `NU1900` warnings because the restricted environment could not retrieve online NuGet vulnerability data. |
| Focused and complete .NET tests | PASS: 27/27 focused Azure-demo tests; 350/350 complete tests (205 unit, 145 integration), with 0 failed or skipped. |
| SBOM and source/security | PASS: deterministic 107-package NuGet and 522-package npm SBOM regression; source/security boundary scan passed 170 files. |

No Azure, Azure SQL, other SQL engine or Azure DevOps connection was made. Nothing was staged, committed, pushed, deployed, migrated, seeded, provisioned or rolled back.

### Migration-identity repair verification

| Check | Result |
|---|---|
| Git baseline | PASS: branch `fix/mtp-azure-demo-reconciliation`, HEAD `7f8f8b5978420e21adefdf0051d9726bc7c7b031`, initially clean. |
| Diff integrity | PASS: `git diff --check`; all four new files also contain no trailing whitespace. The reviewed contained-user grants SQL is unchanged from HEAD. |
| PowerShell 5.1 parsing | PASS: all 20 repository scripts under `scripts/` parsed with zero errors. |
| Pipeline structure | PASS: 7 ordered stages; exact dedicated migration connection in EF/seed; no plain-PowerShell migration, seed or SQL bootstrap; both opt-in parameters remain default-disabled. |
| Migration target guard | PASS: 1 valid and 7 fail-closed authentication/target cases. |
| Migration identity/release guard | PASS: 1 valid and 14 fail-closed identity, tenant, service-connection, branch, target and manifest cases. |
| SQL bootstrap evidence guard | PASS: 1 valid and 6 fail-closed stale/substituted evidence cases. |
| Bicep 0.47.16 | PASS: 10 files formatted with no tracked change; lint, main build and 2 parameter builds passed with synthetic values. Existing experimental-assert warnings were emitted. |
| SBOM regression | PASS: deterministic inventories for 107 NuGet and 522 npm components. |
| Monitoring contract | PASS: 17 mandatory alert resources. |
| Rollback safeguards | PASS: 1 valid and 12 fail-closed target cases. |
| Release build | PASS: 0 errors; 3 `NU1900` warnings because the isolated environment could not query the NuGet advisory endpoint. |
| Focused AzureDemo tests | PASS: 27/27. |
| Full automated tests | PASS: 205/205 unit and 145/145 integration; 350 total, 0 failed or skipped. |
| Source-boundary scan | PASS: 166 source/configuration files. |
| Smoke contract | PASS plan-only: 22/22 listed; no endpoint or cloud call made. |
| Focused formatting | PASS for changed .NET file `tools/AzureDemo.DataTool/Program.cs`. Full-solution formatting remains a pre-existing failure in unchanged source files and was not rewritten as part of this scoped repair. |
| Legacy independent candidate harness | 32 PASS / 10 FAIL. The harness is pinned to the previous `release/azure-demo-v1` candidate, clean/three-untracked-file allowlist and earlier monitoring/rollback target strings; it rejects this required fix branch and dirty implementation worktree. It was preserved unchanged for Independent Tester reconciliation. |

## Implemented deployment-readiness behaviour

- Added fail-closed `AzureDemo` startup validation for exact Entra issuer/audience/client allow-list, server-side membership secret reference, membership-cache limit, Blob endpoint/container and passwordless approved Azure SQL target. `LocalTest` and `X-Lgr-Test-Principal` authority are prohibited.
- Added liveness/readiness checks, secure response headers, forwarded-header handling, private API expectations and same-origin Next.js proxy/authentication contracts.
- Added Node.js 24/Next.js 16 standalone and .NET 10 Linux App Service packaging, with local Development, Testing and LocalTest configuration excluded from published artifacts.
- Added Azure Blob discovery-import persistence with bounded tenant/project paths and retained file-based import only. No discovery API was introduced.
- Added parameterised resource-group-scoped Bicep for App Service staging slots, user-assigned managed identities, Key Vault, Azure SQL, Blob Storage, monitoring, VNet integration, private endpoints, private DNS and alerts. The alert module covers web availability, API readiness through the web health route, web/API HTTP 5xx, unhandled exceptions, authentication failures/authorization denials, SQL saturation/connectivity, Key Vault denial, Blob dependency failure, discovery-import failure, storage malware/scan failure, failed deployment, both staging-slot health signals, the daily telemetry cap and UK South service health. All alert resources route to the approved action group. The templates do not provision migration targets.
- Final repair commit `1ae167d` enables the storage-account Defender override, retains the approved `10` GB/month malware-scanning cap, enables on-upload malware scanning, and creates the exact nested Defender diagnostic setting named `service`. It routes `ScanResults` to the approved Log Analytics workspace with the approved 30-day retention, preserves the `StorageMalwareScanningResults` alert, and establishes the explicit workspace -> storage -> Defender -> diagnostic route -> malware-alert dependency. Its strengthened PowerShell and .NET monitoring validation resolves the final Tester monitoring defect.
- Preserved `infra/bicep/parameters/dev.bicepparam` as an AzureDemo-only compatibility parameter entry. Deletion was unnecessary: the restored equivalent contains the same 21 approved parameters as `azure-demo.bicepparam` and no legacy development values.
- Added a default-disabled, release-branch-only Azure Pipelines path with build/test/audit/package/SBOM, Bicep build/what-if, controlled EF artifacts, gated slot deployment, 22 smoke contracts, API-before-web swap and web-before-API rollback ordering. The repaired rollback stage can run only when its same pipeline run actually reached a succeeded or failed `SwapAndVerify` attempt; it also requires deployment and rollback opt-in, the exact release branch, an explicit full immutable source commit, exact `azure-demo` environment, exact `Onkar.Pathre` resource group, approved web/API application names and exact `staging` to `production` slot values. A separate fail-closed guard runs before any Azure task. Human validation and protected environments remain mandatory.
- Added controlled EF idempotent-script and Linux migration-bundle production with no startup migration. Generation preserves the owner-supplied API lock file even on a failed runtime restore.
- Added synthetic seed/reset tooling that validates manifest classification and hashes and refuses non-AzureDemo, unapproved SQL targets or unsafe environments.
- Added deployment-boundary, exact configuration and browser contract tests plus source-boundary, artifact-manifest, pipeline-structure and SBOM tooling.
- Added a narrow ignore rule for reproducible `artifacts/azure-demo-local/` output. No source, test, script, Bicep, pipeline, evidence or dependency lock file was removed.

## Product and security boundaries retained

- The application records plans and evidence; it cannot execute migration, provision Azure targets, call discovery-tool APIs, enable AI, or provide multi-cloud behaviour.
- AzureDemo identity is workforce-Entra-only and fail closed. Tenant/project access remains server-derived; test or caller-supplied headers confer no authority.
- Secrets remain Key Vault references or protected pipeline inputs. Templates and application artifacts contain no secret values or publish profiles.
- Discovery files use the approved private Blob container; synthetic seed content is explicitly classified and hash-bound.
- Staging slots, explicit database migration artifacts, smoke evidence, swap order and rollback are pipeline controls; application startup never migrates or seeds a database.

## Developer verification

| Check | Result |
|---|---|
| Exact Git control | PASS at Independent Tester reconciliation of evidence-status correction `c69508ca66c05ddcf8bb09d384cdb49051be30ba`: branch `release/azure-demo-v1`; HEAD and local upstream `origin/release/azure-demo-v1` both resolved to that commit; ahead/behind `0/0`; zero staged or tracked worktree changes. Independent Git diff verification showed that commits after technical monitoring repair `1ae167d73bd0ae7adcac697c521177ff033563c1` changed only this evidence document. The three authorised Tester-owned files were reported as untracked artefacts with their expected SHA-256 values. |
| Locked .NET restore | PASS with four `NU1900` warnings because the NuGet advisory endpoint is unavailable in the isolated environment. Package locks remained intact. |
| Release build | PASS: 0 errors, 4 `NU1900` advisory-feed warnings. |
| Complete .NET tests | PASS: 343/343 tests passed: 198 unit and 145 integration; 0 failed or skipped. |
| Focused AzureDemo tests | PASS: 20/20 focused AzureDemo tests passed, including the exact nested Defender `ScanResults` route, workspace, retention, dependency and alert-coupling contract. |
| EF pending-model validation | UNAVAILABLE, not passed: `dotnet tool run dotnet-ef ... has-pending-model-changes ... --no-build` exited 1 because the pinned local tool is not restored; `dotnet tool restore` then exited 1 because the NuGet service index is unreachable. No database was accessed. |
| Frontend dependency tree | PASS from `package-lock.json` using `npm.cmd ls --package-lock-only --all` (exit 0): Vitest and `@vitest/mocker` resolve to 4.1.11; patched `brace-expansion` versions remain locked. Frontend execution remained unavailable as recorded below. |
| Mandatory monitoring coverage | PASS: all 17 alert families plus the `ScanResults`-route contract passed. `Test-AzureDemoMonitoringAlerts.ps1` validates both Defender enablement flags, the approved 10 GB cap, per-account override, exact nested `service` diagnostic scope, enabled `ScanResults`, shared workspace, approved 30-day retention, dependency ordering and coupling to the preserved malware scheduled-query alert. Microsoft Learn resource references were used for static schema review because Bicep/Azure CLI validation is unavailable. |
| Rollback fail-closed guards | PASS: rollback validation accepted one valid target and rejected 10 invalid targets. Pipeline structure proves the guard precedes `AzureCLI@2`. |
| Azure Pipelines YAML | PASS: the seven-stage pipeline contract passed, including ordered stages, default-disabled deployment, protected environments, human validation, exact rollback conditions, API-before-web swap and web-before-API rollback. No general YAML parser is installed locally. |
| PowerShell validation | PASS: all 16 tracked PowerShell scripts parsed with zero errors under Windows PowerShell 5.1.26100.9444. The untracked Tester-owned harness was preserved read-only and is not included in the tracked-script total. |
| Bicep parameter parity | PASS: 21/21 Bicep parameter parity passed; `azure-demo.bicepparam` and `dev.bicepparam` each contain 21 assignments with comparison delta 0. |
| Smoke contracts | PASS plan-only: 22/22 smoke contracts passed; plan-only mode confirmed no endpoint or cloud calls. Execution requires the protected deployed environment and independent evidence. |
| Security/prohibited-capability scan | PASS across 155 source/configuration files for likely secrets, prohibited identity/local-test settings, startup migration/seed, generated binaries and prohibited application capability dependencies. This is a scoped developer diagnostic, not a substitute for an approved secret/SAST scanner. |
| Formatting and whitespace | PASS: focused `dotnet format --verify-no-changes --no-restore` and `git diff --check` passed. |

The seven-stage pipeline structure, Bicep parameter parity, source-boundary scan and Git diff checks passed. These results do not convert any unavailable connected or tool-dependent check into a pass.

### Checks blocked by local tooling or connectivity

| Check and exact command | Exit | Environmental blocker |
|---|---:|---|
| EF tool availability: `dotnet tool run dotnet-ef migrations has-pending-model-changes --project src/api/LgrTransformationMigration.Api.csproj --startup-project src/api/LgrTransformationMigration.Api.csproj --configuration Release --no-build`; then `dotnet tool restore` | 1 / 1 | UNAVAILABLE: the pinned `dotnet-ef` 10.0.11 tool is not restored, and the NuGet service index is unreachable. |
| Frontend locked install: `npm.cmd ci --ignore-scripts --fetch-timeout=30000 --fetch-retries=0 --cache ..\..\artifacts\azure-demo-local\npm-cache` from `src/web` | 1 | UNAVAILABLE: registry tarball fetch for `zod-validation-error-4.0.2.tgz` failed with `EACCES` in the restricted environment. |
| Frontend component tests: `npm.cmd run test:component` | 1 | UNAVAILABLE: `vitest` executable was unavailable because the locked install could not complete. |
| Frontend lint: `npm.cmd run lint` | 1 | UNAVAILABLE: `eslint` executable was unavailable because the locked install could not complete. |
| Frontend production build: `npm.cmd run build` | 1 | UNAVAILABLE: `next` executable was unavailable because the locked install could not complete. |
| Connected npm audit: `npm.cmd audit --package-lock-only --audit-level=moderate --fetch-timeout=30000 --fetch-retries=0 --cache ..\..\artifacts\azure-demo-local\npm-cache` from `src/web` | 1 | UNAVAILABLE: npm audit endpoint returned an error in the restricted environment. |
| Connected NuGet vulnerability check: `dotnet list LgrTransformationMigration.sln package --vulnerable --include-transitive` | 1 | UNAVAILABLE: socket access to `https://api.nuget.org/v3/index.json` is forbidden; no vulnerability result is claimed. |
| Connected NuGet deprecation check: `dotnet list LgrTransformationMigration.sln package --deprecated --include-transitive` | 1 | UNAVAILABLE: socket access to `https://api.nuget.org/v3/index.json` is forbidden; no deprecation result is claimed. |
| Bicep build: `bicep build infra/bicep/main.bicep --outfile artifacts/azure-demo-local/repair-scanresults-bicep/main.json` | 1 | UNAVAILABLE: `bicep` is not installed or on `PATH`. |
| Bicep lint: `bicep lint infra/bicep/main.bicep` | 1 | UNAVAILABLE: `bicep` is not installed or on `PATH`. |
| Azure CLI Bicep fallback: `az bicep build --file infra/bicep/main.bicep --outfile artifacts/azure-demo-local/repair-scanresults-bicep/main.json` | 1 | UNAVAILABLE: `az` is not installed or on `PATH`. |
| Linux EF migration bundle | 1 | UNAVAILABLE: the restricted environment cannot resolve the required Linux runtime assets from NuGet; no Linux EF migration bundle is claimed. |
| Complete application packages and package hashes | 1 | UNAVAILABLE: the frontend production build cannot run without the locked install, so no complete application package set or package hashes are claimed. |
| Protected Azure runtime validation | Not run | UNAVAILABLE, not passed: Azure what-if/deployment, protected-environment smoke execution, slot swap and rollback execution require the protected Azure runtime and human-controlled approvals. No Azure, SQL or deployment operation was run. |

Historical owner frontend/audit evidence remains recorded in the tested candidate history, but it was not reproduced by this repair run and is not represented as successor evidence.

## Final Defender monitoring repair commit inventory

- `infra/bicep/main.bicep`
- `infra/bicep/modules/alerts.bicep`
- `infra/bicep/modules/data.bicep`
- `scripts/build/Test-AzureDemoMonitoringAlerts.ps1`
- `tests/api.unit/AzureDemoDeploymentBoundaryTests.cs`

These five paths comprise immutable technical monitoring repair commit `1ae167d73bd0ae7adcac697c521177ff033563c1`. Final monitoring evidence is commit `3a017ccc44e3603c23d54d4c27469cacf0cda1d2`, followed by evidence-status correction `c69508ca66c05ddcf8bb09d384cdb49051be30ba`. Independent Git diff verification showed that both post-technical commits changed only this evidence document. Commits after `1ae167d73bd0ae7adcac697c521177ff033563c1` are evidence-only unless independent Git diff verification shows otherwise. At the last Tester reconciliation, the Tester-owned evidence pack and both `tests/assurance` files were preserved byte-for-byte and reported as authorised untracked artefacts.

## Intended source-commit inventory by classification

### Repository configuration and application source

- `.gitignore`; `Directory.Build.props`; `LgrTransformationMigration.sln`.
- `src/api/Infrastructure/AzureDemoInfrastructure.cs`; `src/api/Infrastructure/HealthAndSecurity.cs`; `src/api/Infrastructure/IdentityAuthorization.cs`; `src/api/LgrTransformationMigration.Api.csproj`; `src/api/Program.cs`.
- `src/api/Services/Discovery/DiscoveryImportOptions.cs`; `src/api/Services/Discovery/ImportFileStorage.cs`.
- `src/api/appsettings.json`; `src/api/appsettings.Development.json`; `src/api/appsettings.Testing.json`; `src/api/appsettings.AzureDemo.json`; `src/api/packages.lock.json`.
- `src/web/.env.example`; `src/web/app/api/[...path]/route.ts`; `src/web/app/health/route.ts`; `src/web/app/globals.css`; `src/web/app/layout.tsx`.
- `src/web/components/ApiContext.tsx`; `src/web/components/AppShell.tsx`; `src/web/components/EntraAuth.tsx`; `src/web/proxy.ts`; `src/web/package.json`; `src/web/package-lock.json`; `src/web/vitest.config.ts`.
- `tools/AzureDemo.DataTool/AzureDemo.DataTool.csproj`; `tools/AzureDemo.DataTool/Program.cs`; `tools/AzureDemo.DataTool/packages.lock.json`.

### Automated tests and test dependency locks

- `src/web/tests/AzureDemoDeploymentContracts.test.ts`.
- `tests/api.unit/AzureDemoConfigurationTests.cs`; `tests/api.unit/AzureDemoDeploymentBoundaryTests.cs`; `tests/api.unit/packages.lock.json`.
- `tests/api.integration/packages.lock.json`.

### Infrastructure and pipeline

- `azure-pipelines.yml`.
- `infra/bicep/main.bicep`; `infra/bicep/modules/alerts.bicep`; `infra/bicep/modules/appservice.bicep`; `infra/bicep/modules/data.bicep`; `infra/bicep/modules/identities.bicep`; `infra/bicep/modules/monitoring.bicep`; `infra/bicep/modules/network.bicep`; `infra/bicep/modules/private-endpoints.bicep`.
- `infra/bicep/parameters/azure-demo.bicepparam`; `infra/bicep/parameters/dev.bicepparam`.
- `scripts/database/Configure-AzureDemoDatabasePrincipals.sql`.

### Build, database, data and smoke tooling

- `scripts/build/Assert-AzureAppServiceNativeRuntimes.ps1`; `scripts/build/Assert-AzureDemoRollbackTarget.ps1`; `scripts/build/New-AzureDemoPackages.ps1`; `scripts/build/New-AzureDemoSboms.ps1`; `scripts/build/New-EfMigrationArtifacts.ps1`; `scripts/build/Test-AzureAppServiceNativeRuntimes.ps1`; `scripts/build/Test-AzureDemoArtifacts.ps1`; `scripts/build/Test-AzureDemoDatabasePrincipalSql.ps1`; `scripts/build/Test-AzureDemoMonitoringAlerts.ps1`; `scripts/build/Test-AzureDemoRollbackSafeguards.ps1`; `scripts/build/Test-AzureDemoSourceBoundaries.ps1`; `scripts/build/Test-AzurePipelineStructure.ps1`.
- `scripts/data/Invoke-AzureDemoReset.ps1`; `scripts/data/Invoke-AzureDemoSeed.ps1`.
- `scripts/smoke/Invoke-AzureDemoSmokeTests.ps1`; `scripts/smoke/README.md`; `scripts/smoke/smoke-checks.json`.

### Evidence and synthetic input

- `demo-data/azure-demo-seed-manifest.json`.
- `docs/implementation/AZURE_DEMO_Implementation_Work_Package.md`.

## Excluded reproducible output

The entire `artifacts/azure-demo-local/**` tree is excluded, including staging/scan directories, package ZIPs, DLLs, PDBs, executable migration bundles, generated SQL, manifests, SBOMs, publish trees and validation output. Repository-wide generated `bin/`, `obj/`, `.next/`, `node_modules/`, `TestResults/` and coverage output also remain excluded. None is an intended source-commit file.

## Compatibility, deployment and rollback

- The implementation is additive deployment enablement for the existing approved demo journeys. It does not close excluded product gaps.
- Intended deployment order is controlled migration artifact, API and web staging slots, protected smoke tests, API swap, web swap and post-swap validation. Deployment remains default disabled.
- Application rollback swaps web before API back to known-good slots only after the exact branch, immutable source release, demo environment, resource group, applications and slots pass the pre-Azure guard. Forward-only database changes require compatibility and a separately approved recovery action; no startup or autonomous migration exists.
- Azure Platform/Operations approval, connected pipeline validation, exact-commit artifact hashes, independent Tester evidence, Quality review and human release authority are still required before any deployment.

## Hand-off

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_MIGRATION_IDENTITY_RETEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_7f8f8b5978420e21adefdf0051d9726bc7c7b031"
  technicalCandidateCommit: "1ae167d73bd0ae7adcac697c521177ff033563c1"
  evidenceParentCommit: "c69508ca66c05ddcf8bb09d384cdb49051be30ba"
  reconciliationCandidate: "EXACT_GIT_HEAD_AT_TESTER_INVOCATION"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-01", "C-02", "C-03", "C-04", "C-05", "C-06", "C-07", "C-08", "C-09", "C-10", "C-11"]
    functional_requirements: ["F-01", "F-02", "F-03", "F-04", "F-05", "F-06", "F-07", "F-08", "F-09", "F-10", "F-11", "F-12", "F-13", "F-14", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-04", "NF-05", "NF-06", "NF-07", "NF-08", "NF-09", "NF-10", "NF-11", "NF-12", "NF-13"]
    risks: ["R-01", "R-02", "R-04", "R-07", "R-08", "R-09", "R-11", "R-12"]
    assumptions: ["A-01", "A-02", "A-03", "A-04", "A-05", "A-10", "A-11", "A-12", "A-13", "A-14", "A-15", "A-16", "A-18"]
    dependencies: ["D-01", "D-02", "D-03", "D-04", "D-05", "D-06", "D-10", "D-11", "D-13"]
    issues: ["I-01", "I-02", "I-03", "I-04", "I-06", "I-08"]
    open_questions: ["Q-01", "Q-02", "Q-03", "Q-06", "Q-07", "Q-08", "Q-09", "Q-10"]
  artefacts:
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
    - "azure-pipelines.yml"
    - "scripts/database/Assert-AzureDemoMigrationIdentity.ps1"
    - "scripts/database/Assert-AzureDemoMigrationTarget.ps1"
    - "scripts/database/Assert-AzureDemoSqlBootstrapEvidence.ps1"
    - "scripts/build/Test-AzureDemoMigrationIdentity.ps1"
    - "scripts/build/Test-AzureDemoMigrationTarget.ps1"
    - "scripts/build/Test-AzureDemoSqlBootstrapEvidence.ps1"
    - "scripts/build/Test-AzurePipelineStructure.ps1"
    - "tools/AzureDemo.DataTool/Program.cs"
    - "infra/bicep/main.bicep"
    - "infra/bicep/modules/alerts.bicep"
    - "infra/bicep/modules/data.bicep"
    - "scripts/build/Test-AzureDemoMonitoringAlerts.ps1"
    - "tests/api.unit/AzureDemoDeploymentBoundaryTests.cs"
  evidence:
    - "Migration target guard accepted one valid target and rejected 7 invalid authentication/target cases."
    - "Migration identity guard accepted one valid identity/release and rejected 14 invalid identity, tenant, service-connection, branch, target and manifest cases."
    - "SQL bootstrap evidence guard accepted one valid record and rejected 6 stale or substituted cases."
    - "343/343 .NET tests passed: 198 unit and 145 integration; 20/20 focused AzureDemo tests passed."
    - "All 17 alert families plus the exact nested Defender ScanResults route contract passed."
    - "Rollback validation accepted one valid target and rejected 10 invalid targets before any Azure task."
    - "All 16 tracked PowerShell scripts parsed under Windows PowerShell 5.1; 22/22 smoke contracts passed plan-only; the seven-stage pipeline contract and 21/21 Bicep parameter parity passed."
    - "The security/prohibited-capability scan passed across 155 files, and git diff --check passed."
    - "Blocked connected/tooling commands and exact exit codes are recorded without claiming a pass."
  decisions:
    - "SQL principal bootstrap is an explicitly external Entra-administrator/DBA prerequisite evidenced by protected sql-bootstrap.json; the pipeline does not run the grants script."
    - "EF migration and seed each authenticate independently through sc-mtp-azure-demo-migration-dev and use explicit workload-identity SQL authentication."
    - "The approved 10 GB monthly malware-scanning cap and 30-day architecture retention are preserved."
    - "The existing StorageMalwareScanningResults scheduled-query alert remains enabled and unchanged in strength."
    - "Deployment remains default disabled and subject to Azure Platform/Operations and human gates."
    - "Technical monitoring repair 1ae167d73bd0ae7adcac697c521177ff033563c1 is followed by final monitoring evidence 3a017ccc44e3603c23d54d4c27469cacf0cda1d2 and evidence-status correction c69508ca66c05ddcf8bb09d384cdb49051be30ba."
    - "Commits after 1ae167d73bd0ae7adcac697c521177ff033563c1 are evidence-only unless independent Git diff verification shows otherwise."
    - "The immutable reconciliation candidate is the exact Git HEAD supplied to the Independent Tester at invocation time; Git branch, HEAD, upstream alignment, ancestry and changed-file evidence are authoritative."
    - "No merge, Azure/SQL/Azure DevOps access, provisioning or deployment action was performed for the AZD-TST-003 documentation repair."
  assumptions:
    - "Connected CI has Bicep, YAML, npm and Linux runtime feeds needed to reproduce the unavailable local checks."
  risks:
    - "Bicep/Azure CLI validation, EF tool restore/model validation, frontend install/tests/lint/build, connected npm audit, connected NuGet vulnerability/deprecation checks, Linux EF migration bundle, complete application packages and hashes, approved secret/SAST and protected Azure runtime validation remain required."
  defects: []
  blockers:
    - "An approved external Entra SQL administrator must apply the reviewed contained-user grants and publish exact-commit bootstrap evidence before any migration task can run."
    - "Local registry/feed connectivity blocks same-worktree frontend execution, connected npm/NuGet audit and EF tool restore/model evidence."
    - "Bicep CLI and Azure CLI are unavailable locally; connected CI must compile and lint the repaired template."
    - "Protected Azure runtime validation remains unavailable and requires the controlled environment and human approvals."
  approvals:
    - "Four exact-package implementation/local-test approvals at b8800e1eda014eef1421a1af5427aaea41393496."
    - "Azure Platform/Operations remains PENDING_PRE_DEPLOYMENT."
  requested_action: "Independent Tester must retest the dedicated migration workload identity, external bootstrap-evidence prerequisite and fail-closed pipeline contracts without deploying or using non-synthetic data."
```

READY_FOR_MIGRATION_IDENTITY_RETEST

## SQLCMD variable-precedence repair hand-off

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_SQLCMD_VARIABLE_RETEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_523ff0a365018652d26db4ea80681bd321c53455"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-01"]
    functional_requirements: ["F-01", "F-02", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-06", "NF-10", "NF-12"]
    risks: ["R-02", "R-09", "R-11"]
    assumptions: ["A-11", "A-12", "A-18"]
    dependencies: ["D-02", "D-03", "D-04", "D-05"]
    issues: ["I-06", "I-08"]
    open_questions: ["Q-01", "Q-06", "Q-08", "Q-09"]
    approvals:
      - "Four exact-package implementation/local-test approvals at b8800e1eda014eef1421a1af5427aaea41393496."
  artefacts:
    - "scripts/database/Configure-AzureDemoDatabasePrincipals.sql"
    - "scripts/build/Test-AzureDemoDatabasePrincipalSql.ps1"
    - "scripts/build/Test-AzurePipelineStructure.ps1"
    - "azure-pipelines.yml"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "Seven supplied SQLCMD variables preserved; exact database accepted; 30 invalid cases rejected."
    - "Zero internal :setvar statements; exact MTP principal and least-privilege contracts retained."
    - "Grants-script SHA-256 ce2557aa39f939c634d94c2776d673426b85b807619a4d52e336c2e15620c790."
    - "24/24 PowerShell parses; 27/27 focused Azure-demo tests; 350/350 complete .NET tests."
    - "Seven-stage pipeline, bootstrap-evidence, SBOM and source/security contracts passed."
  decisions:
    - "SQL principal bootstrap remains an external approved DBA action and is not automated by the pipeline."
    - "Deployment and rollback remain disabled by default."
  assumptions:
    - "The independent retest supplies the seven reviewed values through SQLCMD -v and runs against only the approved controlled Azure SQL target."
  risks:
    - "Online NuGet vulnerability advisory retrieval was unavailable; the locked local restore and build emitted NU1900 only."
  defects: []
  blockers:
    - "Independent controlled Azure SQL retest and all existing human deployment/release approvals remain required."
  approvals:
    - "Azure Platform/Operations remains PENDING_PRE_DEPLOYMENT."
  requested_action: "Independent Tester must rerun the reviewed grants script with externally supplied SQLCMD values and confirm the controlled database guard before any separately approved deployment activity."
```

READY_FOR_SQLCMD_VARIABLE_RETEST

## Azure SQL EXEC compilation repair hand-off

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_SQL_EXEC_COMPILE_RETEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_208b80580329e0e88407e1c8d4886a356cf20ff3"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-01"]
    functional_requirements: ["F-01", "F-02", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-06", "NF-10", "NF-12"]
    risks: ["R-02", "R-09", "R-11"]
    assumptions: ["A-11", "A-12", "A-18"]
    dependencies: ["D-02", "D-03", "D-04", "D-05"]
    issues: ["I-06", "I-08"]
    open_questions: ["Q-01", "Q-06", "Q-08", "Q-09"]
    approvals:
      - "Four exact-package implementation/local-test approvals at b8800e1eda014eef1421a1af5427aaea41393496."
  artefacts:
    - "scripts/database/Configure-AzureDemoDatabasePrincipals.sql"
    - "scripts/build/Test-AzureDemoDatabasePrincipalSql.ps1"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "Inline CONVERT calls removed from all three EXEC expressions; three validated GUIDs are precomputed as dedicated nvarchar(36) variables."
    - "Exact physical principals, CREATE USER FROM EXTERNAL PROVIDER WITH OBJECT_ID, fail-closed guards, grants and denials retained; no object ID hard-coded."
    - "Grants-script SHA-256 749e6631e15afe0613114529e2dd2a21e39b0c582ab5af0fecca586c41d47402."
    - "Strict structural T-SQL regression enforces exactly three literal-plus-precomputed-variable EXEC expressions; true engine compilation was unavailable and is not claimed."
    - "git diff --check; 24/24 PowerShell parses; SQL principal regression; seven-stage pipeline contract; locked restore; Release build; 27/27 focused tests; 350/350 full tests; SBOM and 170-file source/security scan passed."
  decisions:
    - "SQL principal bootstrap remains an external approved DBA action and is not automated by the pipeline."
    - "Deployment and rollback remain disabled by default."
  assumptions:
    - "The independent retest supplies the seven reviewed values through SQLCMD -v and targets only the approved controlled Azure SQL database."
  risks:
    - "True Azure SQL engine compilation/execution remains unverified until the independent controlled retest."
    - "Online NuGet vulnerability advisory retrieval was unavailable; locked restore and build emitted NU1900 warnings only."
  defects:
    - "REPAIRED: Azure SQL error 156 caused by inline CONVERT calls inside the three EXEC concatenations."
  blockers:
    - "Independent controlled Azure SQL compile/execute retest and all existing human deployment/release approvals remain required."
  approvals:
    - "Azure Platform/Operations remains PENDING_PRE_DEPLOYMENT."
  requested_action: "Independent Tester must compile and execute the reviewed grants script against only the approved controlled Azure SQL target, verify all three contained users and permissions, and publish bootstrap evidence bound to the new script hash before any separately approved deployment activity."
```

READY_FOR_SQL_EXEC_COMPILE_RETEST

## Azure DevOps Secure File delivery repair hand-off

The `DatabaseAndSlots` and `Swap` deployment jobs are the only jobs that consume `sql-bootstrap.json` or `AZDEMO_SMOKE_PREREQUISITE_EVIDENCE`. Each now independently uses `DownloadSecureFile@1` with `secureFile: sql-bootstrap.json`, copies the result to the exact filename in a job-local directory beneath `$(Agent.TempDirectory)`, applies Linux owner read/write permissions, sets the subsequent job-scoped evidence-directory variable, and removes only that directory in an `always()` cleanup step. The migration assertion, pre-swap smoke and post-swap smoke uses all follow their job's preparation step. The evidence is neither copied into the repository nor published.

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_SECURE_EVIDENCE_RETEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_85ddcec346e5b322420e7749cb840f740b977731"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-01"]
    functional_requirements: ["F-01", "F-02", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-06", "NF-10", "NF-12"]
    risks: ["R-02", "R-09", "R-11"]
    assumptions: ["A-11", "A-12", "A-18"]
    dependencies: ["D-02", "D-03", "D-04", "D-05"]
    issues: ["I-06", "I-08"]
    open_questions: ["Q-01", "Q-06", "Q-08", "Q-09"]
    approvals:
      - "Four exact-package implementation/local-test approvals at b8800e1eda014eef1421a1af5427aaea41393496."
  artefacts:
    - "azure-pipelines.yml"
    - "scripts/build/Test-AzurePipelineStructure.ps1"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "Initial branch and HEAD matched the request; the worktree and index were clean; local origin and azure branch refs matched the exact HEAD."
    - "git diff --check passed."
    - "PowerShell 5.1 parsed 29 tracked scripts and 17 pipeline inline PowerShell blocks."
    - "Pipeline structure passed for exactly seven ordered stages and independently validated both evidence-consuming jobs."
    - "SQL bootstrap evidence accepted 1 valid and rejected 6 invalid cases; database-principal SQL accepted the approved contract and rejected 30 invalid cases."
    - "Migration identity accepted 1 valid and rejected 14 invalid cases; migration target accepted 1 valid and rejected 7 invalid cases."
    - "Rollback accepted 1 valid and rejected 12 invalid targets; monitoring validated 17 alert resources."
    - "SBOM regression validated 107 API and 522 web components; the source/security boundary scan passed for 170 files."
    - "Locked restore and Release build passed; 27/27 focused Azure-demo, 205/205 unit and 145/145 integration tests passed."
  decisions:
    - "Deployment and rollback remain default-disabled."
    - "The existing seven stages, exact MTP names/service connections, workload identity, immutable package flow, commit binding and migration/rollback safeguards are unchanged."
    - "Historical note: this repair used the former exact-commit evidence rule; the later durable-evidence contract below supersedes that rule while retaining per-release approval."
  assumptions:
    - "Azure DevOps DownloadSecureFile@1 supplies its documented task-scoped secureFilePath output on the managed deployment agents."
  risks:
    - "Protected Azure DevOps task execution was prohibited and not run; runtime Secure File download/permission/cleanup evidence remains for the independent controlled retest."
    - "NuGet vulnerability advisory retrieval was unavailable in the restricted environment; locked restore and build emitted NU1900 warnings only."
  defects:
    - "REPAIRED: managed ephemeral jobs had no step that downloaded protected sql-bootstrap.json evidence."
  blockers:
    - "PowerShell 7 is not installed locally; Windows PowerShell 5.1 supplied parsing and executable regression evidence."
    - "Azure Platform/Operations and all existing human deployment/release approvals remain required before any pipeline deployment action."
  approvals:
    - "Azure Platform/Operations remains PENDING_PRE_DEPLOYMENT."
  requested_action: "Independent Tester must replace the Azure DevOps Secure File with freshly approved evidence bound to the repair commit, then retest job-local delivery and cleanup without granting open access or bypassing protected approvals."
```

READY_FOR_SECURE_EVIDENCE_RETEST

## Azure App Service native-runtime validation repair hand-off

The `PreDeploymentGate` previously captured complete `az webapp list-runtimes --os linux` TSV rows and applied PowerShell array `-notmatch` checks to colon-form values. Azure CLI 2.90 returns pipe-delimited LinuxFxVersion identifiers in the first TSV field, and array `-notmatch` returns every nonmatching catalogue row. The old expression could therefore reject an available approved runtime and could never prove exact membership of `NODE|24-lts` and `DOTNETCORE|10.0`.

The repair captures `az webapp list-runtimes --os linux --output tsv` output without writing the catalogue to the log, immediately captures `$LASTEXITCODE`, and passes both to a fail-closed validator. The validator rejects a non-zero command result, empty output, rows without a tab-delimited first field, empty or malformed identifiers, and missing exact approved identifiers. It trims only the first TSV field and uses `-notcontains` for exact membership. Successful output names only the two required runtimes. The Bicep runtime values remain unchanged.

The executable regression includes the supplied Azure CLI 2.90 rows, a minimal exact-runtime case, and unrelated valid catalogue rows. It separately rejects missing Node, missing .NET, malformed output, empty output, a non-zero native-command exit, and similarly named preview identifiers. `Test-AzurePipelineStructure.ps1` additionally pins the exact Azure CLI invocation, immediate exit-code capture, validator wiring, pipe-form identifiers, tab-field normalization, exact membership, regression execution, and absence of the former colon/array-`-notmatch` contract.

### Local verification

| Check | Result |
|---|---|
| Exact baseline | PASS: branch `fix/mtp-azure-demo-reconciliation`, HEAD `8f10616a7325ba0808370bd3f711bb34314059ce`, initially clean; index empty; local `origin` and `azure` branch refs both matched HEAD. |
| Native-runtime regression | PASS: 3 positive cases and 6 fail-closed cases. The observed Azure CLI 2.90 TSV catalogue passed with both exact approved identifiers; unrelated rows caused no false failure. |
| Pipeline structure | PASS: exactly 7 ordered stages; corrected runtime command/exit/normalization/membership contract; deployment and rollback defaults, release-branch restriction, service connections, protected evidence, migration, smoke, swap and rollback safeguards retained. |
| PowerShell 5.1 | PASS: 31 repository PowerShell scripts and 17 pipeline inline PowerShell blocks parsed with zero errors under Windows PowerShell 5.1.26100.9444. |
| Deployment/security guards | PASS: 11 required Bicep environment variables; 17 monitoring alerts; rollback 1 valid/12 rejected; migration target 1/7; migration identity 1/14; SQL bootstrap evidence 1/6; SQLCMD 7 external values, correct database and 30 rejected invalid cases; EF parsing 20 fail-closed checks. |
| Smoke safeguards | PASS plan-only: all 22 smoke contracts enumerated and the script confirmed that no endpoint, Azure, SQL, Key Vault, Storage, Entra or Azure DevOps call was made. |
| Locked restore | PASS: all projects up to date under `--locked-mode`; four `NU1900` warnings because the restricted environment could not retrieve the NuGet vulnerability service index. |
| Release build | PASS: 0 errors and 4 `NU1900` advisory-feed warnings. |
| Focused Azure Demo tests | PASS: 27/27, 0 failed, 0 skipped. |
| Unit tests | PASS: 205/205, 0 failed, 0 skipped. |
| Integration tests | PASS: 145/145, 0 failed, 0 skipped. |
| SBOM | PASS: deterministic regression for 107 NuGet and 522 npm components. |
| Source/security boundaries | PASS: 172 source/configuration files. |
| Bicep preservation | PASS: no Bicep file changed; `webLinuxFxVersion = NODE|24-lts` and `apiLinuxFxVersion = DOTNETCORE|10.0` remain exact. |
| Protected runtime | NOT RUN and not claimed: the work item prohibits Azure, Azure DevOps and pipeline access. The corrected gate still requires independent execution with Azure CLI 2.90 in the protected environment. |
| Online advisory gates | UNAVAILABLE and not passed: restricted network access prevented NuGet vulnerability-service retrieval; `NU1900` was reported accurately. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_APP_SERVICE_RUNTIME_RETEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_8f10616a7325ba0808370bd3f711bb34314059ce"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-01"]
    functional_requirements: ["F-01", "F-02", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-06", "NF-10", "NF-12"]
    risks: ["R-02", "R-09", "R-11"]
    assumptions: ["A-11", "A-12", "A-18"]
    dependencies: ["D-02", "D-03", "D-04", "D-05"]
    issues: ["I-06", "I-08"]
    open_questions: ["Q-01", "Q-06", "Q-08", "Q-09"]
    approvals:
      - "Four exact-package implementation/local-test approvals at b8800e1eda014eef1421a1af5427aaea41393496."
  artefacts:
    - "azure-pipelines.yml"
    - "scripts/build/Assert-AzureAppServiceNativeRuntimes.ps1"
    - "scripts/build/Test-AzureAppServiceNativeRuntimes.ps1"
    - "scripts/build/Test-AzurePipelineStructure.ps1"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "Exact branch/HEAD, clean worktree, empty index and aligned local origin/azure refs were confirmed before editing."
    - "The observed Azure CLI 2.90 TSV output and two other valid catalogues passed; 6 invalid/native-failure cases were rejected."
    - "31 PowerShell scripts and 17 pipeline inline blocks parsed under PowerShell 5.1; the seven-stage pipeline contract passed."
    - "Locked restore and Release build passed; 27/27 focused Azure Demo, 205/205 unit and 145/145 integration tests passed."
    - "SBOM regression validated 107 API and 522 web components; the 172-file source/security boundary scan passed."
    - "No Bicep file changed and the exact approved pipe-form runtime settings remain pinned."
  decisions:
    - "Runtime discovery fails closed on non-zero native exit, empty/malformed TSV, or absent exact required identifiers."
    - "Deployment and rollback remain default-disabled and release-branch restricted."
    - "No Azure, Azure DevOps, deployment, migration, seed, swap or rollback action was performed."
  assumptions:
    - "Azure CLI 2.90 emits the supplied tab-separated runtime rows in the protected managed deployment job."
  risks:
    - "Protected Azure CLI execution remains independently unverified until the controlled retest."
    - "Online NuGet vulnerability advisory retrieval was unavailable; locked restore and build emitted NU1900 warnings only."
  defects:
    - "REPAIRED: colon-form identifiers and array -notmatch incorrectly validated the complete Azure CLI runtime rows."
  blockers:
    - "Independent protected Azure CLI 2.90 gate execution and all existing Azure Platform/Operations and human deployment/release approvals remain required."
  approvals:
    - "Azure Platform/Operations remains PENDING_PRE_DEPLOYMENT."
  requested_action: "Independent Tester must run the corrected PreDeploymentGate in the protected Azure CLI 2.90 environment and confirm both exact approved native runtimes pass without catalogue disclosure."
```

READY_FOR_APP_SERVICE_RUNTIME_RETEST

## Azure Demo private-DNS reconciliation repair hand-off

### Failed deployment and bounded repair

Pipeline run `20261002.13` / Azure build `17` failed in incremental deployment `mtp-azure-demo-17`, nested deployment `network-mtp-dev-uks-001`. The failure occurred before migration, synthetic seed reconciliation and application staging-slot deployment. Because the ARM deployment mode was incremental, unrelated operations submitted before the nested failure could nevertheless have partially completed; this repair does not infer or overwrite their state.

The authoritative reconciliation inventory identifies one existing SQL private DNS zone/link pair and three missing parent zones:

- `privatelink.database.windows.net` and exact existing link `link-mtp-dev-vnet` are adopted by their current identities. The SQL zone remains an `existing` Bicep resource, while the exact existing child link is declaratively managed with `registrationEnabled: false` against `/subscriptions/633398e2-6c00-4bb7-a576-2db0d210ee77/resourceGroups/Onkar.Pathre/providers/Microsoft.Network/virtualNetworks/vnet-mtp-dev-uks-001`. No delete, rename, temporary link or second SQL-zone/VNet link is introduced.
- `privatelink.vaultcore.azure.net`, `privatelink.azurewebsites.net` and `privatelink.blob.core.windows.net` are now deployable Bicep parent resources. Each has exactly one deterministic child link named `link-mtp-dev-uks-001`, with `registrationEnabled: false`, and each child uses a symbolic `parent:` reference. Compiled ARM dependencies require each managed parent before its child link.
- Private-endpoint DNS-zone-group bindings remain unchanged and use the four network-module zone resource IDs for SQL, Key Vault, App Service and Blob respectively.
- The protected predeployment gate still requires the SQL zone to exist, then enumerates its VNet links and fails closed unless the exact link name, approved VNet ID, disabled registration, `Succeeded` provisioning state and single-link-per-target contract all hold. The other three zones are not pre-existence prerequisites because Bicep owns their creation.
- Repeated incremental deployment is idempotent because all four zone/link resource identities are stable. The expected protected what-if is no deletion or replacement of the SQL zone/link, creation of the three missing zones and creation of their three approved links. Protected what-if was not executed locally.

No variable-group or environment-variable change is required. The seven-stage pipeline, disabled-by-default deployment and rollback parameters, release-branch condition, service connections, workload identities, SQL bootstrap evidence handling, runtime validation, migration, smoke, swap and rollback controls remain intact.

### Local verification

| Check | Result |
|---|---|
| Exact baseline | PASS before editing: branch `fix/mtp-azure-demo-reconciliation`; HEAD `a49ecd256999400635772c0efbd8e0f8501a5b09`; worktree clean; staged index empty; local branch, `origin/fix/mtp-azure-demo-reconciliation` and `azure/fix/mtp-azure-demo-reconciliation` all resolved to the exact HEAD. |
| Diff and changed-file boundary | PASS: `git diff --check` exited 0; the exact nine-file allowlist matched; the staged index remained empty. No application, EF migration, database schema/seed, dependency, identity, SQL principal, runtime, service-connection or variable-group file changed. |
| Private-DNS regression | PASS: one exact existing SQL inventory accepted; six invalid inventories rejected for missing/wrong link name, wrong VNet, `registrationEnabled=true`, failed provisioning and duplicate target link. Four deterministic zone/link identities and all private-endpoint zone-group bindings passed. |
| Pipeline structure | PASS: exactly seven ordered stages; the SQL zone pre-existence check, link enumeration, native exit capture and fail-closed validation occur before what-if. Existing default, branch, service-connection, evidence, migration, smoke, swap and rollback contracts passed. |
| PowerShell 5.1 | PASS: 33 repository PowerShell files and 17 pipeline inline PowerShell blocks parsed with zero errors. |
| Bicep CLI 0.47.16 | PASS using `0.47.16 (3f73e1a234)`: all Bicep/Bicepparam format comparisons were identical; main lint/build exited 0; both parameter builds with synthetic values exited 0. The only output was the repository's existing experimental Assertions warning. |
| Compiled DNS contract | PASS: only SQL compiles as an existing zone; three zones compile as managed parents; four VNet links compile with registration disabled; all three new-zone links compile with parent dependencies; the SQL link compiles from the SQL-specific exact-name parameter. |
| Parameter/runtime regression | PASS: 11 synthetic parameter environment values accepted; App Service runtime regression accepted three valid catalogues and rejected six invalid/native-failure cases. |
| Monitoring and rollback guards | PASS: 17 mandatory alert resources; rollback accepted one valid target and rejected 12 invalid targets. |
| Migration and SQL guards | PASS: migration target 1 valid/7 rejected; migration identity 1 valid/14 rejected; SQL bootstrap evidence 1 valid/6 rejected; SQLCMD contract retained seven external variables and rejected 30 invalid cases; EF parsing passed 20 fail-closed checks. |
| Smoke safeguards | PASS plan-only: all 22 smoke contracts enumerated and no endpoint, Azure, SQL, Key Vault, Storage, Entra or Azure DevOps call was made. An initial invocation without the script's mandatory local-only arguments exited 1; the corrected plan-only command exited 0. |
| Locked restore | PASS, exit 0: all projects up to date under `--locked-mode`; four `NU1900` warnings accurately report that the restricted environment could not reach the NuGet vulnerability service index. |
| Release build | PASS, exit 0: 0 errors and the same four `NU1900` advisory-feed warnings. |
| Focused Azure Demo tests | PASS: 27/27, 0 failed, 0 skipped. |
| Unit tests | PASS: 205/205, 0 failed, 0 skipped. |
| Integration tests | PASS: 145/145, 0 failed, 0 skipped. |
| SBOM regression | PASS: deterministic inventories for 107 NuGet and 522 npm components. |
| Source/security boundaries | PASS: 174 source/configuration files; no prohibited capability or secret boundary regression. |
| Protected Azure what-if/deployment | NOT RUN and not claimed. Command: `az deployment group what-if --resource-group Onkar.Pathre --template-file infra/bicep/main.bicep --parameters infra/bicep/parameters/azure-demo.bicepparam --no-pretty-print`. Exit code: not applicable because execution was prohibited. Blocker: this work item expressly forbids Azure/Azure DevOps access, pipeline execution and deployment. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_PRIVATE_DNS_RECONCILIATION_RETEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_a49ecd256999400635772c0efbd8e0f8501a5b09"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-01"]
    functional_requirements: ["F-01", "F-02", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-06", "NF-10", "NF-12"]
    risks: ["R-02", "R-09", "R-11"]
    assumptions: ["A-11", "A-12", "A-18"]
    dependencies: ["D-02", "D-03", "D-04", "D-05"]
    issues: ["I-06", "I-08"]
    open_questions: ["Q-01", "Q-06", "Q-08", "Q-09"]
    approvals:
      - "Four exact-package implementation/local-test approvals at b8800e1eda014eef1421a1af5427aaea41393496."
  artefacts:
    - "azure-pipelines.yml"
    - "infra/bicep/main.bicep"
    - "infra/bicep/modules/network.bicep"
    - "infra/bicep/parameters/azure-demo.bicepparam"
    - "infra/bicep/parameters/dev.bicepparam"
    - "scripts/build/Assert-AzureDemoPrivateDnsReconciliation.ps1"
    - "scripts/build/Test-AzureDemoPrivateDnsReconciliation.ps1"
    - "scripts/build/Test-AzurePipelineStructure.ps1"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "Exact baseline, clean worktree, empty index and aligned local origin/azure refs were confirmed before editing."
    - "Bicep 0.47.16 format, lint/build, both synthetic parameter builds and compiled parent/dependency assertions passed."
    - "The exact existing SQL link passed; six malformed, missing, wrong-target, registration, provisioning and duplicate cases failed closed."
    - "Locked restore and Release build passed; 27/27 focused Azure Demo, 205/205 unit and 145/145 integration tests passed."
    - "All requested local pipeline, runtime, monitoring, rollback, migration, SQL evidence, SBOM and source/security guards passed."
  decisions:
    - "Preserve and manage the existing SQL link by exact resource identity; do not create, rename or replace it."
    - "Create only the three missing private DNS parent zones and their deterministic links, with symbolic parent dependencies."
    - "No variable-group or Bicep environment-parameter change is required."
    - "Deployment and rollback remain default-disabled and release-branch restricted."
    - "Nothing was staged, committed, pushed, merged, deployed, migrated, seeded, swapped or rolled back."
  assumptions:
    - "The supplied authoritative inventory accurately describes the four private DNS zones and the existing SQL link before protected retest."
  risks:
    - "The prior incremental deployment may have partially completed unrelated operations; protected inventory and what-if must reconcile the current state before deployment."
    - "Actual Azure what-if and repeat-deployment idempotency remain for independent protected retest."
    - "Online NuGet advisory retrieval was unavailable; restore/build succeeded with NU1900 warnings and no vulnerability-pass claim."
  defects:
    - "REPAIRED: a new SQL link name conflicted with the existing zone/VNet link."
    - "REPAIRED: Key Vault, App Service and Blob links were submitted beneath missing parent zones."
  blockers:
    - "Protected Azure what-if, deployment and repeat-deployment evidence require independent execution under existing human/platform controls."
  approvals:
    - "No approval evidence was regenerated or replaced."
  requested_action: "Independent Tester must execute the protected SQL inventory gate and Bicep what-if, confirm the exact no-delete/no-replacement and three-zone/create plan, then perform the separately approved initial and repeat incremental deployments before migration, seed or application deployment can proceed."
```

READY_FOR_PRIVATE_DNS_RECONCILIATION_RETEST

## Azure Demo App Service integration-subnet reconciliation repair hand-off

### Build 19 failure and bounded repair

Azure build `19` failed during incremental deployment `mtp-azure-demo-19`, nested deployment `apps-mtp-dev-uks-001`, while reconciling `Microsoft.Web/sites/app-mtp-api-dev-uks-001/slots/staging`. ARM could not resolve the stale subnet name `snet-appsvc-integration`. The supplied deployment record is:

- nested deployment `data`: `Succeeded`;
- nested deployment `identities`: `Succeeded`;
- nested deployment `monitoring`: `Succeeded`;
- nested deployment `network`: `Succeeded`;
- nested deployment `apps`: `Failed`; and
- migration, synthetic seed reconciliation, package deployment, smoke testing and slot swap did not run.

Because deployment mode was incremental, resources unrelated to the failed App Service operation may have been reconciled before the nested app failure. This repair therefore adopts the supplied authoritative inventory and does not infer that the failed deployment was atomic.

The approved VNet is `vnet-mtp-dev-uks-001` (`10.50.0.0/16`). Bicep continues to reference the VNet and both subnets as symbolic `existing` resources. It now resolves the App Service integration subnet as `/subscriptions/633398e2-6c00-4bb7-a576-2db0d210ee77/resourceGroups/Onkar.Pathre/providers/Microsoft.Network/virtualNetworks/vnet-mtp-dev-uks-001/subnets/snet-appservice` from the existing VNet/subnet symbols; the subscription ID is not embedded in Bicep. The integration subnet remains `snet-appservice` (`10.50.1.0/24`) with exactly the `Microsoft.Web/serverFarms` service delegation. The separate private-endpoint subnet remains `snet-private-endpoints` (`10.50.2.0/24`). No subnet resource, prefix, delegation or VNet address space is created or changed.

The reviewed architecture requires web production and web staging to use regional VNet integration. `AZURE_DEMO_Deployment_Architecture.md` defines the web application as the same-origin proxy to private API endpoints and assigns the delegated subnet to web/API sites and slots. The reconciled topology therefore attaches web production, web staging, API production and API staging to the same existing `snet-appservice` subnet. The two existing API assignments are retained; the two web assignments close the implementation gap rather than expanding the approved architecture.

The protected predeployment gate now inventories the VNet, its subnets and actual `Microsoft.Network/privateEndpoints` resources through separate Azure CLI list commands. Each native exit code is captured immediately. Validation rejects command failure, empty or malformed JSON, missing/duplicate/wrong VNet or subnet matches, the stale subnet name, wrong IDs/prefixes/delegations/provisioning state, an absent or reshaped private-endpoint subnet, and any actual private-endpoint resource whose `subnet.id` targets `snet-appservice`. Provider-managed App Service `privateEndpoints` and `serviceAssociationLinks` collections on the subnet model are deliberately ignored as placement evidence; only independently enumerated `Microsoft.Network/privateEndpoints` resources are evaluated.

No variable-group or environment-variable change is required. The seven stages, both default-disabled deployment controls, release-branch restriction, service connections, workload identities, Secure File evidence handling, private-DNS reconciliation, exact resource/identity names, SQL aliases/grants, runtime settings, migration/seed/smoke/swap/rollback safeguards and repository-contained immutable package flow remain unchanged.

This hand-off originally applied the former exact-commit evidence rule. The durable-evidence repair below supersedes that rule: SQL-bootstrap evidence from `9939709021ed84bfcdbcf778569624865857d280` may be reused by descendants only when ancestry, age, target/identity/executor and exact grants-script hash all pass; every final release commit still needs fresh release approval.

### Local verification

| Check | Result |
|---|---|
| Exact baseline | PASS before editing: branch `fix/mtp-azure-demo-reconciliation`; HEAD `9939709021ed84bfcdbcf778569624865857d280`; worktree clean; staged index empty; local branch, `origin/fix/mtp-azure-demo-reconciliation` and `azure/fix/mtp-azure-demo-reconciliation` all resolved to the exact HEAD. |
| App Service subnet regression | PASS: one exact inventory containing provider-managed App Service association metadata was accepted; 24 fail-closed inventories were rejected; both parameter files, both symbolic existing-subnet resources and all four site/slot integration assignments were verified. |
| Pipeline structure | PASS: exactly seven ordered stages; native VNet/subnet/private-endpoint outputs and exit codes are captured before the fail-closed validator; validation precedes Bicep what-if and the dependent deployment stage. Existing release, service-connection, evidence, migration, smoke, swap and rollback contracts passed. |
| PowerShell 5.1 | PASS under `5.1.26100.9444`: 35 repository PowerShell files and 17 pipeline inline PowerShell blocks parsed with zero errors. |
| Private DNS | PASS: one exact existing SQL inventory accepted; six invalid inventories rejected; four deterministic parent/link and zone-group contracts preserved. |
| Parameter/runtime | PASS: 11 synthetic parameter values accepted; native runtime regression accepted three catalogues and rejected six invalid/native-failure cases. |
| Monitoring/rollback | PASS: 17 mandatory alerts; rollback accepted one exact target and rejected 12 invalid targets. |
| Migration/SQL/EF | PASS: migration target 1/7, migration identity 1/14, SQL bootstrap evidence 1/6, SQLCMD contract seven external variables and 30 invalid cases, and 20 EF parser checks. |
| Restore/build/format | PASS: locked restore exit `0`; Release build exit `0` with zero errors; scoped `dotnet format --verify-no-changes` exit `0`. Restore/build reported four `NU1900` warnings because the restricted environment could not reach the NuGet vulnerability service; no connected vulnerability-pass claim is made. |
| .NET tests | PASS: focused Azure Demo 27/27; full unit 205/205; full integration 145/145; zero failed or skipped. |
| SBOM/source boundaries | PASS: deterministic 107 NuGet and 522 npm component inventories; source/security boundary scan passed. |
| Bicep 0.47.16 format/lint/build and compiled regression | UNAVAILABLE, not passed. `az bicep version`, `az bicep format --file infra/bicep/main.bicep --stdout`, `az bicep build --file infra/bicep/main.bicep --outfile .codex-temp/appservice-subnet-main.json`, and both `az bicep build-params` commands each exited `1`: `az` is not installed or available on `PATH`. No compiled template was produced, so the compiled-mode subnet and private-DNS regressions could not run. |
| Protected Azure checks | NOT RUN and not claimed. The work item prohibits Azure/Azure DevOps access, pipeline execution, what-if, deployment, migration, seed, smoke, swap and rollback. Protected inventory, what-if, initial deployment and repeat incremental deployment remain independent retest actions. |

The source-level idempotency contract passes: the exact VNet and both subnets are `existing`, names are stable, subnet shape is absent from Bicep, and all four App Service resources consume the same symbolic subnet ID. Actual repeat incremental-deployment idempotency cannot be claimed until protected retest.

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_APP_SERVICE_SUBNET_RETEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_9939709021ed84bfcdbcf778569624865857d280"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-01"]
    functional_requirements: ["F-01", "F-02", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-06", "NF-10", "NF-12"]
    risks: ["R-02", "R-09", "R-11"]
    assumptions: ["A-11", "A-12", "A-18"]
    dependencies: ["D-02", "D-03", "D-04", "D-05"]
    issues: ["I-06", "I-08"]
    open_questions: ["Q-01", "Q-06", "Q-08", "Q-09"]
    approvals: []
  artefacts:
    - "azure-pipelines.yml"
    - "docs/architecture/AZURE_DEMO_Deployment_Architecture.md"
    - "docs/architecture/AZURE_DEMO_Environment_Configuration.md"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
    - "infra/bicep/main.bicep"
    - "infra/bicep/modules/appservice.bicep"
    - "infra/bicep/parameters/azure-demo.bicepparam"
    - "infra/bicep/parameters/dev.bicepparam"
    - "scripts/build/Assert-AzureDemoAppServiceSubnet.ps1"
    - "scripts/build/Test-AzureDemoAppServiceSubnet.ps1"
    - "scripts/build/Test-AzurePipelineStructure.ps1"
  evidence:
    - "Exact baseline, clean worktree, empty index and aligned local/origin/azure refs were confirmed before editing."
    - "The exact existing subnet inventory passed; 24 command, JSON, identity, prefix, delegation, provisioning and private-endpoint placement cases failed closed."
    - "All locally available pipeline, DNS, parameter, runtime, monitoring, rollback, migration, SQL, EF, SBOM, source/security, build and test checks passed."
  decisions:
    - "Adopt only the existing snet-appservice regional-integration subnet; do not create or reshape a subnet."
    - "Attach web production, web staging, API production and API staging to snet-appservice as required by the reviewed private-API proxy architecture."
    - "Treat only actual independently enumerated Microsoft.Network/privateEndpoints resources as private-endpoint placement evidence."
    - "Retain snet-private-endpoints as the separate private-endpoint subnet."
    - "No variable-group or Bicep environment-parameter change is required."
  assumptions:
    - "The supplied authoritative Azure inventory and build-19 deployment record are accurate."
  risks:
    - "Build 19 may have reconciled unrelated incremental resources before the apps nested deployment failed."
    - "Compiled Bicep and protected Azure initial/repeat deployment evidence remain unavailable locally."
    - "Historical note: the then-current exact-commit bootstrap-evidence rule is superseded by the durable ancestor-and-contract validation below; per-release approval remains exact-commit-bound."
  defects:
    - "REPAIRED: both parameter files selected the nonexistent snet-appsvc-integration subnet."
    - "REPAIRED: web production and web staging omitted regional VNet integration required by the reviewed architecture."
    - "REPAIRED: the protected gate did not validate the exact existing integration subnet or actual private-endpoint placement before what-if."
  blockers:
    - "Bicep CLI 0.47.16 is unavailable in the local environment."
    - "Protected Azure inventory, what-if, initial deployment and repeat incremental deployment require independent execution under existing approvals."
    - "Fresh release approval remains required; fresh sql-bootstrap.json is required only on target/security-contract change, expiry or revocation."
  approvals: []
  requested_action: "Independent Tester must rerun Bicep 0.47.16 compilation/regressions, execute the protected subnet inventory gate and what-if, verify all four site/slot integrations, then perform separately approved initial and repeat incremental deployments before migration, seed, package deployment, smoke or swap can proceed."
```

READY_FOR_APP_SERVICE_SUBNET_RETEST

## Durable SQL-bootstrap evidence repair hand-off

The SQL-bootstrap Secure File remains job-local and unchanged in schema. Its `sourceCommit` is now the immutable bootstrap provenance commit rather than the application release commit. The validator rejects malformed or missing commit objects, missing Git, shallow/incomplete history and every native Git error, then accepts only exit `0` from `git merge-base --is-ancestor <evidenceSourceCommit> <expectedReleaseCommit>`; exit `1` is a non-ancestor rejection and every other exit is a validation failure. It performs no fetch or pull. The checked-out `HEAD` must equal exact `Build.SourceVersion`.

The durable evidence remains bound to schema version `1`, `PASS`, the exact approved SQL server/database, migration identity name/client/object IDs, executor SQL-administrator object ID, non-empty evidence/approval references, strict UTC `recordedAtUtc`, and the lowercase SHA-256 of the current grants script. Maximum age is 90 days with at most five minutes of clock-skew tolerance. Complete Git history is checked out in `DatabaseAndSlots`; Secure File download, exact filename, temporary location, Linux permissions and `always()` cleanup are unchanged.

SQL-bootstrap approval and release approval remain independent. The former approves the database principal/grant contract. The latter is required for every exact application/Bicep/pipeline `Build.SourceVersion` and retains the release branch, protected environment/manual gate, immutable package/manifest, default-disabled deployment/rollback, service-connection and workload-identity controls. An SQL-bootstrap `approvalReference` is not release approval.

Evidence provenance `9939709021ed84bfcdbcf778569624865857d280` remains eligible for a descendant repair release on the supplied facts: the object is present, `git merge-base --is-ancestor` exits `0`, and `Configure-AzureDemoDatabasePrincipals.sql` is unchanged at SHA-256 `aa78888d54e7399d51a87a8daa9413c0ab9c01e7d0b447ef36df069d87c28eed`. Runtime acceptance still fails closed if the protected record's age, status, target, identities, executor, IDs, approval reference or revocation state no longer passes; the live Secure File was not accessed.

### Local verification

| Check | Result |
|---|---|
| Exact baseline | PASS before editing: branch `fix/mtp-azure-demo-reconciliation`; HEAD `7cb1124661bc7566b3d12943bf6ddf24fa9db2eb`; clean worktree; empty staged index; local, `origin` and `azure` branch refs aligned. |
| Durable evidence regression | PASS: 4 accepted cases and 24 fail-closed cases, including equal/ancestor acceptance; unrelated, descendant, malformed, missing-object, shallow-history, Git-failure, target/identity/executor/hash/ID/age/timestamp rejection. |
| Pipeline structure and Secure File | PASS: exactly seven ordered stages; exact `Build.SourceVersion`, complete-history checkout, mandatory ancestry/hash/90-day controls, two protected Secure File consumers, job-local temporary handling and cleanup, release controls, and default-disabled deployment/rollback retained. |
| PowerShell 5.1 | PASS under `5.1.26100.9444`: 35 tracked scripts and 17 pipeline PowerShell blocks parsed with zero errors. |
| Preserved repair regressions | PASS: EF parsing 20 fail-closed checks; App Service subnet 1 accepted/24 rejected plus four site/slot integrations; private DNS 1/6; migration identity 1/14; migration target 1/7; SQL principal 30 invalid cases; rollback 1/12; monitoring 17 alert resources; smoke plan enumerated 22 checks without external access. |
| Restore/build/tests | PASS: locked restore and Release build exited `0` with zero errors; focused Azure Demo 27/27, unit 205/205 and integration 145/145 passed. Four `NU1900` warnings accurately record unavailable NuGet advisory-index access. |
| Package-generation regression | UNAVAILABLE against the current ignored artifact cache: `powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File scripts/build/Test-AzureDemoPackageGeneration.ps1` exited `1` because `artifacts/azure-demo-ci/packages/application/application-artifact-manifest.json` is absent. Its outside-repository and prefix-confusion guards passed first. No package was generated for this unrelated evidence change; pipeline structure still pins repository-contained immutable package generation and manifest validation. |
| SBOM/security | PASS: deterministic 107 NuGet/522 npm component SBOM regression; source/security boundary scan passed 176 files. |
| Diff/index | PASS: exact seven-file allowlist; `git diff --check` exit `0`; staged index empty. |
| Prohibited/external checks | NOT RUN: no Azure, Azure DevOps, live Secure File, SQL, pipeline, deployment, migration, seed, swap or rollback access/action was permitted. Exit code not applicable because commands were not invoked. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_DURABLE_SQL_EVIDENCE_RETEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_7cb1124661bc7566b3d12943bf6ddf24fa9db2eb"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-01"]
    functional_requirements: ["F-01", "F-02", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-06", "NF-10", "NF-12"]
    risks: ["R-02", "R-09", "R-11"]
    assumptions: ["A-11", "A-12", "A-18"]
    dependencies: ["D-02", "D-03", "D-04", "D-05"]
    issues: ["I-06", "I-08"]
    open_questions: ["Q-01", "Q-06", "Q-08", "Q-09"]
    approvals:
      - "Four exact-package implementation/local-test approvals at b8800e1eda014eef1421a1af5427aaea41393496."
  artefacts:
    - "azure-pipelines.yml"
    - "docs/architecture/AZURE_DEMO_Deployment_Architecture.md"
    - "docs/architecture/AZURE_DEMO_Environment_Configuration.md"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
    - "scripts/build/Test-AzureDemoSqlBootstrapEvidence.ps1"
    - "scripts/build/Test-AzurePipelineStructure.ps1"
    - "scripts/database/Assert-AzureDemoSqlBootstrapEvidence.ps1"
  evidence:
    - "All local checks in the durable-evidence verification table passed against the unstaged worktree."
    - "Provenance commit 9939709021ed84bfcdbcf778569624865857d280 is present and an ancestor; the grants script retains the supplied exact SHA-256."
  decisions:
    - "Reuse valid SQL evidence across descendant releases only while its target/security contract, age and status remain valid."
    - "Require fresh human release approval for every final exact Build.SourceVersion."
    - "Regenerate SQL evidence only when its target/security contract changes, expires or is revoked."
  assumptions:
    - "The supplied protected evidence contract accurately describes the inaccessible live Secure File."
  risks:
    - "Live Secure File fields and revocation state remain runtime-validated but were not inspected."
    - "NuGet online vulnerability advisory retrieval was unavailable in the restricted environment."
  defects:
    - "REPAIRED: unrelated descendant commits no longer force SQL principal bootstrap repetition or Secure File replacement."
    - "REPAIRED: provenance ancestry, finite age and exact executor validation now fail closed."
  blockers:
    - "Independent Tester retest and the normal exact-commit human release approval remain required."
    - "Azure Platform/Operations remains PENDING_PRE_DEPLOYMENT."
  approvals: []
  requested_action: "Independent Tester must retest the durable evidence contract and confirm live pipeline controls without treating SQL-bootstrap approval as release approval."
```

READY_FOR_DURABLE_SQL_EVIDENCE_RETEST

## Compiled App Service subnet regression repair hand-off

### Root cause and bounded repair

The Bicep 0.47.16 build succeeded, but the compiled regression then assumed that every symbolic App Service resource exposed `properties.virtualNetworkSubnetId` as a directly addressable PowerShell property. `webConfiguration` and `apiConfiguration` use `properties: union(...)`; their legitimate compiled ARM representation can therefore be a scoped expression string containing `createObject('virtualNetworkSubnetId', parameters('integrationSubnetId'))`. Strict-mode property access failed before the validator could prove the subnet reference.

`Test-AzureDemoAppServiceSubnet.ps1` now validates each of the four exact symbolic compiled resource nodes independently. It accepts either one direct structured property with the exact value `[parameters('integrationSubnetId')]` or one scoped `union(...)` expression that pairs the exact `virtualNetworkSubnetId` key with the exact `integrationSubnetId` parameter. Each symbolic resource must exist uniquely, and the resource collection must contain exactly four approved assignments. The validator does not search the complete nested template and does not accept a parameter declaration or a reference in another resource as evidence.

Fixtures accept the direct and union-expression shapes and reject missing, substituted, stale-literal, other-resource-only, declaration-only, missing-symbol, fewer-than-four and more-than-four cases. No Bicep, pipeline, network, deployment, SQL or runtime file changed. The source contract remains exactly four assignments across `webConfiguration`, `webSlot`, `apiConfiguration` and `apiSlot`; both subnets remain symbolic `existing` resources with the approved names and shapes.

### Local verification

| Check | Result |
|---|---|
| Exact baseline | PASS before editing: branch `fix/mtp-azure-demo-reconciliation`; HEAD `08e8d8f3cef4412a58c6366807e4c1e0a37e9c07`; clean worktree; empty staged index; local, `origin` and `azure` branch refs aligned. |
| PowerShell 5.1 | PASS under `5.1.26100.9444`: all 35 tracked PowerShell scripts parsed with zero errors. |
| App Service subnet regression | PASS: one exact existing-subnet inventory and two compiled shapes accepted; 24 inventory and eight compiled-shape cases rejected; exactly four source site/slot assignments and both symbolic existing-subnet contracts verified. |
| Pipeline structure | PASS: exactly seven ordered stages; compiled subnet and private-DNS regressions remain after Bicep build; default-disabled deployment/rollback, release restriction, Secure File, migration, smoke, swap and rollback controls retained. |
| Private DNS | PASS: one valid inventory accepted; six invalid inventories rejected; four deterministic parent/link and zone-group contracts retained. |
| Durable SQL-bootstrap evidence | PASS: four accepted and 24 fail-closed cases; descendant reuse remains bound to ancestry, age, target, identity, executor and exact grants-script hash. |
| Bicep 0.47.16 compiled-template execution | UNAVAILABLE, not passed: neither `bicep` nor `az` is installed or available on local `PATH`. No real compiled `main.json` pass is claimed; `mtp-azure-demo-deploy` must independently retest the compiled template. |
| External/protected actions | NOT RUN: no Azure, Azure DevOps, pipeline, deployment, SQL, migration, seed, smoke, swap or rollback action was performed. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_COMPILED_SUBNET_REGRESSION_RETEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_08e8d8f3cef4412a58c6366807e4c1e0a37e9c07"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-01"]
    functional_requirements: ["F-01", "F-02", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-06", "NF-10", "NF-12"]
    risks: ["R-02", "R-09", "R-11"]
    assumptions: ["A-11", "A-12", "A-18"]
    dependencies: ["D-02", "D-03", "D-04", "D-05"]
    issues: ["I-06", "I-08"]
    open_questions: ["Q-01", "Q-06", "Q-08", "Q-09"]
    approvals:
      - "Four exact-package implementation/local-test approvals at b8800e1eda014eef1421a1af5427aaea41393496."
  artefacts:
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
    - "scripts/build/Test-AzureDemoAppServiceSubnet.ps1"
  evidence:
    - "Exact clean baseline, empty index and aligned local/origin/azure refs were confirmed before editing."
    - "Direct and union compiled fixtures pass; missing, substituted, literal, out-of-scope, missing-symbol and wrong-count fixtures fail closed."
    - "PowerShell parsing, source subnet, pipeline structure, private-DNS and durable SQL-evidence regressions pass locally."
  decisions:
    - "Inspect only each exact compiled resource node and require the subnet key to bind to parameters('integrationSubnetId')."
    - "Retain exactly four approved source and compiled VNet-integration assignments."
    - "Do not change Bicep deployment semantics for a validator representation defect."
  assumptions: []
  risks:
    - "Bicep CLI 0.47.16 and Azure CLI are unavailable locally; the real compiled main.json remains to be independently retested."
  defects:
    - "REPAIRED: compiled validation no longer dereferences a property that is legitimately represented by a scoped ARM union expression."
    - "REPAIRED: compiled validation now rejects missing, substituted, literal, out-of-resource and wrong-count references."
  blockers:
    - "Independent pipeline retest with Bicep CLI 0.47.16 remains required."
    - "Azure Platform/Operations remains PENDING_PRE_DEPLOYMENT."
  approvals: []
  requested_action: "Independent Tester must rerun mtp-azure-demo-deploy compilation with Bicep 0.47.16 and confirm the scoped four-resource validator passes while the existing protected gates remain unchanged."
```

READY_FOR_COMPILED_SUBNET_REGRESSION_RETEST
