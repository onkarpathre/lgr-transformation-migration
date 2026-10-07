# AZURE-DEMO-001 Protected Smoke Evidence Coverage and Implementation Plan

```yaml
traceability:
  product_version: "0.1"
  phase: "Phase 1 - MVP"
  capabilities: ["C-01", "C-02", "C-11"]
  functional_requirements: ["F-01", "F-02", "F-03", "F-13", "F-14", "F-15"]
  non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-04", "NF-05", "NF-06", "NF-07", "NF-09", "NF-10", "NF-11", "NF-12", "NF-13"]
  risks: ["R-01", "R-02", "R-09", "R-11"]
  assumptions: ["A-11", "A-12", "A-13", "A-18"]
  dependencies: ["D-02", "D-03", "D-04", "D-05", "D-06", "D-11", "D-13"]
  issues: ["I-03", "I-06", "I-08"]
  open_questions: ["Q-06", "Q-08", "Q-09"]
  approvals: []
```

Status: **PROPOSED IMPLEMENTATION PLAN - NOT APPROVED**

Work item: `AZURE-DEMO-001`; role: Architect; scope: documentation and planning only.

This document is the single coverage proposal and implementation plan. No duplicate plan is required. It does not approve a producer, identity, Azure permission, evidence store, fault injection, alert test, slot operation, first-release exception or release. Product/PRB, TDA, Information Security, Test Services, Azure Platform/Operations, Azure SQL/DBA, Azure DevOps/repository ownership, Service Transition and the human release authority retain their existing responsibilities.

## 1. Review baseline and authority boundary

The review began on branch `fix/mtp-azure-demo-reconciliation` at exact HEAD `b08c2afdf2b42765b1d8936f5a1f531a4d210042`. The index, tracked working tree and untracked-file list were clean. Existing changes therefore required no accommodation and remain preserved.

The following requirements control this plan:

- Product Work Package sections 13-16: AC-01-AC-20, SMK-01-SMK-22, exact commit/artifact/deployment binding, independent Tester `PASS`, Quality review and named human approval.
- Deployment Architecture sections 384-425 and 446-479: protected environments, immutable artifacts, private-pool execution, staging-first validation, rollback, independent test conditions and the post-deployment evidence addendum.
- Environment Configuration sections 430-495 and 560-707: service-connection/environment intent, deployment order, smoke meanings, nine browser journeys and demonstration-entry gates.
- Tester evidence: protected Azure runtime validation remains unavailable until exact deployed-runtime evidence is produced; local/component/static coverage is not a runtime pass.
- Quality record: plan-only smoke, static monitoring and rollback guards are retained partial evidence only; post-deployment acceptance remains unavailable and human-controlled.
- `AGENTS.md`: synthetic data only, tenant isolation, no migration execution or Azure target provisioning by the product, no autonomous merge/deployment/risk acceptance, preserved failed evidence and independent review.

The Product and Architecture packages were approved for controlled implementation/testing at their recorded package commit. Those decisions did not approve the producer and ingestion design below. The environment document also contains earlier proposed `lgrtm/azdemo` naming examples, including `sqldb-lgrtm-azdemo`; the current executable pipeline and application guards use the later exact `mtp/dev` identities. This plan treats repository-declared current executable values as implementation inputs, not as proof that a resource exists or as authority to use it.

## 2. Reconciled current state

### 2.1 Reported connected state

The following is supplied run context, not evidence re-executed by this documentation change:

- Application, IaC and Package validation passed in the latest reported CI run.
- The bounded post-deployment readiness regression now passes on Linux.
- The staging API and web health endpoints returned HTTP `200` in all 16 reported recent requests.
- Run 77 produced 17 `missing-evidence` failures.

These facts establish useful build/readiness progress only. They do not establish protected check acceptance, browser journeys, least privilege, fault/alert delivery, rollback or release readiness.

### 2.2 Why 17 checks fail deterministically

`AzureDemoSmokeEvidenceContract.ps1` requires protected records for SMK-01, SMK-04-SMK-09, SMK-12-SMK-19, SMK-21 and SMK-22. `Invoke-AzureDemoSmokeTests.ps1` accepts `-ProtectedEvidenceDirectory`, but the staging and post-swap pipeline calls intentionally omit it. No repository script produces a complete real protected bundle. The current result is therefore correctly release-blocking.

The current `sql-bootstrap.json` path is a durable, independently produced prerequisite for database principal/grant setup only. It is isolated to the database job and must not be copied, renamed or ingested as an SMK record, runtime result or release approval.

The contract already provides valuable fail-closed checks: exact assertion sets; `protected-runtime` evidence class; exact commit, deployment-manifest hash, infrastructure deployment ID, pipeline definition/run and Azure target; required perspective and identity kind; UTC execution interval; per-assertion contained attachments and SHA-256; and distinct prior-release provenance for SMK-19. It does **not** authenticate the submitter: `origin.producerId` is currently supplied inside the JSON being validated. The collection design in section 5 closes that trust gap through protected-system metadata and requires a validator change before ingestion is enabled.

### 2.3 Reconciliation of the five non-protected checks

These five checks have runner automation. “Automated” does not mean their full Product acceptance meaning has passed.

