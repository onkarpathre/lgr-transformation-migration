namespace LgrTransformationMigration.Api.Infrastructure;

public interface ICurrentCustomerContext
{
    Guid CustomerId { get; }
    Guid ProjectId { get; }
    string UserName { get; }
}

public sealed class CurrentCustomerContext(
    IHttpContextAccessor httpContextAccessor,
    IConfiguration configuration) : ICurrentCustomerContext
{
    public Guid CustomerId => ReadGuid("X-Customer-Id", "DevelopmentContext:CustomerId");
    public Guid ProjectId => ReadGuid("X-Project-Id", "DevelopmentContext:ProjectId");

    public string UserName =>
        httpContextAccessor.HttpContext?.Request.Headers["X-User-Name"].FirstOrDefault()
        ?? configuration["DevelopmentContext:UserName"]
        ?? "local.developer";

    private Guid ReadGuid(string headerName, string configurationKey)
    {
        var headerValue = httpContextAccessor.HttpContext?.Request.Headers[headerName].FirstOrDefault();
        if (Guid.TryParse(headerValue, out var headerGuid))
        {
            return headerGuid;
        }

        if (Guid.TryParse(configuration[configurationKey], out var configuredGuid))
        {
            return configuredGuid;
        }

        throw new InvalidOperationException($"A valid {configurationKey} value is required.");
    }
}
