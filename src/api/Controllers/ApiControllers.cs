using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace LgrTransformationMigration.Api.Controllers;

[ApiController]
[Route("api/customers")]
public sealed class CustomersController(ProgrammeService service) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<CustomerDto>>> List(CancellationToken ct) => Ok(new[] { await service.GetCustomerAsync(ct) });

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<CustomerDto>> Get(Guid id, CancellationToken ct)
    {
        var customer = await service.GetCustomerAsync(ct);
        return customer.Id == id ? Ok(customer) : NotFound();
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<CustomerDto>> Update(Guid id, CustomerRequest request, CancellationToken ct)
    {
        var customer = await service.GetCustomerAsync(ct);
        return customer.Id == id ? Ok(await service.UpdateCustomerAsync(request, ct)) : NotFound();
    }
}

[ApiController]
[Route("api/projects")]
public sealed class ProjectsController(ProgrammeService service) : ControllerBase
{
    [HttpGet] public async Task<ActionResult<IReadOnlyList<ProjectDto>>> List(CancellationToken ct) => Ok(await service.ListProjectsAsync(ct));
    [HttpGet("{id:guid}")] public async Task<ActionResult<ProjectDto>> Get(Guid id, CancellationToken ct) => Ok(await service.GetProjectAsync(id, ct));
    [HttpPost] public async Task<ActionResult<ProjectDto>> Create(ProjectRequest request, CancellationToken ct)
    {
        var result = await service.CreateProjectAsync(request, ct); return CreatedAtAction(nameof(Get), new { id = result.Id }, result);
    }
    [HttpPut("{id:guid}")] public async Task<ActionResult<ProjectDto>> Update(Guid id, ProjectRequest request, CancellationToken ct) => Ok(await service.UpdateProjectAsync(id, request, ct));
    [HttpDelete("{id:guid}")] public async Task<IActionResult> Delete(Guid id, CancellationToken ct) { await service.DeleteProjectAsync(id, ct); return NoContent(); }
}

[ApiController]
[Route("api/applications")]
public sealed class ApplicationsController(ProgrammeService service) : ControllerBase
{
    [HttpGet] public async Task<ActionResult<PagedResult<ApplicationDto>>> List([FromQuery] int page = 1, [FromQuery] int pageSize = 50, [FromQuery] string? search = null, CancellationToken ct = default) => Ok(await service.ListApplicationsAsync(Math.Max(page, 1), Math.Clamp(pageSize, 1, 200), search, ct));
    [HttpGet("{id:guid}")] public async Task<ActionResult<ApplicationDto>> Get(Guid id, CancellationToken ct) => Ok(await service.GetApplicationAsync(id, ct));
    [HttpPost] public async Task<ActionResult<ApplicationDto>> Create(ApplicationRequest request, CancellationToken ct) { var result = await service.CreateApplicationAsync(request, ct); return CreatedAtAction(nameof(Get), new { id = result.Id }, result); }
    [HttpPut("{id:guid}")] public async Task<ActionResult<ApplicationDto>> Update(Guid id, ApplicationRequest request, CancellationToken ct) => Ok(await service.UpdateApplicationAsync(id, request, ct));
    [HttpDelete("{id:guid}")] public async Task<IActionResult> Delete(Guid id, CancellationToken ct) { await service.DeleteApplicationAsync(id, ct); return NoContent(); }
}

[ApiController]
[Route("api/servers")]
public sealed class ServersController(ProgrammeService service) : ControllerBase
{
    [HttpGet] public async Task<ActionResult<PagedResult<ServerDto>>> List([FromQuery] int page = 1, [FromQuery] int pageSize = 50, [FromQuery] string? search = null, [FromQuery] string? environment = null, CancellationToken ct = default) => Ok(await service.ListServersAsync(Math.Max(page, 1), Math.Clamp(pageSize, 1, 200), search, environment, ct));
    [HttpGet("{id:guid}")] public async Task<ActionResult<ServerDto>> Get(Guid id, CancellationToken ct) => Ok(await service.GetServerAsync(id, ct));
    [HttpPost] public async Task<ActionResult<ServerDto>> Create(ServerRequest request, CancellationToken ct) { var result = await service.CreateServerAsync(request, ct); return CreatedAtAction(nameof(Get), new { id = result.Id }, result); }
    [HttpPut("{id:guid}")] public async Task<ActionResult<ServerDto>> Update(Guid id, ServerRequest request, CancellationToken ct) => Ok(await service.UpdateServerAsync(id, request, ct));
    [HttpDelete("{id:guid}")] public async Task<IActionResult> Delete(Guid id, CancellationToken ct) { await service.DeleteServerAsync(id, ct); return NoContent(); }
}

