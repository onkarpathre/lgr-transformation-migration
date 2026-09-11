# PH3-SQL-001 Slice 1 - Implementation Work Package

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
    - "Product Owner JP (opathre), 8 September 2026: local POC implementation only, subject to PR restrictions."
    - "Solution Architect/TDA PT (PTArchitect), 8 September 2026: ADR-006 and ADR-007 accepted with conditions for the local/non-production PH3-SQL-001 POC only."
    - "Information Security NTSecurity (nextgenexamprep-crypto), 8 September 2026: ADR-007 accepted with conditions for the local/non-production PH3-SQL-001 POC only."
    - "Solution Architect/TDA PTArchitect, 10 September 2026: ADR-008 and PH3-SQL-ARCH-001 authentication/RBAC amendment approved for local/non-production implementation and testing only."
    - "Information Security nextgenexamprep-crypto, 10 September 2026: ADR-008 controls approved for local/non-production implementation and testing only."
    - "Product Owner opathre, 10 September 2026: exact SQL Inventory role-to-permission mapping confirmed for the same restricted scope."
```

## Frontend dependency vulnerability remediation - 11 September 2026

### Historical Codex-restricted environment attempt

This Developer-owned historical record retains the earlier Codex registry-access failure and blocked disposition. It does not alter the historical Tester decision, claim independent retesting, or supersede Tester evidence for the previously tested implementation commits. The later successful owner-executed remediation and current Developer disposition are recorded immediately after this historical subsection.

### Control and scope

- Developer role: Developer Agent under `AGENTS.md`.
- Requested branch and exact starting commit: clean `feature/ph3-sql-implementation` at `d97f044c2212b1ae1559dc878dc08f58e181a6b8`; branch, `HEAD`, upstream relationship and empty tracked/untracked status were confirmed before editing.
- Approved basis: ADR-006 permits reviewed Next.js 16 lifecycle/security updates and aligned `eslint-config-next` versions for the restricted local/non-production PH3-SQL-001 POC. React and React DOM remain in the approved React 19 family.
- Allowed change: frontend dependency manifests/lockfile and this Developer record only. No Phase 3 application behaviour, database migration, identity/RBAC rule, production configuration, Tester evidence, commit, push, merge or deployment was changed.
- Incoming verified advisory baseline: six npm findings, comprising one critical and five high findings. The directly affected framework is `next@16.2.12`; the other affected packages are `brace-expansion`, `js-yaml`, `nanoid`, `postcss` and `sharp`.

### Dependency analysis and minimum compatible target

`npm explain` was run for every affected package against the unchanged starting lockfile. The minimum controlled remediation plan retains Next.js 16 and React 19, aligns the framework/tooling versions, and uses the patched release in each existing transitive major line rather than forcing an incompatible package major.

| Finding | Starting version and package path | Scope/applicability | Compatible fixed target |
|---|---|---|---|
| `next` - critical | `next@16.2.12`, direct production dependency | Runtime framework; the published critical advisories affect the current version, including the Windows-hosted server path used by local verification. | Pin `next@16.3.4` (patched 16.x floor is 16.3.3; 16.3.4 is the npm-proposed current stable patch). |
| `brace-expansion` - high | `1.1.16` through `eslint@9.39.5 -> minimatch@3.1.5`; `5.0.8` through `eslint-config-next@16.2.11 -> typescript-eslint@8.65.0 -> minimatch@10.2.6` | Development/lint toolchain. Both installed major lines are affected; replacing both with one cross-major override would be unsafe because minimatch 3 expects the 1.x CommonJS contract. | Resolve the existing ranges to `1.1.18` and `5.0.9` respectively. |
| `js-yaml` - high | `4.3.0` through `eslint@9.39.5 -> @eslint/eslintrc@3.3.6` | Development/lint configuration parsing. | Resolve the existing `^4.3.0` range to `4.3.1`. |
| `nanoid` - high | `3.3.16` through `next@16.2.12 -> postcss@8.4.31` | Transitive production/build dependency. | Resolve the existing 3.x range to `3.3.18`. |
| `postcss` - high | `8.4.31` pinned by `next@16.2.12` | Next.js CSS/build pipeline; affected source-map processing remains in the installed tree. | `next@16.3.4` pins patched `postcss@8.5.23`. |
| `sharp` - high | Optional `sharp@0.34.5` through `next@16.2.12` | Next.js image-optimisation runtime dependency; affected when untrusted supported image input is processed. | `next@16.3.4` permits patched `sharp@0.35.4`. |

The aligned direct target is `next@16.3.4`, `eslint-config-next@16.3.4`, `react@19.2.8` and `react-dom@19.2.8`. No React update is required. The new Next.js package contract pins `postcss@8.5.23` and accepts `sharp@^0.35.4`; the existing PostCSS and ESLint dependency ranges admit the named NanoID, js-yaml and brace-expansion patch releases. A lockfile generated by npm is still required to prove the complete resolved graph and integrity values.

### Commands and observed results

| Command/check | Developer result |
|---|---|
| Starting branch, commit and worktree validation | PASS: `feature/ph3-sql-implementation`, exact `d97f044c2212b1ae1559dc878dc08f58e181a6b8`, clean tracked and untracked status. |
| Node/npm versions | Node `v24.18.0`; npm `11.16.0`, consistent with the ADR-006 Node 24 LTS requirement. |
| Manifest/lock inspection | PASS: lockfile version 3; direct pins were Next.js `16.2.12`, React/React DOM `19.2.8`, and `eslint-config-next` `16.2.11`. Affected installed versions and paths are recorded above. |
| `npm audit --audit-level=high` before editing | BLOCKED: npm could not reach `https://registry.npmjs.org/-/npm/v1/security/advisories/bulk` and returned `audit endpoint returned an error`; therefore the incoming six-finding baseline is not represented as a locally refreshed result. |
| `npm explain next brace-expansion js-yaml nanoid postcss sharp` (executed individually) | PASS: every direct/transitive path was resolved and is recorded above. |
| Attempted `npm install --save-exact` after temporarily setting the two aligned direct pins | BLOCKED before lockfile resolution: registry fetch for `eslint-config-next` failed with `EACCES`. Direct `curl` checks to both `registry.npmjs.org:443` and `unpkg.com:443` also failed to connect. The temporary manifest edit was reverted; `package.json`, `package-lock.json` and `node_modules` remain on the starting dependency graph. |
| Post-update `npm audit --audit-level=high` | NOT RUN: no safe resolved update was available to audit. All one critical/five high incoming findings remain unresolved. |
| Post-update lint and frontend production build | NOT RUN: no dependency update was materialised; running against the unchanged tree would not validate the proposed remediation. |
| Complete .NET Release build and unit/integration tests | NOT RUN: no dependency update was materialised; no regression claim is made. The historical Tester result is unchanged. |
| `git diff --check` | PASS, exit 0; no whitespace error. Git emitted line-ending conversion warnings only. |

### Compatibility, residual risk and required decision

- Compatibility impact if the plan is later materialised: a same-major Next.js 16 minor/security update from 16.2.12 to 16.3.4, matching `eslint-config-next` at 16.3.4, PostCSS 8.4 to 8.5, Sharp 0.34 to 0.35, and patch-only updates within the installed brace-expansion 1.x/5.x, js-yaml 4.x and NanoID 3.x lines. React/React DOM remain 19.2.8. No application behaviour change is intended, but lint, production build and complete .NET regression must be rerun against the generated lockfile.
- Residual security risk: the unchanged lockfile retains all six incoming findings (one critical, five high). No finding is suppressed, omitted, downgraded or accepted by this Developer record.
- Required owner/environment action: provide approved npm registry and advisory-endpoint access (or an approved internal mirror containing the exact target packages). Then rerun the explicit update, inspect the resulting graph and lockfile, and execute the complete requested audit/lint/build/test/diff verification before returning to independent Tester review.
- Package files changed by this attempt: none. `src/web/package.json` was restored exactly and `src/web/package-lock.json` was never modified.

