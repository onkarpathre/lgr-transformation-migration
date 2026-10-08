namespace LgrTransformationMigration.Api.Services.Discovery;

public sealed class DiscoveryImportOptions
{
    public const string SectionName = "DiscoveryImport";

    public long MaximumFileSizeBytes { get; set; } = 25 * 1024 * 1024;
    public string StorageMode { get; set; } = "Local";
    public string LocalStoragePath { get; set; } = "runtime/imports";
    public int FreshnessThresholdDays { get; set; } = 30;
    public string StorageAccountUri { get; set; } = string.Empty;
    public string ContainerName { get; set; } = string.Empty;
    public int MalwareScanTimeoutSeconds { get; set; } = 120;
    public int MalwareScanPollSeconds { get; set; } = 2;
}
