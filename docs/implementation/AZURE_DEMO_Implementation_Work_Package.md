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
- **Developer state:** `READY_FOR_EF_BUNDLE_EXECUTION_RETEST` with the real Linux regression and protected execution retest outstanding.

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
- The EF bundle and seed reconciliation each run inside a separate `AzureCLI@2` task bound literally to `sc-mtp-azure-demo-migration-dev-v2` (validated service-connection ID `d472ce79-141c-4b8c-861a-4dd009b4c6a2`). Each task independently establishes authentication; no Azure CLI context or token is assumed to cross a task boundary.
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
    - "EF migration and seed each authenticate independently through sc-mtp-azure-demo-migration-dev-v2 and use explicit workload-identity SQL authentication."
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

## PowerShell 7/Linux SQL-bootstrap evidence regression repair hand-off

### Pipeline failure and exact root cause

On branch `fix/mtp-azure-demo-reconciliation` at release-test commit `847b68d8791876c63d486167293a86541dd44b8c`, the Linux managed-agent task **Valid and invalid independent SQL bootstrap evidence tests** rejected its first accepted fixture, where the evidence commit equals the release commit. The failure occurred before Git repository or ancestry validation and was reported only through the former compound metadata error.

The cross-platform defect was the handling of `recordedAtUtc` after JSON deserialization. Windows PowerShell 5.1 leaves the ISO-8601 JSON value as a string, while PowerShell 7 recognizes it as a `DateTime`. The validator cast that runtime object back to string before applying its literal-`Z` regular expression. On PowerShell 7 this no longer represented the original JSON token, so valid synthetic evidence failed the UTC syntax branch of the compound predicate. Git identity was already configured and Git setup exit codes were already checked; neither was the defect.

### Bounded repair

`Assert-AzureDemoSqlBootstrapEvidence.ps1` now validates the original `recordedAtUtc` JSON token before PowerShell can change its runtime type. It requires exactly one top-level evidence property and one unescaped string token, a literal trailing `Z`, seconds with either no fractional part or exactly one through seven fractional digits, invariant-culture `DateTimeOffset.TryParseExact`, and `AssumeUniversal -bor AdjustToUniversal`. Future evidence still permits only five minutes of clock skew and evidence still expires after 90 days.

The former compound predicate is replaced by ordered fail-closed checks with stable, value-free reason codes for schema, status, source-commit format, SQL target, migration identity name/client/object IDs, executor GUID format and mismatch, evidence ID, approval reference, timestamp syntax/future/expiry, and grants-hash format/mismatch. Executor parsing uses one dedicated typed local `Guid`, parses once, rejects empty or malformed values and compares typed GUIDs. The grants hash remains the SHA-256 of the original script bytes, must be exactly 64 lowercase hexadecimal characters, and is compared with `StringComparison.Ordinal`; no newline conversion or text reserialization is performed.

`Test-AzureDemoSqlBootstrapEvidence.ps1` now writes deterministic UTF-8-without-BOM fixtures, disables Git newline conversion in its isolated repository, formats timestamps with invariant culture, proves every accepted UTC fractional-second width, and asserts every safe metadata rejection category exactly. Rejection messages are checked not to contain protected fixture values. An accepted-case failure now reports the exact safe rejection message rather than the former aggregate metadata message.

All durable evidence and pipeline semantics remain unchanged: equal and ancestor commits are accepted; descendants, unrelated commits, missing objects, shallow history and native Git failures are rejected; checked-out `HEAD` must equal `ExpectedReleaseCommit`; no fetch or pull occurs; target, principals, executor and grants-script hash remain exact. The seven-stage pipeline, default-disabled deployment and rollback, Secure File handling, release-branch restriction, workload-identity authentication, App Service subnet repair and private-DNS reconciliation are unchanged.

### Verification evidence

| Check | Result |
|---|---|
| Exact baseline | PASS before editing: branch `fix/mtp-azure-demo-reconciliation`; HEAD `847b68d8791876c63d486167293a86541dd44b8c`; clean worktree; empty staged index; local branch and `origin`/`azure` tracking refs aligned exactly. |
| Windows PowerShell 5.1 parsing | PASS under `5.1.26100.9444`: all 35 tracked PowerShell scripts parsed with zero errors. |
| SQL-bootstrap evidence regression | PASS: 10 accepted cases and 33 fail-closed cases across all 17 stable metadata-rejection categories. Equal/ancestor provenance, all supported timestamp precisions, malformed/empty/mismatched executor GUIDs, age/skew, exact target/identity/hash, unavailable/malformed evidence and all ancestry failure modes are covered. |
| Culture determinism | PASS under Windows PowerShell 5.1 with `en-US`, `ar-SA` and `th-TH`: each run passed 10 accepted and 33 fail-closed cases across 17 categories. |
| Pipeline structural regression | PASS: exactly seven ordered stages; `deployAzureDemo` and `rollbackAzureDemo` remain default `false`; existing Secure File, release restriction, workload identity, migration, smoke, swap and rollback controls passed. |
| App Service subnet regression | PASS: one exact inventory and two compiled shapes accepted; 24 inventory and eight compiled-shape cases rejected; four site/slot integrations and two existing-subnet contracts verified. |
| Private-DNS regression | PASS: one valid inventory accepted; six invalid inventories rejected; four deterministic parent/link and zone-group contracts verified. |
| Migration identity and target regressions | PASS: identity one valid/14 rejected; target one valid/seven rejected. |
| Database-principal SQL regression | PASS: seven external variables retained, correct database accepted, 30 invalid cases rejected, and all three approved `CREATE USER` expressions retained. |
| Rollback safeguards | PASS: one valid target and 12 fail-closed target cases. |
| Source/security boundary scan | PASS: 176 source/configuration files scanned. |
| PowerShell 7/Linux execution | UNAVAILABLE locally and not claimed: `pwsh` is not installed; WSL reports that no Linux subsystem is installed; Docker and Podman are unavailable. The Linux managed-agent pipeline task must be rerun independently. |
| Protected/external actions | NOT RUN: no Azure, Azure DevOps, live Secure File, SQL, pipeline, deployment, migration, seed, swap or rollback access/action occurred. Protected `sql-bootstrap.json` was neither accessed nor regenerated. |
| Diff and repository mutation | PASS: changed files are restricted to the validator, its regression test and this implementation document; `git diff --check` passes; staged index remains empty. Nothing was committed, pushed, merged or deployed. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_CROSS_PLATFORM_SQL_EVIDENCE_RETEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_847b68d8791876c63d486167293a86541dd44b8c"
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
    - "scripts/database/Assert-AzureDemoSqlBootstrapEvidence.ps1"
    - "scripts/build/Test-AzureDemoSqlBootstrapEvidence.ps1"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "Exact clean baseline, empty index and aligned local/origin/azure refs were confirmed before editing."
    - "All locally available requested regressions passed; PowerShell 7/Linux remains an explicit independent retest."
    - "Every metadata rejection has a stable safe category and executable no-leak coverage."
  decisions:
    - "Validate the original JSON timestamp token so PowerShell runtime date coercion cannot alter evidence syntax."
    - "Retain the existing durable ancestry, age, target, identity, executor and byte-exact grants-hash contract."
    - "Expose only stable non-sensitive rejection categories."
  assumptions: []
  risks:
    - "PowerShell 7/Linux execution is unavailable locally and must be proven by the managed-agent retest."
  defects:
    - "REPAIRED: PowerShell 7 DateTime coercion no longer invalidates a valid literal-Z recordedAtUtc token."
    - "REPAIRED: metadata rejection no longer collapses all failures into one aggregate message."
    - "REPAIRED: fixtures and parser checks are culture-independent and explicit across supported timestamp and GUID forms."
  blockers:
    - "Independent PowerShell 7/Linux retest of mtp-azure-demo-deploy remains required."
  approvals: []
  requested_action: "Independent Tester must rerun the SQL-bootstrap evidence task on the Linux managed agent and verify the exact safe categories without accessing or replacing protected evidence."