### Historical blocked Developer hand-off

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "BLOCKED_IMPLEMENTATION"
  work_item: "PH3-SQL-001-frontend-dependency-remediation"
  branch: "feature/ph3-sql-implementation"
  commit: null
  baseline_commit: "d97f044c2212b1ae1559dc878dc08f58e181a6b8"
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
      - "ADR-006 restricted local/non-production PH3-SQL-001 POC technology baseline and dependency-update conditions."
  artefacts:
    - "docs/implementation/PH3_SQL_Slice1_Implementation_Work_Package.md"
  evidence:
    - "Exact starting branch/commit and clean worktree confirmed."
    - "All six affected dependency paths explained."
    - "Registry, advisory endpoint and CDN connectivity failures captured."
  decisions:
    - "Retain Next.js 16 and React 19; select Next.js/eslint-config-next 16.3.4 and compatible transitive security patches."
    - "Do not fabricate a lockfile, use a cross-major brace-expansion override, suppress findings, or claim verification without installed packages and a successful audit."
  assumptions:
    - "The supplied six-finding baseline accurately describes the unchanged starting lockfile; the local advisory endpoint could not refresh it."
  risks:
    - "One critical and five high npm findings remain in the unchanged lockfile."
    - "The proposed graph has not been installed, built, audited or regression-tested in this environment."
  defects: []
  blockers:
    - "Approved npm registry/advisory access or an approved internal mirror is unavailable."
    - "A generated and verified package-lock.json for the target graph cannot be produced without package metadata and integrity data."
  approvals:
    - "No security-risk acceptance, Tester approval, merge, release or deployment approval is claimed."
  requested_action: "Provide approved registry/advisory access or an approved internal mirror, then return this work to the Developer to materialise the exact dependency plan and run the complete audit, lint, frontend build, .NET build/tests and diff checks before independent retest."
```

### Successful owner-executed remediation and Developer reconciliation

This update supersedes only the historical frontend-remediation blocker above. It does not rewrite that failed attempt, alter Tester evidence, or claim that Codex executed commands that Onkar manually ran in normal PowerShell.

#### Execution and evidence provenance

- Onkar manually ran the controlled package remediation in normal PowerShell because the Codex environment could not access the npm registry. Onkar supplied the successful install, connected audit, frontend build, .NET build/test and EF model-check results below.
- Codex did not execute those manually supplied commands. Codex subsequently inspected the resulting manifest, npm-generated lockfile, installed package metadata and npm debug command records, and ran only safe offline/static reconciliation checks plus frontend lint.
- The npm debug record for the owner-run remediation contains `argv "audit" "fix"`, with no `--force`, and exit code 0. The subsequent connected record contains `argv "audit" "--audit-level" "high"` and exit code 0. No `npm audit fix --force` was run or claimed by Codex, and the resulting dependency graph retains the approved Next.js 16 and React 19 families.

#### Direct versions before and after

| Package | Starting commit `d97f044c...` | Remediated manifest/lock | Disposition |
|---|---:|---:|---|
| `next` | `16.2.12` | `16.3.4` | Approved same-major lifecycle/security update. |
| `eslint-config-next` | `16.2.11` | `16.3.4` | Aligned exactly with Next.js. |
| `react` | `19.2.8` | `19.2.8` | Unchanged; remains in approved React 19 family. |
| `react-dom` | `19.2.8` | `19.2.8` | Unchanged; remains in approved React 19 family. |

#### Resolved affected transitive versions

| Package/path | Starting lockfile | Remediated lockfile |
|---|---:|---:|
| `node_modules/brace-expansion` | `1.1.16` | `1.1.18` |
| `node_modules/@typescript-eslint/typescript-estree/node_modules/brace-expansion` | `5.0.8` | `5.0.9` |
| `node_modules/js-yaml` | `4.3.0` | `4.3.2` |
| `node_modules/nanoid` | `3.3.16` | `3.3.19` |
| `node_modules/postcss` | `8.4.31` | `8.5.23` |
| `node_modules/sharp` | `0.34.5` | `0.35.4` |

The resolved `js-yaml@4.3.2` and `nanoid@3.3.19` are later compatible patches than the minimum targets identified during the failed environment-restricted attempt. Lockfile version 3 is retained. Static checks confirmed the root manifest/lock entries agree, the named package entries contain npm registry URLs and SHA-512 integrity values, and the installed target graph matches the lockfile.

#### Successful normal-PowerShell evidence supplied by Onkar

| Check | Supplied result and provenance |
|---|---|
| Controlled `npm install` | PASS; manually executed by Onkar in normal PowerShell. Next.js and `eslint-config-next` resolved to `16.3.4`. |
| Non-force `npm audit fix` | PASS; manually executed by Onkar. The npm debug record confirms `argv "audit" "fix"` with no `--force`, exit 0. |
| Final connected `npm audit --audit-level high` | PASS; manually executed by Onkar, 0 vulnerabilities, exit 0. The npm debug record independently confirms the command and exit code; the reported zero-vulnerability result is supplied command output. |
| Frontend lint | PASS, exit 0; manually executed by Onkar. Codex also reran `npm.cmd run lint` offline during reconciliation and observed exit 0. |
| Frontend production build | PASS, exit 0; manually executed by Onkar against Next.js `16.3.4`, generating 16 routes. Codex did not rerun this supplied build. |
| .NET Release build | PASS, 0 warnings and 0 errors; manually executed by Onkar. Codex did not rerun this supplied build. |
| Complete .NET tests | PASS, 169/169: 82 unit and 87 integration; manually executed by Onkar. Codex did not rerun these supplied tests. |
| EF Core pending-model check | PASS: no pending model changes; manually executed by Onkar. No migration was applied. Codex did not rerun the supplied EF check. |

#### `unrs-resolver` install-script warning

- `unrs-resolver@1.12.2` is unchanged from the starting lockfile and remains a development-only dependency through `eslint-import-resolver-typescript`. Its lock entry declares a postinstall script.
- Static source inspection shows that the postinstall calls `napi-postinstall` to find the platform-specific native binding and only falls back to npm installation or a registry download when the binding is missing. The installed `@unrs/resolver-binding-win32-x64-msvc@1.12.2` package and its native `.node` file are present.
- npm 11.16 documents the `allowScripts` warning as advisory: unreviewed dependency scripts still run by default in that release, while `npm approve-scripts` records explicit approval. Consequently, this record does not infer whether npm automatically invoked the script during Onkar's completed install.
- No `allowScripts` approval was added, and Codex neither approved nor separately executed the `unrs-resolver` postinstall. There is no demonstrated need to do so: Onkar's lint and 16-route production build passed without adding approval, and the later Codex offline lint check also passed.

#### Reconciliation checks run by Codex

| Check | Developer result |
|---|---|
| Branch/HEAD/current working tree | PASS: `feature/ph3-sql-implementation` at exact starting commit `d97f044c2212b1ae1559dc878dc08f58e181a6b8`; only this work package, `src/web/package.json` and `src/web/package-lock.json` are modified. |
| Manifest/lock JSON and exact-version assertions | PASS: lockfile v3; direct and affected transitive versions match the tables above; registry URLs and SHA-512 integrity values exist; no `allowScripts` field exists. |
| Targeted offline `npm ls` | PASS, exit 0 for Next.js, aligned ESLint config, React/React DOM and every named affected/transitive package. |
| Installed Next.js CLI version | PASS: `Next.js v16.3.4`. |
| Offline frontend lint | PASS, exit 0. No install script was invoked. |
| `src/web/next-env.d.ts` | PASS: no working-tree delta; the generated delta remains restored. |
| `git diff --check` | PASS, exit 0; no whitespace errors. Git emitted only working-copy line-ending conversion warnings. |

#### Compatibility, scope and remaining blocker

- The remediation is confined to the reviewed Next.js 16 dependency graph. It does not change application code, tests, migrations, Tester evidence or `next-env.d.ts`; React and React DOM remain `19.2.8`.
- The connected npm audit disposition is 0 vulnerabilities, exit 0, based on Onkar's manually supplied normal-PowerShell result. No vulnerability is suppressed or accepted, and no force remediation is used.
- The dependency remediation is ready for independent test after owner review and commit binding. The wider SQL Slice 1 still cannot advance to Quality review: I-06/D-11 named test-authority approval and an approved isolated SQL Server runtime are not evidenced, so migration apply/rollback, collation, concurrency, constraint and query-plan assurance remain blocked. No migration was applied.
- Changes remain intentionally uncommitted for owner review. No commit, push, merge, deployment, production/customer-data access or migration action is claimed.

### Current frontend-remediation Developer hand-off

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_TEST"
  work_item: "PH3-SQL-001-frontend-dependency-remediation"
  branch: "feature/ph3-sql-implementation"
  commit: null
  baseline_commit: "d97f044c2212b1ae1559dc878dc08f58e181a6b8"
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
      - "ADR-006 restricted local/non-production PH3-SQL-001 POC technology baseline and dependency-update conditions."
  artefacts:
    - "src/web/package.json"
    - "src/web/package-lock.json"
    - "docs/implementation/PH3_SQL_Slice1_Implementation_Work_Package.md"
  evidence:
    - "Owner-run connected npm audit: 0 vulnerabilities, exit 0."
    - "Owner-run non-force npm audit fix: exit 0; npm debug argv contains no --force."
    - "Owner-run frontend lint/build: exit 0; Next.js 16.3.4 emitted 16 routes."
    - "Owner-run .NET Release build: 0 warnings, 0 errors; tests: 169/169; EF: no pending model changes."
    - "Codex static/offline reconciliation: manifest/lock/version/integrity assertions, targeted npm ls, Next.js version, lint, next-env check and git diff --check all pass."
  decisions:
    - "Retain approved Next.js 16 and React 19 families while applying the resolved compatible security fixes."
    - "Do not add allowScripts approval or separately execute unrs-resolver postinstall without demonstrated need."
  assumptions:
    - "Onkar's manually supplied normal-PowerShell result accurately reports the connected audit output and build/test totals."
  risks:
    - "I-06/D-11 SQL Server runtime and named test-authority evidence remain absent for the wider Slice 1 gate."
    - "R-11 wider production technology/tenancy approval remains unresolved."
  defects: []
  blockers:
    - "Owner review and exact commit binding are required before independent commit-bound retest."
    - "I-06/D-11 named test-authority approval and an approved isolated SQL Server test environment remain required before the wider Slice 1 can advance to Quality review."
  approvals:
    - "No install-script approval, security-risk acceptance, Tester approval, merge, release or deployment approval is claimed."
  requested_action: "Owner to review and bind the three-file remediation to an exact commit, then independent Tester to verify the dependency graph, connected audit evidence and frontend regression. The wider Slice 1 remains blocked from Quality review pending I-06/D-11 SQL Server/test-authority evidence."
```

