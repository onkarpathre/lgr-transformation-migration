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

## PowerShell 7 readiness-evidence timestamp preservation repair

### Baseline, scope and traceability

This bounded Developer repair started from branch `fix/mtp-azure-demo-reconciliation` at exact HEAD `92d6c149346367e84b57bfc2f2b5bfc5be4b6fe5` with a clean index and worktree. It is limited to the Linux validation failure in `Test-AzureDemoPostDeploymentReadiness.ps1`; it does not change the readiness evidence writer, HTTP behavior, target allowlist, redaction schema, pipeline deployment sequence or protected environment. Nothing was committed, pushed, deployed, migrated, seeded or swapped.

```yaml
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
```

This local regression repair is separable from the remaining Q-01 and Q-08 production decisions. It reuses the approved smoke-evidence JSON contract, performs only synthetic local validation and neither changes nor exercises a protected environment. All connected-CI, staging, protected-evidence and human release gates remain in force.

### Failure analysis and repair

The timeout writer retained the expected raw JSON token `"2026-10-07T20:17:02.0000000+00:00"` under the exact `timeUtc` property. The failing test reader then used plain `ConvertFrom-Json`; on the failing PowerShell 7 path that timestamp was materialised as `System.DateTime`. The assertion cast that value back to a culture-formatted string and compared it with `^2026-10-07T20:17:02(?:\.0{7})?\+00:00$`, so the failure did not mean the property was missing or the stored token was malformed.

The readiness regression now reads JSON through `ConvertFrom-AzureDemoSmokeEvidenceJson`, which selects `ConvertFrom-Json -DateKind String` when the runtime supports it and retains the established Windows PowerShell 5.1 fallback. It requires the parsed property to remain a `System.String`, validates the original value with the shared strict UTC syntax validator, and compares that original string with the exact writer value. It never reconstructs a converted date with `ToString('O')`. A non-zero-offset timestamp fixture must fail closed.

### Changed files and verification

- `scripts/build/Test-AzureDemoPostDeploymentReadiness.ps1`: preserves JSON timestamp strings, validates strict UTC syntax and exact value, and covers immediate success, recovery, persistent 503, timeout, malformed timestamp and temporary-evidence cleanup.
- `docs/implementation/AZURE_DEMO_Implementation_Work_Package.md`: records this implementation and independent Linux verification requirement.

| Check | Result |
|---|---|
| Focused readiness regression | PASS on Windows PowerShell 5.1: success, recovery, persistent 503, deadline timeout, strict malformed-timestamp rejection, target substitution, four-field redaction and cleanup. |
| Safe timestamp observation | PASS: raw token `"2026-10-07T20:17:02.0000000+00:00"`, property `timeUtc`, preserved runtime type `System.String`; the Windows PowerShell 5.1 default type is also `System.String`. |
| Smoke evidence contract | PASS on Windows PowerShell 5.1, including the existing string-preserving JSON parser and full UTC timestamp matrix. |
| Supplemental smoke orchestration | PASS on Windows PowerShell 5.1; the script explicitly retains its separate Linux HTTP/SMK-20 requirement. |
| Source-boundary scan | PASS for 212 source/configuration files. |
| Pipeline structure | PASS for seven ordered stages; the readiness task remains on `ubuntu-latest` and the production entry point retains 120-second overall, five-second poll and ten-second request limits. |
| PowerShell parsing and diff whitespace | PASS for the readiness test, writer, production entry point and shared evidence contract; `git diff --check` exits `0`. |
| PowerShell 7 production-entry execution | `LINUX_VERIFICATION_PENDING`: no local `pwsh`, WSL, Docker or Podman runtime is available; a temporary isolated PowerShell tool download was blocked by network policy and left no repository artefact. The exact `ubuntu-latest` task must prove default `System.DateTime` versus preserved `System.String` and pass all focused cases. |
| External/protected actions | NOT RUN: no Azure, Azure DevOps, SQL, Entra, deployment, migration, seed, smoke, swap, release or approval action occurred. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_TEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_92d6c149346367e84b57bfc2f2b5bfc5be4b6fe5"
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
    - "scripts/build/Test-AzureDemoPostDeploymentReadiness.ps1"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "Windows PowerShell 5.1 focused readiness, smoke-evidence, orchestration, source-boundary, pipeline-structure, parsing and diff checks pass."
    - "The original JSON timestamp string is checked before any temporal parsing and a non-UTC offset fails closed."
  decisions:
    - "Use the established feature-detected ConvertFrom-Json -DateKind String contract for readiness evidence."
    - "Validate strict UTC syntax and the exact original string; never reformat an automatically materialised date."
    - "Leave the production writer, redaction schema and fixed 120-second readiness deadline unchanged."
  assumptions: []
  risks:
    - "The exact ubuntu-latest PowerShell 7 production-entry task remains mandatory before independent acceptance."
  defects:
    - "REPAIRED LOCALLY: plain ConvertFrom-Json materialised timeUtc as System.DateTime on PowerShell 7 and invalidated a string-form assertion despite correct raw JSON."
  blockers: []
  approvals: []
  requested_action: "Independent Tester must run scripts/build/Test-AzureDemoPostDeploymentReadiness.ps1 and the pipeline structural regression on ubuntu-latest PowerShell 7, confirm defaultType=System.DateTime and preservedType=System.String, and retain the same exact commit/worktree evidence before quality review."
```

READY_FOR_TEST

## Bounded post-deployment staging readiness gate

### Baseline, authority and traceability

This bounded Developer repair started from branch `fix/mtp-azure-demo-reconciliation` at exact HEAD `854e8bb3b7b0cfc9b21183d1af0f50ccb973e6f6`, the commit used by Azure DevOps run 77. The worktree and index were clean. Run 77 recorded a transient web `/health` 503 while the correlated API readiness request exhausted its existing shared five-second dependency budget at storage; later probes recovered to HTTP 200. The repair adds orchestration around the existing health contracts. It does not change the API readiness implementation or budget, suppress a 503, weaken smoke assertions, or change any Azure resource.

```yaml
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
```

The approved AZURE-DEMO-001 package closes Q-01 only for its controlled implementation scope. This pipeline-only retry gate retains the approved PowerShell, exact-target and health architecture and is separable from Q-08 production service acceptance. It does not authorise deployment, release, protected evidence ingestion or a slot swap.

### Implemented gate

After both staging deployments, exact deployed-content verification and the existing Azure CLI resource/hostname resolver, the pipeline now runs one bounded readiness task before staging smoke. The task validates the fixed approved subscription, resource group, web/API applications and `staging` slot, then applies the existing exact URI target contract to:

- API staging `https://<Azure-resolved-api-slot-host>/health/ready`; and
- web staging `https://<Azure-resolved-web-slot-host>/health`.

The production entry point fixes the policy at two complete consecutive healthy rounds, a 120-second overall deadline, a five-second poll interval and a ten-second per-request cap reduced to the remaining deadline. Both endpoints must return HTTP 200 in each round. A 503, transport failure, malformed result or incomplete round resets the sequence; non-stabilisation fails the task and therefore prevents staging smoke, ReleaseApproval and swap. The existing smoke task still retains and aggregates its own failures after this gate passes.

Each request carries a generated W3C trace correlation. The readiness artifact is overwritten after each completed probe and contains only an array of exact four-field records: `timeUtc`, numeric HTTP `status` or `unavailable`, `phase` (`api-readiness` or `web-readiness`) and lowercase correlation ID. Pipeline information output uses the same four fields. Request/response bodies, headers, hostnames, paths, query strings and exception messages are neither recorded nor emitted. Failed attempted-gate evidence is published with `always()` without changing the task's nonzero result.

### Protected evidence finding retained

The 17 protected/hybrid checks remain `SMK-01`, `SMK-04` through `SMK-09`, `SMK-12` through `SMK-19`, `SMK-21` and `SMK-22`. Genuine input must be an approved same-run protected bundle passed explicitly as `-ProtectedEvidenceDirectory`. It must contain one `SMK-xx.json` per required check plus all sanitized assertion attachments beneath the same root. Each record must satisfy the exact protected-runtime schema and bind to the current lowercase source commit, deployment-manifest SHA-256, infrastructure deployment ID, pipeline definition/run, Azure-resolved subscription/resource/app/slot/hosts, required producer location/identity, real UTC interval and correlation ID. Every exact assertion must be `PASS` and reference a contained attachment whose SHA-256 matches. Non-SMK-19 records require `previousRelease: null`.

The current pipeline still intentionally supplies no `-ProtectedEvidenceDirectory`, and its structural contract forbids adding one until TDA, Test Services, Information Security, Azure DevOps/repository ownership and Azure Platform/Operations approve the producer, immutable same-run delivery, retention/tamper metadata and independent review design. `sql-bootstrap.json`, source tests, local fixtures and bare `status: PASS` JSON do not satisfy the contract. Missing evidence therefore remains `FAIL`.

SMK-19 has no first-release waiver. It additionally requires the protected rehearsal assertions and a real distinct previous release: a different 40-character source commit, different deployment-manifest artifact SHA-256, the contained previous manifest file whose computed hash equals both recorded manifest hashes and whose `sourceCommit` matches, plus non-empty protected deployment-evidence and rehearsal-approval references. The current candidate, a branch/ref, fabricated manifest, or future post-swap result cannot act as the previous release. If no earlier compatible deployed release exists, SMK-19 cannot truthfully pass: release remains blocked until a separately authorised prior-release/rehearsal path exists or the owning authorities approve a formal first-release contract change.

### Changed files and verification

- `azure-pipelines.yml`: runs the focused Linux regression and inserts the fail-closed readiness gate and always-published sanitized evidence before staging smoke.
- `scripts/smoke/AzureDemoPostDeploymentReadiness.ps1`: exact target validation, bounded consecutive-round state machine and four-field evidence writer.
- `scripts/smoke/Invoke-AzureDemoPostDeploymentReadiness.ps1`: PowerShell 7 production entry point with fixed timing policy and correlation propagation.
- `scripts/smoke/AzureDemoSmokeUtilities.ps1`: adds an optional bounded request timeout while retaining the existing 30-second default for smoke callers.
- `scripts/build/Test-AzureDemoPostDeploymentReadiness.ps1`: focused recovery, persistent 503, timeout, target-substitution and redaction regressions.
- `scripts/build/Test-AzurePipelineStructure.ps1`: pins one Linux regression, exact staging targets, timing policy, evidence publication and deploy/resolve/readiness/smoke order.
- `scripts/smoke/README.md`: documents the bounded gate and its safe evidence.
- `docs/implementation/AZURE_DEMO_Implementation_Work_Package.md`: records this hand-off and unchanged protected-evidence blockers.

| Check | Result |
|---|---|
| Focused readiness regression | PASS on Windows PowerShell 5.1: transient 503 recovery required two full healthy rounds; persistent 503 and timeout failed at their fixed deadlines; production-host substitution made zero requests; evidence/output retained only the four safe fields. |
| Pipeline structure | PASS on Windows PowerShell 5.1: seven stages, one Linux regression, exact staging health paths, fixed policy, always-published readiness evidence and readiness-before-smoke order. |
| Exact target regression | PASS: generated-host, resource identity, staging/production, unsafe URI and catalogue-order cases, including 12 invalid resolver cases. |
| Actual pipeline target-caller regression | PASS: both callers, exact production/slot Azure CLI arguments, separated stderr, bounded diagnostics and nonzero fail-closed behavior. |
| Protected evidence contract | PASS as a local contract test only: valid protected-runtime/previous-release fixtures plus all retained missing, malformed, substitution, provenance, attachment and fixture rejections. No protected check is claimed passed. |
| Supplemental smoke orchestration | PASS on Windows PowerShell 5.1 for redirect, success, transport, assertion, missing/rejected evidence, continuation, redaction and publication fixtures. PowerShell 7-only 4xx/5xx normalization and SMK-20 remain pending. |
| Source/security boundary | PASS: 212 source/configuration files. |
| PowerShell parsing and diff whitespace | PASS for all changed scripts; `git diff --check` exited `0` with existing line-ending notices only. |
| Linux PowerShell 7 readiness/HTTP execution | `LINUX_VERIFICATION_PENDING`: `pwsh`, Docker and a usable WSL installation are unavailable locally. The unprotected `ubuntu-latest` Validate job must run the new regression and the preserved PowerShell 7 smoke HTTP/orchestration suites. |
| Protected staging execution | NOT RUN: no Azure CLI, endpoint, Azure DevOps, SQL, Entra, deployment, migration, seed, smoke, swap, rollback or approval action occurred. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_TEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_854e8bb3b7b0cfc9b21183d1af0f50ccb973e6f6"
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
    - "azure-pipelines.yml"
    - "scripts/smoke/AzureDemoPostDeploymentReadiness.ps1"
    - "scripts/smoke/Invoke-AzureDemoPostDeploymentReadiness.ps1"
    - "scripts/smoke/AzureDemoSmokeUtilities.ps1"
    - "scripts/build/Test-AzureDemoPostDeploymentReadiness.ps1"
    - "scripts/build/Test-AzurePipelineStructure.ps1"
    - "scripts/smoke/README.md"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "Focused readiness, exact-target, pipeline-caller, evidence-contract, supplemental orchestration, source-boundary, parsing, structure and diff checks pass locally."
    - "No genuine protected SMK evidence was supplied or claimed."
  decisions:
    - "Require two complete consecutive API/web HTTP 200 rounds within one fixed 120-second deadline."
    - "Use existing Azure-resolved exact-target validation and retain only four safe probe fields."
    - "Keep missing protected evidence and the no-first-release-waiver SMK-19 contract release-blocking."
  assumptions: []
  risks:
    - "Real Linux PowerShell 7 request behavior and the connected exact staging endpoints remain unexecuted."
    - "The protected evidence producer/ingestion amendment and real prior-release SMK-19 evidence remain absent."
  defects:
    - "REPAIRED LOCALLY: staging smoke could begin during transient post-deployment readiness instability."
  blockers:
    - "Independent Linux PowerShell 7 execution of the new and existing HTTP regressions."
    - "Approved protected evidence ingestion and genuine evidence for all 17 protected/hybrid checks."
    - "A real distinct prior deployed release and protected rehearsal for SMK-19, or an approved first-release contract change."
  approvals: []
  requested_action: "Independent Tester must run the new readiness and preserved smoke suites on Linux PowerShell 7, then review a protected staging attempt's sanitized readiness artifact. Release remains blocked until the approved genuine protected-evidence bundle and SMK-19 prior-release rehearsal evidence exist."
```

READY_FOR_TEST

## Bounded API deployment timestamp repair

### Baseline, scope and traceability

This bounded Developer repair started from the requested branch
`fix/mtp-azure-demo-reconciliation` at exact HEAD
`95b4099ffd220a9d6be692ae28b18e31ec8a6c92`. The tracked worktree and index
were clean before editing. The change is limited to immutable application ZIP
creation, API/Web timestamp preflight, the staging pipeline ordering contract,
and synthetic deployment regressions. It does not change the API upload task,
the Web clean-deployment mechanism, Web Oryx allowances, application behaviour,
Azure resources, SQL, identity, protected approvals or release authority.

```yaml
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
```

The existing Product/PRB, independent TDA, Information Security and Test
Services decisions for controlled implementation and local/isolated testing
remain the applicable authority. Q-01 is unchanged for that bounded approved
stack. Q-08, Azure Platform/Operations approval, independent Tester/Quality
evidence and every protected deployment/release decision remain pending and
separable because this repair performs no Azure-impacting action.

### Observed evidence, cause and uncertainty

Run `#20261006.14` reports a complete 61-file API path set with no missing or
unexpected files, but different SHA-256 values for equal-length deployed and
expected `LgrTransformationMigration.Api.dll` and
`LgrTransformationMigration.Api.pdb`. Repository inspection independently
confirmed that API package creation omitted `EntryTimestamp`, causing the ZIP
utility's fixed `1980-01-01T00:00:00` default, while the repaired Web package
already received a creation-specific timestamp. Those facts strongly support a
metadata-aware stale-copy collision for equal path/length/timestamp files.

`C:\Temp\mtp-api-deployment-evidence` was absent on this host. The supplied API
ZIP SHA-256, its entry timestamps and the two supplied file hashes therefore
were not independently verified and are not represented as local artifact
evidence. The exact Azure API deployment-engine comparison algorithm and
whether that algorithm alone caused the observed live bytes remain uncertain
until a fresh authorised Linux CI artifact and staging deployment are observed.

### Implementation

- Application packaging now captures one UTC `applicationPackageTimestamp`,
  writes that timestamp to both API and Web ZIP entries before either hash is
  calculated, and writes the same instant to manifest `createdAtUtc`.
- ZIP creation explicitly serializes timezone-free DOS wall-clock fields from
  UTC components and truncates seconds to the format's two-second precision.
  Non-UTC inputs fail closed. Fixed payload bytes plus one explicit timestamp
  are reproducible; separately created packages intentionally need not have
  equal bytes. Once produced and hashed, an artifact remains immutable.
- API and Web preflight both retain hash-before-timestamp ordering, require one
  uniform non-legacy timestamp exactly equal to the two-second-rounded manifest
  timestamp, and retain structured failure identity. Web keeps
  `WebEntryTimestampInvalid`; API adds `ApiEntryTimestampInvalid`.
- The protected staging job adds an `AzureCLI@2` API preflight immediately
  before the unchanged `AzureWebApp@1` API upload. It resolves and validates
  the authenticated subscription and exact API staging slot, validates the
  outer deployment manifest and source commit, then validates the selected API
  ZIP, inner manifest, SHA-256 and timestamps. A post-deployment check is still
  retained but is not used as a substitute for this pre-upload gate.
- API deployed-content comparison is unchanged in production: every file set
  is derived from the immutable ZIP and compared by exact path, length and
  SHA-256. Missing, changed and unexpected files fail. There are no API DLL,
  PDB or arbitrary-metadata exclusions. The existing bounded Web dependency
  transformation and root `oryx-manifest.toml` handling are unchanged.
- Synthetic API regressions use non-assembly byte fixtures named exactly as the
  DLL and PDB, with equal filenames and lengths but different content. Portable
  tests prove content reconciliation, and the Ubuntu-only test reproduces stale
  `rsync` copying at equal legacy timestamps before proving both files transfer
  after a different serialized package timestamp. ZIP entry and extracted
  timestamps, same-time-bucket collision and non-UTC rejection are explicit.
- The existing collecting regression chain now runs both Linux Web/API
  timestamp tests plus portable timestamp semantics, clean deployment,
  generated-caller boundary, deployed-content, package-generation and pipeline
  structure checks in isolated child processes. It reports every exit code and
  returns nonzero after collection if any child fails.

### Local validation

Runtime: Windows `10.0.26200`, Windows PowerShell `5.1.26100.9444`, .NET SDK
`10.0.401`, Node.js `v24.18.0`. PowerShell 7, installed WSL/Linux, Docker,
Podman and `rsync` were unavailable.