```

READY_FOR_CROSS_PLATFORM_SQL_EVIDENCE_RETEST

## Deterministic native-Git invocation repair hand-off

### Latest pipeline failure and exact root cause

After the timestamp repair reached commit `ba0729ef89e056c95c1bc33e0fbf3704ae900df6`, the Linux managed-agent task **Valid and invalid independent SQL bootstrap evidence tests** again rejected the first accepted fixture, **evidence commit equals release commit**. Metadata validation completed successfully and the failure occurred inside `Invoke-GitValidation`, where the broad catch reduced the underlying native-process failure to `SQL bootstrap evidence Git validation could not be executed.`

The exact cross-platform invocation defect was using `ApplicationInfo.Source` as the native process target after `Get-Command -CommandType Application`. `Source` is command provenance and is not the deterministic cross-platform executable-path contract. `ApplicationInfo.Path` is the executable file path supported by both Windows PowerShell 5.1 and PowerShell 7. The validator therefore attempted to invoke a non-portable source value on Linux, and its broad catch hid the resolution/start distinction. A second portability gap was that the native-command block changed only `ErrorActionPreference`; it did not explicitly neutralise `PSNativeCommandUseErrorActionPreference` on PowerShell versions that expose it.

### Bounded repair

`Assert-AzureDemoSqlBootstrapEvidence.ps1` now resolves Git with `Get-Command -CommandType Application`, invokes the validated absolute `ApplicationInfo.Path`, and rejects a missing or non-rooted path as `GIT_EXECUTABLE_RESOLUTION_INVALID`. It does not invoke `ApplicationInfo.Source` and needs no fallback on either supported PowerShell model. An unavailable command is `GIT_EXECUTABLE_UNAVAILABLE`; a process that cannot start is `GIT_PROCESS_START_FAILED`; exit code 1 is `GIT_EXIT_1`; and any other non-zero exit code is `GIT_EXIT_NONZERO`. Captured standard output and standard error remain internal and are never included in failure messages.

Immediately around each native invocation, the validator captures `ErrorActionPreference`, detects and captures `PSNativeCommandUseErrorActionPreference` when present, sets `ErrorActionPreference` to `Continue`, disables native non-zero exit promotion, invokes the absolute Git path, captures `LASTEXITCODE` immediately, and restores both preferences in `finally`. Windows PowerShell 5.1 remains compatible because the PowerShell 7 preference variable is read and written only when it exists.

The Git contract remains fail-closed and unchanged: the repository must be a complete non-shallow worktree; checked-out `HEAD` must equal the expected release commit; both provenance and release objects must exist as commits; and `merge-base --is-ancestor` accepts only exit 0, rejects exit 1 as not-an-ancestor, and treats every other exit as validation failure. No fetch or pull was introduced.

`Test-AzureDemoSqlBootstrapEvidence.ps1` now proves resolution through `ApplicationInfo.Path`, a real or synthetic executable path containing spaces, successful Git execution, exit 1, exit 2, unavailable executable, process-start failure, caller `ErrorActionPreference` restoration, and conditional `PSNativeCommandUseErrorActionPreference` restoration. Equal and ancestor evidence remain accepted; descendant and unrelated evidence remain rejected. The completed literal-`Z`, invariant-culture, one-through-seven fractional-digit timestamp repair and all stable metadata categories remain covered.

No pipeline, Bicep, application, EF migration, SQL grant, SQL principal alias, Azure identity, runtime, service connection, variable-group value or protected `sql-bootstrap.json` change was made. The seven ordered stages, default-disabled deployment and rollback, release-branch restriction, Secure File delivery, App Service subnet repair, private-DNS reconciliation and workload identity remain unchanged.

### Local verification evidence

| Check | Result |
|---|---|
| Exact baseline | PASS before editing: branch `fix/mtp-azure-demo-reconciliation`; HEAD `ba0729ef89e056c95c1bc33e0fbf3704ae900df6`; clean worktree; empty staged index; local `origin` and `azure` tracking refs both exactly aligned with HEAD. |
| Windows PowerShell 5.1 parsing | PASS under `5.1.26100.9444`: all 35 tracked PowerShell scripts parsed with zero errors. |
| SQL-bootstrap evidence regression | PASS: 10 accepted and 35 fail-closed cases across all 17 safe metadata-rejection categories. Coverage includes deterministic `ApplicationInfo.Path`, a path containing spaces, successful execution, exit 1, exit 2, missing executable, process-start failure, preference restoration, equal/ancestor acceptance and descendant/unrelated rejection. |
| Culture and timestamp determinism | PASS under Windows PowerShell 5.1 with `en-US`, `ar-SA` and `th-TH`: each run passed 10 accepted and 35 fail-closed cases. Literal `Z`, invariant parsing, accepted UTC precision, five-minute future tolerance and 90-day maximum age remain covered. |
| Pipeline structural regression | PASS: exactly seven ordered stages. Existing default-disabled deploy/rollback, Secure File, release restriction, workload identity, migration, smoke, swap and rollback controls passed. |
| App Service subnet regression | PASS: one exact inventory and two compiled shapes accepted; 24 inventory and eight compiled-shape cases rejected; four site/slot integrations and two existing-subnet contracts verified. |
| Private-DNS regression | PASS: one valid inventory accepted; six invalid inventories rejected; four deterministic parent/link and zone-group contracts verified. |
| Migration identity and target regressions | PASS: identity one valid/14 rejected; target one valid/seven rejected. |
| Database-principal SQL regression | PASS: seven external variables retained, correct database accepted, 30 invalid cases rejected, and all three approved `CREATE USER` expressions retained. |
| Rollback safeguards | PASS: one valid target and 12 fail-closed target cases. |
| Source/security boundary scan | PASS: 176 source/configuration files scanned. |
| PowerShell 7/Linux execution | UNAVAILABLE locally and not claimed: `pwsh` is absent; WSL reports that the Linux subsystem is not installed; Docker and Podman are absent. Conditional `PSNativeCommandUseErrorActionPreference` behaviour is implemented and covered by the regression when that variable exists, but could not execute locally. |
| Managed Linux validation | BLOCKED pending an independent rerun of pipeline `mtp-azure-demo-deploy`; the managed-agent failure is not claimed fixed until that task passes. |
| Protected/external actions | NOT RUN: no Azure, Azure DevOps, SQL, pipeline, deployment, migration, seed, swap or rollback access/action occurred. Protected `sql-bootstrap.json` was not accessed, regenerated or replaced. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_NATIVE_GIT_LINUX_RETEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_ba0729ef89e056c95c1bc33e0fbf3704ae900df6"
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
    - "scripts/database/Assert-AzureDemoSqlBootstrapEvidence.ps1"
    - "scripts/build/Test-AzureDemoSqlBootstrapEvidence.ps1"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "Exact baseline, empty index and aligned local/origin/azure refs were confirmed before editing."
    - "All locally available requested regressions passed under Windows PowerShell 5.1."
    - "Native-Git resolution, invocation, exit classification and preference restoration are fail-closed without logging captured output."
  decisions:
    - "Invoke only a validated absolute ApplicationInfo.Path."
    - "Disable PowerShell 7 native exit promotion only for the bounded Git call and restore it in finally."
    - "Retain the durable ancestry, timestamp, target, identity, executor and exact grants-hash contracts."
  assumptions: []
  risks:
    - "PowerShell 7/Linux execution is unavailable locally and requires the managed-agent retest."
  defects:
    - "REPAIRED LOCALLY: native Git no longer relies on ApplicationInfo.Source."
    - "REPAIRED LOCALLY: native command preference handling and exit categories are deterministic and fail-closed."
  blockers:
    - "Independent PowerShell 7/Linux rerun of mtp-azure-demo-deploy remains required."
  approvals: []
  requested_action: "Independent Tester must rerun the SQL-bootstrap evidence task on the Linux managed agent and confirm the accepted equal/ancestor cases and fail-closed native-command cases pass without protected-value disclosure."
```

READY_FOR_NATIVE_GIT_LINUX_RETEST

## Scalar native-Git executable selection repair hand-off

### Build 22 failure and exact root cause

Azure DevOps build 22 of pipeline `mtp-azure-demo-deploy` failed the Linux/PowerShell 7 task **Valid and invalid independent SQL bootstrap evidence tests** on branch `fix/mtp-azure-demo-reconciliation`. The exact repair baseline was commit `ac3189687b2dc3b2388be1cc0a114c549250301d`, with a clean worktree, empty staged index and local `origin`/`azure` tracking refs aligned to that commit before editing.

`Get-Command -CommandType Application` returned two valid Git `ApplicationInfo` candidates in PATH order: `/usr/bin/git` and `/bin/git`. The validator treated the result as a single command and converted the candidates' `Path` values to one string, producing `/usr/bin/git /bin/git`. PowerShell then attempted to invoke that combined value as one executable. Build 22 therefore exposed a candidate-collection defect, not an evidence metadata, repository-history or ancestry defect.

### Bounded scalar-selection repair

`Resolve-NativeApplicationExecutablePath.ps1` provides one testable resolution boundary. It accepts an explicit candidate collection, filters it to `ApplicationInfo` instances with non-empty `Path` values, preserves the order supplied by PowerShell/PATH, selects exactly index zero, converts only that selected path to an explicitly typed scalar string, and requires the value to be a rooted existing file. Empty, filtered-out, stale or non-file results fail closed as `GIT_EXECUTABLE_RESOLUTION_INVALID`. The helper never joins candidate paths.

`Assert-AzureDemoSqlBootstrapEvidence.ps1` now captures `Get-Command` output explicitly as an array and passes the collection to that resolver. The call operator receives only the returned scalar string. Explicit `GitExecutablePath` injection remains supported for negative regression cases. Native invocation still captures and restores `ErrorActionPreference`; when available, it captures, disables and restores `PSNativeCommandUseErrorActionPreference`; and it captures `LASTEXITCODE` immediately after invocation. Exit 1 remains distinct from exit 2 and other non-zero results.

`Test-AzureDemoSqlBootstrapEvidence.ps1` directly proves one valid candidate, two valid candidates in both orders, first-candidate selection, scalar-string output, filtering of non-`ApplicationInfo` values, absence of space-joining, and rejection of a selected path whose file no longer exists. Its existing executable-path-with-spaces, missing command, process-start failure, native exit 1/2, equal/ancestor acceptance, descendant/unrelated rejection, preference restoration and protected-value non-disclosure coverage remains intact.

No pipeline YAML, Bicep, application code, EF migration, SQL script/grant, identity, runtime, service connection, variable group or protected SQL-bootstrap evidence file changed. The seven ordered stages, `deployAzureDemo: false`, `rollbackAzureDemo: false`, secure-file delivery, release-branch restriction, App Service subnet repair, private-DNS reconciliation and workload identity remain unchanged.

### Local verification evidence

| Check | Result |
|---|---|
| Exact baseline | PASS before editing: branch `fix/mtp-azure-demo-reconciliation`; HEAD `ac3189687b2dc3b2388be1cc0a114c549250301d`; clean worktree; empty staged index; local `origin` and `azure` tracking refs both exactly aligned with HEAD. |
| Windows PowerShell 5.1 parsing | PASS under `5.1.26100.9444`: all 36 PowerShell scripts, including the new resolver, parsed with zero errors. |
| Durable SQL-evidence regression | PASS: 10 accepted, 35 fail-closed and five executable-resolution cases across all 17 safe metadata-rejection categories. |
| Explicit duplicate-Git regression | PASS: two valid `ApplicationInfo` candidates select exactly one scalar path; both candidate orders were proved; non-application candidates were filtered; the result was never the space-joined candidate list. |
| Executable validity and portability regression | PASS under Windows PowerShell 5.1: rooted existing-file enforcement, invalid stale path, missing executable, process-start failure and an actual Git path containing spaces were covered. The Linux branch retains its executable wrapper with a spaced path for the managed-agent run. |
| Native exit and ancestry semantics | PASS: exit 1 and exit 2 remain distinct; equal and ancestor evidence pass; descendant, unrelated, missing-object, shallow-history and HEAD-mismatch cases remain rejected. |
| Pipeline structural regression | PASS: exactly seven ordered stages; default-disabled deployment/rollback, secure-file, release restriction, workload identity, migration, smoke, swap and rollback controls passed. |
| App Service subnet regression | PASS: one exact inventory and two compiled shapes accepted; 24 inventory and eight compiled-shape cases rejected; four site/slot integrations and two existing-subnet contracts verified. |
| Private-DNS regression | PASS: one valid inventory accepted; six invalid inventories rejected; four deterministic parent/link and zone-group contracts verified. |
| Migration identity and target regressions | PASS: identity one valid/14 rejected; target one valid/seven rejected. |
| Database-principal SQL regression | PASS: seven external variables retained, correct database accepted, 30 invalid cases rejected and all three approved user-creation expression shapes retained. |
| Rollback safeguards | PASS: one valid target and 12 fail-closed target cases. |
| Source/security boundary scan | PASS: 177 source/configuration files scanned. |
| Diff and allowlist | PASS: `git diff --check` returned zero; the changed-file set is limited to the resolver, validator, durable-evidence regression and this implementation document; the staged index remains empty. |
| PowerShell 7/Linux execution | UNAVAILABLE locally and not claimed: `pwsh` is not installed. The Linux managed-agent task must be rerun independently. |
| Managed Linux validation | BLOCKED pending an independent rerun of pipeline `mtp-azure-demo-deploy`; managed-agent success is not claimed until the affected task passes. |
| Protected/external actions | NOT RUN: no Azure, Azure DevOps, SQL, pipeline, deployment, migration, seed, swap or rollback access/action occurred. Protected SQL-bootstrap evidence was not accessed, regenerated or replaced. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_SCALAR_GIT_EXECUTABLE_RETEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_ac3189687b2dc3b2388be1cc0a114c549250301d"
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
    - "scripts/database/Resolve-NativeApplicationExecutablePath.ps1"
    - "scripts/database/Assert-AzureDemoSqlBootstrapEvidence.ps1"
    - "scripts/build/Test-AzureDemoSqlBootstrapEvidence.ps1"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "Exact clean baseline, empty index and aligned local/origin/azure refs were confirmed before editing."
    - "All locally available requested regressions passed under Windows PowerShell 5.1."
    - "Candidate selection is explicitly collection-aware, ordered, scalar and fail-closed."
  decisions:
    - "Select only the first valid ApplicationInfo.Path in PowerShell/PATH order."
    - "Pass only an explicitly scalar existing executable-file path to the call operator."
    - "Retain durable ancestry, timestamp, target, identity, executor and exact grants-hash contracts."
  assumptions: []
  risks:
    - "PowerShell 7/Linux execution is unavailable locally and requires the managed-agent retest."
  defects:
    - "REPAIRED LOCALLY: multiple native Git candidates can no longer become one space-joined executable string."
    - "REPAIRED LOCALLY: stale or otherwise invalid selected executable paths fail closed before invocation."
  blockers:
    - "Independent PowerShell 7/Linux rerun of mtp-azure-demo-deploy remains required."
  approvals: []
  requested_action: "Independent Tester must rerun build 22's SQL-bootstrap evidence task on the Linux managed agent and confirm duplicate Git candidates select one executable while all fail-closed evidence semantics remain intact."
