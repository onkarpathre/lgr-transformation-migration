using LgrTransformationMigration.Api.Services.Discovery;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using System.Diagnostics;
using System.Globalization;
using System.Net;
using System.Text.Json;

namespace LgrTransformationMigration.Api.Infrastructure;

public static class HealthEndpoints
{
    public static void Map(WebApplication app)
    {
        app.MapGet("/health/live", () => Results.Json(new { status = "Healthy" }))
            .AllowAnonymous()
            .ExcludeFromDescription();
        app.MapGet("/health/ready", ReadyAsync)
            .AllowAnonymous()
            .ExcludeFromDescription();
        app.MapGet("/health", ReadyAsync)
            .AllowAnonymous()
            .ExcludeFromDescription();
    }

    private static async Task<IResult> ReadyAsync(
        AppDbContext database,
        IProjectMembershipReadiness memberships,
        IImportStorageReadiness storage,
        ILogger<ReadinessHealthDiagnostics> logger,
        HttpContext context,
        CancellationToken requestAborted)
    {
        var ready = await EvaluateReadinessAsync(
            async cancellationToken =>
            {
                await database.Database.ExecuteSqlRawAsync("SELECT 1", cancellationToken);
                return true;
            },
            memberships.IsReadyAsync,
            storage.IsReadyAsync,
            logger,
            context.TraceIdentifier,
            requestAborted,
            TimeSpan.FromSeconds(5));

        return ready
            ? Results.Json(new { status = "Healthy" })
            : Results.Json(new { status = "Unavailable" }, statusCode: StatusCodes.Status503ServiceUnavailable);
    }

    internal static async Task<bool> EvaluateReadinessAsync(
        Func<CancellationToken, Task<bool>> sql,
        Func<CancellationToken, ValueTask<bool>> memberships,
        Func<CancellationToken, ValueTask<bool>> storage,
        ILogger logger,
        string correlationId,
        CancellationToken requestAborted,
        TimeSpan budget)
    {
        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(requestAborted);
        timeout.CancelAfter(budget);

        var sqlResult = await ProbeAsync(
            "sql",
            async cancellationToken => await sql(cancellationToken),
            logger,
            correlationId,
            timeout,
            requestAborted);
        if (sqlResult is ReadinessProbeOutcome.Exception or ReadinessProbeOutcome.Timeout)
        {
            return false;
        }

        var membershipResult = await ProbeAsync(
            "memberships",
            async cancellationToken => await memberships(cancellationToken),
            logger,
            correlationId,
            timeout,
            requestAborted);
        if (membershipResult is ReadinessProbeOutcome.Exception or ReadinessProbeOutcome.Timeout)
        {
            return false;
        }

        var storageResult = await ProbeAsync(
            "storage",
            async cancellationToken => await storage(cancellationToken),
            logger,
            correlationId,
            timeout,
            requestAborted);

        return sqlResult == ReadinessProbeOutcome.Ready
            && membershipResult == ReadinessProbeOutcome.Ready
            && storageResult == ReadinessProbeOutcome.Ready;
    }

    private static async Task<ReadinessProbeOutcome> ProbeAsync(
        string dependency,
        Func<CancellationToken, Task<bool>> probe,
        ILogger logger,
        string correlationId,
        CancellationTokenSource timeout,
        CancellationToken requestAborted)
    {
        try
        {
            if (await probe(timeout.Token))
            {
                return ReadinessProbeOutcome.Ready;
            }

            AzureDemoDependencyDiagnostics.LogFalse(logger, dependency, correlationId: correlationId);
            return ReadinessProbeOutcome.False;
        }
        catch (OperationCanceledException exception) when (
            timeout.IsCancellationRequested && !requestAborted.IsCancellationRequested)
        {
            AzureDemoDependencyDiagnostics.LogTimeout(
                logger,
                dependency,
                exception,
                "shared-budget-timeout",
                correlationId);
            return ReadinessProbeOutcome.Timeout;
        }
        catch (Exception exception) when (
            AzureDemoDependencyDiagnostics.IsTimeout(exception) && !requestAborted.IsCancellationRequested)
        {
            AzureDemoDependencyDiagnostics.LogTimeout(
                logger,
                dependency,
                exception,
                "dependency-timeout",
                correlationId);
            return ReadinessProbeOutcome.Timeout;
        }
        catch (Exception exception) when (!requestAborted.IsCancellationRequested)
        {
            AzureDemoDependencyDiagnostics.LogException(
                logger,
                dependency,
                exception,
                "dependency-exception",
                correlationId);
            return ReadinessProbeOutcome.Exception;
        }
    }

    private enum ReadinessProbeOutcome
    {
        Ready,
        False,
        Exception,
        Timeout
    }
}

internal sealed class ReadinessHealthDiagnostics;

internal static class AzureDemoDependencyDiagnostics
{
    private const int MaxExceptionTraversalDepth = 8;
    private const int MaxSqlErrorDiagnostics = 8;
    private static readonly EventId FalseEvent = new(7101, "ReadinessDependencyFalse");
    private static readonly EventId ExceptionEvent = new(7102, "ReadinessDependencyException");
    private static readonly EventId TimeoutEvent = new(7103, "ReadinessDependencyTimeout");

    public static void LogFalse(
        ILogger logger,
        string dependency,
        HttpStatusCode? httpStatus = null,
        string? correlationId = null) =>
        logger.LogWarning(
            FalseEvent,
            "AzureDemo dependency readiness failed. Dependency={Dependency}; Outcome={Outcome}; Category={Category}; ExceptionType={ExceptionType}; HttpStatus={HttpStatus}; CorrelationId={CorrelationId}.",
            dependency,
            "false",
            httpStatus.HasValue ? "http-status" : "false-result",
            "none",
            httpStatus.HasValue ? ((int)httpStatus.Value).ToString() : "none",
            SafeCorrelationId(correlationId));

