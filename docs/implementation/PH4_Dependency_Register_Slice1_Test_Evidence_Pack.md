# Phase 4 Dependency Register Slice 1 Test Evidence Pack

Status: **READY_FOR_QUALITY_REVIEW**

Assessment date: 23 September 2026

Tester role: **Tester Agent under `AGENTS.md`**

Candidate branch: `feature/ph4-dependency-register-implementation`

Candidate commit: `d57239c0f5b79eb1f6da50a9b288c8cea7425a97`

Approved implementation baseline: `bb2e0f741d913fb1c5b7740171a14dcfe7e2e0fc`

Work item: `PH4-DEP-001-SLICE-1`

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
    - "Product/PRB, independent TDA/Q-01, Information Security, Dependency-Semantics SME and Test Services approvals retained in docs/approvals/PH4_Architecture_Approval_Evidence.json and bound to 985099c2ec05e3307bdc770af4a97e6e28df8c6e."
    - "Temporary development risk acceptance by ashish50thbirthday-ship-it, Information Security / Human Risk Owner, submitted 2026-09-23T12:00:45Z on PR #10 and bound to d57239c0f5b79eb1f6da50a9b288c8cea7425a97; expires 23 October 2026."
```

## 1. Independent scope and controls

The branch and candidate commit were re-verified before reconciliation. `HEAD` and PR #10 both resolve to exact candidate `d57239c0f5b79eb1f6da50a9b288c8cea7425a97`; the commit is the repair child of `ae71b3a76801cf5982d9acd339486413249a653a` and a descendant of approved implementation baseline `bb2e0f741d913fb1c5b7740171a14dcfe7e2e0fc`. The worktree contains only the six existing Tester-owned artefacts listed in the hand-off. No application source, dependency file, immutable SQL result, customer data, commit, push, merge, deployment, Azure resource or later-slice behaviour was changed by the Tester.

The retained Phase 4 approval file contains all five required decisions. Test Services expressly authorises Tester-owned regression tests, synthetic fixtures and fail-closed assurance harnesses against fresh isolated local SQL Server databases that are never automatically deleted.

The following Tester-owned changes were then made without changing application behaviour:

- strengthened unit and API rejection tests for plain URLs;
- strengthened feature-off capability evidence;
- added an NFC-equivalent reference-name duplicate test;
- added dependency browser route/asset-entry contract tests;
- strengthened the synthetic fixture manifest; and
- added `tests/sqlserver/PH4_Dependency_Register_Slice1_Assurance.ps1`.

Slice 2 validation/cycle evidence and Slice 3 wave/readiness, scale and interactive-browser exit evidence were not started.

The Developer repair at the exact candidate addresses the three previously reproduced Slice 1 defects: plain URL narrative rejection, feature-off dependency-capability filtering, and permission-aware dependency links on all four approved asset surfaces. The Tester independently reran the complete .NET and frontend suites against that repaired commit; all strengthened tests now pass.

## 2. Requirements-to-test matrix

| Requirement | Independent evidence | Result |
|---|---|---|
| AC-01; C-03/C-05; F-04/F-06 | Four canonical source types, canonical/reference targets, allowed matrix and create routes exercised by focused unit/API suites. | PASS for implemented positive paths. |
| AC-02; F-06/F-15; NF-04 | Controlled values, NFC normalization, markup, URL and secret-shaped content tests at domain and API boundaries. | PASS: URL and sensitive narrative inputs reject without partial mutation. |
| AC-03; NF-02/NF-08 | Bounded list defaults/caps, filters, both direction queries, detail DTOs, asset route contract and all four approved asset entry surfaces. | PASS. |
| AC-04/AC-05; F-15; NF-01/NF-02; R-02 | Missing, self, active duplicate, cross-project and cross-customer API tests; non-enumerating errors; composite-FK SQL Server evidence. | PASS at API/SQLite and authorised SQL Server provider assurance. |
| AC-09; NF-04/NF-06 | Create/update/confirm/unconfirm/archive audit actions, server-derived actor/correlation and redacted narrative evidence. | PASS in integration tests. |
| AC-10; NF-01/NF-02/NF-11 | Exact ADR-008 role matrix unit tests, route policy inspection, capability response and feature-off assertion. | PASS: disabled route fails closed and dependency capabilities are absent. |
| AC-11; NF-10; R-09 | If-Match success/missing/stale API tests plus SQL rowversion and simultaneous-write assurance. | PASS at API/SQLite and authorised SQL Server provider assurance. |
| AC-13; NF-10 | Complete repaired .NET/frontend regression, lint and Next.js production build. | PASS. |
| AC-14; product boundaries | Changed-source scan for network/process/filesystem/Azure/AI/automatic migration paths; named references inspected as inert labels. | PASS static inspection. |
| Slice 1 browser contract | Four routes, central API wrapper, bounded requests, explicit direction labels, permission-aware actions and asset entry links, If-Match and stale messaging. | PASS: 22/22 frontend tests. |
| Additive migration | Migration/source/snapshot review, EF model agreement, provider constraints, concurrency, Down/reapply and final migration history. | PASS: authorised OwnerRun03 completed with zero defects and retained the database fully migrated. |
| Synthetic fixtures | Manifest parses, declares synthetic-local-test-only and contains positive/reference/negative/isolation/concurrency/RBAC cases. | PASS after Tester strengthens URL expectation. |

## 3. Execution results

Historical logs and TRX files for the original candidate remain under ignored path `TestResults/PH4_Slice1_ae71b3a/`. They are retained as defect-reproduction evidence and are not represented as the repaired candidate result. The following reconciliation results were obtained against exact application commit `d57239c0f5b79eb1f6da50a9b288c8cea7425a97` with the six Tester-owned artefacts present.

| Check | Result |
|---|---|
| Exact branch/commit/baseline ancestry | PASS: branch `feature/ph4-dependency-register-implementation`; local `HEAD` and PR #10 head are exact `d57239c...`; ancestry is `bb2e0f7...` -> `ae71b3a...` -> `d57239c...`. |
| Candidate repair diff check | PASS: `git diff --check ae71b3a... d57239c...`. |
| Complete repaired .NET regression | PASS: 178 unit + 145 integration = 323/323; exit code 0. |
| EF pending-model validation | PASS with pinned `dotnet-ef 10.0.11`: no changes since the latest migration. |
| Generated migration scripts | PASS: Up and Down generation; transaction, fail-fast duplicate check, persisted computed keys, rowversion, filtered indexes, Restrict FKs, table/key removal and history update inspected. |
| Frontend component and Tester contract suite | PASS: 6 files, 22/22 tests; retained jsdom canvas notice only. |
| Frontend lint | PASS; exit code 0. |
| Next.js 16.3.4 production build | PASS: 21 pages including all four Slice 1 dependency routes; exit code 0. |
| Whole-solution `dotnet format --verify-no-changes` diagnostic | NOT PASS: the repository-wide command reports whitespace in seven existing compact-style files. It reports no new dependency controller/service/domain file and no Tester-changed dependency test file. No agreed repository-wide formatter baseline was found, so this is retained as diagnostic evidence rather than a separate Slice 1 defect. |
| Tester strengthened URL, capability, NFC and asset-link assertions | PASS in the complete repaired suites. |
| Authorised SQL Server OwnerRun03 | PASS; exit code 0; zero defects; exact candidate; database left fully migrated and not automatically deleted. Immutable evidence: `TestResults/PH4_Dependency_Register_Slice1_SQL_20260923T102609731Z/result.json`, SHA-256 `781ECB8A39102E2B09E8E018B1A11B315A19672372E7FC37EB95591E07F45476`. |
| Connected .NET package vulnerability checks | PASS: all three .NET projects report no vulnerable packages from the connected source; exit code 0. |
| Connected npm audit | **NOT PASS:** exit code 1; two moderate findings for `GHSA-82fw-gwwq-j7x9` through `vitest` / `@vitest/mocker` 4.1.10. The patched version is 4.1.11, but installation/verification was blocked by npm registry `EACCES` / `ENOTFOUND`. |
| Dedicated secret/static scanner | UNAVAILABLE: `gitleaks`, `trufflehog`, `detect-secrets`, `git-secrets` and `semgrep` are not installed. |
| Redacted secret-shaped scan of changed files | PASS as diagnostic only: matches are confined to synthetic rejection tests; no credential value was found or printed. |
| Prohibited-I/O scan of changed application source | PASS as diagnostic: no network client, process execution, filesystem I/O, Azure SDK, AI/model or automatic migration-execution call was found. |

## 4. Defect reconciliation

Open recorded defects for the reconciled Slice 1 candidate: **0**.

The three entries below are retained only as historical reproduction records. Each is **CLOSED / independently retested PASS** at `d57239c0f5b79eb1f6da50a9b288c8cea7425a97`; their original failing logs remain historical evidence and are not relabelled as passing runs.

### PH4-S1-DEF-01 — Plain URLs are accepted in dependency narrative

- Severity: Medium
- Traceability: AC-02; F-06/F-15; NF-04; approved write-validation rules; explicit Tester instruction.
- Reproduction: create a dependency with description `https://example.test/dependency`.
- Expected: `400 validation_failed`, no dependency/audit/graph mutation.
- Actual: `201 Created`; the domain rule throws no validation exception.
- Evidence: `DependencyRulesTests.Narrative_rejects_markup_urls_and_secret_like_content` and `DependencyRegisterApiTests.Missing_self_duplicate_invalid_matrix_and_sensitive_text_are_rejected_without_partial_writes`.
- Resolution: CLOSED; domain and API URL-rejection assertions pass in the repaired 323-test .NET regression.

