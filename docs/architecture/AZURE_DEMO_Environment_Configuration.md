# Restricted Azure Management Demo - Environment Configuration

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
  approvals:
    - "Product/PRB authority opathre APPROVED exact package commit b8800e1eda014eef1421a1af5427aaea41393496 on 2026-09-29."
    - "Independent TDA PTArchitect APPROVED exact package commit b8800e1eda014eef1421a1af5427aaea41393496 on 2026-09-29."
    - "Information Security ashish50thbirthday-ship-it APPROVED exact package commit b8800e1eda014eef1421a1af5427aaea41393496 on 2026-09-29."
    - "Test Services nextgenexamprep-crypto APPROVED exact package commit b8800e1eda014eef1421a1af5427aaea41393496 on 2026-09-29."
```

## Purpose and status

This document is the configuration contract for Product Work Package `AZURE-DEMO-001` and architecture package `AZURE-DEMO-ARCH-001` at application baseline `6f4b9bb352dd7d2506bc4c3eb1c5b0a4ae1f40de` and exact package commit `b8800e1eda014eef1421a1af5427aaea41393496`. The Product Work Package supplies the authoritative restricted scope, nine journeys, exclusions, acceptance criteria and synthetic-data boundary. This document specifies intended values and validation rules; it is not evidence that any Azure, Entra, SQL or Azure DevOps resource exists. No Azure or SQL access was performed during preparation or approval reconciliation.

The configuration is `READY_FOR_AZURE_DEMO_IMPLEMENTATION_WITH_PLATFORM_GATE_PENDING`. Four valid exact-commit approvals authorise controlled implementation and local/isolated testing only. Azure Platform/Operations is `PENDING_PRE_DEPLOYMENT`; no Azure resource provisioning, external reachability, pipeline deployment or use of `Onkar.Pathre` is authorised until an identified assigned platform engineer records approval.

## Environment identity

| Setting | Required value |
|---|---|
| Environment code | `azdemo` |
| ASP.NET environment | `AzureDemo` |
| Resource group | Existing `Onkar.Pathre`; never create, rename or delete it from this deployment |
| Azure region | `uksouth` |
| Paired/recovery region | Not deployed for this demo; UK West remains a future production decision |
| Data | Synthetic demonstration data only |
| Access | Named internal Agilisys workforce-tenant users only |
| Availability | No production SLA; one App Service worker and one S0 database |
| Expiry | Required ISO date parameter and resource tag |
| Product boundary | Management, planning and evidence only; never execution or Azure target provisioning |

Globally unique names require a short approved suffix derived without exposing subscription or tenant IDs. Recommended pattern:

| Resource | Pattern |
|---|---|
| App Service plan | `asp-lgrtm-azdemo-uks-01` |
| Web app | `app-lgrtm-web-azdemo-uks-<suffix>` |
| API app | `app-lgrtm-api-azdemo-uks-<suffix>` |
| SQL server | `sql-lgrtm-azdemo-uks-<suffix>` |
| SQL database | `sqldb-lgrtm-azdemo` |
| Key Vault | `kvlgrtmazd<suffix>`; validate the Key Vault length/character constraint |
| Storage account | `stlgrtmazd<suffix>`; lowercase alphanumeric only |
| Log Analytics | `log-lgrtm-azdemo-uks-01` |
| Application Insights | `appi-lgrtm-azdemo-uks-01` |
| VNet | Existing `vnet-mtp-dev-uks-001` (`10.50.0.0/16`) |
| Integration subnet | Existing `snet-appservice` (`10.50.1.0/24`), delegated only to `Microsoft.Web/serverFarms` |
| Private endpoint subnet | Existing `snet-private-endpoints` (`10.50.2.0/24`) |
| Runtime identities | `id-lgrtm-api-azdemo`, `id-lgrtm-api-staging-azdemo`; private deployment/migration-agent identity is separately named and owned by Azure Platform/Operations |

## Bicep parameter contract

No secrets may be supplied as Bicep parameters or emitted as outputs.

| Parameter | Type | Rule/example |
|---|---|---|
| `environmentName` | string | Exact `azdemo` |
| `location` | string | Exact `uksouth`; allow-list approved UK regions only |
| `workloadName` | string | `lgrtm` |
| `uniqueSuffix` | secure operational input, not a secret | Short lowercase deterministic suffix; do not derive from personal data |
| `resourceGroupName` | string | Exact `Onkar.Pathre`; validation only because deployment scope is already the RG |
| `owner` | string | Named team/mailbox, not an individual secret |
| `costCentre` | string | Approved finance code |
| `expiryDate` | string | ISO `YYYY-MM-DD`; must be future dated |
| `appServiceSku` | string | Exact `S1`; a Premium requirement is a material package change and blocks this deployment pending re-cost/reapproval |
| `appServiceCapacity` | int | `1` |
| `webLinuxFxVersion` | string | Exact `NODE|24-lts`; fail preflight if unavailable |
| `apiLinuxFxVersion` | string | Exact `DOTNETCORE|10.0`; fail preflight if unavailable |
| `sqlSkuName` | string | `S0` |
| `sqlMaxSizeBytes` | int | `10737418240` (10 GiB); no silent size/tier expansion |
| `logRetentionDays` | int | `30` initially |
| `telemetryDailyCapGb` | number | Small approved cap, for example `0.25`; final value owned by operations |
| `entraTenantId` | string | Agilisys workforce tenant GUID; non-secret |
| `spaClientId` | string | Azure-demo SPA application/client GUID; non-secret |
| `apiClientId` | string | Azure-demo API application/client GUID; non-secret |
| `apiAudience` | string | Exact API audience, normally `api://<apiClientId>` |
| `apiScope` | string | Exact delegated scope `<apiAudience>/lgr.access` |
| `sqlEntraAdminObjectId` | string | Approved group object ID; no individual admin |
| `sqlEntraAdminName` | string | Approved group display name |
| `alertRecipientId` | string | Approved action-group receiver parameter; avoid personal addresses in source |
| `allowedDeploymentPrincipalIds` | array | Approved federated pipeline and bootstrap principals only |
| `deployBudget` | bool | `false` in RG template; subscription-level budget is separate |

Required Bicep outputs are resource IDs, hostnames, slot hostnames, identity principal/client IDs, SQL FQDN/database name, private DNS zone IDs, App Insights resource ID and artifact deployment targets. Mark values secure when there is any doubt. Never output Key Vault secret values, connection strings, access tokens or deployment credentials.

