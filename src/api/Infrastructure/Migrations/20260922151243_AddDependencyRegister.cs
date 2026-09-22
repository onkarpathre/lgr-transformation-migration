using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace LgrTransformationMigration.Api.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDependencyRegister : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                IF EXISTS (
                    SELECT [CustomerId], [ProjectId], [Id]
                    FROM [Applications]
                    GROUP BY [CustomerId], [ProjectId], [Id]
                    HAVING COUNT_BIG(*) > 1)
                    THROW 51000, 'Cannot add the application tenant/project alternate key because duplicate ownership keys exist.', 1;
                """);

            migrationBuilder.AddUniqueConstraint(
                name: "AK_Applications_CustomerId_ProjectId_Id",
                table: "Applications",
                columns: new[] { "CustomerId", "ProjectId", "Id" });

            migrationBuilder.CreateTable(
                name: "DependencyGraphStates",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    GraphVersion = table.Column<long>(type: "bigint", nullable: false),
                    PlanningVersion = table.Column<long>(type: "bigint", nullable: false),
                    CurrentValidationRunId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    RowVersion = table.Column<byte[]>(type: "rowversion", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DependencyGraphStates", x => x.Id);
                    table.CheckConstraint("CK_DependencyGraphStates_GraphVersion", "[GraphVersion] >= 0");
                    table.CheckConstraint("CK_DependencyGraphStates_PlanningVersion", "[PlanningVersion] >= 0");
                    table.ForeignKey(
                        name: "FK_DependencyGraphStates_Projects_CustomerId_ProjectId",
                        columns: x => new { x.CustomerId, x.ProjectId },
                        principalTable: "Projects",
                        principalColumns: new[] { "CustomerId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "DependencyPolicies",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Version = table.Column<int>(type: "int", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    CreatedBy = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    ActivatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    ActivatedBy = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    RowVersion = table.Column<byte[]>(type: "rowversion", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DependencyPolicies", x => x.Id);
                    table.UniqueConstraint("AK_DependencyPolicies_CustomerId_ProjectId_Id", x => new { x.CustomerId, x.ProjectId, x.Id });
                    table.ForeignKey(
                        name: "FK_DependencyPolicies_Projects_CustomerId_ProjectId",
                        columns: x => new { x.CustomerId, x.ProjectId },
                        principalTable: "Projects",
                        principalColumns: new[] { "CustomerId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "DependencyReferences",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ReferenceType = table.Column<string>(type: "varchar(32)", unicode: false, maxLength: 32, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    NormalizedName = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    ResolutionStatus = table.Column<string>(type: "varchar(20)", unicode: false, maxLength: 20, nullable: false),
                    IsArchived = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    CreatedBy = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedBy = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    RowVersion = table.Column<byte[]>(type: "rowversion", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DependencyReferences", x => x.Id);
                    table.UniqueConstraint("AK_DependencyReferences_CustomerId_ProjectId_Id", x => new { x.CustomerId, x.ProjectId, x.Id });
                    table.CheckConstraint("CK_DependencyReferences_ReferenceType", "[ReferenceType] IN ('FileShare', 'Api', 'ExternalSystem')");
                    table.CheckConstraint("CK_DependencyReferences_ResolutionStatus", "[ResolutionStatus] IN ('Unresolved', 'Resolved')");
                    table.ForeignKey(
                        name: "FK_DependencyReferences_Projects_CustomerId_ProjectId",
                        columns: x => new { x.CustomerId, x.ProjectId },
                        principalTable: "Projects",
                        principalColumns: new[] { "CustomerId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "DependencyPolicyRules",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    DependencyPolicyId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    RuleCode = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: false),
                    MandatorySeverity = table.Column<string>(type: "varchar(20)", unicode: false, maxLength: 20, nullable: false),
                    AdvisorySeverity = table.Column<string>(type: "varchar(20)", unicode: false, maxLength: 20, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DependencyPolicyRules", x => x.Id);
                    table.CheckConstraint("CK_DependencyPolicyRules_Severity", "[MandatorySeverity] IN ('Information', 'Warning', 'Blocker') AND [AdvisorySeverity] IN ('Information', 'Warning', 'Blocker')");
                    table.ForeignKey(
                        name: "FK_DependencyPolicyRules_DependencyPolicies_CustomerId_ProjectId_DependencyPolicyId",
                        columns: x => new { x.CustomerId, x.ProjectId, x.DependencyPolicyId },
                        principalTable: "DependencyPolicies",
                        principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Dependencies",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SourceType = table.Column<string>(type: "varchar(32)", unicode: false, maxLength: 32, nullable: false),
                    SourceApplicationId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    SourceServerId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    SourceSqlInstanceId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    SourceSqlDatabaseId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    SourceEndpointKey = table.Column<string>(type: "varchar(34)", unicode: false, maxLength: 34, nullable: false, computedColumnSql: "CASE [SourceType] WHEN 'Application' THEN 'A:' + REPLACE(CONVERT(varchar(36), [SourceApplicationId]), '-', '') WHEN 'Server' THEN 'S:' + REPLACE(CONVERT(varchar(36), [SourceServerId]), '-', '') WHEN 'SqlInstance' THEN 'I:' + REPLACE(CONVERT(varchar(36), [SourceSqlInstanceId]), '-', '') WHEN 'SqlDatabase' THEN 'D:' + REPLACE(CONVERT(varchar(36), [SourceSqlDatabaseId]), '-', '') END", stored: true),
                    TargetType = table.Column<string>(type: "varchar(32)", unicode: false, maxLength: 32, nullable: false),
                    TargetApplicationId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    TargetServerId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    TargetSqlInstanceId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    TargetSqlDatabaseId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    TargetReferenceId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    TargetEndpointKey = table.Column<string>(type: "varchar(34)", unicode: false, maxLength: 34, nullable: false, computedColumnSql: "CASE [TargetType] WHEN 'Application' THEN 'A:' + REPLACE(CONVERT(varchar(36), [TargetApplicationId]), '-', '') WHEN 'Server' THEN 'S:' + REPLACE(CONVERT(varchar(36), [TargetServerId]), '-', '') WHEN 'SqlInstance' THEN 'I:' + REPLACE(CONVERT(varchar(36), [TargetSqlInstanceId]), '-', '') WHEN 'SqlDatabase' THEN 'D:' + REPLACE(CONVERT(varchar(36), [TargetSqlDatabaseId]), '-', '') WHEN 'DependencyReference' THEN 'R:' + REPLACE(CONVERT(varchar(36), [TargetReferenceId]), '-', '') END", stored: true),
                    DependencyType = table.Column<string>(type: "varchar(40)", unicode: false, maxLength: 40, nullable: false),
                    Criticality = table.Column<string>(type: "varchar(20)", unicode: false, maxLength: 20, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: true),
                    BusinessContext = table.Column<string>(type: "nvarchar(4000)", maxLength: 4000, nullable: true),
                    ConfirmationStatus = table.Column<string>(type: "varchar(20)", unicode: false, maxLength: 20, nullable: false),
                    ConfirmedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    ConfirmedBy = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    IsArchived = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    CreatedBy = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedBy = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    RowVersion = table.Column<byte[]>(type: "rowversion", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Dependencies", x => x.Id);
                    table.UniqueConstraint("AK_Dependencies_CustomerId_ProjectId_Id", x => new { x.CustomerId, x.ProjectId, x.Id });
                    table.CheckConstraint("CK_Dependencies_Confirmation", "([ConfirmationStatus] = 'Unconfirmed' AND [ConfirmedAt] IS NULL AND [ConfirmedBy] IS NULL) OR ([ConfirmationStatus] = 'Confirmed' AND [ConfirmedAt] IS NOT NULL AND [ConfirmedBy] IS NOT NULL)");
                    table.CheckConstraint("CK_Dependencies_Criticality", "[Criticality] IN ('Mandatory', 'Advisory')");
                    table.CheckConstraint("CK_Dependencies_NotSelf", "[SourceEndpointKey] <> [TargetEndpointKey]");
                    table.CheckConstraint("CK_Dependencies_SourceEndpoint", "([SourceType] = 'Application' AND [SourceApplicationId] IS NOT NULL AND [SourceServerId] IS NULL AND [SourceSqlInstanceId] IS NULL AND [SourceSqlDatabaseId] IS NULL) OR ([SourceType] = 'Server' AND [SourceApplicationId] IS NULL AND [SourceServerId] IS NOT NULL AND [SourceSqlInstanceId] IS NULL AND [SourceSqlDatabaseId] IS NULL) OR ([SourceType] = 'SqlInstance' AND [SourceApplicationId] IS NULL AND [SourceServerId] IS NULL AND [SourceSqlInstanceId] IS NOT NULL AND [SourceSqlDatabaseId] IS NULL) OR ([SourceType] = 'SqlDatabase' AND [SourceApplicationId] IS NULL AND [SourceServerId] IS NULL AND [SourceSqlInstanceId] IS NULL AND [SourceSqlDatabaseId] IS NOT NULL)");
                    table.CheckConstraint("CK_Dependencies_TargetEndpoint", "([TargetType] = 'Application' AND [TargetApplicationId] IS NOT NULL AND [TargetServerId] IS NULL AND [TargetSqlInstanceId] IS NULL AND [TargetSqlDatabaseId] IS NULL AND [TargetReferenceId] IS NULL) OR ([TargetType] = 'Server' AND [TargetApplicationId] IS NULL AND [TargetServerId] IS NOT NULL AND [TargetSqlInstanceId] IS NULL AND [TargetSqlDatabaseId] IS NULL AND [TargetReferenceId] IS NULL) OR ([TargetType] = 'SqlInstance' AND [TargetApplicationId] IS NULL AND [TargetServerId] IS NULL AND [TargetSqlInstanceId] IS NOT NULL AND [TargetSqlDatabaseId] IS NULL AND [TargetReferenceId] IS NULL) OR ([TargetType] = 'SqlDatabase' AND [TargetApplicationId] IS NULL AND [TargetServerId] IS NULL AND [TargetSqlInstanceId] IS NULL AND [TargetSqlDatabaseId] IS NOT NULL AND [TargetReferenceId] IS NULL) OR ([TargetType] = 'DependencyReference' AND [TargetApplicationId] IS NULL AND [TargetServerId] IS NULL AND [TargetSqlInstanceId] IS NULL AND [TargetSqlDatabaseId] IS NULL AND [TargetReferenceId] IS NOT NULL)");
                    table.CheckConstraint("CK_Dependencies_Type", "[DependencyType] IN ('Service', 'DataRead', 'DataWrite', 'ApiCall', 'FileTransfer', 'Authentication', 'NetworkConnectivity', 'OperationalSequence')");
                    table.ForeignKey(
                        name: "FK_Dependencies_Applications_CustomerId_ProjectId_SourceApplicationId",
                        columns: x => new { x.CustomerId, x.ProjectId, x.SourceApplicationId },
                        principalTable: "Applications",
                        principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Dependencies_Applications_CustomerId_ProjectId_TargetApplicationId",
                        columns: x => new { x.CustomerId, x.ProjectId, x.TargetApplicationId },
                        principalTable: "Applications",
                        principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Dependencies_DependencyReferences_CustomerId_ProjectId_TargetReferenceId",
                        columns: x => new { x.CustomerId, x.ProjectId, x.TargetReferenceId },
                        principalTable: "DependencyReferences",
                        principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Dependencies_Projects_CustomerId_ProjectId",
                        columns: x => new { x.CustomerId, x.ProjectId },
                        principalTable: "Projects",
                        principalColumns: new[] { "CustomerId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Dependencies_Servers_CustomerId_ProjectId_SourceServerId",
                        columns: x => new { x.CustomerId, x.ProjectId, x.SourceServerId },
                        principalTable: "Servers",
                        principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Dependencies_Servers_CustomerId_ProjectId_TargetServerId",
                        columns: x => new { x.CustomerId, x.ProjectId, x.TargetServerId },
                        principalTable: "Servers",
                        principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Dependencies_SqlDatabases_CustomerId_ProjectId_SourceSqlDatabaseId",
                        columns: x => new { x.CustomerId, x.ProjectId, x.SourceSqlDatabaseId },
                        principalTable: "SqlDatabases",
                        principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Dependencies_SqlDatabases_CustomerId_ProjectId_TargetSqlDatabaseId",
                        columns: x => new { x.CustomerId, x.ProjectId, x.TargetSqlDatabaseId },
                        principalTable: "SqlDatabases",
                        principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Dependencies_SqlInstances_CustomerId_ProjectId_SourceSqlInstanceId",
                        columns: x => new { x.CustomerId, x.ProjectId, x.SourceSqlInstanceId },
                        principalTable: "SqlInstances",
                        principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Dependencies_SqlInstances_CustomerId_ProjectId_TargetSqlInstanceId",
                        columns: x => new { x.CustomerId, x.ProjectId, x.TargetSqlInstanceId },
                        principalTable: "SqlInstances",
                        principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.InsertData(
                table: "DependencyGraphStates",
                columns: new[] { "Id", "CurrentValidationRunId", "CustomerId", "GraphVersion", "PlanningVersion", "ProjectId", "UpdatedAt" },
                values: new object[] { new Guid("44444444-4444-4444-4444-444444444402"), null, new Guid("11111111-1111-1111-1111-111111111111"), 0L, 0L, new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) });

            migrationBuilder.InsertData(
                table: "DependencyPolicies",
                columns: new[] { "Id", "ActivatedAt", "ActivatedBy", "CreatedAt", "CreatedBy", "CustomerId", "IsActive", "Name", "ProjectId", "Version" },
                values: new object[] { new Guid("44444444-4444-4444-4444-444444444401"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), "synthetic-seed", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), "synthetic-seed", new Guid("11111111-1111-1111-1111-111111111111"), true, "Default dependency validation policy", new Guid("22222222-2222-2222-2222-222222222222"), 1 });

            migrationBuilder.InsertData(
                table: "DependencyPolicyRules",
                columns: new[] { "Id", "AdvisorySeverity", "CustomerId", "DependencyPolicyId", "MandatorySeverity", "ProjectId", "RuleCode" },
                values: new object[,]
                {
                    { new Guid("44444444-4444-4444-4444-000000000101"), "Warning", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("44444444-4444-4444-4444-444444444401"), "Blocker", new Guid("22222222-2222-2222-2222-222222222222"), "UnresolvedReference" },
                    { new Guid("44444444-4444-4444-4444-000000000102"), "Warning", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("44444444-4444-4444-4444-444444444401"), "Blocker", new Guid("22222222-2222-2222-2222-222222222222"), "UnconfirmedDependency" },
                    { new Guid("44444444-4444-4444-4444-000000000103"), "Blocker", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("44444444-4444-4444-4444-444444444401"), "Blocker", new Guid("22222222-2222-2222-2222-222222222222"), "SelfDependency" },
                    { new Guid("44444444-4444-4444-4444-000000000104"), "Blocker", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("44444444-4444-4444-4444-444444444401"), "Blocker", new Guid("22222222-2222-2222-2222-222222222222"), "DuplicateDependency" },
                    { new Guid("44444444-4444-4444-4444-000000000105"), "Warning", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("44444444-4444-4444-4444-444444444401"), "Blocker", new Guid("22222222-2222-2222-2222-222222222222"), "DirectedCycle" },
                    { new Guid("44444444-4444-4444-4444-000000000106"), "Warning", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("44444444-4444-4444-4444-444444444401"), "Blocker", new Guid("22222222-2222-2222-2222-222222222222"), "ProviderUnassigned" },
                    { new Guid("44444444-4444-4444-4444-000000000107"), "Blocker", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("44444444-4444-4444-4444-444444444401"), "Blocker", new Guid("22222222-2222-2222-2222-222222222222"), "MultipleWaveAssignments" },
                    { new Guid("44444444-4444-4444-4444-000000000108"), "Warning", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("44444444-4444-4444-4444-444444444401"), "Blocker", new Guid("22222222-2222-2222-2222-222222222222"), "ProviderLaterWave" },
                    { new Guid("44444444-4444-4444-4444-000000000109"), "Warning", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("44444444-4444-4444-4444-444444444401"), "Blocker", new Guid("22222222-2222-2222-2222-222222222222"), "WaveOrderUnknown" },
                    { new Guid("44444444-4444-4444-4444-000000000110"), "Information", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("44444444-4444-4444-4444-444444444401"), "Warning", new Guid("22222222-2222-2222-2222-222222222222"), "ExternalPlanningReview" }
                });

            migrationBuilder.Sql(
                """
                INSERT INTO [DependencyGraphStates]
                    ([Id], [CustomerId], [ProjectId], [GraphVersion], [PlanningVersion], [CurrentValidationRunId], [UpdatedAt])
                SELECT NEWID(), p.[CustomerId], p.[Id], 0, 0, NULL, SYSUTCDATETIME()
                FROM [Projects] p
                WHERE NOT EXISTS (
                    SELECT 1 FROM [DependencyGraphStates] s
                    WHERE s.[CustomerId] = p.[CustomerId] AND s.[ProjectId] = p.[Id]);

                INSERT INTO [DependencyPolicies]
                    ([Id], [CustomerId], [ProjectId], [Version], [Name], [IsActive],
                     [CreatedAt], [CreatedBy], [ActivatedAt], [ActivatedBy])
                SELECT NEWID(), p.[CustomerId], p.[Id], 1, N'Default dependency validation policy', 1,
                       SYSUTCDATETIME(), N'ph4-migration', SYSUTCDATETIME(), N'ph4-migration'
                FROM [Projects] p
                WHERE NOT EXISTS (
                    SELECT 1 FROM [DependencyPolicies] policy
                    WHERE policy.[CustomerId] = p.[CustomerId]
                      AND policy.[ProjectId] = p.[Id]
                      AND policy.[IsActive] = 1);

                INSERT INTO [DependencyPolicyRules]
                    ([Id], [CustomerId], [ProjectId], [DependencyPolicyId], [RuleCode], [MandatorySeverity], [AdvisorySeverity])
                SELECT NEWID(), policy.[CustomerId], policy.[ProjectId], policy.[Id], rules.[RuleCode],
                       rules.[MandatorySeverity], rules.[AdvisorySeverity]
                FROM [DependencyPolicies] policy
                CROSS APPLY (VALUES
                    ('UnresolvedReference', 'Blocker', 'Warning'),
                    ('UnconfirmedDependency', 'Blocker', 'Warning'),
                    ('SelfDependency', 'Blocker', 'Blocker'),
                    ('DuplicateDependency', 'Blocker', 'Blocker'),
                    ('DirectedCycle', 'Blocker', 'Warning'),
                    ('ProviderUnassigned', 'Blocker', 'Warning'),
                    ('MultipleWaveAssignments', 'Blocker', 'Blocker'),
                    ('ProviderLaterWave', 'Blocker', 'Warning'),
                    ('WaveOrderUnknown', 'Blocker', 'Warning'),
                    ('ExternalPlanningReview', 'Warning', 'Information')
                ) rules([RuleCode], [MandatorySeverity], [AdvisorySeverity])
                WHERE policy.[IsActive] = 1
                  AND NOT EXISTS (
                    SELECT 1 FROM [DependencyPolicyRules] existingRule
                    WHERE existingRule.[CustomerId] = policy.[CustomerId]
                      AND existingRule.[ProjectId] = policy.[ProjectId]
                      AND existingRule.[DependencyPolicyId] = policy.[Id]
                      AND existingRule.[RuleCode] = rules.[RuleCode]);
                """);

            migrationBuilder.CreateIndex(
                name: "IX_Dependencies_CustomerId_ProjectId_SourceApplicationId",
                table: "Dependencies",
                columns: new[] { "CustomerId", "ProjectId", "SourceApplicationId" });

            migrationBuilder.CreateIndex(
                name: "IX_Dependencies_CustomerId_ProjectId_SourceServerId",
                table: "Dependencies",
                columns: new[] { "CustomerId", "ProjectId", "SourceServerId" });

            migrationBuilder.CreateIndex(
                name: "IX_Dependencies_CustomerId_ProjectId_SourceSqlDatabaseId",
                table: "Dependencies",
                columns: new[] { "CustomerId", "ProjectId", "SourceSqlDatabaseId" });

            migrationBuilder.CreateIndex(
                name: "IX_Dependencies_CustomerId_ProjectId_SourceSqlInstanceId",
                table: "Dependencies",
                columns: new[] { "CustomerId", "ProjectId", "SourceSqlInstanceId" });

            migrationBuilder.CreateIndex(
                name: "IX_Dependencies_CustomerId_ProjectId_TargetApplicationId",
                table: "Dependencies",
                columns: new[] { "CustomerId", "ProjectId", "TargetApplicationId" });

            migrationBuilder.CreateIndex(
                name: "IX_Dependencies_CustomerId_ProjectId_TargetReferenceId",
                table: "Dependencies",
                columns: new[] { "CustomerId", "ProjectId", "TargetReferenceId" });

            migrationBuilder.CreateIndex(
                name: "IX_Dependencies_CustomerId_ProjectId_TargetServerId",
                table: "Dependencies",
                columns: new[] { "CustomerId", "ProjectId", "TargetServerId" });

            migrationBuilder.CreateIndex(
                name: "IX_Dependencies_CustomerId_ProjectId_TargetSqlDatabaseId",
                table: "Dependencies",
                columns: new[] { "CustomerId", "ProjectId", "TargetSqlDatabaseId" });

            migrationBuilder.CreateIndex(
                name: "IX_Dependencies_CustomerId_ProjectId_TargetSqlInstanceId",
                table: "Dependencies",
                columns: new[] { "CustomerId", "ProjectId", "TargetSqlInstanceId" });

            migrationBuilder.CreateIndex(
                name: "IX_Dependencies_Owner_Forward",
                table: "Dependencies",
                columns: new[] { "CustomerId", "ProjectId", "IsArchived", "SourceEndpointKey", "DependencyType", "Id" });

            migrationBuilder.CreateIndex(
                name: "IX_Dependencies_Owner_Reverse",
                table: "Dependencies",
                columns: new[] { "CustomerId", "ProjectId", "IsArchived", "TargetEndpointKey", "DependencyType", "Id" });

            migrationBuilder.CreateIndex(
                name: "IX_Dependencies_Owner_Validation",
                table: "Dependencies",
                columns: new[] { "CustomerId", "ProjectId", "IsArchived", "ConfirmationStatus", "Criticality", "Id" });

            migrationBuilder.CreateIndex(
                name: "UX_Dependencies_Owner_Endpoints_Type_Active",
                table: "Dependencies",
                columns: new[] { "CustomerId", "ProjectId", "SourceEndpointKey", "TargetEndpointKey", "DependencyType" },
                unique: true,
                filter: "[IsArchived] = 0");

            migrationBuilder.CreateIndex(
                name: "IX_DependencyGraphStates_CustomerId_ProjectId",
                table: "DependencyGraphStates",
                columns: new[] { "CustomerId", "ProjectId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "UX_DependencyPolicies_Owner_Active",
                table: "DependencyPolicies",
                columns: new[] { "CustomerId", "ProjectId" },
                unique: true,
                filter: "[IsActive] = 1");

            migrationBuilder.CreateIndex(
                name: "IX_DependencyPolicyRules_CustomerId_ProjectId_DependencyPolicyId_RuleCode",
                table: "DependencyPolicyRules",
                columns: new[] { "CustomerId", "ProjectId", "DependencyPolicyId", "RuleCode" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_DependencyReferences_Owner_List",
                table: "DependencyReferences",
                columns: new[] { "CustomerId", "ProjectId", "IsArchived", "ReferenceType", "ResolutionStatus", "NormalizedName", "Id" });

            migrationBuilder.CreateIndex(
                name: "UX_DependencyReferences_Owner_Type_Name_Active",
                table: "DependencyReferences",
                columns: new[] { "CustomerId", "ProjectId", "ReferenceType", "NormalizedName" },
                unique: true,
                filter: "[IsArchived] = 0");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Dependencies");

            migrationBuilder.DropTable(
                name: "DependencyGraphStates");

            migrationBuilder.DropTable(
                name: "DependencyPolicyRules");

            migrationBuilder.DropTable(
                name: "DependencyReferences");

            migrationBuilder.DropTable(
                name: "DependencyPolicies");

            migrationBuilder.DropUniqueConstraint(
                name: "AK_Applications_CustomerId_ProjectId_Id",
                table: "Applications");
        }
    }
}
