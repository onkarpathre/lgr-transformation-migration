# ADR-008: Internal authentication, principal contract and project RBAC

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-01", "C-03", "C-04", "C-06"]
  functional_requirements: ["F-01", "F-02", "F-04", "F-15"]
  non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-06", "NF-10", "NF-11", "NF-12"]
  risks: ["R-02", "R-09"]
  assumptions: ["A-01", "A-02", "A-03", "A-16", "A-18"]
  dependencies: ["D-03", "D-04", "D-10", "D-11", "D-13"]
  issues: ["I-02", "I-06"]
  open_questions: ["Q-06", "Q-09"]
  approvals:
    - "Solution Architect/TDA approval by GitHub account PTArchitect, 10 September 2026: local/non-production implementation and testing scope only — https://github.com/onkarpathre/lgr-transformation-migration/pull/3#pullrequestreview-5164009938"
    - "Information Security approval by GitHub account nextgenexamprep-crypto, 10 September 2026: local/non-production implementation and testing scope only — https://github.com/onkarpathre/lgr-transformation-migration/pull/3#pullrequestreview-5164020739"
    - "Product Owner role-mapping confirmation by GitHub account opathre, 10 September 2026: local/non-production scope only — https://github.com/onkarpathre/lgr-transformation-migration/pull/3#issuecomment-5614835348"
