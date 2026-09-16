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
            DomainForbiddenException => (StatusCodes.Status403Forbidden, "Permission denied", "permission_denied"),
            PayloadTooLargeException => (StatusCodes.Status413PayloadTooLarge, "The request payload is too large", "payload_too_large"),
            UnsupportedMediaTypeException => (StatusCodes.Status415UnsupportedMediaType, "The media type is not supported", "unsupported_media_type"),
            UnsupportedSourceContractException => (StatusCodes.Status422UnprocessableEntity, "The source contract is not supported", "unsupported_source_contract"),
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
            KeyNotFoundException => "The requested resource was not found.",
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
                Type = ProblemType(status),
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

    private static string ProblemType(int status) =>
        status switch
        {
            StatusCodes.Status400BadRequest => "https://www.rfc-editor.org/rfc/rfc9110#section-15.5.1",
            StatusCodes.Status403Forbidden => "https://www.rfc-editor.org/rfc/rfc9110#section-15.5.4",
            StatusCodes.Status404NotFound => "https://www.rfc-editor.org/rfc/rfc9110#section-15.5.5",
            StatusCodes.Status409Conflict => "https://www.rfc-editor.org/rfc/rfc9110#section-15.5.10",
            StatusCodes.Status413PayloadTooLarge => "https://www.rfc-editor.org/rfc/rfc9110#section-15.5.14",
            StatusCodes.Status415UnsupportedMediaType => "https://www.rfc-editor.org/rfc/rfc9110#section-15.5.16",
            StatusCodes.Status422UnprocessableEntity => "https://www.rfc-editor.org/rfc/rfc9110#section-15.5.21",
            StatusCodes.Status412PreconditionFailed => "https://www.rfc-editor.org/rfc/rfc9110#section-15.5.13",
            StatusCodes.Status428PreconditionRequired => "https://www.rfc-editor.org/rfc/rfc6585#section-3",
            StatusCodes.Status500InternalServerError => "https://www.rfc-editor.org/rfc/rfc9110#section-15.6.1",
            _ => "about:blank"
        };
}