[ApiController]
[Route("api/migration-decisions")]
public sealed class MigrationDecisionsController(ProgrammeService service) : ControllerBase
{
    [HttpGet] public async Task<ActionResult<IReadOnlyList<MigrationDecisionDto>>> List(CancellationToken ct) => Ok(await service.ListDecisionsAsync(ct));
    [HttpGet("{id:guid}")] public async Task<ActionResult<MigrationDecisionDto>> Get(Guid id, CancellationToken ct) => Ok(await service.GetDecisionAsync(id, ct));
    [HttpPost] public async Task<ActionResult<MigrationDecisionDto>> Create(MigrationDecisionRequest request, CancellationToken ct) { var result = await service.CreateDecisionAsync(request, ct); return CreatedAtAction(nameof(Get), new { id = result.Id }, result); }
    [HttpPut("{id:guid}")] public async Task<ActionResult<MigrationDecisionDto>> Update(Guid id, MigrationDecisionRequest request, CancellationToken ct) => Ok(await service.UpdateDecisionAsync(id, request, ct));
    [HttpDelete("{id:guid}")] public async Task<IActionResult> Delete(Guid id, CancellationToken ct) { await service.DeleteDecisionAsync(id, ct); return NoContent(); }
}

[ApiController]
[Route("api/azure-targets")]
public sealed class AzureTargetsController(ProgrammeService service) : ControllerBase
{
    [HttpGet] public async Task<ActionResult<IReadOnlyList<AzureTargetDto>>> List(CancellationToken ct) => Ok(await service.ListTargetsAsync(ct));
    [HttpGet("{id:guid}")] public async Task<ActionResult<AzureTargetDto>> Get(Guid id, CancellationToken ct) => Ok(await service.GetTargetAsync(id, ct));
    [HttpPost] public async Task<ActionResult<AzureTargetDto>> Create(AzureTargetRequest request, CancellationToken ct) { var result = await service.CreateTargetAsync(request, ct); return CreatedAtAction(nameof(Get), new { id = result.Id }, result); }
    [HttpPut("{id:guid}")] public async Task<ActionResult<AzureTargetDto>> Update(Guid id, AzureTargetRequest request, CancellationToken ct) => Ok(await service.UpdateTargetAsync(id, request, ct));
    [HttpDelete("{id:guid}")] public async Task<IActionResult> Delete(Guid id, CancellationToken ct) { await service.DeleteTargetAsync(id, ct); return NoContent(); }
}

[ApiController]
[Route("api/subnets")]
public sealed class SubnetsController(ProgrammeService service) : ControllerBase
{
    [HttpGet] public async Task<ActionResult<IReadOnlyList<SubnetDto>>> List(CancellationToken ct) => Ok(await service.ListSubnetsAsync(ct));
    [HttpPost] public async Task<ActionResult<SubnetDto>> Create(SubnetRequest request, CancellationToken ct) => StatusCode(StatusCodes.Status201Created, await service.CreateSubnetAsync(request, ct));
    [HttpPut("{id:guid}")] public async Task<ActionResult<SubnetDto>> Update(Guid id, SubnetRequest request, CancellationToken ct) => Ok(await service.UpdateSubnetAsync(id, request, ct));
    [HttpDelete("{id:guid}")] public async Task<IActionResult> Delete(Guid id, CancellationToken ct) { await service.DeleteSubnetAsync(id, ct); return NoContent(); }
}

[ApiController]
[Route("api/ip-addresses")]
public sealed class IpAddressesController(ProgrammeService programme, IpAllocationService allocation) : ControllerBase
{
    [HttpGet] public async Task<ActionResult<IReadOnlyList<IpAddressDto>>> List([FromQuery] Guid? subnetId, CancellationToken ct) => Ok(await programme.ListIpAddressesAsync(subnetId, ct));
    [HttpPost] public async Task<ActionResult<IpAddressDto>> Create(IpAddressRequest request, CancellationToken ct) => StatusCode(StatusCodes.Status201Created, await programme.CreateIpAddressAsync(request, ct));
    [HttpPost("{id:guid}/reserve")] public async Task<ActionResult<IpAddressDto>> Reserve(Guid id, IpTransitionRequest request, CancellationToken ct)
    {
        if (request.ServerId is null) return ValidationProblem("ServerId is required when reserving an address.");
        return Ok(await allocation.ReserveAsync(id, request.ServerId.Value, ct));
    }
    [HttpPost("{id:guid}/allocate")] public async Task<ActionResult<IpAddressDto>> Allocate(Guid id, CancellationToken ct) => Ok(await allocation.AllocateAsync(id, ct));
    [HttpPost("{id:guid}/release")] public async Task<ActionResult<IpAddressDto>> Release(Guid id, CancellationToken ct) => Ok(await allocation.ReleaseAsync(id, ct));
    [HttpDelete("{id:guid}")] public async Task<IActionResult> Delete(Guid id, CancellationToken ct) { await programme.DeleteIpAddressAsync(id, ct); return NoContent(); }
}

