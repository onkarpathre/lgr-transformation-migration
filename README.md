# LGR Transformation and Migration

LGR Transformation and Migration is a multi-tenant SaaS proof of concept for Local Government Reorganisation discovery, assessment, Azure design and migration delivery. It replaces disconnected workbooks with a governed journey from customer and project through inventory, decision, target, IP allocation, wave readiness and runbook.

## Phase 1 capability

The modular-monolith API and Next.js web application provide:

- customer/project context and tenant-isolated data access;
- application and server inventory with many-to-many relationships;
- migration decisions and Azure target builds;
- subnet/IP inventory with validated `Available -> Reserved -> Allocated -> Released` transitions;
- migration waves, asset associations and deterministic readiness;
- wave runbook generation and task status tracking;
- customer-aware dashboard and configurable lookup values;
- realistic fictional Demo Council development data.

The API uses immutable GUID primary keys, DTOs, asynchronous EF Core operations, Problem Details errors and OpenAPI/Swagger. SQL Server Express is the local database and the schema remains Azure SQL compatible.

## Phase 2 capability

Phase 2 adds Discovery Import and Inventory Reconciliation:

- Azure Migrate Server Report CSV upload, validation, JSON staging, preview and full Server reconciliation;
- Azure Migrate All Inventory CSV upload, staging and preview, with clearly identified server rows eligible for Server reconciliation;
- Create, Update, Unchanged, Warning and Reject classifications with field-level old/new differences;
- explicit transactional commit, protected migration/business fields, field-level audit events and repeat-commit prevention;
- SHA-256 duplicate warnings, persistent import history and customer/project isolation;
- append-only server discovery snapshots and configurable 30-day freshness status;
- local ignored file storage behind an Azure Blob-replaceable abstraction.

Upload never immediately updates Server Inventory. Canonical changes occur only after preview and explicit commit.

## Repository structure

```text
src/api                 ASP.NET Core 10 REST API, domain, services, EF Core
src/web                 Next.js 16 / React 19 web application
tests/api.unit          xUnit domain/service rule tests
tests/api.integration   xUnit isolated SQLite API integration tests
infra/bicep             Initial opt-in Azure monitoring foundation
docs/architecture       Architecture, data model and ADRs
docs/functional         POC scope and behaviours
samples/discovery       Fictional Azure Migrate demonstration CSV
```

## Prerequisites (Windows PowerShell)

Install .NET 10 SDK, Node.js 24 LTS (Node 20.9+ is supported by Next.js 16), npm and SQL Server Express. Then verify:

```powershell
dotnet --version
node --version
npm.cmd --version
Get-Service 'MSSQL$SQLEXPRESS'
Start-Service 'MSSQL$SQLEXPRESS'
```

If script execution policy blocks `npm.ps1`, use `npm.cmd` as shown throughout this README.

## Restore packages

From the repository root:

```powershell
dotnet restore .\LgrTransformationMigration.sln
Set-Location .\src\web
npm.cmd ci
Set-Location ..\..
```

## Configure the database connection

The checked-in development default uses Windows integrated authentication and contains no secret:

```text
Server=localhost\SQLEXPRESS;Database=LgrTransformationMigration;Trusted_Connection=True;TrustServerCertificate=True;
```

Override it for the current PowerShell session when required:

```powershell
$env:ConnectionStrings__LgrDatabase='Server=localhost\SQLEXPRESS;Database=LgrTransformationMigration;Trusted_Connection=True;TrustServerCertificate=True;'
```

Do not put passwords or tokens in checked-in configuration. Local-only values may be placed in an ignored `appsettings.Local.json` or environment variables.

## Create and apply EF Core migrations

The initial migration is checked in. Apply it with:

```powershell
dotnet tool restore
dotnet ef database update --project .\src\api\LgrTransformationMigration.Api.csproj --startup-project .\src\api\LgrTransformationMigration.Api.csproj
```

To create a later migration:

```powershell
dotnet ef migrations add DescriptiveMigrationName --project .\src\api\LgrTransformationMigration.Api.csproj --startup-project .\src\api\LgrTransformationMigration.Api.csproj --output-dir Infrastructure\Migrations
```

Phase 2 uses the checked-in `AddDiscoveryImport` migration. Apply it with the same `dotnet ef database update` command above; do not recreate `InitialCreate`.

## Run the API

```powershell
$env:ASPNETCORE_ENVIRONMENT='Development'
dotnet run --project .\src\api\LgrTransformationMigration.Api.csproj --urls 'http://localhost:5000'
```

Open Swagger at `http://localhost:5000/swagger`. Development requests default to Demo Council and its demo project. To select another context, send `X-Customer-Id` and `X-Project-Id`; these headers are the local replacement point for future Microsoft Entra ID claims.

## Run the frontend

