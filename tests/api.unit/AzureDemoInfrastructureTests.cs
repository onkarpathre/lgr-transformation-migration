using System.Net;
using System.Text;
using LgrTransformationMigration.Api.Infrastructure;
using LgrTransformationMigration.Api.Services.Discovery;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace LgrTransformationMigration.Api.UnitTests;

public sealed class AzureDemoInfrastructureTests
{
    private static readonly Guid TenantId = Guid.Parse("11111111-1111-1111-1111-111111111111");
    private static readonly Guid PrincipalId = Guid.Parse("22222222-2222-2222-2222-222222222222");
    private static readonly Guid CustomerId = Guid.Parse("33333333-3333-3333-3333-333333333333");
    private static readonly Guid ProjectId = Guid.Parse("44444444-4444-4444-4444-444444444444");

    private const string LowercaseValueEnvelope = """
        {"value":"{\"schemaVersion\":\"1\",\"membershipVersion\":\"synthetic-v1\",\"tenantId\":\"11111111-1111-1111-1111-111111111111\",\"principals\":[{\"objectId\":\"22222222-2222-2222-2222-222222222222\",\"status\":\"Active\",\"memberships\":[{\"customerId\":\"33333333-3333-3333-3333-333333333333\",\"projectId\":\"44444444-4444-4444-4444-444444444444\",\"status\":\"Active\",\"validFromUtc\":\"2020-01-01T00:00:00Z\",\"validUntilUtc\":\"2100-01-01T00:00:00Z\",\"roles\":[\"MigrationArchitect\"]}]}]}"}
        """;

    [Fact]
    public async Task Lowercase_Key_Vault_value_envelope_loads_and_is_cached()
    {
        var handler = new StubHttpMessageHandler(_ => new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent(LowercaseValueEnvelope, Encoding.UTF8, "application/json")
        });
        var logger = new RecordingLogger<KeyVaultProjectMembershipProvider>();
        var provider = CreateProvider(handler, logger);

        Assert.True(await provider.IsReadyAsync(CancellationToken.None));
        var resolution = await provider.ResolveAsync(Principal(), ProjectId, CancellationToken.None);