```

READY_FOR_SCALAR_GIT_EXECUTABLE_RETEST

## Azure Monitor metric deployment repair hand-off

### Azure build 24 failure and authoritative metric inventory

Azure build `24` of pipeline `mtp-azure-demo-deploy` failed during incremental top-level deployment `mtp-azure-demo-24`, nested deployment `alerts-mtp-dev-uks-001`. The Bicep deployment failed before database migration, synthetic seed reconciliation, application package deployment, smoke testing or slot swap. Because deployment mode was incremental, unrelated resource operations may already have completed; this repair does not treat the failed deployment as atomic and does not access or change live Azure state.

The supplied target-resource metric inventory is authoritative for this repair:

- web staging slot `Microsoft.Web/sites/app-mtp-web-dev-uks-001/slots/staging`, namespace `Microsoft.Web/sites/slots`: `Requests`/`Total`, `Http5xx`/`Total`, deprecated `AverageResponseTime`/`Average`, `HttpResponseTime`/`Average`, and `HealthCheckStatus`/`Average`;
- API staging slot `Microsoft.Web/sites/app-mtp-api-dev-uks-001/slots/staging`, namespace `Microsoft.Web/sites/slots`: the same five metrics and aggregations; and
- SQL database `Microsoft.Sql/servers/sql-mtp-dev-uks-001/databases/sqldb-mtp-dev-uks-001`, namespace `Microsoft.Sql/servers/databases`: `cpu_percent`/`Average`, `app_cpu_percent`/`Average`, `storage_percent`/`Maximum`, `workers_percent`/`Average`, and `sessions_percent`/`Average`. `dtu_consumption_percent` is unavailable for the approved GP serverless/vCore database.

Build 24 exposed three exact contract failures: both staging-slot `HealthCheckStatus` alerts used parent-site namespace `Microsoft.Web/sites` instead of `Microsoft.Web/sites/slots`, and the SQL alert selected unavailable `dtu_consumption_percent` rather than approved `cpu_percent`.

### Bounded repair

| Alert | Exact scope | Metric contract | Preserved reviewed settings |
|---|---|---|---|
| `alert-mtp-web-slot-health-dev-uks-001` | exact web staging slot ID from `webSlot.id` | `HealthCheckStatus`; `Microsoft.Web/sites/slots`; `Average` | severity `1`; enabled; `LessThan 1`; evaluation `PT5M`; window `PT5M`; approved action group |
| `alert-mtp-api-slot-health-dev-uks-001` | exact API staging slot ID from `apiSlot.id` | `HealthCheckStatus`; `Microsoft.Web/sites/slots`; `Average` | severity `1`; enabled; `LessThan 1`; evaluation `PT5M`; window `PT5M`; approved action group |
| `alert-mtp-sql-cpu-dev-uks-001` | exact SQL database ID from `sqlDatabase.id` | `cpu_percent`; `Microsoft.Sql/servers/databases`; `Average` | severity `2`; enabled; `GreaterThan 80`; evaluation `PT5M`; window `PT15M`; approved action group |

The SQL Bicep symbol, parameter key, physical metric-alert name, criterion name, description and executable inventories now use CPU terminology. The invalid DTU alert is replaced one-for-one, so the approved total remains 17 mandatory alerts; no eighteenth alert and no unrelated removal were introduced. `app_cpu_percent` is explicitly rejected and is not used as a substitute.

`Test-AzureDemoMonitoringAlerts.ps1` now validates both parameter files as exact 19-name monitoring inventories: two web-test resources plus 17 mandatory alerts. It proves the exact web/API/SQL resource-ID wiring, metric names, namespaces, aggregations, descriptions, thresholds, enabled states, time settings and action-group bindings. Mutation tests reject parent-site namespace on either slot, production-site substitution for either slot scope, unavailable `dtu_consumption_percent` and unapproved `app_cpu_percent`. The alert module is also rejected if it introduces an identity or Azure role assignment.

No application, EF migration, database schema/seed, SQL principal alias/grant, Azure identity ID, runtime version, service connection, variable-group value, dependency or `sql-bootstrap.json` change is required or made. Both Bicep parameter files change only the static monitoring name mapping from `sqlDtu: alert-mtp-sql-dtu-dev-uks-001` to `sqlCpu: alert-mtp-sql-cpu-dev-uks-001`; no environment parameter or variable-group update is required. `infra/bicep/main.bicep` and `azure-pipelines.yml` remain unchanged.

### Incremental deployment and retest requirements

Renaming the SQL alert accurately causes incremental deployment to create or correct `alert-mtp-sql-cpu-dev-uks-001`; incremental mode does not establish that a failed `alert-mtp-sql-dtu-dev-uks-001` resource is absent and does not remove it. The work item prohibits Azure access, so no live-resource check was performed. Before or during the separately authorised retest, an authorised operator must perform a read-only inventory check for the legacy DTU-named resource. If Azure retained it, its cleanup requires a separate controlled, approved action with evidence. No destructive automatic deletion was added to Bicep or the pipeline.

The protected Bicep `what-if` remains mandatory and is expected to show correction/update of the two slot alerts and creation or correction of the SQL CPU alert. It must show no unrelated deletion or replacement and no SQL, application, identity, DNS, subnet or private-endpoint change caused by this repair. Any broader change blocks deployment before migration, seed, package deployment, smoke or swap.

### Local verification

| Check | Result |
|---|---|
| Exact baseline | PASS before editing: branch `fix/mtp-azure-demo-reconciliation`; HEAD `77ea25b5fb501985e42f11e958e64443b1833f4a`; worktree clean; staged index empty; local `origin/fix/mtp-azure-demo-reconciliation` and `azure/fix/mtp-azure-demo-reconciliation` refs both exactly matched HEAD. |
| Diff and changed-file boundary | PASS: `git diff --check` exited `0`; the exact eight-file allowlist matched; `azure-pipelines.yml`, `infra/bicep/main.bicep` and the database-principal SQL script are unchanged; the staged index remains empty. |
| Monitoring regression | PASS, exit `0`: 17 mandatory alerts retained; three exact metric contracts passed; six invalid namespace, scope and SQL-metric mutations rejected. Both parameter-file inventories and exact action-group/permission boundaries passed. |
| Pipeline structure | PASS, exit `0`: exactly seven ordered stages. Default-disabled deployment/rollback, release-branch restriction, exact service connections/targets, workload identity, Secure File evidence, migration/seed/smoke/swap and rollback safeguards remain intact. |
| PowerShell 5.1 | PASS under `5.1.26100.9444`: 36 tracked PowerShell scripts and 17 pipeline script blocks parsed with zero errors. |
| App Service subnet regression | PASS, exit `0`: one exact inventory and two compiled shapes accepted; 24 inventory and eight compiled-shape cases rejected; four site/slot integrations and two existing-subnet contracts verified. |
| Private-DNS regression | PASS, exit `0`: one valid inventory accepted; six invalid inventories rejected; four deterministic parent/link and zone-group contracts verified. |
| Durable SQL-evidence regression | PASS, exit `0`: 10 accepted, 35 fail-closed and five executable-resolution cases passed across 17 safe metadata-rejection categories. The protected evidence file was not accessed or replaced. |
| Migration identity and target | PASS, exit `0` each: identity one valid/14 rejected; target one valid/seven rejected. |
| Database-principal SQL | PASS, exit `0`: seven external variables, correct database, 30 invalid cases and all three approved `CREATE USER` expressions passed. |
| Rollback safeguards | PASS, exit `0`: one valid and 12 fail-closed target cases. |
| Source/security boundary | PASS, exit `0`: 177 source/configuration files scanned. |
| Focused .NET deployment boundary | PASS, exit `0`: 10/10 `AzureDemoDeploymentBoundaryTests` passed. Two `NU1900` warnings record that the restricted environment could not reach the NuGet advisory service; no connected vulnerability-pass claim is made. |
| Bicep CLI 0.47.16 | UNAVAILABLE, not passed. `az bicep version`; four `az bicep format --file ... --stdout` commands for `main.bicep`, `alerts.bicep` and both parameter files; `az bicep lint --file infra/bicep/main.bicep`; `az bicep build --file infra/bicep/main.bicep --outfile .codex-temp/azure-monitor-main.json`; and both `az bicep build-params` commands with synthetic environment values each exited `1`. Exact blocker: `'az' is not recognized as an internal or external command, operable program or batch file.` No Bicep executable exists on `PATH` or in the repository, so no format comparison, lint, compiled template or compiled parameter output is claimed. |
| Protected/external validation | NOT RUN: the work item prohibits Azure/Azure DevOps access, pipeline execution, live alert inventory/change, what-if, deployment, migration, seed, smoke, swap and rollback. Those actions require the existing protected human workflow. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_AZURE_MONITOR_METRIC_RETEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_77ea25b5fb501985e42f11e958e64443b1833f4a"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-01", "C-11"]
    functional_requirements: ["F-14", "F-15"]
    non_functional_requirements: ["NF-01", "NF-03", "NF-06", "NF-07", "NF-10", "NF-12"]
    risks: ["R-02", "R-09", "R-11"]
    assumptions: ["A-11", "A-12", "A-18"]
    dependencies: ["D-02", "D-03", "D-04", "D-05"]
    issues: ["I-06", "I-08"]
    open_questions: ["Q-01", "Q-06", "Q-08", "Q-09"]
    approvals: []
  artefacts:
    - "docs/architecture/AZURE_DEMO_Deployment_Architecture.md"
    - "docs/architecture/AZURE_DEMO_Environment_Configuration.md"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
    - "infra/bicep/modules/alerts.bicep"
    - "infra/bicep/parameters/azure-demo.bicepparam"
    - "infra/bicep/parameters/dev.bicepparam"
    - "scripts/build/Test-AzureDemoMonitoringAlerts.ps1"
    - "tests/api.unit/AzureDemoDeploymentBoundaryTests.cs"
  evidence:
    - "Exact branch/HEAD, clean worktree, empty index and aligned local origin/azure refs were confirmed before editing."
    - "All locally available requested monitoring, pipeline, PowerShell, subnet, DNS, SQL-evidence, migration, SQL-principal, rollback and source/security checks passed."
    - "The mandatory inventory remains exactly 17 alerts and all three corrected metric contracts pass fail-closed regression."
  decisions:
    - "Use Microsoft.Web/sites/slots for both staging-slot HealthCheckStatus alerts."
    - "Replace the invalid DTU metric/name contract one-for-one with approved SQL cpu_percent and CPU terminology."
    - "Require a separately authorised read-only legacy-resource check and separately approved cleanup if the failed DTU-named resource was retained."
    - "Make no automatic deletion, permission, variable-group, pipeline, database, identity or application change."
  assumptions:
    - "The supplied Azure metric inventory and build 24 deployment record are accurate."
  risks:
    - "Incremental build 24 may have completed unrelated resource operations and may have retained a failed legacy DTU-named resource."
    - "Bicep compilation and protected Azure what-if/deployment evidence remain unavailable locally."
  defects:
    - "REPAIRED LOCALLY: web and API staging-slot health alerts used the parent-site metric namespace."
    - "REPAIRED LOCALLY: the GP serverless/vCore database alert used an unavailable DTU metric and false DTU terminology."
  blockers:
    - "Bicep CLI 0.47.16 is unavailable because Azure CLI/Bicep is not installed on PATH."
    - "Independent protected what-if and deployment retest remain required before any later deployment stage can proceed."
  approvals: []
  requested_action: "Independent Tester must run Bicep CLI 0.47.16 format/lint/build and both parameter builds, execute the protected what-if, verify only the three intended alert changes and no unrelated changes, perform the authorised legacy DTU-alert inventory check, then rerun the incremental Bicep deployment before migration, seed, package deployment, smoke or slot swap."
```