```

Status: Accepted - local/non-production implementation and testing scope only

Decision date: 9 September 2026

Acceptance date: 10 September 2026

Decision owner: Solution Architect / Technical Design Authority

Security decision owner: Information Security

Approved architecture commit: `09078a048cb99a24d6a89552843d955b643a219b`

Approval evidence:

- Solution Architect/TDA approval by GitHub account `PTArchitect`, 10 September 2026: <https://github.com/onkarpathre/lgr-transformation-migration/pull/3#pullrequestreview-5164009938>
- Information Security approval by GitHub account `nextgenexamprep-crypto`, 10 September 2026: <https://github.com/onkarpathre/lgr-transformation-migration/pull/3#pullrequestreview-5164020739>
- Product Owner role-to-permission mapping confirmation by GitHub account `opathre`, 10 September 2026: <https://github.com/onkarpathre/lgr-transformation-migration/pull/3#issuecomment-5614835348>

These decisions accept ADR-008 and the associated PH3-SQL-ARCH-001 amendment only for PH3-SQL-001 implementation and testing in the expressly approved local/non-production scope. They do not authorise production identity configuration, external customer identity, production tenancy, production deployment, real customer data, migration execution or release.

## Context

PH3-SQL-001 requires every SQL inventory path to enforce an authenticated customer and project context and a permitted project role. The independent Tester raised `PH3SQL-TST-002` because the SQL Instance and SQL Database endpoints register no authentication scheme or authorisation policy and do not verify actor membership or project role. Record-level customer/project predicates and tenant-leading database constraints are present, but possession of synthetic context headers is sufficient to exercise full local/test CRUD.

The Product Specification requires Microsoft Entra ID or an approved Microsoft identity service, least-privilege RBAC, tenant isolation and no cross-customer access under F-15, NF-01 and NF-02. The HLD selects Microsoft Entra ID for Agilisys users, prohibits local credentials, requires tenant and role authorisation on every API, and lists broad application roles. It does not define the token-to-principal contract, project-membership authority, exact SQL Inventory permission mapping, local/test simulation or denial semantics.

ADR-007 permits the shared-schema model only for restricted local/non-production PH3-SQL-001 POC work and requires server-side customer/project authorisation. It does not approve a production identity or tenancy model. Q-09 remains open for external customer identity and is not closed or bypassed by this decision.

The repository currently has no application principal, customer-membership or project-membership model. `CurrentCustomerContext` reads `X-Customer-Id`, `X-Project-Id` and `X-User-Name` in Development/Testing and fails closed elsewhere. Those headers are development conveniences, not authentication or role evidence.

The Product Specification and HLD files are authoritative baselines for this work, but their own document-control tables do not contain completed approval evidence. PR #3 records Solution Architect/TDA and Information Security approval of this ADR and its PH3-SQL-ARCH-001 amendment, plus Product Owner confirmation of the role-to-permission mapping, against approved architecture commit `09078a048cb99a24d6a89552843d955b643a219b`. Every decision is restricted to PH3-SQL-001 local/non-production implementation and testing and does not approve any production identity, tenancy, customer-data, deployment or release scope.

## Decision scope

This decision defines:

- authentication for Agilisys internal human users;
- the normalized internal principal and project-authorization contracts;
- server-side customer/project membership authority;
- the Phase 3 project roles relevant to SQL Inventory;
- the exact SQL Instance and SQL Database CRUD permission matrix;
- local-development and automated-test identity simulation;
- deny-by-default, isolation, audit, service-to-service and error behaviour; and
- the security tests required to resolve the architectural part of `PH3SQL-TST-002`.

It does not:

- choose or implement the external customer identity model governed by Q-09;
- approve production identity configuration, production tenancy or production deployment;
- create an identity-administration UI or API;
- create application code, tests, migrations, database objects or Azure resources;
- grant Platform Administrator cross-customer access;
- change the approved SQL inventory data model or migration; or
- weaken the feature flag, tenant predicates, composite ownership constraints or independent test requirements in ADR-007 and PH3-SQL-ARCH-001.

## Decision

Use Microsoft Entra ID for authentication and an application-owned, server-side membership and policy service for customer/project authorization. Entra proves who the caller is and whether the caller may invoke the API. The application membership store proves which customer/project the principal may access and which business permissions apply there.

Token groups, Entra directory roles, email addresses, display names, client-supplied customer IDs and caller-supplied role/permission headers are not customer/project authorization authority.

### 1. Identity provider and API token validation

For the internal PH3-SQL-001 scope:

- Human users authenticate against the Agilisys Microsoft Entra workforce tenant through a single-tenant, environment-specific application registration.
- The browser application uses OAuth 2.0/OpenID Connect authorization code flow with PKCE and requests a delegated API access token. An ID token is never accepted as an API bearer token.
- The API accepts only v2.0 access tokens issued by the configured Agilisys tenant for the exact environment-specific API audience.
- Human tokens must contain delegated scope `lgr.access`. The calling client application ID in `azp` must be in the environment's server-side allow-list.
- The API validates signature, signing key, issuer, audience and lifetime using the supported Microsoft identity middleware. Issuer and `tid` must identify the same configured tenant.
- Conditional Access and MFA are enforced in Entra configuration. The API does not infer MFA from a caller-controlled value or make authorization depend on mutable display claims.
- Each environment has separate app registrations, identifiers and configuration. A token issued for another environment, tenant, audience or client is rejected.

Microsoft documents `oid` as the immutable Entra object identifier, `tid` as the tenant identifier, `azp` as the v2 client application identifier, `scp` as delegated scopes and `roles` as application/user roles. It also states that display `name` is mutable and must not drive authorization: <https://learn.microsoft.com/en-us/entra/identity-platform/access-token-claims-reference>.

### 2. Required validated Entra claims

The authentication layer must validate or require the following before creating an internal principal:

| Claim / property | Human delegated token | Workload app-only token | Use |
|---|---:|---:|---|
| `iss` | Required | Required | Exact configured v2 issuer; validated cryptographically. |
| `aud` | Required | Required | Exact API audience for the environment. |
| `exp` and token lifetime | Required | Required | Reject expired or otherwise invalid lifetime. |
| `nbf` when present | Validated | Validated | Reject token before its validity window. |
| `ver` | Must be `2.0` | Must be `2.0` | Prevent mixed v1/v2 claim interpretation. |
| `tid` | Required GUID | Required GUID | Must equal the configured Agilisys workforce tenant. |
| `oid` | Required GUID | Required GUID | Immutable directory object/service-principal identifier. |
| `sub` | Required | Required | Token subject; for an approved app-only token it must equal `oid`. |
| `azp` | Required GUID | Required GUID | Must be an allowed web client or service client for the environment. |
| `scp` | Must contain `lgr.access` | Must be absent | Distinguishes and authorizes delegated human API access. |
| `roles` | Not project authority | Must contain `Lgr.Api.Service` | Coarse application permission for an explicitly allowed workload caller only. |
| `name`, `preferred_username` | Optional | Not used | Display only; never a key, membership or permission input. |

A token that mixes the delegated human scope with the workload-only application role is rejected. Inbound claims using the application's private `urn:agilisys:lgr:*` namespace are removed before authorization context is built.

Microsoft's protected-web-API guidance requires APIs to verify delegated scopes for user calls and application roles for daemon calls, and recommends distinct user and application roles: <https://learn.microsoft.com/en-us/entra/identity-platform/scenario-protected-web-api-verification-scope-app-roles>.

### 3. Internal principal contract

After token validation, the authentication adapter resolves or creates no authorization by itself. It maps the validated identity to this immutable request principal:

```text
InternalPrincipal
  PrincipalId: Guid                 application-owned immutable identifier
  PrincipalType: Human | Workload
  IdentityProvider: EntraId
  DirectoryTenantId: Guid           validated tid
  DirectoryObjectId: Guid           validated oid
  ClientApplicationId: Guid         validated azp
  Subject: string                   validated sub
  DisplayName: string?              non-authoritative display snapshot only
  AuthenticationScheme: EntraBearer | LocalTest
