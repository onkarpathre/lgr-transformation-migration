# Phase 3 SQL Discovery and Assessment - Product Work Package

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-02", "C-03", "C-04", "C-06"]
  functional_requirements: ["F-03", "F-04", "F-05", "F-07", "F-15"]
  non_functional_requirements: ["NF-01", "NF-02", "NF-04", "NF-06", "NF-08", "NF-09", "NF-10", "NF-13"]
  risks: ["R-01", "R-02", "R-03", "R-06", "R-09"]
  assumptions: ["A-01", "A-02", "A-05", "A-06", "A-08", "A-11", "A-13", "A-18"]
  dependencies: ["D-01", "D-07", "D-08", "D-11", "D-13"]
  issues: ["I-03", "I-04", "I-06", "I-08"]
  open_questions: ["Q-01"]
  approvals: []
```

## Work item control

- **Work item:** PH3-SQL-001
- **Title:** SQL Discovery and Assessment
- **Priority:** Required prerequisite package for the next repository delivery increment
- **Product Owner state:** `READY_FOR_ARCHITECTURE`
- **Formal approval:** Pending a named Product Owner/PRB decision with date, scope and evidence link under D-01. This document does not manufacture that approval.
- **Scope interpretation:** Roadmap Phase 3 is the repository delivery increment following the Phase 1 POC and Phase 2 Discovery Import implementation. It is an MVP-completion increment within Product Specification Phase 1, not Product Specification "Phase 3 - Scale and extend", and it does not authorise AI, direct integration, multi-cloud or automated provisioning.
- **Roadmap evidence:** `docs/product/PRODUCT_GAP_ANALYSIS_AND_ROADMAP.md` is absent from the current branch, but its draft was inspected from local branch `feature/agilisys-ui-theme` at commit `3dbc2fdca87cd0ea550e3d2928f068c6caad52fb`. It must be restored to this branch or formally superseded and approved before implementation.

## Business objective

Provide a governed, tenant-isolated record of discovered Microsoft SQL Server instances and databases, their hosting relationships, and their human-reviewed assessment and migration planning decisions. The outcome is a reliable SQL workload inventory that reduces re-keying, exposes incomplete or unsafe source data, and supports readiness and target planning without executing migration or provisioning Azure resources.

Success is measured from synthetic fixtures and test evidence showing that authorised users can import, reconcile, maintain and assess SQL inventory; relationships remain correct; duplicates and cross-tenant access are prevented; and every recommendation or migration approach is explicitly recorded as a human-managed planning decision.

## Personas

- **Database Specialist / DBA:** reviews SQL instances and databases, corrects inventory, records findings, blockers, readiness and migration approach.
- **Discovery Analyst:** imports supported SQL discovery CSV files, resolves validation warnings/rejects and reconciles source data.
- **Migration Architect:** records a proposed target platform and target SQL version for human review; does not provision it.
- **Migration Manager:** monitors assessment status, gaps and blockers across the current customer and project.
- **Application Owner / Technical SME:** validates workload context and supplies information discovery cannot determine.
- **Auditor / Programme Governance:** reviews provenance, changes, decisions and tenant-scoped evidence.

## User journey

1. An authorised user enters an authenticated customer and project context.
2. The user opens SQL inventory and reviews existing server, SQL instance and database relationships.
3. A Discovery Analyst uploads a supported synthetic SQL Instance or SQL Database CSV for the current project.
4. The platform validates the file and rows, normalises matching values, and presents Create, Update, Unchanged, Warning and Reject outcomes without changing canonical SQL inventory.
5. The user reviews row-level source values, validation messages and proposed discovery-managed changes, then explicitly commits safe rows.
6. The platform reconciles SQL instances to servers and databases to instances within the authorised tenant/project, records audit evidence and preserves protected assessment/business fields.
7. A DBA completes instance-level and/or database-level assessment, including status, readiness, blockers, findings and notes.
8. An authorised human records a target platform and migration approach. These are planning records, not an autonomous recommendation or execution instruction.
9. Migration and governance users filter the inventory and assessment status, review unresolved items, and use the recorded data in later readiness and planning activities.

## Data classification and tenant context

The feature stores potentially sensitive infrastructure metadata: server names, SQL instance names, database names, versions, editions, ports, sizes, configurations, findings, blockers and migration decisions. It must be handled as customer-confidential migration information. Development and test use only synthetic or properly anonymised data (A-18).

All reads, writes, imports, files, previews, commits, relationships, assessments, audit events, caches and future background work are bound to an authenticated server-side `CustomerId` and authorised `ProjectId`. Client-supplied identifiers cannot grant tenant access. Cross-customer or cross-project matching and relationship creation must fail safely and disclose no record existence.

## Functional requirements

| ID | Requirement | Product traceability |
|---|---|---|
| SQL-PO-001 | Maintain a paged and filterable SQL Instance inventory for the current customer/project. | C-03, F-04 |
| SQL-PO-002 | Maintain a paged and filterable SQL Database inventory for the current customer/project. | C-03, F-04 |
| SQL-PO-003 | Associate every SQL Instance with exactly one existing Server in the same customer/project. | C-03, F-04, F-15 |
| SQL-PO-004 | Associate every SQL Database with exactly one SQL Instance in the same customer/project. | C-03, F-04, F-15 |
| SQL-PO-005 | Allow authorised users to create, view, update and delete SQL inventory subject to validation, relationship and audit rules. | C-03, F-04, F-15 |
| SQL-PO-006 | Import SQL Instance and SQL Database discovery data from separately selected, supported CSV contracts. | C-02, F-03 |
| SQL-PO-007 | Preview source reconciliation as Create, Update, Unchanged, Warning or Reject before an explicit commit. | C-02, F-03, R-01 |
| SQL-PO-008 | Validate and normalise source values, display row-level messages, and reject unsafe or unmatchable rows without partially applying them. | C-02, F-03, R-01 |
| SQL-PO-009 | Protect human-managed assessment, target, migration approach, notes and approval fields from discovery overwrite. | C-04, C-06, F-05, F-07 |
| SQL-PO-010 | Record an assessment against a SQL Instance and/or a SQL Database with findings, blockers and notes. | C-04, F-05 |
| SQL-PO-011 | Record assessment status and readiness status so incomplete and blocked workloads can be reported. | C-04, F-05 |
| SQL-PO-012 | Record a human-selected target platform from Azure SQL Database, Azure SQL Managed Instance, SQL Server on Azure VM, Retain, Retire or Investigate. | C-06, F-07 |
| SQL-PO-013 | Record a human-selected migration approach and, where relevant, a target SQL version. | C-06, F-07 |
| SQL-PO-014 | Record discovery/import and assessment timestamps and source provenance. | C-02, C-04, NF-06 |
| SQL-PO-015 | Enforce customer/project authorisation and isolation for all SQL inventory, relationships, imports, assessments and exports. | F-15, NF-01, NF-02, R-02 |
| SQL-PO-016 | Audit significant SQL inventory, relationship, reconciliation and assessment changes with actor and timestamp. | F-15, NF-06 |
| SQL-PO-017 | Expose the capability through consistent tenant-authorised REST APIs using DTO contracts and safe errors. | NF-01, NF-02, NF-10, NF-13 |
| SQL-PO-018 | Provide browser journeys for SQL Instances, Databases, import/reconciliation and assessment using the current project context. | NF-09 |
| SQL-PO-019 | Support representative estates of at least 200 total assets per project without architectural redesign or unbounded list operations. | NF-08 |
| SQL-PO-020 | Remain a record, planning and evidence capability: it must not execute database migration, remediation or Azure provisioning. | A-11, A-13 |
| SQL-PO-021 | Where explicitly approved, record an optional non-sensitive SQL service-account display name; never accept credentials, secrets or authentication material. It is not part of the CSV v1 contracts unless separately approved. | C-03, F-04, F-15, NF-04 |
| SQL-PO-022 | Preserve append-only discovery history for committed SQL Instance and Database source facts. | C-02, C-03, F-03, F-04, NF-06 |

## Business rules

1. An SQL Instance cannot exist without a same-customer, same-project Server relationship.
2. A SQL Database cannot exist without a same-customer, same-project SQL Instance relationship.
3. Instance identity is unique within a customer and hosting server after approved normalisation of Instance Name.
4. Database identity is unique within a customer and SQL instance after approved normalisation of Database Name.
5. Display values preserve the reviewed business representation; normalised values are used only for deterministic comparison and uniqueness.
6. Blank or missing discovery values do not clear existing canonical values unless the approved field policy explicitly allows clearing and the user can see the proposed change.
7. Discovery manages observed technical fields only. Assessment status, readiness, target platform, target SQL version, migration approach, blockers, findings and notes are protected human-managed fields.
8. A target platform is a recorded proposal/decision requiring human review. The system must not infer it through AI or present it as automatically approved.
9. `Retain`, `Retire` and `Investigate` are planning outcomes, not Azure target resources.
10. Reject rows never modify canonical inventory. Warning rows may commit only where the approved contract identifies them as safe and the user confirms the batch.
11. Duplicate rows within a batch are rejected deterministically. Repeat files and existing canonical matches follow the approved reconciliation policy and remain auditable.
12. Deleting a Server with SQL Instances or an SQL Instance with Databases/Assessments is restricted unless a separately approved lifecycle process safely handles dependants.
13. All timestamps are stored as UTC instants and displayed consistently for the user locale.
14. No real customer or personal data may be used in development fixtures or automated tests.
15. A service-account display name is optional metadata only. Passwords, tokens, keys, connection strings and other authentication material are rejected and must never be stored or logged.

## Acceptance criteria

| ID | Acceptance criterion | Requirements / product mapping |
|---|---|---|
| SQL-AC-001 | Given an authorised project, users can create, retrieve, update, list/filter and delete valid SQL Instances and Databases; invalid or restricted operations return consistent Problem Details and no partial change. | SQL-PO-001..005; C-03, F-04, NF-10 |
| SQL-AC-002 | A same-customer/project Server can own multiple uniquely named instances, and an instance can own multiple uniquely named databases; cross-tenant/project relationships and duplicate normalised names are rejected. | SQL-PO-003, SQL-PO-004, SQL-PO-015; F-15, NF-01, NF-02 |
| SQL-AC-003 | SQL Instance and Database CSVs that conform to the approved synthetic contracts can be uploaded and previewed; canonical SQL inventory is unchanged until explicit commit. | SQL-PO-006, SQL-PO-007; C-02, F-03 |
| SQL-AC-004 | Preview and commit produce deterministic Create, Update and Unchanged outcomes; malformed, missing-key, duplicate, ambiguous, cross-project and out-of-range rows produce the specified Warning or Reject with row/field evidence. | SQL-PO-007, SQL-PO-008; F-03, R-01, I-03 |
| SQL-AC-005 | Re-importing identical committed technical data is Unchanged and does not duplicate instances/databases; protected human-managed fields remain byte-for-byte unchanged after any discovery commit. | SQL-PO-007, SQL-PO-009; C-02, C-04, C-06 |
| SQL-AC-006 | A DBA can record and revise an instance-level or database-level assessment, including assessment/readiness status, target platform, optional target SQL version, migration approach, blockers, findings, notes and assessed time. | SQL-PO-010..014; C-04, C-06, F-05, F-07 |
| SQL-AC-007 | Only the six allowed target-platform values can be recorded, and none triggers migration, DMS, remediation or Azure resource creation. | SQL-PO-012, SQL-PO-020; F-07, A-13 |
| SQL-AC-008 | Every SQL API list/detail/write/import/assessment path is proven unable to read, mutate, relate or enumerate another customer/project's data, including direct-object references and import history/rows. | SQL-PO-015; F-15, NF-01, NF-02, R-02 |
| SQL-AC-009 | Significant creates, updates, relationship changes, committed discovery changes and assessment changes produce tenant-scoped audit evidence with actor and UTC timestamp. | SQL-PO-014, SQL-PO-016; NF-06 |
| SQL-AC-010 | The browser provides discoverable navigation, loading/empty/error states, accessible labels and keyboard-usable CRUD/import/assessment journeys for supported modern browsers. | SQL-PO-018; NF-09, NF-13 |
| SQL-AC-011 | Automated evidence covers a synthetic project containing at least 200 total assets and demonstrates bounded/paged API behaviour without cross-tenant leakage or architectural redesign. | SQL-PO-019; NF-08 |
| SQL-AC-012 | Existing Phase 1 and Phase 2 API, import, tenant-isolation, build and frontend lint/build checks remain green against the same commit. | All; NF-10, D-13 |
| SQL-AC-013 | Source contracts, synthetic positive/negative/boundary fixtures, implementation notes, migration/rollback notes and a requirements-to-test matrix are reviewed and stored with the work item evidence. | SQL-PO-006..020; D-11, I-06 |
| SQL-AC-014 | Repository search and behavioural tests confirm there is no Phase 3 path for database migration execution, DMS orchestration, AI recommendations, automatic remediation or production Azure deployment. | SQL-PO-020; A-11, A-13 |
| SQL-AC-015 | Committed safe SQL rows create append-only tenant/project-scoped discovery history; optional service-account display metadata is accepted only through an approved field contract, while credential-like values are rejected and never logged. | SQL-PO-021, SQL-PO-022; C-02, C-03, F-03, F-04, F-15, NF-04, NF-06 |

### Roadmap acceptance mapping

The draft roadmap's AC-01 to AC-14 are retained as source traceability: AC-01 maps to SQL-AC-003/004; AC-02 to SQL-AC-004; AC-03 to SQL-AC-003/004/005; AC-04 to SQL-AC-002/005/008; AC-05 to SQL-AC-001/009/015; AC-06 to SQL-AC-001/009/015; AC-07 to SQL-AC-006/007; AC-08 to SQL-AC-007; AC-09 to SQL-AC-001/010; AC-10 to SQL-AC-008/009/015; AC-11 to SQL-AC-001/002/004; AC-12 to SQL-AC-009/015; AC-13 to SQL-AC-012/013; and AC-14 to SQL-AC-011/012/013. The local SQL-AC identifiers make those draft criteria testable without treating the unapproved roadmap as authority to implement.

## Out of scope

- Database migration execution or data movement of any kind.
- Azure Database Migration Service orchestration.
- SSIS packages, projects, catalogues or migration.
- SSRS reports, servers or migration.
- Linked-server discovery, assessment or migration.
- AI-generated or autonomous target recommendations.
- Automated remediation, configuration change or script execution.
- Production Azure deployment, Azure SQL provisioning or target-environment configuration.
- Direct Azure Migrate or third-party discovery API integration.
- Multi-cloud targets.
- Changes to the implemented tenancy model without an approved architecture decision and required human approvals.

## Dependencies, assumptions, risks and decisions

### Entry dependencies

- D-01: named Product Owner/PRB approval of scope, investment and phasing.
- Q-01 / HLD OD-07: named Solution Architect/TDA approval of the single application stack.
- TDA resolution of the conflict between ADR-001 shared tenant-aware persistence and HLD DD-05 database-per-customer wording.
- Approved synthetic SQL Instance and Database CSV contracts and fixtures; no customer data.
- Green API restore/build/test baseline, or a clearly evidenced environment-only blocker.
- Agreed frontend and SQL Server-specific test approach (I-06, D-11).

### Assumptions

- File-based CSV input remains the supported integration boundary for this increment (A-05).
- Host server records already exist or are safely reconciled before an instance can commit.
- Customer/SME/DBA review remains authoritative for source accuracy and assessment decisions (A-06, A-11).
- Names are mutable business identifiers, not primary keys (A-08).
- Existing immutable GUID identifiers and tenant-aware patterns remain unless an approved architecture decision says otherwise.

### Risks

- Variable source formats or ambiguous server/instance names can create incorrect relationships (R-01, I-03).
- Missing tenant constraints can expose highly sensitive infrastructure metadata (R-02).
- Incomplete DBA/SME input can leave readiness or target decisions unreliable (R-03).
- Scope can expand into SSIS, SSRS, execution or automation without strict boundary enforcement (R-06).
- Framework/provider differences, especially SQLite versus SQL Server behaviour, can leave uniqueness or migration defects undetected (R-09, I-06).

## Definition of Done

This work item is done only when:

- A named Product Owner/PRB approval is recorded with date, scope, conditions and evidence.
- Q-01 / OD-07 and the tenancy decision are closed by their authorised human owners in approved decision records.
- Architecture defines approved entities, keys, tenant/project constraints, uniqueness, indexes, delete behaviour, API/file contracts, field ownership, migration and rollback.
- Only synthetic contracts and fixtures are used and their validation/reconciliation expectations are approved.
- Implementation remains inside this scope and contains no execution, provisioning, AI or direct-discovery integration path.
- Additive EF Core migration and application changes pass review; production migration is not auto-applied.
- Required unit, integration, SQL Server provider, tenant-isolation, API and frontend tests pass against the same commit.
- Restore, Release build/test, frontend lint/build, security/dependency checks and migration checks are evidenced.
- Tester provides an independent requirements-to-test matrix and a PASS or properly evidenced risk disposition.
- Quality Manager verifies the full hand-off chain and issues a release-readiness recommendation; named humans retain merge and production authority.
- Documentation, audit, operability, compatibility and rollback evidence are current.

## Product Owner approval

**Agent recommendation:** Approve the scope for architecture review only.

**Human Product Owner / PRB approval:** Pending. Required approval evidence must include approver name/role, decision, date, scope, conditions and link. `READY_FOR_ARCHITECTURE` is a hand-off state and is not permission to implement.

## Hand-off

```yaml
handoff:
  from_agent: "product-owner"
  to_agent: "architect"
  state: "READY_FOR_ARCHITECTURE"
  work_item: "PH3-SQL-001"
  branch: null
  commit: null
  traceability:
    capabilities: ["C-02", "C-03", "C-04", "C-06"]
    functional_requirements: ["F-03", "F-04", "F-05", "F-07", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-04", "NF-06", "NF-08", "NF-09", "NF-10", "NF-13"]
  artefacts: ["docs/product/Phase3_SQL_Discovery_Assessment_Work_Item.md"]
  evidence:
    - "Product Specification V0.1"
    - "Existing Phase 1 and Phase 2 functional documentation"
  decisions: []
  assumptions:
    - "Phase 3 is the next repository increment and does not enable Product Specification Phase 3 AI or automation scope."
  risks: ["R-01", "R-02", "R-03", "R-06", "R-09"]
  defects: []
  blockers:
    - "Named Product Owner/PRB approval (D-01) is pending before implementation."
    - "Q-01 / OD-07 and tenancy conflict require authorised architecture decisions."
    - "PRODUCT_GAP_ANALYSIS_AND_ROADMAP.md is absent from this branch; the draft at 3dbc2fd must be restored or superseded and approved."
  approvals: []
  requested_action: "Produce the Phase 3 Architecture Work Package and proposed decision records; identify every human approval that still blocks implementation."
```
