# Phase 3 SQL Slice 4 Implementation Work Package

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-02", "C-03", "C-04", "C-06"]
  functional_requirements: ["F-03", "F-04", "F-05", "F-07", "F-15"]
  non_functional_requirements: ["NF-01", "NF-02", "NF-04", "NF-06", "NF-08", "NF-09", "NF-10", "NF-13"]
  risks: ["R-01", "R-02", "R-03", "R-06", "R-09", "R-11"]
  assumptions: ["A-05", "A-06", "A-08", "A-11", "A-13", "A-18"]
  dependencies: ["D-01", "D-07", "D-08", "D-11", "D-13"]
  issues: ["I-03", "I-04", "I-06", "I-08"]
  open_questions: ["Q-01", "Q-02", "Q-06", "Q-09"]
  approvals:
    - "Product Owner scope decision by onkarpathre, 15 September 2026, approved package commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a."
    - "Architect/TDA approval by opathre, 15 September 2026, approved package commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a."
    - "Information Security approval by ashish50thbirthday-ship-it, 15 September 2026, approved package commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a."
    - "DBA/Discovery SME approval by nextgenexamprep-crypto, 15 September 2026, approved package commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a."
    - "Named Test Authority approval by ashish50thbirthday-ship-it, 16 September 2026, for synthetic Slices 2-4 testing on this branch."