| Check | Result |
|---|---|
| Branch/HEAD/tracked status | PASS before editing: exact requested branch and HEAD; clean tracked index/worktree. |
| Evidence artifact verification | NOT RUN: supplied evidence directory absent; no independent ZIP/hash/timestamp claim. |
| PowerShell parsing | PASS: all changed PowerShell files parse under Windows PowerShell 5.1. |
| API/Web preflight regression | PASS, exit `0`: both valid; both fixed-1980 cases rejected with workload-specific identities; non-uniform API timestamps rejected; both wrong hashes rejected as `ZipHashMismatch`; exact target checks and exit-17 Web deployment failure retained. |
| Generated-caller process boundary | PASS, exit `0`: assertion/native/missing/cleanup children each exit `1`; real regression child exits `0` with bounded structured diagnostics. |
| Portable ZIP semantics | PASS, exit `0`: UTC wall-clock ZIP serialization/extraction, odd-second truncation to `2026-10-06T12:34:56`, same-bucket byte collision, next-bucket byte change and non-UTC rejection. |
| Deployed-content regression | PASS, exit `0`: exact API/Web path-length-SHA256, equal-size DLL/PDB mismatch, API missing/unexpected, Web Oryx/dependency bounds and BUILD_ID checks. |
| Existing artifact root/hash/prohibited-content check | PASS, exit `0`, against the retained prior application artifact only; it is not evidence for a newly packaged API timestamp. |
| Pipeline structure | PASS, exit `0`: seven stages; shared API/Web package timestamp; hash-before-timestamp; API target/outer-manifest/commit/inner-manifest preflight ordered immediately before upload; collected Ubuntu checks pinned. |
| Full package creation | PENDING CI: isolated .NET publish was reachable, but local Web dependencies were absent; the normal locked restore retry completed .NET restore with NU1900 vulnerability-source warnings and then failed `npm ci` because restricted access could not fetch `next-16.3.8.tgz`. No new package/hash is claimed. |
| Package-generation regression on retained artifact | Expected FAIL, exit `1`: the old API ZIP retains the legacy timestamp and is correctly rejected. A newly created immutable package is required. |
| Collected chain on this host | Expected overall exit `1` after all children: portable timestamp `0`, clean preflight `0`, process boundary `0`, deployed content `0`, structure `0`; Linux Web `1`, Linux API `1`, retained-old-package `1`. |
| Linux PowerShell 7 / real `rsync` | `LINUX_VERIFICATION_PENDING`; both scripts are wired into the single unprotected `ubuntu-latest` Package-stage collection. Windows simulation is not Linux proof. |
| Web build/CSP and full new-package regression | PENDING the same Ubuntu package job with restored npm dependencies and normal package creation. Existing Web timestamp/Oryx code paths were not relaxed. |
| Live staging | NOT RUN: no Azure, deployment, migration, seed, smoke, swap or other protected action occurred. |

### Developer hand-off

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_TEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_95b4099ffd220a9d6be692ae28b18e31ec8a6c92"
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
  artefacts:
    - "azure-pipelines.yml"
    - "scripts/build/AzureDemoPackageUtilities.ps1"
    - "scripts/build/Invoke-AzureDemoWebDeploymentRegressionChain.ps1"
    - "scripts/build/New-AzureDemoPackages.ps1"
    - "scripts/build/Test-AzureDemoCleanWebDeployment.ps1"
    - "scripts/build/Test-AzureDemoCleanWebDeploymentProcessBoundary.ps1"
    - "scripts/build/Test-AzureDemoDeployedContentVerification.ps1"
    - "scripts/build/Test-AzureDemoLinuxApiDeploymentTimestamp.ps1"
    - "scripts/build/Test-AzureDemoPackageGeneration.ps1"
    - "scripts/build/Test-AzureDemoPackageTimestampSemantics.ps1"
    - "scripts/build/Test-AzurePipelineStructure.ps1"
    - "scripts/deployment/AzureDemoStagingDeployment.ps1"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "Portable Windows PowerShell 5.1 preflight, timestamp, process-boundary, content and structure regressions pass."
    - "The collector ran every child and retained nonzero overall status for unavailable Linux and new-package prerequisites."
  decisions:
    - "Bind API and Web ZIP timestamps to one manifest creation instant before hashes are calculated."
    - "Treat ZIP timestamps as two-second UTC wall-clock change metadata, not a uniqueness guarantee."
    - "Place exact API target and immutable artifact preflight immediately before the unchanged upload task."
    - "Retain exact all-file API verification and unchanged bounded Web Oryx handling."
  assumptions:
    - "Metadata-aware stale copying is strongly supported but the Azure deployment-engine algorithm remains unverified."
  risks:
    - "A fresh normal CI package and real Linux rsync evidence remain required."
    - "Authorised staging must prove both API binary hashes and the complete package-derived file set after upload."
  defects:
    - "REPAIRED LOCALLY: application packaging previously assigned a deployment timestamp only to Web; API inherited fixed 1980 ZIP entry times."
  blockers: []
  approvals: []
  requested_action: "Independent Tester must run the collected Ubuntu package/deployment regression chain against a newly produced exact-commit artifact, then perform the separately authorised staging-only upload and exact API content reconciliation before Quality review."
```

READY_FOR_TEST

## Linux executable discovery and collected web-deployment regression repair

### Baseline, scope and traceability

This bounded Developer repair started from branch `fix/mtp-azure-demo-reconciliation` at exact HEAD `50b823aad66cfa14126ba2a035cde6666b028682`. The index and worktree were clean before editing. It repairs only Linux `rsync` executable discovery and the validation-only orchestration of the existing web deployment regression chain. It does not change application behaviour, package timestamp production, deployment commands, Azure resources, protected gates or production state. Nothing was committed, pushed, deployed, migrated, seeded or swapped.

```yaml
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
```

The repair is separable from the open production decisions because it changes only synthetic regressions and unprotected Ubuntu validation. The existing PowerShell/package architecture, production deployment gating and human approvals remain unchanged.

### Confirmed cause and repair

`Get-Command rsync -CommandType Application` returned both `/usr/bin/rsync` and `/bin/rsync`. The expression `& $rsync.Source ...` then used PowerShell member enumeration on the `ApplicationInfo[]`; invocation converted the resulting path array to the single command name `/usr/bin/rsync /bin/rsync`.

The regression now captures all application matches, selects `$commands[0]` as one `System.Management.Automation.ApplicationInfo`, validates its string `Path` as a non-empty leaf, and passes that single path separately from `$rsyncArguments`. The native exit code is captured immediately after each probe or real `rsync` invocation. Synthetic Linux executables prove one match, two distinct matches in PATH order, duplicate PATH entries, no match, and an executable path plus arguments containing spaces. Duplicate entries are accepted; first-match PATH precedence is authoritative.

A scoped audit found no equivalent discovery-to-path-array conversion for `pwsh`, `chmod`, `node` or `az` in the related deployment and regression scripts. Those sites use a literal command name or the single current-process path, so they were not changed.

### Collected validation chain and local evidence

`Invoke-AzureDemoWebDeploymentRegressionChain.ps1` runs the Linux timestamp, clean deployment, generated-caller boundary, deployed-content, package-generation and pipeline-structure regressions in isolated child processes. It captures each child exit immediately, reports every result, and exits `1` after collection if any child failed. The unprotected `ubuntu-latest` Package stage invokes this chain once after exact-commit package assembly and before publication; it has no `continueOnError`, and protected deployment conditions remain unchanged.

| Check | Result |
|---|---|
| Host/runtime | Windows `10.0.26200`; Windows PowerShell `5.1.26100.9444`; Node and .NET available. `pwsh`, Docker, Podman and `rsync` unavailable; WSL is not installed and `wsl --status` exits `50`. |
| PowerShell parsing | PASS under Windows PowerShell 5.1 for the changed scripts. Parsing is not Linux runtime evidence. |
| Clean deployment regression | PASS, exit `0`; timestamp/hash negative identities, four invalid targets and native exit `17` remain rejected. |
| Generated-caller/process boundary | PASS, exit `0`; assertion/native/missing/cleanup cases exit `1`, actual regression exits `0`, and the outer caller reports `LASTEXITCODE: 0`. |
| Deployed-content regression | PASS, exit `0`; equal-size/equal-time stale content, missing chunk, changed BUILD_ID, unknown platform file and packaged Oryx metadata remain negative assertions. |
| Package-generation regression | PASS, exit `0`, against a synthetic current-commit six-file package; odd second `12:34:57.987Z` rounds to ZIP time `12:34:56`, hashes and deterministic regeneration pass, and the pre-existing ignored package output is restored by matching manifest hash. |
| Pipeline structural regression | PASS, exit `0`; seven stages, one unprotected Ubuntu chain, ordered child coverage, immediate exit capture, aggregate failure and absence of `continueOnError` are pinned. |
| Collected-chain outer status on this host | EXPECTED FAIL, outer exit `1`: Linux timestamp exits `1` because the host is Windows and the pre-existing ignored package is from older commit `0989a99d871c7158eed4994c9e6ff1f7a994ab0f`; all four intervening portable checks and the later structural check still execute and report. |
| Real Linux PowerShell 7 and real `rsync` | `LINUX_VERIFICATION_PENDING`; no Linux pass is claimed. The chain is wired to the unprotected `ubuntu-latest` package-validation job using freshly generated exact-commit artifacts. |
| External/protected actions | NOT RUN: no Azure, Azure DevOps, SQL, Entra, deployment, migration, seed, smoke, swap, release or approval action occurred. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_TEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_50b823aad66cfa14126ba2a035cde6666b028682"
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
    - "scripts/build/Test-AzureDemoLinuxWebDeploymentTimestamp.ps1"
    - "scripts/build/Invoke-AzureDemoWebDeploymentRegressionChain.ps1"
    - "scripts/build/Test-AzurePipelineStructure.ps1"
    - "azure-pipelines.yml"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "Portable deployment regressions, current-commit synthetic package regression, parsing and pipeline structure pass locally."
    - "The aggregate runner reports later results after failures and preserves a nonzero outer exit."
  decisions:
    - "Select exactly the first ApplicationInfo in PATH precedence order before reading Path."
    - "Invoke executable path and arguments separately and capture every native child exit immediately."
    - "Collect all six related regressions in one unprotected Ubuntu task before returning final failure."
  assumptions: []
  risks:
    - "Real Linux PowerShell 7 and rsync execution remains mandatory before independent acceptance."
  defects:
    - "REPAIRED LOCALLY: member enumeration converted two rsync paths into one invalid command name."
  blockers: []
  approvals: []
  requested_action: "Independent Tester must run the collected chain on the exact worktree in ubuntu-latest with real PowerShell 7, real rsync and freshly generated exact-commit packages."
```

READY_FOR_TEST

## Azure demo staging clean-deployment and exact-content reconciliation

### Baseline, authority and traceability

This bounded Developer repair started from branch `fix/mtp-azure-demo-reconciliation` at exact HEAD `1b29e4e0fcce4a2f110c065d47ad9c1516944676`. The staged index was empty. Six unstaged API hostname-validation repair files were present before this continuation and were inventoried and preserved: `infra/bicep/modules/appservice.bicep`, `src/api/Infrastructure/AzureDemoInfrastructure.cs`, `src/api/appsettings.AzureDemo.json`, `tests/api.integration/GeneratedHostnameSecurityTests.cs`, `tests/api.unit/AzureDemoConfigurationTests.cs` and `tests/api.unit/AzureDemoDeploymentBoundaryTests.cs`. Nothing was reset, stashed, staged, committed or pushed.

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-01", "C-11"]
  functional_requirements: ["F-01", "F-02", "F-13", "F-14", "F-15"]
  non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-06", "NF-07", "NF-10", "NF-12", "NF-13"]
  risks: ["R-02", "R-09", "R-11"]
  assumptions: ["A-11", "A-12", "A-13", "A-18"]
  dependencies: ["D-04", "D-11"]
  issues: ["I-06", "I-08"]
  open_questions: ["Q-02", "Q-08"]
  approvals: []