| Check | Current executable behaviour | Reconciled limitation |
|---|---|---|
| SMK-02 | Requests `/health`, `/`, `/inventory/servers` and a deliberately missing route; requires `200/200/200/404`, a non-empty bounded signed-out Entra shell and no generic 500 page. | This is transport/render-shell evidence, not an assigned-user browser journey. |
| SMK-03 | Parses root HTML, selects the first safe quoted same-origin `script[src]` or stylesheet `link[href]` under `/_next/static/` ending in `.js` or `.css`, verifies the exact path is a non-empty member of the manifest-bound `application/web.zip`, then requires live `200`, correct JS/CSS MIME, non-empty content and non-contradictory `public, immutable` caching. | The path validator does **not** require a filename hash token. The earlier claim that it requires a “hash-like” name was stale. Product SMK-03 still says “hashed”; Product/TDA must either approve “build-generated, immutable-package-bound asset” as the precise meaning or require a build-metadata-derived hash assertion and fixtures. No acceptance is inferred here. |
| SMK-10 | Sends unapproved origin, method and authority-header preflights and requires no CORS grant; checks that the same-origin proxy route is reachable. | Reachability is not assigned-user successful business semantics. |
| SMK-11 | Checks the web response for HSTS, CSP frame denial, `nosniff`, referrer, permissions and frame headers; checks the private API live response for CSP, `nosniff`, referrer and frame denial. | Host/forwarded-header negative cases are absent. The API branch does not assert API HSTS or permissions policy, so the broad Product wording is only partially automated. |
| SMK-20 | Checks source patterns, manifest paths and exact patched lock entries and relies on prior artifact-manifest validation. | It does not extract and scan both deployed ZIPs or bind a sanitized live App Service configuration fingerprint to the deployed slots. |

### 2.4 Obsolete SQL assurance target and bounded repair

`tests/assurance/AzureDemoSqlRuntimeValidation.sql` refuses every database except `sqldb-lgrtm-azdemo`. The current pipeline, Bicep contract, runtime connection guard, database-principal script, migration guard and seed guard use exact database `sqldb-mtp-dev-uks-001`. The SQL assurance file is therefore non-executable against the current approved target and must not be cited as deployed evidence.

Changing only the name would still be insufficient. The file currently:

- checks permission metadata but does not execute the required runtime DML or prove actual DDL/user-creation denial;
- hard-codes the current eight migrations rather than binding expected values to the immutable migration manifest supplied to the release run;
- checks only that representative seed rows exist, not the exact seed-manifest counts/checksum; and
- does not provide the separated runtime and migration identity evidence required by SMK-13.

The bounded repair is Tester/DBA-owned assurance implementation, not an application/runtime change:

1. Retain a fail-closed exact-target guard for `sqldb-mtp-dev-uks-001`, using ordinal/binary equality and refusing reset/other databases.
2. Split effective-runtime permission/DML assertions from migration-history/seed reconciliation so each runs under the approved identity or an explicitly DBA-approved `EXECUTE AS USER` procedure with the real runtime DML separately proven through the deployed API.
3. Run synthetic DML in a controlled transaction with rollback or through an approved synthetic API journey; attempt only bounded synthetic DDL/user-creation negatives and prove that no object/principal remains.
4. Supply the expected migration list, seed version, exact counts and checksum from the already validated immutable manifests; do not accept free-form SQL or model-supplied target arguments.
5. Emit only sanitized structured results (database, principal/object identifiers, assertion IDs, counts, hashes and error numbers/categories), never tokens, connection strings, row values or unrestricted SQL errors.
6. Add local positive/negative parser/target/identity tests and require DBA/TDA review before connected execution.

No SQL was executed and no SQL, pipeline or runtime script was changed by this plan.

## 3. Protected-check execution contract

Effects use: `R` read/probe only; `W` controlled synthetic write; `F` controlled fault injection; `A` alert trigger/acknowledgement; `S` slot swap/recovery. Negative HTTP/authentication requests are `R`; they must not mutate business data.

| ID | Exact required assertion IDs in the current contract | Required location and identity | Effect |
|---|---|---|---|
| SMK-01 | `minimum-tls-rejected` | Outside authorised private network; anonymous external client | R |
| SMK-04 | `public-api-unreachable-or-denied`; `no-api-metadata-disclosed` | Outside authorised private network; anonymous external client | R |
| SMK-05 | `api-private-resolution`; `sql-private-resolution`; `key-vault-private-resolution`; `blob-private-resolution`; `approved-identity-access`; `unapproved-identity-denial` | Current private managed pool; deployment agent plus exact runtime identities | R |
| SMK-06 | `pkce-s256-completed`; `exact-tenant-audience-client-scope`; `assigned-user-enforced`; `token-absent-from-url-storage-logs` | Assigned-user browser; named assigned workforce user | R (identity/session logs only) |
| SMK-07 | `missing-token-denied`; `expired-token-denied`; `wrong-tenant-denied`; `wrong-audience-denied`; `disallowed-client-denied`; `www-authenticate-on-401`; `no-authentication-fallback` | Private managed pool; untrusted-token test client | R |
| SMK-08 | `all-prohibited-headers-tested`; `no-authority-change`; `header-values-redacted` | Private managed pool; anonymous and assigned-user contexts | R |
| SMK-09 | `authorized-project-succeeds`; `foreign-project-non-enumerating-denial`; `unassigned-project-non-enumerating-denial` | Assigned-user browser; assigned workforce user | R |
| SMK-12 | `live-remains-process-only`; `ready-and-web-return-503`; `alert-and-trace-observed`; `no-dependency-details-disclosed` | Private managed pool; controlled Operations identity | F, A, then R recovery |
| SMK-13 | `runtime-dml-succeeds`; `runtime-ddl-denied`; `runtime-user-creation-denied`; `migration-rights-match-reviewed-contract` | Private SQL path; separated runtime and migration/DBA identities | W (rolled back or synthetic/audited), negative privilege attempts |
| SMK-14 | `approved-key-vault-read-succeeds`; `approved-blob-read-succeeds`; `administration-denied`; `cross-container-project-denied`; `public-access-denied` | Private path; staging runtime UAMI plus anonymous/unapproved contexts | R |
| SMK-15 | `migration-history-exact`; `schema-checks-pass`; `seed-counts-and-checksum-exact`; `no-startup-migration-or-seed` | Private SQL path; migration identity for reconciliation and runtime/telemetry readers | R |
| SMK-16 | `approved-synthetic-csv-scans-and-previews`; `malformed-file-denied`; `oversized-file-denied`; `wrong-type-file-denied`; `tenant-object-path-exact`; `audit-evidence-recorded` | Assigned-user browser; approved Discovery Analyst synthetic role | W synthetic file/data; denied negative uploads |
| SMK-17 | `browser-web-api-sql-trace-correlated`; `payload-token-secret-header-redaction` | Assigned-user browser plus read-only telemetry reader | R |
| SMK-18 | `synthetic-alert-delivered-to-named-owner`; `sampling-active`; `retention-active`; `daily-cap-active` | Protected monitoring job plus named monitoring operator | A and R |
| SMK-19 | `unhealthy-candidate-blocked`; `no-direct-main-deployment`; `swap-back-restored-previous-release` | Separately protected rehearsal; human-approved release operator | F, S |
| SMK-21 | `j01-pass`; `j02-pass`; `j03-pass`; `j04-pass`; `j05-pass`; `j06-pass`; `j07-pass`; `j08-pass`; `j09-pass`; `excluded-capabilities-not-presented` | Assigned-user browser; independent Tester | R and approved synthetic W for journey actions |
| SMK-22 | `no-azure-provisioning-path`; `no-migration-execution-path`; `no-direct-discovery-api-path`; `no-ai-path`; `no-multi-cloud-path`; `no-external-customer-access-path` | Independent review workstation plus read-only configuration evidence; independent Tester | R |

