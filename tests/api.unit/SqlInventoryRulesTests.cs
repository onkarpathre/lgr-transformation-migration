using LgrTransformationMigration.Api.Domain;

namespace LgrTransformationMigration.Api.UnitTests;

public sealed class SqlInventoryRulesTests
{
    [Theory]
    [InlineData("MSSQLSERVER")]
    [InlineData("default")]
    [InlineData(" (DEFAULT) ")]
    public void Default_instance_aliases_share_one_normalized_identity(string value)
    {
        Assert.Equal("MSSQLSERVER", SqlInventoryNormalizer.NormalizeInstanceName(value));
    }

    [Fact]
    public void Business_names_are_trimmed_normalized_to_form_c_and_case_folded()
    {
        var decomposed = " Cafe\u0301 ";

        Assert.Equal("CAFÉ", SqlInventoryNormalizer.NormalizeDatabaseName(decomposed));
    }

    [Theory]
    [InlineData("bulk logged")]
    [InlineData("Bulk-Logged")]
    [InlineData("BULK_LOGGED")]
    public void Recovery_model_aliases_are_normalized(string value)
    {
        Assert.Equal(SqlDatabaseRecoveryModels.BulkLogged, SqlInventoryNormalizer.NormalizeRecoveryModel(value));
    }

    [Theory]
    [InlineData("recovery pending")]
    [InlineData("Recovery_Pending")]
    [InlineData("RECOVERY-PENDING")]
    public void Database_status_aliases_are_normalized(string value)
    {
        Assert.Equal(SqlDatabaseStatuses.RecoveryPending, SqlInventoryNormalizer.NormalizeDatabaseStatus(value));
    }

    [Theory]
    [InlineData("DOMAIN\\sql-service")]
    [InlineData("sql.service@example.test")]
    [InlineData("NT SERVICE\\MSSQLSERVER")]
    public void Safe_service_account_display_names_are_accepted(string value)
    {
        Assert.Equal(value, SqlInventoryNormalizer.NormalizeServiceAccountName(value));
    }

    [Theory]
    [InlineData("Server=synthetic;Password=not-a-secret")]
    [InlineData("https://example.test/account")]
    [InlineData("name\npassword")]
    public void Credential_like_service_account_content_is_rejected(string value)
    {
        Assert.Throws<DomainValidationException>(() => SqlInventoryNormalizer.NormalizeServiceAccountName(value));
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    public void Blank_inventory_names_are_rejected(string value)
    {
        Assert.Throws<DomainValidationException>(() => SqlInventoryNormalizer.NormalizeInstanceName(value));
        Assert.Throws<DomainValidationException>(() => SqlInventoryNormalizer.NormalizeDatabaseName(value));
    }
}