## App Service platform configuration

### Shared Linux plan

| Property | Value |
|---|---|
| SKU | Standard S1 minimum |
| OS | Linux |
| Workers | 1 |
| Zone redundancy | Off for demo |
| Autoscale | Off |
| Per-site scaling | Off |
| Apps | Web main/`staging`; API main/`staging` |
| Web runtime | Native App Service `NODE|24-lts`; no container |
| API runtime | Native App Service `DOTNETCORE|10.0`; no container |

### Settings required on every site and slot

| Platform property | Value |
|---|---|
| HTTPS only | Enabled |
| Minimum inbound TLS | At least `1.2` |
| SCM minimum TLS | At least `1.2` |
| FTPS | Disabled |
| HTTP/2 | Enabled after smoke testing |
| Always On | Enabled |
| Remote debugging | Disabled |
| Basic auth for SCM/deployment | Disabled |
| Health check | Web `/health`; API `/health/ready` |
| Client certificate | Not required for demo; do not enable without a design change |
| Public network | Web enabled; API disabled after private endpoints are approved |
| VNet integration | Integration subnet for both sites and slots |
| Route All | Enabled where required for private Key Vault/Storage resolution; prove Entra/telemetry egress still works |

Deployment slots have independent TLS/private-endpoint configuration. Do not assume cloning or swap transfers these controls.

## Web application settings

`NEXT_PUBLIC_*` settings are embedded at build time by Next.js. They are public identifiers and must be provided to the build stage as non-secret pipeline variables. A runtime setting with the same name does not repair an already built bundle. Build one artifact specifically for this single Azure-demo environment, or implement a reviewed runtime public-configuration endpoint before attempting multi-environment promotion.

| Name | Required value/source | Secret | Slot-sticky | Notes |
|---|---|---:|---:|---|
| `NODE_ENV` | `production` | No | No | Build and runtime. |
| `HOSTNAME` | `0.0.0.0` | No | No | Standalone server bind address. |
| `PORT` | Supplied by App Service | No | No | Do not hard-code. |
| `API_ORIGIN` | `https://<api-app>.azurewebsites.net` or slot equivalent | No | Yes | Server-only private destination. Never prefix `NEXT_PUBLIC_`. |
| `NEXT_PUBLIC_ENTRA_TENANT_ID` | Approved workforce tenant GUID | No | Build-time | Public identifier. |
| `NEXT_PUBLIC_ENTRA_CLIENT_ID` | Azure-demo SPA client GUID | No | Build-time | Public identifier. |
| `NEXT_PUBLIC_API_SCOPE` | `api://<api-client-id>/lgr.access` | No | Build-time | Exact delegated scope. |
| `NEXT_PUBLIC_DEMO_LABEL` | `Restricted synthetic non-production demo` | No | Build-time | Must be visible in the UI. |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | Bicep resource value | No credential, but protect config | Yes | Use only with configured telemetry SDK/agent; no web Key Vault access. |
| `OTEL_SERVICE_NAME` | `lgrtm-web-azdemo` / slot-specific suffix | No | Yes | Distinguishes slots. |
| `WEBSITE_HEALTHCHECK_MAXPINGFAILURES` | Approved value, normally `3` | No | No | Avoid aggressive recycle loops. |
| `WEBSITE_SWAP_WARMUP_PING_PATH` | `/health` | No | Yes | Must return 200 only when API path is ready. |
| `WEBSITE_SWAP_WARMUP_PING_STATUSES` | `200` | No | Yes | Fail swap warm-up otherwise. |
| `SCM_DO_BUILD_DURING_DEPLOYMENT` | `false` | No | No | CI supplies a ready-to-run standalone ZIP; no Oryx/platform build. |

Forbidden web settings and build variables:

```text
NEXT_PUBLIC_API_BASE_URL          # direct public API path is removed
NEXT_PUBLIC_LGR_TEST_PRINCIPAL
LGR_TEST_PRINCIPAL
Authentication__Mode=LocalTest
any client secret, access token, SQL password or Key Vault secret value
```

The production artifact startup command is `node server.js` from the standalone artifact root. Do not use `npm run dev`, `next dev` or `next start` against the standalone artifact.

## API application settings

Array settings use standard ASP.NET double-underscore/index notation.