## Tester Agent independent retest update - 10 September 2026

This is a Tester-owned status update for the exact committed implementation. It does not alter or replace the Developer's historical command evidence or claim Developer/human approval.

- Branch and immutable commit: `feature/ph3-sql-implementation` at `dc31d60303525da7727d92acba455007fd24ef9a`; exact match and clean working tree confirmed before testing.
- Approved architecture baseline: `7f2d6aa12c7f1cffd3d6d9215955bac0b8eca600`; ancestry confirmed.
- Previous implementation baseline: `3650852bb91a8b8ca89a92d1de6ed352b37dde79`; ancestry confirmed.
- Initial committed test run: PASS, 73 unit + 85 integration = 158 passed, 0 failed, 0 skipped.
- Tester-strengthened test run: PASS, 82 unit + 87 integration = 169 passed, 0 failed, 0 skipped.
- Focused current totals: 32 identity/token/principal/permission unit tests; 47 SQL authorization integration tests; 17 SQL Inventory API integration tests; 55 Phase 1/2 regression tests. All pass with zero skipped.
- Role and method result: `DatabaseSme` read/create/update/logical-delete pass for SQL Instances and Databases. `MigrationArchitect`, `ProjectManager`, `DiscoveryAnalyst` and `ReviewerAuditor` read pass and all mutation attempts return `403/permission_denied`. Customer Administrator, Platform Administrator and unknown roles receive no SQL Inventory permission.
- Abuse result: unknown/unauthenticated identities, invalid memberships, cross-customer/project requests, direct-object database and instance attempts, production header injection and app-only/mixed principals fail closed with the approved non-enumerating Problem Details contracts.
- LocalTest result: allow-listed synthetic identities operate in Testing; configuration validation accepts only Development/Testing and production-like LocalTest startup fails. Production-like valid bearer requests cannot be widened by identity, customer, test-principal, role or permission headers. Authentication is evidenced before project authorization.
- Audit result: stable actor, principal type, derived customer/project, UTC time and correlation ID pass; service-account values remain redacted.
- Build/model/frontend result: Release build 0 warnings/0 errors; EF model has no pending changes via global pinned `dotnet-ef 10.0.11`; frontend lint and 16-route production build pass.
- Migration result: `20260910082037_AddInternalPrincipalAuditType` adds only nullable `AuditEvents.ActorPrincipalType nvarchar(20)` and is additive/backward compatible in `Up`. It was inspected and never applied.
- Dependency assurance: NuGet and npm vulnerability advisory calls are blocked by unavailable/denied endpoints; `gitleaks` and `trivy` are not installed. No dependency manifest or lockfile changed in the ADR-008 delta.
- Defect disposition: PH3SQL-TST-001, PH3SQL-TST-002, PH3SQL-TST-003 and PH3SQL-TST-004 are independently closed for the exact restricted local/non-production commit. No new application defect was found.
- Remaining blockers: I-06/D-11 named test-authority approval and an approved isolated SQL Server runtime; connected dependency-advisory evidence; Identity Platform/deployed membership confirmation; Q-06/Q-09 and all production/tenancy/customer-data/Service Transition/release decisions.
- Tester gate: `BLOCKED`, not `READY_FOR_QUALITY_REVIEW` and not `RETURN_TO_DEVELOPER`, because no implementation defect remains but mandatory environment/human evidence is unavailable.

The authoritative current-run details and exact commit-bound hand-off are in `docs/implementation/PH3_SQL_Slice1_Test_Evidence_Pack.md`. The statement in the historical Developer section below that the evidence pack was unmodified was accurate when that Developer evidence was authored; it is superseded by this Tester update.

## ADR-008 Developer remediation update - 10 September 2026

This section supersedes the 9 September Developer remediation status for PH3SQL-TST-002. The historical Developer and Tester records retained later in this package remain evidence of the earlier state; `PH3_SQL_Slice1_Test_Evidence_Pack.md` was not modified.

Post-reboot recovery verification found the requested branch still at exact baseline `3650852bb91a8b8ca89a92d1de6ed352b37dde79` with the same 16 tracked modifications and six untracked implementation files. The recovered `InternalPrincipal`, LocalTest configuration, authorization tests and `20260910082037_AddInternalPrincipalAuditType` migration were preserved in place; duplicate-type and duplicate-migration inspection found no second implementation. The historical Tester evidence hash still matches `HEAD`. All current Developer checks below were rerun against this recovered working tree on 10 September 2026.

### Implemented authorization contract

