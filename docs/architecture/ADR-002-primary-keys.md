# ADR-002: Immutable GUID primary keys

Status: Accepted

## Decision

Use immutable `Guid` values as database primary keys for all entities. Treat names, customer codes, IP addresses and hostnames as mutable business attributes. Enforce `CustomerId + Hostname` as the server business-uniqueness rule.

## Consequences

Relationships remain stable when assets are renamed, imports can be reconciled without using mutable keys, and future distributed ingestion can generate IDs without a central sequence. GUID indexes are larger than integer indexes; later production work may consider sequential GUID generation while preserving the contract.