| Name | Required value/source | Secret | Slot-sticky | Notes |
|---|---|---:|---:|---|
| `ASPNETCORE_ENVIRONMENT` | Exact `AzureDemo` | No | Yes | Never `Development`, `Testing` or `LocalTest`. |
| `ASPNETCORE_URLS` | Allow App Service to manage, or approved `http://+:8080` | No | No | Do not bind a public custom port. |
| `ASPNETCORE_FORWARDEDHEADERS_ENABLED` | `true` | No | No | Required on Linux App Service; application ordering still must be tested. |
| `AllowedHosts__0` | API main hostname | No | Yes | Add slot hostname on slot only if needed. |
| `AllowedOrigins__0` | Exact web main HTTPS origin | No | Yes | Defence only; normal browser path is same-origin. |
| `AllowedOrigins__1` | Exact web staging HTTPS origin on staging/API if approved | No | Yes | No wildcard or trailing slash. |
| `Authentication__Mode` | `Entra` | No | Yes | Startup must fail otherwise. |
| `Authentication__Entra__TenantId` | Approved workforce tenant GUID | No | Yes | Exact GUID. |
| `Authentication__Entra__Issuer` | `https://login.microsoftonline.com/<tenant-guid>/v2.0` | No | Yes | Exact HTTPS v2 issuer. |
| `Authentication__Entra__Audience` | `api://<api-client-id>` | No | Yes | Must match access token audience. |
| `Authentication__Entra__AllowedClientIds__0` | Azure-demo SPA client GUID | No | Yes | No broad/wildcard client acceptance. |
| `Authentication__EntraDemoMemberships__SecretUri` | Versionless `https://<vault>.vault.azure.net/secrets/entra-demo-memberships` URI | No | Yes | API reads directly with its slot UAMI; the JSON value is never an app setting. |
| `Authentication__EntraDemoMemberships__CacheSeconds` | Maximum `300` | No | Yes | Fail closed after the last valid cache interval; disable/expiry is evaluated per request. |
| `AzureIdentity__ManagedIdentityClientId` | Exact API-main or API-staging UAMI client ID | No | Yes | AzureDemo code constructs the user-assigned managed-identity credential explicitly; no developer-credential fallback. |
| `ConnectionStrings__LgrDatabase` | Passwordless encrypted Azure SQL connection string | No password; protect setting | Yes | Use the slot's UAMI client ID. |
| `Features__SqlDiscoveryAssessment` | `true` | No | Yes | Required only after journey evidence passes. |
| `Features__SqlDiscoveryImport` | `true` | No | Yes | Requires Blob/scan control. |
| `Features__SqlAssessment` | `true` | No | Yes | Human planning only. |
| `Features__SqlBrowserJourneys` | `true` | No | Yes | Requires RBAC evidence. |
| `Features__DependencyRegister` | `true` | No | Yes | Requires independent test evidence. |
| `DiscoveryImport__MaximumFileSizeBytes` | `26214400` or lower approved limit | No | Yes | Retain bounded upload. |
| `DiscoveryImport__StorageMode` | `AzureBlob` | No | Yes | Local file mode must fail startup in Azure. |
| `DiscoveryImport__StorageAccountUri` | `https://<account>.blob.core.windows.net` | No | Yes | Private DNS path. |
| `DiscoveryImport__ContainerName` | `discovery-imports` | No | Yes | Private container. |
| `DiscoveryImport__FreshnessThresholdDays` | `30` | No | Yes | Existing behaviour. |
| `DemoData__Enabled` | `false` at API runtime | No | Yes | Pipeline seeder overrides explicitly; startup never seeds. |
| `DemoData__ManifestVersion` | Approved manifest version | No | Yes | Read-only verification endpoint may expose version, not contents. |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | Application Insights connection string | No credential, but protect config | Yes | Prefer Bicep reference; never log. |
| `OTEL_SERVICE_NAME` | `lgrtm-api-azdemo` / slot-specific suffix | No | Yes | Distinguishes slots. |
| `Logging__LogLevel__Default` | `Information` | No | Yes | No Debug/Trace in deployed demo. |
| `Logging__LogLevel__Microsoft.AspNetCore` | `Warning` | No | Yes | Preserve auth/security events via explicit categories. |
| `WEBSITE_SWAP_WARMUP_PING_PATH` | `/health/ready` | No | Yes | Readiness, not liveness. |
| `WEBSITE_SWAP_WARMUP_PING_STATUSES` | `200` | No | Yes | Block swap on dependencies. |
| `SCM_DO_BUILD_DURING_DEPLOYMENT` | `false` | No | No | CI supplies a ready-to-run .NET publish ZIP. |

Passwordless UAMI connection-string pattern:

```text
Server=tcp:<server>.database.windows.net,1433;Database=<database>;Encrypt=True;TrustServerCertificate=False;Authentication=Active Directory Managed Identity;User Id=<uami-client-id>;Connect Timeout=30;MultipleActiveResultSets=False
```

Validate the exact Microsoft.Data.SqlClient version and syntax in the implementation test lane. Do not add `User ID`/`Password`, `TrustServerCertificate=True`, SQL authentication or a public fallback.

Forbidden API settings/files:

```text
Authentication__Mode=LocalTest
ASPNETCORE_ENVIRONMENT=Development
ASPNETCORE_ENVIRONMENT=Testing
appsettings.LocalTest.json in publish output
DiscoveryImport__StorageMode=Local
ConnectionStrings__LgrDatabase containing Password= or TrustServerCertificate=True
any X-Lgr-Test-Principal/default synthetic alias setting
```

## Key Vault configuration

| Item | Configuration |
|---|---|
| SKU | Standard |
| Authorisation | Azure RBAC only |
| Soft delete | Enabled |
| Purge protection | Enabled |
| Public network access | Disabled after private endpoint and DNS validation |
| Deployment/template access | Do not enable legacy template/VM/disk access unless separately justified |
| Runtime role | `Key Vault Secrets User` for the exact API-main and API-staging UAMIs only; no web access |
| Administrator | Named human/PIM group outside application identities |
| Diagnostics | Audit events to Log Analytics with redaction/retention policy |

Expected secrets are deliberately few:

| Secret name | Content | Owner/rotation |
|---|---|---|
| `entra-demo-memberships` | Versioned JSON mapping validated Entra `tid`/named-user `oid` to the synthetic project and approved roles | Identity/Product owner; rotate on membership change; no group IDs, email or display name |

The API reads this secret through the Key Vault data plane with the slot's explicitly selected UAMI, validates schema/tenant/version/effective dates, caches it for no more than five minutes and fails closed when no valid document is available. Emergency revocation disables Entra assignment, publishes a disabled/expired membership version and invokes the approved refresh/restart procedure. The API and SPA need no client secret. SQL is passwordless. The Application Insights connection string is routing configuration, not an authentication secret; handle it as protected configuration but do not claim it authenticates ingestion.

## Entra application configuration

### SPA registration

- Supported account type: this organisational directory only.
- Platform: Single-page application.
- Redirect URIs: exact HTTPS web main URL, exact web staging URL, and the approved localhost URI for developer use. No wildcards.
- Logout URL: exact web route.
- Implicit grant: disabled.
- Public client/native flow: disabled unless Identity Platform explicitly requires it.
- API permission: delegated `lgr.access` only; admin consent according to tenant policy.
- Assignment required: enabled; assign only the approved demo group.
- No client secret or certificate.

### API registration

- Single tenant.
- Application ID URI: exact approved audience.
- Delegated scope: `lgr.access`.
- Pre-authorized client: exact SPA client ID.
- App roles/service credentials: none for this browser-only demo; `Lgr.Api.Service` remains unused.
- Token version: v2.

### Conditional Access

MFA and the normal Agilisys device/location/risk policy apply. No policy exception may be created merely for the demo. Break-glass accounts do not receive application project membership.

## Demo membership document

The interim document must be schema validated and versioned. For this restricted demo it lists exact named user object IDs only; Entra group assignment may control coarse app access, but no group claim or group object ID grants application project membership. Conceptual shape:

```json
{
  "schemaVersion": "1",
  "membershipVersion": "azdemo-YYYYMMDD-N",
  "tenantId": "<workforce-tenant-guid>",
  "principals": [
    {
      "objectId": "<approved-user-object-guid>",
      "status": "Active",
      "memberships": [
        {
          "customerId": "11111111-1111-1111-1111-111111111111",
          "projectId": "22222222-2222-2222-2222-222222222222",
          "validFromUtc": "<approved-utc>",
          "validUntilUtc": "<demo-expiry-utc>",
          "roles": ["ReviewerAuditor"]
        }
      ]
    }
  ]
}
```

