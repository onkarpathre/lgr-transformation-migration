using System.Security.Claims;
using LgrTransformationMigration.Api.Infrastructure;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Protocols.OpenIdConnect;
using Microsoft.IdentityModel.Tokens;

namespace LgrTransformationMigration.Api.UnitTests;

public sealed class IdentityAuthorizationTests
{
    private static readonly Guid TenantId = Guid.Parse("10000000-0000-0000-0000-000000000001");
    private static readonly Guid ObjectId = Guid.Parse("20000000-0000-0000-0000-000000000002");
    private static readonly Guid ClientId = Guid.Parse("30000000-0000-0000-0000-000000000003");
    private const string Issuer = "https://login.microsoftonline.com/10000000-0000-0000-0000-000000000001/v2.0";
    private const string Audience = "api://lgr-synthetic-test";

    [Theory]
    [InlineData("DatabaseSme", true, true, true, true)]
    [InlineData("MigrationArchitect", true, false, false, false)]
    [InlineData("ProjectManager", true, false, false, false)]
    [InlineData("DiscoveryAnalyst", true, false, false, false)]
    [InlineData("ReviewerAuditor", true, false, false, false)]
    [InlineData("CustomerAdministrator", false, false, false, false)]
    [InlineData("PlatformAdministrator", false, false, false, false)]
    [InlineData("UnexpectedRole", false, false, false, false)]
    public void Sql_inventory_role_mapping_is_exact_and_deny_by_default(
        string role,
        bool read,
        bool create,
        bool update,
        bool delete)
    {
        var permissions = SqlInventoryPermissions.ForRoles([role]);

        Assert.Equal(read, permissions.Contains(SqlInventoryPermissions.Read));
        Assert.Equal(create, permissions.Contains(SqlInventoryPermissions.Create));
        Assert.Equal(update, permissions.Contains(SqlInventoryPermissions.Update));
        Assert.Equal(delete, permissions.Contains(SqlInventoryPermissions.Delete));
    }

    [Fact]
    public void Multiple_roles_produce_only_the_documented_union()
    {
        var readOnly = SqlInventoryPermissions.ForRoles(["ReviewerAuditor", "UnexpectedRole"]);
        var databaseSme = SqlInventoryPermissions.ForRoles(["ReviewerAuditor", "DatabaseSme"]);

        Assert.True(readOnly.SetEquals([SqlInventoryPermissions.Read]));
        Assert.True(databaseSme.SetEquals(
            [
                SqlInventoryPermissions.Read,
                SqlInventoryPermissions.Create,
                SqlInventoryPermissions.Update,
                SqlInventoryPermissions.Delete
            ]));
    }

    [Fact]
    public async Task Entra_token_validator_accepts_a_correctly_signed_v2_api_token()
    {
        var signingKey = SigningKey();
        var validator = Validator(signingKey);
        var token = Token(signingKey);

        var validated = await validator.ValidateAsync(token, CancellationToken.None);
        var principal = EntraInternalPrincipalMapper.Map(validated, EntraOptions());

        Assert.Equal(InternalPrincipalType.Human, principal.PrincipalType);
        Assert.True(principal.ApiAccessAllowed);
        Assert.Equal(TenantId, principal.DirectoryTenantId);
        Assert.Equal(ObjectId, principal.DirectoryObjectId);
        Assert.Equal(ClientId, principal.ClientApplicationId);
        Assert.Equal($"entra:{TenantId:D}:{ObjectId:D}", principal.AuditActor);
    }

    [Theory]
    [InlineData("wrong-issuer")]
    [InlineData("wrong-audience")]
    [InlineData("expired")]
    [InlineData("not-yet-valid")]
    [InlineData("invalid-signature")]
    public async Task Entra_token_validator_rejects_invalid_cryptographic_or_lifetime_contract(string variation)
    {
        var signingKey = SigningKey();
        var tokenKey = variation == "invalid-signature" ? SigningKey(0x44) : signingKey;
        var token = Token(
            tokenKey,
            issuer: variation == "wrong-issuer" ? "https://issuer.invalid/v2.0" : Issuer,
            audience: variation == "wrong-audience" ? "api://wrong-audience" : Audience,
            notBefore: variation == "not-yet-valid" ? DateTime.UtcNow.AddHours(1) : DateTime.UtcNow.AddMinutes(-1),
            expires: variation == "expired" ? DateTime.UtcNow.AddMinutes(-5) : DateTime.UtcNow.AddMinutes(30));

        await Assert.ThrowsAnyAsync<SecurityTokenException>(
            () => Validator(signingKey).ValidateAsync(token, CancellationToken.None));
    }

