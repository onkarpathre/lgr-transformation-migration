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
    public DbSet<SqlInstance> SqlInstances => Set<SqlInstance>();
    public DbSet<SqlDatabase> SqlDatabases => Set<SqlDatabase>();
    public DbSet<SqlInstanceDiscoverySnapshot> SqlInstanceDiscoverySnapshots => Set<SqlInstanceDiscoverySnapshot>();
    public DbSet<SqlDatabaseDiscoverySnapshot> SqlDatabaseDiscoverySnapshots => Set<SqlDatabaseDiscoverySnapshot>();
    public DbSet<SqlAssessment> SqlAssessments => Set<SqlAssessment>();
    public DbSet<DependencyReference> DependencyReferences => Set<DependencyReference>();
    public DbSet<Dependency> Dependencies => Set<Dependency>();
    public DbSet<DependencyPolicy> DependencyPolicies => Set<DependencyPolicy>();
    public DbSet<DependencyPolicyRule> DependencyPolicyRules => Set<DependencyPolicyRule>();
    public DbSet<DependencyGraphState> DependencyGraphStates => Set<DependencyGraphState>();

    public override int SaveChanges(bool acceptAllChangesOnSuccess)
    {
        EnforceAppendOnlyDiscoveryHistory();
        return base.SaveChanges(acceptAllChangesOnSuccess);
    }

    public override Task<int> SaveChangesAsync(
        bool acceptAllChangesOnSuccess,
        CancellationToken cancellationToken = default)
    {
        EnforceAppendOnlyDiscoveryHistory();
        return base.SaveChangesAsync(acceptAllChangesOnSuccess, cancellationToken);
    }

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
            entity.HasAlternateKey(x => new { x.CustomerId, x.Id }).HasName("AK_Projects_CustomerId_Id");
            entity.Property(x => x.Name).HasMaxLength(200).IsRequired();
            entity.Property(x => x.Status).HasMaxLength(50).IsRequired();
            entity.HasIndex(x => x.CustomerId);
            entity.HasOne(x => x.Customer).WithMany(x => x.Projects).HasForeignKey(x => x.CustomerId).OnDelete(DeleteBehavior.Restrict);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<Application>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.HasAlternateKey(x => new { x.CustomerId, x.ProjectId, x.Id })
                .HasName("AK_Applications_CustomerId_ProjectId_Id");
            entity.Property(x => x.Name).HasMaxLength(200).IsRequired();
            ConfigureBusinessStrings(entity);
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId });
            entity.HasOne(x => x.Project).WithMany().HasForeignKey(x => x.ProjectId).OnDelete(DeleteBehavior.Restrict);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<Server>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.HasAlternateKey(x => new { x.CustomerId, x.ProjectId, x.Id })
                .HasName("AK_Servers_CustomerId_ProjectId_Id");
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
            entity.Property(x => x.ActorPrincipalType).HasMaxLength(20);
            entity.Property(x => x.CorrelationId).HasMaxLength(100);
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
            entity.HasAlternateKey(x => new { x.CustomerId, x.ProjectId, x.Id })
                .HasName("AK_ImportBatches_CustomerId_ProjectId_Id");
            entity.Property(x => x.SourceType).HasMaxLength(80).IsRequired();
            entity.Property(x => x.OriginalFileName).HasMaxLength(260).IsRequired();
            entity.Property(x => x.StoredFileName).HasMaxLength(260);
            entity.Property(x => x.FileHash).HasMaxLength(64).IsRequired();
            entity.Property(x => x.Status).HasMaxLength(50).IsRequired();
            entity.Property(x => x.UploadedBy).HasMaxLength(200).IsRequired();
            entity.Property(x => x.Notes).HasMaxLength(2000);
            entity.Property(x => x.CommitIdempotencyKeyHash).HasMaxLength(64).IsFixedLength();
            entity.Property(x => x.CommitResultJson).HasMaxLength(2000);
            ConfigureRowVersion(entity.Property(x => x.RowVersion));
            entity.HasIndex(x => x.CustomerId);
            entity.HasIndex(x => x.ProjectId);
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.UploadedAt });
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.Status });
            entity.HasIndex(x => new { x.CustomerId, x.FileHash });
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.CommitIdempotencyKeyHash })
                .HasDatabaseName("IX_ImportBatches_Owner_CommitIdempotencyKeyHash")
                .HasFilter("[CommitIdempotencyKeyHash] IS NOT NULL");
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
            entity.Property(x => x.NormalizedInstanceName).HasMaxLength(128);
            entity.Property(x => x.NormalizedDatabaseName).HasMaxLength(128);
            entity.Property(x => x.Classification).HasMaxLength(50).IsRequired();
            entity.Property(x => x.ProposedAction).HasMaxLength(20);
            entity.Property(x => x.ValidationStatus).HasMaxLength(50).IsRequired();
            entity.Property(x => x.ValidationMessagesJson);
            entity.Property(x => x.ProposedChangesJson);
            entity.Property(x => x.ReconciliationFingerprint).HasMaxLength(64).IsFixedLength();
            entity.HasIndex(x => x.CustomerId);
            entity.HasIndex(x => x.ProjectId);
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.ImportBatchId, x.RowNumber }).IsUnique();
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.Classification });
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.NormalizedHostname, x.NormalizedInstanceName })
                .HasDatabaseName("IX_DiscoveryImportRows_Owner_InstanceMatch");
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.MatchedSqlInstanceId, x.NormalizedDatabaseName })
                .HasDatabaseName("IX_DiscoveryImportRows_Owner_DatabaseMatch");
            entity.HasOne(x => x.ImportBatch)
                .WithMany(x => x.Rows)
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.ImportBatchId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id })
                .OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(x => x.MatchedServer).WithMany().HasForeignKey(x => x.MatchedEntityId).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.MatchedSqlInstance)
                .WithMany()
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.MatchedSqlInstanceId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id })
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.MatchedSqlDatabase)
                .WithMany()
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.MatchedSqlDatabaseId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id })
                .OnDelete(DeleteBehavior.Restrict);
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

        modelBuilder.Entity<SqlInstance>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.HasAlternateKey(x => new { x.CustomerId, x.ProjectId, x.Id })
                .HasName("AK_SqlInstances_CustomerId_ProjectId_Id");
            entity.Property(x => x.InstanceName).HasMaxLength(128).IsRequired();
            entity.Property(x => x.NormalizedInstanceName).HasMaxLength(128).IsRequired();
            entity.Property(x => x.SqlVersion).HasMaxLength(100).IsRequired();
            entity.Property(x => x.Edition).HasMaxLength(100).IsRequired();
            entity.Property(x => x.ServiceStatus).HasMaxLength(50).IsRequired();
            entity.Property(x => x.DiscoverySource).HasMaxLength(100).IsRequired();
            entity.Property(x => x.ServiceAccountName).HasMaxLength(256);
            entity.Property(x => x.CreatedBy).HasMaxLength(200).IsRequired();
            entity.Property(x => x.UpdatedBy).HasMaxLength(200).IsRequired();
            entity.Property(x => x.DeletedBy).HasMaxLength(200);
            ConfigureRowVersion(entity.Property(x => x.RowVersion));
            entity.ToTable(table => table.HasCheckConstraint(
                "CK_SqlInstances_Port",
                "[Port] IS NULL OR ([Port] >= 1 AND [Port] <= 65535)"));
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.ServerId, x.NormalizedInstanceName })
                .IsUnique()
                .HasDatabaseName("UX_SqlInstances_Owner_Server_NormalizedName_Active")
                .HasFilter("[IsDeleted] = 0");
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.IsDeleted, x.NormalizedInstanceName })
                .HasDatabaseName("IX_SqlInstances_Owner_Active_Name");
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.IsDeleted, x.ServiceStatus })
                .HasDatabaseName("IX_SqlInstances_Owner_Active_ServiceStatus");
            entity.HasOne(x => x.Project)
                .WithMany()
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId })
                .HasPrincipalKey(x => new { x.CustomerId, x.Id })
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.Server)
                .WithMany(x => x.SqlInstances)
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.ServerId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id })
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.LastImportBatch)
                .WithMany()
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.LastImportBatchId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id })
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId && !x.IsDeleted);
        });

        modelBuilder.Entity<SqlDatabase>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.HasAlternateKey(x => new { x.CustomerId, x.ProjectId, x.Id })
                .HasName("AK_SqlDatabases_CustomerId_ProjectId_Id");
            entity.Property(x => x.Name).HasMaxLength(128).IsRequired();
            entity.Property(x => x.NormalizedName).HasMaxLength(128).IsRequired();
            entity.Property(x => x.RecoveryModel).HasMaxLength(30).IsRequired();
            entity.Property(x => x.Collation).HasMaxLength(128);
            entity.Property(x => x.Status).HasMaxLength(50).IsRequired();
            entity.Property(x => x.CreatedBy).HasMaxLength(200).IsRequired();
            entity.Property(x => x.UpdatedBy).HasMaxLength(200).IsRequired();
            entity.Property(x => x.DeletedBy).HasMaxLength(200);
            ConfigureRowVersion(entity.Property(x => x.RowVersion));
            entity.ToTable(table =>
            {
                table.HasCheckConstraint("CK_SqlDatabases_SizeMb", "[SizeMb] >= 0");
                table.HasCheckConstraint(
                    "CK_SqlDatabases_CompatibilityLevel",
                    "[CompatibilityLevel] >= 80 AND [CompatibilityLevel] <= 200");
            });
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.SqlInstanceId, x.NormalizedName })
                .IsUnique()
                .HasDatabaseName("UX_SqlDatabases_Owner_Instance_NormalizedName_Active")
                .HasFilter("[IsDeleted] = 0");
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.IsDeleted, x.NormalizedName })
                .HasDatabaseName("IX_SqlDatabases_Owner_Active_Name");
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.IsDeleted, x.Status })
                .HasDatabaseName("IX_SqlDatabases_Owner_Active_Status");
            entity.HasOne(x => x.Project)
                .WithMany()
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId })
                .HasPrincipalKey(x => new { x.CustomerId, x.Id })
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.SqlInstance)
                .WithMany(x => x.Databases)
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.SqlInstanceId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id })
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.LastImportBatch)
                .WithMany()
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.LastImportBatchId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id })
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId && !x.IsDeleted);
        });

        modelBuilder.Entity<SqlInstanceDiscoverySnapshot>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.InstanceName).HasMaxLength(128).IsRequired();
            entity.Property(x => x.SqlVersion).HasMaxLength(100).IsRequired();
            entity.Property(x => x.Edition).HasMaxLength(100).IsRequired();
            entity.Property(x => x.ServiceStatus).HasMaxLength(50).IsRequired();
            entity.Property(x => x.DiscoverySource).HasMaxLength(100).IsRequired();
            entity.ToTable(table => table.HasCheckConstraint(
                "CK_SqlInstanceDiscoverySnapshots_Port",
                "[Port] IS NULL OR ([Port] >= 1 AND [Port] <= 65535)"));
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.SqlInstanceId, x.ImportedAt, x.Id })
                .HasDatabaseName("IX_SqlInstanceDiscoverySnapshots_Owner_History")
                .IsDescending(false, false, false, true, false);
            entity.HasOne(x => x.SqlInstance)
                .WithMany(x => x.DiscoverySnapshots)
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.SqlInstanceId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id })
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.ImportBatch)
                .WithMany(x => x.SqlInstanceSnapshots)
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.ImportBatchId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id })
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<SqlDatabaseDiscoverySnapshot>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.Name).HasMaxLength(128).IsRequired();
            entity.Property(x => x.RecoveryModel).HasMaxLength(30).IsRequired();
            entity.Property(x => x.Collation).HasMaxLength(128);
            entity.Property(x => x.Status).HasMaxLength(50).IsRequired();
            entity.ToTable(table =>
            {
                table.HasCheckConstraint("CK_SqlDatabaseDiscoverySnapshots_SizeMb", "[SizeMb] >= 0");
                table.HasCheckConstraint(
                    "CK_SqlDatabaseDiscoverySnapshots_CompatibilityLevel",
                    "[CompatibilityLevel] >= 80 AND [CompatibilityLevel] <= 200");
            });
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.SqlDatabaseId, x.ImportedAt, x.Id })
                .HasDatabaseName("IX_SqlDatabaseDiscoverySnapshots_Owner_History")
                .IsDescending(false, false, false, true, false);
            entity.HasOne(x => x.SqlDatabase)
                .WithMany(x => x.DiscoverySnapshots)
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.SqlDatabaseId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id })
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.ImportBatch)
                .WithMany(x => x.SqlDatabaseSnapshots)
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.ImportBatchId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id })
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<SqlAssessment>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.HasAlternateKey(x => new { x.CustomerId, x.ProjectId, x.Id })
                .HasName("AK_SqlAssessments_CustomerId_ProjectId_Id");
            entity.Property(x => x.AssessmentStatus).HasMaxLength(50).IsRequired();
            entity.Property(x => x.ReadinessStatus).HasMaxLength(50).IsRequired();
            entity.Property(x => x.TargetPlatform).HasMaxLength(80);
            entity.Property(x => x.TargetSqlVersion).HasMaxLength(100);
            entity.Property(x => x.MigrationApproach).HasMaxLength(50);
            entity.Property(x => x.Blockers).HasMaxLength(4000).IsRequired();
            entity.Property(x => x.Findings).HasMaxLength(8000).IsRequired();
            entity.Property(x => x.Notes).HasMaxLength(4000).IsRequired();
            entity.Property(x => x.CreatedBy).HasMaxLength(200).IsRequired();
            entity.Property(x => x.UpdatedBy).HasMaxLength(200).IsRequired();
            entity.Property(x => x.DeletedBy).HasMaxLength(200);
            ConfigureRowVersion(entity.Property(x => x.RowVersion));
            entity.ToTable(table =>
            {
                table.HasCheckConstraint(
                    "CK_SqlAssessments_ExactlyOneTarget",
                    "(CASE WHEN [SqlInstanceId] IS NULL THEN 0 ELSE 1 END + CASE WHEN [SqlDatabaseId] IS NULL THEN 0 ELSE 1 END) = 1");
                table.HasCheckConstraint(
                    "CK_SqlAssessments_AssessmentStatus",
                    "[AssessmentStatus] IN ('NotStarted', 'InProgress', 'Complete', 'Blocked')");
                table.HasCheckConstraint(
                    "CK_SqlAssessments_ReadinessStatus",
                    "[ReadinessStatus] IN ('NotAssessed', 'NotReady', 'AtRisk', 'ReadyWithConditions', 'Ready', 'Blocked')");
                table.HasCheckConstraint(
                    "CK_SqlAssessments_TargetPlatform",
                    "[TargetPlatform] IS NULL OR [TargetPlatform] IN ('AzureSqlDatabase', 'AzureSqlManagedInstance', 'SqlServerOnAzureVm', 'Retain', 'Retire', 'Investigate')");
                table.HasCheckConstraint(
                    "CK_SqlAssessments_MigrationApproach",
                    "[MigrationApproach] IS NULL OR [MigrationApproach] IN ('Offline', 'Online', 'ToBeDetermined', 'NotApplicable')");
            });
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.SqlInstanceId })
                .IsUnique()
                .HasDatabaseName("UX_SqlAssessments_Owner_Active_Instance")
                .HasFilter("[IsDeleted] = 0 AND [SqlInstanceId] IS NOT NULL");
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.SqlDatabaseId })
                .IsUnique()
                .HasDatabaseName("UX_SqlAssessments_Owner_Active_Database")
                .HasFilter("[IsDeleted] = 0 AND [SqlDatabaseId] IS NOT NULL");
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.IsDeleted, x.AssessmentStatus, x.ReadinessStatus, x.Id })
                .HasDatabaseName("IX_SqlAssessments_Owner_Filter");
            entity.HasOne(x => x.Project)
                .WithMany()
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId })
                .HasPrincipalKey(x => new { x.CustomerId, x.Id })
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.SqlInstance)
                .WithMany(x => x.Assessments)
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.SqlInstanceId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id })
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(x => x.SqlDatabase)
                .WithMany(x => x.Assessments)
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.SqlDatabaseId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id })
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId && !x.IsDeleted);
        });

        modelBuilder.Entity<DependencyReference>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.HasAlternateKey(x => new { x.CustomerId, x.ProjectId, x.Id })
                .HasName("AK_DependencyReferences_CustomerId_ProjectId_Id");
            entity.Property(x => x.ReferenceType).HasMaxLength(32).IsUnicode(false).IsRequired();
            entity.Property(x => x.Name).HasMaxLength(200).IsRequired();
            entity.Property(x => x.NormalizedName).HasMaxLength(200).IsRequired();
            entity.Property(x => x.Description).HasMaxLength(1000);
            entity.Property(x => x.ResolutionStatus).HasMaxLength(20).IsUnicode(false).IsRequired();
            entity.Property(x => x.CreatedBy).HasMaxLength(200).IsRequired();
            entity.Property(x => x.UpdatedBy).HasMaxLength(200).IsRequired();
            ConfigureRowVersion(entity.Property(x => x.RowVersion));
            entity.ToTable(table =>
            {
                table.HasCheckConstraint("CK_DependencyReferences_ReferenceType", "[ReferenceType] IN ('FileShare', 'Api', 'ExternalSystem')");
                table.HasCheckConstraint("CK_DependencyReferences_ResolutionStatus", "[ResolutionStatus] IN ('Unresolved', 'Resolved')");
            });
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.ReferenceType, x.NormalizedName })
                .IsUnique()
                .HasDatabaseName("UX_DependencyReferences_Owner_Type_Name_Active")
                .HasFilter("[IsArchived] = 0");
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.IsArchived, x.ReferenceType, x.ResolutionStatus, x.NormalizedName, x.Id })
                .HasDatabaseName("IX_DependencyReferences_Owner_List");
            entity.HasOne<Project>()
                .WithMany()
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId })
                .HasPrincipalKey(x => new { x.CustomerId, x.Id })
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<Dependency>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.HasAlternateKey(x => new { x.CustomerId, x.ProjectId, x.Id })
                .HasName("AK_Dependencies_CustomerId_ProjectId_Id");
            entity.Property(x => x.SourceType).HasMaxLength(32).IsUnicode(false).IsRequired();
            entity.Property(x => x.TargetType).HasMaxLength(32).IsUnicode(false).IsRequired();
            var sourceKey = entity.Property(x => x.SourceEndpointKey).HasMaxLength(34).IsUnicode(false).IsRequired();
            var targetKey = entity.Property(x => x.TargetEndpointKey).HasMaxLength(34).IsUnicode(false).IsRequired();
            if (Database.IsSqlServer())
            {
                sourceKey.HasComputedColumnSql(
                    "CASE [SourceType] WHEN 'Application' THEN 'A:' + REPLACE(CONVERT(varchar(36), [SourceApplicationId]), '-', '') WHEN 'Server' THEN 'S:' + REPLACE(CONVERT(varchar(36), [SourceServerId]), '-', '') WHEN 'SqlInstance' THEN 'I:' + REPLACE(CONVERT(varchar(36), [SourceSqlInstanceId]), '-', '') WHEN 'SqlDatabase' THEN 'D:' + REPLACE(CONVERT(varchar(36), [SourceSqlDatabaseId]), '-', '') END",
                    stored: true);
                targetKey.HasComputedColumnSql(
                    "CASE [TargetType] WHEN 'Application' THEN 'A:' + REPLACE(CONVERT(varchar(36), [TargetApplicationId]), '-', '') WHEN 'Server' THEN 'S:' + REPLACE(CONVERT(varchar(36), [TargetServerId]), '-', '') WHEN 'SqlInstance' THEN 'I:' + REPLACE(CONVERT(varchar(36), [TargetSqlInstanceId]), '-', '') WHEN 'SqlDatabase' THEN 'D:' + REPLACE(CONVERT(varchar(36), [TargetSqlDatabaseId]), '-', '') WHEN 'DependencyReference' THEN 'R:' + REPLACE(CONVERT(varchar(36), [TargetReferenceId]), '-', '') END",
                    stored: true);
            }
            entity.Property(x => x.DependencyType).HasMaxLength(40).IsUnicode(false).IsRequired();
            entity.Property(x => x.Criticality).HasMaxLength(20).IsUnicode(false).IsRequired();
            entity.Property(x => x.Description).HasMaxLength(2000);
            entity.Property(x => x.BusinessContext).HasMaxLength(4000);
            entity.Property(x => x.ConfirmationStatus).HasMaxLength(20).IsUnicode(false).IsRequired();
            entity.Property(x => x.ConfirmedBy).HasMaxLength(200);
            entity.Property(x => x.CreatedBy).HasMaxLength(200).IsRequired();
            entity.Property(x => x.UpdatedBy).HasMaxLength(200).IsRequired();
            ConfigureRowVersion(entity.Property(x => x.RowVersion));
            entity.ToTable(table =>
            {
                table.HasCheckConstraint(
                    "CK_Dependencies_SourceEndpoint",
                    "([SourceType] = 'Application' AND [SourceApplicationId] IS NOT NULL AND [SourceServerId] IS NULL AND [SourceSqlInstanceId] IS NULL AND [SourceSqlDatabaseId] IS NULL) OR ([SourceType] = 'Server' AND [SourceApplicationId] IS NULL AND [SourceServerId] IS NOT NULL AND [SourceSqlInstanceId] IS NULL AND [SourceSqlDatabaseId] IS NULL) OR ([SourceType] = 'SqlInstance' AND [SourceApplicationId] IS NULL AND [SourceServerId] IS NULL AND [SourceSqlInstanceId] IS NOT NULL AND [SourceSqlDatabaseId] IS NULL) OR ([SourceType] = 'SqlDatabase' AND [SourceApplicationId] IS NULL AND [SourceServerId] IS NULL AND [SourceSqlInstanceId] IS NULL AND [SourceSqlDatabaseId] IS NOT NULL)");
                table.HasCheckConstraint(
                    "CK_Dependencies_TargetEndpoint",
                    "([TargetType] = 'Application' AND [TargetApplicationId] IS NOT NULL AND [TargetServerId] IS NULL AND [TargetSqlInstanceId] IS NULL AND [TargetSqlDatabaseId] IS NULL AND [TargetReferenceId] IS NULL) OR ([TargetType] = 'Server' AND [TargetApplicationId] IS NULL AND [TargetServerId] IS NOT NULL AND [TargetSqlInstanceId] IS NULL AND [TargetSqlDatabaseId] IS NULL AND [TargetReferenceId] IS NULL) OR ([TargetType] = 'SqlInstance' AND [TargetApplicationId] IS NULL AND [TargetServerId] IS NULL AND [TargetSqlInstanceId] IS NOT NULL AND [TargetSqlDatabaseId] IS NULL AND [TargetReferenceId] IS NULL) OR ([TargetType] = 'SqlDatabase' AND [TargetApplicationId] IS NULL AND [TargetServerId] IS NULL AND [TargetSqlInstanceId] IS NULL AND [TargetSqlDatabaseId] IS NOT NULL AND [TargetReferenceId] IS NULL) OR ([TargetType] = 'DependencyReference' AND [TargetApplicationId] IS NULL AND [TargetServerId] IS NULL AND [TargetSqlInstanceId] IS NULL AND [TargetSqlDatabaseId] IS NULL AND [TargetReferenceId] IS NOT NULL)");
                table.HasCheckConstraint("CK_Dependencies_NotSelf", "[SourceEndpointKey] <> [TargetEndpointKey]");
                table.HasCheckConstraint("CK_Dependencies_Type", "[DependencyType] IN ('Service', 'DataRead', 'DataWrite', 'ApiCall', 'FileTransfer', 'Authentication', 'NetworkConnectivity', 'OperationalSequence')");
                table.HasCheckConstraint("CK_Dependencies_Criticality", "[Criticality] IN ('Mandatory', 'Advisory')");
                table.HasCheckConstraint("CK_Dependencies_Confirmation", "([ConfirmationStatus] = 'Unconfirmed' AND [ConfirmedAt] IS NULL AND [ConfirmedBy] IS NULL) OR ([ConfirmationStatus] = 'Confirmed' AND [ConfirmedAt] IS NOT NULL AND [ConfirmedBy] IS NOT NULL)");
            });
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.SourceEndpointKey, x.TargetEndpointKey, x.DependencyType })
                .IsUnique()
                .HasDatabaseName("UX_Dependencies_Owner_Endpoints_Type_Active")
                .HasFilter("[IsArchived] = 0");
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.IsArchived, x.SourceEndpointKey, x.DependencyType, x.Id })
                .HasDatabaseName("IX_Dependencies_Owner_Forward");
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.IsArchived, x.TargetEndpointKey, x.DependencyType, x.Id })
                .HasDatabaseName("IX_Dependencies_Owner_Reverse");
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.IsArchived, x.ConfirmationStatus, x.Criticality, x.Id })
                .HasDatabaseName("IX_Dependencies_Owner_Validation");
            entity.HasOne<Project>().WithMany()
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId })
                .HasPrincipalKey(x => new { x.CustomerId, x.Id }).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne<Application>().WithMany()
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.SourceApplicationId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id }).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne<Server>().WithMany()
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.SourceServerId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id }).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne<SqlInstance>().WithMany()
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.SourceSqlInstanceId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id }).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne<SqlDatabase>().WithMany()
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.SourceSqlDatabaseId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id }).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne<Application>().WithMany()
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.TargetApplicationId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id }).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne<Server>().WithMany()
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.TargetServerId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id }).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne<SqlInstance>().WithMany()
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.TargetSqlInstanceId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id }).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne<SqlDatabase>().WithMany()
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.TargetSqlDatabaseId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id }).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne<DependencyReference>().WithMany()
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.TargetReferenceId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id }).OnDelete(DeleteBehavior.Restrict);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<DependencyPolicy>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.HasAlternateKey(x => new { x.CustomerId, x.ProjectId, x.Id })
                .HasName("AK_DependencyPolicies_CustomerId_ProjectId_Id");
            entity.Property(x => x.Name).HasMaxLength(100).IsRequired();
            entity.Property(x => x.CreatedBy).HasMaxLength(200).IsRequired();
            entity.Property(x => x.ActivatedBy).HasMaxLength(200);
            ConfigureRowVersion(entity.Property(x => x.RowVersion));
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId })
                .IsUnique().HasDatabaseName("UX_DependencyPolicies_Owner_Active").HasFilter("[IsActive] = 1");
            entity.HasOne<Project>().WithMany()
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId })
                .HasPrincipalKey(x => new { x.CustomerId, x.Id }).OnDelete(DeleteBehavior.Restrict);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<DependencyPolicyRule>(entity =>
        {
            entity.HasKey(x => x.Id);
            entity.Property(x => x.RuleCode).HasMaxLength(50).IsUnicode(false).IsRequired();
            entity.Property(x => x.MandatorySeverity).HasMaxLength(20).IsUnicode(false).IsRequired();
            entity.Property(x => x.AdvisorySeverity).HasMaxLength(20).IsUnicode(false).IsRequired();
            entity.ToTable(table => table.HasCheckConstraint(
                "CK_DependencyPolicyRules_Severity",
                "[MandatorySeverity] IN ('Information', 'Warning', 'Blocker') AND [AdvisorySeverity] IN ('Information', 'Warning', 'Blocker')"));
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId, x.DependencyPolicyId, x.RuleCode }).IsUnique();
            entity.HasOne(x => x.DependencyPolicy).WithMany(x => x.Rules)
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId, x.DependencyPolicyId })
                .HasPrincipalKey(x => new { x.CustomerId, x.ProjectId, x.Id }).OnDelete(DeleteBehavior.Restrict);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        modelBuilder.Entity<DependencyGraphState>(entity =>
        {
            entity.HasKey(x => x.Id);
            ConfigureRowVersion(entity.Property(x => x.RowVersion));
            entity.ToTable(table =>
            {
                table.HasCheckConstraint("CK_DependencyGraphStates_GraphVersion", "[GraphVersion] >= 0");
                table.HasCheckConstraint("CK_DependencyGraphStates_PlanningVersion", "[PlanningVersion] >= 0");
            });
            entity.HasIndex(x => new { x.CustomerId, x.ProjectId }).IsUnique();
            entity.HasOne<Project>().WithMany()
                .HasForeignKey(x => new { x.CustomerId, x.ProjectId })
                .HasPrincipalKey(x => new { x.CustomerId, x.Id }).OnDelete(DeleteBehavior.Restrict);
            entity.HasQueryFilter(x => x.CustomerId == currentContext.CustomerId);
        });

        SeedData.Configure(modelBuilder);
    }

    private void ConfigureRowVersion(
        Microsoft.EntityFrameworkCore.Metadata.Builders.PropertyBuilder<byte[]> property)
    {
        property.IsRequired().IsConcurrencyToken();
        if (Database.IsSqlServer())
        {
            property.IsRowVersion();
        }
        else
        {
            property.ValueGeneratedNever();
        }
    }

    private void EnforceAppendOnlyDiscoveryHistory()
    {
        var mutableInstanceHistory = ChangeTracker.Entries<SqlInstanceDiscoverySnapshot>()
            .Any(entry => entry.State is EntityState.Modified or EntityState.Deleted);
        var mutableDatabaseHistory = ChangeTracker.Entries<SqlDatabaseDiscoverySnapshot>()
            .Any(entry => entry.State is EntityState.Modified or EntityState.Deleted);
        if (mutableInstanceHistory || mutableDatabaseHistory)
        {
            throw new InvalidOperationException("SQL discovery history is append-only.");
        }
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