This is not LocalTest: identity comes only from a cryptographically validated Entra access token. Group claims and role headers are not membership authority. Any future server-side group expansion is a material design change requiring reapproval. Cache entries include membership version and expire quickly. Removal/disable must revoke access within the accepted demo interval.

## Azure SQL configuration

| Control | Required configuration |
|---|---|
| Logical server region | UK South |
| Database tier | Standard S0 initially |
| Authentication | Microsoft Entra-only |
| Entra administrator | Approved group, not an individual |
| SQL login/admin password | No application use; disable SQL authentication where platform support permits |
| Public network access | Disabled |
| Firewall | No `0.0.0.0`, no broad corporate range and no `Allow Azure services`; private endpoint only |
| Private DNS | `privatelink.database.windows.net` linked to demo VNet |
| Encryption | Platform TDE; TLS with certificate validation from clients |
| Audit/diagnostics | Approved categories to Log Analytics; no query parameter/payload logging |
| Backup | Azure automated PITR; retention set and restore tested before demo acceptance |
| Geo/zone redundancy | Not selected for demo; no production resilience claim |

Database principals:

- API main UAMI and API staging UAMI: minimum application DML/execute permissions. Neither receives `db_owner`, `db_ddladmin` or permission to create users.
- Migration-agent managed identity: reviewed DDL permissions sufficient for EF bundle; no data export or cross-database rights. Prefer time-bounded grant.
- Seed runner: either the migration identity for the explicit seed stage or a separate narrow principal; no startup seeding.
- Human DBA group: PIM/JIT according to enterprise controls; all bootstrap actions evidenced.

The first `CREATE USER ... FROM EXTERNAL PROVIDER` and grants require an approved Entra-admin bootstrap operation. Bicep cannot safely infer database-contained permissions merely from Azure RBAC.

## Storage configuration

| Control | Value |
|---|---|
| Account | StorageV2, Standard LRS, UK South |
| Secure transfer | Required |
| Minimum TLS | 1.2 |
| Public blob/container access | Disabled |
| Shared key access | Disabled where compatible with scanning controls |
| Public network access | Disabled |
| Access | Blob private endpoint/private DNS |
| Runtime role | `Storage Blob Data Contributor` scoped to import container |
| Object naming | Server-derived `<customer>/<project>/<batch>/<guid>.csv` |
| Retention | Short approved demo period; lifecycle deletion after expiry |
| Malware | Defender for Storage malware scanning or approved equivalent quarantine gate |
| Versioning/soft delete | Enable if cost/retention policy approves; never treat as a substitute for database audit |

No macro-enabled workbook, archive or executable type is accepted. Only the supported UTF-8 CSV contracts and pre-approved synthetic sample files may be used in the nine journeys.

## Network and DNS validation

Use the approved existing `vnet-mtp-dev-uks-001` (`10.50.0.0/16`) without changing its address space. Regional App Service VNet integration uses only the existing `snet-appservice` subnet (`10.50.1.0/24`), whose only service delegation is `Microsoft.Web/serverFarms`; private endpoints use only the separate existing `snet-private-endpoints` subnet (`10.50.2.0/24`). Do not create, rename, replace, resize or redelegate either subnet.

The required regional-integration topology is web production, web staging, API production and API staging all attached to `snet-appservice`. This is required because both web slots proxy to private API endpoints and both API slots need outbound private access to SQL, Key Vault and Blob Storage. A subnet response can contain provider-managed App Service `privateEndpoints` or `serviceAssociationLinks` metadata; that metadata is not evidence that a `Microsoft.Network/privateEndpoints` resource targets the integration subnet. Predeployment validation must enumerate actual private-endpoint resources independently and reject only an actual resource whose `subnet.id` is `snet-appservice`.

Required resolution from each site and slot:

| Name | Expected result |
|---|---|
| API main hostname | Private endpoint IP from the web main/slot |
| API staging hostname | Slot private endpoint IP from web staging |
| SQL server FQDN | SQL private endpoint IP from API main/slot and migration agent |
| Key Vault hostname | Vault private endpoint IP from API main/slot |
| Blob hostname | Blob private endpoint IP from API main/slot |

Negative tests from an ordinary internet host must prove API, SQL, Key Vault and Blob are not publicly reachable. Kudu/SCM deployment for a private API requires an approved private agent/DNS path; do not re-enable public access for convenience.

## Secure headers and CORS acceptance matrix

| Control | Web | API |
|---|---|---|
| HTTPS-only/TLS | Platform enforced | Platform enforced on private endpoint ingress |
| HSTS | Required on HTTPS responses | Required where meaningful; platform HTTPS remains mandatory |
| CSP | Enforced, nonce-based where required by Next.js/MSAL | `default-src 'none'; frame-ancestors 'none'` on non-HTML responses is acceptable |
| `X-Content-Type-Options` | `nosniff` | `nosniff` |
| `Referrer-Policy` | `no-referrer` | `no-referrer` |
| `Permissions-Policy` | Disable unused browser features | Not normally applicable but harmless |
| Frame protection | `frame-ancestors 'none'` and `X-Frame-Options: DENY` | Same |
| CORS | Not needed for same-origin browser calls | Exact approved web origin(s), methods and headers only; no wildcard/credentials |
| Host filtering | Exact web hostname(s) at platform/app | Exact API hostname(s) in ASP.NET `AllowedHosts` |
| Proxy headers | Web creates clean outbound set | Accept App Service forwarding configuration only; do not trust caller chain |

## Build artifact configuration

### Web artifact

The build job must:

1. select Node 24 and print the exact versions;
2. run `npm ci` from the lock file;
3. run full audit/security gates, lint and all component tests;
4. set only approved public build identifiers and `NODE_ENV=production`;
5. run the Next production build;
6. copy `.next/static` to `.next/standalone/.next/static` and `public` if it exists;
7. scan the artifact for `.env`, LocalTest configuration, synthetic aliases, tests and dev-only packages;
8. start `server.js` locally in CI and verify `/`, one deep route and one hashed static asset; and
9. ZIP the contents of `.next/standalone`, not the parent directory, so `server.js` is at package root.

