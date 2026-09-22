# PH4 Dependency Register and Planning Validation - Architecture Work Package

Status: **APPROVED - READY_FOR_DEVELOPMENT (RESTRICTED LOCAL/NON-PRODUCTION)**

Architecture date: 22 September 2026

Work item: `PH4-DEP-001`

Branch: `feature/ph4-planning`

Architecture baseline: `d714c10dbe682f23f66ddb5a1ad8063a2b3c16c6`

Product baseline: `docs/product/PH4_Product_Plan.md` at the architecture-package commit. The five required human decisions are recorded in section 20.1 and are explicitly bound to commit `985099c2ec05e3307bdc770af4a97e6e28df8c6e`.

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-03", "C-05", "C-09"]
  functional_requirements: ["F-04", "F-05", "F-06", "F-10", "F-11", "F-15"]
  non_functional_requirements: ["NF-01", "NF-02", "NF-04", "NF-06", "NF-08", "NF-09", "NF-10", "NF-11"]
  risks: ["R-01", "R-02", "R-03", "R-06", "R-07", "R-09"]
  assumptions: ["A-02", "A-06", "A-07", "A-08", "A-11", "A-13", "A-18"]
  dependencies: ["D-01", "D-04", "D-08", "D-11", "D-13"]
  issues: ["I-04", "I-06", "I-07", "I-08"]
  open_questions: ["Q-01", "Q-02", "Q-09"]
  approvals:
    - "Product/PRB, Independent TDA/Q-01, Information Security, Dependency-Semantics SME and Test Services decisions bound to 985099c2ec05e3307bdc770af4a97e6e28df8c6e; see section 20.1"
```

## 1. Architecture outcome and approval state

This package defines all three focused Phase 4 slices as one bounded dependency module within the existing modular monolith:

1. a directed dependency register over existing application, server, SQL instance and SQL database inventory plus controlled named external references;
2. deterministic, persisted project validation with actionable current and historical findings; and
3. read-only dependency impact projections into the existing wave and readiness journeys.

It does not repeat or replace the completed customer/project foundation, application/server inventory, server discovery, SQL inventory/discovery/assessment, internal authentication, ADR-008 membership/RBAC foundation or Phase 3 browser work. It extends those contracts only where this phase requires a dependency permission family, inventory endpoint references, navigation and planning-risk projections.

No code, test, database, migration, deployment or commit is created by this document update. The single phase-level gate in section 20 has been satisfied against exact architecture-package commit `985099c2ec05e3307bdc770af4a97e6e28df8c6e`; the resulting exit state is `READY_FOR_DEVELOPMENT` for the three bounded slices only.

## 2. Baseline findings and boundaries

### 2.1 Reused implementation

The inspected baseline contains:

- one ASP.NET Core modular-monolith API targeting `net10.0`, EF Core SQL Server/Design `10.0.11`, DTO REST contracts, Problem Details, global customer filters and explicit project predicates;
- one Next.js 16 App Router application pinned at Next.js/`eslint-config-next` `16.3.4`, React/React DOM `19.2.8` and TypeScript `5.9.3`; retained Phase 3 evidence records Node.js `24.18.0`;
- immutable GUID keys, SQL Server `rowversion`/ETag patterns, additive EF migrations, non-enumerating object access and append-only audit/discovery evidence patterns;
- canonical Application, Server, SQL Instance and SQL Database records;
- application/server wave membership, readiness checks and summaries;
- ADR-008 server-derived active project membership, deny-by-default authentication and named SQL permission policies; and
- Phase 3 quality evidence restricted to local/non-production synthetic-data use, with live browser checks not run and current external advisory status unavailable.

The existing `ApplicationServer` association, `SqlInstance.ServerId` and `SqlDatabase.SqlInstanceId` remain inventory/hosting ownership. Phase 4 does not copy those relationships into dependencies automatically. A dependency is a human-governed planning assertion and exists only when an authorised user records it.

### 2.2 14-outcome MVP position

The documented MVP definition in `PRODUCT_GAP_ANALYSIS_AND_ROADMAP.md` has 14 outcomes. PH4 materially advances only outcome 5, **Assessment and dependencies**, and outcome 8, **Planning and readiness**, while retaining outcome 14, **Boundaries**. It supplies supporting evidence for outcome 11, **Reporting and audit**, and outcome 12, **Quality evidence**, but does not complete either. It does not claim completion of governance, Azure platform, broad discovery/inventory/assessment, decisions, target design, IP, runbook/rollback, execution/testing/sign-off, pilot or benefit outcomes.

### 2.3 Immutable exclusions

There is no migration executor, Azure provisioner, discovery connector, CMDB synchroniser, network/DNS/firewall changer, autonomous decision, wave approval, AI/model call, multi-cloud path, new customer identity path, export or production-data path. Named external references are inert records: the application never resolves, calls, mounts, probes or authenticates to them.

## 3. Decision-gate disposition

### 3.1 Q-01 / TDA technology stack

The exact proposed PH4 disposition is:

- retain .NET 10 and ASP.NET Core for the API;
- retain EF Core 10.0.x with the SQL Server provider and Azure SQL-compatible DDL;
- retain Next.js 16 App Router, React 19 and TypeScript;
- use Node.js 24 LTS, explicitly pinned in development and CI rather than inferred from `@types/node`;
- retain the modular monolith, synchronous REST and the existing database transaction boundary; and
- add no microservice, message bus, graph database, browser-side graph engine or new cloud service.

At the inspected commit the concrete application pins are EF Core `10.0.11`, Next.js/`eslint-config-next` `16.3.4`, React/React DOM `19.2.8` and TypeScript `5.9.3`. Node 24 is evidenced by Phase 3 but is not repository-pinned; reproducible Node 24 pinning is a Developer/CI acceptance condition. Dependency changes are not authorised by this package and require their own build, licence and vulnerability evidence.

ADR-006 already records the same technology-family decision and lifecycle controls. A new ADR would duplicate that decision, while editing its accepted history before a human decision would imply approval. Therefore no ADR is created or changed. Q-01 remains open for PH4 at authoring time. It is closed only for the bounded PH4 local/non-production scope if the independent Solution Architect/TDA approves the exact consolidated package commit and the approval record explicitly states this Q-01 disposition. Wider MVP and production Q-01 remain open. If TDA requires all scope extensions inside ADR-006, that is an exact approval blocker and ADR-006 must be amended and re-approved before development.

### 3.2 Other gates

- `Q-02`: blocks funded implementation/timeline commitment until the Product Owner/PRB authority records the increment decision. No date or cost is asserted.
- `Q-09`: does not block restricted internal/local development because external customer identity is excluded. It blocks customer/external-user access and production claims.
- `Q-06`, `Q-07`, `Q-08` and `Q-10`: not architecture blockers for this restricted slice; they remain applicable before their production, commercial, service or branding gates.
- `Q-03`/`Q-05`: no AI is present, so no AI decision is sought.

## 4. Component ownership and slice flow

The `DependencyPlanning` module owns dependency records, named references, policy, validation state/runs/findings, dependency API contracts and projections. Inventory modules remain owners of applications, servers, SQL instances and SQL databases. The existing programme module remains owner of waves and readiness.

```text
Next.js dependency journeys
        |
        v
