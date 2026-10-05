# Azure Demo Smoke Evidence Coverage and Delivery Amendment Proposal

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-11"]
  functional_requirements: ["F-13", "F-14", "F-15"]
  non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-04", "NF-05", "NF-06", "NF-07", "NF-10", "NF-11", "NF-12", "NF-13"]
  risks: ["R-02", "R-09", "R-11"]
  assumptions: ["A-11", "A-12", "A-18"]
  dependencies: ["D-04", "D-11"]
  issues: ["I-06", "I-08"]
  open_questions: ["Q-08"]
  approvals: []
```

Status: **PROPOSED WORK-PACKAGE / ADR AMENDMENT — NOT APPROVED**. The approved Product and Architecture packages define the acceptance meaning, staging-first order, evidence content and protected review gates. They do not define a usable producer/ingestion mechanism for protected browser, specialist and rehearsal evidence during the same release run. The ownership, bundle ingestion and production-applicability entries labelled “proposed” below are not recorded human approvals.

## Confirmed current state

- The runner needs protected runtime evidence for 17 checks: SMK-01, 04-09, 12-19, 21 and 22. The other five checks have runner automation, although several are only partially automated against their full acceptance meaning.
- The pipeline delivered only `sql-bootstrap.json`. That file proves a durable SQL principal/grant prerequisite and is neither a smoke result nor a release approval. It is now isolated as `AZDEMO_SQL_BOOTSTRAP_EVIDENCE_DIRECTORY` and consumed only before migration.
- No repository script currently produces protected `SMK-xx.json` results from live assertions. `tests/assurance/Test-AzureDemoCandidate.ps1`, .NET tests, Vitest tests, Bicep/static tests and `AzureDemoSqlRuntimeValidation.sql` provide useful executable coverage but are not exact deployed-runtime evidence.
- The existing `AzureDemoSqlRuntimeValidation.sql` refuses every database except the obsolete `sqldb-lgrtm-azdemo` name and is not wired into the protected pipeline. It cannot be claimed for the approved `sqldb-mtp-dev-uks-001` target without review and repair.
- A real previous deployed release for SMK-19 cannot be established from Git branches, local refs, current-release artifacts or the current worktree. Platform/Operations must identify it from the protected deployment record and supply its distinct source commit, immutable deployment-manifest file/hash and deployment evidence reference.
- Package-level Product/PRB, TDA, Information Security and Test Services approvals at `b8800e1...` authorised controlled implementation/testing only. They did not approve the proposed producers, evidence-ingestion route, operational identities, fault injection, alert test, rehearsal or release.

## Exact SMK-01–SMK-22 coverage matrix

“Existing” means executable coverage that exists in the repository; it does not mean the protected check passed. “Owner” is proposed unless the cell explicitly cites a recorded package-level authority. `S` means the complete criterion is required against staging before the release gate. `P` describes proposed post-swap applicability and never authorises that same swap. `R` is a separately protected rehearsal.

| ID | Acceptance criterion retained exactly | Existing executable coverage | Missing deployed coverage | Execution location / identity | Required inputs | Evidence producer and review | S / P applicability |
|---|---|---|---|---|---|---|---|
| SMK-01 | HTTP redirects to HTTPS; connections below approved TLS minimum fail. | Runner proves exact-host/path HTTP 301/302/307/308; PowerShell 7 fixture regression covers redirect handling/redaction. | Real lower-TLS rejection from an external client. | Outside authorised private network; anonymous transport probe. | Resolved web host, exact deployment ID/commit/manifest hash, TLS policy. | Proposed hosted external transport producer; Tester + InfoSec review. No producer approval recorded. | S: both assertions. P: repeat read-only against main host. |
| SMK-02 | `/health`, home and direct deep route are healthy/rendered. | Runner now requests all three and requires 200 plus non-empty home/deep content. | Browser-rendered semantics remain independent journey evidence. | Sweden managed pool; anonymous web client. | Resolved slot host and deployment provenance. | Existing runner; Tester reviews actual output. | S; P repeat read-only. |
| SMK-03 | Hashed Next JS/CSS returns 200, correct MIME/cache and non-empty content. | Runner now requires a hash-like static name, JS/CSS MIME, non-empty body and public immutable cache policy. | Browser loading remains part of journey evidence, not this transport assertion. | Sweden managed pool; anonymous web client. | Root HTML, asset URL, header matrix. | Existing runner; Tester review. | S; P repeat read-only. |
| SMK-04 | API public hostname is unreachable/denied from the internet with no metadata. | Runner has an optional denial request branch; pipeline supplies no `ApiPublicUri`. | Test from outside the authorised private network and disclosure inspection. A Sweden-pool denial is not equivalent. | Microsoft-hosted/external network; anonymous client. | Exact Azure-resolved API host, response metadata policy, deployment provenance. | Proposed external producer; InfoSec/Tester review. | S; P repeat against main API host. |
| SMK-05 | API, SQL, Key Vault and Blob use private paths and only approved identities. | Bicep/DNS/subnet/configuration contract tests; exact target resolver. | Live DNS/connectivity for all dependencies plus allowed and denied identity tests. | `mdp-mtp-dev-uks-001` Sweden managed pool for private path; runtime identities for data-plane access. | Resource IDs/FQDNs, private DNS results, approved role matrix, slot UAMIs. | Proposed Network/Platform specialist automation; Tester review. Package-level Test Services authority exists, operational ownership does not. | S for staging identities; P read-only validation for distinct production identities. |
| SMK-06 | Assigned internal user completes PKCE with exact tenant/audience/client/scope and no token persistence/leakage. | Vitest/static contract checks PKCE S256 and absence of persistent token storage. | Real assigned-user browser flow, assignment enforcement, token metadata and browser/log inspection. | Interactive assigned-user browser; named workforce user. | Approved user assignment, app registration/redirect URI, browser procedure, redacted telemetry. | Proposed independent Tester producer; Identity/InfoSec review. | S; P repeat sign-in for production redirect context. |
| SMK-07 | Missing, expired, wrong-tenant, wrong-audience and disallowed-client tokens safely receive 401/403 with no fallback and `WWW-Authenticate` on 401. | `IdentityAuthorizationTests` and `SqlInventoryAuthorizationTests` exercise local token/authorization cases. | Full matrix against deployed API path and exact headers. | Sweden pool; untrusted-token test client, never a runtime identity. | Approved non-secret invalid-token fixtures, exact API path/host. | Proposed automated security producer; Tester/InfoSec review. | S; P repeat read-only denial matrix. |
| SMK-08 | Every prohibited identity header has no auth/role/customer/project effect and values are not logged. | Runner compares only `X-Lgr-Test-Principal` and `X-Roles`; integration tests cover several authority headers. | Complete approved header inventory, semantic response comparison and live telemetry redaction. | Sweden pool; anonymous and assigned-user contexts. | Header inventory, baseline requests, sanitized log query. | Proposed automated producer plus telemetry attachment; Tester/InfoSec review. | S; P repeat read-only. |
| SMK-09 | Authorised project succeeds; foreign/unassigned project is non-enumerating with no data/count/ETag/existence leak. | Broad integration coverage in SQL, import and dependency tests. | Real assigned-user browser/API proof for the deployed synthetic membership document. | Assigned-user browser; assigned workforce Tester. | Approved synthetic project IDs, assigned/unassigned memberships, safe expected responses. | Proposed Tester browser producer; independent review required. | S; P representative read-only repeat. |
| SMK-10 | Unapproved origins, methods and headers fail; approved same-origin proxy succeeds. | Runner now tests unapproved origin, method and authority-header preflights and a reachable same-origin proxy route. | Assigned-user successful API semantics still belong to browser evidence. | Sweden pool; anonymous/assigned web client. | Approved CORS matrix and resolved web/API hosts. | Existing runner; Tester/InfoSec review. | S; P repeat read-only. |
| SMK-11 | Web/API HTTPS, HSTS, CSP/frame, nosniff, referrer, permissions, host and proxy-header policies match. | Runner now checks approved web HSTS max-age/CSP/nosniff/referrer/frame/permissions values and the private API live response's exact CSP/nosniff/referrer/frame policy. | TLS-minimum is SMK-01; host and forwarded-header negative matrix remains missing. | Sweden pool; anonymous client. | Approved header matrix, web and private API routes. | Existing runner plus proposed host/proxy test extension; Tester/InfoSec review. | S; P repeat read-only. |
| SMK-12 | Live/ready/web differ; approved dependency outage yields ready/web 503, alert/trace and no detail leak. | Runner proves only healthy web `/health` 200; local health tests cover shape. | Separately authorised fault injection, live-vs-ready behaviour, alert/trace delivery and recovery. | Sweden pool; controlled Operations identity. | Approved fault method/change reference, health endpoints, alert/trace queries. | Proposed Platform/Operations specialist producer; Tester/InfoSec review. | S full controlled exercise. P healthy/read-only checks only; no production fault injection. |
| SMK-13 | Runtime DML succeeds; runtime DDL/user creation fails; migration identity has reviewed rights. | SQL grants/static validators and an unwired stale-target read-only SQL script. | Exact-target execution under two distinct identities, including real runtime DML and negative permissions. | Sweden pool/private SQL path; runtime UAMI and separate migration WIF identity. | Reviewed grants, exact SQL target, controlled transaction/rollback procedure, identity tokens. | Proposed DBA/Test Services producers; DBA/TDA review. One identity never proves the other. | S only for writes/negative privileges. P read-only identity/permission inventory. |
| SMK-14 | Approved Key Vault/Blob reads succeed; administration, cross-container/project and public access fail. | Bicep/RBAC/configuration and source tests. | Live approved and denied data-plane tests under exact slot identity. | Sweden pool/private path; API staging UAMI plus unapproved principal for denial. | Approved object names, RBAC matrix, synthetic object. | Proposed Platform/Tester producer; InfoSec review. | S full matrix; P approved read-only plus configuration inventory. |
| SMK-15 | Migration history, schema and seed counts/checksum are exact; no startup migration/seed. | Migration/seed pipeline steps, manifest validators, startup boundary tests; stale-target SQL assurance script. | Captured exact-target post-run results and startup telemetry bound to deployment. | Sweden pool/private SQL path; migration identity for reconciliation and runtime read-only observation. | Migration/seed/deployment manifests, exact DB, telemetry interval. | Proposed pipeline/DBA producer; Tester/DBA review. | S; P read-only reconciliation. |
| SMK-16 | Approved synthetic CSV scans/previews; malformed/oversized/wrong-type fail; tenant path/audit are correct. | Extensive unit/integration import coverage and package sample fixtures. | Live malware-scan/storage/preview path and audit evidence under assigned user. | Assigned-user browser; Discovery Analyst synthetic role. | Approved CSV plus malicious/invalid samples, project membership, scan evidence. | Proposed Tester browser producer; InfoSec review. | S controlled writes. P not repeated as a release-authorising write; optional separately approved regression only. |
| SMK-17 | One browser→web→API→SQL request shares correlation; no payload/token/secret/header leakage. | Trace/redaction configuration and code tests. | Live correlated trace/dependency query and sanitized content inspection. | Assigned-user browser plus telemetry reader. | Known journey/correlation ID, App Insights query window. | Proposed Tester + Operations producer; InfoSec review. | S; P repeat read-only. |
| SMK-18 | Required alert reaches named owner; sampling, retention and daily cap are active. | Bicep/static contract validates 17 alert families, routing and cap configuration. | Actual approved test alert and acknowledgement; live sampling/retention/cap state. | Sweden pool/control plane; named monitoring operator. | Approved alert-test change, action-group owner, live configuration inventory. | Proposed Operations producer; Tester/Service Transition review. | S full test. P read-only configuration/health only; do not send another alert automatically. |
| SMK-19 | Warm-up blocks bad candidate; protected swap-back restores real prior compatible release with no direct-main deployment. | Rollback target and pipeline-order guards only; no live rehearsal. | Real previous deployed release/manifest/evidence, approved bad-slot method, rehearsal and restoration proof. | Protected rehearsal; human-approved release operator. | Previous commit, manifest file/hash, deployment record, compatibility review, change/approval ref. | Proposed Platform/Operations producer; DBA/TDA/Tester review. | R before release gate. Never current-as-previous and never future post-swap evidence. |
| SMK-20 | Deployed artifact/config scan proves patched dependencies and excludes LocalTest, test authority, `.env`, credentials, publish profiles and prohibited dev artifacts. | Package/hash/source boundary tests; runner now verifies exact 4.1.11 Vitest/mocker lock entries and scans immutable manifest paths plus source credential/LocalTest patterns. | Scan extracted exact ZIP contents and redacted live App Service configuration fingerprint. | Sweden pool; read-only deployment agent. | Immutable manifest and ZIPs, redacted App Service configuration fingerprint. | Proposed enhanced deployed-artifact producer; Tester/InfoSec review. | S; P verify promoted hashes/config fingerprint read-only. |
| SMK-21 | J-01–J-09 pass against one deployment/seed without excluded capability. | API integration journeys and Tester-owned component contract tests cover parts, not a browser run. | Nine real browser journeys, shared deployment/seed IDs and per-journey correlations. | Assigned-user browser; independent Tester. | Seed/deployment IDs, role assignments, browser matrix, journey procedure. | Proposed independent Tester producer; Quality reviews after results. | S full journeys. P representative read-only checks only; full future P set needs approval. |
| SMK-22 | Independent inspection finds no Azure provisioning, migration execution, direct discovery API, AI, multi-cloud or external-customer path. | `Test-AzureDemoSourceBoundaries.ps1`, deployment-boundary unit tests and dependency scans provide strong static coverage. | Independent deployed routes/UI/config/credential inspection bound to exact artifact. | Independent review workstation plus read-only managed-pool configuration evidence; independent Tester. | Route map, packages/SBOM, deployed config fingerprint, UI screenshots. | Proposed independent Tester producer; Quality/InfoSec review. | S; P read-only repeat for promoted target. |

## Required ordering and non-circular release gate

The approved ordering is retained and clarified as follows:

1. Validate/package the exact source commit and immutable artifacts.
2. Complete pre-deployment approvals and deploy/migrate/seed only to the staging slots.
3. Resolve the exact staging site/slot identities and infrastructure deployment ID.
4. Execute staging runtime tests. External-network, Sweden-pool, assigned-user browser, specialist, write/fault and rehearsal procedures remain distinct producers and identities.
5. Publish immutable raw results and failed results. Build the protected evidence bundle only from successful real assertions; missing inputs remain absent/incomplete and fail the gate.
6. Independent Tester reviews the actual results; Quality reviews the resulting Tester pack; Product, InfoSec, Platform/Operations, DBA and other named authorities provide only their assigned decisions.
7. The full human release gate validates the exact commit/artifact/deployment/target evidence, including the real SMK-19 previous release. Only then may the separately protected API-first/web-second swap be authorised.
8. Post-swap checks run against the production hosts and record the result. They are consequences of the swap, not prerequisites retroactively used to authorise it. Failure invokes the approved freeze/swap-back path.

The current YAML preserves steps 1–3, attempts the runner only after both staging deployments, preserves all 22 failed results, places `ReleaseApproval` after that attempt and keeps swap after the gate. Because step 5 has no approved protected-bundle ingestion source, the runner intentionally receives no protected evidence directory and remains release-blocking.

## Protected evidence contract implemented locally

`AzureDemoSmokeEvidenceContract.ps1` enforces:

- the full per-check assertion set derived from the approved acceptance wording;
- `evidenceClass: protected-runtime`, never a local/synthetic fixture evidence class;
- exact lowercase source commit and deployment-manifest SHA-256;
- exact infrastructure deployment ID and Azure DevOps definition/run origin;
- exact subscription, resource group, web/API app, slot and Azure-resolved hosts;
- the required execution perspective/identity kind, including external SMK-04, Sweden-pool SMK-05, assigned-user SMK-06 and separated SQL identities for SMK-13;
- UTC execution interval and non-empty correlation ID;
- an attachment for every real assertion, contained within the bundle and verified by SHA-256; and
- for SMK-19, a distinct previous-release commit and manifest file/hash, protected deployment reference and rehearsal approval reference. Reusing the current release is rejected.

This validation makes a bare `{"status":"PASS"}` insufficient. It does not turn self-authored JSON into independent proof: trust still depends on an approved producer identity, protected pipeline/artifact origin, retained raw attachments and later independent review.

## Minimal decision required

TDA, Test Services, Information Security, Azure DevOps/repository ownership and Azure Platform/Operations must approve one concrete same-run ingestion design before the YAML may pass `-ProtectedEvidenceDirectory`. The minimal decision must name:

1. the protected producer job or authorised upload task for each execution perspective;
2. how an assigned-user browser Tester submits sanitized artifacts to the same immutable pipeline run without exposing tokens or credentials;
3. the Azure DevOps artifact/check name, retention, permissions and tamper/origin metadata used by the aggregator;
4. the independent Tester and Quality ordering after raw results, with no self-approval;
5. the exact post-swap read-only subset and who may authorise any write, fault injection, test alert or rehearsal; and
6. the authoritative previous-release deployment record/manifest source for SMK-19.

No Secure File, pipeline/resource ID, service connection, reviewer decision, previous release or external store is proposed as if it already exists. After approval, the smallest implementation is to have protected producers publish their real assertion attachments through the approved same-run mechanism, aggregate them into this validated bundle, download that bundle before the staging runner, and leave the existing ReleaseApproval and swap ordering intact.
