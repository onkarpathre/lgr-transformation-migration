using LgrTransformationMigration.Api.Contracts;
using LgrTransformationMigration.Api.Infrastructure;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LgrTransformationMigration.Api.Controllers;

[ApiController]
[Route("api/v1/session")]
[ServiceFilter(typeof(SqlBrowserJourneysFeatureFilter))]
public sealed class SessionController(
    IProjectAuthorizationContextAccessor authorization,
    IConfiguration configuration,
    IHostEnvironment environment) : ControllerBase
{
    [HttpGet("capabilities")]
    [Authorize(Policy = ProjectAuthorizationPolicies.ActiveMembership)]
    public ActionResult<BrowserCapabilitiesDto> Capabilities()
    {
        var dependencyRegisterEnabled = (environment.IsDevelopment() || environment.IsEnvironment("Testing"))
                                        && configuration.GetValue<bool>("Features:DependencyRegister");
        var permissions = authorization.AuthorizationContext?.Permissions
            .Where(permission => permission.StartsWith("sql.", StringComparison.Ordinal)
                                 || (dependencyRegisterEnabled
                                     && permission.StartsWith("dependency.", StringComparison.Ordinal)))
            .Order(StringComparer.Ordinal)
            .ToArray() ?? [];
        return Ok(new BrowserCapabilitiesDto(permissions));
    }
}