In a second PowerShell window:

```powershell
Set-Location C:\Projects\lgr-transformation-migration\src\web
$env:NEXT_PUBLIC_API_BASE_URL='http://localhost:5000'
npm.cmd run dev
```

Open `http://localhost:3000`.

## Build and test

Build the API and test projects:

```powershell
Set-Location C:\Projects\lgr-transformation-migration
dotnet build .\LgrTransformationMigration.sln --configuration Release
```

Run all API tests (each integration test creates and disposes its own in-memory SQLite database):

```powershell
dotnet test .\LgrTransformationMigration.sln --configuration Release --no-build
```

Build and lint the frontend:

```powershell
Set-Location C:\Projects\lgr-transformation-migration\src\web
npm.cmd run lint
npm.cmd run build
```

The validated Phase 2 suite contains 32 unit tests and 23 integration tests: 55 passed, 0 failed. SQL Server remains the application provider; SQLite is used only by isolated integration tests.

## Demonstrate discovery import

Start the API and frontend, select the Demo Council context, then open **Discovery > Imports > New import**. Select **Azure Migrate Server Report** and upload:

```text
samples\discovery\azure-migrate-server-report-demo.csv
```

The first preview deliberately contains two Creates, two Updates, one Unchanged, one Warning and one Reject. Review the Update differences, then use **Commit import** and confirm. Server Inventory will show the new servers, current technical changes and Discovery History; migration/business fields remain unchanged.

The same flow can be run exactly from Windows PowerShell at the repository root. Keep the API running at `http://localhost:5000`:

```powershell
Set-Location C:\Projects\lgr-transformation-migration

$customerId = '11111111-1111-1111-1111-111111111111'
$projectId = '22222222-2222-2222-2222-222222222222'
$userName = 'phase2.demo@demo-council.example'
$apiHeaders = @{
    'X-Customer-Id' = $customerId
    'X-Project-Id' = $projectId
    'X-User-Name' = $userName
}

$uploadJson = curl.exe --silent --show-error --fail-with-body `
    --request POST 'http://localhost:5000/api/discovery/imports/upload' `
    --header "X-Customer-Id: $customerId" `
    --header "X-Project-Id: $projectId" `
    --header "X-User-Name: $userName" `
    --form 'SourceType=AzureMigrateServerReport' `
    --form 'File=@.\samples\discovery\azure-migrate-server-report-demo.csv;type=text/csv'
$batch = $uploadJson | ConvertFrom-Json

$preview = Invoke-RestMethod -Method Post `
    -Uri "http://localhost:5000/api/discovery/imports/$($batch.id)/preview" `
    -Headers $apiHeaders
$preview | Select-Object id, status, totalRows, createCount, updateCount, unchangedCount, warningCount, rejectCount

# Inspect the preview in Discovery > Imports before this explicit commit.
$committed = Invoke-RestMethod -Method Post `
    -Uri "http://localhost:5000/api/discovery/imports/$($batch.id)/commit" `
    -Headers $apiHeaders
$committed | Select-Object id, status, committedAt, createCount, updateCount, warningCount, rejectCount
```

Upload the same file again to see the prior-file warning. After preview, the safe rows whose discovery-managed values now match inventory become Unchanged; the intentional warning and reject remain visible.

Local imports are written beneath `src\api\runtime\imports` by default and are excluded from Git. Configure `DiscoveryImport:MaximumFileSizeBytes`, `DiscoveryImport:LocalStoragePath` and `DiscoveryImport:FreshnessThresholdDays` in configuration or environment variables. Production should replace local storage with private Azure Blob Storage using managed identity; Phase 2 deploys no Blob infrastructure.

## Development context

`CurrentCustomerContext` reads the customer, project and user headers for every request, falling back to the safe fictional development IDs in `appsettings.json`. EF Core global query filters enforce the customer boundary; project-aware services additionally constrain project-owned operations. The mechanism can later read Entra ID claims without changing domain or service contracts.

See [POC architecture](docs/architecture/POC_Architecture.md), [data model](docs/architecture/Data_Model.md), [Discovery Import architecture](docs/architecture/Discovery_Import_Architecture.md), [Discovery Import functional scope](docs/functional/Discovery_Import_Functional_Scope.md), [ADR-004](docs/architecture/ADR-004-discovery-staging-and-reconciliation.md) and [ADR-005](docs/architecture/ADR-005-discovery-managed-fields.md).

## POC limits

Phase 2 does not implement real authentication, XLSX ingestion, Azure Blob production integration, canonical database/web app/file share/software import, automated dependency discovery or migration execution, rollback workflow, external integrations, DNS/firewall automation, production Azure deployment, billing, Power BI, AI features, multi-cloud, Kubernetes or microservices. The Bicep folder is an opt-in starting point only; it deploys nothing by default.
