namespace LgrTransformationMigration.Api.Infrastructure;

public interface ICurrentCustomerContext
{
    Guid CustomerId { get; }
    Guid ProjectId { get; }
    string UserName { get; }
    string CorrelationId { get; }
    InternalPrincipal Principal { get; }
}

public sealed class CurrentCustomerContext(
    IHttpContextAccessor httpContextAccessor,
    IInternalPrincipalAccessor principalAccessor,
    IProjectAuthorizationContextAccessor authorizationContextAccessor) : ICurrentCustomerContext
{
    public Guid CustomerId => CurrentAuthorization.CustomerId;
    public Guid ProjectId => CurrentAuthorization.ProjectId;
    public string UserName => Principal.AuditActor;
    public InternalPrincipal Principal => principalAccessor.Principal
                                          ?? throw new InvalidOperationException(
                                              "An authenticated internal principal is required.");

    public string CorrelationId =>
        httpContextAccessor.HttpContext?.TraceIdentifier
        ?? Guid.NewGuid().ToString("N");

    private ProjectAuthorizationContext CurrentAuthorization => authorizationContextAccessor.AuthorizationContext
                                                                 ?? throw new InvalidOperationException(
                                                                     "An authorized customer and project context is required.");
}