The current lock resolves `@vitest/mocker` `4.1.10`; deployment is denied until the Developer updates Vitest to `4.1.11` or later compatible stable, regenerates the lock and proves tests/audit. Excluding dev dependencies from the runtime artifact does not waive the vulnerable CI/build-tool finding.

### API artifact

The build job must:

1. use the SDK pinned by `global.json` or an approved patch update;
2. restore locked dependencies and scan direct/transitive packages;
3. run Release build, unit/integration tests and the SQL Server assurance lane;
4. publish framework-dependent .NET 10 output;
5. exclude `appsettings.LocalTest.json`, tests, user secrets and local connection configuration;
6. produce an EF migration bundle and idempotent migration script separately from the application ZIP;
7. generate SBOMs/hashes and publish test/scan evidence; and
8. prove the application starts in `AzureDemo` only with complete Entra/private dependency configuration and fails closed otherwise.

### Slot deployment contract

- Build once and publish immutable, hashed `web.zip` and `api.zip`; deployment stages download those exact pipeline artifacts and never rebuild them.
- `web.zip` contains the contents of `.next/standalone` with `server.js` at ZIP root. `api.zip` contains the contents of the .NET publish directory with `LgrTransformationMigration.Api.dll` at ZIP root.
- Deploy with the approved Azure DevOps `AzureWebApp@1` task (or approved successor) using the workload-identity-federated Resource Manager connection, `appType: webAppLinux`, `deployToSlotOrASE: true`, `resourceGroupName: Onkar.Pathre`, `slotName: staging`, `deploymentMethod: zipDeploy` and the single exact artifact path.
- The web startup command is `node server.js`; the API uses the native .NET 10 startup contract. Set no container image, registry, Docker setting, publish profile, FTP credential, local-Git hook or direct-main deployment.
- `SCM_DO_BUILD_DURING_DEPLOYMENT=false`; Oryx remote build is not enabled. The VNet-connected private agent must reach private API/slot SCM endpoints without opening public access.
- Verify the downloaded SHA-256 against the signed/integrity-protected artifact manifest before deployment and record the deployment ID/hash after upload.

## Azure DevOps variables, service connections and environments

### Non-secret variable group

Suggested group `vg-lgrtm-azdemo-public`:

```text
azureLocation=uksouth
resourceGroupName=Onkar.Pathre
environmentName=azdemo
webAppName=<approved>
apiAppName=<approved>
webSlotName=staging
apiSlotName=staging
entraTenantId=<approved-guid>
spaClientId=<approved-guid>
apiClientId=<approved-guid>
apiAudience=api://<approved-guid>
apiScope=api://<approved-guid>/lgr.access
```

Do not put access tokens, client secrets, SQL passwords, membership JSON or publish profiles in variable groups.

### Service connections

- Resource Manager connection uses workload identity federation, scoped to the approved resource group or narrower. It cannot grant itself Owner/User Access Administrator.
- Private self-hosted deployment/migration agent uses a dedicated managed identity and resides in or can route to the demo VNet. Its Azure DevOps agent pool permits only the protected deployment stages.
- The pipeline does not read the membership JSON. The API runtime uses direct Key Vault SDK access with its UAMI; any separately approved bootstrap task may address only explicitly named secrets and must mask all output.

### Protected environments

| Environment | Purpose | Checks |
|---|---|---|
| `azure-demo-staging` | Deploy/migrate and test slots | Branch control, exclusive lock, TDA/InfoSec prerequisite evidence, DBA approval for migrations |
| `azure-demo` | Slot swap to the main demo URLs | Independent Tester PASS, Quality Manager recommendation, Product Owner scope confirmation, named human release approval |

## Deployment sequence

1. Confirm approved Product, Architecture and governance packages and record the exact commit/artifact hashes.
2. Verify `release/azure-demo-v1` protection and required checks; do not push directly.
3. Run PR validation and produce immutable web/API/migration/Bicep artifacts and SBOMs.
4. Query the supported App Service stacks in the approved subscription/region through the human-approved deployment workflow. Abort if Node 24 LTS or .NET 10 is unavailable; do not fall back to containers automatically.
5. Run Bicep lint/build/security scan and `what-if` against `Onkar.Pathre`; obtain approval.
6. Deploy/update network, monitoring, identities, App Service plan/sites/slots, Key Vault, SQL, Storage, private endpoints, DNS, diagnostics and alerts.
7. Complete the evidenced SQL Entra administrator/bootstrap grants.
8. Verify private DNS/connectivity from the deployment agent and sites without changing public-network controls.
9. Record the pre-migration schema state/PITR time; review and execute the EF bundle with the migration identity.
10. Execute the explicit AzureDemo seed stage and reconcile the manifest.
11. Deploy API artifact to `staging`; warm `/health/ready`; run API/identity/tenant smoke tests through the web staging path.
12. Deploy web artifact to `staging`; warm `/health`; verify login, proxy, deep links and static assets.
13. Run the complete post-deployment smoke suite and the nine demonstration journeys with synthetic data.
14. Obtain independent Test/Quality evidence and human approval.
15. Swap API staging to main, smoke; then web staging to main, smoke. Stop if either check fails.
16. Retain prior artifacts/slots through the rollback window and monitor alerts/logs/cost.
17. Record deployment, commit, Bicep deployment ID, migration set, seed version, tester evidence, approvals and expiry date.

## Rollback sequence

### Before slot swap

Stop. Do not alter main slots. Correct forward on a working branch, rebuild all evidence and redeploy staging.

### After slot swap, schema still backward compatible

1. Freeze demo mutations and record correlation/time.
2. Swap web back, then API back in the order validated by the compatibility matrix.
3. Run read-only smoke tests and controlled data-integrity checks.
4. Preserve failed artifacts/logs for diagnosis; do not erase evidence.

### Database incompatibility or corruption

1. Declare the demo unavailable and stop writes.
2. Do not run an ad-hoc EF `Down`, `DROP` or repair script.
3. Under DBA/human approval, restore the predeployment point to a new database.
4. Validate migration history, tenant constraints, seed checksum and representative journeys.
5. Grant the correct runtime identities, update only the approved slot-sticky passwordless connection setting and swap the compatible app version back.
6. Record the incident and invalidate downstream evidence.

## Environment shutdown and decommission

### Temporary shutdown outside an approved demo window

