namespace LgrTransformationMigration.Api.Infrastructure;

public interface ICurrentCustomerContext
{
    Guid CustomerId { get; }
    Guid ProjectId { get; }
    string UserName { get; }
    string CorrelationId { get; }
}

public sealed class CurrentCustomerContext(
    IHttpContextAccessor httpContextAccessor,
    IConfiguration configuration,
    IHostEnvironment environment) : ICurrentCustomerContext
{
    public Guid CustomerId => ReadGuid("X-Customer-Id", "DevelopmentContext:CustomerId");
    public Guid ProjectId => ReadGuid("X-Project-Id", "DevelopmentContext:ProjectId");

    public string UserName => environment.IsDevelopment() || environment.IsEnvironment("Testing")
        ? ReadDevelopmentHeader("X-User-Name")
          ?? configuration["DevelopmentContext:UserName"]
          ?? "local.developer"
        : throw new InvalidOperationException("An authenticated user context is required.");

    public string CorrelationId =>
        httpContextAccessor.HttpContext?.TraceIdentifier
        ?? Guid.NewGuid().ToString("N");

    private Guid ReadGuid(string headerName, string configurationKey)
    {
        var headerValue = ReadDevelopmentHeader(headerName);
        if (Guid.TryParse(headerValue, out var headerGuid))
        {
            return headerGuid;
        }

        if (IsLocalContextAllowed && Guid.TryParse(configuration[configurationKey], out var configuredGuid))
        {
            return configuredGuid;
        }

        throw new InvalidOperationException("An authenticated customer and project context is required.");
    }

    private string? ReadDevelopmentHeader(string headerName) =>
        IsLocalContextAllowed
            ? httpContextAccessor.HttpContext?.Request.Headers[headerName].FirstOrDefault()
            : null;

    private bool IsLocalContextAllowed => environment.IsDevelopment() || environment.IsEnvironment("Testing");
}
