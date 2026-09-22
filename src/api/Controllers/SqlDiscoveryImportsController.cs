using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Infrastructure;
using LgrTransformationMigration.Api.Services.Discovery;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LgrTransformationMigration.Api.Controllers;

[ApiController]
[Route("api/v1/discovery/imports")]
[ServiceFilter(typeof(SqlDiscoveryImportFeatureFilter))]
public sealed class SqlDiscoveryImportsController(SqlDiscoveryImportService service) : ControllerBase
{
    [HttpGet]
    [Authorize(Policy = SqlDiscoveryAuthorizationPolicies.Read)]
    public async Task<ActionResult<PagedResult<DiscoveryImportBatchDto>>> List(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken cancellationToken = default) =>
        Ok(await service.ListAsync(
            Math.Max(page, 1),
            Math.Clamp(pageSize, 1, 200),
            cancellationToken));

    [HttpGet("{id:guid}")]
    [Authorize(Policy = SqlDiscoveryAuthorizationPolicies.Read)]
    public async Task<ActionResult<DiscoveryImportBatchDto>> Get(Guid id, CancellationToken cancellationToken)
    {
        var result = await service.GetAsync(id, cancellationToken);
        SetEntityTag(result.Version);
        return Ok(result);
    }

    [HttpPost("upload")]
    [Consumes("multipart/form-data")]
    [Authorize(Policy = SqlDiscoveryAuthorizationPolicies.Prepare)]
    public async Task<ActionResult<DiscoveryImportBatchDto>> Upload(
        [FromForm] DiscoveryUploadRequest request,
        CancellationToken cancellationToken)
    {
        var result = await service.UploadAsync(request.File, request.SourceType, cancellationToken);
        SetEntityTag(result.Version);
        return CreatedAtAction(nameof(Get), new { id = result.Id }, result);
    }

    [HttpPost("{id:guid}/preview")]
    [Authorize(Policy = SqlDiscoveryAuthorizationPolicies.Prepare)]
    public async Task<ActionResult<DiscoveryImportBatchDto>> Preview(Guid id, CancellationToken cancellationToken)
    {
        var result = await service.PreviewAsync(id, Request.Headers.IfMatch.ToString(), cancellationToken);
        SetEntityTag(result.Version);
        return Ok(result);
    }

    [HttpGet("{id:guid}/rows")]
    [Authorize(Policy = SqlDiscoveryAuthorizationPolicies.Read)]
    public async Task<ActionResult<PagedResult<SqlDiscoveryImportRowDto>>> Rows(
        Guid id,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        [FromQuery] string? classification = null,
        CancellationToken cancellationToken = default) =>
        Ok(await service.ListRowsAsync(
            id,
            Math.Max(page, 1),
            Math.Clamp(pageSize, 1, 200),
            classification,
            cancellationToken));

    [HttpGet("{id:guid}/rows/{rowId:guid}")]
    [Authorize(Policy = SqlDiscoveryAuthorizationPolicies.Read)]
    public async Task<ActionResult<SqlDiscoveryImportRowDetailDto>> Row(
        Guid id,
        Guid rowId,
        CancellationToken cancellationToken) =>
        Ok(await service.GetRowAsync(id, rowId, cancellationToken));

    [HttpPost("{id:guid}/commit")]
    [Authorize(Policy = SqlDiscoveryAuthorizationPolicies.Commit)]
    public async Task<ActionResult<DiscoveryImportBatchDto>> Commit(Guid id, CancellationToken cancellationToken)
    {
        var result = await service.CommitAsync(
            id,
            Request.Headers.IfMatch.ToString(),
            Request.Headers["Idempotency-Key"].ToString(),
            cancellationToken);
        SetEntityTag(result.Version);
        return Ok(result);
    }

    [HttpPost("{id:guid}/cancel")]
    [Authorize(Policy = SqlDiscoveryAuthorizationPolicies.Cancel)]
    public async Task<ActionResult<DiscoveryImportBatchDto>> Cancel(Guid id, CancellationToken cancellationToken)
    {
        var result = await service.CancelAsync(id, Request.Headers.IfMatch.ToString(), cancellationToken);
        SetEntityTag(result.Version);
        return Ok(result);
    }

    private void SetEntityTag(string version) => Response.Headers.ETag = $"\"{version}\"";
}

[ApiController]
[ServiceFilter(typeof(SqlDiscoveryImportFeatureFilter))]
public sealed class SqlDiscoveryHistoryController(SqlDiscoveryImportService service) : ControllerBase
{
    [HttpGet("api/v1/sql-instances/{id:guid}/discovery-history")]
    [Authorize(Policy = SqlDiscoveryAuthorizationPolicies.Read)]
    public async Task<ActionResult<PagedResult<SqlInstanceDiscoverySnapshotDto>>> InstanceHistory(
        Guid id,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken cancellationToken = default) =>
        Ok(await service.GetInstanceHistoryAsync(
            id,
            Math.Max(page, 1),
            Math.Clamp(pageSize, 1, 200),
            cancellationToken));

    [HttpGet("api/v1/sql-databases/{id:guid}/discovery-history")]
    [Authorize(Policy = SqlDiscoveryAuthorizationPolicies.Read)]
    public async Task<ActionResult<PagedResult<SqlDatabaseDiscoverySnapshotDto>>> DatabaseHistory(
        Guid id,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken cancellationToken = default) =>
        Ok(await service.GetDatabaseHistoryAsync(
            id,
            Math.Max(page, 1),
            Math.Clamp(pageSize, 1, 200),
            cancellationToken));
}
