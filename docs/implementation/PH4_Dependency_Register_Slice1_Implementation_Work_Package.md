# Phase 4 Dependency Register Slice 1 Implementation Work Package

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-03", "C-05", "C-09"]
  functional_requirements: ["F-04", "F-05", "F-06", "F-10", "F-11", "F-15"]
  non_functional_requirements: ["NF-01", "NF-02", "NF-04", "NF-06", "NF-08", "NF-09", "NF-10", "NF-11"]
  risks: ["R-01", "R-02", "R-03", "R-06", "R-07", "R-09"]
  assumptions: ["A-02", "A-06", "A-07", "A-08", "A-11", "A-13", "A-18"]
  dependencies: ["D-01", "D-04", "D-08", "D-11", "D-13"]
  issues: ["I-04", "I-06", "I-07", "I-08"]
  open_questions: ["Q-01", "Q-02", "Q-09"]
  approvals:
    - "Product/PRB approval by opathre, 22 September 2026, bound to 985099c2ec05e3307bdc770af4a97e6e28df8c6e."
    - "Independent TDA/Q-01 approval by PTArchitect, 22 September 2026, bound to 985099c2ec05e3307bdc770af4a97e6e28df8c6e."
    - "Information Security approval by ashish50thbirthday-ship-it, 22 September 2026, bound to 985099c2ec05e3307bdc770af4a97e6e28df8c6e."
    - "Dependency-Semantics SME approval by nextgenexamprep-crypto, 22 September 2026, bound to 985099c2ec05e3307bdc770af4a97e6e28df8c6e."
    - "Test Services approval by nextgenexamprep-crypto, 22 September 2026, bound to 985099c2ec05e3307bdc770af4a97e6e28df8c6e."