Dependency API controllers -- ADR-008 dependency policies -- server project context
        |
        v
DependencyPlanningService -- endpoint resolver -- validation engine
        |                         |
        |                         +-- bounded in-memory graph (Tarjan SCC)
        v
EF Core / SQL Server shared schema
        |
        +-- existing inventory (read only)
        +-- dependency/reference/policy/state/run/finding tables
        +-- existing wave membership (read only, except version bump by existing commands)
        +-- existing AuditEvents
```

Slice order and feature flags are mandatory:

| Slice | Runtime flag | Dependency | Exposure |
|---|---|---|---|
| 1 - register | `Features:DependencyRegister` | ADR-008 permission extension and first additive migration | dependency/reference API and register UI |
| 2 - validation | `Features:DependencyValidation` | Slice 1 enabled; approved policy exists | validation API/current summary/findings UI |
| 3 - planning impact | `Features:DependencyPlanningImpact` | Slices 1-2 enabled | wave/readiness projections and panels |

Flags default off. A child flag fails closed when its parent is off. Disabled routes return the established non-enumerating 404 and still require authentication/authorization when enabled. Flags are rollout controls, not authorization controls.

## 5. Direction and domain semantics

### 5.1 Edge meaning

Every active dependency is a directed edge:

```text
dependent source --requires--> provider target
```

`Source` is the workload whose sequencing/readiness is affected. `Target` is the capability that must be available first or at the same time. In UI copy, use **Depends on** for source-to-target and **Required by** for the reverse view. Never use an unlabeled arrow or ambiguous “upstream/downstream” alone.

The source is exactly one existing canonical Application, Server, SQL Instance or SQL Database in the authorised project. The target is exactly one canonical asset of those types or one named dependency reference. A named reference cannot be the source in PH4. Reverse direction is a different relationship. Endpoints cannot be changed after create; an incorrect edge is archived and a new edge is created so history is unambiguous.

### 5.2 Aggregate grains

| Aggregate | Grain and owner |
|---|---|
| `Dependency` | One type-specific directed assertion between one canonical source and one canonical/named target in one project. `DependencyPlanning` owns it. |
| `DependencyReference` | One project-owned named FileShare, Api or ExternalSystem endpoint. It can be targeted by many dependencies. |
| `DependencyPolicy` | One active versioned validation policy per project; immutable rules after activation. |
| `DependencyGraphState` | Exactly one row per project holding graph/planning change versions and current completed run pointer. |
| `DependencyValidationRun` | One immutable completed validation of one exact graph version, planning version and policy version. |
| `DependencyValidationFinding` | One rule result in one run. A finding is evidence, not a mutable task. |
| `DependencyValidationFindingNode` | One ordered, safe snapshot node in a finding/cycle path. It is not an inventory FK. |

## 6. Controlled values and endpoint matrix

Values are case-sensitive API codes and are never accepted as arbitrary strings. Display labels are separate. Unknown values return `400 validation_failed`.

### 6.1 Endpoint and state values

| Group | Values |
|---|---|
| canonical asset type | `Application`, `Server`, `SqlInstance`, `SqlDatabase` |
| named reference type | `FileShare`, `Api`, `ExternalSystem` |
| reference resolution | `Unresolved`, `Resolved` |
| dependency criticality | `Mandatory`, `Advisory` |
| confirmation | `Unconfirmed`, `Confirmed` |
| validation severity | `Information`, `Warning`, `Blocker` |
| run status | `Completed`, `Superseded` (derived in responses, not mutated in storage) |

`Resolved` for a named reference means an authorised SME has confirmed that its identity and planning owner/context are sufficiently known. It does not mean a canonical inventory record exists, a connection succeeded or the service is migration-ready. PH4 stores no credentials, URL secrets, personal contact or live health state.

### 6.2 Dependency types

| Code | Meaning | Allowed source | Allowed target |
|---|---|---|---|
| `Service` | source needs a service/capability supplied by target | any canonical | any canonical or `ExternalSystem` |
| `DataRead` | source reads target-managed data | Application, Server, SqlInstance, SqlDatabase | SqlInstance, SqlDatabase, FileShare, Api, ExternalSystem |
| `DataWrite` | source writes target-managed data | Application, Server, SqlInstance, SqlDatabase | SqlInstance, SqlDatabase, FileShare, Api, ExternalSystem |
| `ApiCall` | source invokes a synchronous or asynchronous API | Application, Server | Application, Api, ExternalSystem |
| `FileTransfer` | source consumes or publishes files at target | Application, Server, SqlInstance | Server, FileShare, ExternalSystem |
| `Authentication` | source relies on target for identity/authentication | Application, Server, SqlInstance | Application, Server, Api, ExternalSystem |
| `NetworkConnectivity` | source requires network reachability to target | any canonical | any canonical or any named reference |
| `OperationalSequence` | source must migrate/start after target | any canonical | any canonical |

The matrix is deliberately planning-oriented. `HostsOn`/`RunsOn` are excluded because application-server, SQL-instance-server and database-instance ownership already exist. `Backup`, `Monitoring`, `Licensing` and stakeholder relationships remain future assessment scope unless represented as a `Service` dependency on a named external system. No value causes execution.

The phase-level Migration Architecture/technical SME must approve this exact vocabulary and matrix. A material value or matrix change requires package reapproval; implementation must not add customer-specific enum branches.

## 7. Write validation and invariants

All rules apply in the domain service before persistence; ownership, XOR, self and uniqueness invariants are also enforced in SQL where specified.

1. The authenticated active membership supplies `CustomerId`, `ProjectId`, actor and permissions. Requests contain no ownership or actor fields.
2. Source and target IDs are non-empty and resolve under both customer and project predicates. Missing and foreign IDs produce the same `404 resource_not_found`.
3. Source has exactly one canonical ID matching `sourceType`. Target has exactly one canonical or reference ID matching `targetType`.
4. Source and target endpoint keys differ; self-dependencies return `400 validation_failed`.
5. The dependency type must be allowed by the matrix.
6. An active duplicate is the same project, source endpoint, target endpoint and dependency type. It returns `409 data_conflict`. The reverse edge and a different type are distinct.
7. Create always starts `Unconfirmed`; the creator cannot smuggle confirmation fields into the request.
8. Confirm/unconfirm is a separate permissioned command. Confirm records server-derived `ConfirmedBy` and UTC `ConfirmedAt`; unconfirm clears both and records an audit event.
9. A dependency cannot be confirmed while its target reference is `Unresolved`.
10. A reference cannot be archived while an active dependency targets it. A dependency is archived logically and cannot be edited, confirmed or restored in PH4.
11. Trimming and Unicode normalization Form C occur before length/uniqueness checks. Empty-after-trim text is null. Names are compared with the database's approved case-insensitive normalized column; IDs remain authoritative.
12. Reference name is 1-200 characters; reference description 0-1000; dependency description 0-2000; business context 0-4000. Control characters except CR/LF/TAB, HTML markup intended for rendering, private-key markers, `Password=`, `AccountKey=`, bearer/JWT-shaped tokens and SAS-style secret query signatures are rejected. Text is rendered as text, never HTML/Markdown.
13. No URI is fetched and no filename/path is opened. `Api` and `FileShare` are labels, not active endpoints.
14. Every mutation requires `If-Match` except POST create. Missing is `428 precondition_required`; stale is `412 stale_version`.
15. Every successful mutation atomically writes the entity, increments graph state and appends audit. Partial updates are not allowed.

## 8. Validation model and deterministic rules

### 8.1 Versioned inputs

`DependencyGraphState.GraphVersion` increments for dependency/reference create, update, resolution, confirmation and archive. `PlanningVersion` increments for wave create/update/archive and wave-asset add/remove commands. This requires a narrow call from the existing programme service; it does not change wave ownership or add approval behaviour.

A validation request captures graph version, planning version and active policy version, loads bounded projections, computes findings with a deterministic ordinal sort, then persists the run/findings and advances `CurrentValidationRunId` in one transaction. `InputFingerprint` is SHA-256 over UTF-8 canonical JSON containing the three input versions followed by ordinally sorted active endpoint keys, dependency IDs/types/criticality/confirmation states/reference resolution states and effective wave IDs/dates; display text, timestamps and actor are excluded. If the state `rowversion` or either input version changes before commit, nothing is persisted and the caller receives `409 validation_input_changed`; the client may reload and retry. No partially current run exists. A repeated request for unchanged versions/policy/fingerprint returns the existing current run with 200 and writes no duplicate evidence.

A current run is one whose stored graph, planning and policy versions equal current state. Otherwise the API reports `isCurrent: false`; wave/readiness projection fails safe as `NotValidated` and never presents dependency-ready.

### 8.2 Default policy v1

Severity is data-driven through one active `DependencyPolicy` and child rules per project, not customer-specific code. The first migration inserts the following v1 policy for existing synthetic/local projects; project creation must create the same policy for future projects. PH4 exposes policy read-only. Changing policy values requires the later governed configuration lifecycle or a separately approved administrative work item.

| Rule code | Mandatory edge | Advisory edge | Evaluation |
|---|---:|---:|---|
| `UnresolvedReference` | Blocker | Warning | active target reference is `Unresolved` |
| `UnconfirmedDependency` | Blocker | Warning | active dependency is `Unconfirmed` |
| `SelfDependency` | Blocker | Blocker | defence-in-depth detection of corrupt/self edge |
| `DuplicateDependency` | Blocker | Blocker | defence-in-depth detection of active duplicate |
| `DirectedCycle` | Blocker if any edge in the strongly connected component is Mandatory | Warning otherwise | SCC has more than one node or a self edge |
| `ProviderUnassigned` | Blocker | Warning | dependent source has one effective wave and provider has none |
| `MultipleWaveAssignments` | Blocker | Blocker | either effective planning asset occurs in more than one active wave |
| `ProviderLaterWave` | Blocker | Warning | provider effective wave planned date is later than dependent source wave |
| `WaveOrderUnknown` | Blocker | Warning | distinct waves cannot be ordered because either planned date is null |
| `ExternalPlanningReview` | Warning | Information | resolved named target has no platform wave and requires human sequencing review |

Only `Blocker` prevents a dependency-ready presentation. Warning and Information remain visible. Policy cannot downgrade `SelfDependency`, `DuplicateDependency` or `MultipleWaveAssignments` below Blocker; these integrity floors are domain constraints. Disabling rules is not supported in PH4.

### 8.3 Graph and cycle algorithm

The validation graph contains active canonical-to-canonical dependencies only. Named references produce reference findings but are not graph vertices. Parallel edges of different types are collapsed for strongly connected component discovery and retained when emitting affected dependency IDs. Tarjan's algorithm runs in `O(V + E)`. Each strongly connected component emits one `DirectedCycle` finding with a canonical path starting at the lexically smallest endpoint key and traversing lexically sorted outgoing keys; this makes repeated runs deterministic.

Rejected writes should make self/duplicate findings impossible through the API. The validator still detects them so provider drift/manual corruption fails visibly.

### 8.4 Effective wave anchor

PH4 does not add SQL assets to waves. For validation only, the effective planning asset is:

| Endpoint | Effective planning asset |
|---|---|
| Application | same Application |
| Server | same Server |
| SQL Instance | its existing owning Server |
| SQL Database | its SQL Instance's existing owning Server |
| named reference | none |

The source is the dependent and the target is the provider. Same-wave and earlier-provider-wave relationships are compatible. A provider in a later dated wave is incompatible. Distinct waves with the same date are compatible for PH4 but still display as cross-wave Information. Missing dates produce `WaveOrderUnknown`; IDs are never used to invent business order. Completed/in-progress status does not rewrite dependency logic.

If neither canonical endpoint is wave-assigned, project validation records no `ProviderUnassigned` because there is no asserted planning context. If the source has a wave and provider does not, it does. If provider has a wave but source does not, a non-blocking project Information finding `DependentUnassigned` is returned; it cannot make a particular wave ready. This additional code has fixed severity Information and is not a dependency blocker.

### 8.5 Readiness projection

For each wave the projection returns:

- `NotValidated` when no current completed run exists;
- `Blocked` when any current Blocker affects a source anchored in that wave;
- `AtRisk` when there are no blockers but at least one Warning;
- `Clear` when there are neither blockers nor warnings; and
- counts by code/severity plus links to bounded findings.

The term is **dependency validation**, never wave approval. `Clear` does not alter `MigrationWave.Status`, `ReadinessCheck`, a decision or an approval. The existing readiness UI must not show overall Ready without also showing dependency status; if dependency state is `NotValidated` or `Blocked`, the composite presentation is `NotReady` or `Blocked` respectively. This is a projection, not a persisted rewrite of manually entered readiness checks.

## 9. ADR-008 permission extension

Canonical permissions:

- `dependency.read`
- `dependency.manage`
- `dependency.confirm`
- `dependency.validate`
- `dependency.audit.read`

Exact role matrix:

| Project role | read | manage | confirm | validate | audit.read |
|---|---:|---:|---:|---:|---:|
| `MigrationArchitect` | Allow | Allow | Allow | Allow | Allow |
| `DatabaseSme` | Allow | Allow | Allow | Allow | Allow |
| `ProjectManager` | Allow | Deny | Deny | Allow | Allow |
| `DiscoveryAnalyst` | Allow | Deny | Deny | Deny | Deny |
| `ReviewerAuditor` | Allow | Deny | Deny | Deny | Allow |
| any other/unknown/customer/platform role | Deny | Deny | Deny | Deny | Deny |

`manage` covers dependency/reference create, content update and archive; it does not imply confirmation. Permissions are the union of active roles after ADR-008 status/membership checks. Disabled principals/memberships deny all. Customer Administrator and Platform Administrator have no implicit access. Delegated human principals only are allowed; app-only/workload principals have no PH4 route.

Every PH4 route requires a named policy in addition to the authenticated fallback. Existing active-membership-only programme routes are not broadened. The generic session capability response is extended additively to include `dependency.*` permissions rather than filtering only `sql.*`; caller roles remain undisclosed. Direct URLs and UI hiding never replace server authorization.

This is a material extension of ADR-008's permission catalogue and therefore requires Information Security approval at the consolidated gate. It does not require a new identity provider, membership entity, external identity decision or ADR because it applies the already accepted authorization mechanism.

## 10. API contract

All new routes are `/api/v1`, JSON, DTO-only and feature-gated. Lists default to 50 and cap at 200. Sort fields are allow-listed and stable with `id` as final tie-breaker. Unknown filters/sort fields return 400 rather than becoming dynamic SQL.

### 10.1 Endpoint reference DTO

```text
DependencyReferenceWriteV1
  referenceType: FileShare | Api | ExternalSystem
  name: string(1..200)
  description: string(0..1000)
  resolutionStatus: Unresolved | Resolved