## 4. Practical implementation matrix

Every attachment named below is a **real result from the bound execution**, sanitized before publication. A source test, fixture, screenshot mock, proposed JSON or locally generated `PASS` is not an attachment substitute.

| ID | Existing reusable implementation (partial unless stated) | Missing producer and real sanitized inputs/attachments | Owner / independent review | Dependencies and decisions |
|---|---|---|---|---|
| SMK-01 | Runner HTTP-to-HTTPS assertion; `Test-AzureDemoSmokeHttp.ps1`; orchestration/redaction fixtures. | External TLS producer tests the exact resolved staging web host with the approved minimum and one lower protocol. Attach protocol/result matrix, redirect status/location tuple and bounded TLS failure category; no packet capture containing session material. | Developer implements; Platform runs; Tester reviews; InfoSec confirms protocol method. | Approved TLS minimum and external hosted job; no Azure credential. |
| SMK-04 | Optional runner denial branch and exact target resolver; Bicep public-network contracts. Current pipeline supplies no `ApiPublicUri`. | External producer probes the Azure-resolved API hostname from the hosted network. Attach DNS result class, connection/status class, safe response-header inventory and zero-metadata inspection. | Developer implements; Tester and InfoSec independently review. | Decide whether “unreachable” or bounded `401/403/404` is the approved shape; target context must come from the deployment job. |
| SMK-05 | Private DNS/subnet/configuration assertions, `Assert/Test-AzureDemoPrivateDnsReconciliation.ps1`, App Service subnet tests and exact target resolver. | Private-pool producer resolves all four FQDNs, proves private address/route and performs allowed/denied data-plane calls. Attach sanitized DNS answers, exact resource/role fingerprints, status matrix and principal object IDs; never secret values or Blob contents. | Developer implements; Network/Platform supplies execution authority; Tester reviews. | Network/DNS approval; authoritative approved/unapproved identity matrix; read permissions on exact resources. |
| SMK-06 | Entra/PKCE component contract, identity unit tests and no-persistent-token source checks. | Parent-run manual browser Test Run executes real assigned and unassigned-user cases. Attach sanitized screenshots, storage-key-name inventory, redacted claims table (`tid/aud/azp/scp`, no token or subject/name), sign-in correlation and safe network outcome table. | Tester owns procedure/result; Identity and InfoSec specialist review; Quality reviews independence. | Named synthetic-role workforce accounts, Test Plans licence/API decision, redirect/assignment/CA approval. |
| SMK-07 | `IdentityAuthorizationTests`, `SqlInventoryAuthorizationTests` and API integration authorization coverage. | Private-pool token-negative producer calls the deployed path with approved non-secret generated invalid-token fixtures. Attach case/status/header matrix and token-fixture metadata/hash only; never JWTs. | Developer implements; Tester/InfoSec review. | Identity owner approves safe token-fixture generation and expected `401/403` distinctions. |
| SMK-08 | Runner compares only `X-Lgr-Test-Principal` and `X-Roles`; source-boundary test holds the broader prohibited-header inventory; integration tests cover authority semantics. | Producer enumerates the approved complete header set in anonymous and assigned contexts, compares status/body-shape/authority semantics and queries telemetry for marker absence. Attach case matrix, semantic hashes and zero-match redaction query with marker hash. | Developer implements; Tester/InfoSec review. | Approve canonical header inventory and telemetry-reader query; do not log raw marker values. |
| SMK-09 | SQL/import/dependency integration tests provide broad project-scope coverage. | Browser Test Run proves assigned project success plus foreign/unassigned non-enumerating denial on representative deployed routes. Attach sanitized screenshots, route/status/content-shape matrix, response hashes and synthetic project IDs. | Tester owns and executes; Quality reviews, with InfoSec sampling IDOR evidence. | Approved synthetic memberships and project fixture; browser assignment. |
| SMK-12 | Healthy readiness gate, readiness unit tests, bounded five-second dependency behaviour and static alert contracts. | Protected fault job temporarily removes only the staging API UAMI's container-scoped Blob data role, records live/ready/web timeline, alert/trace, restores the exact assignment and proves stable `200` recovery. Attach approval/change reference, before/after role-assignment fingerprints, statuses, correlation/alert IDs and restoration proof. | Developer implements; Platform/Operations executes; Tester and InfoSec review. | **Proposed method, not approved.** Requires exact role-assignment identity, RBAC write/delete permission, exclusive lock, recovery trap and Platform/TDA/InfoSec approval. If propagation is not deterministic, TDA must choose another slot-only fault. |
| SMK-13 | Database-principal contract and tests; migration identity/target guards; API journeys prove normal DML paths; stale SQL assurance is partial only. | Repaired SQL producer runs exact-target reconciliation under separated identities. Real runtime DML is correlated through the API; DBA-approved effective-user transaction proves bounded DDL/user creation denial and no residue; migration grant inventory is compared with reviewed contract. Attach sanitized SQL result JSON, transaction/correlation IDs, permission matrix and object/principal absence check. | Developer/Tester implement test assets within role boundaries; DBA executes/approves; independent Tester reviews; TDA reviews privilege model. | Bounded SQL repair in 2.4; exact DB; DBA decision on `EXECUTE AS USER`; no free-form SQL; synthetic transaction only. |
| SMK-14 | Bicep/RBAC/configuration and discovery storage integration tests. | Private producer proves runtime reads without returning the membership secret/file contents; anonymous/unapproved data-plane requests prove denial; browser/API route proves cross-project denial. Attach status/resource-scope matrix, object-name/hash metadata and role fingerprints. | Developer implements automation; Platform executes; Tester/InfoSec review. | Identify a permitted negative-test context without granting new data rights; approve exact synthetic object; Key Vault/Storage log access. |
| SMK-15 | EF bundle/manifest generation and validators, migration identity/target guards, seed artifact contract, startup migration boundaries and stale SQL assurance migration list. | Reconciliation producer compares exact immutable migration manifest to history, required schema/constraints, exact seed manifest counts/checksum, and telemetry interval for absence of startup migrate/seed. Attach migration IDs, schema assertion results, counts/checksum and zero-event telemetry query. | Developer/Tester implement assets; DBA executes/reviews database output; independent Tester reviews full result. | SQL repair; immutable migration/seed manifests; approved schema assertion list and telemetry access. |
| SMK-16 | Extensive import unit/integration tests, approved synthetic fixtures, storage mode and malware/alert static contracts. | Browser Test Run uploads the approved synthetic file and bounded malformed/oversized/wrong-type fixtures through the real route, waits for actual scan result, verifies preview/path/audit and retains synthetic records. Attach input hashes, scan status/ID, path shape, preview counts, rejection matrix and audit correlation; no row bodies. | Tester owns execution; Developer supplies automation/fixtures; InfoSec reviews scan/abuse cases; Quality reviews. | Test Services approves files/size limits; Defender result availability; synthetic tenant/project; cleanup/retention decision that preserves audit. |
| SMK-17 | OpenTelemetry/W3C and redaction configuration plus health/security tests. | One browser journey emits a known safe correlation; monitoring producer queries browser/web/API/SQL spans and absence of prohibited fields. Attach sanitized span graph (IDs, operation, status, duration only) and zero-match redaction queries. | Tester initiates; Operations queries; Tester/InfoSec review; Quality checks chain. | Log query permission, agreed time window and redaction query; no HAR/token export. |
| SMK-18 | `Test-AzureDemoMonitoringAlerts.ps1`, Bicep alert inventory/routing and cap contract. | Reuse the approved SMK-12 incident as the synthetic alert where possible; monitoring operator proves fired/resolved delivery and acknowledges it, then reads sampling/retention/cap state. Attach rule/action-group resource fingerprints, fired/resolved times, delivery result/acknowledgement identity and config snapshot without recipient address. | Developer implements collection; Operations executes/acknowledges; Tester and Service Transition review. | Monitoring owner, notification test permission and retention/cap decision; do not send a second alert merely for duplicate evidence. |
| SMK-19 | Rollback target guard, pipeline ordering tests, staging warm-up/readiness and protected swap/swap-back stages. | Existing-contract route requires real distinct prior commit/manifest, deployment record, compatibility review, unhealthy-candidate method, swap-back operation IDs and before/after artifact fingerprints. | Developer implements producer; Platform/Operations executes; DBA/TDA/Tester review; Quality gates. | Unresolved first-release decision in section 6; rehearsal approval and exact slot-swap rights. |
| SMK-21 | `ApiJourneyTests`, browser capability integration tests and Vitest SQL/dependency/component journey contracts. | Assigned independent Tester executes J-01-J-09 in Chrome and Edge against one deployment/seed, including applicable keyboard/focus/reflow/contrast checks. Attach Test Run results, sanitized screenshots/accessibility output, record hashes and per-journey correlations. | Tester owns procedure/execution; Quality reviews; Product samples boundary narration. | Browser matrix, named assignments, immutable seed ID and reset/sequence policy; controlled synthetic writes only. |
| SMK-22 | `Test-AzureDemoSourceBoundaries.ps1`, deployment-boundary unit tests, package/SBOM/configuration contracts. | Independent Tester inspects deployed routes/UI, extracted exact ZIP inventories, sanitized App Service configuration fingerprint, packages/SBOMs and available credentials/permissions. Attach absence matrix, route/config/package inventories and sanitized screenshots. | Tester owns independent inspection; Quality and InfoSec review. | Read-only artifact/config access; complete route inventory; repair SMK-20 extracted-package evidence may be reused but not double-counted. |