[ApiController]
[Route("api/migration-waves")]
public sealed class MigrationWavesController(ProgrammeService service) : ControllerBase
{
    [HttpGet] public async Task<ActionResult<IReadOnlyList<MigrationWaveDto>>> List(CancellationToken ct) => Ok(await service.ListWavesAsync(ct));
    [HttpGet("{id:guid}")] public async Task<ActionResult<MigrationWaveDetailDto>> Get(Guid id, CancellationToken ct) => Ok(await service.GetWaveAsync(id, ct));
    [HttpPost] public async Task<ActionResult<MigrationWaveDto>> Create(MigrationWaveRequest request, CancellationToken ct) => StatusCode(StatusCodes.Status201Created, await service.CreateWaveAsync(request, ct));
    [HttpPut("{id:guid}")] public async Task<ActionResult<MigrationWaveDto>> Update(Guid id, MigrationWaveRequest request, CancellationToken ct) => Ok(await service.UpdateWaveAsync(id, request, ct));
    [HttpDelete("{id:guid}")] public async Task<IActionResult> Delete(Guid id, CancellationToken ct) { await service.DeleteWaveAsync(id, ct); return NoContent(); }
    [HttpPost("{id:guid}/assets")] public async Task<ActionResult<MigrationWaveDetailDto>> AddAsset(Guid id, WaveAssetRequest request, CancellationToken ct) => Ok(await service.AddWaveAssetAsync(id, request, ct));
    [HttpDelete("{id:guid}/assets/{assetId:guid}")] public async Task<IActionResult> RemoveAsset(Guid id, Guid assetId, CancellationToken ct) { await service.RemoveWaveAssetAsync(id, assetId, ct); return NoContent(); }
}

[ApiController]
[Route("api/readiness")]
public sealed class ReadinessController(ProgrammeService service) : ControllerBase
{
    [HttpGet] public async Task<ActionResult<ReadinessResponse>> List(CancellationToken ct) => Ok(await service.GetReadinessAsync(ct));
    [HttpPut("{id:guid}")] public async Task<ActionResult<ReadinessCheckDto>> Update(Guid id, ReadinessUpdateRequest request, CancellationToken ct) => Ok(await service.UpdateReadinessAsync(id, request, ct));
}

[ApiController]
[Route("api/runbooks")]
public sealed class RunbooksController(RunbookService service) : ControllerBase
{
    [HttpGet] public async Task<ActionResult<IReadOnlyList<RunbookDto>>> List(CancellationToken ct) => Ok(await service.ListAsync(ct));
    [HttpGet("{id:guid}")] public async Task<ActionResult<RunbookDto>> Get(Guid id, CancellationToken ct) => Ok(await service.GetAsync(id, ct));
    [HttpPost("generate")] public async Task<ActionResult<RunbookDto>> Generate(GenerateRunbookRequest request, CancellationToken ct) => StatusCode(StatusCodes.Status201Created, await service.GenerateAsync(request, ct));
    [HttpPut("{id:guid}/tasks/{taskId:guid}")] public async Task<ActionResult<RunbookDto>> UpdateTask(Guid id, Guid taskId, RunbookTaskUpdateRequest request, CancellationToken ct) => Ok(await service.UpdateTaskAsync(id, taskId, request, ct));
}

[ApiController]
[Route("api/configuration")]
public sealed class ConfigurationController(ProgrammeService service) : ControllerBase
{
    [HttpGet] public async Task<ActionResult<IReadOnlyList<LookupOptionDto>>> List([FromQuery] string? group, CancellationToken ct) => Ok(await service.GetConfigurationAsync(group, ct));
    [HttpPost] public async Task<ActionResult<LookupOptionDto>> Create(LookupOptionRequest request, CancellationToken ct) => StatusCode(StatusCodes.Status201Created, await service.AddConfigurationAsync(request, ct));
}

[ApiController]
[Route("api/dashboard")]
public sealed class DashboardController(ProgrammeService service) : ControllerBase
{
    [HttpGet("summary")] public async Task<ActionResult<DashboardSummaryDto>> Summary(CancellationToken ct) => Ok(await service.GetDashboardAsync(ct));
}