### PH4-S1-DEF-02 — Feature-off state still advertises dependency capabilities

- Severity: Medium
- Traceability: AC-10; NF-11; architecture sections 11, 15 and 17.1.
- Reproduction: set `Features:DependencyRegister=false`, authenticate as Migration Architect, call the dependency list and session capabilities.
- Expected: dependency route is unavailable and browser capability data does not expose the disabled dependency journey.
- Actual: route returns safe `404 feature_disabled`, but capabilities still contain `dependency.read`, `dependency.manage`, `dependency.confirm`, `dependency.validate` and `dependency.audit.read`; AppShell uses those permissions to expose navigation.
- Security disposition: no authorization bypass or cross-tenant disclosure was observed; the defect is feature-gate/UI consistency.
- Resolution: CLOSED; feature-off capability filtering passes in the repaired integration regression.

### PH4-S1-DEF-03 — Approved asset surfaces do not link to dependency views

- Severity: Medium
- Traceability: AC-03; architecture section 11 line 416; Slice 1 browser journey.
- Expected: application/server inventory rows and SQL instance/database detail pages show a permission-aware Dependencies link/count when `dependency.read` is present.
- Actual: the asset dependency route exists, but none of the four approved asset surfaces contains `dependency.read` handling or a `/planning/dependencies/assets/...` link.
- Evidence: `TesterDependencyBrowserJourneyContracts.test.tsx`; 21/22 frontend tests passed and this contract failed.
- Resolution: CLOSED; all four asset-surface entry contracts pass in the repaired 22-test frontend suite.

