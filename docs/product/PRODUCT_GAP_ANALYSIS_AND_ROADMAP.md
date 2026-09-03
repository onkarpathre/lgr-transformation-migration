# LGR Transformation and Migration - Product Gap Analysis and Delivery Roadmap

Status: DRAFT FOR HUMAN APPROVAL  
Assessment date: 3 September 2026  
Evidence branch: `feature/agilisys-ui-theme`  
Evidence commit: `b323b9cc513eb0385773d44f979dbfe7eb2222ad`  
Working tree at assessment start: clean  
Work item: not supplied  

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-01", "C-02", "C-03", "C-04", "C-05", "C-06", "C-07", "C-08", "C-09", "C-10", "C-11", "C-12"]
  functional_requirements: ["F-01", "F-02", "F-03", "F-04", "F-05", "F-06", "F-07", "F-08", "F-09", "F-10", "F-11", "F-12", "F-13", "F-14", "F-15", "F-16"]
  non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-04", "NF-05", "NF-06", "NF-07", "NF-08", "NF-09", "NF-10", "NF-11", "NF-12", "NF-13"]
  risks: ["R-01", "R-02", "R-03", "R-04", "R-05", "R-06", "R-07", "R-08", "R-09", "R-10", "R-11", "R-12"]
  assumptions: ["A-01", "A-02", "A-03", "A-04", "A-05", "A-06", "A-07", "A-08", "A-09", "A-10", "A-11", "A-12", "A-13", "A-14", "A-15", "A-16", "A-17", "A-18"]
  dependencies: ["D-01", "D-02", "D-03", "D-04", "D-05", "D-06", "D-07", "D-08", "D-09", "D-10", "D-11", "D-12", "D-13"]
  issues: ["I-01", "I-02", "I-03", "I-04", "I-05", "I-06", "I-07", "I-08"]
  open_questions: ["Q-01", "Q-02", "Q-03", "Q-04", "Q-05", "Q-06", "Q-07", "Q-08", "Q-09", "Q-10"]
  approvals: []
