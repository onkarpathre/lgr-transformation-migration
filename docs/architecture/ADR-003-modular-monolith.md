# ADR-003: Modular monolith

Status: Accepted for Phase 1

## Decision

Implement a single ASP.NET Core deployment containing the domain, application services, persistence and REST endpoints, paired with one Next.js web application. Keep business rules in services and expose DTO contracts. Do not introduce microservices, messaging, Kubernetes or speculative integration frameworks.

## Consequences

The primary migration journey can be developed, tested and deployed as one coherent unit. Transaction boundaries are simple and local development needs only SQL Server Express. Clear service and contract boundaries leave room to extract a module later only if operational evidence justifies it.