- Microsoft Entra mode validates signed v2 access tokens against an exact configured HTTPS issuer, API audience and OpenID signing keys, requires matching `tid`, immutable `oid`, `sub`, allow-listed `azp` and appropriate delegated `scp`, and denies app-only or mixed human/workload identity on interactive SQL routes.
- Authentication constructs the immutable application-owned `InternalPrincipal`. The request-scoped project authorization context is created only from a server-side membership result and contains the derived customer, selected project, frozen role/permission sets and membership version.
- The fallback policy requires an authenticated internal human with active project membership. `/health` is the sole reviewed anonymous endpoint and returns no identity, tenant or dependency detail.
- `SqlInventoryRead`, `SqlInventoryCreate`, `SqlInventoryUpdate` and `SqlInventoryDelete` are applied to every SQL Instance and SQL Database action. `DatabaseSme` receives all four permissions; `MigrationArchitect`, `ProjectManager`, `DiscoveryAnalyst` and `ReviewerAuditor` receive read only; all other roles deny.
- Missing, inactive, disabled, expired, not-yet-valid or cross-scope membership returns `404/resource_not_found`; an active member lacking a required permission returns `403/permission_denied`; absent/invalid authentication returns `401/authentication_required`; membership-authority failure returns `503/authorization_unavailable`; missing/malformed project selection returns the approved safe 400 codes.
- LocalTest is usable only in exact Development/Testing environments, accepts only configured synthetic aliases, and obtains customer/project/roles only from server-side fixtures. Any other environment fails startup if LocalTest is selected or required Entra settings are missing. Production-like tests prove identity/customer/user/role/permission headers cannot grant access and bearer failure never falls back.
- Existing customer query filters, explicit project predicates, same-owner relationship validation, composite constraints and the default-off `SqlDiscoveryAssessment` feature filter remain in force. Authentication runs before authorization, which runs before MVC feature filters.
- SQL mutation audit rows now carry the canonical stable actor, `ActorPrincipalType`, derived customer/project, UTC time and correlation ID. Operational access logging uses only stable IDs, route templates, method, status and correlation; it does not log bearer tokens, header values or SQL inventory names.

### Current Developer checks

| Command/check | Observed result |
|---|---|
| Branch/starting-point validation | PASS: clean `feature/ph3-sql-implementation` at exact commit `3650852bb91a8b8ca89a92d1de6ed352b37dde79` before editing. Changes remain intentionally uncommitted and unpushed. |
| `dotnet restore LgrTransformationMigration.sln` | PASS; all projects up to date. No dependency version changed. |
| Release build with `--no-restore` | PASS; 0 warnings, 0 errors. |
| Complete solution tests with `--no-build --no-restore` | PASS; 73 unit + 85 integration = 158 passed, 0 failed, 0 skipped. |
| Focused ADR-008 unit tests | PASS; 23 passed, 0 failed, 0 skipped. Covers permission mapping plus Entra signature, signing key, issuer, audience, lifetime, version, tenant, object ID, client, scope and workload/human claim handling. |
| Focused SQL authorization integration tests | PASS; 45 passed, 0 failed, 0 skipped. Covers both resource types, all methods/roles, membership lifecycle, isolation/injection, safe errors, revocation, production guards, stable audit actor and fallback policy. |
| Explicit Phase 1/2 regression | PASS; 32 unit + 23 integration = 55 passed, 0 failed, 0 skipped. |
| Pinned `dotnet-ef 10.0.11 migrations has-pending-model-changes` | PASS: `No changes have been made to the model since the last migration.` |
| Generated ADR-008 migration delta | PASS: one nullable `ALTER TABLE [AuditEvents] ADD [ActorPrincipalType] nvarchar(20) NULL`; no other operation. Generated/inspected only; not applied. |
| Frontend `npm.cmd run lint` / `npm.cmd run build` | PASS; lint exit 0 and Next.js 16.2.12 production build exit 0 with 16 routes. Build-only `next-env.d.ts` output was restored. |
| Scoped whitespace verification / `git diff --check` | PASS for ADR-008 code/tests; no whitespace errors. Existing line-ending notices only. |
| Scoped credential-pattern inspection | PASS; no credential/private-key pattern in new identity configuration/code/tests. `gitleaks` and `trivy` are not installed. |
| NuGet/npm vulnerability advisory queries | BLOCKED by denied outbound advisory endpoints. Existing packages restored and no package reference changed; no clean connected-feed assertion is made. |

### Defect disposition

| Defect | Developer disposition | Remaining action |
|---|---|---|
| PH3SQL-TST-001 | REMEDIATED | Work is on the requested feature branch and exact starting point; the working tree is intentionally uncommitted by instruction. |
| PH3SQL-TST-002 | IMPLEMENTED; Developer verification PASS | Independent Tester must retest the exact future implementation commit. R-02 remains open until that evidence exists. |
| PH3SQL-TST-003 | REMEDIATED and preserved; full suite PASS | Independent regression remains required. |
| PH3SQL-TST-004 | REMEDIATED and preserved; full suite PASS | Default-off/local-only feature behavior remains subject to independent regression. |

### Current Developer hand-off

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "READY_FOR_TEST"
  work_item: "PH3-SQL-001-slice-1-remediation-PH3SQL-TST-002"
  branch: "feature/ph3-sql-implementation"
  commit: null
  baseline_commit: "3650852bb91a8b8ca89a92d1de6ed352b37dde79"
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
      - "Solution Architect/TDA PTArchitect, 10 September 2026: ADR-008 restricted local/non-production implementation and testing."
      - "Information Security nextgenexamprep-crypto, 10 September 2026: ADR-008 restricted local/non-production controls."
      - "Product Owner opathre, 10 September 2026: exact SQL Inventory role mapping for the restricted scope."
  artefacts:
    - "docs/implementation/PH3_SQL_Slice1_Implementation_Work_Package.md"
    - "src/api/Infrastructure/IdentityAuthorization.cs"
    - "src/api/Infrastructure/Migrations/20260910082037_AddInternalPrincipalAuditType.cs"
    - "tests/api.unit/IdentityAuthorizationTests.cs"
    - "tests/api.integration/SqlInventoryAuthorizationTests.cs"
  evidence:
    - "Release build: 0 warnings, 0 errors."
    - "Complete solution suite: 158 passed, 0 failed, 0 skipped."
    - "Focused ADR-008: 23 unit and 45 integration tests passed."
    - "Phase 1/2 regression: 55 passed, 0 failed, 0 skipped."
    - "EF pending-model validation: no pending model changes."
    - "Migration delta: one nullable audit principal-type column; no database action."
    - "Historical Tester evidence pack preserved unchanged."
  decisions:
    - "Implement ADR-008 through Entra bearer validation plus an application-owned immutable principal and server-side membership interfaces."
    - "Use configuration-backed allow-listed synthetic LocalTest fixtures only in Development/Testing; fail closed elsewhere."
    - "Add only the nullable audit principal-type column required for ADR-008 audit evidence; do not add production membership persistence or administration."
  assumptions:
    - "Only synthetic identities and data were used."
    - "The explicit no-commit instruction means this READY_FOR_TEST working tree is not yet commit-bound."
  risks:
    - "R-02 remains open pending independent authorization/isolation abuse testing."
    - "R-09/I-06 SQL Server runtime and named test-authority evidence remain absent."
    - "R-11 wider production technology/tenancy approval remains unresolved."
  defects:
    - "PH3SQL-TST-001 REMEDIATED"
    - "PH3SQL-TST-002 IMPLEMENTED; DEVELOPER PASS; INDEPENDENT RETEST REQUIRED"
    - "PH3SQL-TST-003 REMEDIATED; DEVELOPER PASS"
    - "PH3SQL-TST-004 REMEDIATED; DEVELOPER PASS"
  blockers:
    - "A permitted repository owner must bind this uncommitted working tree to an exact commit before commit-bound independent Tester evidence can be issued."
    - "Identity Platform configuration confirmation remains required before Entra mode is used in any deployed environment."
    - "I-06/D-11 named test-authority approval and approved isolated SQL Server runtime evidence remain required."
    - "NuGet/npm connected vulnerability-feed evidence remains unavailable."
    - "Q-06/Q-09, production identity, persistent membership administration, production tenancy, customer data, deployment, Service Transition and human release approval remain blocked."
  approvals:
    - "Restricted local/non-production Product Owner, Solution Architect/TDA and Information Security approvals evidenced in ADR-008/PH3-SQL-ARCH-001."
    - "No Identity Platform, named test-authority, PRB, production-tenancy, DPO, Service Transition or release approval is claimed."
  requested_action: "After an authorised repository owner binds this working tree to an exact commit without changing it, the independent Tester should retest PH3SQL-TST-002 against that commit, preserve the existing Test Evidence Pack as historical evidence, and issue a new evidence record. No merge, deployment or production action follows."
