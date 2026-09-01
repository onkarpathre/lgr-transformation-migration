using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Services.Discovery;
using Microsoft.AspNetCore.Mvc;

namespace LgrTransformationMigration.Api.Controllers;

[ApiController]
[Route("api/discovery/imports")]
public sealed class DiscoveryImportsController(DiscoveryImportService service) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<DiscoveryImportBatchDto>>> List(CancellationToken ct) => Ok(await service.ListAsync(ct));

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<DiscoveryImportBatchDto>> Get(Guid id, CancellationToken ct) => Ok(await service.GetAsync(id, ct));

    [HttpPost("upload")]
    [Consumes("multipart/form-data")]
    public async Task<ActionResult<DiscoveryImportBatchDto>> Upload([FromForm] DiscoveryUploadRequest request, CancellationToken ct)
    {
        var result = await service.UploadAsync(request.File, request.SourceType, ct);
        return CreatedAtAction(nameof(Get), new { id = result.Id }, result);
    }

    [HttpPost("{id:guid}/preview")]
    public async Task<ActionResult<DiscoveryImportBatchDto>> Preview(Guid id, CancellationToken ct) => Ok(await service.PreviewAsync(id, ct));

    [HttpGet("{id:guid}/rows")]
    public async Task<ActionResult<PagedResult<DiscoveryImportRowDto>>> Rows(
        Guid id, [FromQuery] int page = 1, [FromQuery] int pageSize = 100,
        [FromQuery] string? classification = null, CancellationToken ct = default) =>
        Ok(await service.ListRowsAsync(id, Math.Max(page, 1), Math.Clamp(pageSize, 1, 200), classification, ct));

    [HttpGet("{id:guid}/rows/{rowId:guid}")]
    public async Task<ActionResult<DiscoveryImportRowDetailDto>> Row(Guid id, Guid rowId, CancellationToken ct) =>
        Ok(await service.GetRowAsync(id, rowId, ct));

    [HttpPost("{id:guid}/commit")]
    public async Task<ActionResult<DiscoveryImportBatchDto>> Commit(Guid id, CancellationToken ct) => Ok(await service.CommitAsync(id, ct));

    [HttpPost("{id:guid}/cancel")]
    public async Task<ActionResult<DiscoveryImportBatchDto>> Cancel(Guid id, CancellationToken ct) => Ok(await service.CancelAsync(id, ct));
}

[ApiController]
[Route("api/servers")]
public sealed class ServerDiscoveryController(DiscoveryImportService service) : ControllerBase
{
    [HttpGet("{id:guid}/discovery-history")]
    public async Task<ActionResult<IReadOnlyList<ServerDiscoverySnapshotDto>>> History(Guid id, CancellationToken ct) =>
        Ok(await service.GetServerHistoryAsync(id, ct));
}