## 5. Provider-specific OwnerRun01/OwnerRun02 history and OwnerRun03 result

This dated OwnerRun01 addendum supersedes only the earlier SQL-provider blocker statements in sections 2 and 3; those entries remain as historical evidence for the prior candidate and run.

At exact application commit `d57239c0f5b79eb1f6da50a9b288c8cea7425a97`, authorised OwnerRun01 passed the exact branch/worktree, retained approval, pinned EF tool, local SQL Express identity, fresh-database, preceding-migration and Slice 1 migration-Up gates. It then failed before schema evidence was recorded with `Cannot convert DBNull to System.Int32`.

The immutable failed result remains at `TestResults/PH4_Dependency_Register_Slice1_SQL_20260923T085128085Z/result.json` with SHA-256 `C72CB4EB78518E6DC6BB7EC5E5BEFC009E2230652193A56D8AF171279F6AAC7A`. OwnerRun01 and its retained database must not be reused, changed or deleted.

Static diagnosis identified the harness defect in the first schema-metadata query after migration Up. `COLUMNPROPERTY(object_id, [name], 'IsPersisted')` used an unsupported property and returned SQL `NULL`; the evidence projection then forced that `DBNull` to `System.Int32`. The repaired query reads `sys.computed_columns.is_persisted`. A left join deliberately returns SQL `NULL` for the non-computed `RowVersion` column, while both computed endpoint-key rows must return non-NULL `is_persisted = 1` or the harness fails closed.

Every remaining post-Up query was inspected. Migration IDs and `COUNT_BIG` expressions are non-null and retain their existing exact assertions; computed endpoint keys, rowversion length and rowversion scalar are required non-null evidence; `CHECKSUM_AGG` is the only other legitimately nullable expression and is now accepted as `NULL` only when its matching table count is zero, otherwise it fails closed. The constraint, composite-isolation, simultaneous-write, stale-rowversion, Down, reapply, non-deletion and final-history gates remain in place.

Authorised OwnerRun02 used the required fresh database `LgrTransformationMigration_PH4_Slice1_Assurance_d57239c_OwnerRun02`. It passed the exact branch/worktree, retained approval, pinned EF tool, local SQL Express identity, fresh-database, preceding-migration and Slice 1 migration-Up gates. Its retained EF output proves the applied DDL created `SourceEndpointKey` and `TargetEndpointKey` with `AS ... PERSISTED`, the endpoint `CHECK` constraints, and the filtered unique active-endpoint index. The run then failed at the combined harness assertion `is_computed = 1 AND is_persisted = 1 AND is_nullable = 0` with `SourceEndpointKey is not persisted, computed and non-null.`