1. A named Azure Platform/Operations owner opens the change record, confirms no deployment/reset/migration is active, freezes application mutations and records health, schema/seed version, artifact hashes and the last audit/correlation evidence.
2. Disable assignment for the demo-user Entra group or otherwise close interactive access using the approved Identity Platform control; do not alter project roles to simulate shutdown.
3. Stop web and API main sites and both `staging` slots through the protected operations workflow. Keep SQL, Key Vault, Storage, private endpoints, monitoring and backups unchanged unless the approved retention plan says otherwise.
4. Confirm public web requests no longer serve the application, alerts show the expected planned state and the incident/on-call owner knows the maintenance window. Suppress only the documented maintenance alert path; do not disable audit or security monitoring.
5. Record that stopping sites does not stop App Service-plan or SQL charges. Cost reduction beyond this point is a separately approved scale/decommission decision.
6. To restart, restore Entra assignment, start API then web, run SMK-01 through SMK-20 plus a representative read-only check from every journey, verify alerts/cost/expiry, and obtain the named operations stop/go decision before the booked demonstration.

### Final decommission

1. Product/PRB and Azure Platform/Operations approve the retention, evidence-export, expiry and deletion scope; Data Protection/DPO and Information Security confirm that no hold or investigation blocks deletion.
2. Preserve only approved non-secret governance evidence, artifact manifests, audit extracts and cost/incident records in the authorised evidence location. Do not export tokens, secrets, uploaded row data or membership JSON.
3. Remove demo-user assignments and expire the server-side membership document; stop all sites/slots and freeze the database.
4. Produce an approved Bicep/Resource Graph inventory of resources tagged `environment=azure-demo` and reconcile it to the package deployment manifest. The existing `Onkar.Pathre` resource group and unrelated resources are never deletion targets.
5. Use a protected human-approved platform workflow to delete only the reconciled Azure-demo resources and role assignments in dependency-safe order. No agent or application performs deletion; no wildcard/resource-group deletion is permitted.
6. Confirm private DNS records/endpoints, identities/RBAC, SQL server/database, Key Vault, Storage, App Services/plan, monitoring rules and budget entries are either deleted or intentionally retained with a named owner and expiry. Purge protection and backup/soft-delete retention remain governed by policy and are not bypassed.
7. Record final cost state, retained-resource exceptions, deletion evidence and closure approvals. Any future demo is a new deployment/evidence chain, not a restart of the approved package.

## Synthetic data seeding contract

The deployed seed must contain enough fictional data for the nine journeys without implying live migration execution:

- one Demo Council customer and one primary synthetic project;
- approved named internal user object IDs mapped server-side to synthetic application roles;
- at least five applications and ten servers, including ready and blocked examples;
- SQL instances/databases and assessments with fictional hostnames/data only;
- supported dependency references and dependencies sufficient to create/edit, confirm/unconfirm and logically archive under the Slice 1 contract; no validation finding is seeded;
- migration decisions in draft/review/approved-like record states without autonomous approval;
- fictional IP records covering only the existing states and duplicate-active demonstration without claiming completed subnet validation or production concurrency assurance;
- flat Azure target-build planning records clearly marked fictional and planning-only;
- existing wave memberships and fixed readiness examples with no dependency-derived blocker or new approval transition;
- existing draft runbook/tasks plus dashboard and available audit records; no completed rollback artefact or external-execution tracking is seeded; and
- one pre-approved synthetic discovery CSV and expected preview/commit reconciliation counts.

The existing seed currently contains several of these records but is not by itself acceptance evidence. The implementation must inventory and fill only the missing fictional records through the reviewed seed manifest, without changing the product model or adding excluded behaviour.

The reset operation is a protected pipeline stage, never a browser/API capability. It requires a change/deployment record and named DBA/operations approval, freezes demo access, restores the approved clean Azure SQL point to a new database or uses a separately reviewed deterministic synthetic-only reset bundle, deletes only Blob objects enumerated by the prior synthetic manifest, reapplies the exact seed, reconciles migrations/counts/checksums, rotates the reset evidence identifier and reruns mandatory smoke tests before access is restored. It refuses any environment other than `AzureDemo`; ad hoc `DELETE`, `DROP`, EF `Down`, broad container deletion and startup reset/seeding are prohibited.

## Post-deployment smoke tests

Every test records UTC time, commit, artifact hash, site/slot, correlation/trace ID, tester identity and result without storing tokens or personal data.

| ID | Test | Expected result |
|---|---|---|
| SMK-01 | Request web HTTP URL | Redirect to HTTPS; TLS below minimum rejected. |
| SMK-02 | Request web `/health` and a deep route | `200`; deep route renders after direct navigation. |
| SMK-03 | Request a hashed `/_next/static/` JS/CSS asset | `200`, correct MIME/cache headers, non-empty content. |
| SMK-04 | Request API public hostname from internet | Not reachable/denied; no API metadata disclosed. |
| SMK-05 | Resolve/call API, SQL, Key Vault and Blob from allowed paths | Private addresses used; dependencies available only to authorised identities. |
| SMK-06 | Sign in as assigned internal user | PKCE succeeds; correct tenant/audience/scope; no token in URL/local storage/log. |
| SMK-07 | Missing, expired, wrong-tenant, wrong-audience and disallowed-client token | Safe `401/403`; no fallback; `WWW-Authenticate` on 401. |
| SMK-08 | Send `X-Lgr-Test-Principal` and all prohibited identity headers | No authentication/role/customer effect; safe security event; header value not logged. |
| SMK-09 | Select an authorised synthetic project then a foreign/unassigned project | Authorised succeeds; foreign returns non-enumerating denial with no counts/ETag/existence leak. |
| SMK-10 | Call API through an unapproved Origin/method/header | CORS/preflight denied; normal same-origin proxy works. |
| SMK-11 | Inspect web/API response headers | HSTS, CSP/frame protection, nosniff, referrer and permissions policies match contract. |
| SMK-12 | Check API live/ready and simulate a safe dependency outage in staging | Live remains process-only; ready/web health become `503`; alert/trace fires without details. |
| SMK-13 | Query DB identity/permissions using approved validation | Runtime DML succeeds; DDL/user creation denied; migration identity follows reviewed rights. |
| SMK-14 | Read approved Key Vault/Blob objects and attempt unapproved scope | Required access succeeds; administration/cross-container/public access denied. |
| SMK-15 | Validate `__EFMigrationsHistory` and seed manifest | Exact expected migrations, counts and checksum; no startup migration/seed. |
| SMK-16 | Upload approved synthetic CSV plus malformed/oversized/wrong-type samples | Approved file scans/previews; invalid files fail safely; tenant path/audit correct. |
| SMK-17 | Trace one page-to-API-to-SQL request | Same trace/correlation visible in web/API/dependency telemetry; no payload/token/secret present. |
| SMK-18 | Validate App Insights alerts and daily cap | Synthetic health failure reaches named owner; cap/sampling configured. |
| SMK-19 | Exercise slot warm-up and planned swap-back in a rehearsal | No direct main deployment; health gates block bad slot; swap-back restores previous version. |
| SMK-20 | Scan deployed artifacts/configuration | Patched `@vitest/mocker`; no LocalTest file/alias, dev dependency, `.env`, password or publish profile. |
| SMK-21 | Execute J-01 through J-09 against the same seed/deployment | All nine journeys pass without invoking, labelling or implying an excluded capability. |
| SMK-22 | Inspect routes, credentials, packages, configuration and UI for prohibited capability | No Azure provisioning, migration execution, direct discovery API, AI, multi-cloud or external-customer access path exists. |