```

## Control and outcome

- Work item: `PH3-SQL-001`, development slice 1.
- Architecture package: `PH3-SQL-ARCH-001`.
- Approved starting baseline: `main` commit `5d3e9b02bc57989d79ee47a133ab35ad4a31d3f8`; verified before editing.
- ADR-008 remediation starting point: clean `feature/ph3-sql-implementation` at exact commit `3650852bb91a8b8ca89a92d1de6ed352b37dde79`; branch, commit and clean status verified before editing on 10 September 2026.
- Implementation state: `READY_FOR_TEST` for implementable ADR-008 local/non-production requirements; independent Tester and downstream human evidence remain outstanding.
- Branch/commit: `feature/ph3-sql-implementation`; the implementation is intentionally uncommitted on starting commit `3650852bb91a8b8ca89a92d1de6ed352b37dde79` because the authorised instruction prohibits committing or pushing. No commit-bound independent-test claim is made.
- Authority: restricted local/non-production POC only. No merge, migration application, deployment, production data, customer data, Azure provisioning, migration execution or AI action was performed.

The current source changes implement ADR-008 for the bounded SQL Instance and SQL Database inventory slice: Microsoft Entra bearer-token validation architecture for internal users, an immutable application-owned `InternalPrincipal`, server-side project membership resolution, deny-by-default fallback authorization, exact named SQL Inventory policies, safe authorization Problem Details, LocalTest production guards and synthetic Development/Testing identities. PH3SQL-TST-002 is implemented and Developer verification passes, but remains open until independent Tester retest against a future exact implementation commit. Vulnerability-feed evidence, I-06/D-11 test-authority approval and approved isolated SQL Server runtime evidence remain unavailable. Developer command results are observations, not independent test-authority acceptance.

## Requirements implemented

| Requirement | Implementation and developer evidence | Scope status |
|---|---|---|
| SQL-PO-001, SQL-PO-002, SQL-PO-005, SQL-AC-001 | Versioned REST create, retrieve, update, logical delete and bounded list endpoints for instances and databases; default page size 50, maximum 200; filters by search, parent and status; model validation; Problem Details; ETag/`If-Match` concurrency. | Implemented for slice 1 |
| SQL-PO-003, SQL-PO-004, SQL-AC-002 | Required same-owner Server-to-Instance and Instance-to-Database relationships; tenant-leading composite alternate keys and foreign keys; active-name uniqueness within each parent. | Implemented for slice 1 |
| SQL-PO-015, SQL-AC-008 | ADR-008 Entra/LocalTest authentication creates only an application-owned typed principal; server-side membership derives CustomerId from the untrusted selected ProjectId; fallback and named read/create/update/delete policies enforce the exact role matrix before existing tenant/project predicates and composite constraints execute. Client identity/customer/role/permission headers confer no authority. | Implemented for restricted local/non-production Slice 1; independent retest outstanding |
| SQL-PO-016, SQL-AC-009 | Significant create, field update, relationship change and archive operations append scoped audit events with actor, UTC time, correlation ID and redacted sensitive values. | Implemented for slice 1 |
| SQL-PO-017 | DTO-only versioned controllers, validation, typed service layer, stable safe error codes and correlation IDs. Automatic validation, feature denial, authentication and authorization failures return the complete approved Problem Details members. | Implemented for Slice 1 |
| SQL-PO-019, SQL-AC-011 | Synthetic integration scenario creates 205 instances and 205 databases and verifies bounded paging and filters. | Automated command observed; formal test authority outstanding |
| SQL-PO-020, SQL-AC-014 | No database-migration execution, DMS orchestration, remediation, AI inference or Azure provisioning path was added. | Implemented as an exclusion |
| SQL-PO-021, SQL-AC-015 | Optional manual service-account display metadata rejects credential-like/multiline values; audit changes are redacted. It is not part of an import contract. | Implemented for manual slice-1 CRUD only |
| SQL-AC-012 | Existing backend tests and frontend lint/build were re-run after the slice. | Command results below; formal clean-feed/test-authority acceptance outstanding |

SQL-PO-006 through SQL-PO-014, SQL-PO-018 and SQL-PO-022 are not claimed by this slice. CSV upload/reconciliation/history, assessment and browser journeys remain later slices and require their applicable approvals. SQL-AC-003 through SQL-AC-007, SQL-AC-010 and full SQL-AC-013/015 are correspondingly excluded.

## Behaviour and security controls

- `SqlInstance` is owned by `CustomerId`/`ProjectId` and must reference one `Server` with the identical ownership tuple.
- `SqlDatabase` is owned by `CustomerId`/`ProjectId` and must reference one `SqlInstance` with the identical ownership tuple.
- Names are trimmed, Unicode NFC-normalised and invariant-uppercase-normalised for uniqueness. Default-instance aliases normalise to `MSSQLSERVER`.
- Active instances are unique by `(CustomerId, ProjectId, ServerId, NormalizedName)`; active databases are unique by `(CustomerId, ProjectId, SqlInstanceId, NormalizedName)`.
- Query filters enforce current-customer visibility and logical deletion; every service query also binds the current project.
- Every API endpoint is protected by an authenticated-human plus active-project-membership fallback policy except the explicitly anonymous, data-free `/health` probe. SQL Instance and SQL Database actions additionally require named read/create/update/delete permission policies.
- Entra mode validates signature, signing key, exact issuer/audience/lifetime and maps only validated `tid`, `oid`, `sub`, `azp`, `ver`, delegated `scp` and workload `roles` semantics. Human SQL routes require `lgr.access` and an allowed client; app-only or mixed human/workload callers are denied.
- `X-Project-Id` is only an untrusted selector. The server-side membership provider derives CustomerId, roles, permissions and membership version. Missing/inactive/expired/not-yet-valid membership returns non-enumerating 404; an active member without permission receives 403; unavailable authorization returns 503.
- LocalTest accepts only exact synthetic allow-listed aliases in Development/Testing. Every other environment requires complete Entra configuration and fails startup if LocalTest is selected. Client-supplied customer, user, principal, role and permission headers are ignored as authority and removed outside local/test.
- Stable canonical actor identifiers, principal type, server-derived customer/project scope, UTC time and correlation ID are recorded for mutations. Authorized operational access logs use principal/scope, route template, method, status and correlation only.
- `SqlDiscoveryAssessment` defaults to `false`. SQL Instance and SQL Database controllers are exposed only when the flag is explicitly enabled and the host is `Development` or `Testing`; disabled access returns a non-enumerating 404 Problem Details response before service execution.
- Database port, database size and compatibility level have database check constraints as well as request validation.
- Parent deletes are restricted: an active Server cannot be archived while it owns an active SQL Instance, and an active instance cannot be archived while it owns an active database.
- Updates and deletes require an opaque `If-Match` token. Missing and stale tokens fail with 428 and 412 respectively without mutation.
- Client payloads contain relationship identifiers only; customer/project, normalised values, audit values, logical-delete values, import ownership and version tokens are server controlled.
- SQL Server uses database-generated rowversion values; the SQLite integration provider uses application-generated opaque versions without weakening SQL Server configuration.

## Files changed

### Application

- `src/api/Domain/SqlInventoryEntities.cs` - SQL Instance and SQL Database aggregates.
- `src/api/Domain/SqlInventoryRules.cs` - normalisation, controlled values and sensitive-display-name validation.
- `src/api/Domain/Entities.cs` - Server navigation and audit correlation identifier.
- `src/api/Contracts/SqlInventoryDtos.cs` - versioned request/response/page contracts and validation.
- `src/api/Services/SqlInventoryService.cs` - tenant/project-scoped CRUD, filtering, relationship validation, concurrency and audit behaviour.
- `src/api/Controllers/SqlInventoryControllers.cs` - `/api/v1/sql-instances` and `/api/v1/sql-databases` endpoints with the SQL discovery/assessment feature gate applied to both Slice 1 controllers.
- `src/api/Infrastructure/AppDbContext.cs` - DbSets, ownership keys, query filters, constraints, indexes and relationships.
- `src/api/Infrastructure/TenantContext.cs` - correlation context and non-development fail-closed behaviour.
- `src/api/Infrastructure/ApiExceptionHandler.cs` - safe 400/404/409/412/428 Problem Details mappings.
- `src/api/Infrastructure/IdentityAuthorization.cs` - ADR-008 authentication options/validation, Microsoft Entra access-token validation, immutable principal and authorization context, synthetic LocalTest identity/membership authority, exact SQL permissions, policy handlers, safe authorization results, prohibited-header handling and access telemetry.
- `src/api/Infrastructure/SqlDiscoveryAssessmentFeatureFilter.cs` - default-off feature options and local/test-only SQL route gate.
- `src/api/Services/ProgrammeService.cs` - prevent logical deletion of Servers with active SQL Instances and include audit correlation IDs.
- `src/api/Program.cs` - scoped inventory service registration, feature-gate registration and complete automatic validation Problem Details.
- `src/api/appsettings.json` - default `SqlDiscoveryAssessment` value of `false`.
- `src/api/appsettings.Development.json` - explicit approved local-development enablement.
- `src/api/appsettings.Testing.json` - explicit automated-test enablement.
- `src/api/appsettings.LocalTest.json` - Development/Testing-only allow-listed synthetic principals and server-side memberships; not loaded outside those environments.

### Database

- `src/api/Infrastructure/Migrations/20260909164944_AddSqlInventory.cs`.
- `src/api/Infrastructure/Migrations/20260909164944_AddSqlInventory.Designer.cs`.
- `src/api/Infrastructure/Migrations/AppDbContextModelSnapshot.cs`.
- `src/api/Infrastructure/Migrations/20260910082037_AddInternalPrincipalAuditType.cs`.
- `src/api/Infrastructure/Migrations/20260910082037_AddInternalPrincipalAuditType.Designer.cs`.

### Tests and evidence

- `tests/api.unit/SqlInventoryRulesTests.cs`.
- `tests/api.integration/SqlInventoryApiTests.cs` - Tester-owned validation contract preserved unchanged; remediation adds default-off/no-mutation feature-gate coverage. Existing direct-object, cross-customer, cross-project and mismatched-context tests remain in place and pass.
- `tests/api.integration/LgrWebApplicationFactory.cs` - deterministic synthetic cross-customer/cross-project fixtures.
- `tests/api.unit/IdentityAuthorizationTests.cs` - exact role/permission union, Entra signature/issuer/audience/lifetime/claim/principal mapping and human/workload API-access validation.
- `tests/api.integration/SqlInventoryAuthorizationTests.cs` - full SQL route role/method matrix, membership lifecycle, safe errors, injection/isolation, revocation, LocalTest and production-like controls, stable audit actor and fallback-policy coverage.
- `docs/implementation/PH3_SQL_Slice1_Implementation_Work_Package.md` - this package.

## Migration and compatibility

Migration `20260909164944_AddSqlInventory` is additive. Its `Up` operation:

1. Adds nullable `CorrelationId` to `AuditEvents`.
2. Adds tenant-leading alternate keys needed as composite principals to `Projects`, `Servers` and `ImportBatches`.
3. Creates `SqlInstances` and `SqlDatabases` with ownership, audit, provenance, logical-delete and rowversion columns.
4. Adds tenant-leading composite parent/project/import foreign keys with restrictive delete behaviour.
5. Adds filtered active-name unique indexes, lookup indexes and value-range check constraints.

The migration was generated and its SQL/script/model-drift output was inspected. It was not applied to any database and no production or customer data was read or modified. The normal generated `Down` method is reserved for explicitly authorised disposable development environments; rollback for a deployed expand-first release should first disable/revert application use while retaining the additive schema until a separately reviewed cleanup change.

ADR-008 remediation adds migration `20260910082037_AddInternalPrincipalAuditType`. Its `Up` operation adds only nullable `AuditEvents.ActorPrincipalType nvarchar(20)` so new audit events can record the required principal type while historical rows remain valid. The generated delta contains no other operation. It was not applied to a database. The LocalTest membership implementation is configuration-backed and introduces no principal/membership persistence or administration schema; production membership persistence remains a separately governed work item.

## Commands executed and results

| Command/check | Observed result |
|---|---|
| `git rev-parse HEAD` / baseline status | Exact baseline `5d3e9b02bc57989d79ee47a133ab35ad4a31d3f8`; initially clean. |
| Baseline `dotnet test LgrTransformationMigration.sln --configuration Release --no-build --no-restore` | Exit 0: 32 unit and 23 integration tests. |
| `git switch -c feature/ph3-sql-inventory-slice-1` | Failed: permission denied writing `.git/refs`; no branch or commit created. |
| Cached EF CLI `migrations add AddSqlInventory` | Exit 0; migration above generated. |
| Cached EF CLI idempotent migration script generation | Exit 0; script inspected only, not executed. |
| Cached EF CLI `migrations has-pending-model-changes` | Exit 0: no pending model changes. |
| Cached EF CLI migration list with no connection | Exit 0: initial, discovery-import and SQL-inventory migrations listed. |
| Additive-operation inspection | No `DropTable`, `DropColumn`, `Rename*`, `AlterColumn`, `DeleteData` or `UpdateData` call in `Up`. |
| External `dotnet tool restore`, clean solution restore and vulnerability query | Blocked by NuGet service-index/socket access. The clean restore failed with `NU1301`; the vulnerability query could not produce evidence. |
| `dotnet restore ... --source C:\\Users\\onkar\\.nuget\\packages` | Exit 0 using exact locally cached archives; no dependency versions changed and no external source was used. |
| Final Release build with `--no-restore` | Exit 0; 0 warnings and 0 errors. |
| Final unit test assembly with `--no-build --no-restore` | Exit 0: 50 executed, 0 failed, 0 skipped. |
| Final integration test assembly with `--no-build --no-restore` | Exit 0: 37 executed, 0 failed, 0 skipped. |
| `npm.cmd run lint` | Exit 0. |
| `npm.cmd run build` | Exit 0; Next.js production build emitted 16 routes. |
| Scoped `dotnet format whitespace --verify-no-changes` for slice files | Exit 0. Full-repository format verification reports pre-existing baseline whitespace debt in unrelated files. |
| `git diff --check` | No whitespace errors; Git emitted line-ending conversion warnings only. |
| Remediation branch/commit validation | PASS: clean starting point was `feature/ph3-sql-implementation` at `4c61979e941974d05009727f3ad7959b372f71c1`; `abd466a014aebcfe02b0f72e4322328df12e203a` is contained by that branch. Remediation remains uncommitted by instruction. |
| Remediation `dotnet restore LgrTransformationMigration.sln` | PASS, exit 0; all projects up to date. |
| Remediation Release build with `--no-restore` | PASS, exit 0; 0 warnings and 0 errors. |
| Remediation complete solution tests with `--no-build --no-restore` | PASS, exit 0; 50 unit and 40 integration tests passed, 0 failed, 0 skipped, 90 total. |
| Focused `SqlInventoryApiTests` | PASS, exit 0; 17 passed, 0 failed, 0 skipped. The preserved Tester validation test plus the new complete-value and disabled-feature tests pass. |
| Repository-manifest `dotnet ef migrations has-pending-model-changes` | Tool unavailable; command requested `dotnet tool restore`. No tool restore or database action was attempted. |
| Pinned global `dotnet-ef 10.0.11 migrations has-pending-model-changes` | PASS, exit 0: `No changes have been made to the model since the last migration.` No migration was applied and no database was accessed. |
| Scoped remediation `dotnet format ... whitespace --verify-no-changes` | PASS, exit 0. |
| Remediation vulnerability query | BLOCKED: NuGet service index/socket access to `api.nuget.org:443` is forbidden; no dependency was added or changed. |
| Remediation `git diff --check` | PASS; no whitespace errors, only line-ending conversion warnings. |

Because external NuGet access is blocked, these raw cached-package command results must not be represented as a clean connected-feed, vulnerability-scanned or formally accepted test success.

## Test coverage added

- Valid instance/database CRUD, filtering and parent changes.
- Missing and stale ETag preconditions with no mutation.
- Duplicate names after normalisation; identical names allowed under different parents.
- Missing, cross-customer and cross-project relationship rejection.
- Cross-customer/project list, detail, update, delete and direct-object enumeration attempts.
- Mismatched customer/project context fails closed.
- Audit evidence for creates, field changes, relationship moves and archives; service-account values remain redacted.
- Server/instance parent-delete restrictions.
- Invalid port, compatibility, controlled status/recovery and credential-like service-account metadata.
- 205-instance and 205-database bounded-paging/filter scenarios.
- Physical composite-FK rejection, EF model metadata, filtered uniqueness and synthetic ownership preflight.
- SQL Server provider create-script assertions for rowversion, composite foreign keys and filtered indexes without opening or mutating a SQL Server database.
- Complete automatic model-validation Problem Details member/value and media-type coverage, preserving the Tester-authored failing test without deletion or weakening.
- Default-off feature behaviour for read/write SQL routes, including non-enumerating 404 Problem Details and proof that a disabled create request does not mutate SQL inventory.
- Existing cross-customer, same-customer/cross-project, mismatched-context, relationship and direct-object protection tests remain unchanged and pass.

## Unresolved risks and blockers

1. **PH3SQL-TST-002 independent closure:** ADR-008 is implemented for the restricted scope and Developer automation passes. The high defect remains open until the independent Tester retests the full authorization/abuse matrix against an exact future implementation commit. This working tree is intentionally uncommitted by instruction, so Developer evidence is not commit-bound Tester evidence.
2. **Identity Platform and production membership authority:** no real Entra tenant, app registration, Conditional Access/MFA setting or deployed identity configuration was created. The Entra adapter is implemented and fails startup on incomplete non-local configuration; non-local membership fails closed until a separately approved persistent provider is supplied. Identity Platform approval remains mandatory before deployed Entra use.
3. **Dependency advisory evidence:** NuGet and npm advisory endpoints are inaccessible in this environment. Restore/build/tests use the existing dependency graph and no package reference changed, but connected vulnerability evidence remains unavailable.
4. **I-06/D-11 and SQL Server runtime evidence:** named test-authority approval and an approved isolated SQL Server test database were not supplied. Generated SQL Server DDL and the additive delta were inspected, but runtime apply/rollback, collation, concurrency, constraint and query-plan evidence remain to be independently produced. No migration was applied.
5. **Production and external-access governance:** Q-06/Q-09, production tenancy/HLD DD-05 reconciliation, PRB, production Information Security, Service Transition and human release approvals remain open. This implementation is not authorised for external customer access, production identity/tenancy, customer data, deployment or release.
6. CSV/source-contract, discovery history, assessment and browser work are excluded from slice 1 and must not be inferred from these APIs.

## Original Developer hand-off (historical; superseded by remediation status below)

```yaml
handoff:
  from_agent: "developer"
  to_agent: "tester"
  state: "BLOCKED_IMPLEMENTATION"
  work_item: "PH3-SQL-001-slice-1"
  branch: null
  commit: null
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-02", "C-03", "C-04", "C-06"]
    functional_requirements: ["F-03", "F-04", "F-05", "F-07", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-04", "NF-05", "NF-06", "NF-08", "NF-09", "NF-10", "NF-11", "NF-12", "NF-13"]
    risks: ["R-01", "R-02", "R-03", "R-06", "R-09", "R-11"]
    assumptions: ["A-01", "A-02", "A-05", "A-06", "A-08", "A-11", "A-13", "A-15", "A-16", "A-18"]
    dependencies: ["D-01", "D-03", "D-04", "D-05", "D-07", "D-08", "D-10", "D-11", "D-13"]
    issues: ["I-01", "I-02", "I-03", "I-04", "I-06", "I-08"]
    open_questions: ["Q-01", "Q-02", "Q-06", "Q-09"]
    approvals:
      - "PO local-POC implementation approval, 8 September 2026"
      - "ADR-006/ADR-007 conditional local-POC approvals, 8 September 2026"
  artefacts:
    - "docs/implementation/PH3_SQL_Slice1_Implementation_Work_Package.md"
    - "src/api/Infrastructure/Migrations/20260909164944_AddSqlInventory.cs"
    - "tests/api.unit/SqlInventoryRulesTests.cs"
    - "tests/api.integration/SqlInventoryApiTests.cs"
  evidence:
    - "Cached-package Release build: exit 0, 0 warnings, 0 errors"
    - "Cached-package unit command: exit 0, 50 executed, 0 failed"
    - "Cached-package integration command: exit 0, 37 executed, 0 failed"
    - "Frontend lint and production build: exit 0"
    - "EF model drift check: no pending model changes"
    - "Migration Up additive-operation inspection: no destructive operations"
  decisions:
    - "Use accepted .NET 10/EF Core 10 modular-monolith baseline."
    - "Use ADR-007 shared database/shared schema only for this restricted local/non-production POC."
    - "Keep CSV, assessment, browser and production identity/tenancy outside slice 1."
  assumptions:
    - "Only synthetic test identities and data were used."
    - "A named authority will supply the approved test environment and exact branch/commit before independent execution."
  risks:
    - "R-02 tenant isolation requires independent abuse testing."
    - "R-09/I-06 SQL Server-specific runtime and migration behaviour is not yet proven against an approved SQL Server test database."
    - "R-11 wider production technology/tenancy approval remains unresolved."
  defects: []
  blockers:
    - "Workspace denied creation of the required feature branch; changes are uncommitted on baseline main."
    - "External NuGet restore and vulnerability evidence are blocked."
    - "I-06/D-11 test-authority approval and an approved isolated SQL Server test environment are not evidenced."
  approvals:
    - "Product Owner local-POC implementation approval evidenced."
    - "Solution Architect/TDA ADR-006 and ADR-007 conditional local-POC approvals evidenced."
    - "Information Security ADR-007 conditional local-POC approval evidenced."
    - "PRB, test authority, production tenancy, DPO, service transition and release approvals not evidenced."
  requested_action: "Do not accept this package as READY_FOR_TEST. After a human/platform owner provides a writable working branch, restores approved NuGet/vulnerability access, records I-06/D-11 test authority and supplies an isolated SQL Server test environment, bind the unchanged implementation to an exact commit and independently prove CRUD, direct-object/cross-tenant/cross-project isolation, composite database constraints, duplicate-name concurrency, ETag concurrency, audit redaction, 200+ paging, migration apply/rollback and regression before returning PASS or RETURN_TO_DEVELOPER."
```

## Tester Agent evidence update - 9 September 2026

The independent test record is `docs/implementation/PH3_SQL_Slice1_Test_Evidence_Pack.md`.

- Implementation commit tested: `abd466a014aebcfe02b0f72e4322328df12e203a`.
- Comparison baseline: `5d3e9b02bc57989d79ee47a133ab35ad4a31d3f8`.
- Branch discrepancy: the tested commit exists only on local `main`; requested branch `feature/ph3-sql-implementation` remains at the baseline and contains no Slice 1 implementation.
- Restore: PASS for all three solution projects.
- Release build: PASS, 0 warnings and 0 errors.
- Committed tests: PASS, 87/87 (50 unit, 37 integration).
- Tester-strengthened tests: FAIL, 87 passed and 1 failed of 88; the failing test proves automatic DTO validation omits four mandatory Problem Details members.
- Phase 1/2 regression: PASS, 55/55 (32 unit, 23 integration).
- EF pending-model-change validation: PASS with pinned EF CLI 10.0.11.
- Phase 3 delta migration inspection: no destructive schema or data operation; SQL Server runtime migration/provider validation remains blocked and unevidenced.
- Exact Tester state: `BLOCKED` / `RETURN_TO_DEVELOPER`; not `READY_FOR_QUALITY_REVIEW`.

Open defects are PH3SQL-TST-001 (branch/handoff mismatch), PH3SQL-TST-002 (missing authenticated/project-role authorisation policy), PH3SQL-TST-003 (incomplete DTO-validation Problem Details) and PH3SQL-TST-004 (missing architecture-required default-off feature toggle). Mandatory SQL Server runtime evidence, I-06/D-11 test-authority approval and dependency vulnerability-feed evidence remain blocked. The original Developer hand-off state therefore remains `BLOCKED_IMPLEMENTATION`; this Tester update does not rewrite it or invent a Developer/human approval.

## Developer remediation update - 9 September 2026

This update records Developer remediation performed from the user-specified clean starting point `feature/ph3-sql-implementation` at `4c61979e941974d05009727f3ad7959b372f71c1`. Changes remain uncommitted as instructed, so the commit identifies the exact starting tree rather than claiming that the remediation is commit-bound.

| Defect | Developer disposition | Evidence / remaining action |
|---|---|---|
| PH3SQL-TST-001 | REMEDIATED for branch placement; hand-off updated | `HEAD`, the feature branch and `origin/feature/ph3-sql-implementation` were all `4c61979e941974d05009727f3ad7959b372f71c1` before editing; that commit contains the Tester evidence and descends from Slice 1 implementation commit `abd466a014aebcfe02b0f72e4322328df12e203a`. The remediation worktree is deliberately not committed or pushed. |
| PH3SQL-TST-002 | `NEEDS_ARCHITECTURE_DECISION`; not remediated | The approved package requires project-role authorisation but provides no approved internal authentication/membership contract or role-to-permission mapping. The Developer did not invent role names, trust a caller-supplied role header or implement an unapproved identity design. Solution Architect/TDA and Information Security must supply the contract listed in blocker 1 above. Permitted/rejected project-role tests are consequently blocked; existing record-level cross-tenant/cross-project tests pass but are not represented as RBAC evidence. |
| PH3SQL-TST-003 | REMEDIATED; Developer verification PASS | Automatic `[ApiController]` model-validation failures now return `ValidationProblemDetails` with `type`, `status`, `title`, safe `detail`, request `instance`, `errorCode`, `correlationId` and field `errors`. The Tester-added `Dto_validation_returns_the_approved_problem_details_contract` test was not deleted, skipped, relaxed or rewritten and now passes. |
| PH3SQL-TST-004 | REMEDIATED; Developer verification PASS | `SqlDiscoveryAssessment` defaults to `false`, is explicitly enabled only by Development and Testing configuration, and is additionally denied outside those environments. Both SQL controllers are gated; disabled reads/writes return non-enumerating 404 Problem Details before service execution. The new automated test proves disabled read/write behaviour and no create mutation; the existing SQL suite proves explicit Testing enablement. |

**Developer gate recommendation:** `NEEDS_ARCHITECTURE_DECISION`. Do not return this work to independent test or advance it to Quality Manager until PH3SQL-TST-002 has an approved architecture/Information Security contract and its authentication, membership and permitted/rejected role tests are implemented. SQL Server runtime, I-06/D-11 test-authority and vulnerability-feed evidence also remain mandatory external blockers for later acceptance.

```yaml
handoff:
  from_agent: "developer"
  to_agent: "architect"
  state: "NEEDS_ARCHITECTURE_DECISION"
  work_item: "PH3-SQL-001-slice-1-remediation"
  branch: "feature/ph3-sql-implementation"
  commit: "4c61979e941974d05009727f3ad7959b372f71c1 (clean remediation starting commit; working-tree remediation intentionally uncommitted by instruction)"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-02", "C-03", "C-04", "C-06"]
    functional_requirements: ["F-03", "F-04", "F-05", "F-07", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-04", "NF-05", "NF-06", "NF-08", "NF-09", "NF-10", "NF-11", "NF-12", "NF-13"]
    risks: ["R-01", "R-02", "R-03", "R-06", "R-09", "R-11"]
    assumptions: ["A-01", "A-02", "A-05", "A-06", "A-08", "A-11", "A-13", "A-15", "A-16", "A-18"]
    dependencies: ["D-01", "D-03", "D-04", "D-05", "D-07", "D-08", "D-10", "D-11", "D-13"]
    issues: ["I-01", "I-02", "I-03", "I-04", "I-06", "I-08"]
    open_questions: ["Q-01", "Q-02", "Q-06", "Q-09"]
    approvals:
      - "PO local-POC implementation approval, 8 September 2026"
      - "ADR-006/ADR-007 conditional local-POC approvals, 8 September 2026"
  artefacts:
    - "docs/implementation/PH3_SQL_Slice1_Implementation_Work_Package.md"
    - "src/api/Program.cs"
    - "src/api/Infrastructure/SqlDiscoveryAssessmentFeatureFilter.cs"
    - "src/api/Controllers/SqlInventoryControllers.cs"
    - "src/api/appsettings.json"
    - "src/api/appsettings.Development.json"
    - "src/api/appsettings.Testing.json"
    - "tests/api.integration/SqlInventoryApiTests.cs"
  evidence:
    - "Branch placement: feature/ph3-sql-implementation at 4c61979e941974d05009727f3ad7959b372f71c1; Slice 1 commit abd466a is an ancestor"
    - "dotnet restore: exit 0"
    - "Release build: exit 0, 0 warnings, 0 errors"
    - "Complete solution tests: 90 passed, 0 failed, 0 skipped (50 unit, 40 integration)"
    - "Focused SqlInventoryApiTests: 17 passed, 0 failed, 0 skipped"
    - "Pinned dotnet-ef 10.0.11 pending-model check: no pending model changes"
    - "No migration was applied and no database was accessed or mutated"
  decisions:
    - "Preserve the approved default-off feature-toggle and complete safe-error contracts."
    - "Do not invent an internal identity, membership, project-role or role-to-permission design."
  assumptions:
    - "Only repository synthetic test identities and data were used."
  risks:
    - "R-02 remains open until authenticated membership and project-role policy are approved, implemented and independently abused-tested."
    - "R-09/I-06 SQL Server runtime evidence remains absent."
    - "R-11 wider production technology/tenancy approval remains unresolved."
  defects:
    - "PH3SQL-TST-001 REMEDIATED"
    - "PH3SQL-TST-002 NEEDS_ARCHITECTURE_DECISION"
    - "PH3SQL-TST-003 REMEDIATED; Developer tests pass"
    - "PH3SQL-TST-004 REMEDIATED; Developer tests pass"
  blockers:
    - "Solution Architect/TDA and Information Security must approve the internal authentication scheme, server-side project-membership authority/data contract, principal claims, applicable PH3 role subset, role-to-permission matrix for read and inventory-edit, trusted local/test principal fixture, denial semantics and audit actor contract."
    - "NuGet vulnerability advisory feed is inaccessible."
    - "I-06/D-11 test-authority approval and an approved isolated SQL Server test environment are not evidenced."
    - "Q-09 and production tenancy/release gates remain open."
  approvals:
    - "Product Owner local-POC implementation approval evidenced."
    - "Solution Architect/TDA ADR-006 and ADR-007 conditional local-POC approvals evidenced."
    - "Information Security ADR-007 conditional local-POC approval evidenced."
    - "No project-role identity contract, test authority, PRB, production tenancy, DPO, service transition or release approval is claimed."
  requested_action: "Solution Architect/TDA and Information Security must issue the precise internal authentication, project-membership and role-to-permission contract needed for PH3SQL-TST-002; then return to the Developer for implementation and permitted/rejected project-role tests before independent retest."
```