```

The existing exact-package decisions authorise controlled implementation and local/isolated testing only. Azure Platform/Operations remains `PENDING_PRE_DEPLOYMENT`; this repair performed no Azure, Azure DevOps, SQL, Entra, deployment, migration, seed, swap or release action and supplies no human approval.

### Confirmed evidence and bounded hypothesis

The supplied staging evidence confirms that deployment run `20261006.4`, deployment ID `659f6671-0f06-4db8-9c8d-0f4c1d140541`, uploaded web ZIP SHA-256 `8979a864e0b09117c8fa782a02137464e4ac606c6162ba11d4ffc2dbdc4be5ee`, and build ID `3TSclGUd2A6MVo_PfhgU0` do not match the deployed build/homepage. The deployed homepage names a square-bracket chunk absent from the staging slot. The supplied Kudu trace also confirms the optimizer/manifest rsync path and partial transfer pattern. Timestamp/size collision remains a supported explanation, not a proven root cause, because the exact rsync comparison flags were not captured.

Repository inspection confirms that the deployment job downloads only `artifact: azure-demo-immutable` from `current`, then has access to the root deployment manifest and application manifest. It also confirms that an incremental `az deployment group create` already precedes API deployment; the earlier what-if is not the apply. The repair revalidates the downloaded root manifest, exact source commit, application manifest and both ZIP hashes before any deployment. It does not hard-code or mutate the supplied ZIP and does not randomise deterministic archive timestamps.

The web application has no runtime file-write or application-owned persistent-data path under the deployment directory. Durable application data remains in Azure SQL and approved Blob storage. `.next`, `server.js`, static assets and dependency payloads are deployment artefacts; platform dependency compression is non-durable. Clean deployment is therefore bounded to the exact web staging slot. No SSH deletion or broad filesystem removal was added.

### Implemented deployment and verification contract

- The web slot deploy now runs through `sc-mtp-azure-demo-dev` on the existing private-capable deployment job and invokes `az webapp deploy` with the exact subscription, resource group, web app, explicit `staging` slot, selected immutable `web.zip`, `--type zip`, `--clean true`, `--async false`, `--restart true`, `--track-status true` and a bounded timeout. A CLI version/capability preflight rejects an incompatible installation.
- The target guard rejects production and every unexpected subscription, resource group, app, slot, resource ID, resource type or generated hostname. Remote build and Oryx remain disabled.
- Native process exit is captured immediately after `az`; non-zero exit fails the task and is retained in deployment evidence. CLI acceptance or task launch cannot satisfy the gate.
- Authenticated verification obtains a task-local Microsoft Entra token through the service connection and downloads a read-only ZIP snapshot from the exact slot SCM `/api/zip/site/wwwroot/` endpoint. It enables no publishing credentials, does not log the token and removes the token variable and temporary snapshot in `finally`.
- Every non-dependency application path, length and SHA-256 is compared with the selected immutable ZIP. Missing, changed and unexpected files fail. Web verification separately requires exact `.next/BUILD_ID`, `server.js`, `.next/server`, square-bracket chunks and `.next/static`. API application files are also compared exactly.
- App Service `NodeProjectOptimizer` may compress or expand `node_modules`. Evidence therefore records the expected and deployed dependency entry counts, paths and fingerprints and labels this one category `platform-transformed-node-modules`; it never silently omits non-dependency application files. A missing dependency payload still fails.
- Deployment and content evidence publish under `condition: always()` after an attempted web deploy. Any deploy/content mismatch prevents the later smoke, release-approval and swap stages.
- Package and staging smoke checks now require `/` = 200, `/inventory/servers` = 200 and a fixed nonexistent route = 404, all with the existing signed-out Entra shell/demo marker and no generic 500 page. The CSP nonce regression includes the same 404 route.

### API configuration ordering

The existing resource-group Bicep apply is the concrete configuration step; this repair did not introduce another broad apply. The pending host repair adds the trusted production/staging resource IDs, Azure-reported default hostnames and slot name to the existing complete API app-setting definitions, and adds the seven host/origin identity settings to the existing slot-stickiness list. Existing secret references and other app settings remain in those complete definitions.

Immediately after the existing apply, and before repaired API ZIP deployment/start, the pipeline now queries the exact web/API slot identities and API slot settings. It requires the Azure-reported `AllowedHosts`, `AllowedOrigins__0`, five trusted host-identity values, remote-build-disabled value and slot-stickiness to match exactly. A failed query, missing/duplicate/unexpected selected setting, wrong value or non-sticky identity setting stops the job.

This is not deployment readiness: the unchanged Azure Platform/Operations approval is still absent. In addition, the architecture/product package says one S1 worker and requires fresh approval before scale-up, while the supplied live inventory is S2/one instance. Bicep treats the plan as `existing` and does not manage its SKU, so no capacity change is made, but Architecture and Product/PRB must reconcile this stale S1 design/cost baseline before any protected run.

### Local verification

| Check | Result |
|---|---|
| Complete .NET tests | PASS: 234/234 unit and 149/149 integration tests; NuGet vulnerability-feed retrieval emitted `NU1900` because network access is restricted. |
| Applied API configuration regression | PASS: one valid and six fail-closed settings/slot-stickiness cases. |
| Clean web deployment regression | PASS: exact artifact selection and command; four unexpected targets rejected; CLI exit 17 retained as failure. |
| Deployed-content regression | PASS: two deterministic packages with identical paths/sizes/1980 timestamps but different bytes; stale content, missing square-bracket chunk and changed build ID rejected; dependency compression recorded explicitly. |
| Pipeline structural regression | PASS: seven ordered stages, service connection, immutable guards, configuration apply/verification order, clean flags, authenticated content verification, evidence retention and later-gate ordering. |
| Smoke/source/security regressions | PASS locally: supplemental PowerShell 5.1 smoke orchestration, target resolution, native command stream/exit handling, smoke evidence and 203-file source/security boundary. |
| App Service source regressions | PASS: native-runtime positive/fail-closed cases and existing-subnet/site-slot contracts. |
| Diff hygiene | PASS: `git diff --check`; only repository line-ending conversion warnings were emitted. |
| Linux production package routes/CSP | NOT RUN and not claimed: Linux/PowerShell 7 is unavailable and the supplied run `20261006.4` ZIP is not present locally. The local ZIP has a different SHA-256/build ID and is not substitute evidence. |
| Frontend install/lint/build/audit | NOT RUN successfully and not claimed: offline npm caches are incomplete and network access is restricted. |
| Bicep compile/emitted dependency inspection | NOT RUN and not claimed: Azure CLI/Bicep is unavailable locally. |
| Actual Azure CLI compatibility/deploy/content/smoke | NOT RUN and not claimed: Azure CLI is unavailable locally and Azure action is prohibited; the protected agent preflight and independent run remain required. |

### Changed artefacts

The six pre-existing API repair files above remain changed. This continuation also changes `azure-pipelines.yml`, `scripts/build/New-AzureDemoPackages.ps1`, `scripts/build/Test-AzureDemoSmokeOrchestration.ps1`, `scripts/build/Test-AzurePipelineStructure.ps1`, `scripts/smoke/Invoke-AzureDemoSmokeTests.ps1`, `src/web/tests/production-csp-nonce.mjs` and this implementation package. It adds `scripts/build/Test-AzureDemoAppliedApiHostConfiguration.ps1`, `scripts/build/Test-AzureDemoCleanWebDeployment.ps1`, `scripts/build/Test-AzureDemoDeployedContentVerification.ps1`, `scripts/deployment/Assert-AzureDemoAppliedApiHostConfiguration.ps1`, `scripts/deployment/AzureDemoStagingDeployment.ps1`, `scripts/deployment/Invoke-AzureDemoCleanWebSlotDeployment.ps1` and `scripts/deployment/Invoke-AzureDemoSlotContentVerification.ps1`.

```yaml
handoff:
  from_agent: "developer"
  to_agent: "architect"
  state: "NEEDS_ARCHITECTURE_DECISION"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_1b29e4e0fcce4a2f110c065d47ad9c1516944676"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-01", "C-11"]
    functional_requirements: ["F-01", "F-02", "F-13", "F-14", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-06", "NF-07", "NF-10", "NF-12", "NF-13"]
    risks: ["R-02", "R-09", "R-11"]
    assumptions: ["A-11", "A-12", "A-13", "A-18"]
    dependencies: ["D-04", "D-11"]
    issues: ["I-06", "I-08"]
    open_questions: ["Q-02", "Q-08"]
    approvals: []
  artefacts:
    - "azure-pipelines.yml and the exact changed/added files listed above"
    - "local regression output; no protected Azure evidence"
  evidence:
    - "Local application, deployment, content-reconciliation, pipeline, smoke and security regressions pass as listed above."
    - "Unavailable Linux, frontend, Bicep, Azure CLI and connected Azure checks are explicitly not claimed."
  decisions:
    - "Use a supported clean ZIP deployment only for the exact web staging slot."
    - "Hash-verify every application file against the immutable ZIP and explicitly record the documented dependency transformation."
    - "Apply and validate trusted API host identity before API deployment through the existing protected Bicep sequence."
  assumptions:
    - "Timestamp/size collision remains a hypothesis until exact Kudu rsync comparison flags or equivalent proof is obtained."
  risks:
    - "Protected agent Azure CLI/Kudu behavior and exact run-package verification remain unexecuted."
    - "The live S2 plan conflicts with the approved S1 architecture/cost baseline."
  defects:
    - "REPAIRED LOCALLY: incremental web ZIP deployment could leave stale application files without exact post-deploy reconciliation."
    - "REPAIRED LOCALLY: pipeline did not prove applied trusted API host settings before repaired API start."
  blockers:
    - "Azure Platform/Operations approval remains PENDING_PRE_DEPLOYMENT."
    - "Architecture/Product/PRB must reconcile the live S2 plan with the approved S1 design and cost envelope."
    - "Independent Linux/PowerShell 7, connected dependency, Bicep and protected Azure staging evidence is outstanding."
  approvals: []
  requested_action: "Architect and Product/PRB must reconcile and approve or reject the S2 one-instance capacity drift against the S1 design/cost baseline before the independent protected staging test is authorised."
```

NEEDS_ARCHITECTURE_DECISION

## Web staging equal-timestamp content-reconciliation repair

### Baseline, scope and traceability

This bounded Developer repair started from the requested branch `fix/mtp-azure-demo-reconciliation` at exact HEAD `89bff5682b2a2bdead2e81c6b32dea120e46fe05`. The index and worktree were clean before editing, so there was no baseline difference or existing user change to reconcile. Nothing was staged, committed, pushed, deployed, migrated, seeded or swapped, and no Azure resource or setting was changed.

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-11"]
  functional_requirements: ["F-13", "F-14"]
  non_functional_requirements: ["NF-03", "NF-06", "NF-07", "NF-10", "NF-12"]
  risks: ["R-09", "R-11"]
  assumptions: ["A-11", "A-12", "A-18"]
  dependencies: ["D-04", "D-11"]
  issues: ["I-06", "I-08"]
  open_questions: ["Q-01", "Q-08"]
  approvals: []
```

Q-01 remains closed only for the existing controlled Azure demo package. This repair does not change the approved stack, authentication, tenant isolation, SQL, networking, service connections, production controls or release gates. Q-08 and connected CI, staging, protected smoke and human deployment/release decisions remain pending and unchanged.

### Evidence and cause assessment

The supplied immutable ZIP SHA-256 is `06616e5529319761161268e987a0f9f8eb09802a43510ba85e72123738154717`; this repair does not rewrite that historical evidence. Deployment `7a6f6a71-b892-494a-b09f-948ba175f3d3` reported OneDeploy success, `clean=True`, `use manifest=False`, 427 considered files, four transferred regular files and 85 obsolete deletions. Independent verification then found 66 changed application hashes, no missing files, identical expected/deployed lengths, and one additional root `oryx-manifest.toml`. The expected BUILD_ID `SyIeOuurTS_H-Clua5oW0` remained the prior deployed `Xwvb4L_dSTn4jJilCsPfY`, while `server.js`, 105 server chunks and 37 static assets matched. Every one of the 1,543 ZIP entries and the deployed stale BUILD_ID/build manifest had the same 1980 timestamp.

The confirmed failure class is a file-transfer quick-check collision: equal path, length and timestamp concealed changed bytes. The new Linux regression constructs that condition with the two observed equal-length BUILD_ID values and 65 other changed application files. When connected CI executes it, the test requires real Linux `rsync -a` and must prove that the legacy 1980 package transfers none of the 66 changed files, leaving the stale BUILD_ID, while one package-creation timestamp transfers all 67 regular files, including unchanged `server.js`, and reconciles all 66 changed hashes and BUILD_ID. This is a controlled Linux simulation of the observed mechanism, not real Azure execution, and no Linux result is claimed from the current host.

The exact private `NodeProjectOptimizer`/`parallel_rsync.sh` implementation and arguments used by deployment `7a6f6a71-b892-494a-b09f-948ba175f3d3` are not available in the cited public source. A connected staging deployment is therefore still required to prove the correction through that exact platform version. The Azure evidence strongly fits the reproduced mechanism, but this document does not claim visibility into unpublished optimizer code.

### Setting applicability and selected correction

Microsoft's App Service ZIP deployment documentation states that ZIP files are copied only when timestamps differ and that `az webapp deploy` uses the Kudu publish API: <https://learn.microsoft.com/en-us/azure/app-service/deploy-zip>. The archived classic Kudu ZIP Deploy guidance recommends `SCM_ZIPDEPLOY_DONOT_PRESERVE_FILETIME=1`: <https://github.com/projectkudu/kudu/wiki/Deploying-from-a-zip-file-or-url>. Its classic controller passes `GetZipDeployDoNotPreserveFileTime()` into ZIP extraction: <https://github.com/projectkudu/kudu/blob/master/Kudu.Services/Deployment/PushDeploymentController.cs>.

That does not establish support for this Linux OneDeploy path. Current public KuduLite source maps OneDeploy `type=zip` to `LocalZipHandler`, which calls `LocalZipFetch`; its extraction call supplies only the symlink option and contains no lookup of `GetZipDeployDoNotPreserveFileTime`: <https://github.com/Azure-App-Service/KuduLite/blob/dev/Kudu.Services/Deployment/PushDeploymentController.cs>. The setting is therefore **not supported or verified for the relevant public Linux OneDeploy/KuduLite code path** and was not added to Bicep. The pipeline structural regression pins its absence. The existing complete settings owners—`webConfiguration`, `apiConfiguration`, `webSlotConfiguration` and `apiSlotConfiguration`—and existing slot isolation/stickiness remain unchanged.

The smallest documented-path correction is at package creation. API ZIPs retain the deterministic 1980 timestamp. A web ZIP now receives one UTC package-creation timestamp, rounded to the ZIP format's two-second resolution, before its SHA-256 and manifests are calculated. Deployment preflight requires every web entry to carry that one timestamp, requires it to be within five minutes of immutable manifest `createdAtUtc`, and validates the existing manifest-bound SHA-256 before invoking OneDeploy. The ZIP is never patched after hashing, and BUILD_ID is never rewritten or specially excluded.

### Platform metadata boundary

Oryx documents `oryx-manifest.toml` as its generated build/run manifest: <https://github.com/microsoft/Oryx/blob/main/doc/configuration.md#oryx-generated-manifest-file>. KuduLite also explicitly removes a prior root `oryx-manifest.toml` before accepting a pushed artifact. Deployed-content verification therefore treats only the ordinal exact root path `oryx-manifest.toml` as separately recorded platform metadata. When present it must be exactly one non-empty file, no larger than 64 KiB, strict UTF-8 without prohibited control characters, and contain at least one bounded TOML-like assignment. Its length and SHA-256 are recorded. The immutable expected ZIP must not supply it. Any other extra path, missing application path, changed application hash or BUILD_ID mismatch still fails.

### Exact implementation files

- `azure-pipelines.yml`
- `scripts/build/AzureDemoPackageUtilities.ps1`
- `scripts/build/New-AzureDemoPackages.ps1`
- `scripts/build/Test-AzureDemoCleanWebDeployment.ps1`
- `scripts/build/Test-AzureDemoDeployedContentVerification.ps1`
- `scripts/build/Test-AzureDemoLinuxWebDeploymentTimestamp.ps1`
- `scripts/build/Test-AzureDemoPackageGeneration.ps1`
- `scripts/build/Test-AzurePipelineStructure.ps1`
- `scripts/deployment/AzureDemoStagingDeployment.ps1`
- `scripts/deployment/Invoke-AzureDemoCleanWebSlotDeployment.ps1`
- `docs/implementation/AZURE_DEMO_Implementation_Work_Package.md`

`infra/bicep/modules/appservice.bicep` was inspected but intentionally not changed because the proposed setting is not consumed by the relevant public Linux handler.

### Verification and required connected evidence

| Check | Result |
|---|---|
| Requested baseline | PASS: exact branch and HEAD; initially clean index/worktree. |
| PowerShell parsing | PASS on Windows PowerShell 5.1 for all nine changed PowerShell files. |
| Clean web deployment regression | PASS locally: fixed-1980 package rejection, manifest-correlated web timestamp acceptance, exact target and synchronous clean OneDeploy contract, and invalid target/exit evidence. |
| Generated-caller process boundary | PASS locally: assertion, native, missing-script and cleanup failures remained nonzero; real focused regression returned zero. |
| Deployed-content verification | PASS locally: exact application SHA-256, BUILD_ID, missing/changed/unknown-extra failures, dependency transformation boundary and bounded root Oryx metadata. |
| Pipeline structural contract | PASS locally: seven stages; the Linux regression is exactly once in `ubuntu-latest`; unsupported setting absence, package timestamp creation and pre-deploy validation order are pinned. |
| Source/security and whitespace | PASS locally: source-boundary scan covered 206 source/configuration files; `git diff --check` passed. No Bicep file changed, so Bicep format/build remains the existing connected IaC check. |
| Local environment | Windows `10.0.26100`; Windows PowerShell `5.1.26100.9444`; Node `v24.18.0`; .NET SDK `10.0.401`. `pwsh`, Docker, Linux `rsync`, Azure CLI and an installed WSL distribution are unavailable. |
| Linux PowerShell 7 + real rsync regression | **PENDING CONNECTED CI** on the existing `ubuntu-latest` Validate job. No Linux result is claimed locally. |
| Fresh full application package generation | **PENDING CONNECTED CI** in the existing Package job. An isolated local attempt reached API publish but could not start `next build` because the local frontend CLI/dependencies are absent; its explicitly verified generated directory was removed. Existing local package evidence belongs to another source commit and was preserved rather than overwritten. |
| Real OneDeploy/staging reconciliation | **PENDING AUTHORIZED STAGING EXECUTION**. Rebuild once, retain the new immutable web ZIP SHA-256/manifest and entry timestamp, apply unchanged complete Bicep settings before deployment, deploy only to staging, then retain deployment logs and exact downloaded-content evidence. Require expected/deployed BUILD_ID equality, zero missing/changed/unexpected application paths, bounded separately recorded root `oryx-manifest.toml`, and the original immutable ZIP hash unchanged before/after. |
| External/protected actions | NOT RUN: no Azure, Azure DevOps, SQL, Entra, deployment, migration, seed, swap, smoke, rollback or approval action occurred. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_TEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_89bff5682b2a2bdead2e81c6b32dea120e46fe05"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-11"]
    functional_requirements: ["F-13", "F-14"]
    non_functional_requirements: ["NF-03", "NF-06", "NF-07", "NF-10", "NF-12"]
    risks: ["R-09", "R-11"]
    assumptions: ["A-11", "A-12", "A-18"]
    dependencies: ["D-04", "D-11"]
    issues: ["I-06", "I-08"]
    open_questions: ["Q-01", "Q-08"]
    approvals: []
  artefacts:
    - "azure-pipelines.yml"
    - "scripts/build/AzureDemoPackageUtilities.ps1"
    - "scripts/build/New-AzureDemoPackages.ps1"
    - "scripts/build/Test-AzureDemoCleanWebDeployment.ps1"
    - "scripts/build/Test-AzureDemoDeployedContentVerification.ps1"
    - "scripts/build/Test-AzureDemoLinuxWebDeploymentTimestamp.ps1"
    - "scripts/build/Test-AzureDemoPackageGeneration.ps1"
    - "scripts/build/Test-AzurePipelineStructure.ps1"
    - "scripts/deployment/AzureDemoStagingDeployment.ps1"
    - "scripts/deployment/Invoke-AzureDemoCleanWebSlotDeployment.ps1"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "Local exact-content, deployment-preflight, process-boundary and seven-stage structural regressions pass on Windows PowerShell 5.1."
    - "Authoritative public source distinguishes classic Kudu setting support from the KuduLite Linux OneDeploy handler that does not consume it."
    - "A Linux/PowerShell 7/rsync regression is connected to ubuntu-latest and explicitly labels itself a simulation rather than Azure execution."
  decisions:
    - "Do not add SCM_ZIPDEPLOY_DONOT_PRESERVE_FILETIME because support is absent from the relevant public Linux OneDeploy extraction path."
    - "Use one manifest-correlated package-creation timestamp for immutable web ZIP entries while retaining deterministic API ZIP behavior."
    - "Record only the exact root oryx-manifest.toml as bounded platform metadata; retain exact-hash failure for all application mismatches and failure for unknown extras."
  assumptions: []
  risks:
    - "The private deployed NodeProjectOptimizer arguments are not publicly verified."
    - "The selected correction has not yet executed through connected Linux CI or the authorized staging slot."
  defects:
    - "REPAIRED LOCALLY: deterministic 1980 web ZIP timestamps permitted equal-size changed application bytes to survive timestamp-based synchronization."
  blockers: []
  approvals: []
  requested_action: "Independent Tester must retain the connected ubuntu-latest Linux/PowerShell 7/rsync and package-generation evidence, then an authorized operator must run the existing staging-only deployment and exact content verification without weakening any protected gate."
```

READY_FOR_TEST

## Focused staging-path execution and process-boundary reconciliation

### Baseline, role and traceability

This bounded Developer investigation started on `fix/mtp-azure-demo-reconciliation` at exact HEAD `17c67ebc2dce731681245dd720d5577be7d209e7`. The branch matched the supplied last-known HEAD; the index and worktree were clean. No pending uncommitted repair existed to preserve. Nothing was reset, stashed, staged, committed or pushed, and no Azure, Azure DevOps, SQL, Entra, migration, seed, deployment, swap, rollback or endpoint action was performed.

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-01", "C-11"]
  functional_requirements: ["F-01", "F-02", "F-13", "F-14", "F-15"]
  non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-06", "NF-07", "NF-10", "NF-12", "NF-13"]
  risks: ["R-02", "R-09", "R-11"]
  assumptions: ["A-11", "A-12", "A-13", "A-18"]
  dependencies: ["D-04", "D-11"]
  issues: ["I-06", "I-08"]
  open_questions: ["Q-02", "Q-08"]
  approvals: []
```

Q-01 remains closed for the approved Azure demo package scope. This change does not select a stack, change the S2 plan, apply infrastructure or alter a release decision. The existing architecture/cost reconciliation, Azure Platform/Operations approval, protected evidence and human release gates remain unchanged.

### Confirmed execution path and branch attribution

- `Validate` and `Package` run on `ubuntu-latest` after checkout for both `deployAzureDemo=false` and `deployAzureDemo=true`. `Validate` calls the applied-host regression, isolated clean-deployment process regression, deployed-content regression and pipeline structural regression. `Package` calls `New-AzureDemoPackages.ps1`, whose standalone server check exercises `/`, `/inventory/servers`, the fixed 404 route, CSP nonces and a hashed static asset before producing `web.zip` and `api.zip`.
- `PreDeploymentGate` runs only after successful packaging when `deployAzureDemo=true`, the definition is exactly `mtp-azure-demo-deploy`, and the source branch is exactly `refs/heads/release/azure-demo-v1`. It performs prerequisite inventory, runtime validation and `az deployment group what-if`; it does not apply settings.
- `MigrateAndDeploySlots` depends on the protected gate. Its existing `az deployment group create` is the approved apply mechanism. The immediately following task reads and validates the applied API staging settings before migration, seed or API start. API ZIP deployment precedes the clean web ZIP deployment; exact web and API content verification precedes staging smoke.
- `azure-pipelines.yml` is identical between release baseline `7d6ad54` and supplied HEAD `17c67eb` for the affected task and parameter paths. The direct task therefore ran for both parameter values, but the test file differed: only `17c67eb` contains the prior explicit exit repair. A supplied run cannot be attributed to that repair without its source SHA and test-file hash.

### Process-boundary correction

`Validate` now calls `Test-AzureDemoCleanWebDeploymentProcessBoundary.ps1` with `$(Build.SourceVersion)`. The regression constructs and dot-sources an Azure DevOps-style generated caller containing the normal `$LASTEXITCODE` epilogue. That caller invokes `Invoke-AzureDemoCleanWebDeploymentRegression.ps1`, which verifies the checked-out source SHA, emits the PowerShell runtime and exact test-file SHA-256, launches the existing clean-deployment regression in a separate PowerShell process, captures its exit code on the immediately following line and fails on any nonzero result.

The boundary regression proves that the real success path returns outer exit `0`, while assertion, unexpected native exit, missing script and cleanup failure fixtures each return nonzero. The real regression still proves that Azure CLI exit `17` is rejected and recorded as failure evidence. `Invoke-AzureDemoCleanWebSlotDeployment.ps1` is unchanged; no blanket `ignoreLASTEXITCODE`, `continueOnError` or error suppression was added.

### Deployment prerequisite findings

The five new API keys are `AzureDemoHostIdentity__SlotName`, `AzureDemoHostIdentity__ApiResourceId`, `AzureDemoHostIdentity__ApiDefaultHostName`, `AzureDemoHostIdentity__WebResourceId` and `AzureDemoHostIdentity__WebDefaultHostName`. `infra/bicep/modules/appservice.bicep` maps them in both the production API configuration and staging API-slot configuration from the exact site/slot resource IDs and Azure-reported `defaultHostName` properties; all five are included in `apiSlots.properties.appSettingNames`. `AllowedHosts` and `AllowedOrigins__0` use the same trusted API/web host identities and are also slot-sticky.

The protected apply is not missing: `az deployment group create` precedes `Assert-AzureDemoAppliedApiHostConfiguration.ps1`, and that applied-state assertion precedes API deployment. The earlier what-if remains a non-mutating review gate. No infrastructure command was invented or added.

The clean web wrapper selects `application/web.zip` only after root-manifest, source-commit, application-manifest and SHA-256 validation. It supplies the exact approved subscription, resource group, web app and explicit `staging` slot to synchronous `az webapp deploy --type zip --clean true`; production and every unexpected target fail closed. Content reconciliation compares every non-dependency application path, size and SHA-256, including `.next/BUILD_ID`, `server.js`, server pages/chunks and static assets. Only `node_modules/` or the documented platform-compressed `node_modules` archive names are classified as dependencies; missing dependency payload, stale application bytes, unexpected application files and missing chunks still fail.

### Verification and evidence boundary