## 5. Proposed same-run evidence submission and collection design

### 5.1 Existing versus proposed resources

Repository-declared **existing inputs** (existence and current permission are not independently confirmed by this plan):

- the `mtp-azure-demo-deploy` pipeline shape in `azure-pipelines.yml`;
- Microsoft-hosted `ubuntu-latest` validation jobs;
- private pool name `mdp-mtp-dev-uks-001`;
- protected environment name `mtp-azure-demo-dev`;
- deployment service connection name `sc-mtp-azure-demo-dev`;
- migration WIF service connection name `sc-mtp-azure-demo-migration-dev-v2`;
- immutable artifact `azure-demo-immutable` and current deployment/readiness/smoke publications;
- exact target variables, resolver, deployment-manifest validation, staging content verification and readiness gate; and
- Azure DevOps pipeline artifacts and manual validation already used by the pipeline.

**Proposed resources/capabilities** that do not currently exist in the repository and must not be described as operational:

- protected producer jobs for external, private-network, SQL/storage/monitoring and rehearsal evidence;
- one Azure DevOps manual Test Plan/suite/run for assigned-user browser results, created and bound by the parent release run;
- an evidence aggregation/normalization script and collection-manifest validator;
- Azure DevOps Build Service permissions for current-run artifacts and Test Run/result/attachment APIs;
- approved negative-test context for data-plane denials;
- approved fault-injection and first-release/prior-release rehearsal procedures; and
- governed retention/lock configuration for raw and normalized evidence.

