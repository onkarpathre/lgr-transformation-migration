# POC Architecture

## Purpose

The Phase 1 product proves a governed Local Government cloud-migration journey while remaining small enough to run on a developer workstation. The system is a modular monolith: one ASP.NET Core API owns domain rules and persistence, one Next.js application presents the programme UI, and one relational database is the source of truth.

## Runtime topology

```text
Browser / Next.js 16
        |
        | REST + Customer/Project context headers
        v
ASP.NET Core 10 API
  Controllers -> Application services -> EF Core 10
        |             |                  |
        |             |                  +-- global customer query filters
        |             +-- readiness, IP and runbook rules
        +-- DTOs, validation and Problem Details
        |
        v
SQL Server Express (local) / Azure SQL Database (future)
```

Controllers are deliberately thin. `ProgrammeService` coordinates POC CRUD and programme queries; `IpAllocationService`, `ReadinessCalculator` and `RunbookService` contain the important deterministic business rules. EF entities never cross the API boundary.

## Multi-tenancy and identity

All customer-owned records carry `CustomerId`; all project-owned records also carry `ProjectId`. `RunbookTask` includes both even though it is reached through a runbook, preventing a future direct query from losing its tenant boundary. EF Core global query filters use `ICurrentCustomerContext`, and service queries enforce the selected project.

For local development, context comes from `X-Customer-Id`, `X-Project-Id` and `X-User-Name`, with fictional configured defaults. A future Entra implementation will populate the same interface from validated claims. Headers must not be trusted in production.

## API and frontend

REST endpoints live under `/api`; list endpoints for applications and servers are paged. Validation failures, missing records, uniqueness conflicts and unexpected failures use RFC Problem Details. Swagger is available in Development.

The Next.js App Router application is client-rendered for API-driven POC screens. `ApiProvider` adds the current context to every request, and the application shell provides customer/project selection. It does not include hardcoded business rows: defaults are context labels only while the API starts; page content comes from the API.

## Database and seed strategy

The EF migration creates SQL Server-compatible tables, foreign keys, indexes, check constraints and fixed fictional seed data. CIDRs are not expanded. Each demo subnet contains ten manageable IP records, enough to show capacity and transitions without thousands of rows.

Integration tests replace SQL Server with a new in-memory SQLite relational database per test. This tests relationships and unique constraints without shared cleanup or a local SQL dependency.

## Future Azure deployment

The anticipated production topology is Front Door/WAF, managed web hosting, Azure SQL, Blob Storage, Key Vault, Entra ID, Application Insights and Log Analytics. The Bicep skeleton creates monitoring only when explicitly enabled; networking, managed identity, private endpoints, secrets, backups, scaling, security policies and deployment approvals require a later architecture review.
