# PH3-SQL-001 Remaining Phase Plan After Slice 1

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
    - "Product Owner scope decision by onkarpathre, recorded 2026-09-15T12:08:46Z against 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a."
    - "Architect/TDA formal approval by opathre, recorded 2026-09-15T12:09:43Z against 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a."
    - "Information Security formal approval by ashish50thbirthday-ship-it, recorded 2026-09-15T12:11:06Z against 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a."
    - "DBA/Discovery SME formal approval by nextgenexamprep-crypto, recorded 2026-09-15T12:13:03Z against 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a."
```

## Control and outcome

- **Work item:** `PH3-SQL-001-REMAINING`
- **Baseline:** `main` at `284c5b2`
- **Product phase:** Product Specification Phase 1 MVP; this is the remainder of repository Roadmap Phase 3, not Product Specification Phase 3.
- **Slice 1 position:** merged and quality-recommended for its restricted local/non-production scope. SQL Instance/Database inventory CRUD, relationships, isolation, audit and supporting controls are not replanned.
- **Objective:** complete the approved SQL discovery, human assessment and browser journey so database workloads become governed inventory and planning evidence.
- **Scope boundary:** synthetic data and file-based CSV only; record, plan and evidence only. No migration execution, DMS orchestration, AI, remediation, Azure provisioning, direct discovery API, multi-cloud, production deployment, SSIS, SSRS or linked-server scope.
- **Product Owner state:** `READY_FOR_ARCHITECTURE`; scope approval is commit-bound and evidenced below.

## Ordered slices

Slices are sequential because assessment relies on governed inventory, and the end-to-end browser and phase evidence relies on both import/history and assessment contracts.

### Slice 2 - SQL CSV discovery, reconciliation and history

**Outcome:** an authorised Discovery Analyst can safely preview and explicitly commit approved SQL Instance and SQL Database CSV data without overwriting human-managed fields.

Acceptance criteria:

1. `SqlInstanceCsv/v1` and `SqlDatabaseCsv/v1` synthetic files are validated and staged; preview makes no canonical change and deterministically reports Create, Update, Unchanged, Warning or Reject with row/field evidence. (`SQL-AC-003`, `SQL-AC-004`)
2. Explicit commit is transactional and idempotent, rejects stale or repeated unsafe application, preserves protected fields byte-for-byte, and creates scoped append-only snapshots for every safe committed row, including Unchanged rows. (`SQL-AC-005`, `SQL-AC-015`)
3. Upload, batch, row, preview, commit, cancel and discovery-history paths are project-authorised, non-enumerating and audited with actor, UTC time and correlation metadata; raw or credential-like values are not logged. (`SQL-AC-008`, `SQL-AC-009`, `SQL-AC-015`)
4. Boundaries, provider-specific transaction/constraint behaviour and existing Phase 1/2 plus Slice 1 behaviour remain evidenced against the same commit. (`SQL-AC-011` to `SQL-AC-014` as applicable)

Dependencies: Slice 1; approved CSV v1 contracts and synthetic positive/negative/boundary fixtures; same-commit baseline; approved SQL Server test lane.

### Slice 3 - Human SQL assessment and planning records

**Outcome:** an authorised DBA records evidence-based instance or database assessment and human-selected migration planning values without autonomous recommendation or action.

Acceptance criteria:

1. A user can create, retrieve, revise, filter and archive an assessment against exactly one in-project SQL Instance or SQL Database, with status, readiness, blockers, findings, notes and assessed time under optimistic concurrency. (`SQL-AC-006`)
2. Target platform is limited to Azure SQL Database, Azure SQL Managed Instance, SQL Server on Azure VM, Retain, Retire or Investigate; migration approach and optional target version remain human-managed records and trigger no execution, remediation or provisioning. (`SQL-AC-006`, `SQL-AC-007`, `SQL-AC-014`)
3. Assessment values remain protected from discovery, tenant/project isolated and non-enumerating, and significant changes produce privacy-safe actor/UTC audit history. (`SQL-AC-005`, `SQL-AC-008`, `SQL-AC-009`)
4. Bounded API, SQL Server constraint/workflow and full regression evidence pass against the same commit. (`SQL-AC-011` to `SQL-AC-013` as applicable)

Dependencies: Slice 2; approved controlled assessment values and synthetic assessment fixtures; named DBA/Discovery SME availability.

### Slice 4 - Browser journey and Phase 3 evidence closure

**Outcome:** the complete restricted SQL journey is usable and independently evidenced from inventory through discovery and assessment.

Acceptance criteria:

1. Discoverable, keyboard-usable SQL Instance, Database, import/reconciliation/history and assessment journeys provide loading, empty, validation and safe error states in supported browsers. (`SQL-AC-010`)
2. End-to-end evidence proves the role matrix and customer/project isolation across every SQL list, detail, write, relationship, import, history and assessment path. (`SQL-AC-008`)
3. A synthetic project with at least 200 total mixed assets proves bounded/paged behaviour and usable query/import/history performance without leakage, N+1 behaviour or architectural redesign. (`SQL-AC-011`)
4. Same-commit API/UI/accessibility, SQL Server, migration, dependency/security and Phase 1/2/Slice 1 regression evidence passes; reviewed contracts, fixtures, rollback notes and requirements-to-test mapping are retained. (`SQL-AC-012`, `SQL-AC-013`)
5. Repository and behavioural evidence confirms the completed phase contains no migration execution, DMS, AI, remediation, Azure provisioning or production-deployment path. (`SQL-AC-014`)

Dependencies: Slices 2 and 3; approved frontend component/E2E/accessibility approach and isolated synthetic environment; all preceding slice evidence bound to the candidate commit.

## Material approvals and gates

1. Before Slice 2 or 3 development, named Product Owner, Architect and DBA/Discovery SME approval is required for both CSV v1 contracts, controlled assessment values and the exact synthetic fixture set. Information Security is additionally required only if a later contract proposes `ServiceAccountName`.
2. Before independent acceptance, the named Test Authority must approve the frontend tooling and entry/exit criteria and confirm the SQL Server lane covers each changed schema/import transaction. Each slice still requires independent Tester evidence, Quality Manager recommendation and human merge authority.
3. Q-02/PRB approval is required before this ordering is represented as a funded delivery commitment or release baseline. No date, budget or production commitment is made here.
4. Wider Q-01 technology, production tenancy, Q-06/DPIA, deployed identity/Q-09, Service Transition and production release approvals remain mandatory for their production/external scopes; they do not block restricted local/non-production architecture planning and do not become part of these slices.

### Approval evidence reconciled on 15 September 2026

The supplied JSON is syntactically valid, identifies Pull Request 6, and binds every record to the exact architecture-package commit `7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a`. That commit contains both this plan and `PH3_SQL_Remaining_Phase_Architecture.md`. The records authorize restricted local/non-production development and testing only; none authorizes production, customer data, external identity, migration execution, deployment, merge, release or PRB commitments.

| Role | Reviewer name (GitHub login) | Decision and date | Approved scope | Durable permalink |
|---|---|---|---|---|
| Product Owner | `onkarpathre` | Exact-commit decision recorded as `COMMENTED`, 2026-09-15T12:08:46Z | Approves ordered Slices 2-4, scope, priorities, acceptance criteria, controlled-value ownership and phase approach for restricted local/non-production development and testing. The `COMMENTED` state is accepted because GitHub does not permit the PR author to formally approve their own PR and the review body says “Approved as Product Owner.” | [PR 6 review 5209736362](https://github.com/onkarpathre/lgr-transformation-migration/pull/6#pullrequestreview-5209736362) |
| Architect / TDA | `opathre` | Formal exact-commit `APPROVED`, 2026-09-15T12:09:43Z | Approves the consolidated remaining-phase architecture for ordered Slices 2-4 within the documented restricted local/non-production boundaries. | [PR 6 review 5209749102](https://github.com/onkarpathre/lgr-transformation-migration/pull/6#pullrequestreview-5209749102) |
| Information Security | `ashish50thbirthday-ship-it` | Formal exact-commit `APPROVED`, 2026-09-15T12:11:06Z | ADR-008 permission extension, deny-by-default authorization, tenant/project isolation, raw-row controls, audit, safe errors and synthetic-data restrictions. | [PR 6 review 5209763769](https://github.com/onkarpathre/lgr-transformation-migration/pull/6#pullrequestreview-5209763769) |
| DBA / Discovery SME | `nextgenexamprep-crypto` | Formal exact-commit `APPROVED`, 2026-09-15T12:13:03Z | CSV v1 schemas and values, fixtures, staging/reconciliation, idempotency/history, SQL constraints, additive migrations and data-preserving rollback. | [PR 6 review 5209781297](https://github.com/onkarpathre/lgr-transformation-migration/pull/6#pullrequestreview-5209781297) |

All four decisions are bound to approved architecture commit [`7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a`](https://github.com/onkarpathre/lgr-transformation-migration/commit/7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a). The Product Owner, Architect/TDA, DBA/Discovery SME and Information Security gates are satisfied for the unchanged restricted package, so sequential Slices 2-4 are `READY_FOR_DEVELOPMENT`. Test Authority approval remains required before formal independent implementation evidence is accepted; all production/external gates remain unchanged.

## Material risks

| Risk | Treatment / owner |
|---|---|
| R-01 / I-03: variable CSVs or ambiguous names create incorrect relationships. | Versioned contracts, deterministic parent matching, preview/explicit commit and DBA/Discovery SME approval. |
| R-02: SQL metadata, staging or history leaks across customer/project boundaries. | Architect retains server-derived scope and owner-leading constraints; Tester proves every deferred path independently. |
| R-03 / I-04: incomplete or unrepresentative SME data makes assessment unreliable. | Controlled values, representative synthetic shapes and visibly incomplete/blocked status; human decisions remain authoritative. |
| R-06: scope expands into execution, integrations, SSIS/SSRS or automation. | Preserve the stated exclusions and repeat absence checks in every slice. |
| R-09 / I-06: SQLite or static UI checks miss SQL Server, concurrency or browser defects. | Mandatory approved SQL Server and frontend/E2E lanes before acceptance. |
| R-11 / I-08: dependency or framework drift breaks the accepted baseline. | Same-commit restore/build/test and dependency/security evidence for each slice. |

## Commit-bound Architecture hand-off

```yaml
handoff:
  from_agent: "architect"
  to_agent: "developer"
  state: "READY_FOR_DEVELOPMENT"
  work_item: "PH3-SQL-001-REMAINING"
  branch: "feature/ph3-remaining-plan"
  commit: "7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a"
  approved_architecture_commit: "7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a"
  delivery_slices: ["Slice 2", "Slice 3", "Slice 4"]
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
      - "Product Owner scope decision: onkarpathre, 2026-09-15T12:08:46Z, commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a, https://github.com/onkarpathre/lgr-transformation-migration/pull/6#pullrequestreview-5209736362"
      - "Architect/TDA formal approval: opathre, 2026-09-15T12:09:43Z, commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a, https://github.com/onkarpathre/lgr-transformation-migration/pull/6#pullrequestreview-5209749102"
      - "Information Security: ashish50thbirthday-ship-it, 2026-09-15T12:11:06Z, commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a, https://github.com/onkarpathre/lgr-transformation-migration/pull/6#pullrequestreview-5209763769"
      - "DBA/Discovery SME: nextgenexamprep-crypto, 2026-09-15T12:13:03Z, commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a, https://github.com/onkarpathre/lgr-transformation-migration/pull/6#pullrequestreview-5209781297"
  artefacts: ["docs/product/PH3_SQL_Remaining_Phase_Plan.md"]
  evidence:
    - "docs/product/PRODUCT_GAP_ANALYSIS_AND_ROADMAP.md"
    - "docs/product/Phase3_SQL_Discovery_Assessment_Work_Item.md"
    - "docs/architecture/Phase3_SQL_Discovery_Assessment_Architecture.md"
    - "docs/product/PH3_SQL_Approval_Pack.md"
    - "docs/quality/PH3_SQL_Slice1_Quality_Gate_Record.md"
  decisions:
    - "Deliver the remaining restricted Phase 3 scope as ordered Slices 2-4: discovery/history, assessment, then browser and evidence closure."
    - "Do not replan the merged Slice 1 scope or expand into production and excluded capabilities."
  assumptions:
    - "The accepted Slice 1 interfaces and controls remain the additive baseline unless Architecture identifies a material conflict."
  risks: ["R-01", "R-02", "R-03", "R-06", "R-09", "R-11"]
  defects: []
  blockers: []
  approvals:
    - "Product Owner scope is approved for restricted local/non-production Slices 2-4 at exact package commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a."
    - "Architect/TDA, Information Security and DBA/Discovery SME formal approvals are recorded for their stated restricted scopes at the same commit."
  requested_action: "Implement sequential Slices 2-4 against approved architecture commit 7fab16fa653fbcbb47a50d2aaa5d25f7c1a47d3a within the documented restricted local/non-production scope. Obtain named Test Authority approval before formal independent implementation evidence is accepted; no merge, deployment, production migration, customer-data use or production action follows."
```