READY_FOR_AZURE_MONITOR_METRIC_RETEST

## Explicit-UTC SQL-bootstrap evidence repair hand-off

### Failed protected deployment and root cause

Pipeline `mtp-azure-demo-deploy` failed task **Require durable independently produced SQL Entra bootstrap evidence** for validated source/release commit `07c575567c864b23a23a1fef8d42dc9f7d9ecb22` with reason `METADATA_UTC_TIMESTAMP_SYNTAX`. The authoritative protected evidence contains `recordedAtUtc: 2026-10-03T00:59:16.7133881+00:00`, an explicit UTC zero-offset value produced by `DateTimeOffset.ToString("O")`. Its supplied SHA-256 is `02d105fd3d16eab02567f565e400b8c79d9ca7f8a75aade40c10ed22114b034e`. The producer was correct, but the durable validator accepted only the equivalent literal-`Z` lexical representation.

The protected evidence was not accessed, edited, regenerated, replaced or rewritten to the current time. This repair preserves the original recorded instant and its explicit `+00:00` syntax.

### Bounded validator and producer-contract repair

`Assert-AzureDemoSqlBootstrapEvidence.ps1` continues to validate the raw JSON token before PowerShell 7 `ConvertFrom-Json` can materialise an ISO-8601 string as a `DateTime`. It now accepts exactly invariant `yyyy-MM-ddTHH:mm:ssZ`, `yyyy-MM-ddTHH:mm:ss.FFFFFFFZ`, `yyyy-MM-ddTHH:mm:ss+00:00` and `yyyy-MM-ddTHH:mm:ss.FFFFFFF+00:00`, where a present fraction contains one through seven digits. Parsing uses explicit exact formats, invariant culture, `DateTimeOffset`, and deterministic universal adjustment; the parsed offset must be exactly zero. Missing, non-zero, negative, malformed or lowercase zones; whitespace; invalid calendar/clock values; locale-specific strings; and fractions longer than seven digits remain rejected.

The synthetic repository evidence producer now emits one canonical future format: uppercase literal `Z` with exactly seven fractional digits (`yyyy-MM-ddTHH:mm:ss.fffffffZ`). Documentation requires the same format for future independently produced protected evidence. Compatibility with the existing `+00:00` evidence is retained; no existing evidence is mutated.

All other controls remain unchanged: schema version `1`, `PASS`, exact SQL target, exact migration identity, exact executor identity, non-empty evidence/approval references, exact grants-script SHA-256, complete non-shallow repository, exact checked-out `HEAD`, commit-object existence, equal/ancestor provenance only, descendant/unrelated rejection, no Git fetch/pull, native scalar Git resolution, 90-day maximum age and five-minute future tolerance. The seven-stage pipeline, default-disabled deploy/rollback, release-branch restriction, Secure File delivery, workload identity, monitoring, subnet, private-DNS, migration, SQL-principal, swap and rollback safeguards are unchanged.

The protected pipeline must be rerun independently. Managed-agent success is not claimed until the existing evidence passes the affected task without weakening provenance, identity, target, hash or age validation.

### Local verification evidence

| Check | Result |
|---|---|
| Exact baseline | PASS before editing: branch `fix/mtp-azure-demo-reconciliation`; HEAD `07c575567c864b23a23a1fef8d42dc9f7d9ecb22`; clean worktree; empty staged index; local `origin` and `azure` tracking refs both exactly aligned with HEAD. |
| Windows PowerShell 5.1 parsing | PASS: all 36 tracked PowerShell scripts parsed with zero errors. |
| Durable SQL-evidence regression | PASS: 27 accepted, 45 fail-closed, five executable-resolution and three culture-execution cases across all 17 safe metadata-rejection categories. Coverage includes both UTC suffixes, zero through seven fractional digits, exact real timestamp shape, `DateTimeOffset.UtcNow.ToString("O")`, raw-token preservation, age/skew, target/identity/hash and full ancestry semantics. |
| Multiple-culture execution | PASS under `en-US`, `ar-SA` and `th-TH` inside the durable regression using invariant timestamp generation and parsing. |
| Pipeline structural validation | PASS: exactly seven ordered stages; deploy/rollback default-disabled, release restriction, Secure File, workload identity, migration, smoke, swap and rollback controls retained. |
| Monitoring regression | PASS: 17 mandatory alerts retained; three exact metric contracts passed and six invalid mutations were rejected. |
| App Service subnet regression | PASS: one exact inventory and two compiled shapes accepted; 24 inventory and eight compiled-shape cases rejected. |
| Private-DNS regression | PASS: one valid inventory accepted; six invalid inventories rejected; four parent/link and zone-group contracts verified. |
| Migration identity and target regressions | PASS: identity one valid/14 rejected; target one valid/seven rejected. |
| Database-principal SQL regression | PASS: seven external variables preserved, correct database accepted, 30 invalid cases rejected, and three approved `CREATE USER` shapes retained. |
| Rollback safeguards | PASS: one valid and 12 fail-closed target cases. |
| Source/security boundary scan | PASS: 177 source/configuration files scanned. |
| Diff and mutation boundary | PASS: `git diff --check`; exact five-file allowlist; staged index empty. No Bicep, application, EF migration, SQL grant/principal, identity, service connection, runtime, variable-group, pipeline YAML or protected evidence change. |
| PowerShell 7/Linux | UNAVAILABLE locally and not claimed: `pwsh` is absent, WSL is not installed, and Docker/Podman are absent. |
| Protected/external actions | NOT RUN: no Azure, Azure DevOps, SQL, pipeline, deployment, migration, seed, swap or rollback access/action occurred. The protected evidence and supplied SHA-256 `02d105fd3d16eab02567f565e400b8c79d9ca7f8a75aade40c10ed22114b034e` were not accessed or modified. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_EXPLICIT_UTC_EVIDENCE_RETEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_07c575567c864b23a23a1fef8d42dc9f7d9ecb22"
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
    - "scripts/database/Assert-AzureDemoSqlBootstrapEvidence.ps1"
    - "scripts/build/Test-AzureDemoSqlBootstrapEvidence.ps1"
    - "docs/architecture/AZURE_DEMO_Deployment_Architecture.md"
    - "docs/architecture/AZURE_DEMO_Environment_Configuration.md"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "Exact clean baseline, empty index and aligned local origin/azure refs were confirmed before editing."
    - "All locally available requested regressions passed under Windows PowerShell 5.1."
    - "The exact real explicit-zero-offset timestamp fixture passed without accessing or changing protected evidence."
  decisions:
    - "Accept only uppercase Z or exact +00:00 after raw JSON lexical validation."
    - "Parse exact invariant DateTimeOffset formats, normalise deterministically to UTC and require zero offset."
    - "Emit canonical uppercase Z with exactly seven fractional digits for new evidence."
  assumptions:
    - "The supplied protected-evidence observation and SHA-256 are authoritative."
  risks:
    - "PowerShell 7/Linux and the protected Secure File remain independently testable only on the managed agent."
  defects:
    - "REPAIRED LOCALLY: the durable validator rejected valid explicit UTC +00:00 timestamps produced by DateTimeOffset.ToString(O)."
  blockers:
    - "Independent PowerShell 7/Linux rerun of pipeline mtp-azure-demo-deploy remains required; managed-agent success is not claimed."
  approvals: []
  requested_action: "Independent Tester must rerun the protected SQL-bootstrap task using the unchanged Secure File and confirm the existing +00:00 timestamp passes while age, provenance, identity, target and hash validation remain fail-closed."
```

READY_FOR_EXPLICIT_UTC_EVIDENCE_RETEST

## Dedicated migration service-connection v2 reconciliation

The validated dedicated workload-identity service connection is `sc-mtp-azure-demo-migration-dev-v2`, service-connection ID `d472ce79-141c-4b8c-861a-4dd009b4c6a2`. The read-only `AZDEMO_MIGRATION_WIF_SERVICE_CONNECTION` value and the literal `azureSubscription` inputs for both the reviewed EF migration bundle and synthetic seed reconciliation now use that endpoint. The retired `sc-mtp-azure-demo-migration-dev` endpoint is rejected by pipeline structure and migration-identity regressions.

The approved migration identity remains `id-mtp-migration-dev-uks-001`, client ID `f77b1931-0954-4ae9-8f6b-de5f9cfdb2e7`, object ID `9b984b84-7ebe-45ca-9441-7b2f41fd8f6c`, in tenant `af8fcf7a-30f8-4ce0-bad1-088afe786ec4`. The general deployment connection remains `sc-mtp-azure-demo-dev`. No SQL permission/principal alias, protected evidence, runtime, DNS, subnet, monitoring, Bicep, application, EF migration, schema or seed-data change is included.

| Migration service-connection verification | Result |
|---|---|
| Exact baseline | PASS before editing: branch `fix/mtp-azure-demo-reconciliation`; HEAD `e9e48b3a29e656f55db887d770102de288898851`; clean worktree; empty staged index; local `origin` and `azure` tracking refs both exactly aligned with HEAD. |
| PowerShell parsing | PASS: all 36 tracked PowerShell scripts parsed with zero errors. |
| Pipeline structural regression | PASS: exactly seven ordered stages; both migration/seed AzureCLI tasks require `sc-mtp-azure-demo-migration-dev-v2`; retired endpoint rejected; default-disabled deploy/rollback, release restriction, workload identity, Secure File evidence, migration, smoke, swap and rollback controls retained. |
| Migration identity and target regressions | PASS: identity one valid/15 rejected, including the retired endpoint; target one valid/seven rejected. |
| Durable SQL-evidence regression | PASS: 27 accepted, 45 fail-closed, five executable-resolution and three culture-execution cases across 17 safe metadata-rejection categories. |
| Database-principal SQL regression | PASS: seven external variables preserved, correct database accepted, 30 invalid cases rejected and three approved `CREATE USER` shapes retained. |
| Rollback safeguards | PASS: one valid and 12 fail-closed target cases. |
| Preserved repair regressions | PASS: native runtimes three positive/six rejected; subnet one exact inventory and two compiled shapes accepted, 24 inventory/eight compiled shapes rejected; private DNS one accepted/six rejected; monitoring retained 17 alerts and rejected six invalid metric mutations. |
| Source/security boundary scan | PASS: 177 source/configuration files scanned. |
| Protected/external actions | NOT RUN: no Azure, Azure DevOps, SQL, pipeline, deployment, migration, seed, swap or rollback access/action occurred. Protected `sql-bootstrap.json` was not accessed, modified or regenerated. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_MIGRATION_SERVICE_CONNECTION_RETEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_e9e48b3a29e656f55db887d770102de288898851"
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
    - "scripts/database/Assert-AzureDemoMigrationIdentity.ps1"
    - "scripts/build/Test-AzureDemoMigrationIdentity.ps1"
    - "scripts/build/Test-AzurePipelineStructure.ps1"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "Exact clean baseline, empty index and aligned local origin/azure refs were confirmed before editing."
    - "The pipeline variable and both dedicated migration/seed AzureCLI tasks use the validated v2 service connection."
    - "All requested local regressions and preserved repair regressions passed."
  decisions:
    - "Reference the validated endpoint by its Azure DevOps service-connection name in pipeline execution and record its supplied immutable ID in implementation evidence."
    - "Reject the retired dedicated endpoint in both structural and runtime-guard regression coverage."
  assumptions:
    - "The supplied v2 service-connection validation, ID and managed-identity binding are authoritative."
  risks:
    - "The service connection remains independently testable only through the protected Azure DevOps pipeline."
  defects:
    - "REPAIRED LOCALLY: migration and seed tasks referenced the retired dedicated migration service connection."
  blockers:
    - "Independent protected Azure DevOps migration-service-connection retest remains required; no external execution is claimed."
  approvals: []
  requested_action: "Independent Tester must rerun the protected pipeline through the pre-migration guard and confirm both dedicated AzureCLI tasks authenticate as the approved managed identity through service connection d472ce79-141c-4b8c-861a-4dd009b4c6a2, without executing migration or seed unless separately authorised."
```

