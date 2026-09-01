# POC Functional Scope

## Primary journey

The POC proves: Customer -> Project -> Application/Server Inventory -> Migration Decision -> Azure Target -> IP Allocation -> Migration Wave -> Readiness -> Runbook.

## Included

- Demo Council and LGR Azure Transformation Programme context.
- Application/server create and edit, relationships, search and filters.
- Migration decision create plus API CRUD.
- Azure target display plus API CRUD, limited to one target per server.
- Two sample subnets across two VNets and deliberately small address pools.
- Validated reserve, allocate and release operations.
- Three seeded migration waves; wave creation and application/server association.
- Seeded readiness checks, editable check status, overall calculation and wave summary.
- Default 13-task runbook generation and task status updates.
- Dashboard metrics scoped to current customer and project.
- Global/customer lookup architecture and customer-specific value creation.
- Foundation audit rows for key changes; no event sourcing.

## Demonstration flow

Start the API and web app, retain the Demo Council context, review dashboard and inventory, record a decision, inspect a target, select an unassigned server and reserve an available IP, allocate it, create or inspect a wave, review readiness, and generate a runbook for a wave without one.

## Excluded

Imports and automated discovery; SQL/SSIS/SSRS assessment; migration execution; complete rollback workflow; ServiceNow/CMDB, DNS and firewall integration; Power BI; billing/licensing; AI recommendations; multi-cloud; Kubernetes/microservices; and direct Azure deployment are intentionally outside Phase 1.

## Phase 2 candidates

Microsoft Entra ID and role-based access, stronger audit capture, attachment storage, assessment/import pipelines, complete rollback/test/sign-off workflows, optimistic concurrency, customer lookup override rules, production Azure landing-zone design, observability and operational dashboards should be prioritised through discovery before implementation.