No artifact store, service connection, resource ID, Test Plan ID, user ID or permission is asserted to exist beyond the repository-declared names above. Owners must record real IDs only after authorization and discovery through the protected system.

### 5.2 One concrete flow

The recommended design uses Azure DevOps as the submission boundary and keeps every accepted byte in the same parent release run:

1. **Deployment context producer (existing stage, extended later).** After immutable staging deployment, content verification and stable readiness, a private-pool task publishes `target-context.json`. It contains the exact source commit, deployment-manifest file/hash and member hashes, infrastructure deployment ID, migration/seed manifest hashes, staging deployment evidence hashes, exact resource IDs/hosts/slot and deployment-completed UTC. It contains no credentials.
2. **External producer job.** A Microsoft-hosted job downloads only the current run's target context and executes SMK-01/04 without an Azure service connection. Its network perspective is derived from the hosted job timeline/pool metadata, not a JSON claim.
3. **Private producer jobs.** Jobs on the current private pool run the SMK-05/07/08 probes and specialist SQL, storage and monitoring procedures. Distinct Azure DevOps tasks use only their approved service connection/identity. Runtime and migration SQL evidence is never produced by one substituted principal.
4. **Assigned-user browser Test Run.** The parent pipeline creates a manual Azure DevOps Test Run bound to the current Build ID, commit, deployment ID, target-context hash and a pipeline-generated nonce, with test points assigned to the named Tester. The pipeline pauses at a Manual Validation step. The Tester completes SMK-06/09/16/17/21 and the UI portion of SMK-22 in supported browsers and uploads sanitized attachments to that Test Run. This is how browser evidence enters the same release run; the later ingestion job copies the exact Test Run results/attachments into a current-run immutable raw artifact.
5. **Specialist observed evidence.** DBA/Operations acknowledgements that cannot be safely automated are separate assigned Test Run results, not edits to producer JSON. Automated job output and specialist observation must agree; disagreement fails the assertion.
6. **Attempt selection and aggregation.** A private, read-only aggregation job queries the current run's timeline/artifact metadata and the exact Test Run IDs created for the current stage attempt. It selects attempts under 5.5, verifies every byte under 5.4, normalizes successful assertions into the current `SMK-xx.json` contract, records failed/incomplete submissions separately and publishes one immutable bundle.
7. **Full smoke validation.** A new stage downloads only the selected bundle from the current run and invokes the existing runner with `-ProtectedEvidenceDirectory`. This occurs before independent evidence review and the existing release approval. Missing/rejected evidence remains a failure.
8. **Independent review.** Tester signs off the actual exact-run results; Quality verifies the complete chain. The existing human Release Approval may start only after full smoke and these independent reviews pass. Slot swap remains later and human-controlled.

This requires a later pipeline restructure: move the current full smoke invocation out of `MigrateAndDeploySlots`; insert producer, manual intake, aggregation, full smoke and independent-review stages; then make `ReleaseApproval` depend on the successful review. The readiness gate remains immediately after deployment and before producers. This document does not make that change.

Staging evidence cannot be reused after swap because the current contract binds the slot and resolved hosts. The present post-swap call also omits a protected bundle and will remain red. Before full release implementation, Product/TDA must approve either a separately defined production-target read-only verification catalogue or new production-target protected records. The recommendation is a distinct post-swap read-only verifier: repeat transport, identity denial, project isolation, headers, approved reads, reconciliation, trace, artifact/configuration and prohibited-capability inspection; do not automatically repeat staging fault injection, SQL privilege mutation, uploads, alert delivery, rollback rehearsal or all write journeys. That recommendation is not implemented and cannot narrow the existing acceptance criteria without exact-commit Product/TDA approval.

### 5.3 Authentication and authorization of producers