READY_FOR_MIGRATION_SERVICE_CONNECTION_RETEST

## Immutable seed-tool deployment artifact repair

### Protected deployment failure and exact root cause

Pipeline `mtp-azure-demo-deploy` passed the migration identity, tenant, release, artifact and SQL-target guards, and the reviewed EF migration task progressed far enough for the independent seed task to start. Seed startup then failed with `NETSDK1004` because `scripts/data/Invoke-AzureDemoSeed.ps1` executed `dotnet run --project tools/AzureDemo.DataTool/AzureDemo.DataTool.csproj --configuration Release --no-restore`. The protected deployment job runs on a separate ephemeral agent. Its filesystem contains neither the Package job's `obj/project.assets.json` nor any Package-job `bin` output, so `--no-restore` against repository source could not succeed. Job/stage isolation is the root cause; the migration, identity, tenant, target and durable SQL-bootstrap evidence controls were not the failing controls.

### Bounded immutable-artifact repair

The Linux Package job now restores `AzureDemo.DataTool.csproj` in locked mode and publishes Release, framework-dependent .NET 10 output once with `--no-restore` and `--no-self-contained`. Packaging is Linux-gated and produces:

- `azure-demo-immutable/seed/AzureDemo.DataTool.dll` plus its `.deps.json`, `.runtimeconfig.json` and complete published dependency set;
- `azure-demo-immutable/demo-data/azure-demo-seed-manifest.json`; and
- `azure-demo-immutable/samples/discovery/azure-migrate-server-report-demo.csv`, retaining the manifest's approved SHA-256.

The package generator builds `deployment-artifact-manifest.json` only after application, migration, infrastructure, smoke, seed-tool, seed-manifest and approved-sample payloads are present. The manifest records exact `Build.SourceVersion` and one SHA-256 entry for every payload file. Validation compares the complete manifest set with the complete downloaded set and therefore rejects missing, modified, added or substituted files. Absolute paths, `..` traversal, repository escape, prohibited source/restore metadata, duplicate paths and symbolic-link/reparse-point paths fail closed. The manifest itself is excluded from its self-referential payload list; its own SHA-256 remains the evidence identifier used by protected smoke evidence.

The seed task retains the dedicated `sc-mtp-azure-demo-migration-dev-v2` workload-identity flow, migration identity/tenant/release/artifact guard, exact passwordless SQL target guard and token-file cleanup. It now passes explicit absolute paths beneath `$(Pipeline.Workspace)/azure-demo-immutable`, verifies the complete artifact and exact commit, requires the installed .NET 10 shared runtimes, then executes `dotnet <validated AzureDemo.DataTool.dll>`. Protected deployment contains no `dotnet run`, restore, build or source-project execution and does not use `Build.SourcesDirectory` as the executable location.

`Program.cs` now consumes the explicit immutable artifact root and manifest path. It no longer searches for `LgrTransformationMigration.sln` or derives sample locations from repository source. It preserves the exact `AzureDemo`, `Onkar.Pathre`, approved database-name, synthetic classification/customer/project, sample checksum, passwordless workload-identity SQL, pending-migration refusal, stable-ID idempotent reconciliation, minimum-count verification and manifest-checksum semantics. `Invoke-AzureDemoReset.ps1` forwards the identical immutable root/tool/seed-manifest/deployment-manifest/commit contract while retaining named restore evidence and DBA approval requirements and every destructive-operation prohibition.

This repair creates a new source commit and therefore requires a new release approval bound to that future exact commit and artifact manifest; no prior release approval is inherited. Existing durable `sql-bootstrap.json` evidence remains independently evaluated by its unchanged ancestry, age, target, identity, executor and grants-script-hash contract. It was not accessed, edited or regenerated.

### Local verification evidence