```

The stable external key is `(IdentityProvider, DirectoryTenantId, DirectoryObjectId, PrincipalType)`. Email address, UPN, display name and `sub` are not membership keys. The application-owned `PrincipalId` is the audit and relationship key; for the existing string-only audit contract its canonical representation is `entra:{tid}:{oid}` for humans and `entra-app:{tid}:{oid}` for workloads until a separately reviewed schema change adds a principal foreign key.

Project authorization produces a second immutable, request-scoped object:

```text
ProjectAuthorizationContext
  Principal: InternalPrincipal
  CustomerId: Guid                  derived from authorized membership
  ProjectId: Guid                   validated selected project
  ProjectRoles: read-only set<ProjectRole>
  Permissions: read-only set<Permission>
  MembershipVersion: opaque value
```

Only the authentication/membership adapter may create the private server-side claims below. Domain services should consume the typed principal/context interfaces rather than parse tokens or headers directly.

- `urn:agilisys:lgr:principal-id`
- `urn:agilisys:lgr:principal-type`
- `urn:agilisys:lgr:customer-id`
- `urn:agilisys:lgr:project-id`
- repeated `urn:agilisys:lgr:project-role`
- repeated `urn:agilisys:lgr:permission`
- `urn:agilisys:lgr:membership-version`

The context is fixed for one request. It cannot be replaced or widened after a controller/service begins work.

### 4. Customer and project membership authority

The authoritative business-authorization source is an application-owned membership service backed by the approved server-side data store for the environment. Its logical contract is:

```text
SecurityPrincipal
  PrincipalId, PrincipalType, IdentityProvider,
  DirectoryTenantId, DirectoryObjectId, ClientApplicationId?, Status

CustomerMembership
  CustomerId, PrincipalId, Status, ValidFromUtc, ValidUntilUtc?, Version

ProjectMembership
  CustomerId, ProjectId, PrincipalId, Status, ValidFromUtc, ValidUntilUtc?, Version

ProjectMembershipRole
  CustomerId, ProjectId, PrincipalId, ProjectRole
