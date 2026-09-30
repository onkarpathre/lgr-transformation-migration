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
- **Original tested Azure demo candidate:** `38add95edf8b63a552a29a6d6625336de92ea896`.
- **Committed and pushed repair candidate:** `a5d683c7336d5938e274cb2c9460a2b6e4da6542`.
- **Repair scope:** commit `a5d683c` contains the monitoring-alert implementation, rollback safeguards and related validation changes. It addresses Tester defects `AZD-TST-001`, `AZD-TST-002` and `AZD-TST-003`.
- **Data/environment boundary:** local and isolated validation using synthetic data only.
- **Developer state:** `READY_FOR_RETEST`.
- **Evidence-only update:** this document update records the immutable repair candidate and does not alter candidate `a5d683c7336d5938e274cb2c9460a2b6e4da6542`.

The four exact-package decisions authorise controlled implementation and local or isolated testing only. Q-01 is closed for this package. Q-09 external identity remains excluded and is separable. Azure Platform/Operations approval remains `PENDING_PRE_DEPLOYMENT`; no Azure, Azure SQL, Key Vault, Entra, App Service, Azure DevOps, resource-group or other cloud action was performed.

## Implemented deployment-readiness behaviour

- Added fail-closed `AzureDemo` startup validation for exact Entra issuer/audience/client allow-list, server-side membership secret reference, membership-cache limit, Blob endpoint/container and passwordless approved Azure SQL target. `LocalTest` and `X-Lgr-Test-Principal` authority are prohibited.
- Added liveness/readiness checks, secure response headers, forwarded-header handling, private API expectations and same-origin Next.js proxy/authentication contracts.
- Added Node.js 24/Next.js 16 standalone and .NET 10 Linux App Service packaging, with local Development, Testing and LocalTest configuration excluded from published artifacts.
- Added Azure Blob discovery-import persistence with bounded tenant/project paths and retained file-based import only. No discovery API was introduced.
- Added parameterised resource-group-scoped Bicep for App Service staging slots, user-assigned managed identities, Key Vault, Azure SQL, Blob Storage, monitoring, VNet integration, private endpoints, private DNS and alerts. The repaired alert module now covers web availability, API readiness through the web health route, web/API HTTP 5xx, unhandled exceptions, authentication failures/authorization denials, SQL saturation/connectivity, Key Vault denial, Blob dependency failure, discovery-import failure, storage malware/scan failure, failed deployment, both staging-slot health signals, the daily telemetry cap and UK South service health. All alert resources route to the approved action group. The templates do not provision migration targets.
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
| Exact Git control | PASS locally: branch `release/azure-demo-v1`; HEAD and local upstream `origin/release/azure-demo-v1` both resolve to repair candidate `a5d683c7336d5938e274cb2c9460a2b6e4da6542`; ahead/behind `0/0`. Its direct parent is original tested candidate `38add95edf8b63a552a29a6d6625336de92ea896`. The repair is committed and pushed; no commit, push, merge or deployment was performed by this evidence-only document update. |
| Locked .NET restore | PASS with four `NU1900` warnings because the NuGet advisory endpoint is unavailable in the isolated environment. Package locks remained intact. |
| Release build | PASS: 0 errors, 4 `NU1900` advisory-feed warnings. |
| Complete .NET tests | PASS: 197 unit + 145 integration = 342 passed; 0 failed or skipped. |
| Focused AzureDemo tests | PASS: 19/19, including mandatory monitoring coverage and rollback guard structure. |
| EF pending-model validation | PASS with pinned global `dotnet-ef` 10.0.11: no changes since the last migration. No database was accessed. |
| Frontend dependency tree | PASS from `package-lock.json` using `npm.cmd ls --package-lock-only --all` (exit 0): Vitest and `@vitest/mocker` resolve to 4.1.11; patched `brace-expansion` versions remain locked. Frontend execution remained unavailable as recorded below. |
| Mandatory monitoring coverage | PASS: `Test-AzureDemoMonitoringAlerts.ps1` validates 17 required alert resources, the four approved Azure Monitor resource types, Bicep parameter/slot wiring and action-group routing. Microsoft template references were used for static schema review because the Bicep CLI is unavailable. |
| Rollback fail-closed guards | PASS: one exact approved target accepted and 10 wrong-branch/release/environment/resource-group/application/slot cases rejected. Pipeline structure proves the guard precedes `AzureCLI@2`. |
| Azure Pipelines YAML | PASS for the local structural contract: exactly 7 ordered stages, default-disabled deployment, protected environments, human validation, exact rollback conditions, API-before-web swap and web-before-API rollback. No general YAML parser is installed locally. |
| PowerShell validation | PASS: all 17 repository PowerShell scripts, including Tester-owned scripts read-only, parse with zero errors under Windows PowerShell 5.1. PowerShell 7 is unavailable. |
| Bicep parameter parity | PASS: `azure-demo.bicepparam` and `dev.bicepparam` each contain 21 assignments; comparison delta 0. |
| SBOM generation | PASS: candidate-bound CycloneDX inventories generated for 522 npm and 107 NuGet components. SHA-256: API `00b2b890a8c7d19dda792dc125f732391c8b8741aa199f98bf5c04949554886e`; web `aa8c7a930ca67669e51e7a2f30cb977c0099653bd961cd0ffc9c3c80827b0ada`. |
| Smoke contracts | PASS at plan level: contiguous `SMK-01` through `SMK-22`; plan-only mode confirmed no endpoint or cloud calls. Execution requires the protected deployed environment and independent evidence. |
| Boundary scan | PASS across 155 source/configuration files for likely secrets, prohibited identity/local-test settings, startup migration/seed, generated binaries and prohibited application capability dependencies. This is a scoped developer diagnostic, not a substitute for an approved secret/SAST scanner. |
| Startup behaviour | PASS: an AzureDemo startup rehearsal without required configuration terminated with `Authentication:Mode must be Entra in AzureDemo.` |
| Formatting and whitespace | PASS: `dotnet format --verify-no-changes` for the repaired .NET test file and `git diff --check` both exit 0. |