| Check | Result |
|---|---|
| Windows PowerShell process boundary | Supplemental PASS, `5.1.26100.9444`, outer exit `0`: source SHA `17c67ebc2dce731681245dd720d5577be7d209e7`, real child exit `0`, generated-caller outer exit `0`; assertion/native/missing/cleanup outer exits were each `1`. The real regression retained expected exit-17 rejection. |
| Applied API configuration regression | Supplemental PASS, outer exit `0`: one valid and six fail-closed applied-setting/slot-stickiness cases. |
| Deployed-content regression | Supplemental PASS, outer exit `0`: exact SHA-256, deterministic timestamp/size collision, dependency compression, stale content, missing square-bracket chunk and changed build ID. |
| Pipeline/source contracts | Supplemental PASS, outer exit `0`: seven stages and 205 source/configuration files. |
| Focused API host tests | Supplemental PASS on .NET SDK `10.0.401`: 55 unit and 4 integration tests, both outer exit `0`. NuGet advisory retrieval remained unavailable (`NU1900`), so no vulnerability-clean claim is made. |
| Linux PowerShell 7 focused sequence | ARRANGED, NOT YET EVIDENCED: the existing unprotected `Validate` job runs the real process-boundary, applied-configuration and content regressions on `ubuntu-latest`; the `IaC` job compiles Bicep and both parameter files; `Package` builds and starts the standalone production web package and exercises the required routes/CSP. |
| Local Linux/Bicep | UNAVAILABLE: `pwsh`, Docker, an installed WSL distribution, `az` and `bicep` are absent. Windows results are not Linux proof. |
| Live staging content and health | NOT RUN: clean deployment and exact content verification remain unproved against live Azure. |

### Ordered protected staging procedure and blockers

1. Run `Validate`, `IaC` and `Package` on one reviewed exact source SHA; retain the emitted runtime/test hash/child and outer exit diagnostics, Bicep compilation, immutable artifact manifest and standalone route/CSP results.
2. Obtain the unchanged architecture/Product decision for the live S2 plan, Azure Platform/Operations pre-deployment approval and all existing protected environment/service-connection prerequisites. Confirm durable SQL bootstrap evidence and reviewed migration/seed prerequisites before authorising the protected run.
3. Queue only `mtp-azure-demo-deploy` from `release/azure-demo-v1` with `deployAzureDemo=true`. Review the protected prerequisite inventory and Bicep what-if; do not treat what-if as apply.
4. Allow the existing reviewed `az deployment group create` to apply the complete Bicep configuration. Require the subsequent applied-state preflight to match the exact staging resource IDs, generated hostnames, host/origin settings, remote-build setting and slot stickiness before any API start.
5. Revalidate this run's immutable artifact, then execute the separately governed SQL checkpoint/migration/seed steps. Deploy the API ZIP to `staging`, clean-deploy the current run's selected immutable web ZIP to `staging`, and publish deployment evidence even on failure.
6. Require exact deployed-content reconciliation for both web and API, then resolve exact staging smoke targets and exercise health plus `/`, `/inventory/servers`, fixed 404 and CSP behavior. Stop on any mismatch; do not proceed to release approval or swap.
7. Keep protected smoke evidence ingestion and first-release SMK-19 rollback evidence as separate release requirements. Even healthy staging does not satisfy them and does not authorise production swap.

Application-health blockers are the unexecuted Linux/PowerShell 7, Bicep compile, immutable package server, live applied-setting/content and protected staging smoke evidence. Production-release blockers remain the separate protected evidence-delivery decision, genuine previous-release/SMK-19 rollback evidence, independent Tester and Quality records, and named human release approval.

```yaml
handoff:
  from_agent: "developer"
  to_agent: "architect"
  state: "NEEDS_ARCHITECTURE_DECISION"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_17c67ebc2dce731681245dd720d5577be7d209e7"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-01", "C-11"]
    functional_requirements: ["F-01", "F-02", "F-13", "F-14", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-06", "NF-07", "NF-10", "NF-12", "NF-13"]
    risks: ["R-02", "R-09", "R-11"]
    assumptions: ["A-11", "A-12", "A-13", "A-18"]
    dependencies: ["D-04", "D-11"]
    issues: ["I-06", "I-08"]
    open_questions: ["Q-02", "Q-08"]
    approvals: []
  artefacts:
    - "azure-pipelines.yml"
    - "scripts/build/Invoke-AzureDemoCleanWebDeploymentRegression.ps1"
    - "scripts/build/Test-AzureDemoCleanWebDeployment.ps1"
    - "scripts/build/Test-AzureDemoCleanWebDeploymentProcessBoundary.ps1"
    - "scripts/build/Test-AzurePipelineStructure.ps1"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "Focused supplemental Windows process/configuration/content/source and API host tests pass with recorded outer exits."
    - "Required Linux validation, Bicep compilation and production standalone route/CSP checks are pinned to existing unprotected ubuntu-latest jobs but have not yet run on this worktree."
  decisions:
    - "Isolate the clean deployment regression in its own PowerShell process and test the complete generated caller boundary."
    - "Use the existing protected Bicep apply and applied-state preflight; do not add an infrastructure deployment path."
    - "Keep application-health evidence separate from protected production-release evidence."
  assumptions: []
  risks:
    - "No Linux/PowerShell 7, Bicep compilation or live Azure content evidence exists for this uncommitted worktree."
    - "The live S2 plan remains unchanged and still requires the recorded architecture/Product reconciliation."
  defects:
    - "REPAIRED LOCALLY: the validation task shared native process state with a regression that deliberately exercised Azure CLI exit 17."
  blockers:
    - "Architecture/Product and Azure Platform/Operations decisions remain pending for a protected staging attempt."
    - "Protected smoke ingestion and genuine first-release rollback evidence remain separate unresolved release blockers."
  approvals: []
  requested_action: "Run the exact changed SHA through the existing unprotected Linux Validate/IaC/Package jobs, then obtain the unchanged architecture and platform decisions before any protected staging attempt."
```

NEEDS_ARCHITECTURE_DECISION

## Staging smoke orchestration execution and diagnostic repair

### Baseline, role, scope and traceability

This bounded Developer repair started on branch `fix/mtp-azure-demo-reconciliation` at the requested release commit `580e725e43c8b9bf835fe07714ad85d4507e294d`. Before editing, `HEAD` matched that commit and its configured upstream, the staged and unstaged indexes were empty, and there were no untracked files. Nothing was reset, stashed, staged, committed, pushed, deployed or changed in Azure. The work is confined to smoke orchestration, safe diagnostic/result handling, local fixture regression, failure-artifact publication conditions and supporting records. It does not change application behavior, tenant/identity controls, evidence acceptance requirements, release approvals, migrations, seed, slots or infrastructure.

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-11"]
  functional_requirements: ["F-13", "F-14", "F-15"]
  non_functional_requirements: ["NF-03", "NF-06", "NF-07", "NF-10", "NF-12", "NF-13"]
  risks: ["R-09", "R-11"]
  assumptions: ["A-11", "A-12", "A-18"]
  dependencies: ["D-04", "D-11"]
  issues: ["I-06", "I-08"]
  open_questions: ["Q-01", "Q-08"]
  approvals: []
```

This regression repair is separable from Q-01 and Q-08: it selects no technology stack, changes no service commitment and does not supply or accept protected runtime evidence. The existing evidence-ingestion, operational-producer, real previous-release SMK-19 and human release decisions remain blocking.

### Confirmed root causes and before-repair reproduction

A controlled full-runner reproduction used the exact production orchestration and smoke functions with deterministic response objects at the `Invoke-WebRequest` boundary. It reproduced the reported shape exactly: 22 results, eight automated/hybrid checks recorded as generic `check-execution` failures (`SMK-01`, `02`, `03`, `08`, `10`, `11`, `12`, `20`), SMK-01 incorrectly reported the HTTPS base URI, and the final aggregate throw occurred only after all result files and the summary were written. This reproduction was Windows PowerShell 5.1 control-flow evidence, not Linux or live-endpoint evidence.

Four independent defects were confirmed:

1. `Write-SafeRequestDiagnostic` used `Write-Output` inside both checked-request wrappers. Its diagnostic text and the returned response object therefore became a two-item success-pipeline array. Strict-mode property access in SMK-01, 03, 08, 10, 11 and 12 then failed instead of evaluating the retained HTTP response.
2. SMK-02 assigned the web-root result to `$home`. PowerShell variable names are case-insensitive, so this attempted to overwrite the read-only automatic `$HOME` variable and raised `VariableNotWritable` after the first request.
3. SMK-10 left an empty `Where-Object` pipeline as null and then accessed `.Count` under strict mode. The CORS assertion therefore raised `PropertyNotFoundStrict` when the expected result was no CORS grant.
4. SMK-20 parsed npm lockfile v3 into a `PSCustomObject`. The valid empty `packages[""]` key is not a valid object-property name for that conversion path, so JSON conversion raised before dependency assertions. PowerShell 7 `-AsHashtable` parsing is required for that document shape.

The aggregate throw at the former line 293 was not a root cause. The old SMK-01 HTTPS diagnostic was produced by the generic catch from `$WebBaseUri`, not proof of the URI actually requested. No HTTP 503, DNS result or live application-health conclusion can be derived from that failed run.

### Implemented repair

- Diagnostic logging now uses the information stream, so it cannot alter HTTP return values. All internal calls use named parameters.
- Diagnostics contain only check ID, phase, actual safe scheme/host/path, available status, bounded exception type/category, sanitized error identifier and repository script basename/line when available. Query strings, headers, cookies, tokens, bodies, raw messages and unrestricted objects remain excluded.
- Each check accumulates its real HTTP diagnostics. A later assertion, evidence rejection or harness exception no longer replaces an observed HTTP status with an unavailable transport result.
- Results now retain separate `failureCategories`: `application-response-failure`, `transport-failure`, `assertion-failure`, `harness-exception`, `missing-evidence` and `rejected-evidence`.
- SMK-01 records the actual HTTP attempt and still permits only 301/302/307/308 to HTTPS on the exact host/default port/path with no userinfo, query or fragment. Redirect following remains disabled.
- SMK-02 uses `$homeResponse`; SMK-10 materializes the no-grant collection; SMK-20 uses PowerShell 7 hashtable JSON parsing and checks dictionary shapes before reading exact versions.
- Header retrieval now handles case-insensitive dictionary keys plus scalar and enumerable values without strict-mode property assumptions.
- Both protected pipeline callers create their evidence directory before invocation. Both publication steps use `and(always(), attempt-marker)` so a smoke failure does not skip sanitized evidence publication; the smoke error is not caught or replaced.
- `Test-AzureDemoSmokeOrchestration.ps1` drives the complete production runner through real loopback HTTP fixtures and verifies redirect, 2xx, 404, 503, abrupt close, assertion after valid 200 responses, missing/rejected evidence, continued collection, redaction and all 22 result files plus summary before the final failure. Fixtures are explicitly synthetic and cannot satisfy protected release evidence.

### Per-check disposition supported by current evidence

| Checks | Before-repair category | Confirmed disposition |
|---|---|---|
| SMK-01 | Harness exception hidden as unavailable transport; displayed scheme was wrong | Orchestration defect repaired; live redirect outcome remains unknown. The current caller still lacks mandatory protected lower-TLS evidence. |
| SMK-02 | Harness exception | `$HOME` collision repaired; live health/home/deep-route outcomes remain unknown. |
| SMK-03 | Harness exception | Success-stream contamination repaired; live root/asset outcomes remain unknown. |
| SMK-08 | Harness exception | Success-stream contamination repaired; protected header/redaction evidence remains absent from the pipeline. |
| SMK-10 | Harness exception | Null-count and contaminated-response paths repaired; live CORS/proxy outcome remains unknown. |
| SMK-11 | Harness exception | Contaminated-response/header handling repaired; live web/API header outcome remains unknown. |
| SMK-12 | Harness exception | Contaminated response is now retained separately; protected outage/alert evidence remains absent. |
| SMK-20 | Harness exception | Lockfile empty-key parsing repaired for PowerShell 7; exact deployed-artifact/config evidence still requires its approved producer. |
| SMK-04, 05, 06, 07, 09, 13-19, 21, 22 | No HTTP diagnostic in the reported excerpt | The exact pipeline caller supplies no `-ProtectedEvidenceDirectory`, so these 14 evidence-only checks deterministically remain `missing-evidence`; this is not inferred as a transport or application failure. |

After repair, SMK-01, 08 and 12 also remain release-blocking as `missing-evidence` unless and until their independently approved protected records are supplied. Therefore at least 17 checks remain intentionally red under the current pipeline even if all five automation-only checks succeed.

### Changed files

- `azure-pipelines.yml`
- `docs/implementation/AZURE_DEMO_Implementation_Work_Package.md`
- `scripts/build/Test-AzureDemoSmokeHttp.ps1`
- `scripts/build/Test-AzureDemoSmokeOrchestration.ps1`
- `scripts/build/Test-AzurePipelineStructure.ps1`
- `scripts/smoke/AzureDemoSmokeUtilities.ps1`
- `scripts/smoke/Invoke-AzureDemoSmokeTests.ps1`
- `scripts/smoke/README.md`
- `tests/api.unit/AzureDemoDeploymentBoundaryTests.cs`

`AzureDemoSmokeEvidenceContract.ps1` and `Resolve-AzureDemoSmokeTargets.ps1` were inspected but did not require source changes. Their fail-closed evidence and exact-target contracts remain in force.

### Verification and remaining blockers

Local Windows PowerShell parsing, evidence-contract, target-resolution, pipeline-structure, source-boundary and focused deployment-boundary tests pass. The after-repair complete runner uses real loopback HTTP fixtures, retains the real HTTP diagnostics, passes SMK-02/03/10/11 with deterministic successful responses, distinguishes abrupt-close transport and post-200 assertion failures, continues through SMK-22 and writes all records plus the summary before the expected aggregate failure. SMK-20 deliberately reports its PowerShell 7 runtime requirement under Windows PowerShell 5.1; 4xx/5xx response normalization and SMK-20 are deferred to the Linux run. This supplemental execution is not Linux proof.

| Verification | Runtime | Exit/result |
|---|---|---|
| Parse seven changed/relevant PowerShell files | Windows PowerShell `5.1.26100.9444` | `0`; zero parser errors. Supplemental only. |
| `Test-AzureDemoSmokeEvidence.ps1` | Windows PowerShell `5.1.26100.9444` | `0`; valid and retained fail-closed evidence cases passed. |
| `Test-AzureDemoSmokeTargetResolution.ps1` | Windows PowerShell `5.1.26100.9444` | `0`; 12 invalid resolver cases rejected. |
| `Test-AzurePipelineStructure.ps1` | Windows PowerShell `5.1.26100.9444` | `0`; seven ordered stages and both failure-publication conditions passed. |
| `Test-AzureDemoSourceBoundaries.ps1` | Windows PowerShell `5.1.26100.9444` | `0`; 196 source/configuration files passed. |
| `Test-AzureDemoSmokeOrchestration.ps1` supplemental subset | Windows PowerShell `5.1.26100.9444` | `0`; real loopback redirect, successful response, transport, assertion, evidence, continuation, redaction and publication fixtures passed. 4xx/5xx and SMK-20 were explicitly not claimed. |
| Focused `AzureDemoDeploymentBoundaryTests` | .NET `10.0`, Windows | `0`; 13/13 passed. |
| Full solution test | .NET `10.0`, Windows | `0`; unit 209/209 and integration 148/148 passed. NuGet vulnerability metadata remained unavailable and emitted `NU1900`; no dependency changed. |
| Focused `dotnet format --verify-no-changes` | .NET `10.0`, Windows | `0`; workspace-load warning only. |
| `git diff --check` | Git/Windows | `0`; line-ending notices only. |
| `where.exe pwsh` | Windows host | `1`; no PowerShell 7 executable found. |
| `Test-AzureDemoSmokeHttp.ps1` and complete `Test-AzureDemoSmokeOrchestration.ps1` | Required Linux PowerShell 7 | **NOT RUN / `LINUX_VERIFICATION_PENDING`**; both are wired once into `ubuntu-latest`. |

PowerShell 7, WSL and Docker are unavailable on the authorized host. Consequently the new complete real-HTTP orchestration regression and the existing HTTP-helper regression remain `LINUX_VERIFICATION_PENDING`; Windows parsing, response-object substitution and mocks are not presented as Linux execution evidence. They are each wired exactly once into the `ubuntu-latest` validation job. No protected pipeline, staging endpoint or Azure operation was invoked.

The protected evidence-ingestion decision described in `AZURE_DEMO_Smoke_Evidence_Coverage.md`, the named producer identities and permissions, the real prior deployment record/manifest for SMK-19, independent Tester review and all human gates remain unresolved. A rerun of the protected staging task is required to determine actual application/transport results for the repaired automation-only checks; diagnostics alone do not establish application health.

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_TEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_580e725e43c8b9bf835fe07714ad85d4507e294d"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-11"]
    functional_requirements: ["F-13", "F-14", "F-15"]
    non_functional_requirements: ["NF-03", "NF-06", "NF-07", "NF-10", "NF-12", "NF-13"]
    risks: ["R-09", "R-11"]
    assumptions: ["A-11", "A-12", "A-18"]
    dependencies: ["D-04", "D-11"]
    issues: ["I-06", "I-08"]
    open_questions: ["Q-01", "Q-08"]
  artefacts:
    - "scripts/smoke/Invoke-AzureDemoSmokeTests.ps1"
    - "scripts/smoke/AzureDemoSmokeUtilities.ps1"
    - "scripts/build/Test-AzureDemoSmokeOrchestration.ps1"
    - "azure-pipelines.yml"
  evidence:
    - "Before-repair full-runner reproduction matched the eight reported generic execution failures."
    - "After-repair controlled orchestration retains actual status/scheme, continues all 22 checks and publishes failure evidence."
    - "Locally available focused contracts and deployment-boundary tests pass."
  decisions:
    - "Keep diagnostics off the success stream and preserve the original HTTP result through later phases."
    - "Keep application, transport, assertion, harness and evidence failures distinct."
    - "Retain every protected evidence and release block."
  assumptions: []
  risks:
    - "Complete Linux PowerShell 7 fixture execution remains pending."
    - "Live endpoint health remains unknown until the protected staging task is rerun."
  defects:
    - "REPAIRED LOCALLY: success-stream diagnostic contamination."
    - "REPAIRED LOCALLY: SMK-02 read-only HOME variable collision."
    - "REPAIRED LOCALLY: SMK-10 strict-mode null Count access."
    - "REPAIRED LOCALLY: SMK-20 npm lockfile empty-key object conversion."
  blockers:
    - "Independent Linux/PowerShell 7 execution of both HTTP suites."
    - "Approved protected evidence ingestion and producers for 17 protected/hybrid checks."
    - "Real previous-release evidence and approval source for SMK-19."
  approvals: []
  requested_action: "Independent Tester must run the two PowerShell 7 HTTP suites in Linux validation, then rerun the protected staging smoke task and review the retained per-check evidence without waiving the existing protected-evidence blockers."
```

READY_FOR_TEST

## Azure CLI App Service slot-show command repair

### Baseline, scope and traceability

This bounded Developer repair started from the requested branch `fix/mtp-azure-demo-reconciliation` at exact HEAD `0502523181afde81412f857e1be97f379f650c42`. The index and worktree were clean before editing. Nothing was staged, committed, pushed, reset or stashed. The repair changes only the two protected smoke-target resolver callers, their native Azure CLI capture, focused/structural regressions and supporting documentation. It does not change RBAC, host validation, release gates, swaps, Azure state or smoke acceptance.

