# Restricted Azure Management Demo - Product Work Package

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-01", "C-02", "C-03", "C-04", "C-05", "C-06", "C-07", "C-08", "C-09", "C-10", "C-11"]
  functional_requirements: ["F-01", "F-02", "F-03", "F-04", "F-05", "F-06", "F-07", "F-08", "F-09", "F-10", "F-11", "F-12", "F-13", "F-14", "F-15"]
  non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-04", "NF-05", "NF-06", "NF-07", "NF-08", "NF-09", "NF-10", "NF-11", "NF-12", "NF-13"]
  risks: ["R-01", "R-02", "R-04", "R-07", "R-08", "R-09", "R-11", "R-12"]
  assumptions: ["A-01", "A-02", "A-03", "A-04", "A-05", "A-10", "A-11", "A-12", "A-13", "A-14", "A-15", "A-16", "A-18"]
  dependencies: ["D-01", "D-02", "D-03", "D-04", "D-05", "D-06", "D-10", "D-11", "D-13"]
  issues: ["I-01", "I-02", "I-03", "I-04", "I-06", "I-08"]
  open_questions: ["Q-01", "Q-02", "Q-03", "Q-06", "Q-07", "Q-08", "Q-09", "Q-10"]
  approvals: []
```

## 1. Document control and product decision

| Field | Value |
|---|---|
| Product work package | `AZURE-DEMO-001` |
| Role | Product Owner |
| Date | 29 September 2026 |
| Branch | `release/azure-demo-v1` |
| Exact application baseline | `6f4b9bb352dd7d2506bc4c3eb1c5b0a4ae1f40de` |
| Target | Restricted internal non-production Azure management demonstration |
| Data classification | Synthetic demonstration data only |
| Product state | `READY_FOR_ARCHITECTURE_REVIEW` |
| Package commit | `PENDING` - this Product Owner has not committed, pushed, merged or deployed |

The Product Owner selects the smallest stable management-demo scope from behaviour already implemented at the exact baseline and supported by retained quality evidence. This work package adds no product capability and does not start Phase 4 Slice 2 or Slice 3. Work needed to host the selected behaviour safely in Azure is deployment, identity, security, observability, packaging and operational enablement; it must not change the product journeys or fill any excluded functional gap.

The two Azure demo architecture documents reviewed for this decision are draft workspace inputs and are not members of the exact baseline commit. They therefore have no approval status and cannot themselves authorise implementation or deployment:

| Input | Review identity |
|---|---|
| `docs/product/PH4_Product_Plan.md` | Baseline blob `744b1829c0eb6a484665a92f4ed7b5b20abd5ac4` |
| `docs/architecture/PH4_Dependency_Register_Architecture.md` | Baseline blob `0039702104fd8faf4780146993247f64b3f9d87a` |
| `docs/quality/PH4_Dependency_Register_Slice1_Quality_Gate_Record.md` | Baseline blob `f9eeba1cd28be66cfd98cc758ea08f540e4e5049` |
| `docs/architecture/AZURE_DEMO_Deployment_Architecture.md` | Draft SHA-256 `f66e9a1bbf7fcb46e1ac6f6b559a2c286078a51a0824a8ba61174df357870245` |
| `docs/architecture/AZURE_DEMO_Environment_Configuration.md` | Draft SHA-256 `8b615b08acf5344a8f8f69a201929cd986c1529c5e63bb558d75e38fe1de39cd` |

All later approvals must be bound to one immutable package commit as specified in section 16. Until that record exists, the package is ready only for architecture review.

## 2. Objective, audience and business value

### Objective

Provide a stable, controlled browser demonstration showing management stakeholders how the existing product records, governs and evidences an Azure migration programme. The demonstration must show an end-to-end planning narrative without moving a workload, provisioning a customer target, calling a discovery API or implying production readiness.

### Audience

- Agilisys product and PRB decision-makers;
- migration practice leadership, Migration Architects, Project Managers and technical SMEs;
- TDA, Information Security, Azure Platform/Operations and Test Services reviewers; and
- named internal management-demo participants approved for the synthetic project.

External customers, public marketing audiences, customer users and anonymous users are not approved audiences.

### Business value and success measure

The demo provides one repeatable, evidence-backed view of the current accelerator so management can assess whether the existing product direction merits further governed investment. Success is measured by:

1. all nine journeys in section 6 completing in a supported browser against the same exact deployed package, using only the approved synthetic seed;
2. all deployment-readiness and post-deployment smoke criteria passing with no product-scope expansion;
3. the system visibly retaining human approval and record-only boundaries throughout; and
4. Tester and Quality evidence being attributable to the exact package commit, artifact hashes, environment deployment identifier and test run.

The measurement sources are the independent Test Evidence Pack, Quality Gate Record, deployment manifest, smoke-test report, synthetic seed manifest, application audit records and Azure monitoring evidence. No effort-saving, production-availability, customer-readiness or commercial-value percentage is claimed; Q-04 remains outside this demo decision.

## 3. Exact included product scope

Only the following existing behaviour may be demonstrated. “Included” does not assert that the baseline is currently safe to deploy; the readiness controls in this package remain mandatory.

| Product area | Included demonstration behaviour | Evidence boundary |
|---|---|---|
| Session and project context | Authenticated internal user session, active synthetic project and existing capability/permission presentation. | Azure must replace local identity simulation with Entra and a server-side membership authority; this is a deployment control, not a new product role model. |
| Customer/project administration | Existing customer, project and configuration views needed to establish the pre-seeded demo context. | No customer onboarding/offboarding redesign or complete user/role administration. |
| Server discovery | Existing file-based synthetic server CSV upload, validation, preview, explicit commit/cancel, reconciliation and history. | No direct Azure Migrate API, new format, new asset importer or broader data-quality workflow. |
| Master Inventory | Existing application and server list/detail/search/relationship views. | No new canonical web-application, file-share or software inventory. |
| SQL inventory and assessment | Existing SQL instance/database inventory, SQL discovery and approved assessment/planning records. | Human-entered records only; no migration recommendation engine or execution. |
| Dependency register | Phase 4 Slice 1 only: directed typed dependencies between supported in-project assets and controlled named references; list/detail, create/edit, confirm/unconfirm, logical archive, permissions, concurrency and audit. | The current Quality record recommends restricted approval for Slice 1 only. Validation findings and planning projections are not included. |
| Migration decisions | Existing application migration-decision record and rationale/status behaviour. | No new governed recommendation/business-approval workflow. A stored status is not autonomous or release approval. |
| Azure target records | Existing flat target-build planning records. | Planning records only; no versioned design hierarchy, provisioning, ARM/Bicep invocation or Azure subscription change by the application. |
| IP management | Existing IP record lifecycle and duplicate-active protection already present in the product. | No claim of completed subnet validation, production concurrency assurance or enterprise IPAM replacement beyond separately retained evidence. |
| Waves and readiness | Existing wave membership and fixed readiness views/checks. | No dependency validation, dependency-derived blockers, database wave membership or new human approval transition. |
| Draft runbooks | Existing draft runbook and task update foundation. | No separate completed rollback capability, workload-aware expansion, technical-SME approval enhancement or executable automation. |
| Dashboard and audit | Existing programme dashboard and significant-change audit evidence needed by the nine journeys. | No new reports, export formats, audit-search product or external-execution feature. |

The Phase 4 Slice 1 Quality Gate records 323/323 .NET tests, 22/22 frontend tests, lint, a 21-page production build, EF model agreement and 14/14 SQL assurance steps as passing. Its npm risk acceptance was restricted to localhost-only development and is not valid for external Azure reachability. Section 11 therefore makes remediation an unconditional deployment gate.

## 4. Exact exclusions

The following are not authorised by this work package:

- Phase 4 Slice 2 dependency validation, including missing/unresolved, cycle, unconfirmed or other project-level finding generation;
- Phase 4 Slice 3 dependency-to-wave/readiness projection, cross-wave dependency blockers or phase-exit behaviour;
- any other unimplemented acceptance criterion from `PH4-DEP-001`;
- new application or infrastructure assessment fields, new inventory types, new import formats or new customer-specific workflow;
- full user/membership/role administration or external customer identity;
- a new recommendation/decision approval workflow, versioned target-design model, completed subnet model, completed readiness approval gate, workload-aware runbook/rollback product or external-execution tracking;
- new reporting, CSV/Excel/PDF export, audit-search or Power BI capability;
- live or real customer data, production-derived personal data, customer exports or real migration evidence;
- production, pilot, customer acceptance, commercial licensing, public marketing use or an MVP/Phase 4 completion claim;
- migration execution, workload movement, DNS/firewall/network change or application-held migration credentials;
- Azure target provisioning or configuration by the application;
- direct Azure Migrate or third-party discovery API integration;
- AI inference, training or configuration, autonomous recommendation, multi-cloud behaviour or cost-optimisation capability;
- production tenancy selection, database-per-customer implementation or a claim that the restricted shared-schema demo proves the production topology;
- Front Door/WAF, custom domains, multi-region/zone redundancy, autoscale, production HA, production DR or a production SLA; and
- remediation by silently weakening authentication, authorisation, tenant isolation, audit, tests, security scans, health gates or rollback controls.

If any of the nine journeys cannot pass without an excluded product change, the journey fails and returns to Product Owner scope control. It must not be repaired by starting Slice 2 or adding an unapproved feature.

## 5. Target environment and immutable restrictions

Subject to architecture and human approval, the target is one UK South restricted non-production environment in the existing `Onkar.Pathre` resource group:

- one public Next.js web application on native Node.js 24 LTS;
- one private ASP.NET Core API application on native .NET 10;
- one shared Linux Standard S1 App Service plan, one worker, with `staging` slots for both applications;
- same-origin browser access through a narrow web-to-private-API proxy;
- one Azure SQL Database at Standard S0 for the approved restricted-demo shared-schema topology;
- Entra-only, passwordless API-to-SQL access using least-privilege managed identity and a separate controlled migration identity;
- private endpoints for API, SQL, Key Vault and Blob Storage, with public access denied as approved by architecture;
- private Blob Storage for the already supported discovery journey; and
- workspace-based Application Insights and Log Analytics in the approved UK region.

No Azure or SQL resource exists by authority of this document. Architecture must confirm the exact design, runtime availability, private connectivity, tenancy exception and policy compliance before development or provisioning begins.

### Synthetic-data-only restriction

All application records, uploaded files, identities represented in business data, hostnames, addresses, migration evidence and screenshots must be fictional and visibly labelled synthetic. A versioned, checksummed, idempotent seed manifest must identify the expected records and refuse execution outside the `AzureDemo` environment. No production/customer data may be copied, transformed, masked ad hoc or used as a seed source. Only pre-approved synthetic CSV files may be uploaded. A synthetic/non-production banner must remain visible.

### Microsoft Entra ID requirement

Only named internal Agilisys workforce-tenant users may access the demo. The approved implementation must use Microsoft Entra ID authorization-code flow with PKCE, the delegated `lgr.access` API scope, exact tenant/audience/client validation, named assignment, MFA/Conditional Access as decided by the Identity Platform owner, and server-side project membership derived from validated `tid`/`oid`. Roles, permissions, customer IDs and project grants must not be accepted from browser-controlled claims or headers. Anonymous business endpoints and external/customer identities are prohibited.

### LocalTest and test-principal prohibition

An externally reachable Azure deployment must run only in the distinct `AzureDemo` environment. `LocalTest`, Development/Testing identity simulation, `appsettings.LocalTest.json`, local aliases and `X-Lgr-Test-Principal` are prohibited from Azure settings, artifacts and runtime behaviour. The web proxy must strip prohibited identity headers and the API must reject or ignore them without changing authentication, role, customer or project context. CI and post-deployment scanning must prove their absence. The header value must never be logged.

## 6. Nine priority browser demonstration journeys

Each journey uses the same approved synthetic project and exact deployed package. Every journey records the authorised actor, UTC timestamp, project context and correlation/trace identifier where supported.

### J-01 - Entra sign-in and project-scoped session

A named internal user signs in through Entra, selects the authorised synthetic project and views the existing session capabilities. A read-only user sees only permitted actions. An unassigned project request fails without revealing whether the project exists. LocalTest aliases and `X-Lgr-Test-Principal` have no effect.

### J-02 - Governed server discovery import

An authorised user uploads the approved fictional server CSV, reviews validation and create/update/unchanged/warning/reject preview counts, explicitly commits the staged import and views its history. A duplicate or invalid sample fails according to the existing contract. The journey uses no direct discovery API and adds no import format.

### J-03 - Application and server Master Inventory

The user searches and pages existing fictional applications and servers, opens their current relationships and observes that an import changes only fields governed by the existing reconciliation contract. A direct request for another project’s identifier is denied without data or count leakage.

### J-04 - SQL inventory and assessment records

The Database SME browses fictional SQL instances and databases and updates the existing assessment/planning record using an authorised role. A read-only reviewer cannot mutate it, and a stale write receives the existing safe concurrency response. The UI and narration make clear that these are human-owned planning records and execute nothing.

### J-05 - Phase 4 Slice 1 dependency register

The Migration Architect creates a supported dependency or controlled named reference, views it from the existing bounded dependency surfaces, edits it, confirms/unconfirms it and logically archives it. Duplicate, self, invalid and cross-project relationships are rejected under the Slice 1 contract; a reviewer can view but not mutate. The journey must not run graph validation, create cycle findings or claim wave impact.

### J-06 - Migration decision and Azure target planning record

The user records an existing fictional migration decision and flat Azure target-build planning record with rationale/status. The demonstration shows the stored record and explicitly shows there is no endpoint, credential or UI action that provisions or modifies Azure resources.

### J-07 - Existing IP record lifecycle

The user exercises only the implemented fictional IP record states and existing duplicate-active protection. The narration states that the product records planning data, does not configure Azure networking, does not replace enterprise IPAM and does not claim the excluded completion work.

### J-08 - Existing wave and fixed readiness view

The user places supported fictional workloads into an existing wave and views the current fixed readiness result. Any displayed blocker comes only from rules already implemented at the baseline. No dependency validation, dependency-derived blocker, automatic wave movement or approval action is demonstrated.

### J-09 - Draft runbook, dashboard and audit boundary

The user opens the existing draft runbook/task foundation and programme dashboard, updates an allowed draft task and views available significant-change audit evidence. The artefact remains a draft and cannot be represented as technically approved without the responsible SME. The application contains no migration execution control; separate rollback-plan completion and external-execution tracking are excluded.

## 7. Controlled database migration and rollback requirements

1. CI must build and test against SQL Server, then produce a hashed Linux EF migration bundle, idempotent SQL script and migration manifest as artifacts separate from the API package.
2. A named Azure SQL/DBA and TDA reviewer must compare the manifest/script with the deployed `__EFMigrationsHistory`. Any destructive operation, data rewrite, unsupported `Down` path or unexplained model difference blocks deployment.
3. Before migration, the deployment record must capture the database identity, schema/migration state and an Azure SQL point-in-time-restore checkpoint.
4. Only an approved private-network Azure DevOps agent and dedicated passwordless migration identity may run the reviewed bundle. The runtime identity must not have schema-administration rights.
5. Migrations must be additive and backward compatible with both old and new web/API versions throughout the slot-swap window. Schema, tenant constraints and synthetic seed reconciliation must pass before slot deployment.
6. The API must never invoke `Database.Migrate`, `EnsureCreated`, an EF `Down`, an ad hoc repair script or seed logic at startup.
7. Normal application rollback is slot swap-back and database forward-fix. If incompatibility or corruption requires database reversal, the demo becomes unavailable and writes stop. Under named human/DBA approval, restore the checkpoint to a new database, validate it, update only the approved slot-sticky passwordless setting and swap back compatible artifacts.
8. Failed migrations, artifacts, logs and audit evidence must be preserved. No destructive cleanup is authorised by this package.

## 8. Monitoring, health checks and audit

### Health and monitoring

- API `/health/live` is process-only, anonymous and detail-free.
- API `/health/ready` returns generic `200/503` and checks bounded SQL connectivity, membership-provider readiness/version and Blob availability without enumerating dependencies or identities.
- Web `/health` returns generic `200/503` and verifies the Node service plus API readiness through the private path.
- App Service health checks and slot warm-up use readiness paths, never the baseline’s unconditional health response.
- Both services use Azure Monitor OpenTelemetry, W3C trace context and distinct service names. Correlation must flow browser/web to API and dependency traces.
- Metrics and alerts cover availability/readiness, HTTP failures, unhandled errors, auth failures/denials, SQL/Key Vault/Blob dependency failure, import failure, failed deployment, slot health and the log daily cap.
- Logs are initially retained for 30 days with sampling and a small approved cap. Tokens, secrets, connection strings, uploaded rows, request/response bodies and customer payloads must not be logged.
- A named operational owner receives and acknowledges alert-test evidence before demonstration entry.

### Product audit

Significant demonstrated writes must retain the server-derived actor, UTC timestamp, customer/project, change type and correlation context under the existing audit contract. Audit and telemetry must remain tenant/project scoped, minimise identity data and never record tokens or prohibited header values. Demonstration evidence must show that read-only users cannot mutate and that cross-project requests do not disclose foreign audit records.

## 9. Azure DevOps build, test and deployment pipeline requirements

The protected-branch workflow must produce immutable, hashed artifacts from one exact package commit. No agent may push directly to `release/azure-demo-v1`, approve/merge the PR or deploy.

### PR/build validation

- verify the approved work item, traceability, expected base and commit-bound approvals;
- locked .NET restore, format check, Release build, unit/integration tests, EF model agreement and the SQL Server assurance lane;
- Node 24 `npm ci`, lint, the complete frontend regression suite and production Next.js build;
- mandatory vulnerable dependency remediation and the connected audit gate in section 11;
- NuGet direct/transitive vulnerability and deprecated-package checks;
- dedicated secret scanning, SAST, dependency/licence review and SBOM generation;
- Bicep format/lint/build, policy/security scan and approved resource-group-scoped `what-if`;
- separate hashed API ZIP, Next standalone ZIP, EF bundle/script/manifest and Bicep artifacts;
- local CI startup of `server.js` proving the home page, a deep route and a hashed static asset; and
- publication of all tests, scans, coverage, artifact hashes and evidence against the same commit.

### Gated deployment

- use protected Azure DevOps Environments `azure-demo-staging` and `azure-demo`, named human approvals and an exclusive lock;
- use workload-identity federation and least-privilege service connections; client secrets, publish profiles and public SQL workarounds are prohibited;
- run migrations only from the approved VNet-connected agent;
- deploy web/API artifacts only to their `staging` slots, warm and smoke test there;
- require independent Tester `PASS`, Quality Manager recommendation and named human demo-release approval before any swap; and
- run all post-swap smoke checks and retain previous artifacts/slots for the approved rollback window.

## 10. Deployment slots and rollback expectations

The `staging` slots are restricted change-validation surfaces, not a second environment, and use the same synthetic demo database. Slot-specific identities, private endpoints and sticky settings must be approved and tested independently.

The API staging slot is warmed and verified first, followed by the web staging slot through the private API path. The API swaps first and the web second only after compatibility checks pass. No artifact is deployed directly to a main slot. If pre-swap checks fail, the current main slots remain untouched. If post-swap checks fail, freeze demo writes, swap the web back and then the API, run read-only integrity/health checks and follow section 7 for any database incompatibility. No improvised database rollback is allowed.

The prior application artifacts, deployment manifest and usable slots must remain available for a human-approved rollback window long enough to complete the scheduled demonstration and immediate evidence review. Architecture and Operations must set the exact duration in the commit-bound decision; an unspecified rollback window blocks deployment.

## 11. Vulnerability remediation and frontend evidence gate

The baseline lock resolves vulnerable `@vitest/mocker` `4.1.10` through Vitest. The prior time-bound risk acceptance applied only to localhost, non-externally reachable development and cannot be carried into this Azure demo.

Before any web endpoint becomes externally reachable, the Developer must:

1. update Vitest and `@vitest/mocker` to `4.1.11` or a later compatible stable patched version through the normal reviewed dependency process and regenerate the lock file;
2. run the complete frontend regression suite successfully with no failed or skipped required test;
3. run frontend lint successfully;
4. produce the successful production Next.js build and expected route set;
5. run a connected, non-offline `npm audit` against the remediated lock with exit code `0` and zero reported vulnerabilities; and
6. attach the dependency diff, exact resolved versions, audit output, test output and build output to the same-commit Implementation and Test evidence.

An artifact that omits development dependencies does not waive this gate because the affected tool participates in CI/build assurance. Any unapproved moderate, high or critical finding blocks external deployment. Risk acceptance cannot be granted by an agent.

## 12. Low-cost configuration, cost approval, availability and support

### Cost envelope

The planning configuration is one S1 worker with no autoscale, one SQL S0 database, Standard Key Vault, small Standard LRS storage, approved private endpoints, 30-day sampled/capped logs and an existing private deployment agent where available. The architecture draft estimates roughly GBP 100-210 per month before enterprise discounts, licences, Defender/scanning, notifications, tax and any new agent capacity. This is an estimate, not a quote or budget decision.

Before provisioning, Product/PRB and Azure Platform/Operations must approve the priced configuration under the organisation’s agreement, funding owner, cost centre, budget ceiling, alert recipients, resource tags and expiry date. Budget alerts are required at 50/75/90/100 percent. Weekly review applies while the demo is active and monthly review otherwise. Scale-up, Premium selection or cost-envelope increase requires fresh approval; the platform must fail rather than silently upscale.

### Availability and support

This package authorises no production SLA, 24x7 support, high availability, pilot service or Q-08 production-service acceptance. Availability is limited to pre-booked internal management demonstration and approved change/test windows. A named Azure Platform/Operations owner must confirm the demonstration window, pre-demo health check, monitoring coverage, incident contact, stop/go authority, rollback owner, cost owner and expiry/decommission decision. Planned interruption is acceptable outside booked windows when communicated to the audience. Any unresolved health, security, data-integrity or rollback issue makes the demo unavailable; the scheduled session is postponed rather than bypassing a gate.

## 13. Deployment-readiness acceptance criteria

All criteria are mandatory and must be evidenced against the exact package commit unless explicitly marked as a human decision.

| Ref | Acceptance criterion | Traceability |
|---|---|---|
| AC-01 | Product/PRB approves the objective, exact included/excluded scope, nine journeys, synthetic-only position, cost ceiling and restricted-demo boundary at the package commit. | D-01, Q-02, R-06 |
| AC-02 | TDA approves the final architecture, Q-01 disposition, public-web/private-API pattern, shared-schema demo exception, App Service/SQL tiers, private connectivity, migration and rollback at the package commit. | Q-01, NF-03, NF-10, NF-12 |
| AC-03 | Information Security approves external reachability, Entra/RBAC, LocalTest eradication, tenant isolation, headers/CORS, private endpoints, upload controls, telemetry redaction and vulnerability gates. | NF-01-NF-06, NF-11, R-02 |
| AC-04 | Azure Platform/Operations approves the resource group/region, policy/quota/naming/tags, network/DNS, identities, Azure SQL controls, protected deployment path, budget, support, monitoring, expiry and rollback ownership. | D-02-D-06, NF-07, NF-12 |
| AC-05 | Test Services approves the isolated environment, synthetic seed/files, browser matrix, security/tenant test plan, migration/rollback rehearsal and entry/exit evidence. | D-11, I-06, NF-09 |
| AC-06 | Required Identity Platform, Data Protection/DPO, DBA, Network, Azure DevOps/repository and Service Transition supporting decisions are recorded where the approved architecture assigns them; none is inferred from this package. | Q-06, Q-08, Q-09, NF-04 |
| AC-07 | The Developer Implementation Work Package maps every change to deployment/security enablement and proves that no new product capability or Slice 2/3 behaviour was added. | C-01-C-11, NF-10 |
| AC-08 | Entra workforce sign-in, exact token checks, named assignment and server-side project membership pass; external/anonymous access and caller-selected authority fail closed. | F-01, F-02, F-15, NF-01, NF-02 |
| AC-09 | LocalTest artifacts/settings/aliases and `X-Lgr-Test-Principal` authority are absent from Azure artifacts/configuration/runtime and verified by tests/scans. | NF-01, NF-03, NF-11 |
| AC-10 | Web/API/SQL/Key Vault/Blob network exposure, managed identities and least privilege match the approved design; only the web entry point is externally reachable. | NF-01, NF-03, NF-05 |
| AC-11 | The controlled migration artifact, review, backward-compatibility proof, PITR checkpoint and restore/swap-back rehearsal meet sections 7 and 10. | NF-07, NF-10, R-09 |
| AC-12 | API/web health, traces, alerts, redaction, audit, retention and named operational response meet section 8. | F-14, NF-04, NF-06, NF-12 |
| AC-13 | The synthetic seed is versioned, checksummed, idempotent, environment-locked and reconciled; inspection finds no real customer/personal data. | A-18, NF-04 |
| AC-14 | The `@vitest/mocker` remediation, full frontend regression, lint, production build and clean connected npm audit all pass at the same commit. | D-13, NF-03, R-09 |
| AC-15 | Locked .NET restore/build/tests, SQL assurance, EF agreement, NuGet scan, secret scan, SAST, licence review, SBOMs and Bicep validation/what-if pass with no unapproved finding. | NF-03, NF-10 |
| AC-16 | Immutable application, migration and infrastructure artifacts have recorded hashes and are promoted through protected environments without rebuild or direct-main deployment. | NF-10, NF-12 |
| AC-17 | Independent Tester issues `PASS` and the Quality Manager issues a recommendation for the same commit, artifact hashes, deployment ID and environment. | D-11, I-06 |
| AC-18 | A named human Azure-demo release authority approves the staging deployment and later slot swap after all prior evidence. | A-11, A-12 |
| AC-19 | No high/critical security issue, cross-tenant defect, data-loss risk, destructive migration, missing rollback or product-boundary breach remains. | R-02, R-09, R-11 |
| AC-20 | Product Owner confirms immediately before swap that no scope drift, customer data, production claim, Slice 2/3 behaviour or excluded feature is present. | R-06, A-18 |

## 14. Post-deployment smoke-test acceptance criteria

Each result must record UTC time, package commit, artifact hash, infrastructure deployment ID, site/slot, tester identity and correlation/trace identifier without storing tokens, secrets or personal data.

| Ref | Smoke acceptance criterion |
|---|---|
| SMK-01 | HTTP redirects to HTTPS and connections below the approved TLS minimum fail. |
| SMK-02 | Web `/health`, the home page and a directly navigated deep route return the expected healthy/rendered result. |
| SMK-03 | A hashed `/_next/static/` JavaScript/CSS asset returns `200`, correct MIME/cache headers and non-empty content. |
| SMK-04 | The API public hostname is not reachable from the internet and discloses no metadata. |
| SMK-05 | API, SQL, Key Vault and Blob resolve/use private paths and accept only their approved identities. |
| SMK-06 | A named assigned internal user completes Entra PKCE sign-in with the exact tenant, audience, client and scope; no token appears in URL, local storage or logs. |
| SMK-07 | Missing, expired, wrong-tenant, wrong-audience and disallowed-client tokens receive safe `401/403` results with no fallback. |
| SMK-08 | `X-Lgr-Test-Principal` and all prohibited identity headers have no authentication, role, customer or project effect and their values are not logged. |
| SMK-09 | An authorised synthetic project succeeds; a foreign/unassigned project receives a non-enumerating denial with no data, count, ETag or existence leak. |
| SMK-10 | Unapproved origins/methods/headers fail while the approved same-origin proxy path succeeds. |
| SMK-11 | Web/API HTTPS, HSTS, CSP/frame protection, `nosniff`, referrer, permissions, host and proxy-header policies match the approved matrix. |
| SMK-12 | Live/ready/web health behave distinctly; a safe staging dependency-failure exercise returns readiness `503` and produces the expected alert/trace without detail leakage. |
| SMK-13 | Runtime SQL DML needed by the journeys succeeds while DDL, user creation and other unapproved operations fail; migration identity rights match the reviewed contract. |
| SMK-14 | Required Key Vault/Blob access succeeds and unapproved scope, public access and cross-container/project attempts fail. |
| SMK-15 | `__EFMigrationsHistory`, schema checks and seed counts/checksum match the exact manifests; no startup migration or seed occurs. |
| SMK-16 | The approved synthetic CSV completes the existing scan/storage/preview path; malformed, oversized and wrong-type files fail safely with correct tenant path and audit evidence. |
| SMK-17 | One browser-to-web-to-API-to-SQL request retains trace correlation without payload, token, secret or prohibited header leakage. |
| SMK-18 | Required alerts reach the named owner and sampling, retention and the approved daily cap are active. |
| SMK-19 | Slot warm-up blocks an unhealthy candidate and the planned swap-back rehearsal restores the prior compatible version without direct-main deployment. |
| SMK-20 | Artifact/configuration scan proves patched dependencies and absence of LocalTest files/aliases, test-principal injection, `.env`, secrets, passwords, publish profiles and prohibited dev artifacts. |
| SMK-21 | All nine browser journeys in section 6 pass without invoking or presenting an excluded capability. |
| SMK-22 | Negative inspection confirms no Azure provisioning, migration execution, direct discovery API, AI, multi-cloud or external-customer access path. |

Failure of any mandatory smoke criterion blocks demonstration entry. Evidence may not be made green by deleting, skipping or weakening the test.

## 15. Independent Tester and Quality evidence

The independent Tester must derive a requirements-to-test matrix from this Product Work Package and the approved Architecture Work Package. At minimum, the Test Evidence Pack must contain:

- exact package commit, application/migration/Bicep artifact hashes and Azure deployment identifier;
- results for AC-01 through AC-20 and SMK-01 through SMK-22;
- supported Chrome and Edge browser results for all nine journeys, including keyboard/focus/reflow/contrast checks appropriate to the demonstrated surfaces;
- authentication, authorisation, tenant/project IDOR, file, cache, log and background-path isolation evidence for every demonstrated route;
- vulnerability, secret/SAST, dependency, migration, rollback, health, monitoring, audit and synthetic-data evidence;
- defect list, untested scope and explicit confirmation that Phase 4 Slice 2/3 were not started; and
- an explicit `PASS` or `FAIL`. `PASS_WITH_ACCEPTED_RISK` is insufficient for an externally reachable deployment unless a named human risk owner records a fresh exact-commit acceptance that does not conflict with section 11 or the no-high/critical/cross-tenant/data-loss gates.

The Quality Manager must independently verify the full evidence chain and issue `RECOMMEND_APPROVAL`, `REJECT` or `BLOCKED_PENDING_HUMAN_DECISION` against the same commit, artifacts, deployment and test run. The Quality Manager may not repair code/tests, accept risk, merge, deploy or turn its recommendation into release authority.

The current Phase 4 Slice 1 Quality Gate is retained as historical input only. It does not authorise Azure deployment and its localhost-only npm risk decision cannot satisfy this package.

## 16. Commit-bound human decisions

### Single package-commit rule

Before implementation begins, the final Product Work Package, approved Architecture Work Package, environment configuration and any decision record must be present together at one immutable Git commit on the governed branch or PR. Every decision below must quote that full commit SHA, the package/work-item ID `AZURE-DEMO-001`, reviewer identity and role, UTC date, decision, approved scope, conditions, expiry where applicable and durable evidence link.

The package commit is currently `PENDING` because this Product Owner was explicitly prohibited from committing. The two Azure architecture inputs are currently untracked draft files. Therefore no existing approval is treated as applying to this package, and no reviewer may approve only a floating branch, file path, draft hash or later application commit by inference. A material change to product scope, architecture, identity, tenancy, reachability, data classification, cost envelope, acceptance criteria or rollback invalidates the decisions and requires re-review at a new exact package commit.

### Required decisions at that exact commit

| Authority | Mandatory decision |
|---|---|
| Product/PRB | Approve objective, audience, exact features and exclusions, nine journeys, synthetic-only classification, restricted-demo value, cost/funding ceiling and Q-02 disposition sufficient for this demo. This is not a release or full MVP approval. |
| Solution Architect / independent TDA | Approve the Architecture Work Package, Q-01 scope, native runtime lifecycle, trust boundaries, public-web/private-API pattern, non-production shared-schema exception, storage addition, Entra/membership design, App Service/SQL tier, migration, slots and rollback. |
| Information Security | Approve restricted external reachability, threat model, Entra/RBAC, LocalTest eradication, tenant isolation, private endpoints/proxy, upload controls, headers/CORS, telemetry redaction, security scans and vulnerability policy. |
| Azure Platform/Operations | Approve UK South and `Onkar.Pathre` use, Azure Policy/quota/naming/tags, network/DNS/private agent path, identities and least privilege, SQL/backup controls, protected pipeline/service connection, priced configuration, budget/alerts, availability/support, operational owner and expiry/decommission decision. Named specialist evidence may be supplied by Identity Platform, Network, DBA, Azure DevOps and Service Transition owners. |
| Test Services | Approve the environment, synthetic fixtures/files, requirements-to-test matrix, browser/accessibility/security/tenant test scope, migration/rollback rehearsal and evidence entry/exit criteria. |

Data Protection/DPO must also record Q-06 applicability for internal identity and telemetry if required by policy. Q-09 external customer identity remains open and excluded; Q-07 commercial positioning, Q-08 production operating model and Q-10 final product naming are not closed by this demo.

Before the first externally reachable staging deployment and before the later slot swap, named human authorities must additionally record the Developer hand-off, independent Tester `PASS`, Quality recommendation, Information Security confirmation, Product Owner no-scope-drift confirmation, operational readiness confirmation and Azure-demo release decision against the exact artifact set. No agent decision substitutes for those approvals.

## 17. Product risks and treatments

| Risk | Required product treatment |
|---|---|
| Management interprets a polished demo as production or full-MVP readiness. | Persistent restricted-demo banner, scripted boundary statements, explicit excluded-scope evidence and no customer/public audience. |
| Deployment enablement grows into new product behaviour or Slice 2. | Developer diff and independent tests must map every change to this package; any new product journey returns to Product Owner. |
| Entra identity is mistaken for complete customer identity/administration. | Internal workforce users only; Q-09 and full user administration remain open/excluded. |
| Shared-schema demo is mistaken for the production tenancy choice. | TDA-approved non-production exception label and no production-tenancy claim. |
| Vulnerable build tooling reaches an externally accessible environment. | Section 11 is a non-waivable pre-reachability gate unless a controlling human authority formally changes policy outside agent authority. |
| Synthetic data is contaminated with real identifiers or files. | Approved seed/file manifests, automated/manual inspection, clear labels and fail-closed seeding. |
| Migration/slot failure damages demo evidence. | Backward-compatible migration, PITR checkpoint, swap-back rehearsal, preserved artifacts and human stop/go. |
| Low-cost settings are silently scaled or become an unowned recurring cost. | Approved budget ceiling, alerts, tags, named owner, review cadence and expiry decision. |
| Existing shallow features are narrated as complete capabilities. | Journey scripts use the exact boundaries in sections 3, 4 and 6; unsupported completion claims fail acceptance. |

## 18. Restricted approval statement

Any approval arising from this package is restricted to a non-production internal management demo using synthetic data and the exact commit/artifacts approved. It does not authorise production, pilot, customer data, customer/external access, commercial release, merge, protected-branch push, deployment by an agent, full Phase 4 completion, Phase 4 Slice 2 or Slice 3, full MVP approval or human release approval.

## 19. Product Owner hand-off

```yaml
handoff:
  from_agent: "product-owner"
  to_agent: "architect"
  state: "READY_FOR_ARCHITECTURE_REVIEW"
  work_item: "AZURE-DEMO-001"
  branch: "release/azure-demo-v1"
  commit: "PENDING"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-01", "C-02", "C-03", "C-04", "C-05", "C-06", "C-07", "C-08", "C-09", "C-10", "C-11"]
    functional_requirements: ["F-01", "F-02", "F-03", "F-04", "F-05", "F-06", "F-07", "F-08", "F-09", "F-10", "F-11", "F-12", "F-13", "F-14", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-04", "NF-05", "NF-06", "NF-07", "NF-08", "NF-09", "NF-10", "NF-11", "NF-12", "NF-13"]
    risks: ["R-01", "R-02", "R-04", "R-07", "R-08", "R-09", "R-11", "R-12"]
    assumptions: ["A-01", "A-02", "A-03", "A-04", "A-05", "A-10", "A-11", "A-12", "A-13", "A-14", "A-15", "A-16", "A-18"]
    dependencies: ["D-01", "D-02", "D-03", "D-04", "D-05", "D-06", "D-10", "D-11", "D-13"]
    issues: ["I-01", "I-02", "I-03", "I-04", "I-06", "I-08"]
    open_questions: ["Q-01", "Q-02", "Q-03", "Q-06", "Q-07", "Q-08", "Q-09", "Q-10"]
  artefacts:
    - "docs/product/AZURE_DEMO_Product_Work_Package.md"
    - "docs/architecture/AZURE_DEMO_Deployment_Architecture.md"
    - "docs/architecture/AZURE_DEMO_Environment_Configuration.md"
  evidence:
    - "Exact application baseline 6f4b9bb352dd7d2506bc4c3eb1c5b0a4ae1f40de."
    - "Phase 4 Slice 1 Quality Gate retained as restricted historical evidence; it does not authorise Azure deployment."
    - "Scope limited to existing Phase 1-3 surface and quality-reviewed Phase 4 Slice 1 dependency registration."
  decisions:
    - "Do not add product features or start Phase 4 Slice 2/3."
    - "Remediate @vitest/mocker 4.1.10 and prove full frontend regression, build and clean connected npm audit before external reachability."
    - "Require one exact package-commit approval set before implementation."
    - "Approval is restricted to a synthetic non-production internal management demo."
  assumptions:
    - "Architecture can make the selected existing journeys safely deployable without adding product behaviour."
  risks:
    - "The Azure architecture inputs remain drafts outside the exact baseline until governed into a package commit."
    - "External Azure reachability invalidates the prior localhost-only npm risk acceptance."
  defects: []
  blockers:
    - "Implementation is blocked until the Product/PRB, TDA, Information Security, Azure Platform/Operations and Test Services decisions are recorded against one exact package commit."
  approvals: []
  requested_action: "Architect to reconcile the two Azure demo drafts with this exact product scope, remove all Slice 2/3 assumptions, identify any remaining gate conflicts, and prepare the commit-bound Architecture Work Package for independent approval."
```

READY_FOR_ARCHITECTURE_REVIEW