DependencyReferenceDto
  id, referenceType, name, description, resolutionStatus,
  activeDependencyCount, isArchived,
  createdAt, createdBy, updatedAt, updatedBy, version
```

Routes:

| Method/path | Permission | Result |
|---|---|---|
| `GET /api/v1/dependency-references` | read | paged filter by type/status/search; archived excluded by default |
| `GET /api/v1/dependency-references/{id}` | read | detail plus ETag |
| `POST /api/v1/dependency-references` | manage | 201, Location, ETag; graph version increments |
| `PUT /api/v1/dependency-references/{id}` | manage | full update with If-Match; graph version increments |
| `DELETE /api/v1/dependency-references/{id}` | manage | logical archive with If-Match; 409 while active dependency exists |

### 10.2 Dependency DTO

```text
DependencyEndpointV1
  type: Application | Server | SqlInstance | SqlDatabase | DependencyReference
  id: Guid

DependencyCreateV1
  source: DependencyEndpointV1   // canonical only
  target: DependencyEndpointV1
  dependencyType: controlled code
  criticality: Mandatory | Advisory
  description: string(0..2000)
  businessContext: string(0..4000)

DependencyUpdateV1
  dependencyType, criticality, description, businessContext

DependencyConfirmationV1
  confirmationStatus: Confirmed | Unconfirmed