```yaml
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
```

This local pipeline-command repair is separable from Q-01 and Q-08: it does not select an application stack, change the operating model or alter any approval. Connected Azure validation and all existing human gates remain in force.

### Confirmed command defect and correction

Both protected Azure CLI tasks used the unsupported argument sequence `az webapp deployment slot show` for each staging-slot lookup. The four corrected callers are:

- staging resolver: web staging slot;
- staging resolver: API staging slot;
- pre-swap resolver: web staging slot;
- pre-swap resolver: API staging slot.

Each now executes `az webapp show` with the existing exact subscription, resource group, application, `--slot staging`, resource projection, JSON output and `--only-show-errors` arguments. The four production lookups remain `az webapp show` without `--slot`. The valid API-first/web-second `az webapp deployment slot swap` commands are unchanged.

Both `Invoke-AzJson` helpers now send native stdout only to the `Json` result, redirect stderr to a unique temporary file, capture `$LASTEXITCODE` on the immediately following statement and remove the file in `finally`. The public `Json`/`ExitCode` result contract is unchanged. A nonzero result emits only a bounded operation (`account-show`, `webapp-show` or `unknown`), integer exit code and allowlisted error category; raw stderr is not printed. `Resolve-AzureDemoSmokeTargets.ps1` is unchanged and still fails closed on the exact subscription, tenant, resource group, app, slot, resource ID, resource type and generated default hostname.

### Regression and verification

`Test-AzureDemoPipelineSmokeTargetCommands.ps1` extracts both real inline pipeline scripts, substitutes only their pipeline variables and executes each caller against a native recording `az` stub. It proves the exact web/API staging and production arrays, rejects the invalid sequence, verifies success JSON remains parseable when native stderr is present, and verifies native exit `17` with valid stdout still fails closed. The failure fixture includes unrestricted marker text in stderr and proves only `operation=webapp-show`, `exitCode=17` and `errorCategory=authorization` reach diagnostics. It also checks that helper stderr files are removed.

| Check | Result |
|---|---|
| Baseline and inventory | PASS before editing: exact requested branch/HEAD, clean worktree and empty staged index. |
| PowerShell parsing | PASS: the new caller regression, structural regression and unchanged resolver parse under Windows PowerShell 5.1. |
| Actual pipeline caller/native-stub regression | PASS, exit `0`: both callers retained exact arguments; stdout/stderr remained separate; native nonzero failed closed with bounded diagnostics; temporary stderr was removed. |
| Smoke-target resolver regression | PASS, exit `0`: generated hosts, exact identities, staging/production separation, unsafe URI rejection, catalogue order and 12 invalid cases. |
| Pipeline structural regression | PASS, exit `0`: seven ordered stages; four supported slot lookups; four production lookups without `--slot`; no invalid lookup; swap commands retained. |
| Focused .NET deployment-boundary tests | PASS, exit `0`: 13 passed, 0 failed, 0 skipped. NuGet emitted `NU1900` because external vulnerability metadata was unreachable; no connected vulnerability-audit success is claimed. |
| PowerShell 7/Linux | NOT RUN: `pwsh` is unavailable on the authorized local host. The pipeline pins this regression to `ubuntu-latest`, where it remains to be executed. |
| Live Azure/same-service-connection proof | NOT RUN: no Azure mutation or query was authorized. The repository still binds both resolver tasks to `sc-mtp-azure-demo-dev`; a protected run must prove that identity can read both production sites and both staging slots with the corrected command. |
| External/protected actions | NOT RUN: no Azure, Azure DevOps, SQL, Entra, deployment, migration, seed, swap, smoke endpoint, rollback or approval action occurred. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_TEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_0502523181afde81412f857e1be97f379f650c42"
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
    - "azure-pipelines.yml"
    - "scripts/build/Test-AzureDemoPipelineSmokeTargetCommands.ps1"
    - "scripts/build/Test-AzurePipelineStructure.ps1"
    - "scripts/smoke/README.md"
    - "tests/api.unit/AzureDemoDeploymentBoundaryTests.cs"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "Both actual inline callers pass the native recording-stub command and stream-separation regression."
    - "Resolver, structural and focused deployment-boundary regressions pass locally."
  decisions:
    - "Use the supported webapp show command for both sites and slots, adding --slot only for staging."
    - "Keep native stderr out of JSON and emit only bounded operation/exit/category diagnostics."
    - "Retain the resolver's existing exact identity and generated-hostname validation unchanged."
  assumptions: []
  risks:
    - "PowerShell 7/Linux and connected same-service-connection reads remain unverified locally."
  defects:
    - "REPAIRED LOCALLY: all four staging-slot lookups used unsupported az webapp deployment slot show arguments."
  blockers: []
  approvals: []
  requested_action: "Independent Tester must run the new caller regression and protected pipeline validation on Linux/PowerShell 7, then verify sc-mtp-azure-demo-dev can read the exact production and staging resources without exposing stderr."
```

READY_FOR_TEST

## Smoke evidence workflow reconciliation and fail-closed contract

### Baseline, role and authority

This Developer continuation began from branch `fix/mtp-azure-demo-reconciliation`, exact HEAD `e20410c008d1ebc67f6148cab4760fc9037cbb6c`, an empty staged index and the ten requested hostname/HTTP repair paths already present in the worktree. Those ten paths were preserved and extended; none was discarded, reset, staged or recreated from baseline. No additional pre-existing or unexpected worktree path was found.

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-11"]
  functional_requirements: ["F-13", "F-14", "F-15"]
  non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-04", "NF-05", "NF-06", "NF-07", "NF-10", "NF-11", "NF-12", "NF-13"]
  risks: ["R-02", "R-09", "R-11"]
  assumptions: ["A-11", "A-12", "A-18"]
  dependencies: ["D-04", "D-11"]
  issues: ["I-06", "I-08"]
  open_questions: ["Q-08"]
  approvals: []
```

The approved architecture authorises staging-first implementation and evidence enforcement, but does not identify a protected same-run ingestion mechanism for interactive browser, specialist, fault-injection, alert and rehearsal results. This implementation therefore strengthens local validation and ordering without inventing a Secure File, artifact resource, pipeline ID, service connection, previous release, approval or external store. The exact proposed amendment is `docs/implementation/AZURE_DEMO_Smoke_Evidence_Coverage.md`; it is explicitly unapproved.

### Confirmed dependency and delivery defect

The pipeline used the job-local SQL bootstrap directory as `AZDEMO_SMOKE_PREREQUISITE_EVIDENCE`. That directory contained only `sql-bootstrap.json`, while the runner required 17 distinct `SMK-xx.json` records. The SQL file's reusable grant-provenance contract cannot prove a release-specific smoke assertion. The `Swap` job downloaded the SQL Secure File only because smoke was pointed at the wrong directory; it had no migration/SQL-bootstrap consumer.

The correct non-circular order is staging deployment, staging runtime execution, immutable failed/success evidence publication, independent Tester/Quality review of actual results, full human release gate, swap, then post-swap verification. A post-swap result cannot authorise the swap that created it. SMK-19 is a separate protected rehearsal input to the release gate and must refer to the real previously deployed release, not the current build.

### Implemented work

- Renamed the database-only job variable to `AZDEMO_SQL_BOOTSTRAP_EVIDENCE_DIRECTORY`; only `DatabaseAndSlots` downloads and validates `sql-bootstrap.json`. `Swap` no longer downloads it, and no smoke invocation receives it.
- Captured the exact infrastructure deployment ID and bound smoke output to the Azure DevOps definition/run. The runner also validates the deployment manifest schema and exact source commit before execution.
- Added `AzureDemoSmokeEvidenceContract.ps1`. A protected record must contain all acceptance-derived assertions for its check, exact commit/manifest/deployment/run/target/slot/host provenance, the required execution perspective and identity kind, UTC interval/correlation, and hash-verified sanitized attachments. A bare PASS, fixture evidence or substituted origin fails.
- Preserved exactly 17 protected/hybrid checks. SMK-04 requires an outside-private-network perspective; SMK-05 requires the Sweden managed pool/private identities; SMK-06 requires an assigned-user browser; SMK-13 requires separated runtime/migration identities.
- SMK-19 additionally requires a distinct previous source commit, previous deployment-manifest file/hash, protected deployment reference and rehearsal approval reference. Current-release substitution is rejected. No previous release was guessed.
- Added local evidence-contract tests for valid records and missing, malformed, wrong-commit, wrong-artifact, substituted-target, wrong-run/origin, fixture, missing-assertion, attachment-hash and current-as-previous failures. The regression uses temporary synthetic fixtures only and never publishes them as release evidence.
- Extended safe read-only runner automation: SMK-02 checks health/home/deep responses; SMK-03 checks hash-like asset, MIME and immutable public caching; SMK-10 checks origin/method/header denials plus same-origin route reachability; SMK-11 checks exact web and private-API headers; SMK-20 checks the exact patched lock plus source/manifest prohibited paths.
- Retained all 22 result records and summary publication after an attempted failed run. Until the protected ingestion decision is approved, the YAML intentionally supplies no `-ProtectedEvidenceDirectory`, so missing protected evidence blocks the release gate.
- Added the exact 22-row coverage/ownership/input/reviewer/staging-production matrix and the minimal unapproved work-package/ADR decision.

### SMK-19 finding

The repository and local Git refs do not prove what release is deployed in the production slots. `release/azure-demo-v1`, the current artifact, current smoke results and current deployment manifest are not rollback-target evidence. Platform/Operations must provide the prior protected deployment record, its source commit, immutable deployment-manifest file/hash, compatibility decision and rehearsal change/approval reference. No swap or rehearsal was performed and the requirement was not waived.

### Exact changed files

The original ten-file repair set remains:

- `azure-pipelines.yml`
- `docs/implementation/AZURE_DEMO_Implementation_Work_Package.md`
- `scripts/build/Test-AzurePipelineStructure.ps1`
- `scripts/build/Test-AzureDemoSmokeHttp.ps1`
- `scripts/build/Test-AzureDemoSmokeTargetResolution.ps1`
- `scripts/smoke/AzureDemoSmokeUtilities.ps1`
- `scripts/smoke/Invoke-AzureDemoSmokeTests.ps1`
- `scripts/smoke/README.md`
- `scripts/smoke/Resolve-AzureDemoSmokeTargets.ps1`
- `tests/api.unit/AzureDemoDeploymentBoundaryTests.cs`

This continuation adds exactly three new paths:

- `docs/implementation/AZURE_DEMO_Smoke_Evidence_Coverage.md`
- `scripts/build/Test-AzureDemoSmokeEvidence.ps1`
- `scripts/smoke/AzureDemoSmokeEvidenceContract.ps1`

### Local verification

| Check | Result |
|---|---|
| Baseline/index | PASS: branch and HEAD matched the request; staged index remained empty. |
| PowerShell parsing | PASS: five evidence/runner/target/pipeline PowerShell files parsed with zero errors under Windows PowerShell 5.1. This is not PowerShell 7/Linux runtime evidence. |
| Evidence contract | PASS: valid protected-runtime and previous-release fixtures; missing, malformed, wrong commit/artifact, substituted target, wrong origin, fixture, assertion, attachment and current-release substitution rejected. |
| Exact smoke targets | PASS: four generated App Service host shapes and 12 invalid resolver/URI/slot/substitution cases. |
| Pipeline structure | PASS: seven ordered stages, database-only SQL input, deployment-before-staging-tests, tests-before-review/gate, gate-before-swap, API-first swap, post-swap verification and failed-evidence publication. |
| Focused deployment boundary | PASS: 12/12. |
| Full .NET unit suite | PASS: 208/208. |
| Full .NET integration suite | PASS: 145/145. |
| Source/security boundary | PASS across 193 source/configuration files. |
| Rollback safeguards | PASS: one valid and 12 fail-closed cases. This is structural guard evidence, not SMK-19 rehearsal evidence. |
| Formatting/diff | PASS: focused `dotnet format --verify-no-changes` and `git diff --check`; only Git line-ending notices were emitted. |
| Linux HTTP regression | UNAVAILABLE locally and not passed: `pwsh` is absent. `Test-AzureDemoSmokeHttp.ps1` and the new evidence test are each wired once into `ubuntu-latest` validation. |
| Protected/live tests | NOT RUN: no Azure, Azure DevOps, SQL, Entra, endpoints, deployment, migration, seed, fault, test alert, staging, swap or rehearsal action occurred. No smoke PASS or approval was created. |

NuGet vulnerability metadata was unavailable during `dotnet test` and emitted `NU1900`; no restore or dependency change occurred.

### Remaining decision and operator inputs

TDA, Test Services, Information Security, Azure DevOps/repository ownership and Azure Platform/Operations must approve a concrete protected same-run evidence ingestion route, producer identities/permissions, artifact/check name and retention, browser submission method, independent review ordering, post-swap read-only subset and SMK-19 previous-release source. The operator must then supply the actual infrastructure deployment ID, Azure DevOps run, exact resolved targets, assigned-user/role context, authorised invalid-token fixtures, approved fault/alert/rehearsal changes and the real previous deployment record/manifest as applicable. Missing values remain blocking.

The separately reported web staging degraded health was neither diagnosed nor changed by this repair. Hostname resolution and evidence validation do not establish application health.

```yaml
handoff:
  from_agent: "developer"
  to_agent: "architect"
  state: "NEEDS_ARCHITECTURE_DECISION"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_e20410c008d1ebc67f6148cab4760fc9037cbb6c"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-11"]
    functional_requirements: ["F-13", "F-14", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-04", "NF-05", "NF-06", "NF-07", "NF-10", "NF-11", "NF-12", "NF-13"]
    risks: ["R-02", "R-09", "R-11"]
    assumptions: ["A-11", "A-12", "A-18"]
    dependencies: ["D-04", "D-11"]
    issues: ["I-06", "I-08"]
    open_questions: ["Q-08"]
  artefacts:
    - "docs/implementation/AZURE_DEMO_Smoke_Evidence_Coverage.md"
    - "scripts/smoke/AzureDemoSmokeEvidenceContract.ps1"
    - "scripts/build/Test-AzureDemoSmokeEvidence.ps1"
    - "scripts/smoke/Invoke-AzureDemoSmokeTests.ps1"
    - "azure-pipelines.yml"
  evidence:
    - "Local evidence, target, pipeline, source, rollback, boundary, unit and integration regressions passed."
    - "PowerShell 7/Linux HTTP and every protected live assertion remain explicitly unexecuted."
  decisions:
    - "SQL bootstrap input is separate from smoke evidence and is consumed only before migration."
    - "Missing protected evidence remains a release-blocking failure; no delivery source is inferred."
    - "Post-swap evidence cannot authorise the same swap."
    - "SMK-19 requires the real distinct previous deployment and manifest."
  assumptions: []
  risks:
    - "No approved protected evidence ingestion mechanism exists."
    - "The staging application independently reports degraded health."
  defects:
    - "REPAIRED LOCALLY: SQL bootstrap input was incorrectly presented as the smoke prerequisite directory."
    - "REPAIRED LOCALLY: smoke evidence validation accepted an under-specified PASS-only contract."
  blockers:
    - "Architecture/governance decision for protected same-run evidence ingestion and reviewer ordering."
    - "Actual live evidence for all mandatory checks and the real SMK-19 previous release."
  approvals: []
  requested_action: "Architect/TDA and named control owners must decide the minimal evidence-ingestion amendment; after approval, Developer may wire only that mechanism and Tester must execute/review the protected suite before any release gate or swap."
```

NEEDS_ARCHITECTURE_DECISION

## PowerShell 7 HTTP redirect regression repair

### Baseline, authority and traceability

This bounded Developer repair started on the requested branch `fix/mtp-azure-demo-reconciliation` at exact HEAD `6881b1da10be389f938fec5bcf7a10eddcfc8eba`. The tracked, staged and untracked worktree was clean before editing. Nothing was reset, stashed, staged, committed or pushed. The repair is confined to the local HTTP smoke helper, its real loopback fixture regression and this implementation record. It does not change product scope, tenant/identity controls, CSP, generated-hostname behavior, Bicep, evidence contracts, release gates or any protected action.

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-11"]
  functional_requirements: ["F-13", "F-14"]
  non_functional_requirements: ["NF-03", "NF-06", "NF-07", "NF-10", "NF-12"]
  risks: ["R-09", "R-11"]
  assumptions: ["A-11", "A-12", "A-18"]
  dependencies: ["D-04", "D-11"]
  issues: ["I-06", "I-08"]
  open_questions: ["Q-01", "Q-08"]
  approvals: []
```

Q-01 remains closed only for the controlled package scope already recorded in this document. Q-08 and the existing protected evidence, SMK-19, staging, release and human-approval blockers remain unchanged. This local test/helper correction is separable from those gates.

### Confirmed cause and evidence

The failing assertion is the first redirect iteration in `Test-AzureDemoSmokeHttp.ps1`: the real loopback fixture returns HTTP 301 with `Location: https://127.0.0.1/fixture`, then `Invoke-FixtureRequest` calls `Invoke-AzureDemoSmokeHttpRequest`. The fixture-ready file is written only after the listener has successfully bound, and the request helper waits for the fixture process to exit successfully before returning. The reported failure therefore occurred after readiness, request acceptance and clean fixture exit; it was not a startup, binding or readiness failure.

PowerShell 7's web-cmdlet implementation processes the response first and then emits the non-terminating `MaximumRedirectExceeded` error when `MaximumRedirection` is zero and the status is a redirect. `SkipHttpErrorCheck` correctly preserves ordinary HTTP error responses. The helper nevertheless specified `-ErrorAction Stop`, promoting the redirect-limit error before the assignment retained the already-written response. The catch path handled only a runtime variant whose exception exposes a `Response` property. For the `MaximumRedirectExceeded` `InvalidOperationException`, no response property exists, so status remained null and the valid 301 was returned as `TransportSucceeded = false`. The assertion then reported only that PowerShell had not preserved the response.

This is runtime/version-dependent web-cmdlet pipeline behavior, not redirect following and not a valid HTTP response becoming a network failure. The CI excerpt did not include its PowerShell version or the discarded result shape. The repaired regression now emits those safe values on every local fixture so a future failure identifies the actual runtime, returned wrapper type, raw response type, status, bounded exception type and bounded category without emitting headers, cookies, tokens, query strings, response bodies or exception messages.

### Bounded implementation

- `Invoke-AzureDemoSmokeHttpRequest` keeps `MaximumRedirection 0` and `SkipHttpErrorCheck`, captures success-pipeline output separately from the redirect-limit error, and accepts the response only when there is exactly one HTTP-shaped result and either no error or only `MaximumRedirectExceeded` for a 3xx response.
- The existing exception-response compatibility path remains for PowerShell variants that retain the original 3xx on an exception. It walks inner exceptions but still requires the response and `Location` header; a status alone cannot pass redirect validation.
- Multiple or non-HTTP pipeline objects fail closed as `unexpected-output`. HTTP responses remain distinct from DNS, TLS, connection, timeout and other transport failures. The nested exception classifier now recognizes TLS and timeout causes as well as socket categories.
- `Test-AzureDemoSmokeHttp.ps1` still exercises the real loopback listener for 301, 302, 307, 308, 200, 500, cross-host rejection and abrupt close. Exact HTTPS scheme, host, default port and path validation is unchanged. No redirect is followed and certificate validation is not disabled.
- Fixture readiness now also fails immediately if the child exits before binding. Normal completion uses the timeout result directly; forced cleanup kills, waits for exit and disposes the process. Synthetic authorization, cookie and query secrets are supplied only to the abrupt-close test, and both structured and assertion diagnostics prove they are absent.