The seven-stage pipeline structure, Bicep parameter parity, source-boundary scanning, SBOM generation and Git diff checks passed. These results do not convert any unavailable connected or tool-dependent check into a pass.

### Checks blocked by local tooling or connectivity

| Check and exact command | Exit | Environmental blocker |
|---|---:|---|
| Live remote alignment: `git ls-remote --heads origin release/azure-demo-v1` | 128 | Outbound HTTPS to `github.com:443` is blocked. Local `origin/release/azure-demo-v1` alignment is `0/0` at the candidate SHA. |
| Frontend locked install: `npm.cmd ci --ignore-scripts --fetch-timeout=30000 --fetch-retries=0` | 1 | UNAVAILABLE: registry tarball fetches fail with `EACCES`; the writable-cache retry failed at `zod-validation-error-4.0.2.tgz`. |
| Frontend component tests: `npm.cmd run test:component` | 1 | UNAVAILABLE: `vitest` executable was unavailable because the locked install could not complete. |
| Frontend lint: `npm.cmd run lint` | 1 | UNAVAILABLE: `eslint` executable was unavailable because the locked install could not complete. |
| Frontend production build: `npm.cmd run build` | 1 | UNAVAILABLE: `next` executable was unavailable because the locked install could not complete. |
| Connected npm audit: `npm.cmd audit --package-lock-only --audit-level=moderate --fetch-timeout=30000 --fetch-retries=0` | 1 | UNAVAILABLE: npm audit endpoint is unreachable in the restricted environment. |
| Connected NuGet vulnerability check: `dotnet list LgrTransformationMigration.sln package --vulnerable --include-transitive` | 1 | UNAVAILABLE: socket access to `https://api.nuget.org/v3/index.json` is forbidden; no vulnerability result is claimed. |
| Bicep build: `bicep build infra/bicep/main.bicep --outfile artifacts/azure-demo-local/bicep/main.json` | 1 | UNAVAILABLE: `bicep` is not installed or on `PATH`. |
| Bicep lint: `bicep lint infra/bicep/main.bicep` | 1 | UNAVAILABLE: `bicep` is not installed or on `PATH`. |
| Azure CLI Bicep fallback: `az bicep build --file infra/bicep/main.bicep --outfile artifacts/azure-demo-local/bicep/main.json` | 1 | `az` is not installed or on `PATH`. |
| Linux EF migration bundle: `dotnet-ef migrations bundle --project src/api/LgrTransformationMigration.Api.csproj --startup-project src/api/LgrTransformationMigration.Api.csproj --configuration Release --target-runtime linux-x64 --output artifacts/azure-demo-local/repair-migration/lgrtm-efbundle-linux-x64 --force --verbose` | 1 | UNAVAILABLE: `NU1301` occurred because socket access to NuGet on port 443 is forbidden while resolving `linux-x64` runtime assets. |
| Complete application packages and package hashes: `New-AzureDemoPackages.ps1 -OutputDirectory artifacts/azure-demo-local/repair-packages -SkipRestore -SkipTests` | 1 | UNAVAILABLE: API publish completed, but the exact-candidate web build failed because `next` is unavailable. No complete package, manifest or package hash is claimed. |

