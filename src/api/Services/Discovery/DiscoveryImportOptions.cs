namespace LgrTransformationMigration.Api.Services.Discovery;

public sealed class DiscoveryImportOptions
{
    public const string SectionName = "DiscoveryImport";

    public long MaximumFileSizeBytes { get; set; } = 25 * 1024 * 1024;
    public string LocalStoragePath { get; set; } = "runtime/imports";
    public int FreshnessThresholdDays { get; set; } = 30;
}
