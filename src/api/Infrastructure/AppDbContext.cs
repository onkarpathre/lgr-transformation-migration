using LgrTransformationMigration.Api.Domain;
using Microsoft.EntityFrameworkCore;

namespace LgrTransformationMigration.Api.Infrastructure;

public sealed class AppDbContext(
    DbContextOptions<AppDbContext> options,
    ICurrentCustomerContext currentContext) : DbContext(options)
{
    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<Project> Projects => Set<Project>();
    public DbSet<Application> Applications => Set<Application>();
    public DbSet<Server> Servers => Set<Server>();
    public DbSet<ApplicationServer> ApplicationServers => Set<ApplicationServer>();
    public DbSet<MigrationDecision> MigrationDecisions => Set<MigrationDecision>();
    public DbSet<AzureTarget> AzureTargets => Set<AzureTarget>();
    public DbSet<Subnet> Subnets => Set<Subnet>();
    public DbSet<IpAddress> IpAddresses => Set<IpAddress>();
    public DbSet<MigrationWave> MigrationWaves => Set<MigrationWave>();
    public DbSet<WaveAsset> WaveAssets => Set<WaveAsset>();
    public DbSet<ReadinessCheck> ReadinessChecks => Set<ReadinessCheck>();
    public DbSet<Runbook> Runbooks => Set<Runbook>();
    public DbSet<RunbookTask> RunbookTasks => Set<RunbookTask>();
    public DbSet<AuditEvent> AuditEvents => Set<AuditEvent>();
    public DbSet<LookupOption> LookupOptions => Set<LookupOption>();
    public DbSet<ImportBatch> ImportBatches => Set<ImportBatch>();
    public DbSet<DiscoveryImportRow> DiscoveryImportRows => Set<DiscoveryImportRow>();
    public DbSet<ServerDiscoverySnapshot> ServerDiscoverySnapshots => Set<ServerDiscoverySnapshot>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Customer>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Name).HasMaxLength(200).IsRequired();
            entity.Property(x => x.Code).HasMaxLength(50).IsRequired();
            entity.Property(x => x.Status).HasMaxLength(50).IsRequired();
            entity.HasIndex(x => x.Code).IsUnique();
            entity.HasQueryFilter(x => x.Id == currentContext.CustomerId);
        });

        modelBuilder.Entity<Project>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Name).HasMaxLength(200).IsRequired();
            entity.Property(x => x.Status).HasMaxLength(50).IsRequired();
            entity.HasIndex(x => x.CustomerId);
            entity.HasOne(x => x.Customer).WithMany(x => x.Projects).HasForeignKey(x => x.CustomerId).OnDelete(DeleteBehavior.Restrict);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<Application>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Name).HasMaxLength(200).IsRequired();
            ConfigureBusinessStrings(entity);
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId });
            entity.HasOne(x => x.Project).WithMany().HasForeignKey(x => x.ProjectId).OnDelete(DeleteBehavior.Restrict);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<Server>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Hostname).HasMaxLength(253).IsRequired();
            entity.Property(x => x.IpAddress).HasMaxLength(45);
            ConfigureBusinessStrings(entity);
            entity.HasIndex(x => new { x.CustomerId, x.Hostname }).IsUnique();
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId });
            entity.HasIndex(x => x.LastImportBatchId);
            entity.HasOne(x => x.Project).WithMany().HasForeignKey(x => x.ProjectId).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.LastImportBatch).WithMany().HasForeignKey(x => x.LastImportBatchId).OnDelete(DeleteBehavior.Restrict);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<ApplicationServer>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.CustomerId, x.ApplicationId, x.ServerId }).IsUnique();
            entity.HasOne(x => x.Application).WithMany(x => x.ApplicationServers).HasForeignKey(x => x.ApplicationId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.Server).WithMany(x => x.ApplicationServers).HasForeignKey(x => x.ServerId).OnDelete(DeleteBehavior.Cascade);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<MigrationDecision>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId });
            entity.HasOne(x => x.Application).WithMany().HasForeignKey(x => x.ApplicationId).OnDelete(DeleteBehavior.Restrict);
            ConfigureBusinessStrings(entity);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<AzureTarget>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.HasIndex(x => new { x.CustomerId, x.ServerId }).IsUnique();
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId });
            entity.HasOne(x => x.Server).WithOne(x => x.AzureTarget).HasForeignKey<AzureTarget>(x => x.ServerId).OnDelete(DeleteBehavior.Restrict);
            ConfigureBusinessStrings(entity);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<Subnet>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Name).HasMaxLength(100).IsRequired();
            entity.Property(x => x.VNetName).HasMaxLength(100).IsRequired();
            entity.Property(x => x.Cidr).HasMaxLength(50).IsRequired();
            entity.Property(x => x.Environment).HasMaxLength(50).IsRequired();
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.Name }).IsUnique();
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<IpAddress>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Address).HasMaxLength(45).IsRequired();
            entity.Property(x => x.Status).HasMaxLength(50).IsRequired();
            entity.HasIndex(x => new { x.CustomerId, x.SubnetId, x.Address }).IsUnique();
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.Status });
            entity.HasIndex(x => new { x.CustomerId, x.ServerId })
                .IsUnique()
                .HasFilter("[ServerId] IS NOT NULL AND [Status] IN ('Reserved', 'Allocated')");
            entity.HasOne(x => x.Subnet).WithMany(x => x.IpAddresses).HasForeignKey(x => x.SubnetId).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.Server).WithMany().HasForeignKey(x => x.ServerId).OnDelete(DeleteBehavior.Restrict);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<MigrationWave>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Name).HasMaxLength(150).IsRequired();
            entity.Property(x => x.Status).HasMaxLength(50).IsRequired();
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId });
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<WaveAsset>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Status).HasMaxLength(50).IsRequired();
            entity.HasIndex(x => new { x.CustomerId, x.MigrationWaveId });
            entity.ToTable(t => t.HasCheckConstraint("CK_WaveAsset_Asset", "[ApplicationId] IS NOT NULL OR [ServerId] IS NOT NULL"));
            entity.HasOne(x => x.MigrationWave).WithMany(x => x.Assets).HasForeignKey(x => x.MigrationWaveId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.Application).WithMany().HasForeignKey(x => x.ApplicationId).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.Server).WithMany().HasForeignKey(x => x.ServerId).OnDelete(DeleteBehavior.Restrict);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<ReadinessCheck>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.CheckType).HasMaxLength(100).IsRequired();
            entity.Property(x => x.Status).HasMaxLength(50).IsRequired();
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId });
            entity.ToTable(t => t.HasCheckConstraint("CK_ReadinessCheck_Asset", "[ApplicationId] IS NOT NULL OR [ServerId] IS NOT NULL"));
            entity.HasOne(x => x.Application).WithMany().HasForeignKey(x => x.ApplicationId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.Server).WithMany().HasForeignKey(x => x.ServerId).OnDelete(DeleteBehavior.Cascade);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<Runbook>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Name).HasMaxLength(200).IsRequired();
            entity.Property(x => x.Status).HasMaxLength(50).IsRequired();
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId });
            entity.HasOne(x => x.MigrationWave).WithMany().HasForeignKey(x => x.MigrationWaveId).OnDelete(DeleteBehavior.Restrict);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<RunbookTask>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Category).HasMaxLength(100).IsRequired();
            entity.Property(x => x.Task).HasMaxLength(500).IsRequired();
            entity.Property(x => x.Status).HasMaxLength(50).IsRequired();
            entity.HasIndex(x => new { x.RunbookId, x.Sequence }).IsUnique();
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId });
            entity.HasOne(x => x.Runbook).WithMany(x => x.Tasks).HasForeignKey(x => x.RunbookId).OnDelete(DeleteBehavior.Cascade);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<AuditEvent>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.EntityType).HasMaxLength(100).IsRequired();
            entity.Property(x => x.Action).HasMaxLength(50).IsRequired();
            entity.Property(x => x.ChangedBy).HasMaxLength(200).IsRequired();
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.ChangedAt });
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<LookupOption>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Group).HasMaxLength(100).IsRequired();
            entity.Property(x => x.Value).HasMaxLength(100).IsRequired();
            entity.Property(x => x.DisplayName).HasMaxLength(150).IsRequired();
            entity.HasIndex(x => new { x.CustomerId, x.Group, x.Value }).IsUnique();
            entity.HasQueryFilter(x => x.CustomerId == null || x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<ImportBatch>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.SourceType).HasMaxLength(80).IsRequired();
            entity.Property(x => x.OriginalFileName).HasMaxLength(260).IsRequired();
            entity.Property(x => x.StoredFileName).HasMaxLength(260);
            entity.Property(x => x.FileHash).HasMaxLength(64).IsRequired();
            entity.Property(x => x.Status).HasMaxLength(50).IsRequired();
            entity.Property(x => x.UploadedBy).HasMaxLength(200).IsRequired();
            entity.Property(x => x.Notes).HasMaxLength(2000);
            entity.HasIndex(x => x.CustomerId);
            entity.HasIndex(x => x.ProjectId);
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.UploadedAt });
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.Status });
            entity.HasIndex(x => new { x.CustomerId, x.FileHash });
            entity.HasOne(x => x.Project).WithMany().HasForeignKey(x => x.ProjectId).OnDelete(DeleteBehavior.Restrict);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<DiscoveryImportRow>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.SourceRecordId).HasMaxLength(500);
            entity.Property(x => x.SourceType).HasMaxLength(80).IsRequired();
            entity.Property(x => x.RawDataJson).IsRequired();
            entity.Property(x => x.NormalizedHostname).HasMaxLength(253);
            entity.Property(x => x.Classification).HasMaxLength(50).IsRequired();
            entity.Property(x => x.ValidationStatus).HasMaxLength(50).IsRequired();
            entity.Property(x => x.ValidationMessagesJson);
            entity.Property(x => x.ProposedChangesJson);
            entity.HasIndex(x => x.CustomerId);
            entity.HasIndex(x => x.ProjectId);
            entity.HasIndex(x => x.ImportBatchId);
            entity.HasIndex(x => new { x.ImportBatchId, x.RowNumber }).IsUnique();
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.Classification });
            entity.HasOne(x => x.ImportBatch).WithMany(x => x.Rows).HasForeignKey(x => x.ImportBatchId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.MatchedServer).WithMany().HasForeignKey(x => x.MatchedEntityId).OnDelete(DeleteBehavior.Restrict);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<ServerDiscoverySnapshot>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Hostname).HasMaxLength(253).IsRequired();
            entity.Property(x => x.ExternalSourceId).HasMaxLength(500);
            ConfigureBusinessStrings(entity);
            entity.Property(x => x.IpAddresses).HasMaxLength(2000);
            entity.Property(x => x.Dependencies).HasMaxLength(4000);
            entity.Property(x => x.ApplicationNames).HasMaxLength(4000);
            entity.Property(x => x.Tags).HasMaxLength(4000);
            entity.HasIndex(x => x.CustomerId);
            entity.HasIndex(x => x.ProjectId);
            entity.HasIndex(x => x.ImportBatchId);
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.ServerId, x.ImportedAt });
            entity.HasOne(x => x.Server).WithMany(x => x.DiscoverySnapshots).HasForeignKey(x => x.ServerId).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.ImportBatch).WithMany(x => x.ServerSnapshots).HasForeignKey(x => x.ImportBatchId).OnDelete(DeleteBehavior.Restrict);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        SeedData.Configure(modelBuilder);
    }

    private static void ConfigureBusinessStrings<TEntity>(Microsoft.EntityFrameworkCore.Metadata.Builders.EntityTypeBuilder<TEntity> entity)
        where TEntity : class
    {
        foreach (var property in entity.Metadata.GetProperties().Where(x => x.ClrType == typeof(string) && x.GetMaxLength() is null))
        {
            property.SetMaxLength(500);
        }
    }
}
