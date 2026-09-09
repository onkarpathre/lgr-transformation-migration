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
  approvals:
    - "Solution Architect/TDA PT (GitHub reviewer: PTArchitect), 8 September 2026: accepted with conditions for the local/non-production PH3-SQL-001 POC technology baseline only — https://github.com/onkarpathre/lgr-transformation-migration/pull/2#pullrequestreview-5147899102"
```

Status: Accepted - local/non-production PH3-SQL-001 POC scope only; conditions apply

Decision date: 8 September 2026

Decision owner: Solution Architect / Technical Design Authority

Approver: PT (`PTArchitect`), Solution Architect/TDA

Approval target commit: `127c3099b0fdb452259433daa472704d6820e241`

Approval evidence: https://github.com/onkarpathre/lgr-transformation-migration/pull/2#pullrequestreview-5147899102

## Context

Product Specification Q-01 and HLD OD-07 record a conflict between the HLD stack and an earlier development-plan stack. Phase 1 and Phase 2 have since been implemented consistently with the HLD direction. At the reviewed baseline, `LgrTransformationMigration.Api.csproj` targets `net10.0` and pins EF Core SQL Server/Design `10.0.11`; `src/web/package.json` pins Next.js `16.2.12`, React/React DOM `19.2.8` and TypeScript `5.9.3`. The merge commit for PR #1 adds the PH3-SQL-001 approval/architecture documents only; it is not implementation or TDA approval evidence.

The named Solution Architect/TDA approval makes this decision effective only for local/non-production PH3-SQL-001 POC development. It closes Q-01/HLD OD-07 for that restricted scope; it does not approve a wider MVP or production baseline and does not close production hosting, identity, tenancy, support, DPIA, commercial or release gates.

## Evidence

- The Product Specification Appendix A names Next.js/React and ASP.NET Core/.NET but marks the stack subject to Q-01.
- HLD Table 19 names the same application technologies and OD-07 says a single stack must be approved before build.
- The repository already contains the modular monolith, DTO REST APIs, EF migrations, SQL Server provider and Next.js App Router implementation described above.
- Microsoft records [.NET 10 as active LTS through 14 November 2028](https://dotnet.microsoft.com/en-us/platform/support/policy) and [EF Core 10 as supported through November 2028](https://learn.microsoft.com/en-us/ef/core/what-is-new/).
- Vercel records [Next.js 16 as Active LTS](https://nextjs.org/support-policy) and requires [Node.js 20.9 or later for Next.js 16](https://nextjs.org/docs/app/guides/upgrading/version-16). The Node.js project records [Node.js 24 as an LTS line and Node.js 20 as end-of-life](https://nodejs.org/en/about/previous-releases) at the review date.

## Accepted decision

Baseline one application stack for the Phase 3 SQL Discovery and Assessment increment:

- Backend: .NET 10, ASP.NET Core, EF Core 10, SQL Server for local/provider verification, and Azure SQL-compatible schema and SQL.
- Frontend: Next.js 16 App Router, React 19 and TypeScript.
- JavaScript runtime: pin a supported Node.js 24 LTS patch in development, CI and any later host; do not rely only on Next.js's minimum runtime. Commit the npm lock file.
- Application shape: the established modular monolith with DTO-based REST APIs; no microservices or messaging are introduced for this increment.
- Infrastructure posture: Azure-ready and Bicep-defined where infrastructure is later approved. This ADR does not authorise Azure provisioning or production deployment.
- Testing: xUnit unit/integration tests, a mandatory SQL Server provider lane for provider-specific schema behaviour, and an approved frontend component/browser test stack in addition to lint and production build.

Use the latest approved `10.0.x` .NET/EF patch and aligned approved Next.js 16/`eslint-config-next` patches after restore/build/test, licence, dependency and vulnerability review. Exact version changes are Developer work after this ADR is accepted; this ADR does not modify dependencies.

The Python/FastAPI/Flask, Node.js API and Angular alternatives described by the conflicting development plan are not part of this proposed baseline.

## Rationale

- It matches the authoritative HLD direction and the existing Phase 1/2 implementation.
- Reusing the established application, persistence, tenant-context, API and test patterns avoids an unjustified rewrite.
- .NET 10 and EF Core 10 provide a supported LTS-aligned backend and first-party SQL Server/Azure SQL integration.
- The selected frontend versions are already locked by the repository and preserve the established App Router implementation.
- A modular monolith keeps transaction boundaries for staged import and canonical reconciliation local and testable.

## Alternatives considered

### A. .NET 10 / Next.js 16 modular monolith - recommended

Retains the implemented HLD-aligned stack and preserves the current domain, tenant-context, DTO, migration and import patterns. Main costs are disciplined lifecycle management and independent SQL Server/browser assurance.

### B. Rewrite the API in Python/FastAPI/Flask or Node.js

Rejected for PH3-SQL-001 because it replaces functioning Phase 1/2 code, EF migrations and tests without a product requirement or evidence of compensating value. It also creates a parallel persistence/security implementation during a tenant-sensitive increment.

### C. Replace Next.js with Angular or maintain two frontends

Rejected for this increment because it duplicates UI architecture and testing, breaks the established App Router implementation and does not improve a PH3-SQL-001 acceptance criterion.

### D. Keep the stack decision open while allowing feature work

Rejected. It perpetuates Q-01/R-11 and makes dependency, test, skills and delivery evidence non-reproducible. `AGENTS.md` explicitly blocks implementation until the decision record is approved.

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
- Node.js 24 and Next.js 16 lifecycle/security updates must be reviewed more frequently than the .NET LTS line. CI must make the selected Node version reproducible.
- The repository's Next.js `16.2.12` and `eslint-config-next` `16.2.11` patch mismatch must be assessed and aligned through a reviewed dependency update rather than silently changed by this ADR.
- This decision does not close external identity, production hosting, tenancy, support, DPIA, commercial or deployment gates.

## Approval scope and conditions

PT approved ADR-006 with conditions for local/non-production PH3-SQL-001 development and approved the POC technology baseline. The accepted scope is not the wider MVP or any production environment. All lifecycle, dependency, SQL Server provider-test and frontend-test conditions in this ADR remain binding and must be carried into the Architecture Work Package and implementation hand-off.

The PR #2 approval envelope is also preserved: no production deployment, production tenancy architecture, real customer data, destructive database changes, migration execution or autonomous provisioning is approved.

## Approval record

```text
Decision: ACCEPTED WITH CONDITIONS
Approver: PT
GitHub reviewer account: PTArchitect
Role: Solution Architect / TDA
Date: 8 September 2026
GitHub review submission state: APPROVED
Approved scope: Local/non-production PH3-SQL-001 development; POC technology baseline only.
Conditions: Retain every lifecycle, dependency, SQL Server provider-test and frontend-test condition in this ADR and every PR #2 scope exclusion. No production deployment, production tenancy architecture, real customer data, destructive database change, migration execution or autonomous provisioning is authorised.
Q-01 / HLD OD-07 disposition: Closed for the restricted PH3-SQL-001 local/non-production POC scope only; unresolved for any wider MVP or production baseline.
Approval target commit: 127c3099b0fdb452259433daa472704d6820e241
Pull Request: https://github.com/onkarpathre/lgr-transformation-migration/pull/2
Evidence link: https://github.com/onkarpathre/lgr-transformation-migration/pull/2#pullrequestreview-5147899102
```

Product Specification Q-01, HLD OD-07, I-08 and R-11 are superseded only for this approved local/non-production POC scope. This record is not PRB, Information Security, production, merge, release or deployment approval.