| Producer | Authentication source | Minimum proposed authorization |
|---|---|---|
| External probes | Azure DevOps hosted job identity/timeline for the current run; anonymous target access | Read current target-context artifact and publish its own attempt artifact; no Azure service connection or secrets. |
| Private probes | Current private agent job plus approved federated deployment identity | Read exact resource/config/network metadata and logs required by the assigned checks; no subscription-wide access, RBAC mutation or secret-value read. |
| Browser Tester | Azure DevOps user identity assigned to the pipeline-created Test Run plus Entra assigned workforce account | Update only assigned Test Run results/attachments; access only the synthetic demo projects and routes granted for the test. |
| SQL migration reconciliation | Existing migration WIF identity for its reviewed rights; separate DBA/effective-runtime context for runtime permission negatives | Connect only to exact server/database through private path; execute reviewed scripts only. No generic SQL shell input. |
| Storage/Key Vault | Staging runtime identity through the app for allowed reads; anonymous/unapproved context for denials | Exact membership secret read and import-container object scope without returning content; no Key Vault administration or broad storage list. |
| Monitoring | Named monitoring operator and protected job identity | Read exact App Insights/Log Analytics/alert configuration and test outcome; only the approved test-notification/fault action may write. |
| Fault injection | Separately approved Operations identity under exclusive environment lock | Remove and restore only the exact staging UAMI/import-container role assignment, if TDA approves this method. No production identity or network mutation. |
| Rehearsal | Named human-approved release operator in protected environment | Warm-up and swap/swap-back on the exact two demo apps/slots only; no direct-main deployment, database rollback or resource deletion. |

Required deployment/security decisions still outstanding include real pool and service-connection permissions; Test Run API permissions/licensing; log-query permissions; exact DBA capability; the negative-test principal/context; the slot-only fault method and recovery permission; alert test permission; exact slot-swap permission; attachment malware/DLP controls; retention; and owner identities. Existing broad rights must not be assumed merely because deployment currently succeeds.

### 5.4 Trusted origin, release binding and attachments

`producerId` inside submitted JSON remains informational. The aggregator must derive and record trusted origin from Azure DevOps and Entra metadata:

- organisation/project and pipeline definition ID/name;
- parent run ID, source branch and exact 40-character source commit;
- stage, job and numeric stage/job attempt;
- agent pool/perspective and job identity;
- service-connection resource identifier plus authenticated client/object/tenant identifiers returned by the protected task, where applicable;
- environment/check/approval history references;
- Test Plan/Test Run/result/attachment IDs and Azure DevOps assigned/updated-by identities for browser/specialist submissions; and
- raw artifact ID/name, creation time and SHA-256 manifest.

The normalized collection manifest must additionally bind every assertion to:

- exact deployment-manifest file/hash and all artifact member hashes;
- infrastructure deployment ID and staging deployment/content-verification evidence hashes;
- exact subscription, resource group, apps, slot, resource IDs and Azure-resolved hosts;
- migration and seed manifest hashes/results;
- deployment-completed UTC and assertion execution interval; and
- raw attachment path, size, allowed media type and lowercase SHA-256.

The aggregator accepts only attachments under `attachments/<SMK-id>/<assertion-id>/`, rejects absolute/traversing paths, links/reparse points, unexpected executable/archive types, duplicates, unknown files and configured size/count excesses, and performs the approved malware/DLP scan. Browser evidence must exclude HAR files, tokens, cookies, local/session-storage values, personal data and unrestricted logs. Secret reads are evidenced by status, version/resource fingerprint and hash metadata only.

An implementation change is required so the evidence validator requires the trusted collection manifest/receipt mapping and no longer treats a non-empty submitted `producerId` as proof of identity. Local contract fixtures must cover substituted producer metadata, artifact IDs, attempts, Test Runs, timestamps and attachments.

### 5.5 Duplicate submissions, retries and stale-evidence rejection

Raw artifacts use immutable names that include producer key, parent Build ID, stage attempt and job attempt, for example the pattern:

`azdemo-protected-raw-<producer>-run<BuildId>-s<StageAttempt>-j<JobAttempt>`

The final bundle name additionally contains the selected aggregation attempt and collection-manifest hash prefix. Browser attachment names include the current Test Run/result/attachment ID; they are copied into the raw artifact without overwriting earlier bytes. Constant artifact names are not used for proposed producer output.

Selection is fail-closed:

1. Consider only artifacts and Test Runs whose protected-system metadata belongs to the current parent run and current producer-stage attempt.
2. For each producer key, identify the numerically highest stage/job attempt recorded by the Azure DevOps timeline and require that exact attempt to be terminal and successful. Never fall back to an older successful attempt after a later failed, cancelled or incomplete retry.
3. Reject two artifacts for the same producer/job/attempt, two completed Test Runs for the same current binding, or any ambiguous assertion owner.
4. Retain superseded attempts for audit but never merge their assertions with the selected attempt.
5. Require every selected execution to start after the bound staging deployment-completed time and finish before aggregation.
6. Revalidate exact commit, manifest, deployment, target, seed and attachment hashes. A successful prior run, stage attempt, slot or deployment is stale and rejected.
7. Publish `attempt-selection.json` with the selected and superseded IDs/hashes. The full-smoke job downloads the exact final artifact name/hash from that selection, not a wildcard or “latest” artifact.

### 5.6 Failure, publication, containment and retention

Every producer writes a bounded `PASS`, `FAIL` or `INCOMPLETE` raw result and publishes it with `always()` after an attempt marker. The aggregator never fills a missing assertion, re-labels failure, or combines partial success across attempts. A check receives a contract-valid `SMK-xx.json` only when all exact assertions pass from compatible selected evidence. Failed/incomplete results remain under `failures/`; the full runner therefore reports missing or rejected protected evidence and blocks downstream stages. Publication failure is itself a gate failure.

The final bundle contains raw manifests, normalized records, sanitized attachments, attempt selection and aggregation summary. It excludes credentials and unrestricted logs. The recommended retention is to mark the exact release run retained through Quality/human disposition and retain raw/normalized evidence for 90 days after the restricted demo expiry; retain only the governance record and manifest hashes thereafter according to enterprise records policy. Data Protection/records ownership must approve or replace that period before implementation.

## 6. SMK-19 first-release decision - unresolved

