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
- **Exact unchanged HEAD:** `4dc284b06a9d0cb2e0114c7a16d99196b545b63e`.
- **Implementation commit:** `null`; the recovered implementation remains uncommitted by instruction.
- **Data/environment boundary:** local and isolated validation using synthetic data only.
- **Developer state:** `READY_FOR_TEST`.

The four exact-package decisions authorise controlled implementation and local or isolated testing only. Q-01 is closed for this package. Q-09 external identity remains excluded and is separable. Azure Platform/Operations approval remains `PENDING_PRE_DEPLOYMENT`; no Azure, Azure SQL, Key Vault, Entra, App Service, Azure DevOps, resource-group or other cloud action was performed.

## Implemented deployment-readiness behaviour

- Added fail-closed `AzureDemo` startup validation for exact Entra issuer/audience/client allow-list, server-side membership secret reference, membership-cache limit, Blob endpoint/container and passwordless approved Azure SQL target. `LocalTest` and `X-Lgr-Test-Principal` authority are prohibited.
- Added liveness/readiness checks, secure response headers, forwarded-header handling, private API expectations and same-origin Next.js proxy/authentication contracts.
- Added Node.js 24/Next.js 16 standalone and .NET 10 Linux App Service packaging, with local Development, Testing and LocalTest configuration excluded from published artifacts.
- Added Azure Blob discovery-import persistence with bounded tenant/project paths and retained file-based import only. No discovery API was introduced.
- Added parameterised resource-group-scoped Bicep for App Service staging slots, user-assigned managed identities, Key Vault, Azure SQL, Blob Storage, monitoring, VNet integration, private endpoints, private DNS and alerts. The templates do not provision migration targets.
- Preserved `infra/bicep/parameters/dev.bicepparam` as an AzureDemo-only compatibility parameter entry. Deletion was unnecessary: the restored equivalent contains the same 21 approved parameters as `azure-demo.bicepparam` and no legacy development values.
- Added a default-disabled, release-branch-only Azure Pipelines path with build/test/audit/package/SBOM, Bicep build/what-if, controlled EF artifacts, gated slot deployment, 22 smoke contracts, API-before-web swap and web-before-API rollback ordering. Human validation and protected environments remain mandatory.
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
| Exact Git control | PASS: branch `release/azure-demo-v1`; HEAD remains `4dc284b06a9d0cb2e0114c7a16d99196b545b63e`; no stage, commit, push, merge or deployment. |
| Locked .NET restore | PASS with four `NU1900` warnings because the NuGet advisory endpoint is unavailable in the isolated environment. Package locks remained intact. |
| Release build | PASS: 0 errors, 4 `NU1900` advisory-feed warnings. |
| Complete .NET tests | PASS: 195 unit + 145 integration = 340 passed; 0 failed or skipped. |
| EF pending-model validation | PASS with pinned global `dotnet-ef` 10.0.11: no changes since the last migration. No database was accessed. |
| Frontend dependency tree | PASS offline from `package-lock.json` using `npm ls --package-lock-only`: lockfile v3; Vitest 4.1.11; `@vitest/mocker` 4.1.11; `brace-expansion` 1.1.21 and 5.0.12. |
| Frontend tests/lint/build | OWNER EVIDENCE retained: 22/22 tests, lint and Next.js production build with 21 routes passed. A repeat install could not run because the isolated npm cache lacks the Vitest tarball and network access is denied; no connected npm audit was attempted. |
| Owner dependency audit | OWNER EVIDENCE retained: connected npm audit exited 0 with zero vulnerabilities. It was not rerun, as instructed. |
| Bicep build/lint | NOT LOCALLY AVAILABLE: neither Bicep CLI nor Azure CLI is installed. The pipeline compiles `main.bicep` and the approved parameter file before what-if; independent connected CI evidence remains required. |
| Azure Pipelines YAML | PASS for the local structural contract: exactly 7 ordered stages, default-disabled deployment, release-branch condition, protected environments, human validation, swap and rollback order. No general YAML parser is installed locally. |
| PowerShell validation | PASS: all 9 new scripts parse without errors. |
| Packaging and manifest | PASS: API/web ZIP hashes, ZIP-root layout and prohibited-file/local-setting scans validated against the recovered package. No ZIP, DLL or PDB is intended for source control. |
| SBOM generation | PASS: CycloneDX inventories generated locally for 522 npm and 107 NuGet components under ignored output. |
| Smoke contracts | PASS at plan level: contiguous `SMK-01` through `SMK-22`; plan-only mode confirmed no endpoint or cloud calls. Execution requires the protected deployed environment and independent evidence. |
| Boundary scan | PASS across 152 source/configuration files for likely secrets, prohibited identity/local-test settings, startup migration/seed, generated binaries and prohibited application capability dependencies. This is a scoped developer diagnostic, not a substitute for an approved secret/SAST scanner. |
| Startup behaviour | PASS: an AzureDemo startup rehearsal without required configuration terminated with `Authentication:Mode must be Entra in AzureDemo.` |
| EF artifact generation | PASS for the idempotent SQL script and 8-migration manifest. Linux-x64 bundle restore is not locally reproducible because runtime metadata requires the blocked NuGet source; the pipeline must generate it in its connected build environment. |
| `git diff --check` | PASS: no whitespace errors; index empty; 60 intended source/evidence files; ignored Azure demo generated output absent from status. Git reports only its normal LF-to-CRLF checkout notices. |

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

