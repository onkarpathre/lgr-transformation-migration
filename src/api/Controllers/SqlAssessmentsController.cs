using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Infrastructure;
using LgrTransformationMigration.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LgrTransformationMigration.Api.Controllers;

[ApiController]
[Route("api/v1/sql-assessments")]
[ServiceFilter(typeof(SqlAssessmentFeatureFilter))]
public sealed class SqlAssessmentsController(SqlAssessmentService service) : ControllerBase
{
    [HttpGet]
    [Authorize(Policy = SqlAssessmentAuthorizationPolicies.Read)]
    public async Task<ActionResult<PagedResult<SqlAssessmentDto>>> List(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        [FromQuery] string? targetType = null,
        [FromQuery] Guid? targetId = null,
        [FromQuery] string? assessmentStatus = null,
        [FromQuery] string? readinessStatus = null,
        CancellationToken cancellationToken = default) =>
        Ok(await service.ListAsync(
            Math.Max(page, 1),
            Math.Clamp(pageSize, 1, 200),
            targetType,
            targetId,
            assessmentStatus,
            readinessStatus,
            cancellationToken));

    [HttpGet("{id:guid}")]
    [Authorize(Policy = SqlAssessmentAuthorizationPolicies.Read)]
    public async Task<ActionResult<SqlAssessmentDto>> Get(Guid id, CancellationToken cancellationToken)
    {
        var result = await service.GetAsync(id, cancellationToken);
        SetEntityTag(result.Version);
        return Ok(result);
    }

    [HttpPost]
    [Authorize(Policy = SqlAssessmentAuthorizationPolicies.Manage)]
    public async Task<ActionResult<SqlAssessmentDto>> Create(
        SqlAssessmentCreateV1 request,
        CancellationToken cancellationToken)
    {
        var result = await service.CreateAsync(request, cancellationToken);
        SetEntityTag(result.Version);
        return CreatedAtAction(nameof(Get), new { id = result.Id }, result);
    }

    [HttpPut("{id:guid}/evidence")]
    [Authorize(Policy = SqlAssessmentAuthorizationPolicies.Manage)]
    public async Task<ActionResult<SqlAssessmentDto>> UpdateEvidence(
        Guid id,
        SqlAssessmentEvidenceUpdateV1 request,
        CancellationToken cancellationToken)
    {
        var result = await service.UpdateEvidenceAsync(
            id,
            request,
            Request.Headers.IfMatch.ToString(),
            cancellationToken);
        SetEntityTag(result.Version);
        return Ok(result);
    }

    [HttpPut("{id:guid}/planning")]
    [Authorize(Policy = SqlAssessmentAuthorizationPolicies.Plan)]
    public async Task<ActionResult<SqlAssessmentDto>> UpdatePlanning(
        Guid id,
        SqlAssessmentPlanningUpdateV1 request,
        CancellationToken cancellationToken)
    {
        var result = await service.UpdatePlanningAsync(
            id,
            request,
            Request.Headers.IfMatch.ToString(),
            cancellationToken);
        SetEntityTag(result.Version);
        return Ok(result);
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Policy = SqlAssessmentAuthorizationPolicies.Manage)]
    public async Task<IActionResult> Archive(Guid id, CancellationToken cancellationToken)
    {
        await service.ArchiveAsync(id, Request.Headers.IfMatch.ToString(), cancellationToken);
        return NoContent();
    }

    private void SetEntityTag(string version) => Response.Headers.ETag = $"\"{version}\"";
}
