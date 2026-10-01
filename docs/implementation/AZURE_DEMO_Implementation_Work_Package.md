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
- **Committed evidence successor:** `3a017ccc44e3603c23d54d4c27469cacf0cda1d2`.
- **Final repair scope:** commit `1ae167d` resolves the final Tester monitoring defect `AZD-TST-001`; the monitoring and rollback repair history continues to resolve `AZD-TST-002` and `AZD-TST-003`.
- **Data/environment boundary:** local and isolated validation using synthetic data only.
- **Developer state:** `READY_FOR_EVIDENCE_COMMIT`.
- **Evidence-only correction:** committed evidence successor `3a017ccc44e3603c23d54d4c27469cacf0cda1d2` records immutable technical monitoring repair `1ae167d73bd0ae7adcac697c521177ff033563c1`. The current correction is an uncommitted evidence-only successor to `3a017ccc44e3603c23d54d4c27469cacf0cda1d2` until the owner commits it; it does not alter either immutable commit.

The four exact-package decisions authorise controlled implementation and local or isolated testing only. Q-01 is closed for this package. Q-09 external identity remains excluded and is separable. Azure Platform/Operations approval remains `PENDING_PRE_DEPLOYMENT`; no Azure, Azure SQL, Key Vault, Entra, App Service, Azure DevOps, resource-group or other cloud action was performed.

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
| Exact Git control | PASS at correction entry: branch `release/azure-demo-v1`; HEAD and local upstream `origin/release/azure-demo-v1` both resolve to committed evidence successor `3a017ccc44e3603c23d54d4c27469cacf0cda1d2`; ahead/behind `0/0`; zero staged files. Technical monitoring repair `1ae167d73bd0ae7adcac697c521177ff033563c1` is its direct parent. The only tracked working-tree modification is the current uncommitted evidence-only correction to this implementation document; the three authorised Tester-owned files remain untracked and unstaged with their expected SHA-256 values. |
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

These five paths comprise immutable technical monitoring repair commit `1ae167d73bd0ae7adcac697c521177ff033563c1`. Its committed evidence successor is `3a017ccc44e3603c23d54d4c27469cacf0cda1d2`. The current correction is an uncommitted evidence-only successor to `3a017ccc44e3603c23d54d4c27469cacf0cda1d2` until the owner commits it and does not alter either immutable commit. The Tester-owned evidence pack and both `tests/assurance` files were preserved byte-for-byte and remain untracked and unstaged.

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
  state: "READY_FOR_EVIDENCE_COMMIT"
  work_item: "AZURE-DEMO-001"
  branch: "release/azure-demo-v1"
  commit: "1ae167d73bd0ae7adcac697c521177ff033563c1"
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
    - "infra/bicep/main.bicep"
    - "infra/bicep/modules/alerts.bicep"
    - "infra/bicep/modules/data.bicep"
    - "scripts/build/Test-AzureDemoMonitoringAlerts.ps1"
    - "tests/api.unit/AzureDemoDeploymentBoundaryTests.cs"
  evidence:
    - "343/343 .NET tests passed: 198 unit and 145 integration; 20/20 focused AzureDemo tests passed."
    - "All 17 alert families plus the exact nested Defender ScanResults route contract passed."
    - "Rollback validation accepted one valid target and rejected 10 invalid targets before any Azure task."
    - "All 16 tracked PowerShell scripts parsed under Windows PowerShell 5.1; 22/22 smoke contracts passed plan-only; the seven-stage pipeline contract and 21/21 Bicep parameter parity passed."
    - "The security/prohibited-capability scan passed across 155 files, and git diff --check passed."
    - "Blocked connected/tooling commands and exact exit codes are recorded without claiming a pass."
  decisions:
    - "The approved 10 GB monthly malware-scanning cap and 30-day architecture retention are preserved."
    - "The existing StorageMalwareScanningResults scheduled-query alert remains enabled and unchanged in strength."
    - "Deployment remains default disabled and subject to Azure Platform/Operations and human gates."
    - "Technical monitoring repair 1ae167d73bd0ae7adcac697c521177ff033563c1 is followed by committed evidence successor 3a017ccc44e3603c23d54d4c27469cacf0cda1d2."
    - "The current correction is an uncommitted evidence-only successor to 3a017ccc44e3603c23d54d4c27469cacf0cda1d2 until the owner commits it and changes only this document."
    - "No merge, Azure/SQL/Azure DevOps access, provisioning or deployment action was performed during the current correction."
  assumptions:
    - "Connected CI has Bicep, YAML, npm and Linux runtime feeds needed to reproduce the unavailable local checks."
  risks:
    - "Bicep/Azure CLI validation, EF tool restore/model validation, frontend install/tests/lint/build, connected npm audit, connected NuGet vulnerability/deprecation checks, Linux EF migration bundle, complete application packages and hashes, approved secret/SAST and protected Azure runtime validation remain required."
  defects: []
  blockers:
    - "Local registry/feed connectivity blocks same-worktree frontend execution, connected npm/NuGet audit and EF tool restore/model evidence."
    - "Bicep CLI and Azure CLI are unavailable locally; connected CI must compile and lint the repaired template."
    - "Protected Azure runtime validation remains unavailable and requires the controlled environment and human approvals."
  approvals:
    - "Four exact-package implementation/local-test approvals at b8800e1eda014eef1421a1af5427aaea41393496."
    - "Azure Platform/Operations remains PENDING_PRE_DEPLOYMENT."
  requested_action: "Owner must commit this evidence-only correction as an immutable successor to 3a017ccc44e3603c23d54d4c27469cacf0cda1d2, then return the successor for independent retest without deploying or using non-synthetic data."
```

READY_FOR_EVIDENCE_COMMIT