    public static void LogException(
        ILogger logger,
        string dependency,
        Exception exception,
        string category,
        string? correlationId = null)
    {
        var status = FindHttpStatus(exception);
        var sqlException = FindSqlException(exception);
        if (sqlException is not null)
        {
            logger.LogError(
                ExceptionEvent,
                "AzureDemo dependency readiness failed. Dependency={Dependency}; Outcome={Outcome}; Category={Category}; ExceptionType={ExceptionType}; HttpStatus={HttpStatus}; CorrelationId={CorrelationId}; SqlNumber={SqlNumber}; SqlState={SqlState}; SqlClass={SqlClass}; SqlErrorCount={SqlErrorCount}; SqlErrorsTruncated={SqlErrorsTruncated}; SqlErrors={SqlErrors}.",
                dependency,
                "exception",
                category,
                exception.GetType().FullName ?? exception.GetType().Name,
                status.HasValue ? ((int)status.Value).ToString() : "none",
                SafeCorrelationId(correlationId),
                sqlException.Number,
                sqlException.State,
                sqlException.Class,
                sqlException.Errors.Count,
                sqlException.Errors.Count > MaxSqlErrorDiagnostics,
                FormatSqlErrors(sqlException.Errors));
            return;
        }

        logger.LogError(
            ExceptionEvent,
            "AzureDemo dependency readiness failed. Dependency={Dependency}; Outcome={Outcome}; Category={Category}; ExceptionType={ExceptionType}; HttpStatus={HttpStatus}; CorrelationId={CorrelationId}.",
            dependency,
            "exception",
            category,
            exception.GetType().FullName ?? exception.GetType().Name,
            status.HasValue ? ((int)status.Value).ToString() : "none",
            SafeCorrelationId(correlationId));
    }

    public static void LogTimeout(
        ILogger logger,
        string dependency,
        Exception exception,
        string category,
        string? correlationId = null) =>
        logger.LogError(
            TimeoutEvent,
            "AzureDemo dependency readiness failed. Dependency={Dependency}; Outcome={Outcome}; Category={Category}; ExceptionType={ExceptionType}; HttpStatus={HttpStatus}; CorrelationId={CorrelationId}.",
            dependency,
            "timeout",
            category,
            exception.GetType().FullName ?? exception.GetType().Name,
            "none",
            SafeCorrelationId(correlationId));

    public static string ClassifyMembershipException(Exception exception) =>
        FindHttpStatus(exception).HasValue
            ? "http-status"
            : exception is JsonException or InvalidOperationException
                ? "invalid-response"
                : "dependency-exception";

    public static bool IsTimeout(Exception exception) =>
        exception is TimeoutException or OperationCanceledException;

    private static HttpStatusCode? FindHttpStatus(Exception exception)
    {
        var current = exception;
        for (var depth = 0;
             current is not null && depth < MaxExceptionTraversalDepth;
             depth++, current = current.InnerException)
        {
            if (current is HttpRequestException { StatusCode: { } statusCode })
            {
                return statusCode;
            }
        }

        return null;
    }

    private static SqlException? FindSqlException(Exception exception)
    {
        var current = exception;
        for (var depth = 0;
             current is not null && depth < MaxExceptionTraversalDepth;
             depth++, current = current.InnerException)
        {
            if (current is SqlException sqlException)
            {
                return sqlException;
            }
        }

        return null;
    }

    private static string FormatSqlErrors(SqlErrorCollection errors)
    {
        var count = Math.Min(errors.Count, MaxSqlErrorDiagnostics);
        var diagnostics = new string[count];
        for (var index = 0; index < count; index++)
        {
            var error = errors[index];
            diagnostics[index] = string.Create(
                CultureInfo.InvariantCulture,
                $"Number={error.Number},State={error.State},Class={error.Class}");
        }

        return string.Join('|', diagnostics);
    }

    private static string SafeCorrelationId(string? correlationId)
    {
        if (!string.IsNullOrWhiteSpace(correlationId))
        {
            return correlationId;
        }

        var traceId = Activity.Current?.TraceId.ToHexString();
        return string.IsNullOrWhiteSpace(traceId) ? "unavailable" : traceId;
    }
}

public sealed class ApiSecurityHeadersMiddleware(RequestDelegate next)
{
    public async Task InvokeAsync(HttpContext context)
    {
        context.Response.OnStarting(() =>
        {
            var headers = context.Response.Headers;
            headers["X-Content-Type-Options"] = "nosniff";
            headers["Referrer-Policy"] = "no-referrer";
            headers["X-Frame-Options"] = "DENY";
            headers["Content-Security-Policy"] = "default-src 'none'; frame-ancestors 'none'; base-uri 'none'";
            headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=(), payment=(), usb=()";
            headers["Cache-Control"] = "no-store";
            headers.Remove("Server");
            return Task.CompletedTask;
        });
        await next(context);
    }
}

public sealed class TraceCorrelationMiddleware(RequestDelegate next)
{
    public async Task InvokeAsync(HttpContext context)
    {
        var correlationId = Activity.Current?.TraceId.ToHexString();
        if (string.IsNullOrWhiteSpace(correlationId))
        {
            correlationId = context.TraceIdentifier;
        }
        context.TraceIdentifier = correlationId;
        context.Response.OnStarting(() =>
        {
            context.Response.Headers["X-Correlation-Id"] = correlationId;
            return Task.CompletedTask;
        });
        await next(context);
    }
}