## Nine key demonstration journeys

Each journey is a management demonstration. It must never trigger Azure provisioning or workload migration.

### J-01 - Entra sign-in and project-scoped session

An assigned internal user signs in with MFA, selects the synthetic project and views capabilities. A read-only user sees fewer actions than an authorised editor. Attempting an unassigned project returns a non-enumerating denial. Evidence: token metadata (redacted), capabilities response, role-based UI and audit/trace ID.

### J-02 - Governed server discovery import

An authorised synthetic Discovery Analyst uploads the approved fictional server CSV. The platform scans/quarantines, applies the existing validation and previews create/update/unchanged/warning/reject counts before an explicit commit or cancel. The existing duplicate/invalid sample behaviour and history are shown. No direct discovery API or new import format is used. Evidence: scan result, batch checksum/counts, explicit actor and audit correlation.

### J-03 - Application and server Master Inventory

The user searches/paginates fictional applications and servers, opens existing relationships and observes that import changes only fields governed by the existing reconciliation contract. A cross-project direct ID request is denied without data or count leakage. Evidence: before/after DTOs and audit history without real data.

### J-04 - SQL inventory and assessment records

The Database SME browses fictional SQL instances/databases and updates the existing human-owned assessment/planning record. A read-only reviewer cannot mutate and a stale write receives the existing safe concurrency response. The UI states that these records execute nothing. Evidence: permission matrix, ETag/concurrency response, audit actor/correlation.

### J-05 - Phase 4 Slice 1 dependency register

The Migration Architect creates a supported fictional dependency or controlled named reference, views it on the existing bounded surfaces, edits it, confirms/unconfirms it and logically archives it. Duplicate, self, invalid and cross-project relationships are rejected; a reviewer can view but not mutate. No graph validation, cycle/missing finding or wave impact is run or claimed. Evidence: permission/concurrency results and significant-change audit event.

### J-06 - Migration decision and Azure target planning record

The user records an existing fictional migration decision and flat Azure target-build planning record with rationale/status. The demonstration explicitly shows that this is a planning record only; no versioned design hierarchy, ARM/Bicep/customer subscription action, provisioning endpoint or credential is available from the application. Evidence: stored record and negative route/credential inspection.

### J-07 - Existing IP record lifecycle

The user exercises only the implemented fictional IP record states and existing duplicate-active protection. The narration states that the product records planning data, does not configure Azure networking, does not replace enterprise IPAM and does not claim completed subnet validation or production concurrency assurance. Evidence: existing state transition/conflict response and audit event.

### J-08 - Existing wave and fixed readiness view

The user places supported fictional workloads into an existing wave and views the current fixed readiness result/checks. Any displayed blocker comes only from rules already implemented at the baseline. No dependency validation, dependency-derived blocker, database wave membership, automatic movement or approval action is demonstrated. Evidence: wave membership and current readiness result.

### J-09 - Draft runbook, dashboard and audit boundary

The user opens the existing draft runbook/task foundation and programme dashboard, updates an allowed draft task and views available significant-change audit evidence. The artefact remains a draft and is not represented as technically approved without the responsible SME. Separate rollback-plan completion, workload-aware generation and external-execution tracking are excluded; there is no migration-execution control or service credential. Evidence: draft/task status, dashboard/audit view and negative route/credential inspection.

## Demo acceptance and negative assertions

Acceptance requires all nine journeys plus proof that the application cannot:

- provision or modify Azure resources;
- call Azure Migrate/discovery APIs;
- execute server/database/file/application/DNS/firewall migration;
- grant itself tenant/project membership;
- accept LocalTest aliases or caller-supplied customer/role/permission headers;
- access data outside the authorised synthetic project;
- enable AI or multi-cloud behaviour; or
- represent the demo as production, customer-licensed or approved for real customer data.

## Cost configuration and operating controls

| Control | Configuration/owner |
|---|---|
| App Service | One S1 worker; no autoscale; quarterly runtime review and before each demo release |
| SQL | S0; alerts before any scale-up; no elastic pool until production tenancy is decided |
| Logs | 30 days, sampling, small daily cap, no Debug; review dropped telemetry after cap |
| Storage | Small LRS capacity, lifecycle deletion, no redundant copies of uploads |
| Private endpoints | Five planned; remove only through approved environment decommission |
| Budget | Subscription-level monthly budget with 50/75/90/100% notifications |
| Tags | Owner, cost centre, environment, synthetic classification, expiry date |
| Review | Weekly during active demo; monthly otherwise |
| Expiry | Named owner chooses renew or controlled decommission; no autonomous deletion |

The working estimate is roughly £100-£210 per month before enterprise discounts, Defender/scanning, alert notifications and any new agent capacity. The Product Owner/PRB must reconcile Q-02 before treating it as a commitment.

## Deployment-readiness and evidence record

Before the first slot deployment, the protected environment check must consume one manifest for the same exact package/application commit. It records: the four implementation approvals; the separately mandatory `APPROVED` Azure Platform/Operations pre-deployment decision from an identified assigned platform engineer; pipeline/run ID; runtime/tool versions; immutable web/API/migration/Bicep hashes and SBOMs; all build/test/lint/SQL/EF/security/licence/IaC results; patched Vitest and clean connected npm audit; approved Bicep `what-if`; target resource group/region and runtime preflight; private-agent identity; migration history/PITR/compatibility/rollback target; seed/reset/sample-file versions and checksums; redacted configuration fingerprint; cost/expiry/operations owner; and Developer `READY_FOR_TEST` plus Tester entry evidence. Any mismatch blocks deployment.