The current contract is unambiguous: SMK-19 requires a distinct prior deployed source commit, prior deployment-artifact manifest file/hash, protected deployment evidence reference, rehearsal approval reference and successful swap-back to that compatible release. A Git branch, an old build, the current staging artifact, a future post-swap result or an empty production slot does not establish that prior release.

### Route A - staging-only demonstration, production release blocked

**Recommended immediate disposition.** Execute staging-safe evidence collection for the other checks, publish a full runner result with SMK-19 failed/incomplete, keep `ReleaseApproval` and `SwapAndVerify` blocked, and label the result `STAGING_DEMO_VERIFICATION_ONLY`. This can provide useful management-demo confidence while preserving the gate. It is not Tester `PASS`, Quality release approval or a production release pass.

### Route B - explicitly approved first-release recovery contract

This route does not exist today and is **not recommended without material governance change**. Product/PRB could decide that the first release may recover to a documented “not released/unavailable” main-slot state rather than a compatible prior application. TDA, InfoSec, Platform/Operations, DBA, Service Transition and the human release authority would then have to approve the availability and operational consequence.

Implementation would require all of the following before use:

- **Acceptance changes:** amend Product AC-11, AC-18, AC-19 and SMK-19 and the Architecture/Environment rollback text at one exact approved package commit. Define the first-release pre-state, bounded outage outcome, access freeze, database compatibility and evidence required. It must not be described as restoration of a compatible prior release.
- **Validator changes:** introduce a versioned, mutually exclusive `prior-compatible-release` versus `first-release-not-released` schema. The first-release object would require exact pre-state content/config fingerprints, an approval/change reference, distinct rehearsal operation IDs and proof that the pre-state was restored. It must reject an empty object, the current artifact presented as prior, or use after a genuine compatible release exists.
- **Pipeline changes:** add an explicit parameter that defaults off, a protected pre-release rehearsal with separate human approval, frozen demo access, exact pre-state capture, unhealthy-candidate warm-up rejection, controlled swap/swap-back, restoration verification and unconditional recovery trap. The ordinary release gate remains later; the rehearsal cannot silently authorize release.
- **Test changes:** positive/negative contract fixtures; pipeline order/target/attempt tests; failure-at-each-operation recovery tests; and an independently witnessed connected rehearsal.
- **Documentation changes:** Product, Architecture, Environment, smoke README, implementation/test packs, Quality gate, operator runbook and incident/availability wording.

Until those changes and exact-commit approvals exist, the current validator must continue to reject first-release evidence.

### Route C - existing prior-release rehearsal

If Platform/Operations locates genuine protected deployment evidence, use the current route unchanged. The prior commit and manifest must be distinct from the candidate, the manifest file/hash must agree with the prior deployment record, compatibility must be DBA/TDA reviewed, and a separately approved rehearsal must prove unhealthy candidate rejection, no direct-main deployment and swap-back to that exact prior release. This is the preferred full-release route.

## 7. Sequenced work list

### 7.1 Documentation and decisions

1. Product/TDA decide the exact SMK-03 “hashed” meaning and record any acceptance clarification/change.
2. TDA/Test Services/InfoSec/Azure DevOps/Platform approve this producer topology, assertion ownership, Test Run intake, origin trust, retry selection, attachment controls and retention.
3. DBA/TDA approve the bounded SQL repair and separated-identity procedure.
4. Platform/TDA/InfoSec approve or replace the proposed staging Blob-role fault; Operations/Service Transition approve alert delivery/acknowledgement.
5. Product/PRB and technical/operational owners select SMK-19 Route A, B or C. No default converts it to pass.

### 7.2 Producer implementation

6. Developer adds raw-result schemas and external/private/security producers with local fixtures.
7. Tester adds browser/specialist Test Run procedures, sanitization checklist and exact requirements-to-test mapping.
8. Developer/Tester/DBA implement the bounded SQL assurance repair and local no-database parser/target tests.
9. Developer adds storage/monitoring/fault/rehearsal producers only after their decisions; add SMK-03/11/20 bounded repairs as separately scoped work.

### 7.3 Ingestion and contract

10. Implement Test Run bootstrap/intake, Azure DevOps metadata receipts, containment/hash manifest, attempt selection and normalization.
11. Version the protected evidence validator to require the collection manifest/receipt and trusted derived identity.
12. Restructure pipeline ordering to readiness -> producers/manual intake -> aggregation -> full smoke -> independent review -> Release Approval -> swap.

### 7.4 Local tests

13. Add positive and substitution/duplicate/stale/retry/failure/redaction fixtures for every producer, aggregator and validator rule.
14. Run existing smoke HTTP/orchestration/evidence, readiness, pipeline-structure, target, deployment, security, rollback, migration, package and SQL static regressions without connected calls.

### 7.5 Connected CI

15. Run build/IaC/package and all local producer/contract tests on Linux; publish fixture evidence only as test output, never protected evidence.
16. Validate Azure DevOps artifact/Test Run permissions and retry behavior in an isolated non-release run using synthetic attachments.

### 7.6 Authorized staging execution

17. After named approvals, deploy the exact candidate to staging, pass readiness, execute external/private/browser/specialist checks and the approved fault/alert procedure, restore all mutated state and aggregate the same-run bundle.
18. Run full smoke with the bundle. Preserve failures and stop before release approval if any check is missing/rejected/failed.

### 7.7 Independent release review

19. Tester reviews actual exact-run evidence and issues the appropriate outcome; Quality independently verifies the complete chain.
20. Only Route C, or a fully approved and implemented Route B, can satisfy SMK-19 for release. The human release authority remains the final gate; no autonomous swap follows this plan.

### Minimum useful staging-demo verification