### Exact changed files

- `scripts/smoke/AzureDemoSmokeUtilities.ps1`
- `scripts/build/Test-AzureDemoSmokeHttp.ps1`
- `docs/implementation/AZURE_DEMO_Implementation_Work_Package.md`

No CSP, generated-hostname, Bicep, protected-evidence or release-gate file was changed.

### Verification

| Check | Result |
|---|---|
| Baseline and preservation | PASS: requested branch and exact HEAD confirmed; initial tracked/staged/untracked state clean; no Git state mutation. |
| PowerShell parsing | PASS, exit `0`: both changed scripts parsed with zero errors under Windows PowerShell 5.1. This is syntax evidence only. |
| Smoke target resolution | PASS, exit `0`: generated-host, exact-identity, staging/production, unsafe URI and catalogue-order cases; 12 invalid resolver cases rejected. |
| Smoke evidence contract | PASS, exit `0`: valid synthetic protected-runtime/previous-release contracts and all existing fail-closed substitution cases. This is not protected evidence. |
| Pipeline structure | PASS, exit `0`: seven ordered stages retained. |
| Source/security boundary | PASS, exit `0`: 194 source/configuration files. |
| Focused deployment boundary | PASS, exit `0`: 13/13. NuGet advisory lookup emitted existing `NU1900` warnings because the connected service index was unavailable; no restore or dependency change occurred. |
| Supplemental pipeline-shape check | PASS, exit `0`: a local injected response-plus-`MaximumRedirectExceeded` shape retained status 301 and exact destination; multiple output failed closed. This supports the control-flow repair but is not claimed as real PowerShell 7/Linux HTTP evidence. |
| Supplemental nested exception classification | PASS, exit `0`: synthetic connection-refused, TLS and timeout exception chains produced distinct bounded categories. This is classifier evidence, not a live network test. |
| Real PowerShell 7/Linux HTTP fixture | UNAVAILABLE locally and not passed: `pwsh`, Docker and Podman are absent; `wsl.exe --status` exits `50` because WSL is not installed. The Windows PowerShell guard ran and correctly exited `1`. CI must run the real 301/302/307/308, 200/500, cross-host, abrupt-close, redaction, readiness and cleanup fixtures. |
| Preliminary supplemental attempts | NOT EVIDENCE: the first ad-hoc dot-source attempt was blocked by local execution policy; two transport simulations under Windows PowerShell 5.1 wrapped the injected exception as `RuntimeException` and were rejected. The process-scope policy was then bounded to the test process, and only the final passing supplemental checks above are cited. |
| External/protected actions | NOT RUN: no Azure, Azure DevOps, SQL, Entra, endpoint, deployment, migration, seed, smoke, swap, rollback or approval action occurred. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_TEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_6881b1da10be389f938fec5bcf7a10eddcfc8eba"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-11"]
    functional_requirements: ["F-13", "F-14"]
    non_functional_requirements: ["NF-03", "NF-06", "NF-07", "NF-10", "NF-12"]
    risks: ["R-09", "R-11"]
    assumptions: ["A-11", "A-12", "A-18"]
    dependencies: ["D-04", "D-11"]
    issues: ["I-06", "I-08"]
    open_questions: ["Q-01", "Q-08"]
    approvals: []
  artefacts:
    - "scripts/smoke/AzureDemoSmokeUtilities.ps1"
    - "scripts/build/Test-AzureDemoSmokeHttp.ps1"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "All locally available focused smoke, source, pipeline, boundary, parser and supplemental control-flow checks passed."
    - "Real PowerShell 7/Linux loopback HTTP execution remains explicitly unavailable and unclaimed."
  decisions:
    - "Capture the one original response before handling PowerShell's separate redirect-limit error."
    - "Retain no-follow and exact redirect-destination validation; fail closed on ambiguous pipeline output."
    - "Expose only bounded runtime/type/status/category diagnostics."
  assumptions: []
  risks:
    - "The changed path still requires independent execution on the ubuntu-latest PowerShell 7 agent."
    - "Existing protected smoke-evidence and SMK-19 blockers remain unresolved and unchanged."
  defects:
    - "REPAIRED LOCALLY: ErrorAction Stop discarded PowerShell 7's already-written no-follow redirect response before assignment."
  blockers:
    - "PowerShell 7/Linux execution is unavailable in the local environment."
    - "Existing protected smoke-evidence delivery and real SMK-19 previous-release evidence remain absent."
  approvals: []
  requested_action: "Independent Tester must run Test-AzureDemoSmokeHttp.ps1 on the ubuntu-latest PowerShell 7 agent and retain its safe per-fixture diagnostics before the unchanged downstream gates proceed."
```

READY_FOR_TEST

## Azure demo smoke target resolution and safe diagnostics repair

### Baseline, authority and traceability

The Developer repair started from the exact requested baseline: branch `fix/mtp-azure-demo-reconciliation`, commit `e20410c008d1ebc67f6148cab4760fc9037cbb6c`, clean worktree and empty staged index. It remains within approved work item `AZURE-DEMO-001` and the deployment architecture's staging-first, exact-resource, commit/artifact-bound smoke contract. The work is separable from Q-08 service acceptance and does not change application capability, migrations, schema, seed, startup, network rules, identities, service connections, deployment defaults or approval policy. No Azure, Azure DevOps, SQL or deployed endpoint was accessed.

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-11"]
  functional_requirements: ["F-13", "F-14"]
  non_functional_requirements: ["NF-03", "NF-06", "NF-07", "NF-10", "NF-12"]
  risks: ["R-09", "R-11"]
  assumptions: ["A-11", "A-12", "A-18"]
  dependencies: ["D-04", "D-11"]
  issues: ["I-06", "I-08"]
  open_questions: ["Q-01", "Q-08"]
  approvals: []
```

### Confirmed defects and prerequisite-evidence findings

The staging and production callers constructed legacy hostnames from application names. The real staging `defaultHostName` includes an Azure-generated uniqueness token and regional stamp, so the caller and the runner's two-entry legacy hostname allowlist rejected the exact deployed slot. The generic request catch then reduced every request failure to the path `/`, concealing check ID, destination host, status and failure category.

Both protected deployment jobs populate `AZDEMO_SMOKE_PREREQUISITE_EVIDENCE` with a job-local directory containing only `sql-bootstrap.json`. No pipeline step, artifact download or Secure File supplies any `SMK-xx.json`. Under the current invocation, the runner requires protected evidence for `SMK-01`, `SMK-04`, `SMK-05`, `SMK-06`, `SMK-07`, `SMK-08`, `SMK-09`, `SMK-12`, `SMK-13`, `SMK-14`, `SMK-15`, `SMK-16`, `SMK-17`, `SMK-18`, `SMK-19`, `SMK-21` and `SMK-22`. SQL bootstrap evidence is not any of those contracts: it has a different filename, schema, provenance purpose and validation rule. No file was copied, renamed, fabricated or treated as PASS. The protected staging run must therefore remain red until an independently approved commit/artifact-bound producer and delivery route exists.

Repository inspection found no rollback smoke caller. The rollback stage validates the requested release/target and swaps web then API back, but it has neither a previous-release deployment manifest nor previous-release `SMK-xx.json` evidence with which to bind a truthful post-rollback smoke record. Reusing the current build manifest would violate commit/artifact binding. This repair does not fabricate that missing release-evidence contract and does not add an unbound rollback smoke claim.

### Bounded implementation

`Resolve-AzureDemoSmokeTargets.ps1` receives captured Azure CLI account/site/slot responses and their exit codes. It rejects nonzero commands, empty or malformed/non-object JSON, the wrong subscription or tenant, the wrong resource group/app/slot/type/ID, malformed host-only values, and hostnames that do not belong to the exact resolved app/slot shape. It supports both legacy App Service default names and Azure-generated uniqueness-token/regional-stamp names without hardcoding the observed suffix. The two deployment jobs query the production site and `staging` slot for both web and API with explicit `--subscription`, using only the existing general deployment service connection `sc-mtp-azure-demo-dev`. Production targets resolve before the API-first/web-second swap. Staging smoke remains before ReleaseApproval, so any staging smoke failure blocks swap.

The smoke runner binds the URI to the resolver's exact verified host and to the fixed approved subscription, resource group, web/API names and production/staging identity. It rejects HTTP for the HTTPS base URI, userinfo, query strings, fragments, unexpected ports, cross-slot hosts and arbitrary `azurewebsites.net` names. Every derived request is checked against the exact host before dispatch.

`SMK-01` still sends HTTP and calls PowerShell 7 `Invoke-WebRequest` with `MaximumRedirection 0` and `SkipHttpErrorCheck`. Normal 3xx returns and the PowerShell variant that exposes a retained 3xx response through an exception are normalized. Only 301, 302, 307 or 308 to HTTPS on the same exact host, default port and path passes; transport failure, 200, 500, cross-host redirect, userinfo, query and fragment do not. Hybrid `SMK-01`, `SMK-08` and `SMK-12` now require their protected evidence as well as the automated check.

Request evidence contains only check ID, scheme, hostname, path, available HTTP status and a bounded exception category. It excludes request headers, tokens, cookies, query strings, response bodies and unrestricted exception messages. The runner completes all 22 catalogue entries in fixed order, writes each record and `smoke-summary.json`, then fails with check IDs only. Attempt-marker conditions publish staging or production evidence after a failed attempted run. The original SQL evidence remains job-local and is still removed by the existing `always()` cleanup.

### Verification

| Check | Result |
|---|---|
| PowerShell parsing | PASS: all six changed/new PowerShell scripts parsed with zero errors under Windows PowerShell 5.1. Parsing is not PowerShell 7 runtime evidence. |
| Exact smoke target regression | PASS, exit `0`: Azure-generated production/staging hosts for web/API, including the reported web staging host shape; exact staging/production separation; approved catalogue order; and 12 wrong-subscription/group/app/slot, malformed, substituted, scheme, userinfo, port and arbitrary-host cases. |
| Pipeline structural regression | PASS, exit `0`: seven ordered stages; exact-subscription Azure CLI lookup through `sc-mtp-azure-demo-dev`; resolver-before-swap; staging-smoke-before-approval; API-first/web-second swap; resolved staging/production hosts; attempted-failure evidence publication; existing SQL evidence cleanup and rollback controls. |
| Rollback safeguards | PASS, exit `0`: one valid and 12 fail-closed rollback target cases. This validates the existing guard, not a post-rollback smoke run. |
| Focused deployment boundary | PASS as part of rebuilt full suite; resolver/caller/evidence-publication assertions increased the class to 12 tests. |
| Full API unit suite | PASS after rebuild, exit `0`: 208/208. Build emitted `NU1900` because connected NuGet vulnerability metadata was unavailable. |
| Application artifact | PASS, exit `0`: hash, root-layout and prohibited-file checks. |
| Immutable seed/deployment artifact | PASS, exit `0`: package publication, complete hash manifest, protected execution, reset, idempotency and fail-closed path/content checks against the unchanged 1,803-file local fixture. No artifact was regenerated. |
| Package/hash generation regression | PASS, exit `0`: repository boundary, ZIP, exact-file manifest, SHA-256 and deterministic-generation checks for the unchanged 1,803-file local fixture. |
| Source/security boundary | PASS, exit `0`: 191 source/configuration files. |
| Focused formatting | PASS, exit `0`: `dotnet format ... --verify-no-changes --no-restore --include tests/api.unit/AzureDemoDeploymentBoundaryTests.cs`; workspace-load warnings only. PowerShell parsing and the pipeline trailing-whitespace structural gate also passed; PSScriptAnalyzer is not installed locally. |
| Diff hygiene | PASS: `git diff --check`; line-ending conversion warnings only. |
| Real PowerShell 7 HTTP fixtures | UNAVAILABLE locally and not claimed: only Windows PowerShell 5.1 is installed; `pwsh` and Docker are absent and WSL is not installed. `Test-AzureDemoSmokeHttp.ps1` is wired once into the `ubuntu-latest` validation job and must pass its 301/302/307/308, 200/500, cross-host, abrupt-close and redaction fixtures. |
| Protected runtime | NOT RUN: no Azure/Azure DevOps/SQL access; no deployment, migration, seed, live smoke, swap or rollback. `sql-bootstrap.json` was not accessed or regenerated. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_TEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_e20410c008d1ebc67f6148cab4760fc9037cbb6c"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-11"]
    functional_requirements: ["F-13", "F-14"]
    non_functional_requirements: ["NF-03", "NF-06", "NF-07", "NF-10", "NF-12"]
    risks: ["R-09", "R-11"]
    assumptions: ["A-11", "A-12", "A-18"]
    dependencies: ["D-04", "D-11"]
    issues: ["I-06", "I-08"]
    open_questions: ["Q-01", "Q-08"]
    approvals: []
  artefacts:
    - "azure-pipelines.yml"
    - "scripts/smoke/AzureDemoSmokeUtilities.ps1"
    - "scripts/smoke/Resolve-AzureDemoSmokeTargets.ps1"
    - "scripts/smoke/Invoke-AzureDemoSmokeTests.ps1"
    - "scripts/smoke/README.md"
    - "scripts/build/Test-AzureDemoSmokeTargetResolution.ps1"
    - "scripts/build/Test-AzureDemoSmokeHttp.ps1"
    - "scripts/build/Test-AzurePipelineStructure.ps1"
    - "tests/api.unit/AzureDemoDeploymentBoundaryTests.cs"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "All locally available exact-target, pipeline, rollback, deployment-boundary, unit, artifact, source, formatting and diff checks passed."
    - "PowerShell 7 fixture execution and connected protected runtime checks remain outstanding and are not claimed."
  decisions:
    - "Resolve App Service defaultHostName from exact Azure resource identities; never construct or wildcard-allow smoke hosts."
    - "Retain all 22 sanitized records before failing a smoke run."
    - "Fail closed on missing SMK evidence and preserve commit/artifact binding rather than reuse SQL bootstrap or current-release evidence."
  assumptions: []
  risks:
    - "The protected pipeline cannot pass until an approved producer/delivery contract supplies all 17 currently required SMK-xx.json files."
    - "No truthful post-rollback smoke binding exists until the prior release manifest and its prerequisite evidence are delivered to the rollback job."
  defects:
    - "REPAIRED LOCALLY: constructed legacy smoke hostnames, legacy-only allowlists, unsafe generic request diagnostics, incomplete hybrid-evidence enforcement and success-only smoke evidence publication."
  blockers:
    - "Real PowerShell 7 HTTP fixture validation has not run in this Windows-only environment."
    - "Protected SMK prerequisite evidence delivery is absent."
    - "Rollback post-swap smoke artifact/evidence binding is absent."
  approvals: []
  requested_action: "Independent Tester must run Linux validation, review the missing SMK/rollback evidence contracts, and only then execute the protected exact-resource staging smoke flow under the existing human-controlled gates."
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

## Production CSP nonce and API_ORIGIN configuration repairs

### Baseline, scope and traceability

This Developer continuation started from branch `fix/mtp-azure-demo-reconciliation`, exact HEAD `e20410c008d1ebc67f6148cab4760fc9037cbb6c`, an empty staged index and exactly 16 pre-existing changed paths: the preserved 13-path smoke repair plus the three-path production CSP nonce repair (`scripts/build/New-AzureDemoPackages.ps1`, `src/web/app/layout.tsx` and `src/web/tests/production-csp-nonce.mjs`). No existing path was reset, stashed, discarded, staged, committed or pushed. This continuation changes only the App Service module, the existing deployment-boundary test file and this implementation record. It does not alter the CSP implementation, authentication, identity, networking, SQL, seed, migration, protected smoke evidence, release gates or approvals.

```yaml
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
```

The exact-package decisions already recorded at the start of this work package close Q-01 only for this controlled implementation and local/isolated test scope. Q-08, protected evidence ingestion, real SMK-19 previous-release evidence, connected CI and every human release/deployment decision remain unchanged and blocking where previously stated.

### Confirmed API_ORIGIN defect and bounded implementation

The production web setting constructed `https://${apiAppName}.azurewebsites.net`, and the staging web slot constructed `https://${apiAppName}-${stagingSlotName}.azurewebsites.net`. These values do not represent Azure-generated `defaultHostName` values containing uniqueness and regional components.

Production `API_ORIGIN` now uses `https://${api.properties.defaultHostName}` from the exact existing production API resource. Staging `API_ORIGIN` now uses `https://${apiSlot.properties.defaultHostName}` from the exact API staging-slot resource. Both retain the `https://` scheme, and `API_ORIGIN` remains in the web application's `slotConfigNames.appSettingNames` list so production and staging values remain deployment-slot settings through swap.

The staging property reference creates an implicit `apiSlot` dependency for `webSlot`. The resulting relevant order is: resolve the existing plan/web/API resources; deploy/update `apiSlot`; then deploy/update `webSlot` with the resolved API-slot hostname. Production `webConfiguration` reads the existing `api` resource property and does not require API-slot creation. `apiSlot` has no symbolic reference back to `webSlot`—its current web-origin value remains name-constructed—so the repair introduces no circular dependency. Textual declaration order is not deployment order in Bicep.

Repository inspection found four adjacent legacy constructions in the same module: production/staging API `AllowedHosts` from `apiAppName`, and production/staging API `AllowedOrigins__0` from `webAppName`. They are not `API_ORIGIN`, and their runtime impact was not supplied or approved for this bounded repair. They are reported for separate assessment and remain unchanged; no observed generated hostname is hard-coded.

The focused regression isolates the production web configuration, staging web-slot resource and web slot-setting resource. It proves the two exact resource-property mappings occur once each in the correct scope, rejects cross-mapping, verifies `API_ORIGIN` slot stickiness and rejects both old constructed `API_ORIGIN` expressions.

### Verification

| Check | Result |
|---|---|
| Exact baseline and inventory | PASS before editing: expected branch and HEAD; exactly 16 changed paths (8 modified, 8 untracked); empty staged index. |
| Focused API_ORIGIN regression | PASS, exit `0`: 1/1 mapping, scope, stickiness and legacy-rejection test. Build emitted only `NU1900` because connected NuGet vulnerability metadata is unavailable. |
| Deployment-boundary regression | PASS, exit `0`: 13/13. |
| Full API unit suite | PASS, exit `0`: 209/209 after rebuilding the deployment-boundary assembly. |
| Pipeline structural regression | PASS, exit `0`: seven ordered stages retained. |
| App Service subnet regression | PASS, exit `0`: four site/slot integrations and the existing-subnet contract retained; accepted/rejected inventory and compiled shapes passed. |
| Smoke target resolution | PASS, exit `0`: generated-host/exact-identity/staging-production cases and 12 invalid cases passed. |
| Smoke evidence contract | PASS, exit `0`: valid protected-runtime/previous-release fixtures and all fail-closed substitutions passed. This is local synthetic contract evidence, not protected SMK evidence. |
| Source/security boundary | PASS, exit `0`: 194 source/configuration files. |
| Focused formatting | Initial `dotnet format --verify-no-changes` exited `1` on the new test's range-expression wrapping. After correcting that formatting, the exact rerun passed with exit `0`; workspace-load warnings only. |
| Diff hygiene | PASS, exit `0`: `git diff --check`; Git emitted only existing LF/CRLF conversion notices. |
| Bicep CLI/version | UNAVAILABLE, exit `1`: `az bicep version` could not run because `az` is not installed or on `PATH`. |
| Bicep compilation | UNAVAILABLE, exit `1`: `az bicep build --file infra/bicep/main.bicep --outfile .codex-temp/api-origin-main.json` could not run for the same missing-tool reason. No compiled-template pass is claimed. |
| External/protected actions | NOT RUN: no Azure, Azure DevOps, SQL, endpoint, deployment, migration, seed, smoke, swap, rollback or approval action occurred. |