The immutable OwnerRun02 failed result remains at `TestResults/PH4_Dependency_Register_Slice1_SQL_20260923T091652656Z/result.json` with SHA-256 `DDE8A77A5B7EEBC6D9825B735D6D55516D4A1D55AC22BFDD524BBA43A96D5F42`. OwnerRun02 and its retained database must not be reused, changed or deleted.

Static diagnosis identified a second Tester-harness defect. SQL Server derives `sys.columns.is_nullable` for these computed expressions from the nullable endpoint-ID operands and possible `CASE` fall-through; it does not infer metadata non-nullability from the separate endpoint `CHECK` constraints. The migration contract's non-null requirement is therefore a data invariant, not a reliable `sys.columns.is_nullable = 0` assertion. The repaired harness continues to require `is_computed = 1` and `sys.computed_columns.is_persisted = 1`, explicitly verifies both endpoint `CHECK` constraint objects and the named filtered unique endpoint index, and requires the valid seeded dependency to return non-NULL, exact source and target keys. Invalid endpoint shapes, active duplicates, cross-scope writes, Restrict deletes, stale/simultaneous writes, Down/reapply, non-deletion and final-history assertions remain unchanged.

The harness is pinned to exact branch/commit, exact local SQL Express naming rules and the exact fresh OwnerRun03 database. The authorised owner executed it outside this Tester reconciliation, and the Tester verified the resulting immutable file by content and SHA-256.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\sqlserver\PH4_Dependency_Register_Slice1_Assurance.ps1 `
  -Server 'localhost\SQLEXPRESS' `
  -Database 'LgrTransformationMigration_PH4_Slice1_Assurance_d57239c_OwnerRun03'