```

## Control and implementation state

- **Role:** Developer under `AGENTS.md`.
- **Work item:** `PH4-DEP-001`, ordered Slice 1 only.
- **Branch:** `feature/ph4-dependency-register-implementation`.
- **Exact adopted baseline:** `bb2e0f741d913fb1c5b7740171a14dcfe7e2e0fc`.
- **Approved architecture evidence:** `docs/approvals/PH4_Architecture_Approval_Evidence.json`, five required decisions bound to `985099c2ec05e3307bdc770af4a97e6e28df8c6e`.
- **Repair baseline:** committed candidate `ae71b3a76801cf5982d9acd339486413249a653a` on `feature/ph4-dependency-register-implementation`.
- **Implementation commit:** `null`; the user expressly prohibited commit, push and merge. The repaired working tree remains uncommitted and formal Tester evidence must bind it to a later human-created candidate commit before quality review.
- **Scope:** restricted local/non-production development using synthetic data only.
- **Developer state:** `READY_FOR_RETEST` subject to the independent evidence boundaries below.

Q-01 and Q-02 are closed only for the approved restricted Phase 4 scope. Q-09 remains open and production/external customer identity is not used. No other open gate affects this local synthetic implementation.

## Implemented Slice 1 behaviour

- Added directed dependency records whose source is exactly one in-project Application, Server, SQL Instance or SQL Database and whose target is one canonical asset or controlled named reference.
- Added inert FileShare, Api and ExternalSystem named references with explicit Unresolved/Resolved state. Labels are stored and displayed only; no path, URL or external system is opened, mounted, probed or called.
- Enforced the approved eight dependency types and source/target matrix, Mandatory/Advisory criticality, separate Unconfirmed/Confirmed state and immutable endpoints.
- Added bounded project list, detail, both-direction asset retrieval, search and controlled filters; default page size is 50 and the API caps it at 200. Unsupported filter/query keys return `validation_failed` rather than being ignored or translated to dynamic SQL.
- Added authorised create, edit, confirm/unconfirm and logical archive operations. Dependency/reference writes advance the project graph version transactionally.
- Added `If-Match` handling for update, confirmation and archive: missing preconditions return 428 and stale versions return 412 without silent retry.
- Added significant-action audit events with server-derived actor, UTC timestamp, customer/project, principal type and correlation ID. Narrative values are not copied to audit rows or logs.
- Added safe DTO-only responses with server-derived display names and inventory routes. Cross-project/customer and missing IDs share non-enumerating 404 behaviour.
- Added the exact ADR-008 `dependency.read`, `dependency.manage`, `dependency.confirm`, `dependency.validate` and `dependency.audit.read` permission family, role matrix, additive session capabilities and direct-route server enforcement.
- Added a default-off `Features:DependencyRegister` gate. It is enabled only in Development and Testing settings and never widens authorization.
- Added dependency list, create, detail and affected-asset browser routes with explicit “Depends on” direction, permission-aware actions, loading/error/empty states, form labels, confirmation/archive controls and stale-write messaging.
- Added a repository development pin for Node.js `24.18.0`; CI already pins Node `24.x`. No package version or dependency changed.

## Persistence and migration

- Added `DependencyReference`, `Dependency`, `DependencyPolicy`, `DependencyPolicyRule` and `DependencyGraphState` entities with explicit customer/project ownership.
- Added composite owner FKs to every canonical endpoint/reference, Restrict delete behaviour, endpoint XOR and controlled-value checks, confirmation coherence and no-self constraints.
- Added persisted SQL Server endpoint keys, active duplicate uniqueness, active reference-name uniqueness, forward/reverse/list/validation indexes, active-policy uniqueness and rowversion concurrency.
- Added the additive `AddDependencyRegister` EF migration and updated the model snapshot. `Up` creates only Slice 1 structures plus the Application owner alternate key; it performs a fail-fast duplicate precondition before that key.
- The migration creates one graph state and active v1 policy/rule set for every existing project and the normal project-create path creates the same foundation for future projects.
- Empty project deletion removes its unused dependency foundation; a project or inventory asset with dependency evidence fails safely rather than losing history.
- `Down` removes only the new dependency structures and the new Application alternate key. The migration was not applied to any database.
- Validation-run/finding tables are deliberately absent; those belong to Slice 2.

## Security, privacy and tenant isolation

- Customer/project context continues to come from authenticated active membership under ADR-008; request headers do not confer customer, role, permission, actor or audit authority.
- Every dependency/reference read, mutation, duplicate check, audit query and endpoint resolution uses the active customer/project scope in addition to EF query filters.
- Workload tokens, disabled/expired memberships and unknown/platform/customer-administrator roles receive no dependency permissions. Multi-role union remains server-derived.
- Include-archived access requires `dependency.audit.read` in addition to route read access.
- Unicode input is NFC-normalised and trimmed. Length, control-character, markup, private-key, password, connection-secret, bearer/JWT and SAS-like content is rejected before persistence.
- Synthetic fixtures only are provided in `tests/TestData/dependencies/slice1-fixture-manifest.json`; no customer or production data was accessed.
- No migration execution, Azure provisioning, network/DNS/firewall change, direct discovery API, external-reference I/O, AI or multi-cloud behaviour was added.

## API and browser artefacts

API routes implemented:

- `GET|POST /api/v1/dependency-references`
- `GET|PUT|DELETE /api/v1/dependency-references/{id}`
- `GET|POST /api/v1/dependencies`
- `GET|PUT|DELETE /api/v1/dependencies/{id}`
- `PUT /api/v1/dependencies/{id}/confirmation`
- `GET /api/v1/dependencies/{id}/audit`

Browser routes implemented:

- `/planning/dependencies`
- `/planning/dependencies/new`
- `/planning/dependencies/[id]`
- `/planning/dependencies/assets/[assetType]/[assetId]`

The Slice 2 validation route and all Slice 3 wave/readiness projections, panels and validation-dependent embedded browser integration remain absent by design.

## Developer tests and synthetic fixtures

- Domain tests cover controlled values, full allowed/denied endpoint-type matrix, normalization, unsafe narrative rejection and ETag parsing.
- Authorization tests cover every approved role/permission cell, unknown roles, workload principals and permission union.
- Integration tests cover feature fail-closed behaviour, canonical/reference lifecycle, both directions, audit redaction, ETags, reference state, missing/self/duplicate/cross-scope rejection, pagination/filter validation, unknown query rejection, role enforcement, capability response, graph increments and new-project policy/state creation.
- The versioned Slice 1 fixture manifest records positive, reference, negative, isolation, concurrency and RBAC scenarios and explicitly excludes later-slice cycle, validation, wave/readiness and timing outcomes.

## Tester-return repair

The three Slice 1 defects in the Tester evidence pack were reproduced against committed candidate `ae71b3a76801cf5982d9acd339486413249a653a` before implementation changes:

- `PH4-S1-DEF-01`: the strengthened domain test accepted `https://example.test/dependency`, and the integration path returned `201 Created` rather than `400 validation_failed`.
- `PH4-S1-DEF-02`: the disabled dependency route returned the approved non-enumerating `404 feature_disabled`, but the authenticated session response still contained the server-derived `dependency.*` permission family.
- `PH4-S1-DEF-03`: the Tester-owned browser contract found no permission-aware dependency entry link on the approved application, server, SQL instance or SQL database surfaces.

