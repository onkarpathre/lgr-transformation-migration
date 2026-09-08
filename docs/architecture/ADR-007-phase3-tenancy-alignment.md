# ADR-007: Phase 3 tenancy alignment

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-01", "C-02", "C-03", "C-04"]
  functional_requirements: ["F-01", "F-02", "F-03", "F-04", "F-05", "F-15"]
  non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-04", "NF-05", "NF-06", "NF-08", "NF-10", "NF-11", "NF-12"]
  risks: ["R-02", "R-09", "R-11"]
  assumptions: ["A-01", "A-02", "A-15", "A-16", "A-18"]
  dependencies: ["D-01", "D-03", "D-04", "D-05", "D-10", "D-11"]
  issues: ["I-01", "I-02", "I-04"]
  open_questions: ["Q-01", "Q-06", "Q-09"]
  approvals: []
```

Status: Proposed - pending Solution Architect/TDA and Information Security approval

Proposed decision date: 3 September 2026

Decision record reviewed: 8 September 2026 against baseline commit `579171c927905876640cdf6bcb48ee8261b6c301`

Decision owners: Solution Architect / Technical Design Authority; Information Security for the isolation control position

Approval evidence: Pending - no named approval evidence is present in the repository.

## Decision required

The repository and HLD contain different tenant persistence models. A named human authority must decide both the bounded PH3-SQL-001 development topology and the production target. This ADR recommends a two-horizon decision but does not approve it:

1. retain shared database/shared schema persistence for PH3-SQL-001 local development and approved non-production POC use, with strengthened tenant-aware keys and controls; and
2. retain HLD DD-05 database-per-customer as the proposed production target until TDA either confirms it and commissions a transition or expressly supersedes it with an approved shared-production design.

No production customer processing, tenant-model migration, catalogue implementation or production deployment is authorised by this record.

## Evidence and conflict reconciliation

| Source | Evidence | Architectural effect |
|---|---|---|
| Product Specification F-01, F-02, F-15 and NF-01/NF-02 | Requires logical customer/project isolation, RBAC and prevention of cross-tenant access; it does not mandate one physical database topology. | Either topology must prove the same authorisation, isolation and audit outcomes. |
| HLD DD-05 and Sections 5.4/6 | Select a catalogue plus database per customer in an Azure SQL elastic pool, with customer database resolution after authentication. | This is the stated HLD production design, but the reviewed HLD is draft and its TDA readiness/approval fields contain no approval evidence. |
| ADR-001 (repository status: Accepted for Phase 1) and current persistence implementation | Use one shared schema with `CustomerId` on customer-owned data, `ProjectId` on project-owned data, EF Core global customer filters and service-level project predicates. ADR-001 contains no named decision owner, approval date or approval evidence. | This is the implemented local POC/non-production baseline; it is not equivalent to DD-05 and cannot silently supersede it. |
| Current identity/context implementation | Development headers and a configured Demo Council fallback establish tenant context locally. | These are development conveniences, not production identity or isolation controls. Production must fail closed on validated Entra-derived context. |
| PR #1 merge commit `579171c927905876640cdf6bcb48ee8261b6c301` | Adds the PH3-SQL-001 work item, approval pack, architecture package and ADRs. | It proves Product Owner approval of a bounded local POC planning package only. It is not TDA, Information Security, persistence-topology or production approval. |

The repository does not implement the DD-05 tenant catalogue, claim-to-database routing, per-customer connection resolution, fleet migration orchestration, drift control, per-customer backup/restore operations or offboarding workflow. Conversely, the HLD does not describe the composite ownership constraints and project-scoped invariants required to make the current shared schema a defensible production topology. Neither the ADR-001 label nor implementation history supplies the owner/date/approval evidence needed to supersede an open baseline conflict. Treating either position as already approved would conceal R-11 and breach the decision authority in `AGENTS.md`.

## Recommended decision

### Horizon 1: PH3-SQL-001 local development and approved non-production POC

Retain the implemented shared database/shared schema for this bounded increment. New SQL Instance, SQL Database, SQL Assessment, import staging, snapshot, audit and relationship records must carry the appropriate `CustomerId` and `ProjectId`. The design must enforce:

- tenant context derived server-side and validated so that the project belongs to the authenticated customer;
- global customer query filters plus explicit project predicates for every project-scoped operation;
- tenant-leading alternate keys and composite foreign keys so a relationship cannot cross customer or project boundaries even if application validation fails;
- tenant-scoped unique indexes, reconciliation, idempotency, background work, files, caches, audit records and exports;
- non-enumerating responses for inaccessible identifiers and no payload-controlled ownership;
- fail-closed production configuration with no Demo Council fallback or trusted tenant headers; and
- independent cross-tenant, direct-object-reference, relationship, import, history, export and concurrency tests.

The detailed keys, foreign keys, indexes and test conditions are normative in `Phase3_SQL_Discovery_Assessment_Architecture.md` once this ADR and the work package are approved.

### Horizon 2: production target

Retain DD-05 as a proposed target rather than claiming the current shared topology is production-approved. Before pilot/production, TDA must choose and approve one of these outcomes:

- **Confirm database per customer.** Commission a separately scoped transition including catalogue, claim-derived routing, Key Vault integration, customer database lifecycle, fleet schema migration/drift control, recovery, monitoring, cost/capacity, offboarding and audited data movement.
- **Supersede DD-05 with shared production persistence.** Amend the HLD and ADR-001, document compensating controls and obtain Information Security approval. The design must cover database defence in depth (including a decision on Azure SQL Row-Level Security), connection privilege, backup/restore granularity, retention/deletion evidence, noisy-neighbour/capacity controls, incident containment, export/offboarding and tenant-isolation assurance.

PH3-SQL-001 must not implement either production change by implication.

## Rationale

- It avoids an unapproved, high-risk platform rewrite during a bounded domain increment.
- It preserves the repository's tested EF query-filter, tenant-context and transaction patterns.
- SQL discovery and assessment can be designed with tenant keys that remain valid if records are later partitioned into customer databases.
- It makes the unresolved production decision visible instead of implying that either document has already won.

## Alternatives considered

### A. Two-horizon alignment - recommended

Use the existing tenant-aware shared topology only for the bounded local/non-production increment while preserving DD-05 as the proposed production target pending a formal decision and transition.

Consequences:

- Phase 3 implementation can reuse current EF Core and transaction patterns only after this ADR and the architecture work package are approved.
- Every new relationship and uniqueness rule carries customer/project ownership, even though a future per-customer database may make `CustomerId` physically redundant.
- A later topology transition remains material work and will invalidate affected test and operational evidence.
- This option does not establish production readiness.

### B. Approve the shared database/shared schema for production

This would minimise near-term application change and fleet migration complexity, but a single filter/authorisation defect could expose multiple customers. Point-in-time restore, deletion evidence, incident containment and noisy-neighbour management are also harder at customer granularity.

This option is not rejected in principle, but it cannot be selected by the Architect Agent. It requires explicit HLD/ADR supersession, TDA and Information Security approval, a production control design and production-grade independent isolation testing.

### C. Implement database per customer within PH3-SQL-001

This aligns directly with DD-05 but is not recommended for this work item. It introduces catalogue/routing, secrets, fleet migration, recovery, monitoring and operational failure modes unrelated to the approved SQL discovery outcome. The repository lacks the necessary platform components and the local POC approval explicitly does not grant that scope.

### D. Schema per customer in one database

This offers some namespace separation but complicates EF model/migration management and does not provide the connection-level isolation or per-customer restore advantages of DD-05. It also diverges from both existing implementation and the HLD without a compensating product need. Not recommended.

### E. Separate application deployment per customer

This could increase blast-radius isolation but contradicts the shared multi-tenant SaaS boundary, multiplies release/support overhead and is not the HLD design. Rejected unless PRB changes the product architecture and operating model.

## Mandatory security implications

- `CustomerId` and `ProjectId` are copied from authenticated server-side context; request payloads cannot select ownership.
- A project context is accepted only after proving `(CustomerId, ProjectId)` membership and role authorisation. Missing or ambiguous context fails closed.
- Every request path applies global customer filters and explicit project predicates. Inaccessible identifiers return a non-enumerating not-found response.
- Relationships are validated in the same customer/project and backed by tenant-leading composite alternate keys and foreign keys for new Phase 3 entities. Simple GUID foreign keys alone are insufficient in the shared topology.
- EF global customer filters are defence in depth, not the only authorisation control. No request handler may use `IgnoreQueryFilters`; background processing requires a narrow, audited, server-created tenant scope and separate authorisation.
- Tenant-scoped unique indexes, import files, staging rows, history, snapshots, exports, caches and logs must not leak cross-customer data. Cache keys include both customer and project identifiers.
- The current development headers and Demo Council fallback are not production identity controls. Production requires validated Entra-derived claims and Q-09 closure.
- Automated horizontal/vertical access, direct-object reference, import/history and relationship tests are release-blocking. Independent security testing remains required before production.
- Production services use least-privilege identities and authorised secret resolution. Customer connection strings, credentials and service-account secrets are never model inputs, API responses, logs or audit values.
- Azure SQL Row-Level Security may supplement a shared production model, but it cannot repair missing application authorisation or composite ownership constraints. Its session-context, connection-pooling and bypass-role behaviour needs dedicated threat modelling and tests.
- NF-04 UK residency, encryption, backup/recovery, retention, deletion and DPIA obligations apply regardless of physical topology.

## Database-per-customer transition requirements

If DD-05 remains the production target, a separate approved transition must:

- introduce a catalogue containing only the minimum tenant-routing metadata and define its ownership, resilience and recovery;
- resolve customer databases from validated Entra/customer claims, never from model/client-supplied database names or connection strings;
- obtain connection material server-side from Key Vault with least-privilege managed identities and no secret return path;
- define database creation/onboarding through protected human-approved infrastructure workflows, not application or agent provisioning;
- apply and verify additive EF migrations across all customer databases with version inventory, drift detection, retry, partial-failure quarantine and auditable outcomes;
- migrate each customer's data with reversible, checksum/reconciliation-based tooling and without cross-customer staging;
- preserve immutable GUIDs, ownership fields and audit history;
- define cutover, compatibility window, data-preserving rollback, failed-tenant handling and forward-fix rules;
- define per-customer backup/restore, retention, legal hold, export, deletion evidence and offboarding;
- demonstrate isolation, restore, performance, capacity, observability and service support against the target topology; and
- prohibit autonomous production migration, database creation/deletion or customer-data access by agents.

Designing Phase 3 entities with ownership columns and immutable GUIDs reduces, but does not eliminate, this future work.

## Human decision questions and acceptance conditions

The Solution Architect/TDA decision must state:

1. whether shared database/shared schema is approved for PH3-SQL-001 local development and which non-production environments, if any;
2. whether DD-05 remains the production target or is superseded;
3. if DD-05 remains, the transition owner, decision/work-item reference and latest gate by which it must complete;
4. if shared production is selected, the approved database, identity, isolation, backup/restore, capacity, retention/deletion, incident and offboarding controls;
5. whether Azure SQL Row-Level Security is required, deferred or rejected, with rationale;
6. which tenant model is in scope for performance, security, recovery and release evidence; and
7. any effect on ADR-001, the HLD, Q-06, Q-09, I-01/I-02/I-04 and R-02/R-11.

Information Security must approve the isolation/threat-control position for the selected scope. Any approval must name the approver and role, date, scope, conditions and durable evidence link. A prompt or agent-authored edit is not approval evidence.

## Documentation changes required after approval

- Change this ADR to Accepted only after genuine approval evidence is recorded.
- Amend ADR-001 status/scope to show whether it remains authoritative, is bounded to local/non-production use or is superseded.
- Amend the HLD DD-05/Section 5.4 position, or explicitly record it as the future production target with transition gate and owner.
- Update `POC_Architecture.md`, `Data_Model.md`, security, identity, DR, retention/offboarding and automated-test documentation consistently.
- Link the approval and conditions from PH3-SQL-001 and any transition work item.

Until those approvals are recorded, ADR-007 remains Proposed. The Phase 3 Architecture Work Package is `READY_FOR_ARCHITECTURE_APPROVAL`; it must not be reissued as `READY_FOR_DEVELOPMENT`, and implementation remains blocked by the architecture decision.