```

OwnerRun03 result:

- Result file: `C:\Projects\lgr-transformation-migration\TestResults\PH4_Dependency_Register_Slice1_SQL_20260923T102609731Z\result.json`
- SHA-256: `781ECB8A39102E2B09E8E018B1A11B315A19672372E7FC37EB95591E07F45476`
- Outcome / process result: `PASS`; exit code `0`
- Exact repository head: `d57239c0f5b79eb1f6da50a9b288c8cea7425a97`
- Database state: left fully migrated `true`; automatically deleted `false`
- Recorded defects: `0`
- Verified coverage: fresh-database gate, migration Up, schema and computed-key evidence, endpoint checks, filtered uniqueness, cross-scope composite FK rejection, controlled values, active duplicate rejection, Restrict deletes, optimistic and simultaneous-write concurrency, Down/reapply legacy fingerprints and final full migration history.

Do not reuse, change or delete OwnerRun01, OwnerRun02 or OwnerRun03 databases or immutable evidence. This reconciliation did not connect to SQL Server.

## 6. Connected dependency evidence and accepted risk

The connected .NET vulnerability check completed with exit code `0`; `LgrTransformationMigration.Api`, `LgrTransformationMigration.Api.UnitTests` and `LgrTransformationMigration.Api.IntegrationTests` each reported no vulnerable packages.

The connected npm audit did **not** pass. It returned exit code `1` with two moderate findings for `GHSA-82fw-gwwq-j7x9` / `CVE-2026-84373` through `vitest` and `@vitest/mocker` 4.1.10. Upstream documents 4.1.11 as the patched version. Installation and validation of that patch were attempted but blocked by npm registry `EACCES` / `ENOTFOUND`; no dependency or lock file was changed.

PR #10 [review `5290659469`](https://github.com/onkarpathre/lgr-transformation-migration/pull/10#pullrequestreview-5290659469) is a named, exact-commit, time-bound `APPROVED` review by `ashish50thbirthday-ship-it` (Ashish), acting as **Information Security / Human Risk Owner**. It was submitted at `2026-09-23T12:00:45Z`, is explicitly bound to `d57239c0f5b79eb1f6da50a9b288c8cea7425a97`, covers this moderate development-tooling advisory, and expires **23 October 2026**. Decision: `ACCEPTED_WITH_CONDITIONS`.

All acceptance restrictions are mandatory:

- restricted local/non-production Phase 4 development and testing only;
- development servers bind only to localhost/loopback;
- `--host`, `0.0.0.0`, LAN exposure, proxying, tunnelling and public port exposure are prohibited;
- synthetic data only;
- no secrets in the repository or development tree;
- install and validate Vitest 4.1.11 or a later patched stable version when npm registry access is restored;
- rerun npm audit before production release; and
- no production use, deployment, customer data, external access, merge, release or Phase 4 exit is authorised by this acceptance.

Required follow-up: install the patched Vitest version, run the complete frontend regression, and rerun npm audit successfully before any production release. Expiry, any commit change affecting dependency state, any relaxation of the restrictions, or any change that places this tooling in production runtime invalidates this accepted-risk basis and requires fresh human review.

## 7. Recommendation

Recommendation: **PASS_WITH_ACCEPTED_RISK**

Exit state: **READY_FOR_QUALITY_REVIEW**

All three repaired defects independently pass, authorised OwnerRun03 supplies complete SQL Server provider assurance with zero defects, and the complete repaired .NET/frontend regression passes. The connected npm audit remains a genuine non-pass with two moderate findings. The named Human Risk Owner has accepted only that exact-commit development-tooling risk, under the stated expiry and restrictions. This recommendation is therefore `PASS_WITH_ACCEPTED_RISK`, not `PASS`, and advances only Slice 1 evidence to independent Quality review. The unavailable dedicated scanner remains declared as untested scope for the Quality Manager to assess against repository/CI gate evidence; it is not represented as passing and is not covered by the npm risk acceptance.

```yaml
handoff:
  from_agent: "tester"
  to_agent: "quality-manager"
  state: "READY_FOR_QUALITY_REVIEW"
  work_item: "PH4-DEP-001-SLICE-1"
  branch: "feature/ph4-dependency-register-implementation"
  commit: "d57239c0f5b79eb1f6da50a9b288c8cea7425a97"
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
    - "docs/implementation/PH4_Dependency_Register_Slice1_Test_Evidence_Pack.md"
    - "tests/sqlserver/PH4_Dependency_Register_Slice1_Assurance.ps1"
    - "src/web/tests/TesterDependencyBrowserJourneyContracts.test.tsx"
    - "tests/api.unit/DependencyRulesTests.cs"
    - "tests/api.integration/DependencyRegisterApiTests.cs"
    - "tests/TestData/dependencies/slice1-fixture-manifest.json"
  evidence:
    - "Exact-head repaired regression: 178 unit + 145 integration = 323 .NET tests passed; exit code 0."
    - "Frontend: 6 files / 22 tests passed, lint passed, and 21-page production build passed; exit code 0 for each command."
    - "OwnerRun03 SQL assurance PASS, exit code 0, zero defects, database left fully migrated and not automatically deleted; immutable result SHA-256 781ECB8A39102E2B09E8E018B1A11B315A19672372E7FC37EB95591E07F45476."
    - "Connected package evidence: all three .NET projects reported no vulnerable packages; exit code 0."
    - "Connected npm audit did not pass: exit code 1; two moderate GHSA-82fw-gwwq-j7x9 findings through vitest/@vitest-mocker 4.1.10."
  decisions:
    - "Only Slice 1 was tested; Slices 2 and 3 remain excluded."
    - "No critical/high security defect or cross-tenant disclosure was observed in executed API tests."
    - "npm audit is explicitly NOT PASS; the recommendation relies on named, exact-commit, time-bound human acceptance for restricted development/test only."
    - "The dedicated secret/static scanner is unavailable and is not represented as passing or as covered by the npm risk acceptance."
  assumptions: []
  risks:
    - "Accepted moderate development-tooling risk GHSA-82fw-gwwq-j7x9 expires 23 October 2026 and is invalid outside its mandatory restrictions."
    - "Vitest 4.1.11 installation remains blocked by npm registry EACCES/ENOTFOUND; dependency and lock files remain unchanged."
  defects: []
  blockers: []
  approvals:
    - "Five retained Phase 4 approvals in docs/approvals/PH4_Architecture_Approval_Evidence.json."
    - "PR #10 review 5290659469 by ashish50thbirthday-ship-it, Information Security / Human Risk Owner, submitted 2026-09-23T12:00:45Z, exact commit d57239c0f5b79eb1f6da50a9b288c8cea7425a97, ACCEPTED_WITH_CONDITIONS until 23 October 2026."
  requested_action: "Quality Manager: review the exact-commit evidence and accepted-risk restrictions. Before any production release, require installation and validation of Vitest 4.1.11 or later patched stable, complete frontend regression, and a successful npm audit rerun; do not infer merge, release, production, Phase 4 exit or Slice 2 authority."
```
