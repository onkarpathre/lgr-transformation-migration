# ADR-001: Shared-database tenant isolation

Status: Accepted for Phase 1

## Decision

Use a shared database/schema. Store `CustomerId` on every customer-owned entity and apply EF Core global query filters. Store `ProjectId` on project-owned entities and constrain application-service operations to the selected project. Resolve the current context through `ICurrentCustomerContext`.

The POC implementation accepts development headers with configured Demo Council fallbacks. Production must replace this resolver with validated Microsoft Entra ID claims and reject arbitrary tenant headers.

## Consequences

This is cost-effective and Azure SQL compatible, makes tenant isolation testable from the first migration, and avoids per-customer operational overhead. Developers must not use `IgnoreQueryFilters` in request handling. Background jobs will require an explicit, audited tenant scope. Defence-in-depth row-level security can be evaluated later.