Historical owner frontend/audit evidence remains recorded in the tested candidate history, but it was not reproduced by this repair run and is not represented as successor evidence.

## Repair commit changed-file inventory

- `azure-pipelines.yml`
- `infra/bicep/main.bicep`
- `infra/bicep/modules/alerts.bicep`
- `infra/bicep/modules/appservice.bicep`
- `scripts/build/Assert-AzureDemoRollbackTarget.ps1`
- `scripts/build/Test-AzureDemoMonitoringAlerts.ps1`
- `scripts/build/Test-AzureDemoRollbackSafeguards.ps1`
- `scripts/build/Test-AzurePipelineStructure.ps1`
- `tests/api.unit/AzureDemoDeploymentBoundaryTests.cs`

This implementation document is a subsequent evidence-only working-tree update and is not part of immutable repair commit `a5d683c`. The Tester-owned evidence pack and both `tests/assurance` files were preserved byte-for-byte and were not staged.

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

- `scripts/build/Assert-AzureDemoRollbackTarget.ps1`; `scripts/build/New-AzureDemoPackages.ps1`; `scripts/build/New-AzureDemoSboms.ps1`; `scripts/build/New-EfMigrationArtifacts.ps1`; `scripts/build/Test-AzureDemoArtifacts.ps1`; `scripts/build/Test-AzureDemoMonitoringAlerts.ps1`; `scripts/build/Test-AzureDemoRollbackSafeguards.ps1`; `scripts/build/Test-AzureDemoSourceBoundaries.ps1`; `scripts/build/Test-AzurePipelineStructure.ps1`.
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
  state: "READY_FOR_RETEST"
  work_item: "AZURE-DEMO-001"
  branch: "release/azure-demo-v1"
  commit: "a5d683c7336d5938e274cb2c9460a2b6e4da6542"
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
    - "infra/bicep/main.bicep"
    - "infra/bicep/modules/alerts.bicep"
    - "infra/bicep/modules/appservice.bicep"
    - "scripts/build/Assert-AzureDemoRollbackTarget.ps1"
    - "scripts/build/Test-AzureDemoMonitoringAlerts.ps1"
    - "scripts/build/Test-AzureDemoRollbackSafeguards.ps1"
    - "scripts/build/Test-AzurePipelineStructure.ps1"
    - "tests/api.unit/AzureDemoDeploymentBoundaryTests.cs"
  evidence:
    - "Locked restore, Release build, 342 .NET tests, 19 focused AzureDemo tests and EF pending-model validation passed locally."
    - "Seventeen mandatory monitoring alerts, action-group/parameter wiring and approved Azure Monitor resource families passed the local contract."
    - "Rollback accepted one exact target and rejected 10 incorrect branch/release/environment/resource-group/application/slot cases before any Azure task."
    - "Package-lock dependency tree, 17-script PowerShell 5.1 parsing, 7-stage pipeline contract, SBOM generation, 22 smoke-plan contracts, source-boundary scan, format and git diff checks passed locally."
    - "Blocked connected/tooling commands and exact exit codes are recorded without claiming a pass."
  decisions:
    - "The deleted dev.bicepparam was restored as an AzureDemo-compatible equivalent because deletion was unnecessary and would remove an owner-tracked Bicep entry."
    - "Reproducible local Azure demo output is ignored and excluded from source control."
    - "Deployment remains default disabled and subject to Azure Platform/Operations and human gates."
    - "Repair candidate a5d683c7336d5938e274cb2c9460a2b6e4da6542 is committed and pushed; this document-only evidence update does not change that immutable candidate."
  assumptions:
    - "Connected CI has Bicep, YAML, npm and Linux runtime feeds needed to reproduce the unavailable local checks."
  risks:
    - "Connected frontend/audit/NuGet evidence, Bicep build/lint, Linux EF bundle, exact package hashes, approved secret/SAST and deployed-environment smoke evidence remain required."
  defects: []
  blockers:
    - "Local registry/feed connectivity blocks same-worktree frontend, connected audit, NuGet advisory, Linux bundle and package evidence."
    - "Bicep CLI and Azure CLI are unavailable locally; connected CI must compile and lint the repaired template."
  approvals:
    - "Four exact-package implementation/local-test approvals at b8800e1eda014eef1421a1af5427aaea41393496."
    - "Azure Platform/Operations remains PENDING_PRE_DEPLOYMENT."
  requested_action: "Independently retest immutable repair candidate a5d683c7336d5938e274cb2c9460a2b6e4da6542 and reproduce the unavailable connected artifacts/checks against that exact candidate without deploying or using non-synthetic data."
```

READY_FOR_RETEST
