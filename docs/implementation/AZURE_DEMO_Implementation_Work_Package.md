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
- **Previous repair scope:** commit `1ae167d` resolves the final Tester monitoring defect `AZD-TST-001`; `AZD-TST-003` is limited to stable reconciliation wording in this evidence document and does not change that earlier technical implementation or its results.
- **Data/environment boundary:** local and isolated validation using synthetic data only.
- **Developer state:** `READY_FOR_SQLCMD_VARIABLE_RETEST`.

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

The pipeline does not execute `Configure-AzureDemoDatabasePrincipals.sql`. The migration identity cannot create its own contained user before it has database access. Before deployment, an independently approved Entra SQL administrator/bootstrap identity must execute the exact reviewed script and publish protected `sql-bootstrap.json` evidence. The evidence must be bound to the exact release commit, SQL server/database, migration identity name/client/object IDs, executing administrator object ID, named approval reference, UTC timestamp and SHA-256 of `Configure-AzureDemoDatabasePrincipals.sql`. Missing, stale, substituted or hash-mismatched evidence fails before migration. This remains an external DBA/human pre-deployment action; it is not claimed as automated.

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

- `scripts/build/Assert-AzureDemoRollbackTarget.ps1`; `scripts/build/New-AzureDemoPackages.ps1`; `scripts/build/New-AzureDemoSboms.ps1`; `scripts/build/New-EfMigrationArtifacts.ps1`; `scripts/build/Test-AzureDemoArtifacts.ps1`; `scripts/build/Test-AzureDemoDatabasePrincipalSql.ps1`; `scripts/build/Test-AzureDemoMonitoringAlerts.ps1`; `scripts/build/Test-AzureDemoRollbackSafeguards.ps1`; `scripts/build/Test-AzureDemoSourceBoundaries.ps1`; `scripts/build/Test-AzurePipelineStructure.ps1`.
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