| Check | Result |
|---|---|
| Exact baseline | PASS before editing: branch `fix/mtp-azure-demo-reconciliation`; HEAD `0989a99d871c7158eed4994c9e6ff1f7a994ab0f`; clean worktree; empty staged index; local `origin` and `azure` tracking refs both exactly aligned with HEAD. |
| Windows PowerShell 5.1 parsing | PASS: all 42 repository PowerShell scripts parsed with zero errors. |
| Pipeline structural regression | PASS: exactly seven ordered stages; default-disabled deploy/rollback, release branch, both service connections, workload identity, migration/target/SQL-evidence guards, seed package/manifest validation, staging-first deployment, smoke, swap and rollback controls retained. |
| Immutable seed regression | PASS: Package locked-restore/no-restore publish contract, complete seed hash coverage, packaged execution path, no deployment restore/build/`dotnet run`, missing tool/manifest, traversal, outside-root, modified/added content, commit mismatch, reset forwarding, stable-ID idempotency and no-secret-output checks passed. |
| Deployment artifact validation | PASS against local test fixtures: 1,803 payload files matched the complete manifest and SHA-256 set; required seed DLL, manifest and sample entries were present. Fixtures are ignored local evidence only and are not a release artifact. |
| Package-generation regression | PASS against the same local test fixtures: repository/prefix path guards, ZIP roots, deterministic ZIP recreation, application manifest hashes and complete deployment-manifest coverage passed. |
| Application artifact regression | PASS: API/web ZIP hashes, root layout and prohibited-file checks passed. |
| Source/security boundary scan | PASS after generated probe cleanup: 183 source/configuration files; no generated/binary path, secret pattern, LocalTest deployment setting or prohibited capability finding. |
| Durable SQL evidence | PASS: 27 accepted, 45 fail-closed, five executable-resolution and three culture-execution cases across 17 rejection categories. |
| Migration identity and target | PASS: identity one accepted/15 rejected; target one accepted/seven rejected. |
| Database-principal SQL | PASS: seven external variables, correct database, 30 invalid guard cases and three approved `CREATE USER` shapes. |
| Reset/rollback | PASS: immutable regression proves reset forwards the same artifact contract; existing rollback regression accepted one valid and rejected 12 invalid targets. |
| Private DNS / App Service subnet / runtime / monitoring | PASS: DNS one valid/six rejected; subnet one inventory and two compiled shapes accepted with 24/eight rejected; runtime three accepted/six rejected; all 17 alerts with three exact metric contracts and six invalid mutations. |
| Locked .NET restore | PASS, exit `0`: solution restored in locked mode; only `NU1900` warnings remained because the vulnerability service was unreachable. |
| Release build and formatting | PASS: Release build produced all four projects with zero errors; focused `Program.cs` format verification exited `0`. |
| Focused Azure Demo tests | PASS: 27/27. |
| Full unit and integration tests | PASS: 205/205 unit and 145/145 integration tests. |
| SBOM regression | PASS: 107 NuGet and 522 npm components; repeat generation remained valid. |
| Full application package generation | UNAVAILABLE: the exact Package-equivalent command exited `1` because sandboxed `npm ci` could not fetch `https://registry.npmjs.org/next/-/next-16.3.8.tgz`; a no-restore retry exited `1` because `next` was absent after the failed clean install. No application package success is claimed. |
| Linux seed publish | UNAVAILABLE on this Windows host: the exact generator exited `1` with `Azure demo seed packaging must run on the Linux Package agent.` The Linux Package-stage contract is covered structurally and must be executed by the protected pipeline retest. |
| Azure CLI / Bicep | UNAVAILABLE: `az --version`, `az bicep version` and `bicep --version` each exited `1` because the executables are not installed. No Bicep format/build/what-if result is claimed. |
| PowerShell 7/Linux | UNAVAILABLE: `pwsh --version` exited `1`; `wsl.exe --status` exited `50` because WSL is not installed. |
| Protected/external actions | NOT RUN: no Azure, Azure DevOps, SQL, pipeline, deployment, migration, seed, swap or rollback action occurred. No token, connection string, evidence content or protected file was printed. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_IMMUTABLE_SEED_ARTIFACT_RETEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_0989a99d871c7158eed4994c9e6ff1f7a994ab0f"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-01", "C-11"]
    functional_requirements: ["F-01", "F-02", "F-13", "F-14", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-04", "NF-06", "NF-10", "NF-12"]
    risks: ["R-02", "R-09", "R-11"]
    assumptions: ["A-11", "A-12", "A-18"]
    dependencies: ["D-02", "D-03", "D-04", "D-05", "D-11"]
    issues: ["I-06", "I-08"]
    open_questions: ["Q-01", "Q-06", "Q-08", "Q-09"]
    approvals: []
  artefacts:
    - "azure-pipelines.yml"
    - "scripts/build/AzureDemoDeploymentArtifactUtilities.ps1"
    - "scripts/build/New-AzureDemoDeploymentArtifactManifest.ps1"
    - "scripts/build/Assert-AzureDemoDeploymentArtifact.ps1"
    - "scripts/build/New-AzureDemoSeedArtifact.ps1"
    - "scripts/build/Test-AzureDemoImmutableSeedArtifact.ps1"
    - "scripts/build/Test-AzureDemoPackageGeneration.ps1"
    - "scripts/build/Test-AzurePipelineStructure.ps1"
    - "scripts/data/AzureDemoSeedArtifactContract.ps1"
    - "scripts/data/Invoke-AzureDemoSeed.ps1"
    - "scripts/data/Invoke-AzureDemoReset.ps1"
    - "tools/AzureDemo.DataTool/Program.cs"
    - "docs/architecture/AZURE_DEMO_Deployment_Architecture.md"
    - "docs/architecture/AZURE_DEMO_Environment_Configuration.md"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "Exact clean baseline, empty index and aligned origin/azure refs confirmed before editing."
    - "All locally available immutable seed, package/hash, pipeline, source/security, SQL-evidence, identity, target, principal, rollback, DNS, subnet, runtime, monitoring, restore/build/test and SBOM checks passed."
    - "Unavailable Linux, Bicep and network-dependent checks are recorded with exact commands, exit codes and blockers."
  decisions:
    - "Publish once in Package; execute only the immutable DLL beneath Pipeline.Workspace."
    - "Hash and exact-commit bind every payload file, including the seed tool, dependencies, approved manifest and sample."
    - "Use no deployment-time restore, build, source project or mutable seed-tool download."
  assumptions:
    - "The protected Linux Package agent supplies .NET SDK 10 and the protected deployment agent supplies both .NET 10 shared runtimes."
  risks:
    - "Linux Package execution and the protected ephemeral deployment-agent retest remain independent downstream evidence."
    - "A new release approval is mandatory for the future repair commit."
  defects:
    - "REPAIRED LOCALLY: the protected seed task depended on another ephemeral job's absent NuGet restore/build outputs."
  blockers:
    - "Independent protected Linux Package/deployment retest is required; no pipeline or deployment success is claimed."
  approvals: []
  requested_action: "Independent Tester must run the Package stage on Linux, verify the published seed payload and exact deployment manifest, then rerun the protected deployment through seed reconciliation and prove no restore/build/dotnet run or source-project execution occurs."
```

READY_FOR_IMMUTABLE_SEED_ARTIFACT_RETEST

## Build 40 EF migration bundle execution repair

### False-success failure and confirmed code-level cause

Azure DevOps build 40 passed the migration identity and exact target guards, then emitted `xdg-open: no method available for opening .../migration/lgrtm-efbundle-linux-x64`. The migration task nevertheless completed successfully and allowed the independent seed task to start. The seed tool correctly refused to continue because pending EF migrations remained, reporting that the reviewed migration bundle must be applied first. Build 40 therefore supplies no evidence that any migration was applied.

The pipeline defect is confirmed in code: it called the extensionless downloaded bundle with PowerShell's call operator and then inspected ambient `$LASTEXITCODE`. It did not establish or verify executable permission, disable shell/document-association execution through an explicit native-process contract, retain the launched process object, or read that process's own exit code. A file-association attempt could therefore produce the observed `xdg-open` message while the following `$LASTEXITCODE` check observed no bundle-specific failure. Missing execute permission is consistent with the evidence and is the leading runtime hypothesis, but the downloaded build-40 file's mode was not measured and is not claimed as fact.

### Bounded repair

`Invoke-AzureDemoEfMigrationBundle.ps1` now accepts only absolute immutable-root, root-manifest and exact-commit inputs. It derives the sole executable location as `migration/lgrtm-efbundle-linux-x64`, reuses the existing traversal and symlink/reparse-point rejection, requires Linux `/usr/bin/test` or `/bin/test` to confirm a regular file, and validates the complete downloaded immutable artifact and SHA-256 set before permission or execution. The preceding unchanged migration-identity guard continues to bind the migration manifest and its two exact artifact hashes to the approved release commit.

On Linux the wrapper invokes an absolute `chmod` executable as a native process with separated arguments `u+x`, `--` and the one validated bundle path. It waits for completion and rejects launch failure, absent status or nonzero exit. It then re-resolves the bundle, rechecks regular-file and user-execute state, and proves the SHA-256 is unchanged. It does not recursively alter the artifact root.

The bundle itself is launched with `System.Diagnostics.ProcessStartInfo`, a scalar absolute executable path, `UseShellExecute = false` and one `ArgumentList` entry per argument. Standard output and error remain inherited for live diagnostic output, so there is no redirected-stream deadlock and the wrapper never prints the workload-identity token, federated assertion or connection string. The process is explicitly awaited and its own `ExitCode` is required to be zero. Launch and status errors are sanitised and do not include arguments.

The existing migration task retains `sc-mtp-azure-demo-migration-dev-v2`, identity/token/tenant/release/target guards, workload-identity environment variables and `finally` cleanup. The seed task remains a later default-success-gated task and retains its pending-migration prerequisite; API/web slot deployment remains later still. Any wrapper failure therefore stops migration, seed and application deployment. `sc-mtp-azure-demo-dev`, `mdp-mtp-dev-uks-001`, default-false deployment/rollback parameters, exact-commit approvals and the seven-stage structure are unchanged.

### Regression coverage and local evidence

The new Linux-only regression uses harmless temporary shell-script fixtures and no Azure or SQL access. It covers a downloaded file initially without execute permission, separated arguments and paths containing spaces, waiting for delayed successful completion, nonzero exit, missing bundle, invalid executable format, a fake `xdg-open` trap, pre-execution tamper rejection, symlink substitution rejection and an unchanged SHA-256 after `u+x`. It fails immediately when not running under real PowerShell on Linux and is wired once into the existing unprotected `Validate/Application` `ubuntu-latest` job; Windows parsing is not represented as Linux execution evidence.

| Check | Result |
|---|---|
| Exact baseline | PASS before editing: branch `fix/mtp-azure-demo-reconciliation`; HEAD `e510189848cf7b571e62a710fe27b61d2c0e6d21`; clean worktree; empty staged index; local `origin` and `azure` tracking refs both exactly aligned with HEAD. |
| PowerShell parsing | PASS: the two new scripts and modified pipeline structural regression parsed with zero errors under Windows PowerShell 5.1. |
| Pipeline structure and cleanup | PASS, exit `0`: seven ordered stages, default-disabled deploy/rollback, approved service connections and agent pool, identity/target/SQL evidence guards, immutable invocation, native-process contract, migration-before-seed-before-deploy ordering, and both `finally` cleanup paths remain enforced. |
| Migration identity | PASS, exit `0`: one accepted and 15 fail-closed cases. |
| Migration target | PASS, exit `0`: one accepted and seven fail-closed cases. |
| Immutable seed/artifact | PASS, exit `0`: Package publication, complete hash manifest, protected seed execution/reset/idempotency and fail-closed path/content checks against the unchanged ignored baseline artifact. |
| Package/hash generation regression | PASS, exit `0`: repository boundary, ZIP, exact-file manifest, SHA-256 and deterministic generation checks for 1,803 unchanged local payload files. No artifact or approval evidence was regenerated. |
| Application artifact regression | PASS, exit `0`: hash, root-layout and prohibited-file checks. |
| Durable SQL-bootstrap evidence | PASS, exit `0`: 27 accepted, 45 fail-closed, five executable-resolution and three culture-execution cases across 17 safe rejection categories. |
| Database-principal SQL | PASS, exit `0`: seven external variables, correct database, 30 invalid guard cases and three approved `CREATE USER` shapes. |
| Source/security boundary | PASS, exit `0`: 185 source/configuration files and no generated/binary, secret, LocalTest or prohibited-capability finding. |
| Real PowerShell-on-Linux bundle regression | UNAVAILABLE locally: `pwsh.exe` is absent; Docker and Podman are absent; `wsl.exe --status` exited `50` because WSL is not installed. The regression is mandatory in the unprotected `ubuntu-latest` validation job before protected execution retest. |
| Protected/external execution | NOT RUN: no Azure, Azure DevOps, SQL, real migration bundle, deployment, migration, seed, swap or rollback action occurred. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_TEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_e510189848cf7b571e62a710fe27b61d2c0e6d21"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-01", "C-11"]
    functional_requirements: ["F-01", "F-02", "F-13", "F-14", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-06", "NF-10", "NF-12"]
    risks: ["R-02", "R-09", "R-11"]
    assumptions: ["A-11", "A-12", "A-18"]
    dependencies: ["D-02", "D-03", "D-04", "D-05", "D-11"]
    issues: ["I-06", "I-08"]
    open_questions: ["Q-01", "Q-06", "Q-08", "Q-09"]
    approvals: []
  artefacts:
    - "azure-pipelines.yml"
    - "scripts/database/Invoke-AzureDemoEfMigrationBundle.ps1"
    - "scripts/build/Test-AzureDemoEfMigrationBundleExecution.ps1"
    - "scripts/build/Test-AzurePipelineStructure.ps1"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "Exact clean baseline, empty index and aligned origin/azure refs confirmed before editing."
    - "All locally available pipeline, identity, target, immutable artifact/seed, package/hash, application artifact, SQL evidence, SQL guard and source-boundary checks passed."
    - "Real Linux execution coverage is implemented and wired but remains outstanding because no local Linux PowerShell runtime is available."
  decisions:
    - "Execute only the exact hash-validated bundle as a shell-disabled native process and inspect only that process's exit status."
    - "Adjust permission only on the validated bundle and prove its approved content hash remains unchanged."
  assumptions:
    - "Build 40's downloaded mode was not measured; missing execute permission remains a runtime hypothesis rather than a claimed fact."
  risks:
    - "The new Linux-native regression must pass on ubuntu-latest before the protected execution retest."
    - "The protected pipeline must independently prove the downloaded Azure DevOps artifact's runtime mode and native launch behavior."
  defects:
    - "REPAIRED LOCALLY: build 40 could report migration success after file-association failure without observing a bundle process exit code."
  blockers:
    - "Real PowerShell-on-Linux regression evidence is outstanding."
    - "Independent protected Azure DevOps bundle execution retest remains required; no database migration is claimed."
  approvals: []
  requested_action: "Independent Tester must first run the unprotected Ubuntu regression, then retest the protected migration task and prove native bundle completion before seed or slot deployment."
```

READY_FOR_EF_BUNDLE_EXECUTION_RETEST

## Linux CI dependent unit assertion repair

### Confirmed regression cause and bounded correction

Linux CI against `720688160cc30e109a1a19c3bbd9b06a892e3e70` passed locked restore, Release build and all 145 integration tests, then reported 204 passing unit tests and one failure in `AzureDemoDeploymentBoundaryTests.Deferred_internal_LGR_naming_remains_unchanged`. The naming contract was not removed: the protected EF migration `AzureCLI@2` task invokes `./scripts/database/Invoke-AzureDemoEfMigrationBundle.ps1` with the exact immutable artifact root, deployment manifest and source commit, while that wrapper retains the sole reviewed executable identity `migration/lgrtm-efbundle-linux-x64`.

The boundary test had continued to require the bundle filename directly in `azure-pipelines.yml` after execution ownership moved into the wrapper. The correction isolates the named EF migration task and requires exactly one active line containing the complete approved wrapper invocation. It separately requires exactly one active wrapper assignment to the approved bundle identity. Existing solution, project, namespace, connection-string, variable-group, service-connection, pipeline, environment, managed-pool and retired-name assertions remain unchanged. The assertions cannot be satisfied by a YAML comment, unused variable or concatenated global file search.

No pipeline or wrapper implementation change was required. The existing wrapper still requires Linux, absolute immutable-artifact paths, complete deployment-artifact validation, regular-file checks, a bundle-only `u+x`, post-permission execute-mode and SHA-256 validation, `UseShellExecute = false`, separated native arguments, process completion and that process's zero exit code. The pipeline structural validator still proves that migration failure cannot continue to seed or application deployment.

The previous Build 40 handoff checks missed this dependent unit assertion: they validated the new PowerShell scripts and pipeline structure but did not rerun the entire unit suite after moving the bundle identity out of YAML and into the wrapper. This addendum records that evidence gap rather than treating the original handoff as complete.

### Local regression evidence

| Check | Result |
|---|---|
| Exact baseline | PASS before editing: branch `fix/mtp-azure-demo-reconciliation`; HEAD `720688160cc30e109a1a19c3bbd9b06a892e3e70`; clean worktree; empty staged index. |
| Pre-edit failing assertion | REPRODUCED, exit `1`: `dotnet test tests/api.unit/LgrTransformationMigration.Api.UnitTests.csproj --configuration Release --no-restore --filter "FullyQualifiedName~AzureDemoDeploymentBoundaryTests.Deferred_internal_LGR_naming_remains_unchanged" --logger "console;verbosity=minimal"` failed only at the stale YAML filename assertion. |
| Focused boundary tests | PASS, exit `0`: `dotnet test tests/api.unit/LgrTransformationMigration.Api.UnitTests.csproj --configuration Release --no-restore --filter "FullyQualifiedName~AzureDemoDeploymentBoundaryTests" --logger "console;verbosity=minimal"` passed 10/10. NuGet vulnerability metadata was unavailable and emitted `NU1900`; package restoration was not performed. |
| Entire unit suite | PASS, exit `0`: `dotnet test tests/api.unit/LgrTransformationMigration.Api.UnitTests.csproj --configuration Release --no-build --no-restore --logger "console;verbosity=minimal"` passed 205/205. |
| Pipeline structural validation | PASS, exit `0`: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build/Test-AzurePipelineStructure.ps1` passed all seven ordered stages and retained the Linux execution-regression wiring. |
| Focused formatting | PASS, exit `0`: `dotnet format LgrTransformationMigration.sln --verify-no-changes --no-restore --include tests/api.unit/AzureDemoDeploymentBoundaryTests.cs`. |
| Real PowerShell-on-Linux bundle regression | NOT RUN and not claimed as passed. This host has no `pwsh`, Docker or Podman; the test remains wired exactly once into the unprotected `Validate/Application` `ubuntu-latest` job and still requires Linux CI execution. |
| Protected/external execution | NOT RUN: no Azure, Azure DevOps, SQL, pipeline, deployment, migration, seed, swap or rollback action occurred. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_TEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_720688160cc30e109a1a19c3bbd9b06a892e3e70"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-01", "C-11"]
    functional_requirements: ["F-01", "F-02", "F-13", "F-14", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-06", "NF-10", "NF-12"]
    risks: ["R-02", "R-09", "R-11"]
    assumptions: ["A-11", "A-12", "A-18"]
    dependencies: ["D-02", "D-03", "D-04", "D-05", "D-11"]
    issues: ["I-06", "I-08"]
    open_questions: ["Q-01", "Q-06", "Q-08", "Q-09"]
    approvals: []
  artefacts:
    - "tests/api.unit/AzureDemoDeploymentBoundaryTests.cs"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "The stale pre-edit assertion was reproduced, and the final focused boundary and full unit suites passed."
    - "Pipeline structure proves the exact wrapper invocation and one Ubuntu validation-stage Linux execution regression."
  decisions:
    - "Follow the actual YAML-to-wrapper execution boundary while preserving the exact deferred internal bundle identity."
  assumptions: []
  risks:
    - "The Linux-native regression still requires execution on a real Linux CI agent."
  defects:
    - "REPAIRED LOCALLY: the unit boundary test searched the YAML for a bundle identity now owned by the approved wrapper."
    - "PREVIOUS HANDOFF EVIDENCE GAP: the dependent unit assertion was not rerun after the execution-structure change."
  blockers:
    - "Real PowerShell-on-Linux regression evidence remains outstanding."
    - "Independent protected Azure DevOps bundle execution retest remains required; no database migration is claimed."
  approvals: []
  requested_action: "Independent Tester must run the full Linux validation job, confirm the native execution regression passes, and retain the protected migration retest requirement."
```

READY_FOR_TEST

## EF migration bundle DbContext creation repair

### Baseline, scope and traceability

The Developer repair started from the exact requested baseline: branch `fix/mtp-azure-demo-reconciliation`, commit `428686548f743158e5e5b332a7ab1b6cc30c6a44`, clean worktree and empty staged index. It remains within `AZURE-DEMO-001`, `DEV-AC-06`, `NF-03`, `NF-07`, `NF-10`, `NF-12`, `R-09` and `R-11`. The approved local/non-production SQL POC stack in ADR-006 covers this bounded EF configuration repair; wider production Q-01 approval remains outside this work.

No EF migration, model snapshot, schema, seed content, dependency, web startup, identity, network, service connection, approval control or deployment default changed. No Azure, Azure DevOps or SQL system was accessed, and no migration or seed was executed.

### Confirmed cause and runtime evidence boundary

The baseline had no `IDesignTimeDbContextFactory<AppDbContext>`. EF therefore attempted application-service-provider discovery through `Program.cs`. That web bootstrap adds `appsettings.LocalTest.json` as a non-optional relative file whenever the ASP.NET environment is `Development` or `Testing`. The protected error resolved that relative file as `/mnt/vss/_work/1/s/appsettings.LocalTest.json`, confirming that protected bundle execution entered web bootstrap from the repository working directory under one of those two environment names. `AppDbContext` also requires both `DbContextOptions<AppDbContext>` and `ICurrentCustomerContext`, so EF's subsequent constructor fallback could not satisfy the context.

Local verbose EF 10.0.11 execution with both `DOTNET_ENVIRONMENT` and `ASPNETCORE_ENVIRONMENT` unset reported `Using environment 'Development'`, found `MigrationDbContextFactory`, and then reported `Using DbContext factory 'MigrationDbContextFactory'`. The local observation establishes the EF CLI default but does not prove which protected-agent variable or EF default selected Development/Testing in the failed bundle. The protected task did not record those variables, so their exact inherited values remain an unresolved runtime fact. The native wrapper sets neither a working directory nor an environment name; its shell-disabled child therefore inherits the pipeline process working directory and environment.

### Chosen migration-context contract

`MigrationDbContextFactory` is now the single EF design-time/bundle creation boundary. It constructs `AppDbContext` directly with the SQL Server provider and an inert migration-only customer context. It reads no JSON file, environment name, web-host service or connection string. It deliberately configures no database target: EF bundle execution must inject the already guarded connection through `--connection`, while offline model, migration-list and script operations can create the context without a connection.

The existing SQL Server defaults are retained. Tests prove provider `Microsoft.EntityFrameworkCore.SqlServer`, the `AppDbContext` assembly and model snapshot, all eight existing migrations in order, and the default `__EFMigrationsHistory` creation script. The runtime web registration remains unchanged. The protected path remains `LGR_AZURE_DEMO_SQL_CONNECTION_STRING` -> exact passwordless workload-identity target guard -> shell-disabled wrapper -> separated `--connection` argument. Missing configuration is rejected before permission change or payload execution, and the connection value is never written to diagnostics by the new tests.

The native wrapper retains exact-commit and hash validation, lexical path and symbolic-link rejection, regular-file checks, bundle-only `u+x`, post-permission hash verification, `UseShellExecute = false`, separated arguments, process-specific exit-code enforcement and task `finally` token/environment cleanup. Its Linux regression now also proves that a missing connection cannot reach permission change or execution. The DataTool remains independently configured from `LGR_AZURE_DEMO_SQL_CONNECTION_STRING`, uses `UseSqlServer(connectionString)`, and calls `GetPendingMigrationsAsync()` before its first mutation; its refusal to seed when migrations are pending was not weakened.

### Packaging and configuration dependency findings

- EF `migrations list --no-connect` selected the dedicated factory from an empty temporary directory for unset, Development, Testing and accidental LocalTest environment/authentication selections. No local configuration file was read or created.
- Offline idempotent-script generation selected the factory and emitted all eight migrations plus `__EFMigrationsHistory` without contacting a database.
- Application packaging continues to include only `appsettings.json` and `appsettings.AzureDemo.json`; LocalTest, Development and Testing files remain prohibited and excluded.
- The published DataTool still requires only its explicit immutable artifact/seed manifest arguments and process connection environment; it does not discover a repository or local appsettings file.
- Native `linux-x64` bundle generation could not be completed on this host because NuGet access is blocked and the required target-runtime restore metadata is not cached. Verbose failure was `NU1301` while resolving project metadata for `linux-x64`, before bundle construction. This is unavailable evidence, not a DbContext failure or a passing bundle check.

### Changed files

- `src/api/Infrastructure/MigrationDbContextFactory.cs`
- `tests/api.unit/MigrationDbContextFactoryTests.cs`
- `scripts/build/Test-EfMigrationDbContextCreation.ps1`
- `scripts/build/Test-AzureDemoEfMigrationBundleExecution.ps1`
- `scripts/build/Test-AzureDemoImmutableSeedArtifact.ps1`
- `scripts/build/Test-AzurePipelineStructure.ps1`
- `azure-pipelines.yml`
- `docs/implementation/AZURE_DEMO_Implementation_Work_Package.md`

### Local verification

| Check | Result |
|---|---|
| Exact baseline | PASS before editing: branch `fix/mtp-azure-demo-reconciliation`; HEAD `428686548f743158e5e5b332a7ab1b6cc30c6a44`; clean worktree; empty staged index. |
| Release build | PASS, exit `0`: `dotnet build LgrTransformationMigration.sln --configuration Release --no-restore`; four `NU1900` warnings reported unavailable NuGet vulnerability metadata. |
| Focused factory unit test | PASS, exit `0`: 1/1; created the context from an empty temporary directory and verified provider, no connection, migration assembly/snapshot, all eight migrations and history table SQL without database access. |
| EF environment/context regression | PASS, exit `0`: actual EF 10.0.11 `migrations list --no-connect --verbose` selected `MigrationDbContextFactory` and discovered all eight migrations from an empty temporary directory for unset, Development, Testing and accidental LocalTest selections. |
| Idempotent migration SQL | PASS, exit `0`: offline `migrations script --idempotent --no-build` discovered all eight migrations and `__EFMigrationsHistory`; no database connection was opened and the generated validation file was removed. |
| Entire unit suite | PASS, exit `0`: 207/207. |
| Entire integration suite | PASS, exit `0`: 145/145. |
| Pipeline, target and identity regressions | PASS: seven-stage structural contract; one valid/seven invalid target cases; one valid/15 invalid identity cases; 20 migration-artifact parsing cases. |
| Packaging/seed/source regressions | PASS: immutable seed prerequisite and path contract; application prohibited-file/hash/root checks; deterministic package/hash checks across the existing 1,803-file ignored fixture; source/security boundary across 187 source/configuration files. The existing fixture is structural evidence, not a regenerated artifact for this worktree. |
| Formatting and diff hygiene | PASS: focused `dotnet format --verify-no-changes`; four changed PowerShell files parsed with zero errors; `git diff --check` passed with only Git line-ending notices. |
| Native Linux bundle regression | NOT RUN and not claimed. This Windows host has no `pwsh`, Docker or Podman; `wsl.exe --status` exits `50` because WSL is not installed. The regression remains required exactly once in the unprotected `ubuntu-latest` validation job. |
| Linux bundle generation | UNAVAILABLE and not passed: `linux-x64` bundle creation failed on blocked NuGet access with `NU1301`; no bundle was produced. |
| Connected dependency checks | UNAVAILABLE and not passed: both vulnerable and deprecated package queries exited `1` because `https://api.nuget.org/v3/index.json` is unreachable. No dependency changed. |
| External/protected actions | NOT RUN: no Azure, Azure DevOps, SQL, protected pipeline, migration, seed, deployment, swap or rollback action occurred. `sql-bootstrap.json` and approval evidence were neither accessed nor regenerated. |

### Remaining verification

Independent Linux CI must execute the new context-creation regression and existing real native-wrapper regression. Package CI must build the `linux-x64` migration bundle with connected pinned dependencies. Protected deployment must then rerun the exact reviewed bundle under the approved workload identity and SQL target, prove the factory is selected with the protected `--connection` handoff, and report the bundle process exit code. This work does not claim that migrations were applied.

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_TEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_428686548f743158e5e5b332a7ab1b6cc30c6a44"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-11"]
    functional_requirements: ["F-13", "F-14"]
    non_functional_requirements: ["NF-03", "NF-07", "NF-10", "NF-12"]
    risks: ["R-09", "R-11"]
    assumptions: ["A-11", "A-12", "A-18"]
    dependencies: ["D-04", "D-11"]
    issues: ["I-06", "I-08"]
    open_questions: ["Q-01", "Q-08"]
    approvals: []
  artefacts:
    - "src/api/Infrastructure/MigrationDbContextFactory.cs"
    - "tests/api.unit/MigrationDbContextFactoryTests.cs"
    - "scripts/build/Test-EfMigrationDbContextCreation.ps1"
    - "scripts/build/Test-AzureDemoEfMigrationBundleExecution.ps1"
    - "scripts/build/Test-AzureDemoImmutableSeedArtifact.ps1"
    - "scripts/build/Test-AzurePipelineStructure.ps1"
    - "azure-pipelines.yml"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "All locally available build, context creation, unit, integration, pipeline, guard, artifact, seed, source-boundary, formatting and diff checks passed."
    - "Linux-native execution, connected bundle production, connected dependency analysis and protected deployment remain explicitly outstanding."
  decisions:
    - "Use an EF design-time factory with a provider-only, target-free context instead of web-host bootstrap."
    - "Keep the guarded protected --connection argument as the only runtime migration target handoff."
  assumptions:
    - "The exact protected DOTNET_ENVIRONMENT/ASPNETCORE_ENVIRONMENT value was not captured; the missing LocalTest path proves only that web bootstrap evaluated Development or Testing."
  risks:
    - "Independent Linux and protected workload-identity execution evidence remains mandatory."
  defects:
    - "REPAIRED LOCALLY: migration context creation depended on web startup and a non-deployed LocalTest configuration file."
  blockers: []
  approvals: []
  requested_action: "Independent Tester must execute Linux validation, build the native bundle with connected pinned dependencies, and then retain the protected no-claim migration retest under the approved identity and SQL target."