DependencyDto
  id, source, target, directionLabel="DependsOn",
  dependencyType, criticality, description, businessContext,
  confirmationStatus, confirmedAt, confirmedByDisplay,
  currentFindingCounts, isArchived,
  createdAt, createdBy, updatedAt, updatedBy, version
```

Endpoint responses include safe `displayName` and canonical `inventoryRoute`, derived server-side. `confirmedByDisplay` is the stable audit actor or approved display label; no email/token claims are returned.

Routes:

| Method/path | Permission | Contract |
|---|---|---|
| `GET /api/v1/dependencies` | read | paged; filters `assetType`, `assetId`, `direction=DependsOn|RequiredBy|Either`, type, criticality, confirmation, finding severity, search |
| `GET /api/v1/dependencies/{id}` | read | detail plus ETag; archived excluded unless `includeArchived=true` and audit.read |
| `POST /api/v1/dependencies` | manage | 201 with default Unconfirmed; endpoints resolved server-side |
| `PUT /api/v1/dependencies/{id}` | manage | update mutable fields with If-Match; endpoints immutable |
| `PUT /api/v1/dependencies/{id}/confirmation` | confirm | confirm/unconfirm with If-Match |
| `DELETE /api/v1/dependencies/{id}` | manage | logical archive with If-Match |
| `GET /api/v1/dependencies/{id}/audit` | audit.read | paged safe significant events only |

### 10.3 Validation and planning DTOs

```text
DependencyValidationSummaryDto
  runId, isCurrent, graphVersion, planningVersion, policyVersion,
  completedAt, completedBy, nodeCount, edgeCount,
  informationCount, warningCount, blockerCount, durationMs

DependencyValidationFindingDto
  id, runId, dependencyId?, ruleCode, severity,
  messageCode, endpointPath[], affectedWaveIds[], createdAt

WaveDependencyImpactDto
  waveId, validationRunId?, isCurrent,
  status: NotValidated | Blocked | AtRisk | Clear,
  informationCount, warningCount, blockerCount,
  topFindings[]