The post-deployment record adds the infrastructure deployment ID, slot/site identities, deployed hashes, private DNS/connectivity validation, migration/seed outcome, SMK-01 through SMK-22, J-01 through J-09, trace/redaction and alert evidence, slot swap/swap-back rehearsal, defects, independent Tester decision, Quality recommendation and named human release decision. All evidence is immutable and attributable by UTC time and correlation/run ID; failed evidence is retained.

## Governance approval checklist

Checked architecture-entry items below are backed by durable PR #11 records for exact package commit `b8800e1eda014eef1421a1af5427aaea41393496`. An empty checkbox means the decision or evidence is absent and must not be inferred from this document or the user prompt. The referenced `docs/approvals/AZURE_DEMO_Architecture_Approval_Evidence.json` is absent from the exact package commit and current PR branch and is not relied upon.

### Architecture entry

- [x] The Product Work Package, Deployment Architecture and this Environment Configuration coexist at immutable package commit `b8800e1eda014eef1421a1af5427aaea41393496`; the four recognised decisions quote that SHA, reviewer role, date, scope, conditions and evidence link.
- [x] Product/PRB authority `opathre` approves the restricted scope for controlled implementation and independent testing only; this is not deployment, release or full-MVP approval. [Evidence](https://github.com/onkarpathre/lgr-transformation-migration/pull/11#pullrequestreview-5358896442)
- [x] Independent TDA `PTArchitect` approves `AZURE-DEMO-ARCH-001` for controlled implementation/testing only; material design changes require renewed review. [Evidence](https://github.com/onkarpathre/lgr-transformation-migration/pull/11#pullrequestreview-5358867878)
- [x] Information Security `ashish50thbirthday-ship-it` approves implementation/security testing of the documented controls only; LocalTest and `X-Lgr-Test-Principal` remain prohibited in Azure, and `@vitest/mocker` remediation plus successful clean connected audit remain mandatory before external reachability. [Evidence](https://github.com/onkarpathre/lgr-transformation-migration/pull/11#pullrequestreview-5358887229)
- [ ] Azure Platform/Operations is `PENDING_PRE_DEPLOYMENT`. An identified assigned platform engineer must approve `Onkar.Pathre`/UK South, Policy/quota/naming/tags, network/DNS, identities/RBAC, SQL/backup, private agent/protected pipeline, priced configuration, budget/alerts, operational owner, expiry and shutdown/decommission before any Azure-impacting action.
- [x] Test Services `nextgenexamprep-crypto` approves independent testing in authorised isolated resources with synthetic fixtures and commit-bound evidence. [Evidence](https://github.com/onkarpathre/lgr-transformation-migration/pull/11#pullrequestreview-5358878842)

Product/PRB clarified that the four checked authority decisions are sufficient for controlled implementation and local/isolated testing and that the unassigned Platform/Operations decision is a mandatory pre-deployment gate. [Governance clarification](https://github.com/onkarpathre/lgr-transformation-migration/pull/11#pullrequestreview-5358989846). No Azure Platform/Operations decision is recognised unless it comes from an identified assigned platform engineer.

Supporting evidence required before the relevant primary decision:

- [ ] Identity Platform owner approves app registrations, tenant, scope, assignments, MFA/Conditional Access and redirect/logout URIs.
- [ ] Data Protection/DPO records Q-06 applicability and acceptable internal identity/telemetry processing for this synthetic-only demo.
- [ ] Network/DNS owner approves subnets, endpoints, DNS and private agent connectivity.
- [ ] Azure SQL/DBA owner approves Entra admin, users/roles, S0, migration and PITR/restore.
- [ ] Azure DevOps/repository owner approves protected branch/environments, federated service connection, scans and private agent pool.

The four checked decisions authorise controlled implementation and local/isolated testing only. A supporting approval, earlier ADR, risk acceptance, branch name, draft hash or user prompt cannot replace the pending Azure Platform/Operations decision. Until an identified assigned platform engineer records that approval, Azure resource provisioning, external reachability, pipeline deployment and any use of `Onkar.Pathre` are prohibited.

### Deployment entry

- [ ] Identified assigned Azure Platform/Operations engineer records `APPROVED` for the exact pre-deployment scope and artefacts.
- [ ] `@vitest/mocker` advisory remediated and full same-commit scans pass.
- [ ] Developer Implementation Work Package is complete and `READY_FOR_TEST`.
- [ ] Independent Tester recommendation is `PASS` for the exact artifacts/environment.
- [ ] Quality Manager issues the exact-build recommendation.
- [ ] Information Security confirms external-reachability/security evidence.
- [ ] Managed Services/Service Transition names the restricted-demo alert/incident/cost/expiry owner.
- [ ] Product Owner confirms no scope drift and no customer-data use.
- [ ] Named human Azure-demo release authority approves deployment/swap.

### Demonstration entry

- [ ] All post-deployment smoke tests pass.
- [ ] All nine journeys pass with the approved synthetic manifest.
- [ ] Monitoring/alerts and rollback rehearsal are evidenced.
- [ ] Demo banner, expiry and audience restrictions are visible.
- [ ] No unresolved high/critical security issue, cross-tenant defect, data-loss risk or missing rollback remains.

## Configuration disposition

The Product Work Package provides the authoritative boundary and both architecture documents are reconciled to its exact nine journeys and exclusions at package commit `b8800e1eda014eef1421a1af5427aaea41393496`. Product/PRB, Independent TDA, Information Security and Test Services have validly approved controlled implementation and local/isolated testing. The target remains technically feasible with native Node.js 24 and .NET 10 App Service runtimes; custom containers are neither required nor approved. Azure Platform/Operations is `PENDING_PRE_DEPLOYMENT`: no Azure resource provisioning, external reachability, pipeline deployment or use of `Onkar.Pathre` is authorised. Required supporting evidence, application/IaC/pipeline controls, private agent, mandatory `@vitest/mocker` remediation and clean audit, independent Tester `PASS`, Quality Manager recommendation and named human deployment decision remain outstanding. Production, customer data, release, merge and full MVP approval remain excluded.

READY_FOR_AZURE_DEMO_IMPLEMENTATION_WITH_PLATFORM_GATE_PENDING
