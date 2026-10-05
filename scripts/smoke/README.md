# Azure demo smoke evidence runner

This runner implements the `SMK-01`–`SMK-22` catalogue from `AZURE_DEMO_Environment_Configuration.md`. It is inert unless `-Execute` is supplied. No smoke check was executed during implementation.

The protected pipeline resolves `defaultHostName` with Azure CLI for the exact approved subscription, tenant, resource group, web/API applications and staging slots through `sc-mtp-azure-demo-dev`. `Resolve-AzureDemoSmokeTargets.ps1` rejects nonzero commands, empty/malformed responses, wrong resource IDs and substituted hostnames. The runner then requires exact equality between its URI and the verified host; it does not use an `azurewebsites.net` wildcard. Staging and production identities cannot be interchanged.

HTTP checks log only check ID, scheme, hostname, path, HTTP status when available and a bounded exception category. They never log request headers, tokens, cookies, query strings, response bodies or unrestricted exception details. `SMK-01` still requests HTTP with PowerShell 7 `MaximumRedirection 0` and `SkipHttpErrorCheck`; only 301, 302, 307 or 308 to HTTPS on the same exact host/path passes the automated part.

Identity, private-network, SQL, Key Vault, Blob, telemetry, slot-swap, nine-journey and negative-capability checks require protected evidence records named `SMK-xx.json`. Hybrid checks `SMK-01`, `SMK-08` and `SMK-12` require both their automated result and protected evidence. `AzureDemoSmokeEvidenceContract.ps1` validates the approved acceptance assertions, exact source commit, deployment-manifest hash, infrastructure deployment ID, pipeline run, resolved subscription/resource/app/slot/host target, execution location and identity kind. Every assertion must reference an in-bundle sanitized attachment whose SHA-256 is verified; `status: PASS` alone is rejected. Fixture-labelled evidence, missing/malformed records, wrong commit/artifact/run, substituted targets and attachment changes fail closed.

`sql-bootstrap.json` is a durable DBA input for migration-principal grants and is delivered only to the database job. It is not smoke evidence and is never passed to, copied into or renamed for the smoke runner. The current approved architecture has no implemented ingestion source for the required protected runtime bundle, so the pipeline intentionally omits `-ProtectedEvidenceDirectory`; protected checks fail and block swap. The proposed source/delivery and independent-review amendment is documented in `docs/implementation/AZURE_DEMO_Smoke_Evidence_Coverage.md` and remains unapproved.

Every attempted run writes all 22 per-check records and `smoke-summary.json` before returning failure. Pipeline publication is conditioned on the smoke attempt marker rather than success, preserving sanitized failure evidence. A failed staging run prevents the release-approval and slot-swap stages.

The protected test procedures are:

- SMK-01: verify HTTP redirect and reject TLS below the approved minimum.
- SMK-02: request `/health` and a direct deep route.
- SMK-03: request a hashed Next JS/CSS asset and verify MIME/cache/non-empty content.
- SMK-04: prove the API public hostname is unreachable or denied without metadata from outside the authorised private network. A request from the Sweden managed pool is not this proof.
- SMK-05: from the Sweden managed pool, resolve API, SQL, Key Vault and Blob privately from each authorised path and deny other paths. This is not proof of public API denial.
- SMK-06: in a real assigned-user browser session, complete workforce-user authorization code with PKCE; prove tenant/audience/scope, assignment and token-storage rules. Static source tests are not this proof.
- SMK-07: test missing, expired, wrong-tenant, wrong-audience and disallowed-client access tokens, including `WWW-Authenticate` on 401.
- SMK-08: compare access with every prohibited identity header and inspect redacted security logging.
- SMK-09: compare authorised and foreign/unassigned project selectors for non-enumerating denial.
- SMK-10: send unapproved origin/method/header preflights and verify same-origin proxy operation.
- SMK-11: inspect HSTS, CSP/frame, nosniff, referrer and permissions headers.
- SMK-12: check live/ready, then use a separately approved staging dependency-failure simulation and verify 503/alert without details. A healthy read-only probe is not fault-injection evidence.
- SMK-13: separately prove runtime-identity DML plus DDL/user-creation denial and migration-identity rights against the reviewed grant. One identity cannot prove the other identity's privileges.
- SMK-14: read only approved membership/import objects and deny administration, cross-container and public access.
- SMK-15: compare `__EFMigrationsHistory`, migration manifest, synthetic counts and seed checksum; inspect startup telemetry for no migration/seed.
- SMK-16: upload the approved synthetic CSV plus malformed, oversized and wrong-type samples; verify scan, tenant object name and audit.
- SMK-17: correlate one web-to-API-to-SQL request and inspect telemetry for payload/token/secret absence.
- SMK-18: trigger the approved synthetic health alert and verify routing, sampling and daily cap.
- SMK-19: under the protected rehearsal change, prove warm-up blocks a bad slot and a human-approved swap-back restores the real previously deployed release. Its distinct source commit, deployment-manifest file/hash and deployment record are mandatory; current-release evidence is rejected. The runner itself never swaps slots.
- SMK-20: scan immutable deployed artifacts/configuration for patched dependencies and prohibited files/settings/credentials.
- SMK-21: Tester executes J-01–J-09 against one deployment and seed, recording per-journey correlation IDs.
- SMK-22: inspect routes, packages, credentials, configuration and UI for migration execution, Azure target provisioning, direct discovery API, AI, multi-cloud and external-customer access paths.
