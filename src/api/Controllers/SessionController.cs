using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Infrastructure;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LgrTransformationMigration.Api.Controllers;

[ApiController]
[Route("api/v1/session")]
[ServiceFilter(typeof(SqlBrowserJourneysFeatureFilter))]
public sealed class SessionController(IProjectAuthorizationContextAccessor authorization) : ControllerBase
{
    [HttpGet("capabilities")]
    [Authorize(Policy = ProjectAuthorizationPolicies.ActiveMembership)]
    public ActionResult<BrowserCapabilitiesDto> Capabilities()
    {
        var permissions = authorization.AuthorizationContext?.Permissions
            .Where(permission => permission.StartsWith("sql.", StringComparison.Ordinal)
                                 || permission.StartsWith("dependency.", StringComparison.Ordinal))
            .Order(StringComparer.Ordinal)
            .ToArray() ?? [];
        return Ok(new BrowserCapabilitiesDto(permissions));
    }
}
