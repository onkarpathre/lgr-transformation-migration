using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Domain;
using LgrTransformationMigration.Api.Infrastructure;
using LgrTransformationMigration.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LgrTransformationMigration.Api.Controllers;

[ApiController]
[Route("api/v1/dependency-references")]
[ServiceFilter(typeof(DependencyRegisterFeatureFilter))]
public sealed class DependencyReferencesController(DependencyRegisterService service) : ControllerBase
{
    [HttpGet]
    [Authorize(Policy = DependencyAuthorizationPolicies.Read)]
    public async Task<ActionResult<PagedResult<DependencyReferenceDto>>> List(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        [FromQuery] string? referenceType = null,
        [FromQuery] string? resolutionStatus = null,
        [FromQuery] string? search = null,
        [FromQuery] bool includeArchived = false,
        CancellationToken cancellationToken = default)
    {
        DependencyQueryRules.RejectUnknown(
            Request.Query.Keys,
            "page", "pageSize", "referenceType", "resolutionStatus", "search", "includeArchived");
        return Ok(await service.ListReferencesAsync(
            Math.Max(page, 1), Math.Clamp(pageSize, 1, 200), referenceType, resolutionStatus,
            search, includeArchived, cancellationToken));
    }

    [HttpGet("{id:guid}")]
    [Authorize(Policy = DependencyAuthorizationPolicies.Read)]
    public async Task<ActionResult<DependencyReferenceDto>> Get(
        Guid id,
        [FromQuery] bool includeArchived = false,
        CancellationToken cancellationToken = default)
    {
        DependencyQueryRules.RejectUnknown(Request.Query.Keys, "includeArchived");
        var result = await service.GetReferenceAsync(id, includeArchived, cancellationToken);
        SetEntityTag(result.Version);
        return Ok(result);
    }

    [HttpPost]
    [Authorize(Policy = DependencyAuthorizationPolicies.Manage)]
    public async Task<ActionResult<DependencyReferenceDto>> Create(
        DependencyReferenceWriteV1 request,
        CancellationToken cancellationToken)
    {
        var result = await service.CreateReferenceAsync(request, cancellationToken);
        SetEntityTag(result.Version);
        return CreatedAtAction(nameof(Get), new { id = result.Id }, result);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Policy = DependencyAuthorizationPolicies.Manage)]
    public async Task<ActionResult<DependencyReferenceDto>> Update(
        Guid id,
        DependencyReferenceWriteV1 request,
        CancellationToken cancellationToken)
    {
        var result = await service.UpdateReferenceAsync(
            id, request, Request.Headers.IfMatch.ToString(), cancellationToken);
        SetEntityTag(result.Version);
        return Ok(result);
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Policy = DependencyAuthorizationPolicies.Manage)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        await service.ArchiveReferenceAsync(id, Request.Headers.IfMatch.ToString(), cancellationToken);
        return NoContent();
    }

    private void SetEntityTag(string version) => Response.Headers.ETag = $"\"{version}\"";
}

[ApiController]
[Route("api/v1/dependencies")]
[ServiceFilter(typeof(DependencyRegisterFeatureFilter))]
public sealed class DependenciesController(DependencyRegisterService service) : ControllerBase
{
    [HttpGet]
    [Authorize(Policy = DependencyAuthorizationPolicies.Read)]
    public async Task<ActionResult<PagedResult<DependencyDto>>> List(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        [FromQuery] string? assetType = null,
        [FromQuery] Guid? assetId = null,
        [FromQuery] string direction = "Either",
        [FromQuery] string? dependencyType = null,
        [FromQuery] string? criticality = null,
        [FromQuery] string? confirmationStatus = null,
        [FromQuery] string? search = null,
        [FromQuery] bool includeArchived = false,
        CancellationToken cancellationToken = default)
    {
        DependencyQueryRules.RejectUnknown(
            Request.Query.Keys,
            "page", "pageSize", "assetType", "assetId", "direction", "dependencyType",
            "criticality", "confirmationStatus", "search", "includeArchived");
        return Ok(await service.ListDependenciesAsync(
            Math.Max(page, 1), Math.Clamp(pageSize, 1, 200), assetType, assetId, direction,
            dependencyType, criticality, confirmationStatus, search, includeArchived, cancellationToken));
    }

    [HttpGet("{id:guid}")]
    [Authorize(Policy = DependencyAuthorizationPolicies.Read)]
    public async Task<ActionResult<DependencyDto>> Get(
        Guid id,
        [FromQuery] bool includeArchived = false,
        CancellationToken cancellationToken = default)
    {
        DependencyQueryRules.RejectUnknown(Request.Query.Keys, "includeArchived");
        var result = await service.GetDependencyAsync(id, includeArchived, cancellationToken);
        SetEntityTag(result.Version);
        return Ok(result);
    }

    [HttpPost]
    [Authorize(Policy = DependencyAuthorizationPolicies.Manage)]
    public async Task<ActionResult<DependencyDto>> Create(
        DependencyCreateV1 request,
        CancellationToken cancellationToken)
    {
        var result = await service.CreateDependencyAsync(request, cancellationToken);
        SetEntityTag(result.Version);
        return CreatedAtAction(nameof(Get), new { id = result.Id }, result);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Policy = DependencyAuthorizationPolicies.Manage)]
    public async Task<ActionResult<DependencyDto>> Update(
        Guid id,
        DependencyUpdateV1 request,
        CancellationToken cancellationToken)
    {
        var result = await service.UpdateDependencyAsync(
            id, request, Request.Headers.IfMatch.ToString(), cancellationToken);
        SetEntityTag(result.Version);
        return Ok(result);
    }

    [HttpPut("{id:guid}/confirmation")]
    [Authorize(Policy = DependencyAuthorizationPolicies.Confirm)]
    public async Task<ActionResult<DependencyDto>> Confirm(
        Guid id,
        DependencyConfirmationV1 request,
        CancellationToken cancellationToken)
    {
        var result = await service.SetConfirmationAsync(
            id, request, Request.Headers.IfMatch.ToString(), cancellationToken);
        SetEntityTag(result.Version);
        return Ok(result);
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Policy = DependencyAuthorizationPolicies.Manage)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        await service.ArchiveDependencyAsync(id, Request.Headers.IfMatch.ToString(), cancellationToken);
        return NoContent();
    }

    [HttpGet("{id:guid}/audit")]
    [Authorize(Policy = DependencyAuthorizationPolicies.AuditRead)]
    public async Task<ActionResult<PagedResult<DependencyAuditEventDto>>> Audit(
        Guid id,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        CancellationToken cancellationToken = default)
    {
        DependencyQueryRules.RejectUnknown(Request.Query.Keys, "page", "pageSize");
        return Ok(await service.ListAuditAsync(
            id, Math.Max(page, 1), Math.Clamp(pageSize, 1, 200), cancellationToken));
    }

    private void SetEntityTag(string version) => Response.Headers.ETag = $"\"{version}\"";
}

internal static class DependencyQueryRules
{
    public static void RejectUnknown(IEnumerable<string> suppliedKeys, params string[] allowedKeys)
    {
        var allowed = allowedKeys.ToHashSet(StringComparer.OrdinalIgnoreCase);
        var unknown = suppliedKeys.FirstOrDefault(key => !allowed.Contains(key));
        if (unknown is not null)
        {
            throw new DomainValidationException($"Query parameter '{unknown}' is not supported.");
        }
    }
}
