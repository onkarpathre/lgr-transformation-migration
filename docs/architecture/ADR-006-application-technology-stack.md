# ADR-006: Application technology stack baseline

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-01", "C-02", "C-03", "C-04", "C-05", "C-06", "C-07", "C-08", "C-09", "C-10", "C-11"]
  functional_requirements: ["F-01", "F-02", "F-03", "F-04", "F-05", "F-06", "F-07", "F-08", "F-09", "F-10", "F-11", "F-12", "F-13", "F-14", "F-15"]
  non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-08", "NF-09", "NF-10", "NF-11", "NF-12", "NF-13"]
  risks: ["R-09", "R-11"]
  assumptions: ["A-01", "A-14", "A-15"]
  dependencies: ["D-01", "D-04", "D-13"]
  issues: ["I-08"]
  open_questions: ["Q-01"]
  approvals: []
```

Status: Proposed - pending Solution Architect/TDA approval

Proposed decision date: 3 September 2026  
Decision owner: Solution Architect / Technical Design Authority  
Approval evidence: Pending - no named approver, approval date or evidence link is present in the repository.

## Context

Product Specification Q-01 and HLD OD-07 record a conflict between the HLD stack and an earlier development-plan stack. Phase 1 and Phase 2 have since been implemented consistently with the HLD direction. The current repository targets .NET 10 and EF Core 10 for the API and Next.js 16, React 19 and TypeScript for the web application.

An agent-authored recommendation cannot close Q-01/OD-07. Under `AGENTS.md`, the decision becomes effective only when the named Solution Architect/TDA records approval evidence.

## Proposed decision

Baseline one application stack for the Phase 3 SQL Discovery and Assessment increment:

- Backend: .NET 10, ASP.NET Core, EF Core 10, SQL Server for local/provider verification, and Azure SQL-compatible schema and SQL.
- Frontend: Next.js 16 App Router, React 19 and TypeScript.
- Application shape: the established modular monolith with DTO-based REST APIs; no microservices or messaging are introduced for this increment.
- Infrastructure posture: Azure-ready and Bicep-defined where infrastructure is later approved. This ADR does not authorise Azure provisioning or production deployment.
- Testing: xUnit unit/integration tests, a mandatory SQL Server provider lane for provider-specific schema behaviour, and an approved frontend component/browser test stack in addition to lint and production build.

The Python/FastAPI/Flask, Node.js API and Angular alternatives described by the conflicting development plan are not part of this proposed baseline.

## Rationale

- It matches the authoritative HLD direction and the existing Phase 1/2 implementation.
- Reusing the established application, persistence, tenant-context, API and test patterns avoids an unjustified rewrite.
- .NET 10 and EF Core 10 provide a supported LTS-aligned backend and first-party SQL Server/Azure SQL integration.
- The selected frontend versions are already locked by the repository and have passed earlier delivery checks.
- A modular monolith keeps transaction boundaries for staged import and canonical reconciliation local and testable.

## Lifecycle policy

- Pin production dependencies through project and lock files; do not use floating major versions.
- Apply supported patch/security updates through a reviewed work item with build, regression, dependency and vulnerability evidence.
- Review .NET, EF Core, Next.js, React, Node.js and TypeScript support status at least quarterly and before each release gate.
- Plan frontend major upgrades separately because the Next.js support cadence is shorter than the .NET LTS lifecycle, as noted by HLD recommendation RC-01.
- Unsupported runtime/framework versions block release unless a named human risk owner records time-bound acceptance through the approved process.

## Consequences

- Phase 3 code can extend existing projects and patterns after the decision is approved.
- Provider-specific relational constraints, filtered indexes, collation and EF migrations must be verified on SQL Server; SQLite remains a fast isolated integration provider, not the sole database assurance lane.
- New frontend test dependencies require licence/vulnerability review and a separate implementation change.
- This decision does not close external identity, production hosting, tenancy, support, DPIA, commercial or deployment gates.

## Approval required

To close Q-01/OD-07, update this ADR with:

- `Status: Accepted`;
- named Solution Architect/TDA approver;
- approval date;
- decision scope and any conditions;
- durable approval evidence link; and
- confirmation that Product Specification Q-01, HLD OD-07, I-08 and R-11 are superseded for the approved scope.

Until then, implementation remains `BLOCKED_ARCHITECTURE_DECISION`.