Connected CI must run the pinned Bicep compile/parameter regressions and the preserved PowerShell 7/Linux production-CSP and smoke suites. Under the existing human-controlled flow, protected what-if must show only the intended web/site-slot application-setting dependency/update, staging must verify its resolved `API_ORIGIN` equals `https://` plus the exact API-slot `defaultHostName`, production must verify the corresponding production API hostname, and protected staging smoke must pass before any release decision or swap. The existing protected smoke-evidence delivery and SMK-19 blockers remain in force.

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_TEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_e20410c008d1ebc67f6148cab4760fc9037cbb6c"
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
    - "infra/bicep/modules/appservice.bicep"
    - "tests/api.unit/AzureDemoDeploymentBoundaryTests.cs"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "All locally available API_ORIGIN, boundary, pipeline, subnet, smoke-target, smoke-evidence and source/security regressions passed."
    - "Bicep compilation and every connected/protected verification remain explicitly unavailable or unexecuted."
  decisions:
    - "Bind web API_ORIGIN values to the exact API site/slot defaultHostName resource properties."
    - "Retain API_ORIGIN as a deployment-slot setting."
    - "Report adjacent legacy hostname construction without broadening this repair."
  assumptions: []
  risks:
    - "Pinned Bicep compilation and connected staging/production setting verification remain mandatory."
    - "The existing smoke-evidence ingestion and real previous-release blockers remain unresolved."
  defects:
    - "REPAIRED LOCALLY: web API_ORIGIN settings constructed legacy App Service hostnames instead of using Azure-reported defaultHostName properties."
  blockers:
    - "Local Bicep CLI is unavailable."
    - "Protected smoke-evidence delivery and real SMK-19 previous-release evidence remain absent."
  approvals: []
  requested_action: "Independent Tester must compile the Bicep with the pinned connected-CI toolchain, inspect the dependency graph/template, and verify both exact resolved API_ORIGIN values in staging/production before the existing protected smoke and release gates can proceed."
```

READY_FOR_TEST

## Generated-hostname allowlist assessment and repair

### Baseline, scope and traceability

This bounded Developer continuation started from the requested branch `fix/mtp-azure-demo-reconciliation` and exact HEAD `e20410c008d1ebc67f6148cab4760fc9037cbb6c`. Before editing, the worktree contained exactly 17 changed paths (9 modified and 8 untracked), including the smoke-evidence, production CSP nonce and `API_ORIGIN` repairs. Every pre-existing path was inventoried and preserved. Nothing was reset, stashed, discarded, staged, committed or pushed.

```yaml
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
```

Q-01 remains closed only for the controlled package scope already recorded in this document. This repair does not change an approval, release state, identity design, network boundary, smoke-evidence requirement or protected action. Q-08 and all existing connected-CI, staging, protected smoke, SMK-19 and human release blockers remain explicit.

### Runtime trace and findings

`AllowedHosts` is consumed by ASP.NET Core host filtering from the root configuration key. It compares the HTTP `Host` value before the endpoint executes and returns HTTP 400 for an unlisted host. The AzureDemo forwarded-header policy processes only `X-Forwarded-For` and `X-Forwarded-Proto`, with a forward limit of two; it does not process `X-Forwarded-Host`. The API proxy also removes caller-supplied `Forwarded`, `X-Forwarded-For`, `X-Forwarded-Host` and `X-Forwarded-Proto`. Consequently, `X-Forwarded-Host` cannot replace `Request.Host` or bypass the exact host allowlist.

`AllowedOrigins` is read eagerly by `Program.cs` and supplied to the named `Web` CORS policy through `WithOrigins`. For an allowed browser origin the middleware returns `Access-Control-Allow-Origin`; for an unrelated origin it withholds that header, so the browser denies cross-origin response access. CORS does not ordinarily reject or authorise a server-to-server request, and a response without an `Origin` request header is not subject to browser CORS enforcement.

The normal request route remains:

1. The browser calls the web application's same-origin `/api/...` route.
2. The Next.js route validates the method, path and body size, removes prohibited forwarding/identity headers and forwards only the narrow approved header set.
3. Server-side `fetch` targets `API_ORIGIN` plus `/api/...`; the target URL supplies the API `Host`. The browser does not make this API hop, and the proxy does not forward an `Origin` header, so CORS does not govern it.
4. The API host filter validates the exact API hostname before CORS, authentication and authorisation continue. Authentication, project-derived authorisation and all existing API controls remain unchanged.

The four reported legacy values were confirmed configuration defects. Name construction from `apiAppName`, `webAppName` and `stagingSlotName` is not guaranteed to equal Azure's authoritative generated `defaultHostName`. A mismatch in `AllowedHosts` rejects the normal Next.js-to-API request with HTTP 400. A mismatch in `AllowedOrigins__0` does not break that server-side proxy route, but it makes the exact browser CORS allowlist wrong for any permitted direct cross-origin browser request from the deployed web host.

The already repaired `API_ORIGIN` settings were functionally correct and were left unchanged: production is `https://${api.properties.defaultHostName}`, staging is `https://${apiSlot.properties.defaultHostName}`, and `API_ORIGIN` remains slot-sticky. The CORS policy, allowed methods/headers, authentication, authorisation, forwarded-header selection/limit, local development configuration and API slot-stickiness list were also left unchanged. No wildcard, hard-coded generated hostname or weaker check was introduced.

### Exact mapping, dependency order and ownership

The resulting exact mappings are:

| Environment | Web `API_ORIGIN` | API `AllowedHosts` | API `AllowedOrigins__0` |
|---|---|---|---|
| Production | `https://${api.properties.defaultHostName}` | `api.properties.defaultHostName` | `https://${web.properties.defaultHostName}` |
| Staging | `https://${apiSlot.properties.defaultHostName}` | `apiSlot.properties.defaultHostName` | `https://${webSlot.properties.defaultHostName}` |

Production web and API configurations reference only the two existing production site resources. For staging, `webSlot` and `apiSlot` are created independently and contain no symbolic reference to each other. `webSlotConfiguration` depends on its `webSlot` parent and reads `apiSlot.properties.defaultHostName`; `apiSlotConfiguration` depends on its `apiSlot` parent and reads `webSlot.properties.defaultHostName`. Neither configuration references the other configuration, so there is no self-reference or circular dependency. Connected Bicep compilation remains required to independently inspect the emitted `dependsOn` graph.

There are exactly four app-settings writers: production web `webConfiguration`, production API `apiConfiguration`, staging web `webSlotConfiguration`, and staging API `apiSlotConfiguration`. Each owns its complete environment-specific app-settings payload. The slot resources no longer embed a second app-settings payload. The two common arrays and every environment-specific setting name are retained; the only hostname-value changes are the four confirmed allowlist repairs plus the pre-existing two `API_ORIGIN` repairs. The setting-name inventory is unchanged apart from the two new child configuration resources themselves being named `web`. `API_ORIGIN`, `AllowedHosts` and `AllowedOrigins__0` remain in their existing `slotConfigNames` lists.

### Changed files for this continuation

- `infra/bicep/modules/appservice.bicep`: maps all six host/origin values to authoritative resource properties and separates both staging app-settings payloads into single child-configuration writers.
- `tests/api.unit/AzureDemoDeploymentBoundaryTests.cs`: verifies exact production/staging mappings, rejects all six legacy constructions, proves configuration ownership/stickiness and statically excludes direct cross-slot creation dependencies.
- `tests/api.integration/GeneratedHostnameSecurityTests.cs`: exercises real ASP.NET Core host filtering and CORS behavior for generated production/staging hostnames, unrelated hosts/origins and forwarded-host bypass attempts.
- `docs/implementation/AZURE_DEMO_Implementation_Work_Package.md`: records this bounded assessment, implementation and evidence without changing approvals.

The final worktree therefore contains the original 17 changed paths plus the new integration-test path, for 18 changed paths in total.

### Verification

| Check | Result |
|---|---|
| Baseline and preservation | PASS before editing: exact requested branch/HEAD; 17 changed paths (9 modified, 8 untracked); every path retained; no Git mutation beyond working-file edits. |
| Release build | PASS, exit `0`: `dotnet build LgrTransformationMigration.sln --configuration Release --no-restore`; 0 errors and four `NU1900` warnings because connected NuGet advisory metadata is unavailable. |
| Generated-host runtime regression | PASS, exit `0`: 3/3. Both exact environment hosts returned 200, the other environment's host returned 400, both exact origins received their own CORS allow header, unrelated origins received none, and `X-Forwarded-Host` could not bypass an unrelated `Host`. |
| Focused Bicep mapping/ownership regression | PASS, exit `0`: 1/1 after the final mapping and complete-setting assertions. |
| Full API unit suite | PASS, exit `0`: 209/209. |
| Full API integration suite | PASS, exit `0`: 148/148. |
| App Service subnet regression | PASS, exit `0`: one exact inventory and two compiled fixture shapes accepted; 24 invalid inventory and 8 invalid compiled-shape cases rejected; exactly four site/slot integration assignments retained. This fixture test is not compilation of the changed template. |
| Pipeline structure | PASS, exit `0`: seven ordered stages retained. |
| Smoke target resolution | PASS, exit `0`: generated-host, exact-identity, staging/production and 12 invalid resolver cases passed. |
| Smoke evidence contract | PASS, exit `0`: valid local synthetic fixtures and all fail-closed substitutions passed. This does not supply protected or previous-release evidence. |
| Source/security boundary | PASS, exit `0`: 194 source/configuration files. |
| Focused formatting | PASS, exit `0`: `dotnet format ... --verify-no-changes` for both changed C# tests; workspace-load warnings only. |
| Initial test-authoring feedback | The first integration invocation exited `1` because the new file omitted `System.Net`; the next exited `1` because a late test configuration source could not affect eagerly constructed CORS options. Both test-only defects were corrected, and the exact final 3/3 run passed. The first subnet reruns also exited `1` while the configuration split temporarily duplicated, then removed the wrong, subnet assignments; the final exact regression passed after restoring the original four owners. |
| Production CSP nonce regression | UNAVAILABLE and not passed locally: `node src/web/tests/production-csp-nonce.mjs` exited `1` at its required-base-URL usage guard because no deployed endpoint is available or permitted. No CSP source was changed by this continuation. |
| Frontend Vitest/build | UNAVAILABLE and not passed: `src/web/node_modules/.bin/vitest.cmd` and `next.cmd` are absent; no dependency install or connected registry access was attempted. |
| Bicep CLI and compilation | UNAVAILABLE and not passed: neither `bicep` nor `az` is installed or on `PATH`. The current Bicep was not compiled, and static/source assertions are not represented as compilation evidence. |
| External/protected actions | NOT RUN: no Azure, Azure DevOps, SQL, Entra, endpoint, deployment, migration, seed, smoke, swap, rollback or approval action occurred. |

Connected CI must compile and lint the changed Bicep with the pinned toolchain, compile both parameter files, and inspect the emitted dependencies to confirm both slots precede both slot configurations with no configuration-to-configuration cycle. It must run the preserved complete application, frontend, PowerShell 7/Linux, dependency/vulnerability and source checks. Protected what-if must show only the intended configuration updates and no competing app-settings writer. Staging must verify the exact reported web/API slot `defaultHostName` values against `API_ORIGIN`, `AllowedHosts` and `AllowedOrigins__0`, then exercise web-to-API readiness and the host/CORS negative cases. Production mappings require the corresponding protected verification before any release decision. The existing protected smoke-evidence ingestion and real SMK-19 previous-release blockers remain unresolved and unchanged.

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_TEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_e20410c008d1ebc67f6148cab4760fc9037cbb6c"
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
    - "infra/bicep/modules/appservice.bicep"
    - "tests/api.unit/AzureDemoDeploymentBoundaryTests.cs"
    - "tests/api.integration/GeneratedHostnameSecurityTests.cs"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "Locally available build, runtime host/CORS, mapping/ownership, full unit/integration, subnet, pipeline, smoke-contract, source-boundary and formatting checks pass."
    - "Bicep compilation, frontend execution and all connected/protected checks remain explicitly unavailable or unexecuted."
  decisions:
    - "Use each Azure site/slot defaultHostName as the single authority for API host, web origin and server-side API origin mappings."
    - "Create both staging slots before writing either complete slot configuration so cross-slot hostname reads cannot create a slot creation cycle."
    - "Retain exact allowlists, deployment-slot settings and all existing authentication, authorisation, CORS and forwarded-header controls."
  assumptions: []
  risks:
    - "Pinned Bicep compilation and emitted dependency inspection remain mandatory in connected CI."
    - "Protected staging/production configuration and request-flow verification remains mandatory."
    - "Existing protected smoke-evidence and SMK-19 blockers remain unresolved."
  defects:
    - "REPAIRED LOCALLY: production/staging API host allowlists constructed legacy names instead of using each API resource's defaultHostName."
    - "REPAIRED LOCALLY: production/staging API CORS allowlists constructed legacy names instead of using each web resource's defaultHostName."
  blockers:
    - "Bicep/Azure CLI and frontend dependencies are unavailable locally."
    - "Protected smoke-evidence delivery and real SMK-19 previous-release evidence remain absent."
  approvals: []
  requested_action: "Independent Tester must run connected Bicep/frontend regressions, inspect compiled dependencies and verify exact staging host/origin behavior before the unchanged protected smoke and release gates proceed."
```

READY_FOR_TEST

## Current worktree terminal state

The PowerShell 7 HTTP redirect repair recorded above is the latest bounded implementation change and is ready for independent Linux/PowerShell 7 testing. The broader smoke-evidence continuation still governs the overall worktree: its validated local implementation is complete, but the protected evidence ingestion route, operational producer identities and real SMK-19 previous-release source require the named architecture/governance decision before the pipeline can consume protected smoke evidence.

NEEDS_ARCHITECTURE_DECISION

## HTTP smoke error-object normalization repair

### Baseline, scope and traceability

This bounded Developer repair started from branch `fix/mtp-azure-demo-reconciliation` at exact HEAD `253d20d5a99b3e6b231f43f5a8864ee3bca25ce6`. The index and worktree were clean before editing. Nothing was staged, committed, pushed, reset or stashed. The change is confined to the HTTP helper, its real loopback regression and this supporting documentation; CSP, hostname resolution, Bicep, evidence acceptance, authentication, release gates and deployment controls are unchanged.

```yaml
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
```

This regression-only repair is separable from Q-01 and Q-08: it does not choose a stack, change an environment, ingest protected evidence or alter a release decision. Existing connected-CI and human gates remain in force.

### Confirmed cause and correction

The helper captured `Invoke-WebRequest` errors twice: `-ErrorVariable requestErrors` received the engine's error-variable object and `catch` received the terminating record. Redirect-limit responses are non-terminating `ErrorRecord` objects and therefore passed. A terminating request failure uses a different shape: the error-variable collection contains `System.Management.Automation.CmdletInvocationException`, with an embedded `ErrorRecord`, while `catch` receives `System.Management.Automation.ErrorRecord`. The previous `Where-Object` unconditionally read `FullyQualifiedErrorId` from every error-variable item, so the abrupt-close transport fixture reached that property access with the exception object and failed under strict mode. There was no stream merge; the success pipeline, error variable and catch path were separate. A nested collection was not the normal origin, but is now covered as an unexpected object and fails closed.

The helper now normalizes success output and both error origins before deciding the result. `ErrorRecord`, `Exception`, null and unexpected objects have explicit classifications. An exception's embedded `ErrorRecord` is inspected only after type verification; `FullyQualifiedErrorId`, `Exception`, `Response`, `StatusCode`, `Headers`, `Content` and `RawContentLength` are accessed only after compatible type/property checks. Unknown, null, nested or malformed shapes cannot become success and are retained as bounded type-only diagnostics.

`MaximumRedirection 0` and `SkipHttpErrorCheck` remain unchanged. A redirect-limit result is accepted only when every captured error resolves to the exact `MaximumRedirectExceeded,Microsoft.PowerShell.Commands.InvokeWebRequestCommand` identity and the corresponding captured response is a valid 3xx response. `Test-AzureDemoHttpsRedirectResponse` still permits only 301, 302, 307 or 308 and still requires HTTPS, the exact host, default port, exact path, and no userinfo, query or fragment. No certificate bypass was added. An ordinary HTTP 500 response remains `TransportSucceeded = true`; a failure exception carrying status 500 remains `TransportSucceeded = false` with status 500 retained.

The regression now prints only collection/result/error/exception type names, capture origins, bounded status and category. It exercises real redirect, 200/500, cross-host and abrupt-close fixtures, plus focused runtime coverage for the terminating error-variable object shape, ErrorRecord, raw Exception, null, unexpected object, nested collection, malformed status, exception-carried 500 and wrong redirect identity. Readiness files are removed after each fixture. A forced post-readiness failure proves child termination and readiness-file cleanup; the suite also verifies removal of its temporary directory.

### Verification status

| Check | Result |
|---|---|
| PowerShell parsing | PASS, exit `0`: both changed PowerShell files parse under strict Windows PowerShell syntax. This is supplemental evidence only. |
| Focused runtime normalization | PASS, exit `0`, Windows PowerShell `5.1.26100.9444`: error-variable outer type `System.Collections.ArrayList`, item type `System.Management.Automation.CmdletInvocationException`, catch type `System.Management.Automation.ErrorRecord`; unknown and nested shapes failed closed; exception-carried 500 retained status without transport success; wrong redirect identity was rejected. This is supplemental evidence only. |
| Smoke target resolution | PASS, exit `0`: generated-host, exact-identity, staging/production, unsafe URI, catalogue order and 12 invalid cases. |
| Smoke evidence contract | PASS, exit `0`: valid fixtures and all fail-closed provenance/substitution cases. |
| Pipeline structural contract | PASS, exit `0`: seven ordered stages. |
| Source/security boundary | PASS, exit `0`: 194 source/configuration files. |
| Linux PowerShell 7.6.6 complete HTTP suite | **LINUX_VERIFICATION_PENDING**. The authorized host has Windows PowerShell 5.1 only; `pwsh` and Docker are absent, WSL reports not installed, and the sandbox cannot reach NuGet to install a workspace-local runtime. No Linux fixture result is claimed. |
| External/protected actions | NOT RUN: no Azure, Azure DevOps, SQL, Entra, deployment, migration, seed, swap, endpoint smoke or release action occurred. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "BLOCKED_IMPLEMENTATION"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_253d20d5a99b3e6b231f43f5a8864ee3bca25ce6"
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
    - "scripts/smoke/AzureDemoSmokeUtilities.ps1"
    - "scripts/build/Test-AzureDemoSmokeHttp.ps1"
    - "scripts/smoke/README.md"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "Type-only runtime reproduction confirms the terminating ErrorVariable/catch object split."
    - "Locally available smoke-target, evidence, pipeline and source-boundary regressions pass."
  decisions:
    - "Normalize each stream origin explicitly and fail closed on null, unknown, nested or malformed objects."
    - "Accept redirect-limit responses only with the exact expected error identity and a corresponding valid response."
    - "Retain bounded type-only diagnostics and the existing public result contract."
  assumptions: []
  risks:
    - "The complete changed HTTP regression has not yet executed on Linux PowerShell 7.6.6."
  defects:
    - "REPAIRED LOCALLY: terminating ErrorVariable exceptions were treated as ErrorRecords and caused strict-mode property access failure."
  blockers:
    - "No authorized Linux/PowerShell 7 runtime is available in the current environment."
  approvals: []
  requested_action: "Run the entire scripts/build/Test-AzureDemoSmokeHttp.ps1 suite on the existing ubuntu-latest PowerShell 7.6.6 validation agent and retain its type-only fixture diagnostics before changing the hand-off state."
```

