# Data Model

## Core relationships

```text
Customer 1--* Project
Project  1--* Application
Project  1--* Server
Application *--* Server           through ApplicationServer
Application 1--* MigrationDecision
Server 1--0..1 AzureTarget
Subnet 1--* IpAddress 0..1--1 Server
MigrationWave 1--* WaveAsset      -> Application and/or Server
Application/Server 1--* ReadinessCheck
MigrationWave 1--* Runbook 1--* RunbookTask
Customer 1--* AuditEvent
Project 1--* ImportBatch 1--* DiscoveryImportRow
ImportBatch 1--* ServerDiscoverySnapshot *--1 Server
LookupOption                         global or customer-specific
```

Every persisted primary key is an immutable `Guid`. Hostname is a business identifier and is unique only within a customer through `UX_Servers_CustomerId_Hostname`. Azure targets are unique per customer/server. IP address records are unique within customer/subnet, and an additional filtered index prevents one server having multiple active reservations/allocations.

Discovery file bytes are outside the database. `ImportBatch` retains file identity and counts, `DiscoveryImportRow` retains original source JSON and preview results, and `ServerDiscoverySnapshot` retains append-only technical history. `Server.LastImportBatchId` links the current canonical view to its latest committed source.

## Tenant columns and indexes

All business entities except the tenant root contain `CustomerId`; project data also contains `ProjectId`. `RunbookTask` intentionally repeats these ownership keys. Customer/project and common status fields are indexed where they drive tenant lists or dashboard counts.

## Delete behaviour

Core ownership references use `Restrict` to prevent accidental programme-data loss. Pure association/owned-detail rows use cascade delete: application/server joins, wave assets, readiness checks and runbook tasks. The POC returns a conflict when a restricted relationship prevents deletion.

## Readiness algorithm

For an application or server:

1. no checks is `NotReady`;
2. any `Blocked` check is `Blocked`;
3. otherwise any `NotStarted` check is `NotReady`;
4. more than one `AtRisk` check is `AtRisk`;
5. exactly one `AtRisk` check is `ReadyWithConditions`;
6. all remaining checks `Complete` or `NotApplicable` is `Ready`;
7. any other combination is `NotReady`.

This ordering is deterministic and intentionally conservative for Phase 1.

## IP lifecycle

Only these transitions are valid: `Available -> Reserved`, `Reserved -> Allocated`, and `Allocated -> Released`. Reservation requires a server in the current tenant/project. A server cannot hold another active reserved or allocated record. `AzureReserved` and `Excluded` are inventory terminal states in this POC.

## Lookup configuration

`LookupOption.CustomerId = null` denotes a global default; a customer ID denotes a future customer override/extension. API queries return active global values plus values for the current customer. Domain-critical lifecycle values remain central constants so they cannot drift between services.