```

Required invariants:

- Principal external keys are unique and immutable. Disabled principals fail closed.
- A ProjectMembership references an active CustomerMembership for the same principal/customer and a Project owned by that customer.
- Roles are unique within a principal/project. Unknown role values are invalid and confer no permission.
- Disabled, expired, not-yet-valid or missing membership confers no access.
- The selected ProjectId is an untrusted context selector. The membership lookup derives CustomerId from the matching active ProjectMembership; the client never chooses CustomerId as authority.
- Entra groups or app roles may be used later to control coarse application assignment, but they do not create, replace or widen customer/project membership.
- Customer Administrator may manage memberships only through a separately approved administrative workflow for its own customer. It receives no SQL data permission merely by being an administrator.
- Platform Administrator cross-customer access requires the separately approved PIM/elevation and audit design in HLD TI-05. There is no implicit bypass or wildcard in this ADR.
- Membership and role changes require optimistic concurrency, least-privilege administration and append-only audit. No such administration endpoint is authorized by PH3-SQL-001.

For the restricted shared-schema POC, the membership store must preserve `(CustomerId, ProjectId, PrincipalId)` ownership. If the production database-per-customer topology is approved later, the same contract remains but membership/catalogue placement and routing are governed by the production tenancy decision.

### 5. Project roles and exact SQL Inventory permissions

The applicable Phase 3 project roles are:

- `DatabaseSme` - HLD Database SME / DBA; maintains SQL Instance and SQL Database inventory.
- `MigrationArchitect` - reviews inventory to support assessment and planning; SQL assessment/decision permissions are outside this CRUD decision.
- `ProjectManager` - monitors project inventory and progress.
- `DiscoveryAnalyst` - reviews SQL inventory in support of file-based discovery. Import preview/commit uses separate permissions in a later approved slice.
- `ReviewerAuditor` - read-only review of authorized project information and evidence.

Canonical permissions are:

- `sql.inventory.read`
- `sql.inventory.create`
- `sql.inventory.update`
- `sql.inventory.delete`

`delete` means the existing logical archive operation only. This decision grants no hard-delete permission.

| Project role | GET list/detail (`read`) | POST (`create`) | PUT (`update`) | DELETE logical archive (`delete`) |
|---|---:|---:|---:|---:|
| `DatabaseSme` | Allow | Allow | Allow | Allow |
| `MigrationArchitect` | Allow | Deny | Deny | Deny |
| `ProjectManager` | Allow | Deny | Deny | Deny |
| `DiscoveryAnalyst` | Allow | Deny | Deny | Deny |
| `ReviewerAuditor` | Allow | Deny | Deny | Deny |
| Any other, unknown, customer-level or platform role | Deny | Deny | Deny | Deny |

Permissions are the union of the caller's active project roles, after principal and membership status checks. A disabled/suspended principal or membership overrides all role allows. There are no wildcards. Customer Administrator and Platform Administrator do not inherit SQL Inventory access; they need an explicit active project role, except for a future separately approved elevated support path.

The same policy applies to SQL Instance and SQL Database routes:

- `GET /api/v1/sql-instances` and `GET /api/v1/sql-instances/{id}` require `sql.inventory.read`.
- `POST /api/v1/sql-instances` requires `sql.inventory.create`.
- `PUT /api/v1/sql-instances/{id}` requires `sql.inventory.update`.
- `DELETE /api/v1/sql-instances/{id}` requires `sql.inventory.delete`.
- `GET /api/v1/sql-databases` and `GET /api/v1/sql-databases/{id}` require `sql.inventory.read`.
- `POST /api/v1/sql-databases` requires `sql.inventory.create`.
- `PUT /api/v1/sql-databases/{id}` requires `sql.inventory.update`.
- `DELETE /api/v1/sql-databases/{id}` requires `sql.inventory.delete`.

Legacy aliases, if retained, invoke the identical policies and services. No route alias may create a weaker authorization surface.

### 6. Deny-by-default and tenant/project isolation

- Authentication middleware runs before authorization and controller/feature filters.
- An ASP.NET Core fallback policy requires an authenticated principal for every endpoint. Only explicitly reviewed liveness/readiness probes may use anonymous access, and they return no identity, tenant, database or dependency detail. Microsoft recommends a fallback policy to protect newly added endpoints by default: <https://learn.microsoft.com/en-us/aspnet/core/security/authorization/secure-data?view=aspnetcore-10.0>.
- Each SQL action also requires its named permission policy. Authentication alone and `lgr.access` alone never grant SQL access.
- Missing configuration, identity-store failure, membership-store failure, ambiguous membership, unknown role or unhandled policy state fails closed. There is no Demo Council, first-project or first-customer fallback.
- `X-Project-Id` may remain an untrusted project selector for the existing internal API contract. A syntactically valid value grants nothing; the server must resolve an active membership and derive CustomerId. A later route-based selector is equivalent if it uses the same authorization service.
- `X-Customer-Id` is not accepted as production authority. CustomerId never comes from route, query, body, cookie, browser storage or a forwarded identity header.
- After authorization, all SQL reads/writes retain explicit ProjectId predicates, global CustomerId filters, same-owner relationship checks and ADR-007 composite database constraints.
- A caller with access to project A cannot enumerate project B through list counts, IDs, ETags, parent relationships, errors, import/history, cache entries or audit records.
- Authorization caches are optional. If introduced, a key includes PrincipalId, CustomerId, ProjectId and membership version; revocation/status change invalidates it. Cache failure cannot produce an allow.
- Background work uses a server-created immutable job scope containing CustomerId, ProjectId, initiating PrincipalId and authorization evidence. A queue message alone is not authority; the worker revalidates its service grant and the job ownership before data access.

### 7. Local-development and automated-test identity simulation

No local username/password store is introduced. A dedicated `LocalTest` authentication adapter may simulate the same InternalPrincipal and membership interfaces only when all of these conditions hold:

1. The host environment is exactly `Development` or `Testing`.
2. `Authentication:Mode` is explicitly `LocalTest`.
3. only synthetic, allow-listed principal aliases and memberships are loaded from non-secret local/test configuration or the test host;
4. startup fails if LocalTest is selected in any other environment; and
5. no LocalTest configuration is shipped as enabled in default or production settings.

In automated tests, `WebApplicationFactory` installs a test authentication handler and fixed synthetic membership provider. In local development, `X-Lgr-Test-Principal` may select one preconfigured alias. It cannot contain a GUID, customer, project, role, permission, email or arbitrary claim. Unknown aliases fail authentication. `X-Project-Id` remains an untrusted selector and must match the selected alias's active membership.

Minimum synthetic principals are:

| Alias | Membership purpose |
|---|---|
| `dba-project-a` | Active `DatabaseSme` in customer A/project A. |
| `reader-project-a` | Active `ReviewerAuditor` in customer A/project A. |
| `architect-project-a` | Active `MigrationArchitect` in customer A/project A. |
| `manager-project-a` | Active `ProjectManager` in customer A/project A. |
| `analyst-project-a` | Active `DiscoveryAnalyst` in customer A/project A. |
| `dba-project-a2` | Active `DatabaseSme` in the same customer, different project. |
| `dba-project-b` | Active `DatabaseSme` in a different customer/project. |
| `unassigned` | Authenticated principal with no membership. |
| `disabled` | Disabled principal or membership. |

The current `X-Customer-Id`, `X-User-Name` and configured Demo Council/user fallbacks are superseded for identity simulation by this accepted contract within the restricted local/non-production implementation and testing scope.

### 8. Prohibited trusted identity headers outside local/test

In every environment other than Development/Testing:

- `Authentication:Mode` must be `Entra`; the application fails startup if Entra issuer, audience, tenant or allowed clients are absent.
- `X-Customer-Id`, `X-User-Name`, `X-Lgr-Test-Principal`, `X-Principal-Id`, `X-Roles`, `X-Project-Roles`, `X-Permissions` and any `urn:agilisys:lgr:*` value supplied by the caller are never trusted.
- The edge should strip those headers and the API must ignore them for identity/authorization and record a safe security signal if received. The API must not silently fall back to them when bearer authentication fails.
- `X-Project-Id` is the sole permitted existing context selector, is not an identity claim and always requires server-side membership validation.

Forwarded network headers needed for reverse-proxy operation are outside this identity contract and require an explicit trusted-proxy configuration; they cannot convey user, tenant, role or permission.

### 9. Auditing and security telemetry

Successful SQL create/update/archive audit events must record:

- server-derived CustomerId and ProjectId;
- immutable application PrincipalId, or the canonical stable principal string where the current schema has only `ChangedBy`;
- principal type;
- action and entity identifier;
- UTC timestamp;
- correlation ID; and
- no raw bearer token, authorization header, mutable username as the sole actor key, or sensitive request value.

Read access is recorded in bounded operational access logs rather than field-level AuditEvent rows unless a later compliance decision requires read auditing. The logs contain the internal PrincipalId, permitted project scope, route template, HTTP method, outcome and correlation ID, not raw query values or SQL inventory names.

Authentication failures, invalid claims, disallowed client applications, missing/expired membership, permission denials, cross-scope object attempts, receipt of prohibited identity headers and membership-store failures generate structured security events. Expected 401/403/404 outcomes do not log raw tokens, token payloads, headers, display names or another tenant's record details.

Any future principal, customer-membership, project-membership, role or status change is a significant administrative event under NF-06. It records the acting principal, target PrincipalId, customer/project, old/new role or status, UTC time, correlation ID and approval/elevation reference where applicable. Membership audit is append-only and tenant scoped.

### 10. Service-to-service access

Azure-hosted services authenticate with Microsoft Entra managed identity or approved workload identity federation, never shared API keys, passwords or client secrets. Microsoft recommends managed identity for secretless service-to-service authentication: <https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview>.

For PH3-SQL-001 Slice 1:

- the interactive SQL CRUD routes accept delegated human principals only;
- app-only tokens are denied on those routes even when they carry `Lgr.Api.Service`;
- the API's managed identity for Azure SQL, Storage or Key Vault is infrastructure access and does not confer application project permissions; and
- no background service is granted SQL Inventory DELETE or a cross-customer wildcard.

A future service endpoint must be separately declared as workload-enabled, validate an app-only token and allowed `azp`/`oid`, require `Lgr.Api.Service`, and resolve an explicit active `ServiceProjectGrant` from the server-side membership authority. A proposed import/reconciliation worker may receive only `sql.inventory.read`, `sql.inventory.create` and `sql.inventory.update` for the job's customer/project; delete remains denied. That future endpoint/workflow requires its own approved work item and abuse tests.

### 11. Error responses

All responses use the approved Problem Details shape with `type`, `title`, `status`, safe `detail`, `instance`, `errorCode` and `correlationId`.

| Condition | Status | `errorCode` | Disclosure rule |
|---|---:|---|---|
| Missing/invalid/expired/wrong-issuer/wrong-audience token | 401 | `authentication_required` | Include `WWW-Authenticate: Bearer`; do not identify the failed claim or token value. |
| Valid token has no `lgr.access`, uses a disallowed client or is app-only on a human route | 403 | `api_access_denied` | Do not identify an allowed client, scope or principal type. |
| Malformed project selector | 400 | `invalid_project_context` | State only that the selector is invalid. |
| Required project selector absent | 400 | `project_context_required` | Do not list the caller's memberships. |
| Valid selector but no active customer/project membership | 404 | `resource_not_found` | Do not confirm that the project exists. |
| Active member lacks the required SQL permission | 403 | `permission_denied` | Do not list roles that would grant access. |
| SQL entity/parent is missing or outside authorized scope | 404 | `resource_not_found` | Same response for missing and inaccessible. |
| Authorization/membership service unavailable | 503 | `authorization_unavailable` | Fail closed; no fallback identity or cached allow beyond an explicitly valid cache entry. |

Existing 409, 412 and 428 SQL business/concurrency responses remain unchanged after authorization succeeds. Feature-disabled SQL routes may continue returning the existing non-enumerating 404, but the feature flag is not authorization and cannot create an anonymous or role-free path when enabled.

## Required security tests

The following tests are mandatory and release-blocking for the affected SQL endpoints.

### Authentication and token validation

- Missing bearer token returns the approved 401 contract on every SQL route.
- Reject invalid signature, wrong issuer, wrong `tid`, wrong audience, expired/not-yet-valid token, non-v2 token, missing/malformed `oid` and an ID token used as an access token with 401; reject disallowed `azp`, missing `lgr.access` scope and the wrong principal type with `api_access_denied` 403.
- Reject a delegated/app-only claim-type confusion, including a workload role on a human-only route and inbound `urn:agilisys:lgr:*` claim injection.
- Prove the fallback policy protects a newly mapped endpoint unless it is explicitly reviewed as anonymous.

### Membership and RBAC

- Execute every row/column combination in the SQL CRUD permission matrix for both SQL Instance and SQL Database routes.
- Prove multiple active roles produce only the documented union; unknown roles produce no allow.
- Prove Customer Administrator and Platform Administrator have no implicit SQL access.
- Prove missing, disabled, expired, not-yet-valid and mismatched customer/project membership denies access.
- Prove membership revocation/version change invalidates any authorization cache.
- Prove a role/permission header cannot add or widen access.

### Tenant and project isolation

- For customer A/project A, attempt list, detail, create-parent, update, re-parent and archive using IDs from customer A/project A2 and customer B/project B; verify no data, counts, ETags or existence signals leak.
- Prove a ProjectId selector derives CustomerId from membership and that a spoofed `X-Customer-Id` has no effect.
- Repeat direct-object and relationship attacks for SQL Instance-to-Server and SQL Database-to-Instance.
- Prove legacy route aliases, feature enabled/disabled paths, audit/history paths and any authorization cache use the identical scope.
- Prove background-job scope cannot be changed by message payload and that the worker revalidates its service project grant.

### Local/test and production-safety controls

- In Development/Testing, only allow-listed synthetic aliases authenticate; arbitrary alias/claim/GUID/role input fails.
- The read-only alias cannot mutate; the DBA alias can perform only its member project CRUD.
- A production-like environment fails startup with `LocalTest` mode or incomplete Entra configuration.
- In a production-like environment, every prohibited identity header is ignored as authority and produces no access; bearer failure never falls back to headers/configuration.
- No real user identity or customer data appears in fixtures, logs or snapshots.

### Service-to-service, audit and errors

- Reject app-only tokens on human SQL CRUD routes, including an otherwise valid managed-identity token.
- Reject wrong service audience/client/role and missing project grant on any future workload-enabled route.
- Prove no service grant includes delete or wildcard cross-customer access in this scope.
- Successful mutations record stable actor, principal type, tenant/project, UTC timestamp and correlation ID; `ChangedBy` is not based solely on mutable display name.
- Authentication/authorization failures create safe structured security signals without raw token/header/customer data.
- Verify every 400/401/403/404/503 status/error code above, including both 403 codes, and prove missing versus inaccessible resources are indistinguishable.

Independent Tester evidence must run against the exact implementation commit. Any cross-customer disclosure, missing authentication policy or privilege escalation is a release-blocking failure under F-15, NF-01, NF-02 and R-02.

## Alternatives considered

### A. Entra authentication plus application-owned project membership and permission policies - recommended

This separates identity proof from customer/project business authorization. It supports users with different roles in different projects, makes revocation and audit explicit, avoids token-size/group-overage coupling, and remains valid whether production uses shared schema or database per customer.

Costs are a new principal/membership abstraction, administration lifecycle, policy tests and eventual persistence work. Those are necessary controls rather than optional feature complexity.

### B. Put customer, project and application roles entirely in Entra groups or token app roles

Rejected. Project membership changes during programmes, a user may hold different roles in many projects, token claims are stale until refresh and group/app-role naming creates an external identity/configuration dependency. It also makes customer/project authorization vulnerable to claim/configuration drift and complicates Q-09. Entra remains coarse API assignment authority, not the system of record for project membership.

### C. Trust `X-Customer-Id`, `X-Project-Id`, `X-User-Name` and role headers

Rejected outside a tightly gated synthetic LocalTest adapter. Headers are caller controlled, provide no cryptographic identity proof and reproduce the `PH3SQL-TST-002` defect. Even in LocalTest, only an allow-listed alias and untrusted ProjectId selector are permitted; customer and roles come from the synthetic server-side membership fixture.

### D. Use local application accounts and issue application JWTs

Rejected. It contradicts NF-01, HLD ID-06 and DD-07, creates password/credential storage and account lifecycle obligations, and duplicates Entra controls.

### E. Resolve external customer identity and multi-tenant federation now

Deferred. Entra External ID, B2B guests or another external approach remains Q-09/OD-01 and needs Solution Architect and Information Security approval before customer-access implementation. The internal principal/membership interfaces are provider-neutral enough to support the approved future adapter without granting external access now.

## Consequences

- `PH3SQL-TST-002` has an accepted architecture contract for the restricted local/non-production scope but remains open until it is implemented and independently retested against the exact implementation commit.
- The current header-derived context and Demo Council/user fallback cannot remain the Phase 3 authorization mechanism under the accepted local/non-production implementation.
- The Developer will need authentication registration, middleware ordering, typed principal/context services, a membership provider, named permission policies and tests. This ADR itself makes none of those changes.
- Eventual persistent principal/membership administration may require additive schema and migration work under a separately reviewed Implementation Work Package. For restricted local/test remediation, an allow-listed synthetic provider can implement the same interfaces without a production membership schema.
- Existing SQL global filters, project predicates and composite constraints remain mandatory defence in depth; authentication/RBAC does not replace them.
- Existing Phase 1/2 routes will be affected by the secure fallback policy and must receive an approved policy or an explicit, reviewed anonymous exception. Regression evidence is required.
- Customer Administrator and Platform Administrator no longer imply migration-data access. Operational support needing customer data requires a separate elevated, time-bound and audited design.
- Identity Platform configuration confirmation and named test-authority approval remain outstanding downstream gates. SQL Server runtime assurance and vulnerability-feed evidence also remain unresolved downstream.
- External customer access under Q-09, production identity configuration, production deployment, real customer-data use, production tenancy, Service Transition and release approval remain blocked. Q-06 also remains open for production processing.

## Traceability and defect disposition

| Reference | Decision coverage | Required closure evidence |
|---|---|---|
| F-15 | Entra authentication, server-side membership, least-privilege permission policies, stable audit actor and fail-closed handling. | Approved ADR, implementation and independent security/RBAC evidence. |
| NF-01 | Entra workforce authentication, delegated scope validation, exact CRUD role matrix, managed identity for future workloads and deny-by-default policies. | Token-validation, policy-matrix, local/test guard and service-principal tests. |
| NF-02 | Customer derived from active project membership, explicit project predicates, non-enumerating denial, no admin wildcard and retained ADR-007 constraints. | Cross-customer/project and direct-object abuse tests on every SQL route. |
| PH3SQL-TST-002 | Supplies the accepted identity provider, principal/claims, membership authority, project roles, SQL CRUD matrix, local/test fixture, denial/error, audit and workload contracts for the restricted local/non-production scope. | Developer implementation on a working branch, exact `READY_FOR_TEST` hand-off and independent Tester retest; downstream Identity Platform and named test-authority gates remain. |

## Approval and downstream implementation gates

Received decisions for approved architecture commit `09078a048cb99a24d6a89552843d955b643a219b`:

1. Solution Architect/TDA approval by GitHub account `PTArchitect`, 10 September 2026, for local/non-production PH3-SQL-001 implementation and testing only: <https://github.com/onkarpathre/lgr-transformation-migration/pull/3#pullrequestreview-5164009938>.
2. Information Security approval by GitHub account `nextgenexamprep-crypto`, 10 September 2026, for the same restricted scope: <https://github.com/onkarpathre/lgr-transformation-migration/pull/3#pullrequestreview-5164020739>.
3. Product Owner role-to-permission mapping confirmation by GitHub account `opathre`, 10 September 2026, for the approved local/non-production business-access model only: <https://github.com/onkarpathre/lgr-transformation-migration/pull/3#issuecomment-5614835348>.

Outstanding downstream consultation/evidence:

- Identity Platform owner confirms environment app registrations, tenant, clients, Conditional Access/MFA and managed-identity configuration before any deployed environment uses Entra mode.
- Agilisys Test Services or the named test authority approves the authentication/RBAC and SQL Server test environment, tools and entry/exit criteria under I-06/D-11 before implementation results are accepted as formal test evidence.
- SQL Server runtime assurance and dependency/vulnerability evidence remain required in the downstream Developer/Test packages.
- Q-09 remains separately owned by Solution Architect/Information Security and blocks external customer identity and access. Production identity configuration is not approved.
- Real customer data remains prohibited; only synthetic or properly anonymised data may be used in development/test. No production deployment is authorised.
- Data Protection/DPO, production tenancy, Service Transition and human release decisions remain required before production as already recorded.

No production, customer-data, deployment or release approval is inferred from the PR #3 decisions, existing ADR-006/ADR-007 reviews, the user instruction, this ADR's author, or the status `READY_FOR_DEVELOPMENT`.

## Hand-off

```yaml
handoff:
  from_agent: "architect"
  to_agent: "developer"
  human_reviewers: ["Identity Platform owner", "Named test authority"]
  state: "READY_FOR_DEVELOPMENT"
  work_item: "PH3-SQL-001-slice-1-remediation-PH3SQL-TST-002"
  branch: "feature/ph3-sql-rbac-architecture"
  commit: "09078a048cb99a24d6a89552843d955b643a219b"
  baseline_commit: "5d3e9b02bc57989d79ee47a133ab35ad4a31d3f8"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-01", "C-03", "C-04", "C-06"]
    functional_requirements: ["F-01", "F-02", "F-04", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-06", "NF-10", "NF-11", "NF-12"]
    risks: ["R-02", "R-09"]
    assumptions: ["A-01", "A-02", "A-03", "A-16", "A-18"]
    dependencies: ["D-03", "D-04", "D-10", "D-11", "D-13"]
    issues: ["I-02", "I-06"]
    open_questions: ["Q-06", "Q-09"]
    approvals:
      - "Solution Architect/TDA approval by PTArchitect, 10 September 2026: local/non-production implementation and testing only."
      - "Information Security approval by nextgenexamprep-crypto, 10 September 2026: local/non-production implementation and testing only."
      - "Product Owner role-mapping confirmation by opathre, 10 September 2026: approved local/non-production business-access model only."
  artefacts:
    - "docs/architecture/ADR-008-internal-authentication-project-rbac.md"
    - "docs/architecture/Phase3_SQL_Discovery_Assessment_Architecture.md"
  evidence:
    - "Product Specification V0.1 F-15, NF-01 and NF-02; document-control approval field remains unevidenced."
    - "HLD V0.1 API-03/API-04, ID-01..ID-06, Table 27 roles, TI-01..TI-07 and release-blocking authentication/RBAC/isolation tests; HLD approval/readiness fields remain unevidenced."
    - "GitHub PR #3 head and approved architecture commit: 09078a048cb99a24d6a89552843d955b643a219b."
    - "Solution Architect/TDA approval by PTArchitect, 10 September 2026: https://github.com/onkarpathre/lgr-transformation-migration/pull/3#pullrequestreview-5164009938"
    - "Information Security approval by nextgenexamprep-crypto, 10 September 2026: https://github.com/onkarpathre/lgr-transformation-migration/pull/3#pullrequestreview-5164020739"
    - "Product Owner role-mapping confirmation by opathre, 10 September 2026: https://github.com/onkarpathre/lgr-transformation-migration/pull/3#issuecomment-5614835348"
    - "ADR-006 and ADR-007 conditional local/non-production POC approvals remain applicable within their recorded boundaries."
    - "feature/ph3-sql-implementation at fa479713ab0cc882397a86f9c962570e9f74e2da: Implementation Work Package requests the missing architecture contract."
    - "Tester evidence at 4c61979e941974d05009727f3ad7959b372f71c1: PH3SQL-TST-002 records missing authentication, membership and project-role policy."
    - "Microsoft primary documentation links in this ADR for token claims, scope/app-role validation, fallback authorization and managed identity."
  decisions:
    - "Accept Entra workforce authentication plus application-owned principal/customer/project membership and permission policies for restricted local/non-production implementation and testing only."
    - "Only DatabaseSme receives SQL Inventory create/update/logical-delete; applicable planning/review roles are read-only; all other roles deny."
    - "LocalTest uses allow-listed synthetic aliases and server-side memberships only; production never trusts identity or role headers."
  assumptions:
    - "Only Agilisys internal users and synthetic local/test identities are in scope."
    - "No code, test, migration, database, Azure, merge or deployment action occurs in this architecture work."
  risks:
    - "R-02 remains open until implementation and independent abuse testing."
    - "Membership administration and production persistence are not implemented or approved."
    - "Q-09 external customer identity and production tenancy remain open."
    - "The Product Specification and HLD document-control tables do not evidence final approval."
  defects:
    - "PH3SQL-TST-002: architecture amendment accepted for restricted local/non-production implementation and testing; implementation and independent retest remain outstanding."
  blockers:
    - "Identity Platform configuration confirmation remains required before Entra mode is used in any deployed environment."
    - "Named test-authority approval under I-06/D-11 remains required before implementation results are accepted as formal test evidence."
    - "SQL Server runtime assurance and vulnerability-feed evidence remain unresolved in the Developer/Test packages."
    - "Q-09 external customer identity, production identity configuration, production tenancy, production deployment, real customer-data use, Service Transition and release approval remain blocked; Q-06 remains open for production processing."
  approvals:
    - "Solution Architect/TDA — PTArchitect — 10 September 2026 — restricted local/non-production implementation and testing — https://github.com/onkarpathre/lgr-transformation-migration/pull/3#pullrequestreview-5164009938"
    - "Information Security — nextgenexamprep-crypto — 10 September 2026 — restricted local/non-production implementation and testing — https://github.com/onkarpathre/lgr-transformation-migration/pull/3#pullrequestreview-5164020739"
    - "Product Owner role-mapping confirmation — opathre — 10 September 2026 — restricted local/non-production business-access model — https://github.com/onkarpathre/lgr-transformation-migration/pull/3#issuecomment-5614835348"
  requested_action: "Developer may implement PH3SQL-TST-002 only within the approved local/non-production scope using synthetic data and reversible changes, then provide a commit-bound READY_FOR_TEST hand-off for independent Tester retest. Preserve the outstanding Identity Platform, named test-authority, SQL runtime, Q-09, production identity, production tenancy, production deployment, customer-data, Service Transition and release gates; no merge or production action follows."
```