```

## Control and implementation state

- **Role:** Developer under `AGENTS.md`.
- **Work item:** `PH3-SQL-001-REMAINING`, Slice 4 only.
- **Branch:** `feature/ph3-sql-remaining-implementation`.
- **Adopted baseline:** `93aada7b4b8fffcdb7bfefb2223d4974b6a9de4c`.
- **Approved architecture:** `PH3-SQL-ARCH-REMAINING-001` at `7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a`.
- **Implementation commit:** `a1df3449d3f06bdff513437e88ca5209a30a426b`.
- **State:** `READY_FOR_CONSOLIDATED_TEST` at the clean implementation commit above, ready for formal same-commit independent evidence.

The interrupted 17 modified and 15 untracked files present at hand-off were inspected individually before further edits. They contained only Slice 4 application code, generated dependency metadata and developer-owned automated tests. No unrelated feature, Tester evidence pack, Tester-only assurance harness, deployment change, customer data or production configuration was present. No file was reset, restored, cleaned or discarded.

## Implemented behaviour

- Added SQL instance and database list/detail journeys, server-side bounded paging and filters, parent/child navigation, create/update/archive controls, immutable discovery history, retryable loading/error states and permission-aware empty actions.
- Extended discovery imports with SQL CSV v1 source types, upload validation, ETag-aware preview/commit/cancel, idempotency keys, paged reconciliation outcomes, raw-row permission handling, terminal states and explicit rejected-row/atomic-commit messaging.
- Added assessment list/detail journeys with server-side status/readiness filters, exact instance/database target routing, evidence and planning command separation, controlled values, cross-field client validation, stale-write refresh and record-only/no-execution language.
- Added a default-off `SqlBrowserJourneys` child flag restricted to Development/Testing. It gates only the browser capability endpoint and is not an authorisation control.
- Added `/api/v1/session/capabilities`, protected by authenticated active project membership, returning only the current server-derived `sql.*` permission union. Caller-owned customer, role, permission and actor headers remain absent.
- Reused the central `ApiContext` with `no-store`, active project selection, typed safe Problem Details, response ETags and project-change permission clearing/reload. Customer-confidential application data is not persisted in browser storage.
- Added permission-aware navigation. Hidden controls are only presentation; every API route retains its existing server-side policy.
- Added semantic captions/headings/landmarks, labelled controls, live loading/error/success states, visible focus, responsive layouts, bounded pagination, modal focus containment/return, Escape close and validation-outcome focus.
- Preserved the product boundary: planning values remain inert records. No migration executor, Azure provisioner, DMS, remediation, AI, direct discovery API or multi-cloud path was added.

## Routes

| Route | Journey |
|---|---|
| `/inventory/sql-instances` | Paged/filterable SQL instance inventory and permitted create action. |
| `/inventory/sql-instances/[id]` | Detail, edit/archive, paged linked databases and paged typed history. |
| `/inventory/sql-databases` | Paged/filterable SQL database inventory and permitted create action. |
| `/inventory/sql-databases/[id]` | Detail, parent link, edit/archive and paged typed history. |
| `/discovery/imports` | Combined legacy and permitted SQL batch history. |
| `/discovery/imports/new` | Permission-aware legacy/SQL CSV upload and preview entry. |
| `/discovery/imports/[id]` | ETag-aware reconciliation, row evidence, commit/cancel and terminal outcomes. |
| `/assessment/sql` | Paged status/readiness filtering and permitted assessment creation. |
| `/assessment/sql/[id]` | Evidence, readiness and human planning sections with split permissions. |
| `/api/v1/session/capabilities` | Server-derived SQL browser capability contract. |

## Security, tenancy and concurrency

- `X-Project-Id` remains a selector only. The API resolves its customer and roles from the authenticated, active server-side membership.
- The frontend never supplies customer, role, permission, actor or audit-time authority. The synthetic `X-Lgr-Test-Principal` adapter remains Development-only and allow-listed.
- Capability responses contain permission names only and are cleared when project context changes. A feature flag never widens a permission.
- SQL create/update/archive, discovery and assessment APIs retain their named server policies, explicit project predicates, non-enumerating errors and existing audit behavior.
- Inventory, discovery and assessment writes use returned entity versions as quoted `If-Match` values. A 412 reloads current state and requires review; no silent overwrite or automatic mutation retry occurs.
- Import commit generates a fresh idempotency key only for an explicit user action. UI retry controls reload reads and never repeat mutations.
- Production/default feature settings remain false. Development/Testing enablement does not authorise deployment, production data or external identity.

## Developer verification

| Check | Result |
|---|---|
| `dotnet restore .\LgrTransformationMigration.sln` | PASS; all projects restored. Three retained `NU1900` warnings report that the NuGet vulnerability feed is blocked by network policy. |
| `npm.cmd ci` | PASS; 442 packages installed from the locked dependency graph. npm reported one install script not allow-listed and did not run it. |
| Release solution build | PASS; 0 errors, 3 retained `NU1900` advisory-feed warnings. |
| Focused SQL unit tests | PASS: 89 passed, 0 failed/skipped. |
| Focused SQL/browser integration tests | PASS: 57 passed, 0 failed/skipped. |
| Complete .NET tests | PASS: 146 unit + 128 integration = 274 passed, 0 failed/skipped. |
| EF pending-model validation | PASS using cached global `dotnet-ef` 10.0.11: no changes since the last migration. No database command was run. |
| Frontend component/accessibility tests | PASS: 4 files, 15 tests, 0 failed/skipped. The retained jsdom canvas notice is emitted by `axe-core`; no canvas package is required by the application. |
| Frontend lint | PASS. |
| Frontend Next.js 16.3.4 production build | PASS: 19 routes. |
| Installed dependency tree (`npm ls --depth=0`) | PASS. |
| npm production vulnerability audit | NOT AVAILABLE: the registry advisory endpoint was blocked by network policy; no vulnerability result is claimed. |
| Forbidden-capability and secret-value diff scan | PASS. |
| `git diff --check` | PASS; line-ending notices only. |

## Files changed

### API and integration developer tests

- `src/api/Contracts/SessionDtos.cs`
- `src/api/Controllers/SessionController.cs`
- `src/api/Infrastructure/IdentityAuthorization.cs`
- `src/api/Infrastructure/SqlDiscoveryAssessmentFeatureFilter.cs`
- `src/api/Program.cs`
- `src/api/appsettings.json`
- `src/api/appsettings.Development.json`
- `src/api/appsettings.Testing.json`
- `tests/api.integration/BrowserCapabilitiesApiTests.cs`

### Browser application and developer tests

- `src/web/app/discovery/imports/page.tsx`
- `src/web/app/discovery/imports/new/page.tsx`
- `src/web/app/discovery/imports/[id]/page.tsx`
- `src/web/app/inventory/sql-instances/page.tsx`
- `src/web/app/inventory/sql-instances/[id]/page.tsx`
- `src/web/app/inventory/sql-databases/page.tsx`
- `src/web/app/inventory/sql-databases/[id]/page.tsx`
- `src/web/app/assessment/sql/page.tsx`
- `src/web/app/assessment/sql/[id]/page.tsx`
- `src/web/components/ApiContext.tsx`
- `src/web/components/AppShell.tsx`
- `src/web/components/SqlInventoryForms.tsx`
- `src/web/components/ui.tsx`
- `src/web/app/globals.css`
- `src/web/types/api.ts`
- `src/web/tests/ApiContext.test.tsx`
- `src/web/tests/AppShell.test.tsx`
- `src/web/tests/SqlInventoryForms.test.tsx`
- `src/web/tests/ui.test.tsx`
- `src/web/tests/setup.ts`
- `src/web/vitest.config.ts`
- `src/web/package.json`
- `src/web/package-lock.json`
- `src/web/next-env.d.ts`

### Evidence

- `docs/implementation/PH3_SQL_Slice4_Implementation_Work_Package.md`

No EF model or migration, database schema, infrastructure, Azure, pipeline or production setting changed.

## Test setup and residual evidence boundaries

- All automated API tests use synthetic LocalTest identities and isolated in-memory SQLite databases. No SQL Server or customer data was accessed.
- Formal Playwright supported-browser runs, independent keyboard/focus/reflow/contrast review, 200+ mixed-asset browser timing, SQL Server execution plans/runtime concurrency/migration rehearsal and independent tenant/permission abuse evidence remain for the named Tester/Test Authority against the exact candidate commit.
- The NuGet and npm advisory services were unreachable. Dependency vulnerability closure remains required before Quality approval; no risk is accepted here.
- Wider Q-01, Q-02 commitment, Q-06/DPO, production tenancy, deployed Identity Platform/Q-09, Service Transition, PRB and human release approval remain outside this restricted implementation.
- Q-09 continues to block external customer access. No production deployment, migration application, merge or customer-data use is authorised.

## Deployment and rollback notes

There is no database migration or infrastructure change in Slice 4. In an authorised non-production environment, deploy the already compatible application with `SqlBrowserJourneys` off, smoke authentication/project isolation, then enable the child flag only after Slice 2 and Slice 3 flags are enabled. Operational rollback is data-preserving: disable `SqlBrowserJourneys` and return to the preceding compatible web/API build. Do not remove Slice 2/3 schema, history or assessment data.

## Hand-off

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_CONSOLIDATED_TEST"
  work_item: "PH3-SQL-001-REMAINING-SLICE-4"
  branch: "feature/ph3-sql-remaining-implementation"
  commit: "a1df3449d3f06bdff513437e88ca5209a30a426b"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-02", "C-03", "C-04", "C-06"]
    functional_requirements: ["F-03", "F-04", "F-05", "F-07", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-04", "NF-06", "NF-08", "NF-09", "NF-10", "NF-13"]
    risks: ["R-01", "R-02", "R-03", "R-06", "R-09", "R-11"]
    assumptions: ["A-05", "A-06", "A-08", "A-11", "A-13", "A-18"]
    dependencies: ["D-01", "D-07", "D-08", "D-11", "D-13"]
    issues: ["I-03", "I-04", "I-06", "I-08"]
    open_questions: ["Q-01", "Q-02", "Q-06", "Q-09"]
  artefacts:
    - "docs/implementation/PH3_SQL_Slice4_Implementation_Work_Package.md"
    - "docs/architecture/PH3_SQL_Remaining_Phase_Architecture.md"
    - "docs/approvals/PH3_SQL_PR8_Test_Authority_Approval.json"
  evidence:
    - "Release build passed."
    - "Focused tests passed: 89 unit and 57 integration."
    - "Full suite passed: 146 unit plus 128 integration equals 274 passed."
    - "Frontend tests passed: 15 tests."
    - "EF pending-model validation, frontend lint, frontend build with 19 routes and git diff check passed."
    - "No SQL Server, production environment or customer data was used; no additional commit, push, merge or deployment was performed for this documentation update."
  decisions:
    - "Browser permissions are a server-derived presentation contract; API policies remain authoritative."
    - "All mutations remain explicit, ETag-aware and non-retrying."
    - "Planning remains human-authored, advisory record data with no execution mapping."
  assumptions:
    - "Formal independent testing will use the exact implementation commit recorded in this package."
  risks:
    - "R-02 remains release-blocking until exact-commit independent browser/API isolation evidence passes."
    - "R-09/R-11 remain open pending supported-browser, SQL Server and online dependency-advisory evidence."
  defects: []
  blockers: []
  approvals:
    - "Named Test Authority approval: ashish50thbirthday-ship-it, 16 September 2026, PR #8 review 5221828015."
  requested_action: "Independently execute the approved consolidated Slices 2-4 test matrix against the exact implementation commit. Do not merge, deploy, access production/customer data or accept residual risk autonomously."
```
