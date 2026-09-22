# PH4 Product Plan - Dependency Register and Planning Validation

Status: **DRAFT PRODUCT WORK PACKAGE - READY_FOR_ARCHITECTURE**

Assessment date: 22 September 2026

Repository baseline: `70e0774a10bd438d305fd013a645800405a6745d`

Branch inspected: `feature/ph4-planning`

Proposed work item: `PH4-DEP-001` (local planning identifier; not an approval)

Product-specification phase: **Phase 1 - MVP**

Roadmap increment: **Phase 4** (repository delivery label only; not Product Specification Phase 3)

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
  approvals: []
```

## 1. Product decision

The smallest high-value phase after the completed Phase 3 SQL increment is a **governed dependency register with planning validation**.

This is deliberately narrower than the September roadmap's combined “Application/Infrastructure Assessment and Dependency Management” phase. The repository now has governed application, server, SQL instance, SQL database, wave and readiness records, but it still has no directed, typed dependency capability. Building the dependency slice first connects those existing assets, addresses the product's central cutover-risk user journey, and creates a prerequisite for later wave approval without waiting for the broader application-assessment backlog.

The phase does not repeat:

- Phase 1 customer/project, application/server inventory, decisions, target, IP, wave, readiness, runbook and dashboard foundations;
- Phase 2 server CSV staging, preview, reconciliation, explicit commit, snapshots and history;
- Phase 3 SQL instance/database inventory, SQL CSV discovery, SQL assessment/planning records, session capabilities and SQL-specific RBAC.

No schedule, budget, release baseline or approval is asserted. Q-02 remains open. The Product Owner recommends this phase for architecture; implementation must not start until the single phase-level approval gate in section 13 is satisfied.

## 2. Business outcome

Migration Architects and technical SMEs can record and validate the dependencies that determine migration sequence, while Project Managers can see unresolved, circular, unassigned and cross-wave risks before a human makes a wave-readiness or approval decision.

Success is measured from platform evidence, not a claimed efficiency percentage:

- all supported dependency records are attached to the active customer/project and retrievable from both ends;
- invalid, duplicate, self-referential and cross-tenant/project relationships are rejected safely;
- unresolved, unconfirmed, circular, unassigned and cross-wave conditions are visible to authorised users;
- dependency blockers are surfaced in the existing planning/readiness journey without approving or executing migration;
- significant dependency changes are attributable to an authenticated principal and timestamp;
- the demonstration journey in section 11 passes with synthetic data.

## 3. Evidence-led baseline

### 3.1 Repository and implemented surface

The assessment began with a clean working tree at the requested merge commit. The current surface contains 90 HTTP actions across six controller files and 21 Next.js product routes.

Implemented product journeys include:

- administration: customers, projects and configuration;
- inventory: applications, servers, SQL instances and SQL databases;
- discovery: server and SQL file upload, preview, row inspection, commit/cancel and history;
- assessment: application-level migration decisions and SQL assessment/planning;
- Azure planning records: target builds and IP management;
- migration planning: waves, readiness and draft runbooks;
- programme dashboard and session capability discovery.

The API now has a deny-by-default authenticated fallback policy and server-derived project membership. Fine-grained permission policies are implemented for the Phase 3 SQL inventory, discovery and assessment routes. The older Phase 1/2 routes receive the active-membership fallback but do not yet have complete function-specific RBAC. Entra token validation code exists, but production identity, membership provision and external customer access are not approved or operational.

### 3.2 Phase 1-3 evidence

| Increment | Evidence accepted for planning | Exact boundary retained |
|---|---|---|
| Phase 1 POC | Working application/server inventory, shallow migration journey, IP state rules, wave/readiness/runbook foundations, API/web shell, initial tests and Azure-compatible persistence structure. | It is a POC foundation, not complete C-01 to C-11 behaviour and not production ready. |
| Phase 2 discovery | Server CSV staging, validation, preview, reconciliation, explicit transactional commit, protected business fields, import history and server discovery snapshots. The repository README records 55 passing tests for that baseline. | It does not complete application, web-app, file-share or software import, XLSX, production Blob/quarantine/scanning or asynchronous ingestion. |
| Phase 3 SQL | Final Quality record recommends approval for the restricted local/non-production synthetic-data candidate. Recorded evidence is 274/274 .NET tests, 18/18 frontend tests, 13/13 SQL assurance steps, a Release build, EF model agreement and a 19-route build at the reviewed candidate. | Interactive Chrome/Edge/accessibility journeys were `NOT RUN`; external dependency advisory checks were `UNAVAILABLE`. Production identity, tenancy, Azure, customer data and MVP release were expressly excluded. |

This Product Owner review read the retained evidence and implementation but did not rerun tests, access SQL Server or convert a Quality recommendation into human approval.

### 3.3 Capability state after Phase 3

| Product area | Current evidence | Product development still required |
|---|---|---|
| C-01 customer/project/access | Customer/project records and server-derived local/test project membership exist. | User/membership/role administration, onboarding/offboarding and function-specific policies across all routes. |
| C-02 discovery import | Server and SQL CSV contracts have staged preview/commit/history. | Agreed application, web-application, file-share and software imports; required Excel support and data-quality workflow. |
| C-03 Master Inventory | Applications, servers, SQL instances and SQL databases exist and relate in part. | Web applications, file shares and software; remaining relationships; representative whole-project consolidation. |
| C-04 assessment | SQL evidence and planning assessments exist; application records hold a few shallow fields. | Structured application/infrastructure ownership, availability, backup, licensing, maintenance, vendor and migration requirements. |
| C-05 dependencies | Application-server association is an untyped many-to-many hosting link. | Directed, typed, validated dependencies and planning impact. **Selected for this phase.** |
| C-06 decisions | Application decision CRUD stores scope/strategy/target/reason/risk/status. | Per-asset recommendation, business decision, named approval, history and authorised transitions. |
| C-07 target design | One flat target record per server. | Versioned approved design hierarchy and change impact across workloads/waves; record only. |
| C-08 IP management | Lifecycle rules and duplicate-active protection exist. | CIDR/subnet validity, concurrency evidence, complete transition audit and approval semantics. |
| C-09 waves/readiness | Application/server wave membership and fixed readiness checks exist. | Database membership, dependency/business rules, configurable evidence/blockers and human approval gate. |
| C-10 runbook/rollback | Fixed draft runbook template and task updates exist. | Configurable workload-aware runbooks, separate rollback plans, evidence, version/status and technical-SME approval. |
| C-11 tracking/reporting/audit | Dashboard foundation and write-side audit events exist. | External execution records, testing, exceptions, validation, sign-off, audit retrieval and required exports/reports. |
| C-12 future AI | No AI path is present. | Remains deferred outside MVP under Q-03/Q-05; no Phase 4 work. |

## 4. Complete remaining MVP product-development backlog

The following is the remaining **product behaviour** after Phase 3, ordered by product dependency rather than copied from the earlier roadmap:

1. **Dependency register and validation** - selected Phase 4 scope; connects existing inventory to existing wave/readiness journeys.
2. **Structured application and infrastructure assessment** - ownership, service criticality, availability/SLA, maintenance, backup, support/security, licensing/vendor and migration requirements, with completeness/data-quality handling.
3. **Inventory and discovery breadth** - canonical web applications, file shares and software, application discovery input, remaining agreed Excel/CSV mappings and their reconciliation/history.
4. **Application user, membership and role administration** - authorised customer/project lifecycle and function-specific RBAC for every non-SQL and SQL product operation. Production Entra configuration is a readiness concern, but the application-owned administration and policy behaviour is product development.
5. **Governed migration decisions and approvals** - applicable assets, recommendation versus business decision, named human decision, rationale, immutable history and separation of duties.
6. **Target design versioning and impact** - approved planning records for subscription/resource group/VNet/subnet/compute/backup, comparison and affected workload/wave visibility, with no provisioning.
7. **IP integrity completion** - subnet membership, atomic concurrency, reservation/allocation/release semantics and full audit.
8. **Wave/readiness completion** - database membership, business constraints, assessment/dependency-derived blockers, evidence and authorised human approval.
9. **Runbook and rollback completion** - configurable workload-aware draft runbooks, separate rollback plans, sequencing, owners, timings, evidence, versions and technical-SME approval.
10. **External execution, testing and sign-off records** - externally performed execution events/issues, technical validation, business testing, exceptions, post-migration checks, rollback decision and final human sign-off. The platform remains record-only.
11. **Reporting, export, audit retrieval and governance dashboards** - Master Inventory, wave, readiness and post-migration outputs in required formats; safe CSV/Excel/PDF handling; authorised audit search/timeline/export.
12. **Configuration and data-quality lifecycle** - governed lookup/template/rule maintenance, customer override semantics, quality ownership, exception resolution, freshness and completeness indicators.

Items 2-12 remain after this proposed phase. Their order may be re-baselined by the Product Owner/PRB as evidence changes; none is silently included in PH4-DEP-001.

## 5. Production-readiness work kept separate

The following does not enlarge the Phase 4 product slice. It remains mandatory before applicable pilot/production gates:

- wider Q-01 technology-baseline approval and an approved production tenancy decision reconciling ADR-001/ADR-007 with HLD DD-05;
- Q-02 investment/timeline decision and PRB release baselining;
- production Entra configuration, MFA/Conditional Access evidence and Q-09 external identity decision where customer access is required;
- Q-06 DPIA determination, UK-region/residency evidence, retention, deletion/offboarding and privacy approval;
- approved Azure hosting, SQL/storage topology, Key Vault, managed identity, private endpoints, WAF, environment separation and full IaC;
- private Blob quarantine/promotion, malware scanning and approved file retention/deletion;
- protected pipelines with secret, dependency/vulnerability, static security, migration and IaC checks plus artefact promotion and human-controlled environments;
- privacy-safe monitoring, tracing, metrics, availability/dependency checks, alerts and operational dashboards;
- backup/restore evidence, DR design/drill, service hours, RTO/RPO, incident/escalation, release/rollback and knowledge transfer;
- interactive supported-browser, WCAG 2.2 AA, performance/load, penetration/security, recovery and full every-route isolation evidence against one candidate;
- live-pilot/UAT and Q-04 benefit baseline evidence;
- Q-07 commercial model, Q-08 operating/support model, Q-10 product naming and all required Information Security, DPO, Service Transition, PRB and release-authority decisions.

Production-readiness work can proceed in parallel only through separately approved work packages. It must not be counted as completed product functionality or smuggled into this dependency phase.

## 6. In-scope users and journeys

### Journey A - capture and confirm a dependency

1. An authorised Migration Architect opens an application, server, SQL instance or SQL database in the active project.
2. They record a directed dependency on another supported in-project asset or on a named external/file/API reference.
3. They classify the relationship using governed values and record the known business/technical context without credentials or unnecessary personal data.
4. An authorised human confirms the relationship or leaves it visibly unconfirmed.
5. Both the upstream and downstream views show the relationship and its status.

### Journey B - validate dependency quality

1. A Migration Architect or technical SME runs or views project dependency validation.
2. The product identifies missing/unresolved references, duplicates, self-dependencies, cycles and unconfirmed records.
3. The user can navigate from each finding to the affected record and correct it.
4. Revalidation records the current result without deleting prior significant-change audit evidence.

### Journey C - expose planning risk

1. A Project Manager views a wave or readiness summary.
2. The product identifies dependencies whose related asset is unassigned, assigned to a later/incompatible wave, unresolved or unconfirmed.
3. Mandatory dependency findings are shown as blockers before a human approval decision.
4. The product does not auto-approve a wave, change a migration decision or execute work.

### Journey D - review and audit

1. A Reviewer/Auditor can inspect dependencies and validation outcomes for an authorised project.
2. They can see who made each significant change and when.
3. Read-only roles cannot create, alter, confirm or archive dependencies.

## 7. Ordered delivery slices

All slices belong to one phase-level work package. They are ordered to produce demonstrable value while avoiding a broad platform rewrite.

### Slice 1 - Dependency register

- Capture directed, typed relationships between existing application, server, SQL instance and SQL database records.
- Permit controlled named references for file shares, APIs and external systems that are not yet canonical inventory assets; keep their unresolved/resolved status explicit.
- Provide bounded list/detail views from both dependency directions and from the affected asset.
- Support authorised create, edit, confirm/unconfirm and logical archive behaviour with concurrency protection and audit.
- Reject missing, self-referential, duplicate and cross-customer/project relationships without disclosing foreign records.

### Slice 2 - Validation and data-quality findings

- Validate unresolved endpoints, duplicates, self-links, cycles and unconfirmed relationships.
- Present actionable project-level findings and affected paths/assets.
- Distinguish information/warnings from mandatory blockers using approved configurable values; do not hard-code customer-specific workflow.
- Revalidate deterministically after changes and expose a current validation summary.

### Slice 3 - Wave/readiness impact and evidence closure

- Surface unassigned and cross-wave dependency conditions in existing wave/readiness views.
- Prevent the product from presenting a wave as dependency-ready while mandatory dependency blockers remain.
- Retain human authority: surfacing a clear state is not approval and no migration activity is executed.
- Complete API/web demonstration, tenant/RBAC/graph regression, accessibility-oriented component checks and phase evidence.

## 8. Acceptance criteria

| Ref | Acceptance criterion | Traceability |
|---|---|---|
| AC-01 | An authorised user can create a directed dependency between supported in-project application, server, SQL instance and SQL database records and can create a controlled named file-share/API/external-system reference when no canonical record exists. | C-03, C-05; F-04, F-06 |
| AC-02 | A dependency records approved type/status values, direction, description/context and human confirmation state; secrets, credentials and unnecessary personal data are rejected or excluded. | C-05; F-06, F-15; NF-04 |
| AC-03 | Both upstream and downstream asset views return the dependency, and project list/search/filter results are bounded and tenant/project scoped. | C-05; F-06; NF-02, NF-08 |
| AC-04 | Missing endpoints, self-dependencies and active duplicates are rejected. Both relationship endpoints must belong to the server-authorised active customer/project. | F-06, F-15; NF-01, NF-02; R-02 |
| AC-05 | Cross-customer and cross-project identifiers fail without enumeration, and no list/detail/mutation/audit path returns another tenant/project's relationship or finding. | F-15; NF-01, NF-02; R-02 |
| AC-06 | Project validation identifies unresolved named references, unconfirmed dependencies and directed cycles and shows the affected assets/path sufficiently for an authorised user to act. | C-05; F-06; R-01, R-07 |
| AC-07 | For assets in waves, validation identifies a dependency whose related asset is unassigned or in an incompatible/later wave and surfaces it in the existing wave/readiness journey. | C-09; F-10, F-11; R-07 |
| AC-08 | A wave is never represented as dependency-ready while a mandatory dependency blocker remains. Only an authorised human can make any later approval decision. | C-09; F-10, F-11; A-11, R-07 |
| AC-09 | Significant dependency create, edit, confirm/unconfirm, archive and validation-state changes are auditable with server-derived actor, UTC timestamp, customer/project and correlation context, without sensitive payload logging. | F-15; NF-04, NF-06 |
| AC-10 | Read, manage, confirm and audit behaviours use explicit least-privilege permissions. A reviewer is read-only; local/test identity simulation remains non-production-only; caller-supplied role/customer values confer no authority. | F-15; NF-01, NF-02, NF-11 |
| AC-11 | Concurrent edits cannot silently overwrite a newer dependency state; stale writes return the established safe error contract. | F-06, F-15; NF-10; R-09 |
| AC-12 | A synthetic project containing at least 200 assets and a representative dependency graph proves bounded retrieval and deterministic validation without unbounded reads. The Architect and Tester must agree the measurable timing target before development. | NF-08; D-11 |
| AC-13 | Existing Phase 1/2 journeys and all Phase 3 SQL inventory, discovery, assessment and capability routes remain compatible unless the approved architecture explicitly versions a contract. | NF-10; D-13; R-09 |
| AC-14 | No endpoint, UI action or background operation executes migration, provisions Azure, changes networks/DNS/firewalls, calls discovery APIs, uses AI or introduces multi-cloud behaviour. | A-04, A-10, A-13; product boundaries |
| AC-15 | The complete synthetic demonstration in section 11 is independently testable, with positive, negative, permission, isolation, cycle and wave-impact evidence attached to one identified implementation commit. | I-06; D-11; Definition of Done |

## 9. Dependencies and required inputs

- **D-01 / Q-02:** Product Owner/PRB must approve investment in the phase before implementation; this plan makes no budget or timeline commitment.
- **Q-01 / I-08:** Solution Architect/TDA must state whether the existing .NET/Next.js baseline is approved for this wider MVP increment. ADR-006 closes Q-01 only for PH3-SQL-001 restricted local/non-production scope.
- **ADR-007 boundary:** the phase may be architected for restricted local/non-production shared-schema use only unless TDA/Information Security approve a wider tenancy position. It must not prejudge the production topology.
- **D-08:** Migration Architect, application/infrastructure SME and DBA input is required to approve dependency types, confirmation semantics and blocking rules.
- **I-04:** The model and validation outcomes must be reviewed against a representative synthetic/anonymised migration dataset; no claim is made that the existing model has been proven on a live estate.
- **I-07:** Dependency types and blocking severity must use the approved configuration approach to avoid customer-specific code forks.
- **D-11 / I-06:** a named test authority, isolated test environment and representative synthetic graph are required before implementation evidence can be accepted.
- **D-04 / D-13:** repository/CI access and supported locked dependencies must be available; current vulnerability status must be rechecked when advisory feeds are reachable.
- **Q-09:** external customer identity remains excluded. It does not block restricted internal/local architecture, but it blocks customer-access implementation and any customer-facing production claim.

## 10. Risks and treatment

| Risk | Product treatment; architecture/test proof still required |
|---|---|
| Incomplete or inaccurate dependencies make planning appear safer than it is (R-01/R-07). | Preserve unconfirmed/unresolved states, show validation coverage, surface blockers and require human confirmation before later wave approval. |
| Cross-tenant relationship identifiers disclose or link foreign records (R-02). | Bind both endpoints and every finding to server-authorised customer/project context; use non-enumerating errors and independent isolation tests. |
| A generic relationship model becomes opaque or permits invalid combinations. | Approve a bounded relationship vocabulary and supported target matrix with SMEs; reject invalid combinations and avoid free-form executable content. |
| Cycle detection or graph loading does not scale. | Require bounded APIs, deterministic validation and representative 200+ asset evidence; Architect selects the implementation. |
| Dependency scope expands into automatic discovery or a full CMDB (R-06). | Limit PH4 to human-managed project migration dependencies and controlled references; direct integrations and enterprise CMDB replacement are excluded. |
| Wave/readiness integration is mistaken for autonomous approval. | Use blocker/validation language, preserve visible human decision states and provide no auto-approval transition. |
| Stakeholder information introduces avoidable personal data. | Prefer role/team ownership and minimum contact data; require privacy review before any person-specific fields are approved. |
| Existing legacy routes have coarse permissions. | Architect must define the precise new permission boundary; the phase cannot weaken the fallback policy or expand caller-selected authority. Wider route-RBAC completion remains separate product work. |
| Phase 3 browser/vulnerability evidence gaps recur. | Make an executable interactive-browser environment and reachable advisory feeds explicit phase evidence prerequisites, not assumed passes. |

## 11. Demo requirements

The phase demo uses synthetic data only and must show, in one authorised project:

1. create and confirm an application-to-SQL-database dependency;
2. create a server-to-external-API or file-share reference and show its unresolved status;
3. view each relationship from both upstream and downstream perspectives;
4. reject a duplicate and a self-dependency;
5. attempt cross-project and cross-customer relationships and receive non-enumerating denial/not-found behaviour;
6. create a three-node directed cycle and show the affected path;
7. place related assets into compatible waves, then change one assignment to demonstrate a cross-wave blocker;
8. show an unassigned dependency in wave/readiness status;
9. show a read-only reviewer viewing but failing to mutate a dependency;
10. edit, confirm/unconfirm and archive a dependency and show actor/timestamp audit evidence;
11. validate a synthetic 200+ asset project with bounded pages and the agreed performance evidence;
12. show that no migration execution, Azure provisioning, network change or autonomous approval action exists.

Demo completion is product evidence, not production readiness, release approval or permission to use customer data.

## 12. Environment and evidence gaps

### Required to deliver and test this phase

- No approved PH4 work item, Architecture Work Package or phase-level human approval currently exists.
- Q-01 is closed only for the Phase 3 restricted scope; wider MVP stack use needs an explicit TDA disposition.
- No approved dependency vocabulary, target matrix, confirmation rule or mandatory-blocker policy is recorded.
- No representative dependency graph fixture or named Phase 4 test-authority approval exists.
- Phase 3's interactive browser/backend lane was unavailable, so live Chrome/Edge keyboard, focus, reflow, contrast and browser timing evidence is still missing.
- NuGet/npm advisory services were unavailable for the final Phase 3 candidate, so current clean-vulnerability status is unknown.
- There is no deployed shared test environment; local/test identity and local storage remain development mechanisms.
- The current pipeline builds/tests but lacks the security, dependency, migration and IaC gates required for broader claims.

### Not blockers to architecture of the restricted product slice

- production Azure resources and production data;
- Q-06 DPIA, Q-07 commercial model, Q-08 service model and Q-10 final name;
- Q-09 external identity, provided all customer/external-user access remains excluded;
- Azure Blob, malware scanning, production monitoring, backup/DR and release pipelines.

These become blockers before the corresponding pilot, production-processing or release claim.

## 13. Single phase-level approval approach

Use **one commit-bound phase approval gate** for PH4-DEP-001 after the Architect has completed the Architecture Work Package and before any implementation begins. Do not seek separate scope approvals for each slice.

The one approval record must identify the exact planning/architecture commit and record, without inference:

1. Product Owner/PRB scope and investment decision, including acceptance criteria, exclusions and Q-02 disposition sufficient for this increment;
2. Solution Architect/TDA decision on architecture, trust boundaries, data/contract changes and the wider Q-01 scope;
3. Information Security decision on tenant/project relationship controls, RBAC and audit changes where required;
4. named Migration Architecture/application/infrastructure/DBA SME confirmation of dependency vocabulary and blocking semantics;
5. named Test Services authority for the environment, synthetic dataset and test conditions.

Approval authorises only the bounded local/non-production implementation and independent testing stated in the record unless the named authorities explicitly approve more. It is not merge, deployment, customer-data, production-tenancy, risk-acceptance, MVP-exit or release approval.

The ordered slices still require normal Developer hand-off, independent Tester evidence and Quality review. A material scope, security, tenancy, role, contract or acceptance change invalidates the phase approval and returns to the owning role. Non-material implementation sequencing does not require a new Product Owner approval.

## 14. Explicit exclusions

- broader application/infrastructure assessment fields;
- new canonical web-application, file-share or software inventory;
- automatic dependency discovery or direct Azure Migrate/third-party APIs;
- customer-specific workflows or a general enterprise CMDB;
- external customer identity or access;
- migration decision/target/wave approval workflow beyond surfacing dependency blockers;
- Azure target provisioning, networking, IP changes, DNS or firewall activity;
- runbook/rollback expansion and external execution tracking;
- reporting/export beyond dependency views and evidence needed for this phase;
- production Blob, malware scanning, infrastructure deployment or production migration application;
- AI, autonomous recommendations, cost optimisation, multi-cloud or Power BI;
- real customer or personal data;
- merge, protected-branch push, production deployment, release approval or risk acceptance.

## 15. MVP completion estimate

**Estimated overall Product Specification Phase 1 MVP completion at the inspected baseline: 37% (planning estimate, ±5 percentage points).**

This is an outcome-weighted estimate against the 14 MVP completion outcomes already documented in `PRODUCT_GAP_ANALYSIS_AND_ROADMAP.md`, not a code-line, route or test-count measure:

| MVP outcome | Completion used |
|---|---:|
| Governance | 20% |
| Platform foundation | 35% |
| Discovery | 50% |
| Master Inventory | 55% |
| Assessment and dependencies | 35% |
| Decisions and target design | 30% |
| IP integrity | 55% |
| Planning and readiness | 35% |
| Runbook and rollback | 25% |
| Tracking, testing and sign-off | 10% |
| Reporting and audit | 15% |
| Quality evidence | 50% |
| Pilot and benefit evidence | 0% |
| Immutable boundary compliance | 100% |
| **Equal-weight mean** | **36.8% (reported as 37%)** |

The estimate recognises substantial Phase 1-3 foundations and evidence while avoiding the false conclusion that route count or passing local tests equal MVP completion. Production-readiness is materially lower because no production Azure environment, production identity/tenancy decision, DPIA, support model, live pilot or release evidence exists.

## 16. Product Owner hand-off

```yaml
handoff:
  from_agent: "product-owner"
  to_agent: "architect"
  state: "READY_FOR_ARCHITECTURE"
  work_item: "PH4-DEP-001"
  branch: "feature/ph4-planning"
  commit: "70e0774a10bd438d305fd013a645800405a6745d"
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
    approvals: []
  artefacts:
    - "docs/product/PH4_Product_Plan.md"
    - "docs/product/PRODUCT_GAP_ANALYSIS_AND_ROADMAP.md"
    - "docs/product/Agilisys LGR Migration and Transformation Product Specification V0.1.docx"
    - "docs/quality/PH3_SQL_Phase3_Quality_Gate_Record.md"
  evidence:
    - "Clean requested baseline verified at merge commit 70e0774a10bd438d305fd013a645800405a6745d."
    - "Implemented API/web routes, domain surface, ADRs and Phase 1-3 evidence inspected read-only."
    - "Phase 3 SQL work excluded from new scope; retained evidence limitations remain explicit."
    - "Overall MVP completion estimated at 37% using the documented 14-outcome completion definition."
  decisions:
    - "Select dependency register and planning validation as the smallest high-value next phase."
    - "Separate product-development scope from production-readiness work."
    - "Use one commit-bound phase approval before implementation, not slice-by-slice scope approval."
  assumptions:
    - "Dependency information will be supplied and confirmed by authorised human SMEs."
    - "Restricted development and test use synthetic or properly anonymised data only."
  risks:
    - "Unapproved dependency semantics could create false planning confidence."
    - "Q-01 is not closed for this wider MVP increment."
    - "Interactive browser and connected vulnerability evidence were unavailable at the final Phase 3 gate."
  defects: []
  blockers:
    - "Blocker to development, not architecture: no commit-bound PH4 phase approval exists."
    - "Blocker to development, not architecture: wider-scope Q-01/TDA disposition is absent."
  approvals: []
  requested_action: "Architect to produce the PH4-DEP-001 Architecture Work Package, define the dependency trust/data/API/UI boundaries and test conditions, assess Q-01 and tenancy/RBAC impacts, and assemble the single phase-level approval pack. Do not begin implementation until the named human decisions are recorded."
```
