# ADR-007: Phase 3 tenancy alignment

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-01", "C-02", "C-03", "C-04"]
  functional_requirements: ["F-01", "F-02", "F-03", "F-04", "F-05", "F-15"]
  non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-04", "NF-06", "NF-08", "NF-10", "NF-12"]
  risks: ["R-02", "R-09"]
  assumptions: ["A-01", "A-02", "A-16", "A-18"]
  dependencies: ["D-01", "D-03", "D-05", "D-10", "D-11"]
  issues: ["I-01", "I-02", "I-04"]
  open_questions: ["Q-01", "Q-06", "Q-09"]
  approvals: []
```

Status: Proposed - pending Solution Architect/TDA and Information Security approval

Proposed decision date: 3 September 2026  
Decision owners: Solution Architect / TDA; Information Security for the isolation control position  
Approval evidence: Pending - no named approval evidence is present in the repository.

## Context and conflict

ADR-001, accepted for Phase 1, implements a shared database/shared schema with `CustomerId` on customer-owned entities, `ProjectId` on project-owned entities, EF Core global customer filters and service-level project constraints. Phase 1 and Phase 2 code and tests use this model.

HLD DD-05 selects a catalogue plus database-per-customer model in an Azure SQL elastic pool for the production SaaS. That design adds connection-level isolation, per-customer restore and simpler deletion evidence. The repository does not implement its catalogue, connection routing, per-customer migration orchestration or production operational controls.

The two records therefore describe different persistence models. An agent cannot silently select one as the approved production architecture or overwrite the HLD decision.

## Proposed decision for the Phase 3 increment

Retain the implemented shared database/shared schema as the Phase 3 development and non-production increment baseline. Every new SQL Instance, SQL Database, SQL Assessment, staging, audit and relationship record carries `CustomerId` and `ProjectId`; global filters, explicit project predicates, same-tenant relationship validation and database constraints remain mandatory.

Do not refactor to database-per-customer as part of PH3-SQL-001. That is a materially different platform change requiring an approved product/architecture work item, tenant catalogue and routing design, migration tooling, recovery/offboarding design, cost model, operational ownership, security approval and proportionate retest.

This recommendation is not approval to use the shared model for production customer processing. Production tenancy remains blocked until TDA explicitly decides whether to:

1. supersede HLD DD-05 with the shared tenant-aware model and update the HLD/security/DR/offboarding controls; or
2. retain DD-05 and approve a separate transition before production.

## Rationale

- It avoids an unapproved, high-risk platform rewrite during a bounded domain increment.
- It preserves the repository's tested EF query-filter, tenant-context and transaction patterns.
- SQL discovery and assessment can be designed with tenant keys that remain valid if records are later partitioned into customer databases.
- It makes the unresolved production decision visible instead of implying that either document has already won.

## Mandatory security implications

- `CustomerId` and `ProjectId` are copied from authenticated server-side context; request payloads cannot select ownership.
- Every request path applies global customer filters and explicit project predicates. Inaccessible identifiers return a non-enumerating not-found response.
- Relationships are validated in the same customer/project and backed by composite alternate keys/foreign keys for new Phase 3 entities where supported.
- No request handler may use `IgnoreQueryFilters`; background processing requires an explicit audited tenant scope.
- Tenant-scoped unique indexes, import files, staging rows, audit records, caches and logs must not leak cross-customer data.
- The current development headers and Demo Council fallback are not production identity controls. Production requires validated Entra-derived claims and Q-09 closure.
- Automated horizontal/vertical access, direct-object reference, import/history and relationship tests are release-blocking. Independent security testing remains required before production.
- Azure SQL Row-Level Security may be assessed as defence in depth for a shared production model, but application correctness must not depend on it and its introduction needs its own design and tests.

## Future migration implications

If DD-05 remains the production target, a separate approved transition must:

- introduce a catalogue database and claim-derived tenant-to-connection routing;
- obtain per-customer connection material from Key Vault without constructing it from user input;
- apply and verify EF migrations across all customer databases with drift detection and safe retry;
- export, transform, load and reconcile each customer's data using reversible, audited tooling and no cross-customer staging;
- preserve immutable GUIDs, ownership fields and audit history;
- define cutover, rollback, backup/restore, retention, offboarding and failed-tenant handling;
- run isolation, recovery, performance and operational tests against the target topology; and
- prohibit autonomous production migration or deletion by agents.

Designing Phase 3 entities with ownership columns and immutable GUIDs reduces, but does not eliminate, this future work.

## Documentation changes required on approval

- Update this ADR to Accepted with named approvals and evidence.
- Amend ADR-001 status/scope to show whether it remains authoritative or is superseded.
- Amend the HLD DD-05/Section 5.4 position, or explicitly record it as the future production target with transition gate and owner.
- Update `POC_Architecture.md`, `Data_Model.md`, security/DR/offboarding documentation and automated test requirements consistently.
- Link the approved decision from PH3-SQL-001 and the restored/superseding product roadmap.

Until those approvals are recorded, the tenancy prerequisite remains `BLOCKED_ARCHITECTURE_DECISION` for Phase 3 implementation.