The bounded repair:

- rejects case-insensitive `http://` and `https://` schemes in every dependency narrative processed by `DependencyText` before persistence; the existing exception handler retains the approved `400 validation_failed` contract and the strengthened API test proves no partial dependency write;
- retains ADR-008 role-to-permission derivation and all route authorization policies, but omits every `dependency.*` permission from `/api/v1/session/capabilities` whenever `Features:DependencyRegister` is not enabled in the allowed Development/Testing environments;
- adds `dependency.read`-guarded links from application and server inventory rows and SQL instance/database detail actions to the existing bounded both-direction asset dependency route. Because the capability response removes dependency permissions when the feature is off, the same guard hides these links for both permission denial and feature disablement; and
- changes no persistence model, migration, permission matrix, route authorization, dependency semantics, later-slice validation/wave behaviour, package manifest or test artefact.

Before repair, the six uncommitted Tester-owned artefacts were inventoried and SHA-256 hashed. They were used as acceptance coverage but were not modified, deleted, staged or renamed. Their exact hashes are included in the hand-off evidence below.

## Developer verification

| Check | Result |
|---|---|
| Release solution build after repair | PASS: 0 errors; 3 `NU1900` warnings because the NuGet advisory service was unreachable. |
| Focused dependency unit tests after repair | PASS: 33 passed, 0 failed/skipped, including all strengthened URL cases. |
| Focused dependency API integration tests after repair | PASS: 17 passed, 0 failed/skipped, including feature-off capability filtering and URL rejection without partial persistence. |
| Complete original plus strengthened .NET regression after repair | PASS: 178 unit + 145 integration = 323 passed, 0 failed/skipped. |
| EF pending-model validation after repair | PASS using pinned global `dotnet-ef` 10.0.11: no changes since the last migration. No migration was applied and no database was accessed. |
| Frontend lint | PASS. |
| Frontend component and Tester contract tests after repair | PASS: 6 files, 22 tests, 0 failed/skipped. The jsdom canvas notice is retained from `axe-core`; the application does not require canvas. |
| Next.js 16.3.4 production build | PASS: 21 generated pages and all four Slice 1 dependency routes. |
| Node runtime/pinning | PASS: local `v24.18.0`, `.nvmrc` `24.18.0`, CI `24.x`. |
| Targeted whitespace format verification | PASS for all new backend and test source files. |
| EF migration runtime rehearsal | NOT RUN: read-only connection preflight to the available local SQL Express instances failed before querying with `Cannot generate SSPI context`. No database was created, changed or deleted. |
| NuGet vulnerability report | NOT AVAILABLE: `api.nuget.org` was unreachable under network policy; no clean-vulnerability claim is made. |
| npm high-severity audit | NOT AVAILABLE: the npm advisory endpoint was unreachable; no clean-vulnerability claim is made. |
| Dedicated secret scanner | NOT AVAILABLE: neither `gitleaks` nor `trufflehog` is installed. Repository/diff pattern and product-boundary checks were used only as developer diagnostics, not as replacement release evidence. |
| Final Git controls | PASS: branch and `HEAD` remain at the requested candidate; no staged changes; `git diff --check` reports no whitespace errors; changed-path review is confined to six repaired source files, this Developer-owned work package and the six preserved Tester-owned artefacts. |
| Tester artefact preservation | PASS: all six final SHA-256 hashes exactly match the hashes recorded before repair; no Tester-owned artefact is staged. |

## Compatibility, deployment and rollback

- Existing Phase 1-3 tests remain green and existing contracts are unchanged except for the approved additive `dependency.*` session-capability family.
- Non-production order is schema migration, compatible application deployment with `DependencyRegister` off, smoke/isolation checks, then explicit Slice 1 flag enablement. No startup migration application was introduced.
- Application rollback is data-preserving: disable `DependencyRegister` and return to the preceding compatible application build. Database rollback requires a separately approved disposable/non-production rehearsal; it must not be executed where dependency evidence must be retained.
- No commit, push, PR, merge, deployment, shared-database migration or production/customer access was performed.

## Independent evidence still required

