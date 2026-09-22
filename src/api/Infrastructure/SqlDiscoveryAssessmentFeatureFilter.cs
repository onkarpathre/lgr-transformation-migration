using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Options;

namespace LgrTransformationMigration.Api.Infrastructure;

public sealed class FeatureOptions
{
    public const string SectionName = "Features";

    public bool SqlDiscoveryAssessment { get; set; }
    public bool SqlDiscoveryImport { get; set; }
    public bool SqlAssessment { get; set; }
    public bool SqlBrowserJourneys { get; set; }
}

public sealed class SqlBrowserJourneysFeatureFilter(
    IOptionsSnapshot<FeatureOptions> options,
    IHostEnvironment environment) : IAsyncResourceFilter
{
    public async Task OnResourceExecutionAsync(ResourceExecutingContext context, ResourceExecutionDelegate next)
    {
        var enabled = (environment.IsDevelopment() || environment.IsEnvironment("Testing"))
                      && options.Value.SqlDiscoveryAssessment
                      && options.Value.SqlDiscoveryImport
                      && options.Value.SqlAssessment
                      && options.Value.SqlBrowserJourneys;
        if (enabled)
        {
            await next();
            return;
        }

        FeatureNotFound(context);
    }

    private static void FeatureNotFound(ResourceExecutingContext context)
    {
        var problemDetails = new ProblemDetails
        {
            Type = "https://www.rfc-editor.org/rfc/rfc9110#section-15.5.5",
            Title = "Resource not found",
            Status = StatusCodes.Status404NotFound,
            Detail = "The requested resource is not available.",
            Instance = context.HttpContext.Request.Path
        };
        problemDetails.Extensions["errorCode"] = "feature_disabled";
        problemDetails.Extensions["correlationId"] = context.HttpContext.TraceIdentifier;
        context.Result = new ObjectResult(problemDetails)
        {
            StatusCode = StatusCodes.Status404NotFound,
            ContentTypes = { "application/problem+json" }
        };
    }
}

public sealed class SqlAssessmentFeatureFilter(
    IOptionsSnapshot<FeatureOptions> options,
    IHostEnvironment environment) : IAsyncResourceFilter
{
    public async Task OnResourceExecutionAsync(ResourceExecutingContext context, ResourceExecutionDelegate next)
    {
        var enabled = (environment.IsDevelopment() || environment.IsEnvironment("Testing"))
                      && options.Value.SqlDiscoveryAssessment
                      && options.Value.SqlAssessment;
        if (enabled)
        {
            await next();
            return;
        }

        var problemDetails = new ProblemDetails
        {
            Type = "https://www.rfc-editor.org/rfc/rfc9110#section-15.5.5",
            Title = "Resource not found",
            Status = StatusCodes.Status404NotFound,
            Detail = "The requested resource is not available.",
            Instance = context.HttpContext.Request.Path
        };
        problemDetails.Extensions["errorCode"] = "feature_disabled";
        problemDetails.Extensions["correlationId"] = context.HttpContext.TraceIdentifier;
        context.Result = new ObjectResult(problemDetails)
        {
            StatusCode = StatusCodes.Status404NotFound,
            ContentTypes = { "application/problem+json" }
        };
    }
}

public sealed class SqlDiscoveryImportFeatureFilter(
    IOptionsSnapshot<FeatureOptions> options,
    IHostEnvironment environment) : IAsyncResourceFilter
{
    public async Task OnResourceExecutionAsync(ResourceExecutingContext context, ResourceExecutionDelegate next)
    {
        var enabled = (environment.IsDevelopment() || environment.IsEnvironment("Testing"))
                      && options.Value.SqlDiscoveryAssessment
                      && options.Value.SqlDiscoveryImport;
        if (enabled)
        {
            await next();
            return;
        }

        var problemDetails = new ProblemDetails
        {
            Type = "https://www.rfc-editor.org/rfc/rfc9110#section-15.5.5",
            Title = "Resource not found",
            Status = StatusCodes.Status404NotFound,
            Detail = "The requested resource is not available.",
            Instance = context.HttpContext.Request.Path
        };
        problemDetails.Extensions["errorCode"] = "feature_disabled";
        problemDetails.Extensions["correlationId"] = context.HttpContext.TraceIdentifier;
        context.Result = new ObjectResult(problemDetails)
        {
            StatusCode = StatusCodes.Status404NotFound,
            ContentTypes = { "application/problem+json" }
        };
    }
}

public sealed class SqlDiscoveryAssessmentFeatureFilter(
    IOptionsSnapshot<FeatureOptions> options,
    IHostEnvironment environment) : IAsyncResourceFilter
{
    public async Task OnResourceExecutionAsync(ResourceExecutingContext context, ResourceExecutionDelegate next)
    {
        var isApprovedEnvironment = environment.IsDevelopment() || environment.IsEnvironment("Testing");
        if (isApprovedEnvironment && options.Value.SqlDiscoveryAssessment)
        {
            await next();
            return;
        }

        var problemDetails = new ProblemDetails
        {
            Type = "https://www.rfc-editor.org/rfc/rfc9110#section-15.5.5",
            Title = "Resource not found",
            Status = StatusCodes.Status404NotFound,
            Detail = "The requested resource is not available.",
            Instance = context.HttpContext.Request.Path
        };
        problemDetails.Extensions["errorCode"] = "feature_disabled";
        problemDetails.Extensions["correlationId"] = context.HttpContext.TraceIdentifier;

        context.Result = new ObjectResult(problemDetails)
        {
            StatusCode = StatusCodes.Status404NotFound,
            ContentTypes = { "application/problem+json" }
        };
    }
}
