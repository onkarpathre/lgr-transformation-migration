# Azure demo smoke evidence runner

This runner implements the `SMK-01`–`SMK-22` catalogue from `AZURE_DEMO_Environment_Configuration.md`. It is inert unless `-Execute` is supplied. No smoke check was executed during implementation.

HTTP checks run without printing headers or tokens. Identity, private-network, SQL, Key Vault, Blob, telemetry, slot-swap, nine-journey and negative-capability checks require protected evidence files named `SMK-xx.json`. Each evidence file must contain `status: PASS`, the exact `sourceCommit`, and the exact `artifactManifestSha256`; evidence from another build is rejected.

The protected test procedures are:

- SMK-01: verify HTTP redirect and reject TLS below the approved minimum.
- SMK-02: request `/health` and a direct deep route.
- SMK-03: request a hashed Next JS/CSS asset and verify MIME/cache/non-empty content.
- SMK-04: prove the API public hostname is unreachable or denied without metadata.
- SMK-05: resolve API, SQL, Key Vault and Blob privately from each authorised path and deny other paths.
- SMK-06: complete assigned-workforce-user authorization code with PKCE; prove tenant/audience/scope and token-storage rules.
- SMK-07: test missing, expired, wrong-tenant, wrong-audience and disallowed-client access tokens, including `WWW-Authenticate` on 401.
- SMK-08: compare access with every prohibited identity header and inspect redacted security logging.
- SMK-09: compare authorised and foreign/unassigned project selectors for non-enumerating denial.
- SMK-10: send unapproved origin/method/header preflights and verify same-origin proxy operation.
- SMK-11: inspect HSTS, CSP/frame, nosniff, referrer and permissions headers.
- SMK-12: check live/ready, then use the approved staging dependency-failure simulation and verify 503/alert without details.
- SMK-13: prove runtime DML and denial of DDL/user creation; compare migration identity rights to the reviewed grant.
- SMK-14: read only approved membership/import objects and deny administration, cross-container and public access.
- SMK-15: compare `__EFMigrationsHistory`, migration manifest, synthetic counts and seed checksum; inspect startup telemetry for no migration/seed.
- SMK-16: upload the approved synthetic CSV plus malformed, oversized and wrong-type samples; verify scan, tenant object name and audit.
- SMK-17: correlate one web-to-API-to-SQL request and inspect telemetry for payload/token/secret absence.
- SMK-18: trigger the approved synthetic health alert and verify routing, sampling and daily cap.
- SMK-19: under the protected rehearsal change, prove warm-up blocks a bad slot and a human-approved swap-back restores the prior artifacts. The runner itself never swaps slots.
- SMK-20: scan immutable deployed artifacts/configuration for patched dependencies and prohibited files/settings/credentials.
- SMK-21: Tester executes J-01–J-09 against one deployment and seed, recording per-journey correlation IDs.
- SMK-22: inspect routes, packages, credentials, configuration and UI for migration execution, Azure target provisioning, direct discovery API, AI, multi-cloud and external-customer access paths.