The minimum useful increment is decisions 1-5, trusted ingestion 10-12, local/connected validation 13-16, and authorized staging execution for external probes, private probes, assigned-user browser journeys, read-only SQL/seed reconciliation, storage denials and telemetry. Controlled synthetic import writes may be included. Fault injection, alert delivery and SQL permission negatives require their extra approvals. With SMK-19 unresolved, publish an incomplete full-smoke result and `STAGING_DEMO_VERIFICATION_ONLY`; do not enter `ReleaseApproval` or swap.

### Additional work for full release acceptance

Full release requires every assertion for all 17 protected checks, completion of the SMK-03/11/20 gaps, approved fault/alert and SQL negative procedures, genuine SMK-19 Route C evidence or formally changed Route B, independent Tester `PASS`, Quality recommendation, all named human decisions and the unchanged protected release gate. Staging-demo verification is not a full release pass.

## 8. Decision table

| Decision | Recommendation | Responsible role | Required approval evidence |
|---|---|---|---|
| SMK-03 asset meaning | Define it as a build-generated asset proven against immutable build metadata/package, or add an explicit approved hash rule; do not claim current filename validation. | Product Owner + Architect/TDA | Exact-commit Product/TDA decision and updated test condition. |
| Evidence transport | Use same-parent-run Azure DevOps artifacts plus pipeline-created Test Runs for manual browser/specialist results. | Azure DevOps/repository owner + Architect | Permission/licence record, threat review, protected pipeline PR and TDA/InfoSec approval. |
| Producer identity | Derive identity from pipeline/Test Run/service-connection metadata and require receipt mapping; never trust submitted `producerId`. | Architect + InfoSec | Approved schema/threat model and validator/negative-test evidence. |
| Retry selection | Unique run/stage/job-attempt artifact names; the latest attempt itself must succeed, with no fallback to older success; reject ambiguity/stale evidence. | Architect + Azure DevOps owner | Pipeline design review and retry/duplicate test evidence. |
| Post-swap validation | Add an exact production-target read-only verifier only after Product/TDA approve its catalogue; never reuse staging records or rerun hazardous staging actions automatically. | Product Owner + Architect/TDA + Tester | Updated acceptance, validator/pipeline tests and exact-target post-swap evidence requirements. |
| SQL assurance | Repair exact target and manifest binding; use separated identities and bounded synthetic transaction/denial tests. | Azure SQL/DBA + Architect/TDA | Reviewed SQL, identity/grant matrix, local tests and connected execution approval. |
| Staging fault | Prefer exact staging-UAMI/import-container role removal/restoration under exclusive lock, subject to propagation trial and approval. | Platform/Operations + Architect/TDA + InfoSec | Change/recovery procedure, exact role-assignment fingerprint, permissions and witnessed rehearsal. |
| Retention | Retain exact run through disposition and evidence bytes for 90 days after demo expiry, then keep governance record/hashes per policy. | Data Protection/records owner + Quality | Recorded policy decision, retention lock and deletion responsibility. |
| SMK-19 | Use Route A now; use Route C for full release if real prior deployment evidence exists. Route B requires material reapproval. | Product Owner/PRB + TDA + Platform/Operations | Exact-commit decision, prior deployment/rehearsal evidence or fully approved first-release contract. |

## 9. Remaining blockers and hand-off

Remaining blockers are: no approved producer/ingestion topology; no trusted-origin validator; no browser Test Run intake; no connected external/private/specialist producers; stale and partial SQL assurance; unapproved fault/alert methods and permissions; partial SMK-03/11/20 automation; no decided retention; no genuine compatible prior deployed release; and no approved first-release recovery contract.

```yaml
handoff:
  from_agent: "architect"
  to_agent: "product-owner"
  state: "BLOCKED_ARCHITECTURE_DECISION"
  work_item: "AZURE-DEMO-001"
  branch: "fix/mtp-azure-demo-reconciliation"
  commit: "b08c2afdf2b42765b1d8936f5a1f531a4d210042"
  traceability:
    product_version: "0.1"
    phase: "Phase 1 - MVP"
    capabilities: ["C-01", "C-02", "C-11"]
    functional_requirements: ["F-01", "F-02", "F-03", "F-13", "F-14", "F-15"]
    non_functional_requirements: ["NF-01", "NF-02", "NF-03", "NF-04", "NF-05", "NF-06", "NF-07", "NF-09", "NF-10", "NF-11", "NF-12", "NF-13"]
    risks: ["R-01", "R-02", "R-09", "R-11"]
    assumptions: ["A-11", "A-12", "A-13", "A-18"]
    dependencies: ["D-02", "D-03", "D-04", "D-05", "D-06", "D-11", "D-13"]
    issues: ["I-03", "I-06", "I-08"]
    open_questions: ["Q-06", "Q-08", "Q-09"]
    approvals: []
  artefacts:
    - "docs/implementation/AZURE_DEMO_Smoke_Evidence_Coverage.md"
  evidence:
    - "Current pipeline, smoke catalogue, runner, protected contract and README reconciled."
    - "All 17 protected checks mapped to exact assertions, producers, perspectives, attachments, effects, owners and decisions."
    - "SMK-19 remains unresolved and no PASS/approval was created."
  decisions:
    - "Recommend same-run Azure DevOps artifact/Test Run collection with trusted system-derived producer identity."
    - "Recommend staging-only verification while SMK-19 remains blocked."
  assumptions: []
  risks:
    - "Material identity, pipeline, fault, SQL and first-release decisions are not yet approved."
  defects: []
  blockers:
    - "Protected producer/ingestion and permissions are unapproved and unimplemented."
    - "No genuine compatible prior release or approved first-release recovery contract exists for SMK-19."
  approvals: []
  requested_action: "Product/PRB and the named technical, security, platform, test, database, DevOps and service owners must decide the entries in section 8 before implementation or connected execution."
```