- Tester must bind all formal evidence to one candidate commit after a human creates it, then independently execute the approved Slice 1 matrix.
- Disposable SQL Server migration Up/provider-constraint/Down-reapply, FK Restrict and simultaneous-write behaviour remain mandatory Tester evidence because the available local SQL connection could not authenticate.
- Online NuGet/npm vulnerability checks and an approved secret/static scan remain required before Quality approval; unavailable evidence is not a pass.
- Independent Chrome/Edge keyboard, focus, zoom/reflow and contrast checks remain required at the applicable consolidated browser gate.
- No agent accepts the residual evidence risk, approves release, merges or deploys.

## Hand-off

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_RETEST"
  work_item: "PH4-DEP-001-SLICE-1"
  branch: "feature/ph4-dependency-register-implementation"
  commit: null
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-03", "C-05", "C-09"]
    functional_requirements: ["F-04", "F-05", "F-06", "F-10", "F-11", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-04", "NF-06", "NF-08", "NF-09", "NF-10", "NF-11"]
    risks: ["R-01", "R-02", "R-03", "R-06", "R-07", "R-09"]
    assumptions: ["A-02", "A-06", "A-07", "A-08", "A-11", "A-13", "A-18"]
    dependencies: ["D-01", "D-04", "D-08", "D-11", "D-13"]
    issues: ["I-04", "I-06", "I-07", "I-08"]
    open_questions: ["Q-01", "Q-02", "Q-09"]
  artefacts:
    - "docs/implementation/PH4_Dependency_Register_Slice1_Implementation_Work_Package.md"
    - "src/api/Controllers/SessionController.cs"
    - "src/api/Domain/DependencyRules.cs"
    - "src/web/app/inventory/applications/page.tsx"
    - "src/web/app/inventory/servers/page.tsx"
    - "src/web/app/inventory/sql-instances/[id]/page.tsx"
    - "src/web/app/inventory/sql-databases/[id]/page.tsx"
  evidence:
    - "Release build passed with 0 errors and 3 NU1900 advisory-feed warnings."
    - "Focused dependency lanes passed: 33 unit and 17 integration."
    - "Full original plus strengthened .NET suites passed: 178 unit and 145 integration, 323 total."
    - "Pinned EF 10.0.11 pending-model check, frontend lint, 22 frontend tests, 21-page frontend production build and final Git checks passed."
    - "Tester SHA-256 preservation: evidence pack 5a9fd04fcbf3763a4775d7daeb590402baac3e80519082575522ff70d72e9902; browser contract ae82d914f9601b54642fb6fa0de3764699bffc948cba184a7671f3a36303232b; integration tests 5b733c260764696e902683027cd65b36f1fbb08240cc02a9e12fa85f0fb4a567; unit tests 8b53cf65ebb26fcf44528b1d310c78fefa8f02b3df0ab005c9b69d248dc5c0c0; SQL harness b1192179014a1afa719e1ca86e1f6aedf40489230b41aa01b0fa2e1f45631831; fixture manifest 9d4eb2d96b027b4af54c3ecde7d320976ed55dc42ad9f93396145e0959211186."
    - "SQL Server was not accessed and the Tester SQL assurance harness was not run; vulnerability feeds and disposable SQL Server runtime evidence remain unavailable and are not claimed as passing."
  decisions:
    - "Only ordered Slice 1 dependency capture is implemented; later-slice validation and planning projections are absent."
    - "Named references remain inert human planning records."
    - "Feature gating is not authorization; ADR-008 server policies remain authoritative."
    - "Session capability filtering and UI hiding do not widen authorization or alter the approved dependency role matrix."
  assumptions:
    - "A human will create the candidate commit before formal same-commit Tester evidence is recorded."
  risks:
    - "R-02 and R-09 remain subject to independent exact-commit tenant/concurrency and SQL Server provider evidence."
    - "Dependency vulnerability and dedicated secret-scan status remain unknown until approved connected checks run."
  defects:
    - "PH4-S1-DEF-01 corrected; pending independent retest."
    - "PH4-S1-DEF-02 corrected; pending independent retest."
    - "PH4-S1-DEF-03 corrected; pending independent retest."
  blockers: []
  approvals:
    - "Five retained Phase 4 approvals in docs/approvals/PH4_Architecture_Approval_Evidence.json, bound to 985099c2ec05e3307bdc770af4a97e6e28df8c6e."
  requested_action: "Create an exact repaired candidate commit under human control, then independently rerun the approved Slice 1 test contract, including the preserved strengthened tests and a fresh authorised SQL Server assurance run when available. Do not test later slices, merge, deploy, use customer/production data or accept residual risk autonomously."
```
