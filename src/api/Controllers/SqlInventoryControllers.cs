using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Infrastructure;
using LgrTransformationMigration.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace LgrTransformationMigration.Api.Controllers;

[ApiController]
[Route("api/v1/sql-instances")]
[ServiceFilter(typeof(SqlDiscoveryAssessmentFeatureFilter))]
public sealed class SqlInstancesController(SqlInventoryService service) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PagedResult<SqlInstanceDto>>> List(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        [FromQuery] string? search = null,
        [FromQuery] Guid? serverId = null,
        [FromQuery] string? serviceStatus = null,
        CancellationToken cancellationToken = default) =>
        Ok(await service.ListInstancesAsync(
            Math.Max(page, 1),
            Math.Clamp(pageSize, 1, 200),
            search,
            serverId,
            serviceStatus,
            cancellationToken));

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<SqlInstanceDto>> Get(Guid id, CancellationToken cancellationToken)
    {
        var result = await service.GetInstanceAsync(id, cancellationToken);
        SetEntityTag(result.Version);
        return Ok(result);
    }

    [HttpPost]
    public async Task<ActionResult<SqlInstanceDto>> Create(
        SqlInstanceWriteV1 request,
        CancellationToken cancellationToken)
    {
        var result = await service.CreateInstanceAsync(request, cancellationToken);
        SetEntityTag(result.Version);
        return CreatedAtAction(nameof(Get), new { id = result.Id }, result);
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<SqlInstanceDto>> Update(
        Guid id,
        SqlInstanceWriteV1 request,
        CancellationToken cancellationToken)
    {
        var result = await service.UpdateInstanceAsync(
            id,
            request,
            Request.Headers.IfMatch.ToString(),
            cancellationToken);
        SetEntityTag(result.Version);
        return Ok(result);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        await service.ArchiveInstanceAsync(id, Request.Headers.IfMatch.ToString(), cancellationToken);
        return NoContent();
    }

    private void SetEntityTag(string version) => Response.Headers.ETag = $"\"{version}\"";
}

[ApiController]
[Route("api/v1/sql-databases")]
[ServiceFilter(typeof(SqlDiscoveryAssessmentFeatureFilter))]
public sealed class SqlDatabasesController(SqlInventoryService service) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<PagedResult<SqlDatabaseDto>>> List(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        [FromQuery] string? search = null,
        [FromQuery] Guid? sqlInstanceId = null,
        [FromQuery] string? status = null,
        CancellationToken cancellationToken = default) =>
        Ok(await service.ListDatabasesAsync(
            Math.Max(page, 1),
            Math.Clamp(pageSize, 1, 200),
            search,
            sqlInstanceId,
            status,
            cancellationToken));

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<SqlDatabaseDto>> Get(Guid id, CancellationToken cancellationToken)
    {
        var result = await service.GetDatabaseAsync(id, cancellationToken);
        SetEntityTag(result.Version);
        return Ok(result);
    }

    [HttpPost]
    public async Task<ActionResult<SqlDatabaseDto>> Create(
        SqlDatabaseWriteV1 request,
        CancellationToken cancellationToken)
    {
        var result = await service.CreateDatabaseAsync(request, cancellationToken);
        SetEntityTag(result.Version);
        return CreatedAtAction(nameof(Get), new { id = result.Id }, result);
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<SqlDatabaseDto>> Update(
        Guid id,
        SqlDatabaseWriteV1 request,
        CancellationToken cancellationToken)
    {
        var result = await service.UpdateDatabaseAsync(
            id,
            request,
            Request.Headers.IfMatch.ToString(),
            cancellationToken);
        SetEntityTag(result.Version);
        return Ok(result);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        await service.ArchiveDatabaseAsync(id, Request.Headers.IfMatch.ToString(), cancellationToken);
        return NoContent();
    }

    private void SetEntityTag(string version) => Response.Headers.ETag = $"\"{version}\"";
}
