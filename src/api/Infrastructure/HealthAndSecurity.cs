using LgrTransformationMigration.Api.Services.Discovery;
using Microsoft.EntityFrameworkCore;
using System.Diagnostics;

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
        CancellationToken requestAborted)
    {
        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(requestAborted);
        timeout.CancelAfter(TimeSpan.FromSeconds(5));
        try
        {
            await database.Database.ExecuteSqlRawAsync("SELECT 1", timeout.Token);
            var membershipReady = await memberships.IsReadyAsync(timeout.Token);
            var storageReady = await storage.IsReadyAsync(timeout.Token);
            return membershipReady && storageReady
                ? Results.Json(new { status = "Healthy" })
                : Results.Json(new { status = "Unavailable" }, statusCode: StatusCodes.Status503ServiceUnavailable);
        }
        catch (Exception) when (!requestAborted.IsCancellationRequested)
        {
            return Results.Json(new { status = "Unavailable" }, statusCode: StatusCodes.Status503ServiceUnavailable);
        }
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