    [Theory]
    [InlineData("missing-oid")]
    [InlineData("malformed-oid")]
    [InlineData("wrong-tid")]
    [InlineData("v1-token")]
    public async Task Entra_principal_mapping_rejects_invalid_required_claims(string variation)
    {
        var claims = HumanClaims().ToList();
        if (variation == "missing-oid")
        {
            claims.RemoveAll(claim => claim.Type == "oid");
        }
        else if (variation == "malformed-oid")
        {
            ReplaceClaim(claims, "oid", "not-a-guid");
        }
        else if (variation == "wrong-tid")
        {
            ReplaceClaim(claims, "tid", Guid.NewGuid().ToString("D"));
        }
        else
        {
            ReplaceClaim(claims, "ver", "1.0");
        }

        await Assert.ThrowsAsync<SecurityTokenValidationException>(() => Task.Run(() =>
            EntraInternalPrincipalMapper.Map(Principal(claims), EntraOptions())));
    }

    [Theory]
    [InlineData("missing-scope")]
    [InlineData("disallowed-client")]
    [InlineData("workload")]
    [InlineData("mixed-human-workload")]
    public void Validated_identity_without_approved_human_api_access_is_authenticated_but_not_authorized(
        string variation)
    {
        var claims = HumanClaims().ToList();
        if (variation == "missing-scope" || variation == "workload")
        {
            claims.RemoveAll(claim => claim.Type == "scp");
        }

        if (variation == "disallowed-client")
        {
            ReplaceClaim(claims, "azp", Guid.NewGuid().ToString("D"));
        }

        if (variation is "workload" or "mixed-human-workload")
        {
            claims.Add(new Claim("roles", "Lgr.Api.Service"));
            ReplaceClaim(claims, "sub", ObjectId.ToString("D"));
        }

        var mapped = EntraInternalPrincipalMapper.Map(Principal(claims), EntraOptions());

        Assert.False(mapped.ApiAccessAllowed);
        Assert.Equal(
            variation == "workload" ? InternalPrincipalType.Workload : InternalPrincipalType.Human,
            mapped.PrincipalType);
    }

    private static MicrosoftEntraAccessTokenValidator Validator(SecurityKey signingKey)
    {
        var configuration = new OpenIdConnectConfiguration { Issuer = Issuer };
        configuration.SigningKeys.Add(signingKey);
        return new MicrosoftEntraAccessTokenValidator(
            Options.Create(new LgrAuthenticationOptions { Entra = EntraOptions() }),
            new FixedOpenIdConfigurationProvider(configuration));
    }

    private static EntraAuthenticationOptions EntraOptions() => new()
    {
        TenantId = TenantId.ToString("D"),
        Issuer = Issuer,
        Audience = Audience,
        AllowedClientIds = [ClientId.ToString("D")]
    };

    private static string Token(
        SecurityKey signingKey,
        string issuer = Issuer,
        string audience = Audience,
        DateTime? notBefore = null,
        DateTime? expires = null)
    {
        var descriptor = new SecurityTokenDescriptor
        {
            Issuer = issuer,
            Audience = audience,
            NotBefore = notBefore ?? DateTime.UtcNow.AddMinutes(-1),
            Expires = expires ?? DateTime.UtcNow.AddMinutes(30),
            SigningCredentials = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256),
            Claims = HumanClaims().ToDictionary(claim => claim.Type, claim => (object)claim.Value)
        };
        return new JsonWebTokenHandler().CreateToken(descriptor);
    }

    private static IEnumerable<Claim> HumanClaims()
    {
        yield return new Claim("tid", TenantId.ToString("D"));
        yield return new Claim("oid", ObjectId.ToString("D"));
        yield return new Claim("azp", ClientId.ToString("D"));
        yield return new Claim("sub", "synthetic-subject");
        yield return new Claim("ver", "2.0");
        yield return new Claim("scp", "lgr.access");
        yield return new Claim("name", "Synthetic Internal User");
    }

    private static ClaimsPrincipal Principal(IEnumerable<Claim> claims) =>
        new(new ClaimsIdentity(claims, "ValidatedBearer"));

    private static void ReplaceClaim(List<Claim> claims, string type, string value)
    {
        claims.RemoveAll(claim => claim.Type == type);
        claims.Add(new Claim(type, value));
    }

    private static SymmetricSecurityKey SigningKey(byte value = 0x31) =>
        new(Enumerable.Repeat(value, 64).ToArray());

    private sealed class FixedOpenIdConfigurationProvider(OpenIdConnectConfiguration configuration)
        : IEntraOpenIdConfigurationProvider
    {
        public Task<OpenIdConnectConfiguration> GetAsync(CancellationToken cancellationToken) =>
            Task.FromResult(configuration);
    }
}