```

READY_FOR_TEST

## Linux EF bundle symbolic-link regression repair

### Baseline, scope and traceability

The Developer repair started from the exact requested baseline: branch `fix/mtp-azure-demo-reconciliation`, commit `e036e7891c7c5ed8c932b52023dcccbf01d51426`, clean worktree and empty staged index. It remains within `AZURE-DEMO-001`, `DEV-AC-06`, `NF-03`, `NF-07`, `NF-10`, `NF-12`, `R-09` and `R-11`. It changes only immutable deployment-artifact path validation, the EF bundle wrapper, its Linux/structural/boundary regressions and this implementation record. No product capability, migration, schema, seed, application startup, identity, connection, network, dependency, Azure resource or pipeline deployment definition changed.

### Confirmed cause and evidence boundary

The reported line 98 was the old negative-test classifier, not the wrapper or payload. `Assert-Failed` combined two different outcomes in one condition: a zero child exit, or a nonzero child exit whose human-formatted stderr did not contain one exact contiguous exception sentence. It then discarded the exit code and stderr and emitted the same `did not fail closed` message for both. PowerShell may decorate or wrap rendered error text, so matching that presentation is not a reliable exception contract. The retained CI message therefore proves only that the classifier condition fired; it does not prove that the linked payload executed. Because the old helper emitted neither the child result nor an execution marker for this fixture, the original CI output cannot distinguish successful return from an intended rejection that was misclassified.

Code inspection confirms that an ordinary bundle-file link reached `Resolve-AzureDemoArtifactPath`, whose existing `Assert-AzureDemoNoReparsePoints` check preceded `Resolve-Path`. The original test nevertheless did not verify `CreateSymbolicLink` outcome/type or prove non-execution. Two adjacent path-contract gaps were also found and repaired: the wrapper resolved `ImmutableArtifactRoot` before shared validation, erasing a root link from the inspected path, and `Resolve-AzureDemoArtifactPath` performed existence/type checks before reparse inspection, classifying a dangling link as an ordinary missing path.

### Bounded repair

The wrapper now keeps the absolute lexical immutable root through the shared validator. The shared validator inspects the candidate, each in-root ancestor and the root with non-following file attributes before any existence check or `Resolve-Path`; missing components remain permissible during ancestry inspection so the existing explicit missing-root/missing-payload errors remain intact, while dangling links retain their reparse identity and are rejected. Manifest generation applies the same root rule instead of resolving a supplied root link away. Resolved containment, complete manifest/file-set validation, exact source-commit binding and SHA-256 validation remain unchanged.

The Linux regression now creates links with absolute `/usr/bin/ln` or `/bin/ln`, requires exit code zero, then verifies `ReparsePoint`, `LinkType == SymbolicLink` and the exact recorded target. It covers bundle-file, `migration` ancestor-directory, immutable-root and dangling links. The three executable substitutions use same-hash harmless payloads that create local markers if launched; every rejection requires its marker to remain absent. Regular-file execution, delayed wait, separated connection argument, nonzero exit, missing path, invalid format/association trap, tamper rejection, bundle-only `chmod u+x --`, post-permission mode and unchanged hash remain covered.

The child regression driver now catches wrapper exceptions and emits a base64-encoded JSON record containing only exception type and message with a dedicated exit code. The parent distinguishes successful return, the intended rejection, a different exception, malformed/missing exception evidence and an unexpected process exit. Diagnostics redact the synthetic connection value, replace the temporary root and cap output length. Human-formatted PowerShell stderr is no longer the assertion protocol.

Pipeline and compiled boundary checks require the lexical-root rule and reparse validation before root/payload existence checks. The protected task still uses the exact commit-bound manifest and wrapper. The wrapper still validates the complete manifest and hashes before permission change, changes only the validated bundle mode, disables shell execution, passes separated arguments, waits, reads the launched process's own exit code and rejects nonzero completion.

### Verification

| Check | Result |
|---|---|
| PowerShell parsing | PASS, exit `0`: `AzureDemoDeploymentArtifactUtilities.ps1`, `Invoke-AzureDemoEfMigrationBundle.ps1`, `Test-AzureDemoEfMigrationBundleExecution.ps1` and `Test-AzurePipelineStructure.ps1` parsed with zero errors under Windows PowerShell 5.1. Parsing is not Linux runtime evidence. |
| Pipeline structural regression | PASS, exit `0`: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build/Test-AzurePipelineStructure.ps1`; seven ordered stages and the execution/path boundary contract passed. |
| Focused deployment-boundary suite | PASS, exit `0`: `dotnet test tests/api.unit/LgrTransformationMigration.Api.UnitTests.csproj --configuration Release --no-restore --filter "FullyQualifiedName~AzureDemoDeploymentBoundaryTests" --logger "console;verbosity=minimal"`; 11/11 passed. Restore was not performed; NuGet vulnerability metadata was unavailable and emitted `NU1900`. |
| Immutable seed/deployment artifact regression | PASS, exit `0`: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build/Test-AzureDemoImmutableSeedArtifact.ps1 -PackageDirectory artifacts/azure-demo-ci/packages -ExpectedSourceCommit 0989a99d871c7158eed4994c9e6ff1f7a994ab0f`; the unchanged ignored fixture was validated at its recorded commit. |
| Package/hash generation regression | PASS, exit `0`: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build/Test-AzureDemoPackageGeneration.ps1 -PackageDirectory artifacts/azure-demo-ci/packages -ExpectedSourceCommit 0989a99d871c7158eed4994c9e6ff1f7a994ab0f`; 1,803 payload files passed. |
| Application artifact regression | PASS, exit `0`: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build/Test-AzureDemoArtifacts.ps1 -ArtifactDirectory artifacts/azure-demo-ci/packages/application`. |
| Source/security boundary | PASS, exit `0`: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build/Test-AzureDemoSourceBoundaries.ps1`; 185 source/configuration files passed. |
| Full unit suite | PASS, exit `0`: `dotnet test tests/api.unit/LgrTransformationMigration.Api.UnitTests.csproj --configuration Release --no-build --no-restore --logger "console;verbosity=minimal"`; 206/206 passed. |
| Focused formatting | PASS, exit `0`: `dotnet format LgrTransformationMigration.sln --verify-no-changes --no-restore --include scripts/build/AzureDemoDeploymentArtifactUtilities.ps1 scripts/build/Test-AzureDemoEfMigrationBundleExecution.ps1 scripts/build/Test-AzurePipelineStructure.ps1 scripts/database/Invoke-AzureDemoEfMigrationBundle.ps1 tests/api.unit/AzureDemoDeploymentBoundaryTests.cs`; workspace-load warnings were emitted, with no formatting difference. |
| Real Linux execution regression | UNAVAILABLE locally and not claimed: `pwsh` and Docker are absent, and WSL reports that it is not installed. `scripts/build/Test-AzureDemoEfMigrationBundleExecution.ps1` must pass under real PowerShell on Linux before this defect is considered independently verified. |
| External/protected actions | NOT RUN: no Azure, Azure DevOps, SQL, real bundle/database, deployment, migration, seed, swap or rollback access/action occurred. No artifact, `sql-bootstrap.json` or approval evidence was regenerated. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_TEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_e036e7891c7c5ed8c932b52023dcccbf01d51426"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-11"]
    functional_requirements: ["F-13", "F-14"]
    non_functional_requirements: ["NF-03", "NF-07", "NF-10", "NF-12"]
    risks: ["R-09", "R-11"]
    assumptions: ["A-11", "A-12", "A-18"]
    dependencies: ["D-04", "D-11"]
    issues: ["I-06", "I-08"]
    open_questions: ["Q-01", "Q-08"]
    approvals: []
  artefacts:
    - "scripts/build/AzureDemoDeploymentArtifactUtilities.ps1"
    - "scripts/database/Invoke-AzureDemoEfMigrationBundle.ps1"
    - "scripts/build/Test-AzureDemoEfMigrationBundleExecution.ps1"
    - "scripts/build/Test-AzurePipelineStructure.ps1"
    - "tests/api.unit/AzureDemoDeploymentBoundaryTests.cs"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "All locally supported artifact, pipeline, boundary, source and full-unit checks passed."
    - "The original line-98 diagnostic did not establish payload execution; future link fixtures have verified creation and non-execution markers."
  decisions:
    - "Retain lexical immutable paths until root, ancestor and payload link inspection completes."
    - "Use structured exception evidence rather than rendered stderr as the negative-test assertion protocol."
  assumptions: []
  risks:
    - "Real PowerShell-on-Linux execution remains mandatory because no supported local Linux runtime exists."
  defects:
    - "REPAIRED LOCALLY: ambiguous negative-test classification and incomplete root/dangling-link validation."
  blockers: []
  approvals: []
  requested_action: "Independent Tester must run the real Linux EF migration bundle execution regression and confirm all marker-backed link substitutions are rejected before permission change or payload launch."
```

READY_FOR_TEST