LINUX_VERIFICATION_PENDING

## Azure CLI 2.90 App Service runtime JSON-catalogue repair

### Baseline, scope and traceability

This bounded Developer repair started from the requested branch `fix/mtp-azure-demo-reconciliation` at exact HEAD `ac137ffb32b6754e194eff43029d1e3a6a5de61a`. The index and worktree were clean before editing. Nothing was staged, committed, pushed, reset or stashed. The change is confined to native App Service runtime discovery, its focused and structural regressions, and this supporting documentation. App Service runtime versions, Bicep application configuration, CSP, authentication, networking, SQL, protected evidence and release gates are unchanged.

```yaml
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
```

Q-01 remains closed only for the controlled package scope already approved at the start of this document. This local pipeline-validation repair does not choose a stack, change a deployed environment, ingest protected evidence or alter a release decision. Q-08 and every existing connected-CI, staging, protected-smoke and human release/deployment gate remain unchanged.

### Confirmed defect and correction

The previous validator parsed the first tab-separated field and required `^[A-Z][A-Z0-9]*\|[A-Za-z0-9][A-Za-z0-9._-]*$`. Its existing three-positive/six-negative regression passed, but a synthetic reproduction using the real Azure CLI 2.90 entries `dotnet|11`, `DOTNETCORE|10.0` and `NODE|24-lts` failed with `Azure App Service runtime discovery returned malformed TSV output.` The lowercase but valid unrelated `dotnet|11` entry therefore rejected the complete catalogue before exact required-runtime membership could be proved.

`PreDeploymentGate` now requests `az webapp list-runtimes --os linux --output json --only-show-errors`. Stdout is captured as JSON lines while stderr is redirected to a unique file beneath `$(Agent.TempDirectory)`; the streams are never merged. `$LASTEXITCODE` is captured on the immediately following line and explicitly checked before stdout is assembled or parsed. The stderr file is removed in `finally` and is neither logged nor passed to the validator.

The validator now accepts one JSON string and the native exit code. It rejects a nonzero exit before parsing; empty or malformed JSON; a non-array or empty top-level value; non-object entries; and missing, non-string, blank or malformed `config`/`os` fields. It retrieves `config` and `os` through each object's named properties and ignores other properties. Runtime-family syntax permits upper- or lowercase letters, so unrelated `dotnet|11` is valid catalogue data. Required membership remains ordinal and exact: only `NODE|24-lts` and `DOTNETCORE|10.0` whose `os` value is exactly `Linux` satisfy the gate. `NODE|26`, `dotnet|11`, preview suffixes and required configs reported for another OS do not satisfy it. The existing two-line successful validator output is unchanged, and no support-policy rule was added or removed.

The focused regression covers the three supplied Azure CLI 2.90 objects, reordered properties, additional metadata, both required runtimes missing individually, wrong OS, newer versions only, nonzero exit with valid stdout, empty/malformed JSON, empty/non-array/non-object top-level shapes, invalid and missing required fields, diagnostic contamination, and similarly named preview identifiers.

### Verification

| Check | Result |
|---|---|
| Baseline and inventory | PASS before editing: exact requested branch and HEAD; clean worktree and empty staged index. |
| Defect reproduction | PASS as a reproduction harness, exit `0`: existing regression first passed 3 positive/6 fail-closed cases; the real mixed catalogue then produced the expected uppercase-regex validation failure. |
| PowerShell parsing | PASS: the validator, focused regression and pipeline structural regression parse under Windows PowerShell 5.1. |
| Native-runtime regression | PASS, exit `0`: 3 positive and 15 fail-closed cases. |
| Pipeline structural regression | PASS, exit `0`: seven ordered stages; JSON plus `--only-show-errors`, separate temporary stderr, immediate exit capture/check, JSON validator wiring, exact Linux membership and regression execution are pinned. |
| Local runtime | Windows `10.0.26200`; Windows PowerShell `5.1.26100.9444`. |
| Linux/PowerShell 7/Azure CLI 2.90 | NOT RUN and not claimed: `pwsh` is unavailable on the authorized local host, and the task prohibits Azure and Azure DevOps actions. The real connected command, native stream behavior and CLI catalogue remain pending on the protected Linux validation agent. |
| External/protected actions | NOT RUN: no Azure, Azure DevOps, SQL, Entra, deployment, migration, seed, swap, endpoint smoke, rollback or approval action occurred. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_TEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_ac137ffb32b6754e194eff43029d1e3a6a5de61a"
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
    - "azure-pipelines.yml"
    - "scripts/build/Assert-AzureAppServiceNativeRuntimes.ps1"
    - "scripts/build/Test-AzureAppServiceNativeRuntimes.ps1"
    - "scripts/build/Test-AzurePipelineStructure.ps1"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "The real mixed Azure CLI 2.90 fixture passes while exact required Linux runtime membership remains fail closed."
    - "The focused runtime and seven-stage pipeline structural regressions pass locally on Windows PowerShell 5.1."
  decisions:
    - "Use named JSON properties instead of TSV column order."
    - "Keep Azure CLI stderr out of JSON and remove its temporary capture in finally."
    - "Permit lowercase unrelated runtime families while requiring ordinal exact approved configs on Linux."
  assumptions: []
  risks:
    - "The changed native capture has not yet executed on the protected Linux PowerShell 7/Azure CLI 2.90 agent."
  defects:
    - "REPAIRED LOCALLY: uppercase-only TSV validation rejected the valid lowercase dotnet|11 catalogue entry."
  blockers: []
  approvals: []
  requested_action: "Independent Tester must run the focused runtime and structural regressions plus the unchanged PreDeploymentGate on the protected Linux Azure CLI 2.90 agent, confirming separate stderr, exact runtime success output and no catalogue disclosure."
```

READY_FOR_TEST

## Current worktree terminal state - staging reconciliation

The latest worktree continuation is the section **Focused staging-path execution and process-boundary reconciliation** above, based on exact HEAD `17c67ebc2dce731681245dd720d5577be7d209e7`. Its focused local implementation and supplemental regressions pass, and the unavailable Linux/PowerShell 7, Bicep and production-package checks are pinned to existing unprotected `ubuntu-latest` jobs. This hand-off supersedes older terminal markers in this cumulative document. It does not override the unchanged architecture/Product decision for the supplied live S2 plan, Azure Platform/Operations approval, protected smoke evidence, first-release rollback evidence or human release gates.

NEEDS_ARCHITECTURE_DECISION

## Current worktree terminal state - web content reconciliation

The latest bounded continuation is **Web staging equal-timestamp content-reconciliation repair** above, based on exact HEAD `89bff5682b2a2bdead2e81c6b32dea120e46fe05`. Its local Windows PowerShell 5.1 regressions pass. The real Linux/PowerShell 7/`rsync` regression, fresh package generation and authorized staging-only OneDeploy/content reconciliation remain explicit connected checks. This hand-off supersedes older terminal markers in this cumulative document without overriding the unchanged live-plan architecture decision, Azure Platform/Operations approval, protected evidence or human release/deployment gates.

READY_FOR_TEST

## Legacy web-package timestamp fixture and classification repair

### Baseline, scope and traceability

This bounded Developer repair started from branch `fix/mtp-azure-demo-reconciliation` at exact HEAD `7ec94c45e8527f41404928112a68e515d104e22c`. The index and worktree were clean before editing. The repair is limited to application-manifest timestamp normalization, structured preflight rejection identity, and the timestamp/package/content regressions that prove those controls. It does not change deployment exit-code handling, target allowlists, immutable manifest or ZIP-hash enforcement, Azure resources, release gates, or any production state. Nothing was committed, pushed, deployed, migrated, seeded, swapped, reset or stashed.

```yaml
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
```

This regression repair is separable from the remaining Q-01 and Q-08 production decisions: it retains the approved PowerShell/package architecture, performs only local synthetic validation, and neither changes nor exercises a protected environment. All existing connected-CI, staging, protected-evidence and human release gates remain in force.

### Observed rejection and root cause

The original fixture passed on Windows PowerShell 5.1 because `ConvertFrom-Json` retained `createdAtUtc` as `System.String`. A bounded reproduction of the PowerShell 6+ JSON materialization path supplied the same manifest value as `System.DateTime`. The unmodified validator cast that object to a culture-formatted string before `TryParseExact('O')` and rejected it as follows:

- exception type: `System.Management.Automation.RuntimeException`;
- `FullyQualifiedErrorId`: `Web application artifact manifest createdAtUtc is invalid.`;
- engine category: `OperationStopped`;
- bounded rejection category: `MANIFEST_CREATED_AT_PARSE`.

The fixture therefore did not return successfully and did not reach the intended legacy ZIP timestamp rejection. It was rejected earlier for manifest timestamp parsing, and exact message matching then replaced the original error with the generic assertion at line 77. The ZIP target, source commit and inner SHA-256 were otherwise valid in the original fixture, but the fixture did not validate a complete API/web application manifest, outer deployment manifest or exact staging target before exercising the application validator.

The production parser now normalizes an invariant round-trip string, a timezone-aware `System.DateTime`, or a `System.DateTimeOffset` to UTC without first applying culture-dependent string formatting. An unspecified `DateTime`, malformed string, null or unrelated type still fails closed. ZIP DOS timestamps remain treated as UTC wall-clock components because the format stores no timezone offset. The package regression now uses that zero-offset wall clock when recreating an archive; this prevents a Windows local offset such as BST `+01:00` from being passed into the ZIP creator while retaining the existing UTC-only creation contract and two-second ZIP rounding.

### Structured rejection and fixture isolation

`Assert-AzureDemoApplicationArtifact` now emits `System.IO.InvalidDataException` records with stable error IDs and rejection categories:

- `AzureDemo.ApplicationArtifact.WebEntryTimestampInvalid` / `web-entry-timestamp-invalid`;
- `AzureDemo.ApplicationArtifact.ZipHashMismatch` / `immutable-zip-hash-mismatch`;
- `AzureDemo.ApplicationArtifact.ManifestCreatedAtUtcInvalid` / `manifest-created-at-invalid`.

The regression classifies the structured error data rather than message text. Before each negative application check it proves the exact staging target and validates a complete outer deployment manifest bound to the expected source commit. Both fixtures contain API and web ZIPs. The legacy fixture contains a correct manifest hash and only the 1980 web-entry timestamp is invalid. The hash fixture uses a fresh deployment-specific web timestamp but declares the wrong inner SHA-256, and must receive only the hash-mismatch identity. Bounded stdout diagnostics contain only exception type, `FullyQualifiedErrorId` and rejection category. On an assertion mismatch, the original exception is retained as `InnerException` and the original structured identifiers are copied into the assertion exception data before it is thrown.

### Changed files and verification

- `scripts/deployment/AzureDemoStagingDeployment.ps1`: adds cross-runtime typed UTC timestamp normalization and structured application-artifact rejection records while retaining hash-before-timestamp validation.
- `scripts/build/Test-AzureDemoCleanWebDeployment.ps1`: completes the legacy fixture prerequisites, adds the independent hash-negative fixture, verifies string/`DateTime`/`DateTimeOffset` normalization, and records bounded structured diagnostics.
- `scripts/build/Test-AzureDemoCleanWebDeploymentProcessBoundary.ps1`: requires both bounded rejection categories in the successful generated caller while retaining all nonzero failure cases.
- `scripts/build/Test-AzureDemoPackageGeneration.ps1`: shares the production timestamp normalizer and uses the reconstructed UTC ZIP wall clock for deterministic re-packaging.
- `scripts/build/Test-AzurePipelineStructure.ps1`: pins both stable production rejection IDs before OneDeploy.
- `docs/implementation/AZURE_DEMO_Implementation_Work_Package.md`: records this implementation hand-off and pending Linux evidence.

| Check | Result |
|---|---|
| Baseline and preservation | PASS: requested branch/HEAD, clean index/worktree, no reset/stash/commit/push and no pre-existing tracked changes to reconcile. |
| PowerShell parsing and diff whitespace | PASS on Windows PowerShell 5.1; all five changed scripts parse and `git diff --check` exits `0`. |
| Typed timestamp normalization | PASS on Windows PowerShell 5.1 for invariant string, UTC/local `System.DateTime`, and `System.DateTimeOffset`; unspecified and malformed inputs fail closed. |
| Clean deployment regression | PASS on Windows PowerShell 5.1: valid new timestamp reaches the successful clean synchronous deployment fixture; 1980 timestamp rejects with `WebEntryTimestampInvalid`; wrong hash rejects with `ZipHashMismatch`; four invalid targets and exit 17 remain rejected. |
| Generated-caller process boundary | PASS on Windows PowerShell 5.1: assertion/native/missing/cleanup cases each exit `1`; actual regression exits `0`; structured timestamp and hash categories are present in child stdout. |
| Package generation regression | PASS on Windows PowerShell 5.1 against a synthetic current-commit six-file package: path boundary, manifest binding, timestamp policy, SHA-256 and deterministic regeneration pass. Pre-existing ignored package output was restored afterward. |
| Deployed-content regression | PASS on Windows PowerShell 5.1: exact SHA-256/content reconciliation, stale-file and BUILD_ID rejection, dependency transformation and bounded Oryx metadata. |
| Pipeline structural regression | PASS on Windows PowerShell 5.1: seven ordered stages and both structured preflight identities retained. |
| PowerShell 7 materialization simulation | PASS on Windows PowerShell 5.1: forcing `createdAtUtc` to the `System.DateTime` shape that caused the Linux failure now reaches `WebEntryTimestampInvalid` instead of manifest parsing. This is supplemental, not Linux evidence. |
| Real Linux / PowerShell 7 / `rsync` timestamp regression | `LINUX_VERIFICATION_PENDING`: no `pwsh`, WSL, Docker or Podman runtime is available locally. Windows and simulated checks are not represented as Linux proof. |
| External/protected actions | NOT RUN: no Azure, Azure DevOps, SQL, Entra, deployment, migration, seed, smoke, swap, release or approval action occurred. |

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_TEST"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "UNCOMMITTED_WORKTREE_FROM_7ec94c45e8527f41404928112a68e515d104e22c"
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
    - "scripts/deployment/AzureDemoStagingDeployment.ps1"
    - "scripts/build/Test-AzureDemoCleanWebDeployment.ps1"
    - "scripts/build/Test-AzureDemoCleanWebDeploymentProcessBoundary.ps1"
    - "scripts/build/Test-AzureDemoPackageGeneration.ps1"
    - "scripts/build/Test-AzurePipelineStructure.ps1"
    - "docs/implementation/AZURE_DEMO_Implementation_Work_Package.md"
  evidence:
    - "Windows PowerShell 5.1 clean-deployment, generated-caller boundary, package, content, structure, parsing and diff checks pass."
    - "The legacy and hash fixtures expose distinct structured error identities after all preceding target/manifest/commit prerequisites pass."
  decisions:
    - "Normalize JSON timestamp strings and PowerShell 6+ DateTime materialization without culture-dependent string conversion."
    - "Classify negative fixtures using production error identity and category, never generic exception acceptance or broader message matching."
    - "Retain immutable manifest/ZIP hash ordering, UTC ZIP creation and original process exit semantics."
  assumptions: []
  risks:
    - "Real Linux PowerShell 7 and rsync execution remains mandatory before independent acceptance."
  defects:
    - "REPAIRED LOCALLY: PowerShell 6+ DateTime materialization caused createdAtUtc parsing to reject before the intended legacy timestamp condition."
    - "REPAIRED LOCALLY: the package regression reused a locally offset ZIP timestamp instead of its UTC wall-clock representation."
  blockers: []
  approvals: []
  requested_action: "Independent Tester must run the full clean-deployment, generated-caller, package/content and real Linux PowerShell 7/rsync timestamp regressions against this exact worktree before quality review."
```

READY_FOR_TEST

## Current worktree terminal state - Linux executable discovery

The latest bounded continuation is **Linux executable discovery and collected web-deployment regression repair** above, based on exact HEAD `50b823aad66cfa14126ba2a035cde6666b028682`. Its portable Windows PowerShell 5.1 regressions, synthetic current-commit package regression, failure-collection outer-status check, parsing and pipeline structural check pass as recorded. Real Linux PowerShell 7 with real `rsync` remains explicitly pending on the single unprotected `ubuntu-latest` collected task; no Linux pass is claimed locally. This hand-off supersedes older terminal markers in this cumulative document without changing any protected deployment, Azure, migration, seed, swap, release or human-approval gate.

READY_FOR_TEST

## Current worktree terminal state - bounded API deployment timestamp

The latest bounded continuation is **Bounded API deployment timestamp repair**
above, based on exact HEAD
`95b4099ffd220a9d6be692ae28b18e31ec8a6c92`. Its portable Windows
PowerShell 5.1 timestamp, preflight, process-boundary, deployed-content,
artifact and pipeline-structure regressions pass. A fresh normal package,
real Linux PowerShell 7/`rsync`, and authorised staging-only API reconciliation
remain explicit CI/live checks. This hand-off supersedes older terminal markers
in this cumulative document without authorising Azure, SQL, deployment, swap,
release, merge or any human approval.

READY_FOR_TEST

## Current worktree terminal state - post-deployment readiness stabilization

The latest bounded continuation is **Bounded post-deployment staging readiness gate** above, based on exact HEAD `854e8bb3b7b0cfc9b21183d1af0f50ccb973e6f6`. Its focused readiness, exact-target, pipeline-caller, protected-evidence-contract, supplemental orchestration, source-boundary, parsing, pipeline-structure and diff checks pass locally as recorded. Real Linux PowerShell 7 request execution and an authorised protected staging run remain pending. No Azure action or application readiness-budget change occurred. The missing approved protected-evidence delivery for 17 checks and the distinct prior-release/rehearsal evidence required by SMK-19 remain release blockers; there is no first-release waiver.

READY_FOR_TEST

## Current worktree terminal state - readiness JSON timestamp preservation

The latest bounded continuation is **PowerShell 7 readiness-evidence timestamp preservation repair** above, based on exact HEAD `92d6c149346367e84b57bfc2f2b5bfc5be4b6fe5`. Its Windows PowerShell 5.1 focused readiness, smoke-evidence, supplemental orchestration, source-boundary, parsing, pipeline-structure and diff checks pass as recorded. The exact `ubuntu-latest` PowerShell 7 task remains required to confirm default `System.DateTime` versus preserved `System.String`; no Linux pass is claimed locally. No Azure, deployment, migration, seed, swap, protected evidence, release or human-approval action occurred.

READY_FOR_TEST
