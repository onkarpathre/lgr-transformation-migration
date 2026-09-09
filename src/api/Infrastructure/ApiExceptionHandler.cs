using LgrTransformationMigration.Api.Domain;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LgrTransformationMigration.Api.Infrastructure;

public sealed class ApiExceptionHandler(IProblemDetailsService problemDetailsService, ILogger<ApiExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext httpContext, Exception exception, CancellationToken cancellationToken)
    {
        var (status, title, errorCode) = exception switch
        {
            DomainValidationException => (StatusCodes.Status400BadRequest, "Business validation failed", "validation_failed"),
            StaleVersionException => (StatusCodes.Status412PreconditionFailed, "The resource version is stale", "stale_version"),
            PreconditionRequiredException => (StatusCodes.Status428PreconditionRequired, "A resource version is required", "precondition_required"),
            DomainConflictException => (StatusCodes.Status409Conflict, "The change conflicts with existing data", "data_conflict"),
            KeyNotFoundException => (StatusCodes.Status404NotFound, "Resource not found", "resource_not_found"),
            DbUpdateConcurrencyException => (StatusCodes.Status412PreconditionFailed, "The resource version is stale", "stale_version"),
            DbUpdateException => (StatusCodes.Status409Conflict, "The change conflicts with existing data", "data_conflict"),
            _ => (StatusCodes.Status500InternalServerError, "An unexpected error occurred", "unexpected_error")
        };

        if (status == StatusCodes.Status500InternalServerError)
        {
            logger.LogError(exception, "Unhandled API error");
        }

        var detail = exception switch
        {
            DbUpdateException => "The requested change conflicts with existing data.",
            _ when status == StatusCodes.Status500InternalServerError => "The request could not be completed.",
            _ => exception.Message
        };

        httpContext.Response.StatusCode = status;
        return await problemDetailsService.TryWriteAsync(new ProblemDetailsContext
        {
            HttpContext = httpContext,
            Exception = exception,
            ProblemDetails = new ProblemDetails
            {
                Status = status,
                Title = title,
                Detail = detail,
                Instance = httpContext.Request.Path,
                Extensions =
                {
                    ["errorCode"] = errorCode,
                    ["correlationId"] = httpContext.TraceIdentifier
                }
            }
        });
    }
}