        Assert.Equal(MembershipResolutionStatus.Active, resolution.Status);
        Assert.Equal(CustomerId, resolution.CustomerId);
        Assert.Equal(ProjectId, resolution.ProjectId);
        Assert.Equal("synthetic-v1", resolution.MembershipVersion);
        Assert.Contains("MigrationArchitect", resolution.Roles!);
        Assert.Equal(1, handler.RequestCount);
        Assert.Empty(logger.Entries);
    }

    [Theory]
    [InlineData("{}")]
    [InlineData("{\"value\":null}")]
    [InlineData("{\"value\":\"\"}")]
    [InlineData("{\"value\":\"   \"}")]
    [InlineData("{\"value\":")]
    [InlineData("{\"value\":\"not-json-membership-super-secret\"}")]
    public async Task Missing_null_empty_and_malformed_secret_values_fail_closed(string responseBody)
    {
        var logger = new RecordingLogger<KeyVaultProjectMembershipProvider>();
        var provider = CreateProvider(ResponseHandler(HttpStatusCode.OK, responseBody), logger);

        Assert.False(await provider.IsReadyAsync(CancellationToken.None));

        var entry = Assert.Single(logger.Entries);
        Assert.Equal("memberships", entry.Value("Dependency"));
        Assert.Equal("exception", entry.Value("Outcome"));
        Assert.DoesNotContain("membership-super-secret", entry.Message, StringComparison.Ordinal);
    }

    [Fact]
    public async Task Invalid_tenant_and_invalid_membership_remain_rejected()
    {
        var invalidTenant = LowercaseValueEnvelope.Replace(
            TenantId.ToString("D"),
            "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
            StringComparison.Ordinal);
        var invalidMembership = LowercaseValueEnvelope.Replace(
            "MigrationArchitect",
            "UnapprovedRole",
            StringComparison.Ordinal);

        foreach (var envelope in new[] { invalidTenant, invalidMembership })
        {
            var logger = new RecordingLogger<KeyVaultProjectMembershipProvider>();
            var provider = CreateProvider(ResponseHandler(HttpStatusCode.OK, envelope), logger);

            Assert.False(await provider.IsReadyAsync(CancellationToken.None));
            Assert.Equal("invalid-response", Assert.Single(logger.Entries).Value("Category"));
        }
    }

    [Fact]
    public async Task Key_Vault_HTTP_failure_is_rejected_with_bounded_redacted_diagnostics()
    {
        const string responseSecret = "membership-response-secret-must-not-be-logged";
        var logger = new RecordingLogger<KeyVaultProjectMembershipProvider>();
        var handler = ResponseHandler(HttpStatusCode.ServiceUnavailable, responseSecret);
        var provider = CreateProvider(handler, logger);

        Assert.False(await provider.IsReadyAsync(CancellationToken.None));

        var request = Assert.Single(handler.Requests);
        Assert.Equal("Bearer", request.AuthorizationScheme);
        Assert.Equal("synthetic-token-that-must-not-be-logged", request.AuthorizationParameter);
        var entry = Assert.Single(logger.Entries);
        Assert.Equal("memberships", entry.Value("Dependency"));
        Assert.Equal("exception", entry.Value("Outcome"));
        Assert.Equal("http-status", entry.Value("Category"));
        Assert.Equal("503", entry.Value("HttpStatus"));
        AssertRedacted(logger);
        Assert.DoesNotContain(responseSecret, entry.Message, StringComparison.Ordinal);
    }

    [Fact]
    public async Task Blob_false_status_and_exception_have_bounded_redacted_diagnostics()
    {
        var falseLogger = new RecordingLogger<AzureBlobImportFileStorage>();
        var falseHandler = ResponseHandler(HttpStatusCode.Forbidden, "blob-response-secret-must-not-be-logged");
        var falseProbe = CreateBlobProbe(falseHandler, falseLogger);

        Assert.False(await falseProbe.IsReadyAsync(CancellationToken.None));
        var falseEntry = Assert.Single(falseLogger.Entries);
        Assert.Equal("storage", falseEntry.Value("Dependency"));
        Assert.Equal("false", falseEntry.Value("Outcome"));
        Assert.Equal("403", falseEntry.Value("HttpStatus"));
        AssertRedacted(falseLogger);

        var exceptionLogger = new RecordingLogger<AzureBlobImportFileStorage>();
        var exceptionHandler = new StubHttpMessageHandler((_, _) => throw new HttpRequestException(
            "https://sensitive.example/container?sig=secret-token",
            null,
            HttpStatusCode.ServiceUnavailable));
        var exceptionProbe = CreateBlobProbe(exceptionHandler, exceptionLogger);

        Assert.False(await exceptionProbe.IsReadyAsync(CancellationToken.None));
        var exceptionEntry = Assert.Single(exceptionLogger.Entries);
        Assert.Equal("storage", exceptionEntry.Value("Dependency"));
        Assert.Equal("exception", exceptionEntry.Value("Outcome"));
        Assert.Equal(typeof(HttpRequestException).FullName, exceptionEntry.Value("ExceptionType"));
        Assert.Equal("503", exceptionEntry.Value("HttpStatus"));
        AssertRedacted(exceptionLogger);
    }

    [Fact]
    public async Task Readiness_false_result_keeps_order_and_identifies_memberships()
    {
        var calls = new List<string>();
        var logger = new RecordingLogger<ReadinessHealthDiagnostics>();

        var ready = await HealthEndpoints.EvaluateReadinessAsync(
            _ =>
            {
                calls.Add("sql");
                return Task.FromResult(true);
            },
            _ =>
            {
                calls.Add("memberships");
                return ValueTask.FromResult(false);
            },
            _ =>
            {
                calls.Add("storage");
                return ValueTask.FromResult(true);
            },
            logger,
            "synthetic-correlation",
            CancellationToken.None,
            TimeSpan.FromSeconds(5));

        Assert.False(ready);
        Assert.Equal(["sql", "memberships", "storage"], calls);
        var entry = Assert.Single(logger.Entries);
        Assert.Equal("ReadinessDependencyFalse", entry.EventId.Name);
        Assert.Equal("memberships", entry.Value("Dependency"));
        Assert.Equal("false", entry.Value("Outcome"));
        Assert.Equal("synthetic-correlation", entry.Value("CorrelationId"));
    }

    [Theory]
    [InlineData("sql")]
    [InlineData("memberships")]
    [InlineData("storage")]
    public async Task Readiness_exceptions_identify_dependency_and_redact_messages(string failedDependency)
    {
        const string sensitiveMessage = "Server=tcp:sensitive;Password=secret;https://sensitive.example/?token=secret";
        var logger = new RecordingLogger<ReadinessHealthDiagnostics>();
        var calls = new List<string>();

        Task<bool> Sql(CancellationToken _)
        {
            calls.Add("sql");
            return failedDependency == "sql"
                ? Task.FromException<bool>(new HttpRequestException(sensitiveMessage, null, HttpStatusCode.BadGateway))
                : Task.FromResult(true);
        }

        ValueTask<bool> Memberships(CancellationToken _)
        {
            calls.Add("memberships");
            return failedDependency == "memberships"
                ? ValueTask.FromException<bool>(new HttpRequestException(sensitiveMessage, null, HttpStatusCode.BadGateway))
                : ValueTask.FromResult(true);
        }

        ValueTask<bool> Storage(CancellationToken _)
        {
            calls.Add("storage");
            return failedDependency == "storage"
                ? ValueTask.FromException<bool>(new HttpRequestException(sensitiveMessage, null, HttpStatusCode.BadGateway))
                : ValueTask.FromResult(true);
        }

        Assert.False(await HealthEndpoints.EvaluateReadinessAsync(
            Sql,
            Memberships,
            Storage,
            logger,
            "synthetic-correlation",
            CancellationToken.None,
            TimeSpan.FromSeconds(5)));

        var entry = Assert.Single(logger.Entries);
        Assert.Equal("ReadinessDependencyException", entry.EventId.Name);
        Assert.Equal(failedDependency, entry.Value("Dependency"));
        Assert.Equal("exception", entry.Value("Outcome"));
        Assert.Equal(typeof(HttpRequestException).FullName, entry.Value("ExceptionType"));
        Assert.Equal("502", entry.Value("HttpStatus"));
        Assert.DoesNotContain(sensitiveMessage, entry.Message, StringComparison.Ordinal);
        if (failedDependency is "sql" or "memberships")
        {
            Assert.DoesNotContain("storage", calls);
        }
    }

    [Fact]
    public async Task Readiness_timeout_identifies_dependency_under_shared_budget()
    {
        var logger = new RecordingLogger<ReadinessHealthDiagnostics>();

        Assert.False(await HealthEndpoints.EvaluateReadinessAsync(
            _ => Task.FromResult(true),
            async cancellationToken =>
            {
                await Task.Delay(Timeout.InfiniteTimeSpan, cancellationToken);
                return true;
            },
            _ => ValueTask.FromResult(true),
            logger,
            "synthetic-correlation",
            CancellationToken.None,
            TimeSpan.FromMilliseconds(50)));

        var entry = Assert.Single(logger.Entries);
        Assert.Equal("ReadinessDependencyTimeout", entry.EventId.Name);
        Assert.Equal("memberships", entry.Value("Dependency"));
        Assert.Equal("timeout", entry.Value("Outcome"));
        Assert.Equal("shared-budget-timeout", entry.Value("Category"));
    }

    [Fact]
    public async Task Readiness_request_cancellation_is_not_reclassified()
    {
        var logger = new RecordingLogger<ReadinessHealthDiagnostics>();
        using var request = new CancellationTokenSource();
        request.Cancel();

        await Assert.ThrowsAnyAsync<OperationCanceledException>(async () =>
            await HealthEndpoints.EvaluateReadinessAsync(
                cancellationToken => Task.FromCanceled<bool>(cancellationToken),
                _ => ValueTask.FromResult(true),
                _ => ValueTask.FromResult(true),
                logger,
                "synthetic-correlation",
                request.Token,
                TimeSpan.FromSeconds(5)));
        Assert.Empty(logger.Entries);
    }

    private static KeyVaultProjectMembershipProvider CreateProvider(
        HttpMessageHandler handler,
        ILogger<KeyVaultProjectMembershipProvider> logger) =>
        new(
            new StubHttpClientFactory(handler),
            new StubTokenProvider(),
            Options.Create(new LgrAuthenticationOptions
            {
                Mode = InternalAuthenticationDefaults.EntraMode,
                Entra = new EntraAuthenticationOptions { TenantId = TenantId.ToString("D") }
            }),
            Options.Create(new EntraDemoMembershipOptions
            {
                SecretUri = "https://kv-mtp-dev-uks-op01.vault.azure.net/secrets/entra-demo-memberships",
                CacheSeconds = 300
            }),
            TimeProvider.System,
            logger);

    private static AzureBlobImportFileStorage CreateBlobProbe(
        HttpMessageHandler handler,
        ILogger<AzureBlobImportFileStorage> logger) =>
        new(
            Options.Create(new DiscoveryImportOptions
            {
                StorageAccountUri = "https://stmtpdevuks001.blob.core.windows.net/",
                ContainerName = "discovery-imports"
            }),
            new StubCustomerContext(),
            new StubHttpClientFactory(handler),
            new StubTokenProvider(),
            TimeProvider.System,
            logger);

    private static StubHttpMessageHandler ResponseHandler(HttpStatusCode statusCode, string responseBody) =>
        new((_, _) => Task.FromResult(new HttpResponseMessage(statusCode)
        {
            Content = new StringContent(responseBody, Encoding.UTF8, "application/json")
        }));

    private static void AssertRedacted<T>(RecordingLogger<T> logger)
    {
        Assert.All(logger.Entries, entry => Assert.Null(entry.Exception));
        var diagnostic = string.Join(
            Environment.NewLine,
            logger.Entries.Select(entry =>
                entry.Message + Environment.NewLine + string.Join('|', entry.State.Select(pair => $"{pair.Key}={pair.Value}"))));
        foreach (var forbidden in new[]
                 {
                     "synthetic-token-that-must-not-be-logged",
                     "Authorization",
                     "Password=",
                     "sig=",
                     "token=",
                     "kv-mtp-dev-uks-op01.vault.azure.net",
                     "stmtpdevuks001.blob.core.windows.net",
                     "membership-response-secret",
                     "blob-response-secret"
                 })
        {
            Assert.DoesNotContain(forbidden, diagnostic, StringComparison.OrdinalIgnoreCase);
        }
    }

    private static InternalPrincipal Principal() => new(
        PrincipalId,
        InternalPrincipalType.Human,
        "EntraId",
        TenantId,
        PrincipalId,
        Guid.Parse("55555555-5555-5555-5555-555555555555"),
        "synthetic-user",
        "Synthetic User",
        InternalAuthenticationDefaults.EntraMode,
        IsActive: true,
        ApiAccessAllowed: true);

    private sealed class StubTokenProvider : IAzureAccessTokenProvider
    {
        public ValueTask<string> GetTokenAsync(string scope, CancellationToken cancellationToken) =>
            ValueTask.FromResult("synthetic-token-that-must-not-be-logged");
    }

    private sealed class StubHttpClientFactory(HttpMessageHandler handler) : IHttpClientFactory
    {
        private readonly HttpClient client = new(handler, disposeHandler: false);

        public HttpClient CreateClient(string name) => client;
    }

    private sealed class StubHttpMessageHandler(
        Func<HttpRequestMessage, CancellationToken, Task<HttpResponseMessage>> responseFactory)
        : HttpMessageHandler
    {
        public int RequestCount { get; private set; }
        public List<CapturedRequest> Requests { get; } = [];

        public StubHttpMessageHandler(Func<HttpRequestMessage, HttpResponseMessage> responseFactory)
            : this((request, _) => Task.FromResult(responseFactory(request)))
        {
        }

        protected override async Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken)
        {
            RequestCount++;
            Requests.Add(new CapturedRequest(
                request.RequestUri,
                request.Headers.Authorization?.Scheme,
                request.Headers.Authorization?.Parameter));
            return await responseFactory(request, cancellationToken);
        }
    }

    private sealed record CapturedRequest(
        Uri? Uri,
        string? AuthorizationScheme,
        string? AuthorizationParameter);

    private sealed class StubCustomerContext : ICurrentCustomerContext
    {
        public Guid CustomerId => CustomerIdValue;
        public Guid ProjectId => ProjectIdValue;
        public string UserName => "synthetic-user";
        public string CorrelationId => "synthetic-correlation";
        public InternalPrincipal Principal => AzureDemoInfrastructureTests.Principal();

        private static Guid CustomerIdValue => AzureDemoInfrastructureTests.CustomerId;
        private static Guid ProjectIdValue => AzureDemoInfrastructureTests.ProjectId;
    }

    internal sealed record LogEntry(
        LogLevel Level,
        EventId EventId,
        string Message,
        IReadOnlyDictionary<string, object?> State,
        Exception? Exception)
    {
        public string? Value(string key) => State.TryGetValue(key, out var value) ? value?.ToString() : null;
    }

    internal sealed class RecordingLogger<T> : ILogger<T>
    {
        public List<LogEntry> Entries { get; } = [];

        public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;

        public bool IsEnabled(LogLevel logLevel) => true;

        public void Log<TState>(
            LogLevel logLevel,
            EventId eventId,
            TState state,
            Exception? exception,
            Func<TState, Exception?, string> formatter)
        {
            var properties = state is IEnumerable<KeyValuePair<string, object?>> structured
                ? structured.ToDictionary(pair => pair.Key, pair => pair.Value, StringComparer.Ordinal)
                : new Dictionary<string, object?>(StringComparer.Ordinal);
            Entries.Add(new LogEntry(logLevel, eventId, formatter(state, exception), properties, exception));
        }
    }
}