```

Routes:

| Method/path | Permission | Contract |
|---|---|---|
| `POST /api/v1/dependency-validations` | validate | synchronous deterministic run; 201 when newly committed, 200 for the unchanged current run, 409 on changed inputs |
| `GET /api/v1/dependency-validations/current` | read | current/stale summary; 404 only when no run has ever completed |
| `GET /api/v1/dependency-validations` | audit.read | paged immutable run history |
| `GET /api/v1/dependency-validations/{runId}/findings` | read | paged/filterable findings; historical run requires audit.read |
| `GET /api/v1/dependency-planning/waves/{waveId}` | read | current dependency impact for one authorised wave |
| `GET /api/v1/dependency-planning/readiness-summary` | read | bounded all-wave summary for existing readiness page |

### 10.4 Response and compatibility rules

- Use existing Problem Details/error codes for 400/401/403/404/409/412/428/500.
- Add only `validation_input_changed`, `dependency_policy_unavailable` and `validation_capacity_exceeded` as 409, 409 and 422 codes respectively; add the 422 problem-type mapping without exposing counts from foreign projects.
- Foreign/missing endpoint, dependency, reference, run and wave IDs return identical 404 detail.
- Create retries are not automatically idempotent; the active unique index converts a replay into a safe 409. No caller-provided idempotency key is needed for human CRUD.
- Existing unversioned wave/readiness DTOs are not changed. Slice 3 uses the additive v1 projection routes, preventing regression of Phase 1 clients.
- No raw EF entity, computed key, rowversion bytes, policy implementation detail or foreign ID is exposed.

## 11. Browser journeys and accessibility

New routes:

- `/planning/dependencies` - current validation banner, bounded dependency table, filters, “Depends on/Required by” labels and permission-aware actions;
- `/planning/dependencies/new` - accessible canonical/reference search and dependency creation;
- `/planning/dependencies/[id]` - detail, confirmation, findings and audit timeline according to permissions;
- `/planning/dependencies/validation` - current summary, run action, grouped findings and cycle paths; and
- `/planning/dependencies/assets/[assetType]/[assetId]` - both-direction asset view used by inventory links.

Existing application/server list rows and SQL instance/database detail pages receive only a “Dependencies” link/count when `dependency.read` is present. The existing waves and readiness pages call the additive planning projections and render a dependency status panel. No completed Phase 3 SQL form or route is duplicated.

Required interaction contract:

- server capability response controls visible actions; denied actions remain denied at API;
- loading uses an announced status; empty/error/stale/no-permission states are distinct;
- validation results use text, icon and count, never colour alone;
- each finding links to the dependency/asset when still accessible and otherwise renders a safe unavailable state;
- cycle paths are an ordered list with explicit “depends on” text, not a canvas-only graph;
- forms have programmatic labels, descriptions and inline/summary errors; focus moves to the error summary after failed submit;
- modals, if reused, trap focus, restore focus and close by Escape without losing unsaved data silently;
- tables have captions/headers and remain usable at 320 CSS pixels through responsive cards or two-dimensional labelled scrolling;
- every operation is keyboard accessible with a visible focus indicator; confirmation/archive require explicit named controls;
- stale 412 responses retain entered data and offer reload/reapply, never blind overwrite; and
- automated axe checks plus independent Chrome/Edge keyboard, focus, zoom/reflow and contrast evidence are required. Phase 3's `NOT RUN` browser state is not inherited as a pass.

## 12. Persistence contract

All identifiers are non-sequential GUIDs under ADR-002. All PH4 rows carry `CustomerId` and `ProjectId`, have the global customer filter and explicit service-level project predicate. Strings use explicit maximum lengths and Unicode where human text is allowed.

### 12.1 `DependencyReferences`

Required columns: `Id`, `CustomerId`, `ProjectId`, `ReferenceType` varchar(32), `Name` nvarchar(200), `NormalizedName` nvarchar(200), `Description` nvarchar(1000), `ResolutionStatus` varchar(20), `IsArchived` bit, `CreatedAt`, `CreatedBy` nvarchar(200), `UpdatedAt`, `UpdatedBy` nvarchar(200), `RowVersion` rowversion.

Keys/indexes:

- PK `Id`; alternate key `(CustomerId, ProjectId, Id)`;
- FK `(CustomerId, ProjectId)` to project principal key `(CustomerId, Id)`, Restrict;
- unique filtered `(CustomerId, ProjectId, ReferenceType, NormalizedName)` where `IsArchived = 0`;
- list index `(CustomerId, ProjectId, IsArchived, ReferenceType, ResolutionStatus, NormalizedName, Id)`.

### 12.2 `Dependencies`

Required columns include ownership/audit/rowversion plus:

- `SourceType` and one of `SourceApplicationId`, `SourceServerId`, `SourceSqlInstanceId`, `SourceSqlDatabaseId`;
- `TargetType` and one of `TargetApplicationId`, `TargetServerId`, `TargetSqlInstanceId`, `TargetSqlDatabaseId`, `TargetReferenceId`;
- `SourceEndpointKey` and `TargetEndpointKey` as persisted computed, non-null strings derived only from type plus the matching GUID (`A:`, `S:`, `I:`, `D:`, `R:` plus 32 hex digits);
- `DependencyType` varchar(40), `Criticality` varchar(20), `Description` nvarchar(2000), `BusinessContext` nvarchar(4000);
- `ConfirmationStatus` varchar(20), `ConfirmedAt` nullable, `ConfirmedBy` nullable nvarchar(200); and
- `IsArchived` bit, created/updated actor/timestamps and `RowVersion`.

Constraints/keys/indexes:

- PK `Id`; alternate key `(CustomerId, ProjectId, Id)`;
- project composite FK, Restrict;
- one composite FK `(CustomerId, ProjectId, endpointId)` for each nullable endpoint column to the matching inventory/reference alternate key, all Restrict;
- add alternate key `(CustomerId, ProjectId, Id)` to `Applications`; Server, SQL Instance and SQL Database already have it;
- CHECK exactly one source ID and type match; CHECK exactly one target ID and type match; CHECK source key differs from target key; CHECK controlled type/criticality/confirmation values and confirmation actor/time coherence;
- unique filtered `(CustomerId, ProjectId, SourceEndpointKey, TargetEndpointKey, DependencyType)` where `IsArchived = 0`;
- forward index `(CustomerId, ProjectId, IsArchived, SourceEndpointKey, DependencyType, Id)`;
- reverse index `(CustomerId, ProjectId, IsArchived, TargetEndpointKey, DependencyType, Id)`;
- validation index `(CustomerId, ProjectId, IsArchived, ConfirmationStatus, Criticality, Id)`.

Computed keys are internal only and prevent 20 type-pair-specific unique indexes. Migration SQL and EF model snapshot must prove deterministic persisted expressions on SQL Server; SQLite tests are supplementary.

### 12.3 Policy and graph state

`DependencyPolicies`: PK/tenant/project/id, `Version` integer, `Name` nvarchar(100), `IsActive`, created/activated metadata and rowversion. Unique filtered `(CustomerId, ProjectId)` where active.

`DependencyPolicyRules`: PK/tenant/project/id, composite FK to policy, `RuleCode` varchar(50), `MandatorySeverity`, `AdvisorySeverity`; unique `(CustomerId, ProjectId, DependencyPolicyId, RuleCode)`. Rules are immutable after policy activation.

`DependencyGraphStates`: PK/tenant/project/id, `GraphVersion` bigint, `PlanningVersion` bigint, `CurrentValidationRunId` nullable, `UpdatedAt`, rowversion; unique `(CustomerId, ProjectId)`. Versions start at zero and increment transactionally. The current-run FK is Restrict and added after validation tables exist.

### 12.4 Validation evidence

`DependencyValidationRuns`: PK/alternate tenant-project key; composite FKs to Project and Policy; graph/planning/policy versions, SHA-256 `InputFingerprint` char(64), actor, start/completion UTC, duration/count fields. Unique `(CustomerId, ProjectId, GraphVersion, PlanningVersion, DependencyPolicyId, InputFingerprint)` prevents equivalent concurrent current runs.

`DependencyValidationFindings`: PK/tenant/project, composite FK to run Cascade, optional composite FK to Dependency Restrict, `RuleCode`, `Severity`, `MessageCode`, generated `DetailsJson` nvarchar(2000), `CreatedAt`; index `(CustomerId, ProjectId, DependencyValidationRunId, Severity, RuleCode, Id)`. `DetailsJson` is server-generated from controlled values and safe IDs/counts; it contains no arbitrary dependency narrative.

`DependencyValidationFindingNodes`: PK/tenant/project, composite FK to finding Cascade, `Sequence`, `NodeType`, `NodeId` nullable, `DisplayNameSnapshot` nvarchar(200); unique `(CustomerId, ProjectId, FindingId, Sequence)`. It intentionally has no inventory FK so immutable historical evidence survives later inventory lifecycle changes. API navigation re-resolves `NodeId` within current authorisation.

Completed runs/findings/nodes are append-only through application enforcement. There is no PH4 delete endpoint. Retention/deletion remains a separately approved privacy/operations policy.

### 12.5 Delete behaviour and legacy protection

All dependency endpoint FKs use Restrict. Existing physical deletes of an application/server that participates in an active or archived dependency will fail safely with 409 rather than cascade or lose evidence. Converting legacy inventory deletion to governed archive is a later inventory-lifecycle item; PH4 must not silently add it. SQL inventory already archives logically. Wave and readiness deletions never delete dependency records or validation history.

## 13. Audit, observability and privacy

Atomic `AuditEvent` actions are required for `DependencyCreated`, `DependencyUpdated`, `DependencyConfirmed`, `DependencyUnconfirmed`, `DependencyArchived`, `DependencyReferenceCreated`, `DependencyReferenceUpdated`, `DependencyReferenceArchived`, `DependencyValidationCompleted` and `DependencyValidationCurrentChanged`.

Audit uses ADR-008's stable server-derived actor, principal type, customer/project, entity ID, UTC timestamp and correlation ID. For controlled fields, old/new values may be stored. Description, business context, reference description, endpoint display names, token/header values and validation path labels are not copied into audit or structured logs. The retained entity and immutable run provide authorised detail.

Metrics/logs are project-safe and low-cardinality: route template, outcome, duration, result counts and rule/severity codes. Do not use customer/project/asset/reference names as metric dimensions. Security events cover denial, prohibited identity headers, cross-scope attempts, policy absence, capacity rejection and stale validation. Expected 401/403/404 responses do not log foreign IDs or request bodies.

No person/contact field exists. Synthetic/anonymised data only is allowed. At-rest/in-transit encryption, secrets management, UK residency and production monitoring remain production-platform gates, not supplied by this module.

## 14. Performance and capacity contract

The agreed PH4 restricted-scope performance envelope is:

- lists default 50/cap 200 and never return an entity graph;
- synchronous validation accepts at most 2,000 canonical nodes and 10,000 active dependencies; a larger project returns 422 before graph materialisation and requires a later scale design;
- all reads are async, cancellation-aware, `AsNoTracking` DTO projections with allow-listed filters;
- endpoint resolution is set-based by type; validation uses a bounded number of set queries and dictionaries, no lazy loading/N+1;
- Tarjan cycle detection is `O(V + E)` and stable ordering is applied only to bounded keys/findings;
- validation persistence uses bulk `AddRange` within one transaction; no per-finding database read;
- on the named isolated SQL Server test host with a warm database, 250 mixed canonical assets, 800 active dependencies, 20 named references and 20 waves: dependency list/detail p95 <= 500 ms, wave/readiness projection p95 <= 750 ms, and full validation p95 <= 2,000 ms across 20 sequential runs; zero request may exceed 10 seconds; and
- evidence records host specification, build, database provider/version, cold/warm distinction, query count, p50/p95/max and actual SQL execution plans for forward, reverse, uniqueness, run/finding and wave-anchor queries.

These are acceptance targets for the restricted representative estate, not a production SLA. Q-02/Q-08 and production capacity remain open.

## 15. Additive migrations, rollout and rollback

Two sequential EF Core migrations are permitted after approval:

1. `AddDependencyRegister`: Application composite alternate key; references, dependencies, policy/rules and graph state; SQL Server checks/computed columns/filtered indexes/FKs; deterministic synthetic/local policy and fixture seed support.
2. `AddDependencyValidationEvidence`: validation runs/findings/nodes, current-run FK and planning-version integration support.

Both migrations are expand-only. They add no nullable-to-required column to populated legacy tables except the metadata-only Application alternate key, whose precondition is a duplicate check on existing `(CustomerId, ProjectId, Id)`. They modify no Phase 1-3 business data and do not backfill `ApplicationServer`/SQL ownership into dependencies.

Required migration evidence on disposable SQL Server databases:

- Up from empty and from the immediately preceding checked-in migration;
- EF model snapshot agreement/no pending changes;
- all CHECK, filtered unique, computed, rowversion and composite FK behaviour;
- authorised Down/reapply rehearsal only on a pre-validated disposable test database; and
- transaction/concurrency/rollback evidence with SQLite explicitly insufficient for provider-specific proof.

Non-production rollout is schema -> application with all PH4 flags off -> smoke/isolation checks -> Slice 1 flag -> Slice 2 -> Slice 3. No startup migration application is allowed.

Operational rollback is data-preserving: disable the affected flag, roll back to the preceding compatible application where possible, leave additive tables/data/audit/runs intact and forward-fix. Never run Down, delete PH4 evidence or remove the Application key in production. Any future destructive/data-correction plan needs named human authority and backup/restore evidence.

## 16. Synthetic fixture contract

Fixtures contain no real customer, personal, hostname, URL, credential or commercial data. IDs, clocks, actors, ETags, policy versions, run ordering and expected counts are deterministic.

| Fixture | Minimum content and expected result |
|---|---|
| `PH4-DEP-POS-01` | all four canonical source types, every dependency type, all allowed target categories, both directions in views, confirm/unconfirm/archive and exact audit actions |
| `PH4-DEP-REF-01` | FileShare/Api/ExternalSystem references; unresolved mandatory/advisory findings; resolution update; active-use archive conflict |
| `PH4-DEP-NEG-01` | missing/empty/mismatched endpoint, every invalid matrix pair, self edge, active duplicate, bad values, overlength/control/HTML/secret-like content, archived mutation and missing/stale ETag; no partial mutation |
| `PH4-DEP-ISO-01` | customer A/project A, customer A/project A2 and customer B/project B endpoint/reference/dependency/run/finding IDs used for direct-object and relationship attacks |
| `PH4-DEP-CYCLE-01` | acyclic chain, two-node cycle, three-node mandatory cycle, advisory-only cycle and parallel typed edges; exact canonical paths/severities |
| `PH4-DEP-WAVE-01` | same/earlier/later/equal-date/null-date/unassigned/multiple-wave cases plus SQL instance/database host-derived anchors and resolved external review |
| `PH4-DEP-CONC-01` | two dependency edits, confirmation versus edit, reference update, simultaneous equivalent validations and graph change during validation; exact 409/412 and one current run |
| `PH4-DEP-RBAC-01` | every role/permission cell, multi-role union, disabled/expired membership, unknown/admin non-bypass, workload rejection and capability response |
| `PH4-DEP-SCALE-200-01` | 250 assets (60 Applications, 70 Servers, 60 SQL Instances, 60 SQL Databases), 800 active edges, 20 references, 20 waves, deterministic cycles/findings and isolated second-customer attack data |
| `PH4-DEP-A11Y-01` | loading, empty, errors, stale validation, stale edit, denied actions, long labels, cycle paths, keyboard/focus/reflow and non-colour status states |

Expected counts and hashes belong in a versioned fixture manifest. Developers may split physical fixture files but must not change semantic inputs/outcomes without phase-contract reapproval.

## 17. Independent test contract

All evidence binds to the same candidate commit. Tester derives cases from the Product and Architecture Work Packages, not only implementation tests.

### 17.1 Slice 1

- every endpoint/type matrix cell; direction/reverse retrieval; exact controlled values and normalization;
- self/missing/duplicate/cross-project/cross-customer constraints at API and SQL Server levels;
- reference lifecycle, logical archive, Restrict deletes and no automatic external activity;
- every ADR-008 role/permission cell on every route, session capabilities, direct URLs, workload rejection and non-enumerating errors;
- If-Match missing/stale/success and concurrent mutation; audit attribution/redaction; and
- additive migration Up/provider constraints/Down-reapply on disposable SQL Server plus all Phase 1-3 regression.

### 17.2 Slice 2

- exact v1 policy values, fail-closed missing/duplicate policy and immutable activated rules;
- unresolved/unconfirmed/self/duplicate and all cycle shapes with deterministic path/order;
- graph/reference mutation version increments, equivalent validation uniqueness, change-during-validation rollback and current/stale semantics;
- append-only run/finding evidence, bounded history and audit visibility; and
- node/edge capacity boundaries, cancellation, query counts, plans and performance targets.

### 17.3 Slice 3 / phase exit

- every effective wave anchor and same/earlier/later/equal/null/unassigned/multiple/external case;
- `NotValidated`, `Blocked`, `AtRisk`, `Clear` projection and proof no wave/readiness/decision/approval row is mutated;
- existing wave/readiness DTO compatibility and regression;
- component tests for all browser states, Playwright journeys for permitted/denied roles, project switch, direct URL, stale edit/validation and retry;
- axe automation plus independent Chrome/Edge keyboard, focus, zoom/reflow and contrast checks;
- `PH4-DEP-SCALE-200-01` timings/query plans and cross-tenant leakage evidence;
- build, lint, complete .NET/frontend/SQL regression, secret/static/dependency/vulnerability scan with reachable feeds; unavailable evidence is not PASS; and
- repository/behavioural absence checks for migration execution, Azure/network provisioning, direct discovery calls, external reference access, AI and multi-cloud paths.

Any authentication bypass, privilege escalation, cross-customer/project disclosure, cross-scope FK, silent overwrite, partial validation commit, loss/mutation of history, false dependency-ready result with a current mandatory blocker, product-boundary breach or unresolved critical/high security finding is release-blocking and cannot be accepted by an agent.

## 18. Acceptance traceability

| Product criterion | Architecture controls | Primary slice |
|---|---|---|
| AC-01/02 | directed canonical/reference model, exact types/matrix/state, separate confirmation and sensitive-text rejection | 1 |
| AC-03 | forward/reverse computed-key indexes, bounded DTO lists and asset journey | 1 |
| AC-04/05 | endpoint XOR, composite FKs, self/unique checks, server-derived scope and non-enumerating errors | 1 |
| AC-06 | versioned deterministic validation, named reference findings, SCC cycles and actionable path nodes | 2 |
| AC-07/08 | effective anchors, policy severity, current-run rule and non-mutating wave/readiness projection | 3 |
| AC-09 | atomic audit plus immutable validation runs/findings and privacy-safe logs | 1-3 |
| AC-10 | exact ADR-008 permission family/matrix, delegated-human-only and capability contract | 1-3 |
| AC-11 | rowversion/If-Match and validation state concurrency | 1-2 |
| AC-12 | explicit 250/800 fixture, capacity ceiling, p95 targets and SQL plans | 2-3 |
| AC-13 | additive v1 APIs, unchanged legacy DTOs, flags and full Phase 1-3 regression | 1-3 |
| AC-14 | inert references and absence tests for every prohibited capability | 1-3 |
| AC-15 | deterministic fixture manifest and one-commit independent evidence | 1-3 |

## 19. Risks and residual decisions

- R-01/R-07 are controlled by visible unconfirmed/unresolved states, current-run semantics and human confirmation; no completeness claim is inferred from an empty graph.
- R-02 remains release-blocking until all endpoint, dependency, reference, validation, finding, audit and planning projection isolation tests pass.
- R-03/I-04 remain because synthetic evidence does not prove live-estate correctness. SME approval of values/rules and later pilot evidence are required.
- R-06 is controlled by inert manual references and explicit exclusions; no CMDB/discovery integration exists.
- R-09/I-08 are controlled by Q-01 disposition, pinned supported families, locks and same-commit regression/advisory evidence.
- I-07 is controlled by versioned policy data; PH4 deliberately supplies no customer-specific configuration UI.
- The existing ability to assign an application/server to multiple waves is surfaced as a blocker rather than silently repaired. A later wave-integrity work item should prevent it at write time.
- Legacy Application/Server physical delete is retained but safely restricted when dependency evidence exists; broader inventory archival is outside PH4.

## 20. One consolidated phase-level approval gate

One commit-bound record covers the Product Plan and this complete architecture. It must name each individual, role, decision, date, exact commit, scope, conditions and durable evidence. Slice-by-slice architecture approvals are not required.

Only these reviewer functions are genuinely required:

1. **Named Product Owner with PRB investment authority, or Product Owner plus named PRB delegate if that authority is separate** - confirms the supplied baseline, exclusions, acceptance criteria and Q-02 decision sufficient for this bounded increment.
2. **Named independent Solution Architect/TDA reviewer** - approves this architecture and the exact PH4 Q-01 disposition. The document author cannot self-approve.
3. **Named Information Security reviewer** - approves only the ADR-008 dependency permission extension, composite isolation/audit controls and sensitive-text/log boundary.
4. **Named Migration Architecture technical SME authorised for the application, infrastructure and database dependency semantics** - approves the type/direction matrix, confirmation meaning, policy v1 severities and wave-anchor rules. If no one person holds all three authorities, the approval record must name the minimum applicable application/infrastructure/DBA SMEs under this single reviewer function.
5. **Named Test Services authority** - approves the isolated SQL Server/browser environment, fixture manifest, tools, performance host/targets, entry/exit criteria, evidence retention and disposable Down/reapply authority.

No separate DPO, Identity Platform, Service Transition, Commercial, Azure platform or release reviewer is required for the restricted synthetic local/non-production architecture because this phase adds no personal-data field, identity provider, production service, commercial claim, Azure resource or release. Those authorities remain mandatory before their respective later gates. No DBA approval of SQL inventory/discovery semantics is repeated; DBA participation is needed only if the named technical SME function cannot authoritatively approve database dependency semantics.

Approval authorises bounded development/testing only. It is not merge, deployment, customer-data, production-tenancy, risk acceptance, MVP exit or release approval. Any material change to scope, vocabulary/matrix, policy severity, tenant boundary, permission mapping, API/persistence contract, performance envelope or acceptance criteria invalidates the approval and returns to the owning role.

### 20.1 Verified commit-bound decisions

Architect verification on 22 September 2026 confirmed that `docs/approvals/PH4_Architecture_Approval_Evidence.json` binds every required decision to exact consolidated architecture-package commit `985099c2ec05e3307bdc770af4a97e6e28df8c6e`. The evidence file is preserved unchanged.

| Reviewer account | Role | Date (UTC) | Decision | Approved scope | Conditions and limits | Permalink |
|---|---|---|---|---|---|---|
| `opathre` | Product/PRB Authority | 2026-09-22 13:45:22 | `APPROVED` | PH4 business outcome, three ordered slices, acceptance criteria, priorities, exclusions and MVP alignment | Restricted local/non-production implementation and synthetic-data testing only; excludes production, customer data, production identity, automated migration/cutover, full MVP release and Phase 4 production exit | [Product/PRB review](https://github.com/onkarpathre/lgr-transformation-migration/pull/9#pullrequestreview-5278929152) |
| `PTArchitect` | Independent TDA Reviewer | 2026-09-22 13:46:21 | `APPROVED` | Consolidated PH4 architecture and Q-01 disposition: retain .NET 10/EF Core 10, Next.js 16/React 19 and Node.js 24 for restricted PH4 development | No production deployment; material stack, security-boundary, persistence, dependency-semantics or production-scope change requires renewed TDA review; wider MVP/production Q-01 remains open | [Independent TDA review](https://github.com/onkarpathre/lgr-transformation-migration/pull/9#pullrequestreview-5278940392) |
| `ashish50thbirthday-ship-it` | Information Security Reviewer | 2026-09-22 14:04:59 | `APPROVED` | ADR-008 permission extensions, deny-by-default controls, tenant/project isolation, dependency visibility, validation, safe errors, audit and synthetic-data restrictions | Restricted local/non-production development and test only; excludes production identity, external access, customer data, production tenancy, deployment and release | [Information Security review](https://github.com/onkarpathre/lgr-transformation-migration/pull/9#pullrequestreview-5279192933) |
| `nextgenexamprep-crypto` | Dependency-Semantics SME | 2026-09-22 14:34:26 | `APPROVED` (evidence object recorded as `RECORDED`) | Dependency ownership, direction, types, statuses, controlled values, validation/duplicates, planning-impact rules, fixtures, API/UI contracts and performance constraints | Restricted local/non-production implementation and synthetic-data testing only; material semantics, controlled-value, validation-rule or production-scope change requires renewed SME review | [Dependency-Semantics SME decision](https://github.com/onkarpathre/lgr-transformation-migration/pull/9#issuecomment-5778418471) |
| `nextgenexamprep-crypto` | Test Services Authority | 2026-09-22 14:05:56 | `APPROVED` | Independent testing of all three slices, including unit, integration, API, security, isolation, concurrency, audit, migration, rollback, performance and accessible browser journeys | Synthetic fixtures and isolated local SQL Server only; databases are never automatically deleted; excludes production/shared databases, customer data, destructive cleanup, deployment, merge and release | [Test Services review](https://github.com/onkarpathre/lgr-transformation-migration/pull/9#pullrequestreview-5279204369) |

The decisions contain no condition that changes the architecture contract. For this bounded hand-off, Q-01 and the Q-02 increment decision are satisfied. Q-01 remains open for wider MVP/production scope, and Q-09 remains open but is not a blocker because external customer identity is excluded.

## 21. Architecture audit summary

Read-only inspection covered `AGENTS.md`, the PH4 Product Plan, the 14-outcome MVP definition, ADR-001/002/003/006/007/008, prior architecture packages, the final Phase 3 Quality record, current project manifests/locks, domain entities, EF model, identity/permission implementation, programme/wave/readiness services/contracts/controllers and representative Next.js inventory/wave/readiness routes. The requested branch/HEAD and clean worktree were verified before editing. The Product Plan's inspected baseline `70e0774...` was reconciled to `d714c10...`; the sole intervening commit adds that plan. No DOCX was extracted, no SQL/database was accessed, and no code/test/ADR/remote state was changed.

## 22. Commit-bound hand-off

```yaml
handoff:
  from_agent: "architect"
  to_agent: "developer"
  state: "READY_FOR_DEVELOPMENT"
  work_item: "PH4-DEP-001"
  branch: "feature/ph4-planning"
  commit: "985099c2ec05e3307bdc770af4a97e6e28df8c6e"
  baseline_commit: "d714c10dbe682f23f66ddb5a1ad8063a2b3c16c6"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-03", "C-05", "C-09"]
    functional_requirements: ["F-04", "F-05", "F-06", "F-10", "F-11", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-04", "NF-06", "NF-08", "NF-09", "NF-10", "NF-11"]
    risks: ["R-01", "R-02", "R-03", "R-06", "R-07", "R-09"]
    assumptions: ["A-02", "A-06", "A-07", "A-08", "A-11", "A-13", "A-18"]
    dependencies: ["D-01", "D-04", "D-08", "D-11", "D-13"]
    issues: ["I-04", "I-06", "I-07", "I-08"]
    open_questions: ["Q-01", "Q-02", "Q-09"]
    approvals:
      - "Product/PRB Authority: opathre; APPROVED 2026-09-22T13:45:22Z; https://github.com/onkarpathre/lgr-transformation-migration/pull/9#pullrequestreview-5278929152"
      - "Independent TDA Reviewer: PTArchitect; APPROVED 2026-09-22T13:46:21Z, including restricted PH4 Q-01 disposition; https://github.com/onkarpathre/lgr-transformation-migration/pull/9#pullrequestreview-5278940392"
      - "Information Security Reviewer: ashish50thbirthday-ship-it; APPROVED 2026-09-22T14:04:59Z; https://github.com/onkarpathre/lgr-transformation-migration/pull/9#pullrequestreview-5279192933"
      - "Dependency-Semantics SME: nextgenexamprep-crypto; APPROVED in evidence text and RECORDED as evidence-object status 2026-09-22T14:34:26Z; https://github.com/onkarpathre/lgr-transformation-migration/pull/9#issuecomment-5778418471"
      - "Test Services Authority: nextgenexamprep-crypto; APPROVED 2026-09-22T14:05:56Z; https://github.com/onkarpathre/lgr-transformation-migration/pull/9#pullrequestreview-5279204369"
  artefacts:
    - "docs/product/PH4_Product_Plan.md"
    - "docs/architecture/PH4_Dependency_Register_Architecture.md"
    - "docs/architecture/ADR-006-application-technology-stack.md"
    - "docs/architecture/ADR-007-phase3-tenancy-alignment.md"
    - "docs/architecture/ADR-008-internal-authentication-project-rbac.md"
  evidence:
    - "Architecture package and current HEAD verified at 985099c2ec05e3307bdc770af4a97e6e28df8c6e before this uncommitted documentation-only gate record."
    - "docs/approvals/PH4_Architecture_Approval_Evidence.json records all five required decisions against that exact commit and is preserved unchanged."
    - "Current .NET 10/EF Core 10 and Next.js 16/React 19 implementation, permissions, persistence and wave/readiness contracts inspected read-only."
    - "All three focused slices have exact domain, API, browser, persistence, security, performance, migration, fixture and independent-test contracts."
  decisions:
    - "Use a directed source-requires-target dependency aggregate with canonical composite FKs and inert named targets."
    - "Use persisted versioned validation evidence and a data-driven policy; project readiness consumes a non-mutating projection."
    - "Reuse ADR-006/007/008 patterns; no new ADR is justified. Independent TDA approval closes Q-01 for restricted PH4 development only."
    - "Use one phase-level approval gate, not slice approvals."
    - "Authorise ordered Slice 1 dependency capture, Slice 2 validation and Slice 3 planning impact for Developer implementation under this package."
  assumptions:
    - "The PH4 Product Plan is the Product/PRB-approved planning baseline at the exact package commit."
    - "Only internal synthetic identities and synthetic/anonymised data are used."
  risks:
    - "R-02 remains release-blocking until independent isolation evidence exists."
    - "Synthetic graph validation does not replace later representative/pilot evidence."
    - "Live browser and connected advisory evidence must be produced rather than inherited from Phase 3 limitations."
  defects: []
  blockers: []
  approvals:
    - "Five required commit-bound decisions verified in section 20.1."
  requested_action: "Developer to implement the three ordered PH4 slices against commit 985099c2ec05e3307bdc770af4a97e6e28df8c6e, within the restricted local/non-production synthetic-data scope and all architecture, security, testing and product-boundary conditions. Return any material scope, semantics, security, tenancy, permission, API, persistence, performance or acceptance change for renewed approval. Do not merge, deploy, use production/customer data, execute migration, provision Azure, enable AI or claim release readiness."
```