- `scripts/build/New-AzureDemoPackages.ps1`; `scripts/build/New-AzureDemoSboms.ps1`; `scripts/build/New-EfMigrationArtifacts.ps1`; `scripts/build/Test-AzureDemoArtifacts.ps1`; `scripts/build/Test-AzureDemoSourceBoundaries.ps1`; `scripts/build/Test-AzurePipelineStructure.ps1`.
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
- Application rollback swaps web before API back to known-good slots. Forward-only database changes require compatibility and a separately approved recovery action; no startup or autonomous migration exists.
- Azure Platform/Operations approval, connected pipeline validation, exact-commit artifact hashes, independent Tester evidence, Quality review and human release authority are still required before any deployment.

## Hand-off

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_TEST"
  work_item: "AZURE-DEMO-001"
  branch: "release/azure-demo-v1"
  commit: null
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
    - "infra/bicep/"
    - "scripts/build/"
    - "scripts/data/"
    - "scripts/database/"
    - "scripts/smoke/"
    - "src/api/"
    - "src/web/"
    - "tools/AzureDemo.DataTool/"
  evidence:
    - "Locked restore, Release build, 340 .NET tests and EF pending-model validation passed locally."
    - "Package-lock dependency tree, 9-script PowerShell parsing, 7-stage pipeline contract, artifact manifest, SBOM, 22 smoke-plan contracts and source-boundary scan passed locally."
    - "Owner evidence records frontend 22/22, lint, 21-route production build and connected npm audit exit 0 with zero vulnerabilities."
  decisions:
    - "The deleted dev.bicepparam was restored as an AzureDemo-compatible equivalent because deletion was unnecessary and would remove an owner-tracked Bicep entry."
    - "Reproducible local Azure demo output is ignored and excluded from source control."
    - "Deployment remains default disabled and subject to Azure Platform/Operations and human gates."
  assumptions:
    - "Connected CI has Bicep, YAML, npm and Linux runtime feeds needed to reproduce the unavailable local checks."
  risks:
    - "Independent connected Bicep, pipeline, Linux EF bundle, approved secret/SAST and deployed-environment smoke evidence remains required."
  defects: []
  blockers: []
  approvals:
    - "Four exact-package implementation/local-test approvals at b8800e1eda014eef1421a1af5427aaea41393496."
    - "Azure Platform/Operations remains PENDING_PRE_DEPLOYMENT."
  requested_action: "Bind the uncommitted source inventory to a human-created candidate commit, then independently test the exact commit and generated artifact hashes without deploying or using any non-synthetic data."
```
