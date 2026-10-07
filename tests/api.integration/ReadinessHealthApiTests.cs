using System.Net;
using System.Text.Json;
using LgrTransformationMigration.Api.Infrastructure;
using LgrTransformationMigration.Api.Services.Discovery;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace LgrTransformationMigration.Api.IntegrationTests;

public sealed class ReadinessHealthApiTests
{
    [Fact]
    public async Task Ready_endpoint_returns_only_generic_healthy_response()
    {
        using var baseFactory = new LgrWebApplicationFactory();
        using var factory = Configure(baseFactory, new StubReadiness(true), new StubReadiness(true));
        using var client = factory.CreateClient();

        using var response = await client.GetAsync("/health/ready");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        AssertGenericStatus(await response.Content.ReadAsStringAsync(), "Healthy");
    }

    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task Ready_endpoint_returns_only_generic_unavailable_response(bool throwFromStorage)
    {
        using var baseFactory = new LgrWebApplicationFactory();
        var memberships = throwFromStorage ? new StubReadiness(true) : new StubReadiness(false);
        var storage = throwFromStorage
            ? new StubReadiness(new InvalidOperationException("Password=secret;https://sensitive.example/?token=secret"))
            : new StubReadiness(true);
        using var factory = Configure(baseFactory, memberships, storage);
        using var client = factory.CreateClient();

        using var response = await client.GetAsync("/health/ready");

        Assert.Equal(HttpStatusCode.ServiceUnavailable, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        AssertGenericStatus(body, "Unavailable");
        Assert.DoesNotContain("memberships", body, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("storage", body, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("secret", body, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("SqlNumber", body, StringComparison.Ordinal);
        Assert.DoesNotContain("SqlState", body, StringComparison.Ordinal);
        Assert.DoesNotContain("SqlClass", body, StringComparison.Ordinal);
        Assert.DoesNotContain("SqlError", body, StringComparison.Ordinal);
    }

    private static WebApplicationFactory<Program> Configure(
        LgrWebApplicationFactory factory,
        IProjectMembershipReadiness memberships,
        IImportStorageReadiness storage) =>
        factory.WithWebHostBuilder(builder => builder.ConfigureServices(services =>
        {
            services.RemoveAll<IProjectMembershipReadiness>();
            services.RemoveAll<IImportStorageReadiness>();
            services.AddSingleton(memberships);
            services.AddSingleton(storage);
        }));

    private static void AssertGenericStatus(string json, string expected)
    {
        using var document = JsonDocument.Parse(json);
        var properties = document.RootElement.EnumerateObject().ToList();
        var property = Assert.Single(properties);
        Assert.Equal("status", property.Name);
        Assert.Equal(expected, property.Value.GetString());
    }

    private sealed class StubReadiness : IProjectMembershipReadiness, IImportStorageReadiness
    {
        private readonly bool result;
        private readonly Exception? exception;

        public StubReadiness(bool result) => this.result = result;

        public StubReadiness(Exception exception) => this.exception = exception;

        public ValueTask<bool> IsReadyAsync(CancellationToken cancellationToken) =>
            exception is null
                ? ValueTask.FromResult(result)
                : ValueTask.FromException<bool>(exception);
    }
}