```

## Executive decision

The repository contains a credible Phase 1/Phase 2 proof-of-concept foundation, not a completed Product Specification MVP and not a production-ready SaaS service. The strongest implemented slice is CSV-based Azure Migrate server import: staging, preview, reconciliation, explicit transactional commit, discovery snapshots and field-level audit are present with focused unit and integration tests. Core application/server inventory, decisions, targets, IP allocation, waves, readiness, runbooks and dashboards are functional but deliberately shallow.

The next recommended implementation increment is **Roadmap Phase 3 - SQL Discovery and Assessment**. It is required by C-02, C-03, C-04 and F-03 to F-05, follows the existing discovery staging architecture, adds direct value for the Database Specialist persona, and can be tested independently without introducing migration execution, Azure provisioning, AI, microservices, Kubernetes or new integration infrastructure.

This is a roadmap recommendation, not authority to start implementation. The Product Specification is still draft/pending approval, the HLD has no recorded approval, no approved work item or traceability package was supplied, Q-01/OD-07 has no closure record, and the HLD database-per-customer decision conflicts with accepted Phase 1 ADR-001 and the current shared-database implementation. Those conditions must be resolved by the named human authorities before development starts.

### Phase terminology

Repository labels "Phase 1" and "Phase 2" describe implementation increments. The Product Specification uses Phase 1 for the whole MVP, Phase 2 for the live pilot and Phase 3 for scale/extension. To avoid false traceability, Roadmap Phases 3-10 below are **MVP-completion delivery increments within Product Specification Phase 1**, not Product Specification Phase 3.

## Current state

### Evidence baseline

- Stack present: .NET 10.0.400, ASP.NET Core, EF Core 10.0.11, SQL Server provider, Next.js 16.2.12, React 19.2.8 and TypeScript 5.9.3.
- Architecture present: one ASP.NET Core modular monolith, one Next.js web app, REST/JSON endpoints, one EF Core context, shared-schema tenant columns/global filters and development header-based context.
- Persistence present: 19 EF entity sets and two migrations, `InitialCreate` and `AddDiscoveryImport`.
- API surface present: 63 controller endpoint attributes across programme and discovery controllers.
- Frontend present: 15 product routes built successfully, plus the framework not-found route.
- Test source present: 44 xUnit test methods (39 facts and 5 theories); the README records 55 expanded Phase 2 cases (32 unit and 23 integration).
- Azure present: opt-in Bicep for Log Analytics and Application Insights only; deployment is disabled by default.
- Pipeline present: restore/build/test for .NET and install/lint/build for the web application. No deployment, IaC validation, migration verification, security scan or dependency scan is defined.

### Validation performed in this assessment

| Check | Result | Interpretation |
|---|---|---|
| Git branch/status | PASS | Clean tree on `feature/agilisys-ui-theme` at the evidence commit. |
| Frontend ESLint | PASS | `npm.cmd run lint` exited 0. |
| Frontend production build | PASS | Next.js build exited 0 and emitted all 15 product routes. |
| .NET restore/build/test | NOT REVALIDATED | Restore and build were blocked by restricted access to NuGet. A no-build/no-restore test invocation did not report discovered tests and is not accepted as test evidence. Source tests were inspected. |
| DOCX visual render | NOT AVAILABLE | LibreOffice/Word rendering tools were unavailable. Product Specification and HLD content, tables, document status and references were structurally extracted; page-layout quality was not asserted. |

### Current product capability matrix

`COMPLETE` means complete only for the explicitly stated repository slice and supported by implementation plus tests. It does not mean the Product Specification capability is complete.

| # | Expected repository capability | Status | Repository evidence and exact remaining boundary |
|---:|---|---|---|
| 1 | Customer administration | PARTIAL | Customer list/get/update API and edit UI exist. Create/delete, onboarding/offboarding, users, roles and authorised cross-customer administration do not. No focused customer-admin test exists. |
| 2 | Project administration | PARTIAL | Project CRUD API and create/edit UI exist. Delete is API-only; role enforcement, project membership, approval and focused integration coverage are absent. |
| 3 | Multi-tenant customer/project context | PARTIAL | Tenant columns, EF customer filters and service-level project predicates exist. Any caller can currently select customer/project through headers; Entra claims, membership and RBAC are absent. Isolation tests cover selected reads/imports, not every API route, write path, file, cache, job or log. |
| 4 | Application inventory | PARTIAL | Paged CRUD, search, migration fields and server associations exist. The full Master Inventory fields, ownership and assessment information required by F-04/F-05 do not. |
| 5 | Server inventory | PARTIAL | Paged CRUD, core compute fields, discovery metadata and snapshots exist. Complete infrastructure assessment, software/file-share/web/database inventory and production-scale evidence do not. |
| 6 | Application/server relationships | PARTIAL | A tenant-owned many-to-many join and UI editing exist. This is not the directed, typed dependency model required by C-05/F-06, and focused relationship/isolation tests are absent. |
| 7 | Migration decisions | PARTIAL | Application decision CRUD stores scope, strategy, target, reason, risk, status and date. Decisions are not generalised to servers/databases, and recommendation, business decision, approver, approval workflow and retrievable history are incomplete. |
| 8 | Azure target builds | PARTIAL | One target record per server and CRUD API exist; the UI is read-only. There is no versioned target-design hierarchy, change-impact analysis or workload/wave visibility required by F-08/R-05. |
| 9 | IP management | PARTIAL | Subnet/IP records, valid state transitions and duplicate active allocation protection are implemented and tested. CIDR membership, atomic concurrency evidence, reservation release semantics, approval and audit of transitions are incomplete. |
| 10 | Migration waves | PARTIAL | Wave CRUD and manual application/server membership exist and have a journey test. There is no typed dependency validation, database membership, business constraint model or approval gate. |
| 11 | Migration readiness | PARTIAL | Fixed application/server checks, editable status, deterministic calculation and wave summaries exist. Criteria creation/configuration, evidence, assessment/dependency derivation, database readiness and approval blocking do not. |
| 12 | Migration runbooks | PARTIAL | One draft runbook per wave, a fixed 13-task template and task updates exist with unit/journey coverage. Templates, sequencing controls, evidence, workload variation, runbook status transition and SME approval are incomplete. |
| 13 | Dashboard | PARTIAL | Tenant/project-scoped counts, wave/readiness summaries, application status and latest discovery import exist. SQL, data quality, execution, testing, sign-off, audit and operational views do not. |
| 14 | Configuration/lookups | PARTIAL | Global/customer read and customer value creation exist. Update/deactivate/delete, override precedence, validation, role control, audit and broader template/rule configuration do not. |
| 15 | Azure Migrate discovery import | PARTIAL | CSV Server Report and server-classified All Inventory rows are supported. Canonical application, SQL/database, web app, file-share and software import, XLSX, approved malware scanning and asynchronous processing are absent. |
| 16 | Discovery staging | COMPLETE | For the supported server CSV slice, batch metadata, source rows as JSON, validation results and tenant/project ownership are persisted and tested. |
| 17 | Preview and reconciliation | COMPLETE | For the supported server CSV slice, Create/Update/Unchanged/Warning/Reject classification, differences, safe hostname matching and no canonical preview writes are implemented and tested. |
| 18 | Import commit | COMPLETE | For the supported server CSV slice, commit is explicit, single-use and transactional, with stale-preview checks, rollback-on-failure and protected business fields tested. |
| 19 | Discovery snapshots/history | COMPLETE | Append-only server discovery snapshots, import history, freshness and tenant-aware history retrieval are implemented and tested for the supported slice. |
| 20 | Audit foundation | PARTIAL | `AuditEvent` exists and many CRUD/import operations write events. There is no audit read API/UI/export, several operations omit audit (notably IP transitions and runbook changes), and broad before/after history is absent. |
| 21 | Agilisys SaaS UI design system | PARTIAL | Branded shell, shared components, navigation, responsive styling and assets exist; lint/build pass. There are no component, accessibility, browser or visual-regression tests, and the shell still identifies a development context/user. |
| 22 | Unit and integration tests | PARTIAL | Useful domain/import/API tests exist. API tests could not be rerun here, and coverage is absent for many endpoints, all frontend behaviour, auth/RBAC, full tenant isolation, SQL Server-specific migrations, accessibility, performance, backup/recovery and security. |
| 23 | Initial Bicep/Azure deployment structure | PARTIAL | The stated initial structure exists and can conditionally define Log Analytics/Application Insights, but it has no Bicep validation/deployment test. It is not a deployable product environment and must not be treated as Azure deployment completion. |

### Product gap matrix

| Product area | Status | Priority | Required outcome | Traceability | Proposed phase |
|---|---|---|---|---|---|
| Discovery | PARTIAL | Must | Import all agreed file-based server, application, database, web-app, file-share and software sources with secure validation, reconciliation and repeatability. | C-02, F-03, R-01, I-03 | 3, 4, 9 |
| Master Inventory | PARTIAL | Must | Consolidated related inventory for all F-04 asset types, proven with 200+ assets. | C-03, F-04, NF-08 | 3, 4, 10 |
| Application assessment | PARTIAL | Must | Structured ownership, criticality, SLA/availability, maintenance, licensing, vendor and migration requirements. | C-04, F-05 | 4 |
| Infrastructure assessment | PARTIAL | Must | Structured server configuration, support/security/backup/readiness findings and migration requirements. | C-04, F-05 | 4 |
| SQL discovery/inventory/assessment | NOT STARTED | Must | SQL instances and databases linked to servers/applications, with discovery history, readiness, blockers, compatibility findings and target/approach assessment. | C-02, C-03, C-04, F-03, F-04, F-05 | 3 |
| Migration strategy and approval | PARTIAL | Must | Scope, 6R treatment, recommendation, business decision, named approval and rationale per applicable asset, with history. | C-06, F-07, A-11 | 4, 6 |
| Azure target design | PARTIAL | Must | Approved, versioned subscription/RG/VNet/subnet/compute/backup design with affected workload/wave visibility; record only. | C-07, F-08, R-05 | 6 |
| IP management | PARTIAL | Must | Concurrency-safe, subnet-valid lifecycle with complete audit and zero duplicate/conflicting allocation evidence. | C-08, F-09, R-04 | 6, 10 |
| Dependency management | NOT STARTED | Must | Directed, typed dependencies across applications, servers, databases, files, APIs and external systems; identify missing/circular/cross-wave dependencies. | C-05, F-06, R-07 | 4 |
| Wave planning | PARTIAL | Must | Plan applications/servers/databases using dependency, business and readiness rules and require human approval. | C-09, F-10, A-11 | 6 |
| Readiness | PARTIAL | Must | Configurable prerequisites, risks, blockers, evidence and approval, derived from assessments/dependencies without autonomous approval. | C-09, F-11 | 4, 6 |
| Runbooks | PARTIAL | Must | Structured, workload-aware draft runbooks with owners, timings, evidence, version/status and technical-SME approval. | C-10, F-12, R-08 | 6 |
| Rollback planning | NOT STARTED | Must | Separate structured draft rollback plans/steps, triggers, owners, timing, evidence and technical-SME approval. | C-10, F-12, A-12, R-08 | 6 |
| External execution tracking | PARTIAL | Must | Record externally performed execution, task/event progress, issues and evidence; provide no execution capability. | C-11, F-13, A-13 | 6 |
| Technical testing | NOT STARTED | Must | Test plans/cases/results/evidence and pass/fail status linked to workload/wave/execution. | C-11, F-13 | 7 |
| Business testing | NOT STARTED | Must | Business test ownership, results, exceptions and evidence. | C-11, F-13 | 7 |
| Approval and sign-off | NOT STARTED | Must | Named, dated, authorised technical/business approvals and final sign-off with immutable evidence. | C-06, C-11, F-07, F-13 | 5, 7 |
| Post-migration validation | NOT STARTED | Must | Record validation checks, defects/exceptions, rollback decision and completion outcome. | C-11, F-13, F-14 | 7 |
| Reporting/export | NOT STARTED | Must | Tenant-scoped Master Inventory, wave, readiness and post-migration reports in Excel/CSV/PDF with formula-injection protection. | C-11, F-14, NF-13 | 8 |
| Dashboards | PARTIAL | Must | Governance, progress, blockers, data quality, test/sign-off and operational dashboards. | C-11, F-14 | 8, 9 |
| Auditing | PARTIAL | Must | Complete append-only significant-event history, authorised retrieval/filter/export and user/timestamp evidence. | F-14, F-15, NF-06 | 8 |
| Security/data protection | PARTIAL | Must | Authenticated tenant binding, least privilege, encryption, private services, secrets, secure ingestion, retention/deletion and independent assurance. | F-15, NF-01 to NF-06, NF-11 | 5, 9, 10 |
| Entra ID | NOT STARTED | Must | Federated authentication, MFA/Conditional Access and claims-derived customer/project context; no local credentials. | F-02, F-15, NF-01, A-03, Q-09 | 5 |
| Application RBAC | NOT STARTED | Must | Customer/project/function roles and policy enforcement on every API/UI operation, with privileged access audit. | C-01, F-02, F-15, NF-01, NF-02 | 5 |
| Customer/project/user administration | PARTIAL | Must | Authorised lifecycle and membership administration, including safe onboarding/offboarding. | C-01, F-01, F-02 | 5, 9 |
| Configuration | PARTIAL | Should | Managed lookup/template/rule lifecycle with customer override semantics, validation and audit. | I-07, F-02, F-11, F-12 | 4, 6, 8 |
| Data quality | PARTIAL | Must | Quality rules, ownership, exception resolution, freshness/completeness reporting and approval blockers. | F-03, F-05, F-11, R-01 | 3, 4, 8 |
| Azure production deployment | NOT STARTED | Must | Approved UK Azure topology, full IaC, environment separation, managed identity, private endpoints, Key Vault, storage, SQL, WAF and protected deployment. | A-01, NF-03, NF-05, NF-10, I-01 | 9 |
| Observability | PARTIAL | Must | Application/platform telemetry, correlation, privacy-safe structured logs, availability/dependency checks, alerting and dashboards. | NF-06, NF-07, NF-12 | 9 |
| Operational support | NOT STARTED | Must | Support model, service hours, SLOs, incident/escalation, backup/restore/DR, access review, runbooks and knowledge transfer. | NF-07, NF-12, Q-08 | 9, 10 |
| Accessibility/browser assurance | NOT STARTED | Must for production | WCAG 2.2 AA and supported-browser evidence, accessibility statement and independent audit as applicable. | NF-09, NF-11 | 10 |
| AI recommendations | DEFERRED | Could/later | Advisory only after Q-03/Q-05, InfoSec and DPO approval; no MVP implementation. | C-12, F-16, A-17, R-10 | Product Specification Phase 3 only |
| Direct discovery APIs/integrations | DEFERRED | Could/later | File-based import remains the MVP route. | C-02, F-03, A-05 | Product Specification Phase 3 only |
| Power BI/advanced analytics | DEFERRED | Could/later | Native dashboards and required exports first. | F-14 | After MVP evidence |
| Migration execution engine | OUT OF SCOPE | N/A | Platform records external activity and never performs migration. | F-13, A-13 | Never in this roadmap |
| Azure provisioning/network configuration | OUT OF SCOPE | N/A | Target designs are records only; no provisioning or network changes. | F-08, A-10 | Never in this roadmap |
| Multi-cloud | OUT OF SCOPE | N/A | MVP remains Azure-only. | A-04 | Future change control only |

### Optional enhancements - excluded from MVP completion

These are not prerequisites for MVP or production readiness unless later approved through change control:

- AI-assisted recommendations for wave, target, cost, licensing, security or optimisation (C-12/F-16), only after Q-03/Q-05, Information Security and DPO approval and always advisory.
- Cost calculation and optimisation modelling, listed for Product Specification Phase 3.
- IaC/Bicep template generation as an exportable planning artefact, not direct Azure provisioning.
- Direct Azure Migrate or third-party integrations; file-based interchange remains the MVP contract.
- Power BI/advanced analytics after native dashboards and F-14/NF-13 exports are proven.
- Multi-cloud support only through a separately approved scope/architecture change.

## MVP completion definition

The current repository phases do not satisfy Product Specification Phase 1 MVP. MVP completion requires all of the following against one identified release candidate:

1. **Governance:** approved Product Work Package, HLD/LLDs/ADRs, Q-01 to Q-03 closure, PRB go/no-go, Information Security review and all affected human approvals.
2. **Platform foundation:** operational multi-tenant Azure environment, Entra authentication, least-privilege application RBAC and protected CI/CD.
3. **Discovery:** supported Azure Migrate/agreed files import server, application, database, web-application and file-share information without re-keying; unsafe data is staged, rejected or flagged.
4. **Master Inventory:** one related inventory of applications, servers, databases, web applications, file shares and software, proven with a representative 200+ asset project.
5. **Assessment and dependencies:** structured application/database assessment, ownership and typed dependency management are complete enough to drive safe planning.
6. **Decisions and target design:** migration decisions/approvals and versioned approved Azure target records are auditable; the platform performs no provisioning.
7. **IP integrity:** valid state transitions and atomic duplicate/conflict prevention are proven, including concurrency and subnet boundaries.
8. **Planning/readiness:** workloads and databases can be grouped into waves; missing, circular and cross-wave dependencies and other blockers are surfaced before a human approval.
9. **Runbook/rollback:** each pilot wave has workload-aware draft runbook and rollback plans with tasks, owners, timings and evidence, approved by the responsible technical SME.
10. **Tracking/testing/sign-off:** external execution, technical validation, business testing, exceptions, approvals, post-migration validation and sign-off can be recorded; the platform cannot execute migration.
11. **Reporting/audit:** authorised Excel/CSV/PDF exports and required governance reports work; significant migration decision changes are retrievable with user and timestamp.
12. **Quality:** build, lint, unit, integration, end-to-end, security, tenant isolation, migration, accessibility and applicable performance checks pass against the same commit, with no unresolved release-blocking defect.
13. **Pilot/benefit evidence:** live LGR pilot and structured feedback exist when required by the applicable gate; effort reduction is measured only after Q-04 defines the baseline.
14. **Boundaries:** no direct discovery API, migration execution, Azure provisioning, multi-cloud or AI behaviour has entered MVP scope.

## Production-readiness gaps

Production release remains blocked until these gaps are closed and evidenced:

- **Baseline approvals:** Product Specification and HLD approval fields are incomplete; no approved work item was supplied; Q-01, Q-02 and the ADR-001/HLD tenancy conflict require recorded decisions.
- **Identity/authorisation:** endpoints are anonymous and customer/project are client-selected headers. Entra, MFA/Conditional Access, membership, role policies, privileged access and Q-09 are unresolved.
- **Tenant assurance:** every API/write/export/file/job/log/admin path needs automated customer and same-customer cross-project isolation tests; production topology must match the TDA-approved tenancy decision.
- **Secure ingestion:** local file storage must be replaced by authorised tenant/project-scoped Blob storage, managed identity, quarantine/malware scanning, retention/deletion and asynchronous processing where required. MIME/schema limits and parser abuse tests need completion.
- **Azure/IaC:** there is no application hosting, SQL, Blob, Key Vault, managed identity, Front Door/WAF, private connectivity, DNS, backup, DR, environment separation or protected deployment definition.
- **Observability:** the application has only a simple health endpoint. Correlation IDs, structured privacy-safe logs, traces, metrics, dependency/availability checks, alert routing and operational dashboards are absent.
- **Reliability/operations:** service hours, availability, RTO/RPO, backups, restore tests, DR runbook/test, support ownership, incident/escalation, release/rollback and knowledge transfer are not agreed.
- **Data protection:** Q-06 DPIA decision, UK region enforcement, retention, deletion/offboarding, data classification and privacy review evidence are absent.
- **Audit:** significant events are not comprehensively captured and audit data cannot be retrieved or exported by authorised users.
- **Delivery controls:** the pipeline lacks secret/dependency/vulnerability/static analysis, migration checks, Bicep validation/what-if, artefact promotion, protected environments and production approval gates.
- **Assurance:** no frontend/component/E2E suite, full API isolation matrix, SQL Server migration test, accessibility audit, browser matrix, performance/load test, penetration test or recovery evidence exists.
- **Capacity:** current discovery fixtures contain only 2, 4 and 7 data rows; neither Product Specification 200+ asset evidence nor HLD higher-volume assumptions are proven.
- **Commercial/service gates:** Q-07 and Q-08 block commercial positioning and production service acceptance. Q-10 blocks final customer-facing naming.

## Recommended phases

| Roadmap phase | Objective | Primary business outcome | Priority | Complexity |
|---|---|---|---|---|
| 3 | SQL Discovery and Assessment | Database workloads become governed inventory and assessment records rather than staged counts/spreadsheets. | Must | XL |
| 4 | Application/Infrastructure Assessment and Dependency Management | Teams capture missing business/technical context and plan from validated dependencies. | Must | XL |
| 5 | Internal Entra ID, RBAC and Security Foundation | Approvals and later execution evidence are tied to authenticated, authorised users without retrofitting identity last. | Must | XL |
| 6 | Migration Planning, Target Versioning, Rollback and External Execution Tracking | Waves, targets, runbooks and rollback are safe, governed and traceable while migration remains externally executed. | Must | XL |
| 7 | Technical Testing, Business Validation and Sign-off | Completion is evidenced through structured tests, validation, exceptions and human sign-off. | Must | L |
| 8 | Reporting, Audit and Governance Dashboards | PRB/customer reports and audit evidence are generated from the source of truth. | Must | XL |
| 9 | Azure Production Deployment, Secure Ingestion and Observability | The application can run securely and supportably in approved UK Azure environments. | Must | XL |
| 10 | Production Hardening, Accessibility, Scale and Release | Release-blocking assurance, operability and human approvals are completed against one candidate. | Must | XL |

### Roadmap Phase 3 - SQL Discovery and Assessment

- **Objective/outcome:** deliver C-02/C-03/C-04 database value by converting approved SQL discovery data into canonical instances/databases and structured human assessment.
- **Scope:** supported file mapping, staging/preview/commit, SQL instance/database inventory, server relationship, assessment, findings/blockers, allowed target and migration approach, history/freshness, audit, list/detail/edit UI and tenant-safe APIs.
- **Exclusions:** dependency graph, wave membership, final approvals, execution, automated target recommendation, Azure provisioning, direct Azure Migrate API, AI and unrelated refactoring.
- **Domain/entities:** additive `SqlInstance`, `SqlDatabase`, `DatabaseAssessment`, `DatabaseAssessmentFinding` and SQL discovery snapshot records. Keep discovered technical fields separate from business-managed assessment fields.
- **Database:** additive tables/FKs/indexes; immutable GUIDs; customer/project ownership; required server relationship at canonical commit; case-normalised instance/database uniqueness; non-negative size and valid port constraints; restricted deletes; compatibility-safe migration.
- **API/frontend:** add paged SQL instance/database inventory and assessment endpoints; add `/inventory/sql-instances`, `/inventory/databases` and `/assessment/sql`; extend existing discovery source/preview UI without replacing server import.
- **Integration/Azure:** reuse `ImportBatch`, JSON staging, file storage abstraction and explicit commit. No new runtime integration or Azure resource is required for this increment.
- **Tenancy/security/audit:** use the current context seam and global filters plus project predicates pending the tenancy decision; service-account data is optional display metadata only and must never contain credentials/secrets; audit manual and discovery changes without raw sensitive content.
- **Tests/observability:** mapper/validation/reconciliation unit tests; API/constraint/transaction/isolation integration tests; frontend lint/build plus approved UI test approach; structured import counts/duration/outcome with correlation and no raw source logging.
- **Backward compatibility:** server imports, routes, DTOs and migration-owned fields remain unchanged. The migration is additive and is not auto-applied to production.
- **Dependencies:** approved work item and traceability; Q-01/OD-07 closure; TDA resolution of ADR-001 versus HLD DD-05; approved synthetic SQL source mapping; DBA/Migration SME review; test tooling/fixtures; restored package access.
- **Acceptance:** AC-01 to AC-14 in the next-phase section below.
- **Complexity:** XL.

### Roadmap Phase 4 - Application/Infrastructure Assessment and Dependency Management

- **Objective/outcome:** complete the assessment information automated discovery cannot supply and make dependency risk explicit before planning.
- **Scope:** structured application/server assessments, stakeholders/ownership, availability/SLA, maintenance, backup, licensing/vendor/migration requirements, typed directed dependencies, external systems, dependency validation and data-quality exceptions.
- **Exclusions:** customer-specific workflow code, autonomous decisions, wave approval and external integrations.
- **Domain/database:** add assessment/stakeholder/dependency/external-system and data-quality issue entities with tenant/project ownership, history, unique relationship rules and restricted deletion.
- **API/frontend:** assessment work queues and asset assessment pages; dependency CRUD/search/validation and dependency views; project data-quality summary.
- **Integration/Azure:** extend only approved file mappings; no direct APIs or new Azure services.
- **Tenancy/security/audit:** project-scoped relationships must prove both endpoints belong to the same tenant/project; minimise stakeholder personal data; audit assessment completion and dependency changes.
- **Tests/compatibility/observability:** positive/negative dependency graph cases, missing/circular/cross-wave-ready flags, personal-data/log checks and regression of inventory/import. Additive schema preserves Phase 3; privacy-safe metrics cover incomplete assessments and validation outcomes.
- **Dependencies/acceptance:** D-08 SME inputs, I-04 validation against representative datasets and configurable lookup decisions. Complete F-05/F-06 fields, expose unresolved quality blockers and never auto-approve.
- **Complexity:** XL.

### Roadmap Phase 5 - Internal Entra ID, RBAC and Security Foundation

- **Objective/outcome:** bind activity to authenticated users and enforce least privilege before approval, execution and sign-off workflows expand.
- **Scope:** internal Agilisys Entra authentication, claims-derived context, application users/memberships/roles, endpoint policies, authorised administration, privileged audit and removal of arbitrary production tenant headers.
- **Exclusions:** external customer access until Q-09 is approved; platform/Azure RBAC deployment beyond the approved environment design.
- **Domain/database:** users, customer/project memberships and role assignments; concurrency/audit fields; no local credentials.
- **API/frontend:** `/me`, authorised membership/role administration, forbidden/not-found behaviour, role-aware navigation/actions and session handling.
- **Integration/Azure:** Entra app registrations/configuration through approved identity owners; Key Vault/managed identity only where the approved environment exists.
- **Tenancy/security/audit:** token-derived tenant/project allow-list, deny by default, MFA/Conditional Access evidence, privileged elevation boundaries and every-route isolation matrix.
- **Tests/compatibility/observability:** authentication, policy, horizontal/vertical escalation, direct-object reference and audit tests. Development test authentication may remain only behind an explicit non-production configuration; auth failures, policy denials and privileged changes are observable without logging tokens or personal data.
- **Dependencies/acceptance:** Q-01, TDA/InfoSec approval and internal identity design. Q-09 remains a blocker only for external users. All in-scope endpoints require authentication and role/tenant/project authorisation.
- **Complexity:** XL.

### Roadmap Phase 6 - Migration Planning, Target Versioning, Rollback and External Execution Tracking

- **Objective/outcome:** turn assessments and dependencies into safe, governed migration plans with executable-by-humans artefacts and recorded outcomes.
- **Scope:** versioned target design/change impact, database wave membership, dependency-aware wave validation, readiness evidence/blockers, configurable draft runbooks, structured rollback plans, execution records/issues/evidence and approval states.
- **Exclusions:** actual migration, DNS/firewall/network changes, Azure provisioning and autonomous approval.
- **Domain/database:** target design versions, blockers/approvals, rollback plans/steps, execution sessions/events/issues/evidence metadata and expanded wave asset types.
- **API/frontend:** planning validation/approval endpoints, target-version comparison/impact pages, runbook/rollback editors and external execution tracker.
- **Integration/Azure:** evidence uses the approved storage abstraction when available; no migration or provisioning integration.
- **Tenancy/security/audit:** role-separated authors/reviewers/approvers, immutable approval history, tenant/project-scoped evidence and no claim that drafts are approved before an SME action.
- **Tests/compatibility/observability:** missing/circular/cross-wave dependencies, target changes, readiness blocking, approval transitions, rollback variation and proof no execution endpoint exists. Preserve current wave/runbook APIs or version changes explicitly; log and measure validation, approval and externally recorded execution outcomes without evidence contents.
- **Dependencies/acceptance:** Phases 4-5, D-09 target information and named technical SMEs. A wave cannot be approved with unresolved mandatory blockers; every wave has SME-approved draft runbook/rollback before external execution is recorded.
- **Complexity:** XL.

### Roadmap Phase 7 - Technical Testing, Business Validation and Sign-off

- **Objective/outcome:** provide objective evidence that migrated workloads are technically and operationally acceptable.
- **Scope:** test plans/cases/runs/results, technical validation, business test ownership/results, defects/exceptions, post-migration checks, conditional acceptance and final sign-off.
- **Exclusions:** automated execution of customer tests, replacement of external test tools and agent-granted risk acceptance.
- **Domain/database:** test plan/case/run/result, validation check, exception and sign-off entities with evidence references and immutable approval records.
- **API/frontend:** test/validation workspaces, evidence/result entry, exception disposition and role-authorised sign-off views.
- **Integration/Azure:** optional links/export only; evidence storage through the approved file boundary.
- **Tenancy/security/audit:** test evidence and sign-off are tenant/project/workload scoped; only authorised human roles sign; all state changes audited.
- **Tests/compatibility/observability:** transition, segregation-of-duties, evidence permission, failure/rollback-decision and regression tests. Additive extension of execution tracking; workflow failures, pending sign-offs and exception counts are observable without exposing test evidence.
- **Dependencies/acceptance:** Phase 5 identities/RBAC and Phase 6 execution records. Completion cannot be asserted without required technical and business results and named sign-off.
- **Complexity:** L.

### Roadmap Phase 8 - Reporting, Audit and Governance Dashboards

- **Objective/outcome:** eliminate manual status-pack assembly and make governance evidence retrievable.
- **Scope:** Master Inventory, wave, readiness, execution/test/sign-off and post-migration reports; Excel/CSV/PDF export; audit history API/UI; data-quality and governance dashboards.
- **Exclusions:** Power BI unless separately approved, customer-specific code forks and public APIs.
- **Domain/database:** report definitions/jobs/artefacts where needed; complete audit events and indexes/retention metadata; no parallel reporting database without evidence.
- **API/frontend:** tenant-authorised filters, report generation/download, audit timeline/search and expanded dashboards.
- **Integration/Azure:** use authorised Blob/report processing when Phase 9 infrastructure is available; asynchronous processing only where volume requires it.
- **Tenancy/security/audit:** server-side tenant binding, scoped storage paths/tokens, export authorisation, CSV formula escaping, privacy-safe fields and audit of generation/download.
- **Tests/compatibility/observability:** export correctness, formula injection, IDOR, large report timing, PDF/Excel/CSV structure and audit completeness. Existing dashboard/API behaviour remains compatible; report job duration/failure/size and authorised download events are measured and logged.
- **Dependencies/acceptance:** Phases 3-7 data, approved report formats and I-07 configuration approach. Required reports are reproducible from platform data and meet F-14/NF-13.
- **Complexity:** XL.

### Roadmap Phase 9 - Azure Production Deployment, Secure Ingestion and Observability

- **Objective/outcome:** make the application securely deployable, observable and recoverable in approved UK Azure environments.
- **Scope:** full Bicep, environment separation, hosting, Azure SQL topology per TDA decision, Blob quarantine/promotion, Defender scanning, Key Vault, managed identities, Front Door/WAF, private endpoints, monitoring/logging/alerts, backups, restore/DR automation and protected pipelines.
- **Exclusions:** production deployment by an agent, migration target provisioning and customer Azure network configuration.
- **Domain/database/API/frontend:** minimal product-domain change; health/readiness endpoints and storage/background-job status contracts may be added without changing business APIs.
- **Integration/Azure:** this is the Azure integration phase; every service, identity, network path, region and secret boundary requires approved architecture and least privilege.
- **Tenancy/security/audit:** storage/database topology must implement the approved tenancy ADR; UK residency, encryption, private data services, WAF, secure headers, retention/deletion and platform audit are mandatory.
- **Tests/compatibility/observability:** Bicep lint/validate/what-if, environment rebuild, deployment smoke, scanning/quarantine, backup/restore/DR, failure/retry, alert and cross-tenant storage tests. Promote identical artefacts; do not auto-apply production migrations.
- **Dependencies/acceptance:** Q-06, Q-08, Q-09 as applicable, OD-style hosting/region/cost decisions, D-02/D-05/D-06/D-10 and human-protected service connections. A test environment is reproducibly deployable and operational evidence is complete before production approval.
- **Complexity:** XL.

### Roadmap Phase 10 - Production Hardening, Accessibility, Scale and Release

- **Objective/outcome:** close residual defects/debt and present one evidence-backed release candidate to the human release authority.
- **Scope:** full regression, every-route isolation, 200+ asset and applicable HLD volume/performance tests, concurrency, accessibility/browser testing, penetration/security scans, dependency lifecycle, recovery drill, documentation, support handover, pilot/UAT and release/rollback evidence.
- **Exclusions:** scope expansion, risk acceptance by agents, autonomous merge/deploy and deferred Product Specification Phase 3 features.
- **Domain/database/API/frontend/integration:** only approved defect fixes and hardening; no redesign of working features. Compatibility and data-migration rehearsals use production-like non-production environments and synthetic/anonymised data.
- **Tenancy/security/audit/observability:** zero unresolved cross-tenant/high-security/data-loss issues; monitoring and audit evidence are reviewed against actual acceptance targets.
- **Tests:** all Definition-of-Done gates run against one commit/build, including API, UI, system, accessibility, performance, security, migration, backup/recovery, UAT and smoke plans.
- **Dependencies/acceptance:** Q-04 baseline for benefit claims, Q-06/Q-07/Q-08/Q-09/Q-10 as applicable, live pilot availability, InfoSec/DPO/Service Transition/PRB evidence and named human release decision.
- **Complexity:** XL.

## Next phase

### Selection

**Roadmap Phase 3 - SQL Discovery and Assessment** is selected as the next implementation phase, subject to the entry gates below.

Why it is next:

- C-03/F-04 explicitly require databases in the Master Inventory and C-04/F-05 require database assessment.
- The current All Inventory import already preserves non-server source rows and server snapshots record database instance counts, so the discovery staging pattern can be extended additively.
- It provides a complete user journey for the Database Specialist without waiting for production identity or Azure deployment.
- It creates the data required by later dependency, wave, readiness, target, test and reporting phases.
- It is separable from Q-09 external identity and from Q-03/Q-05 AI decisions because it retains the current context abstraction and contains no AI.

### Entry gates

Development must not start until:

1. A Product Owner/PRB-approved work item supplies an ID, traceability, scope, exclusions, success measure and data classification.
2. Q-01/OD-07 is closed by the Solution Architect/TDA for the existing .NET 10/EF Core 10/Next.js 16/React 19 stack.
3. TDA records whether ADR-001 shared-database tenancy remains the approved path or the unapproved HLD database-per-customer design supersedes it. The decision must include owner, date, approval evidence and affected references.
4. A Database SME and Product Owner approve at least one synthetic/anonymised source file, its schema/version, matching keys, target values and data-quality rules. No real customer data is used.
5. The frontend/E2E test approach and SQL Server-compatible migration verification approach are approved.
6. Package restore/build/test can run and establish a green pre-change baseline against the selected commit.

### Product Work Package summary

- **User story:** As a Database Specialist/Migration Architect, I need discovered SQL instances and databases consolidated and assessed in the selected customer/project so that database migration readiness, blockers and target approach can be governed without spreadsheets.
- **In scope:** approved file import; preview/commit; SQL instance/database inventory; server relationship; assessments/findings; allowed targets; audit/history; UI/API; tenant isolation; regression tests.
- **Out of scope:** dependencies/waves, approval/sign-off, external execution, Azure provisioning, direct discovery API, AI, XLSX unless the approved source contract requires it, and redesign of server discovery.
- **Personas:** Database Specialist, Migration Architect, Project Manager, authorised Reviewer/Auditor.
- **Success measure:** an approved synthetic SQL estate is imported, reconciled, assessed and re-imported without duplicate canonical records or loss of manual assessment; all isolation and regression tests pass.
- **Data classification:** customer migration metadata; service-account name only if confirmed non-sensitive. Credentials, secrets and real customer personal data are prohibited.
- **Product exit state:** `BLOCKED_PRODUCT_DECISION` until the approved work item and source contract exist; then `READY_FOR_ARCHITECTURE`.

## Next phase acceptance criteria

| AC | Acceptance criterion | Traceability |
|---|---|---|
| AC-01 | An authorised user can upload an approved SQL discovery/assessment file for the selected project; the file is validated and staged, and preview causes no canonical inventory or assessment change. | C-02, F-03, R-01, I-03 |
| AC-02 | Preview classifies supported SQL instance/database rows as Create, Update, Unchanged, Warning or Reject and exposes field-level differences and validation messages. | C-02, F-03, R-01 |
| AC-03 | Explicit commit transactionally creates/updates canonical SQL instances and databases, cannot run twice, detects stale previews and rolls back partial changes on failure. | C-02, C-03, F-03, F-04 |
| AC-04 | Matching is case-normalised and tenant/project/server aware; repeated import is idempotent and manually maintained assessment fields are never overwritten by discovery. | A-08, R-01, F-04, F-05 |
| AC-05 | Each canonical SQL instance has immutable ID, customer/project, source server, instance name, version, edition, optional valid port, optional non-sensitive service-account name, status and discovery metadata/history. | C-03, F-04, F-05 |
| AC-06 | Each canonical database has immutable ID, customer/project, SQL instance, name, non-negative size, compatibility level, recovery model, status and discovery metadata/history. | C-03, F-04, F-05 |
| AC-07 | A database assessment records assessment status, migration readiness, blockers, compatibility findings, target service/version, migration approach and human notes without making an autonomous decision. | C-04, F-05, A-11 |
| AC-08 | Allowed target outcomes are Azure SQL Database, Azure SQL Managed Instance, SQL Server on Azure VM, Retain, Retire and Investigate; invalid values are rejected or governed through the approved lookup policy. | C-04, F-05, F-07 |
| AC-09 | Paged/filterable API and UI views support SQL instances, databases and assessments, including navigation from server to instances and instance to databases. | C-03, C-04, F-04, F-05, NF-09 |
| AC-10 | Every SQL API, relationship, staging row, snapshot and audit operation is customer and project isolated; cross-tenant/cross-project IDs cannot be read, changed or enumerated. | F-01, F-02, F-15, NF-01, NF-02, R-02 |
| AC-11 | Unique/FK/check constraints and service validation reject duplicate instances/databases, orphan relationships, invalid ports/sizes and unsafe source rows; deletes do not silently remove governed history. | F-04, F-05, NF-06, R-01 |
| AC-12 | Creates, discovery-managed field changes and assessment changes write privacy-safe audit events with authenticated/development-test user and timestamp; raw source rows and secrets are not logged. | F-15, NF-04, NF-06 |
| AC-13 | Unit and integration tests cover mapping, validation, reconciliation, idempotency, stale/failed commit, protected assessment data, constraints and tenant/project isolation. Existing server import, inventory, IP, wave, readiness, runbook, dashboard and configuration regressions remain green. | NF-02, NF-08, NF-10, R-02, R-09 |
| AC-14 | The additive migration is reviewed for SQL Server/Azure SQL compatibility and rollback/redeployment; a synthetic 200+ combined-asset project remains usable without N+1 or unbounded list behaviour. No migration is auto-applied to production. | NF-08, NF-10, A-15 |

## Architecture impact

### Architecture recommendation

Preserve the modular monolith, REST/DTO boundary, EF Core, Next.js App Router, explicit import preview/commit and current tenant-context interface. Add a SQL module inside the existing API and web applications. Do not split services, add Kubernetes, add messaging or replace the current server import. Background processing remains a later production/non-functional concern unless an approved source volume proves it is required now.

The canonical data model should separate discovered facts from assessed/governed decisions:

```text
Server 1--* SqlInstance 1--* SqlDatabase
SqlInstance/SqlDatabase 1--* DiscoverySnapshot
SqlDatabase 1--0..1 DatabaseAssessment 1--* DatabaseAssessmentFinding
ImportBatch 1--* DiscoveryImportRow
```

This follows the HLD distinction between Inventory and Assessment and preserves ADR-005's rule that discovery may update technical facts but never overwrite human-governed migration data.

### Expected files/modules to change in implementation

- `src/api/Domain/Entities.cs` and `BusinessValues.cs` for additive SQL domain types and governed values.
- `src/api/Infrastructure/AppDbContext.cs`, a new reviewed EF migration and the model snapshot for keys, relationships, filters, constraints and indexes.
- New SQL-specific DTO/controller/service files; `Program.cs` only for required registrations.
- Existing discovery mapper/resolver/models/reconciliation/service only through additive source-specific paths; retain current server behaviours.
- `src/web/types/api.ts`, `AppShell.tsx`, discovery source/preview pages and new inventory/assessment routes.
- Unit and integration test projects plus synthetic versioned SQL test files under `tests/TestData`.
- Functional/architecture documentation and an ADR amendment only where a real decision is approved.

### Reusable patterns

- Immutable GUID identifiers and DTO-only API boundary.
- `ICurrentCustomerContext`, EF global customer filters and explicit project predicates.
- `ImportBatch`/`DiscoveryImportRow`, source mapper resolver, JSON staging and preview/commit lifecycle.
- Discovery-managed versus business-managed field separation and append-only snapshots.
- Problem Details, async EF operations, paged inventory lists and reusable Next.js API/context/UI components.
- Synthetic test factory with second-tenant fixtures and transaction failure tests.

### Implementation sequence after approval

1. Baseline source contract, field ownership and allowed values; record architecture/tenancy decisions.
2. Add domain/entities, EF configuration and additive migration with constraint review.
3. Add SQL inventory/assessment DTOs, service rules and API endpoints.
4. Extend discovery mapping, validation, preview/reconciliation, commit, snapshots and audit additively.
5. Add SQL frontend types, navigation, inventory/assessment pages and discovery presentation.
6. Add unit/integration/isolation/data-integrity/regression tests and approved frontend tests.
7. Run build/lint/tests/scans/migration checks against one commit and prepare the Implementation Work Package. Do not commit, push, merge or deploy unless separately authorised by the approved workflow.

### Likely technical blockers

- No approved SQL export/template or representative synthetic fixture is present.
- The HLD tenancy decision conflicts with ADR-001/current code and lacks approval evidence.
- Existing discovery types and reconciler are server-specific; extension must be additive and avoid an unsafe broad rewrite.
- The repository has no frontend test runner/E2E framework and no SQL Server integration-test environment.
- The current generic `AuditEvent` has no authorised read surface and several existing operations have audit gaps.
- `Database` is an ambiguous CLR/domain name; use a specific name such as `SqlDatabase` while keeping user-facing language clear.
- The integration tests use SQLite, which does not prove SQL Server/Azure SQL filtered indexes, constraints or migration behaviour.
- This assessment environment could not reach NuGet, so a clean API baseline must be re-established elsewhere.

### Architect exit state

`BLOCKED_ARCHITECTURE_DECISION` until Q-01/OD-07 and the tenancy conflict are formally resolved. Once resolved with the existing stack/pattern approved, the phase is suitable for `READY_FOR_DEVELOPMENT` without architectural redesign.

## Test strategy

### Functional scenarios

- Import named and default SQL instances, multiple instances on one server and multiple databases per instance.
- Preview each classification and field difference; commit and re-import unchanged data.
- Update discovered technical fields while preserving manual assessment and findings.
- Create/edit/list/filter SQL inventory and assessment; navigate server -> instance -> database.
- Record every allowed target outcome and migration approach/assessment status.
- Display discovery history/freshness and audit the change actor/time.

### Negative and abuse scenarios

- Unsupported source/schema/version, wrong headers, empty/oversized/malformed file, invalid encoding and source-type mismatch.
- Missing/unmatched server, blank instance/database name, duplicate case variants, duplicate source IDs and same-batch duplicates.
- Port outside 1-65535, negative/overflow size, invalid compatibility/recovery/target/status values and credential-like service-account input.
- Warning/reject rows never change canonical data; failed or stale commit is fully rolled back; repeat commit fails safely.
- Delete/update with governed children, broken FK, concurrency collision and transaction failure.
- Raw file/source content, credentials and sensitive values never appear in logs or errors.

### Tenant-isolation scenarios

- Customer A cannot list, fetch, create, update or delete Customer B instances, databases or assessments by changing IDs/headers.
- Two projects in the same customer cannot cross-read/write SQL inventory, staging rows, snapshots, assessment or audit.
- A SQL row cannot link to a server from another project/customer.
- Duplicate/business-key checks never reveal another tenant's record.
- Import history, row detail, commit/cancel and discovery history remain scoped to the authenticated/current project.
- Background/file/export coverage is added when those facilities enter scope; no cross-tenant cached data is introduced.

### Data integrity/API/frontend

- Verify primary/foreign keys, normalised unique indexes, check constraints, restricted deletes and additive migration on SQL Server/Azure SQL-compatible infrastructure.
- Verify pagination/filter bounds, Problem Details, not-found versus forbidden behaviour and DTO field exposure.
- Add mapper/reconciler/assessment rule unit tests and API integration tests for every endpoint and transition.
- Add approved frontend component/E2E coverage for lists, forms, validation, filters, relationships, preview/commit and error states; until tooling is approved, lint/build and documented browser testing are necessary but insufficient for final Definition of Done.
- Required fixtures: approved synthetic source; default/named instances; duplicate/case variants; invalid boundaries; multi-tenant/multi-project records; changed-after-preview data; transaction-failure hook; 200+ combined-asset dataset.

### Regression/build gates

- Existing 55 expanded API cases must pass after a clean restore/build, plus all new tests.
- Frontend lint and production build must pass; new routes must be present in the build output.
- Server discovery classifications, protected fields, snapshots and duplicate warnings must be unchanged.
- Application/server CRUD/relationships, migration decisions, targets, IP transitions, waves, readiness, runbooks, dashboard and configuration must remain green.
- Migration generation/status, formatting, secret/dependency/static analysis and applicable Bicep checks must be recorded in the Implementation Work Package.

### Tester recommendation

The Phase 3 criteria are independently testable once the source contract, frontend test approach and SQL Server migration environment are supplied. Until then the test package is `RETURN_TO_DEVELOPER`/blocked at entry, not a pass.

## Risks and dependencies

| Item | Impact | Required treatment/owner |
|---|---|---|
| Q-01 / OD-07 unresolved | AGENTS.md prohibits implementation start without approved stack decision. | Solution Architect/TDA records approval of the existing stack. |
| ADR-001 versus HLD DD-05 | Adding more tenant-owned tables could entrench an unapproved tenancy topology or cause later migration rework. | TDA chooses/supersedes with dated approval and migration implications. |
| No approved work item | Scope, acceptance and authority are not auditable. | Product Owner/PRB creates and approves the traced work package. |
| D-07 / I-03 SQL source contract absent | Field mapping, identifiers and supported format cannot be safely inferred. | Product Owner, Database SME and Migration Practice approve synthetic samples/mapping. |
| I-04 model validation absent | Model may reflect one project only. | Validate against at least two representative anonymised/synthetic migration shapes before baselining. |
| Q-02 budget/timeline unresolved | No delivery date or cost can be committed. | Product Owner/PRB reconciles before baselining; this report gives complexity only. |
| Q-09 external identity unresolved | External customer access cannot be implemented. | Keep Phase 3 internal/test-only; resolve before external access. |
| R-02 tenant leakage | Critical release blocker. | Every-endpoint/customer/project isolation automation and independent security testing. |
| R-01 poor source quality | Unsafe inventory/assessment and planning. | Versioned schema, validation, quality exceptions, explicit preview/commit and SME review. |
| R-09 dependency/framework drift | Restore/build or support failure. | Supported versions, lock files, dependency scans and lifecycle policy. |
| Test environment gap | SQLite does not prove SQL Server/Azure SQL behaviour. | Add approved SQL Server-compatible migration/constraint validation. |
| Audit debt | Governance history remains incomplete. | Phase 3 writes complete SQL events; Phase 8 completes retrieval and legacy gaps. |
| Production gates Q-06/Q-07/Q-08 | Privacy, commercial and service acceptance remain blocked. | DPO, Commercial/Product Owner and Managed Services/Service Transition decisions before release. |

## Product Definition of Done

A product work item is done only when:

- scope, exclusions, acceptance and C/F/NF/R/A/D/I/Q traceability are approved before implementation;
- required architecture, tenancy, security, privacy and data decisions have named, dated approval evidence;
- code and data changes preserve the modular monolith, working features, tenant isolation and immutable product boundaries;
- database changes are additive/backward-compatible or explicitly approved, reviewed, rehearsed and reversible;
- authentication, authorisation, validation, error, audit and privacy behaviours are implemented and independently evidenced;
- required unit, integration, UI/E2E, tenant-isolation, security, accessibility, performance and migration tests pass against the same commit/build;
- documentation, support, observability, deployment, compatibility and rollback notes are current;
- all residual defects/risks have disposition and only a named human risk owner has accepted any allowable residual risk;
- Tester issues a valid evidence recommendation and Quality Manager issues an independent recommendation;
- required human Product Owner, TDA/Architect, InfoSec, DPO, SME, Service Transition, PRB and release approvals are recorded as applicable;
- no agent merges, deploys production, executes migration, provisions Azure targets, uses real customer test data or represents an agent recommendation as human approval.

## Quality Manager decision

**ROADMAP APPROVED WITH CONDITIONS**

This means the sequencing, scope boundaries, selected next phase, acceptance criteria and test approach are suitable to submit for human approval. It does **not** mean Roadmap Phase 3 is authorised for development or that the product is release-ready.

Conditions:

1. Supply an approved work item and complete traceability package.
2. Close Q-01/OD-07 and formally resolve ADR-001 versus HLD DD-05 before implementation.
3. Approve the SQL source contract and synthetic fixtures with Product Owner/Database SME evidence.
4. Establish a green API build/test baseline and approve frontend plus SQL Server migration test approaches.
5. Keep Phase 3 free of AI, direct discovery APIs, migration execution, Azure provisioning, multi-cloud and unrelated redesign.
6. Re-review/retest any material scope, tenancy, identity, schema or import-contract change.
7. Obtain independent quality review: this single Codex run performed the requested sequential role assessments and therefore cannot substitute for the independent Quality Manager/human evidence gate required by AGENTS.md.

Quality gate state: `BLOCKED_PENDING_HUMAN_DECISION`.

## Hand-off envelope

```yaml
handoff:
  from_agent: "quality-manager"
  to_agent: "human-release-authority"
  state: "BLOCKED_PENDING_HUMAN_DECISION"
  work_item: "UNASSIGNED"
  branch: "feature/agilisys-ui-theme"
  commit: "b323b9cc513eb0385773d44f979dbfe7eb2222ad"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-02", "C-03", "C-04"]
    functional_requirements: ["F-01", "F-02", "F-03", "F-04", "F-05", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-04", "NF-06", "NF-08", "NF-09", "NF-10"]
    risks: ["R-01", "R-02", "R-09", "R-11"]
    assumptions: ["A-01", "A-02", "A-05", "A-06", "A-08", "A-13", "A-18"]
    dependencies: ["D-01", "D-07", "D-08", "D-11", "D-13"]
    issues: ["I-03", "I-04", "I-06", "I-08"]
    open_questions: ["Q-01", "Q-02", "Q-03", "Q-09"]
    approvals: []
  artefacts:
    - "docs/product/PRODUCT_GAP_ANALYSIS_AND_ROADMAP.md"
  evidence:
    - "Repository source inspection at b323b9c"
    - "Frontend lint and production build passed on 2026-09-03"
    - "API source tests inspected; execution not revalidated because NuGet access was blocked"
  decisions:
    - "Recommend Roadmap Phase 3 - SQL Discovery and Assessment"
    - "Move internal identity/RBAC before approval-heavy planning/execution increments"
  assumptions:
    - "Roadmap phases 3-10 remain Product Specification Phase 1 MVP completion increments"
  risks:
    - "Unresolved stack and tenancy architecture decisions"
    - "Missing approved SQL source contract"
  defects: []
  blockers:
    - "Approved work item/traceability missing"
    - "Q-01/OD-07 closure missing"
    - "ADR-001 versus HLD DD-05 unresolved"
    - "SQL source schema and test fixtures unapproved"
  approvals: []
  requested_action: "Human Product Owner/PRB and TDA approve the Phase 3 work package and resolve the listed gates."
```

## Next Codex command

```text
Operate under AGENTS.md for C:\Projects\lgr-transformation-migration and implement only the approved work item for Roadmap Phase 3 - SQL Discovery and Assessment.

Before any edit:
1. State the active role and process the work through Product Owner -> Architect -> Developer -> Tester -> Quality Manager with the required hand-off envelopes and separation of duties.
2. Read AGENTS.md, README.md, docs/product/PRODUCT_GAP_ANALYSIS_AND_ROADMAP.md, the Product Specification, HLD, all ADRs, functional/architecture docs, current code, tests, Bicep and azure-pipelines.yml.
3. Locate the named human-approved work-item ID, traceability header, SQL source contract/sample, Q-01/OD-07 approval and the dated TDA decision resolving ADR-001 shared-database tenancy versus HLD DD-05 database-per-customer. Do not infer or manufacture approvals. If any is absent, stop with BLOCKED_PRODUCT_DECISION or BLOCKED_ARCHITECTURE_DECISION and report exactly what evidence is missing.
4. Establish a green pre-change build/test/lint baseline. Use synthetic/anonymised data only.

Scope, only after all entry gates pass:
- Add additive SQL instance, SQL database, database assessment, assessment finding/blocker and SQL discovery snapshot models using immutable GUIDs, explicit customer/project ownership, FKs, unique/check constraints, indexes, audit fields and safe delete behaviour.
- Keep discovered technical fields separate from business-managed assessment fields. Discovery must never overwrite manual assessment or governance decisions.
- Extend the existing file-based ImportBatch/DiscoveryImportRow preview-and-explicit-commit workflow additively for the approved SQL source contract. Preserve every existing server-import behaviour and test.
- Provide tenant/project-scoped paged REST DTO APIs and Next.js pages for SQL instances, databases and assessments, including server -> instance -> database navigation.
- Support the approved assessment fields and only these target outcomes unless the approved work item says otherwise: Azure SQL Database, Azure SQL Managed Instance, SQL Server on Azure VM, Retain, Retire, Investigate.
- Treat service-account name as optional non-sensitive metadata only. Reject/avoid credentials and never log raw sensitive source data.
- Add privacy-safe audit events for SQL discovery and assessment changes.
- Implement AC-01 through AC-14 from docs/product/PRODUCT_GAP_ANALYSIS_AND_ROADMAP.md.

Guardrails:
- Preserve .NET 10, EF Core 10, Next.js 16, React 19, TypeScript, modular monolith, REST, SQL Server/Azure SQL compatibility, Bicep/Azure and the TDA-approved tenant-context architecture.
- Do not redesign or replace working Phase 1/2 features.
- Do not add microservices, Kubernetes, speculative messaging/frameworks, direct discovery APIs, migration execution, Azure target provisioning, AI, multi-cloud or real customer/personal data.
- Prefer an additive backward-compatible EF migration. Do not auto-apply it to production.
- Do not commit, push, merge, deploy production, use production credentials/data or approve your own work.

Developer hand-off must list changed files, schema/API/UI behaviour, exclusions, tenant/security/audit controls, test data, commands/results, compatibility and rollback. Tester must independently cover functional, negative, tenant/project isolation, data integrity, stale/failed commit, API, frontend, migration and regression scenarios. Quality Manager must verify traceability and same-build evidence and end with RECOMMEND_APPROVAL, REJECT or BLOCKED_PENDING_HUMAN_DECISION. No autonomous merge or deployment follows.
```
