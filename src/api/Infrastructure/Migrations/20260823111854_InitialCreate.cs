using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace LgrTransformationMigration.Api.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "AuditEvents",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    EntityType = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    EntityId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Action = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    PropertyName = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    OldValue = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    NewValue = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ChangedBy = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    ChangedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AuditEvents", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Customers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Code = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Customers", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "LookupOptions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    Group = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Value = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    DisplayName = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: false),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LookupOptions", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "MigrationWaves",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(150)", maxLength: 150, nullable: false),
                    PlannedDate = table.Column<DateOnly>(type: "date", nullable: true),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MigrationWaves", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Subnets",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    VNetName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Cidr = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Environment = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Subnets", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Projects",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    PlannedStartDate = table.Column<DateOnly>(type: "date", nullable: true),
                    PlannedEndDate = table.Column<DateOnly>(type: "date", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Projects", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Projects_Customers_CustomerId",
                        column: x => x.CustomerId,
                        principalTable: "Customers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Runbooks",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    MigrationWaveId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Runbooks", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Runbooks_MigrationWaves_MigrationWaveId",
                        column: x => x.MigrationWaveId,
                        principalTable: "MigrationWaves",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Applications",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Environment = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    Criticality = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    ApplicationType = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    CurrentVersion = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    MigrationScope = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    MigrationStrategy = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    MigrationStatus = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Applications", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Applications_Projects_ProjectId",
                        column: x => x.ProjectId,
                        principalTable: "Projects",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "Servers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Hostname = table.Column<string>(type: "nvarchar(253)", maxLength: 253, nullable: false),
                    Environment = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    OperatingSystem = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    IpAddress = table.Column<string>(type: "nvarchar(45)", maxLength: 45, nullable: false),
                    VCores = table.Column<int>(type: "int", nullable: true),
                    MemoryMb = table.Column<int>(type: "int", nullable: true),
                    AllocatedStorageGb = table.Column<int>(type: "int", nullable: true),
                    PowerStatus = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    MigrationStatus = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Servers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Servers_Projects_ProjectId",
                        column: x => x.ProjectId,
                        principalTable: "Projects",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "RunbookTasks",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    RunbookId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Sequence = table.Column<int>(type: "int", nullable: false),
                    Category = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Task = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    Owner = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    PlannedStart = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    PlannedEnd = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    ActualStart = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    ActualEnd = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Comment = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RunbookTasks", x => x.Id);
                    table.ForeignKey(
                        name: "FK_RunbookTasks_Runbooks_RunbookId",
                        column: x => x.RunbookId,
                        principalTable: "Runbooks",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "MigrationDecisions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ApplicationId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    MigrationScope = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    MigrationStrategy = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    TargetPlatform = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    Reason = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    Risk = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    DecisionStatus = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    DecisionDate = table.Column<DateOnly>(type: "date", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MigrationDecisions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MigrationDecisions_Applications_ApplicationId",
                        column: x => x.ApplicationId,
                        principalTable: "Applications",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ApplicationServers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ApplicationId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ServerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ApplicationServers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ApplicationServers_Applications_ApplicationId",
                        column: x => x.ApplicationId,
                        principalTable: "Applications",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ApplicationServers_Servers_ServerId",
                        column: x => x.ServerId,
                        principalTable: "Servers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AzureTargets",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ServerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Subscription = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    ResourceGroup = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    VNet = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    Subnet = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    AzureIp = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    AzureHostname = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    VmSize = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    OperatingSystem = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    BackupPolicy = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    Domain = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    OrganisationalUnit = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    Notes = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AzureTargets", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AzureTargets_Servers_ServerId",
                        column: x => x.ServerId,
                        principalTable: "Servers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "IpAddresses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SubnetId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Address = table.Column<string>(type: "nvarchar(45)", maxLength: 45, nullable: false),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    ServerId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    ReservedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    AllocatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_IpAddresses", x => x.Id);
                    table.ForeignKey(
                        name: "FK_IpAddresses_Servers_ServerId",
                        column: x => x.ServerId,
                        principalTable: "Servers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_IpAddresses_Subnets_SubnetId",
                        column: x => x.SubnetId,
                        principalTable: "Subnets",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ReadinessChecks",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ApplicationId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    ServerId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    CheckType = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    Comment = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ReadinessChecks", x => x.Id);
                    table.CheckConstraint("CK_ReadinessCheck_Asset", "[ApplicationId] IS NOT NULL OR [ServerId] IS NOT NULL");
                    table.ForeignKey(
                        name: "FK_ReadinessChecks_Applications_ApplicationId",
                        column: x => x.ApplicationId,
                        principalTable: "Applications",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ReadinessChecks_Servers_ServerId",
                        column: x => x.ServerId,
                        principalTable: "Servers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "WaveAssets",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    MigrationWaveId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ApplicationId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    ServerId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WaveAssets", x => x.Id);
                    table.CheckConstraint("CK_WaveAsset_Asset", "[ApplicationId] IS NOT NULL OR [ServerId] IS NOT NULL");
                    table.ForeignKey(
                        name: "FK_WaveAssets_Applications_ApplicationId",
                        column: x => x.ApplicationId,
                        principalTable: "Applications",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_WaveAssets_MigrationWaves_MigrationWaveId",
                        column: x => x.MigrationWaveId,
                        principalTable: "MigrationWaves",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_WaveAssets_Servers_ServerId",
                        column: x => x.ServerId,
                        principalTable: "Servers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.InsertData(
                table: "Customers",
                columns: new[] { "Id", "Code", "CreatedAt", "Name", "Status", "UpdatedAt" },
                values: new object[] { new Guid("11111111-1111-1111-1111-111111111111"), "DEMO", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), "Demo Council", "Active", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) });

            migrationBuilder.InsertData(
                table: "LookupOptions",
                columns: new[] { "Id", "CustomerId", "DisplayName", "Group", "IsActive", "SortOrder", "Value" },
                values: new object[,]
                {
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000001"), null, "Prod", "Environment", true, 1, "Prod" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000002"), null, "UAT", "Environment", true, 2, "UAT" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000003"), null, "Dev", "Environment", true, 3, "Dev" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000004"), null, "Test", "Environment", true, 4, "Test" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000005"), null, "Rehost", "MigrationStrategy", true, 1, "Rehost" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000006"), null, "Build Ahead", "MigrationStrategy", true, 2, "Build Ahead" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000007"), null, "Replatform", "MigrationStrategy", true, 3, "Replatform" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000008"), null, "Refactor", "MigrationStrategy", true, 4, "Refactor" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000009"), null, "SaaS", "MigrationStrategy", true, 5, "SaaS" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000010"), null, "Retain", "MigrationStrategy", true, 6, "Retain" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000011"), null, "Retire", "MigrationStrategy", true, 7, "Retire" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000012"), null, "Investigate", "MigrationStrategy", true, 8, "Investigate" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000013"), null, "In Scope", "MigrationScope", true, 1, "In Scope" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000014"), null, "Out of Scope", "MigrationScope", true, 2, "Out of Scope" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000015"), null, "Under Review", "MigrationScope", true, 3, "Under Review" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000016"), null, "Not Started", "MigrationStatus", true, 1, "Not Started" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000017"), null, "In Progress", "MigrationStatus", true, 2, "In Progress" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000018"), null, "Completed", "MigrationStatus", true, 3, "Completed" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000019"), null, "Rolled Back", "MigrationStatus", true, 4, "Rolled Back" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000020"), null, "Blocked", "MigrationStatus", true, 5, "Blocked" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000021"), null, "Critical", "ApplicationCriticality", true, 1, "Critical" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000022"), null, "High", "ApplicationCriticality", true, 2, "High" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000023"), null, "Medium", "ApplicationCriticality", true, 3, "Medium" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000024"), null, "Low", "ApplicationCriticality", true, 4, "Low" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000025"), null, "COTS", "WorkloadType", true, 1, "COTS" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000026"), null, "Custom", "WorkloadType", true, 2, "Custom" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000027"), null, "Database", "WorkloadType", true, 3, "Database" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000028"), null, "Web", "WorkloadType", true, 4, "Web" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000029"), null, "SaaS", "WorkloadType", true, 5, "SaaS" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000030"), null, "Not Started", "WaveStatus", true, 1, "Not Started" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000031"), null, "Planning", "WaveStatus", true, 2, "Planning" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000032"), null, "Ready", "WaveStatus", true, 3, "Ready" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000033"), null, "In Progress", "WaveStatus", true, 4, "In Progress" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000034"), null, "Completed", "WaveStatus", true, 5, "Completed" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000035"), null, "Blocked", "WaveStatus", true, 6, "Blocked" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000036"), null, "Draft", "RunbookStatus", true, 1, "Draft" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000037"), null, "In Review", "RunbookStatus", true, 2, "In Review" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000038"), null, "Approved", "RunbookStatus", true, 3, "Approved" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000039"), null, "In Progress", "RunbookStatus", true, 4, "In Progress" },
                    { new Guid("dddddddd-dddd-dddd-dddd-000000000040"), null, "Completed", "RunbookStatus", true, 5, "Completed" }
                });

            migrationBuilder.InsertData(
                table: "MigrationWaves",
                columns: new[] { "Id", "CreatedAt", "CustomerId", "Description", "Name", "PlannedDate", "ProjectId", "Status", "UpdatedAt" },
                values: new object[,]
                {
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000301"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), "Housing service production workload.", "Wave 1 - Housing", new DateOnly(2026, 5, 16), new Guid("22222222-2222-2222-2222-222222222222"), "In Progress", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000302"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), "Document management application and indexing tier.", "Wave 2 - Documents", new DateOnly(2026, 6, 20), new Guid("22222222-2222-2222-2222-222222222222"), "Planning", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000303"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), "Revenues, environment and residual corporate workloads.", "Wave 3 - Corporate", new DateOnly(2026, 8, 15), new Guid("22222222-2222-2222-2222-222222222222"), "Not Started", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) }
                });

            migrationBuilder.InsertData(
                table: "Subnets",
                columns: new[] { "Id", "Cidr", "CreatedAt", "CustomerId", "Environment", "Name", "ProjectId", "UpdatedAt", "VNetName" },
                values: new object[,]
                {
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000201"), "10.80.10.0/27", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), "Prod", "snet-prod-app", new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), "vnet-lgr-prod-uks-01" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000202"), "10.80.20.0/27", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), "Prod", "snet-prod-data", new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), "vnet-lgr-data-uks-01" }
                });

            migrationBuilder.InsertData(
                table: "IpAddresses",
                columns: new[] { "Id", "Address", "AllocatedAt", "CreatedAt", "CustomerId", "ProjectId", "ReservedAt", "ServerId", "Status", "SubnetId", "UpdatedAt" },
                values: new object[,]
                {
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000703"), "10.80.10.6", null, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, null, "Available", new Guid("cccccccc-cccc-cccc-cccc-000000000201"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000704"), "10.80.10.7", null, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, null, "Available", new Guid("cccccccc-cccc-cccc-cccc-000000000201"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000705"), "10.80.10.8", null, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, null, "Available", new Guid("cccccccc-cccc-cccc-cccc-000000000201"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000706"), "10.80.10.9", null, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, null, "Available", new Guid("cccccccc-cccc-cccc-cccc-000000000201"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000707"), "10.80.10.10", null, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, null, "Available", new Guid("cccccccc-cccc-cccc-cccc-000000000201"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000708"), "10.80.10.11", null, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, null, "Available", new Guid("cccccccc-cccc-cccc-cccc-000000000201"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000709"), "10.80.10.12", null, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, null, "Available", new Guid("cccccccc-cccc-cccc-cccc-000000000201"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000710"), "10.80.10.13", null, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, null, "Available", new Guid("cccccccc-cccc-cccc-cccc-000000000201"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000722"), "10.80.20.5", null, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, null, "Available", new Guid("cccccccc-cccc-cccc-cccc-000000000202"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000723"), "10.80.20.6", null, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, null, "Available", new Guid("cccccccc-cccc-cccc-cccc-000000000202"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000724"), "10.80.20.7", null, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, null, "Available", new Guid("cccccccc-cccc-cccc-cccc-000000000202"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000725"), "10.80.20.8", null, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, null, "Available", new Guid("cccccccc-cccc-cccc-cccc-000000000202"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000726"), "10.80.20.9", null, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, null, "Available", new Guid("cccccccc-cccc-cccc-cccc-000000000202"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000727"), "10.80.20.10", null, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, null, "Available", new Guid("cccccccc-cccc-cccc-cccc-000000000202"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000728"), "10.80.20.11", null, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, null, "Available", new Guid("cccccccc-cccc-cccc-cccc-000000000202"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000729"), "10.80.20.12", null, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, null, "Available", new Guid("cccccccc-cccc-cccc-cccc-000000000202"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000730"), "10.80.20.13", null, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, null, "Available", new Guid("cccccccc-cccc-cccc-cccc-000000000202"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) }
                });

            migrationBuilder.InsertData(
                table: "Projects",
                columns: new[] { "Id", "CreatedAt", "CustomerId", "Description", "Name", "PlannedEndDate", "PlannedStartDate", "Status", "UpdatedAt" },
                values: new object[] { new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), "Fictional programme demonstrating discovery, assessment, design and migration planning.", "LGR Azure Transformation Programme", new DateOnly(2027, 3, 31), new DateOnly(2026, 2, 1), "Active", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) });

            migrationBuilder.InsertData(
                table: "Runbooks",
                columns: new[] { "Id", "CreatedAt", "CustomerId", "MigrationWaveId", "Name", "ProjectId", "Status", "UpdatedAt" },
                values: new object[] { new Guid("cccccccc-cccc-cccc-cccc-000000000501"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("cccccccc-cccc-cccc-cccc-000000000301"), "Wave 1 - Housing Migration Runbook", new Guid("22222222-2222-2222-2222-222222222222"), "Draft", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) });

            migrationBuilder.InsertData(
                table: "Applications",
                columns: new[] { "Id", "ApplicationType", "CreatedAt", "Criticality", "CurrentVersion", "CustomerId", "Description", "Environment", "MigrationScope", "MigrationStatus", "MigrationStrategy", "Name", "ProjectId", "UpdatedAt" },
                values: new object[,]
                {
                    { new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000001"), "COTS", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), "Critical", "2024.3", new Guid("11111111-1111-1111-1111-111111111111"), "Fictional housing management workload.", "Prod", "In Scope", "In Progress", "Rehost", "Housing Management", new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000002"), "COTS", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), "Critical", "8.7", new Guid("11111111-1111-1111-1111-111111111111"), "Fictional revenues and benefits workload.", "Prod", "In Scope", "Not Started", "Build Ahead", "Revenues and Benefits", new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000003"), "COTS", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), "High", "12.2", new Guid("11111111-1111-1111-1111-111111111111"), "Fictional document management workload.", "Prod", "In Scope", "In Progress", "Replatform", "Document Management", new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000004"), "Custom", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), "Medium", "5.4", new Guid("11111111-1111-1111-1111-111111111111"), "Fictional environmental services workload.", "Prod", "Under Review", "Not Started", "Investigate", "Environmental Services", new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000005"), "COTS", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), "High", "2025 R1", new Guid("11111111-1111-1111-1111-111111111111"), "Fictional finance workload.", "Prod", "In Scope", "Completed", "SaaS", "Finance", new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) }
                });

            migrationBuilder.InsertData(
                table: "RunbookTasks",
                columns: new[] { "Id", "ActualEnd", "ActualStart", "Category", "Comment", "CustomerId", "Owner", "PlannedEnd", "PlannedStart", "ProjectId", "RunbookId", "Sequence", "Status", "Task" },
                values: new object[,]
                {
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000600"), null, null, "Pre-Migration Checks", "", new Guid("11111111-1111-1111-1111-111111111111"), "Migration Lead", null, null, new Guid("22222222-2222-2222-2222-222222222222"), new Guid("cccccccc-cccc-cccc-cccc-000000000501"), 1, "Not Started", "Pre-Migration Checks" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000601"), null, null, "Backup Validation", "", new Guid("11111111-1111-1111-1111-111111111111"), "Migration Lead", null, null, new Guid("22222222-2222-2222-2222-222222222222"), new Guid("cccccccc-cccc-cccc-cccc-000000000501"), 2, "Not Started", "Backup Validation" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000602"), null, null, "Network Validation", "", new Guid("11111111-1111-1111-1111-111111111111"), "Migration Lead", null, null, new Guid("22222222-2222-2222-2222-222222222222"), new Guid("cccccccc-cccc-cccc-cccc-000000000501"), 3, "Not Started", "Network Validation" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000603"), null, null, "Application Preparation", "", new Guid("11111111-1111-1111-1111-111111111111"), "Migration Lead", null, null, new Guid("22222222-2222-2222-2222-222222222222"), new Guid("cccccccc-cccc-cccc-cccc-000000000501"), 4, "Not Started", "Application Preparation" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000604"), null, null, "Stop Application Services", "", new Guid("11111111-1111-1111-1111-111111111111"), "Technical Team", null, null, new Guid("22222222-2222-2222-2222-222222222222"), new Guid("cccccccc-cccc-cccc-cccc-000000000501"), 5, "Not Started", "Stop Application Services" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000605"), null, null, "Migration Activity", "", new Guid("11111111-1111-1111-1111-111111111111"), "Technical Team", null, null, new Guid("22222222-2222-2222-2222-222222222222"), new Guid("cccccccc-cccc-cccc-cccc-000000000501"), 6, "Not Started", "Migration Activity" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000606"), null, null, "Start Azure Workload", "", new Guid("11111111-1111-1111-1111-111111111111"), "Technical Team", null, null, new Guid("22222222-2222-2222-2222-222222222222"), new Guid("cccccccc-cccc-cccc-cccc-000000000501"), 7, "Not Started", "Start Azure Workload" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000607"), null, null, "DNS / Connectivity Validation", "", new Guid("11111111-1111-1111-1111-111111111111"), "Technical Team", null, null, new Guid("22222222-2222-2222-2222-222222222222"), new Guid("cccccccc-cccc-cccc-cccc-000000000501"), 8, "Not Started", "DNS / Connectivity Validation" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000608"), null, null, "Technical Validation", "", new Guid("11111111-1111-1111-1111-111111111111"), "Technical Team", null, null, new Guid("22222222-2222-2222-2222-222222222222"), new Guid("cccccccc-cccc-cccc-cccc-000000000501"), 9, "Not Started", "Technical Validation" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000609"), null, null, "Business Validation", "", new Guid("11111111-1111-1111-1111-111111111111"), "Technical Team", null, null, new Guid("22222222-2222-2222-2222-222222222222"), new Guid("cccccccc-cccc-cccc-cccc-000000000501"), 10, "Not Started", "Business Validation" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000610"), null, null, "Monitoring Validation", "", new Guid("11111111-1111-1111-1111-111111111111"), "Technical Team", null, null, new Guid("22222222-2222-2222-2222-222222222222"), new Guid("cccccccc-cccc-cccc-cccc-000000000501"), 11, "Not Started", "Monitoring Validation" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000611"), null, null, "Backup Validation", "", new Guid("11111111-1111-1111-1111-111111111111"), "Technical Team", null, null, new Guid("22222222-2222-2222-2222-222222222222"), new Guid("cccccccc-cccc-cccc-cccc-000000000501"), 12, "Not Started", "Backup Validation" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000612"), null, null, "Migration Completion", "", new Guid("11111111-1111-1111-1111-111111111111"), "Technical Team", null, null, new Guid("22222222-2222-2222-2222-222222222222"), new Guid("cccccccc-cccc-cccc-cccc-000000000501"), 13, "Not Started", "Migration Completion" }
                });

            migrationBuilder.InsertData(
                table: "Servers",
                columns: new[] { "Id", "AllocatedStorageGb", "CreatedAt", "CustomerId", "Environment", "Hostname", "IpAddress", "MemoryMb", "MigrationStatus", "OperatingSystem", "PowerStatus", "ProjectId", "UpdatedAt", "VCores" },
                values: new object[,]
                {
                    { new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000001"), 250, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), "Prod", "DC-HOU-APP01", "10.20.10.21", 16384, "In Progress", "Windows Server 2022", "On", new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), 4 },
                    { new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000002"), 800, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), "Prod", "DC-HOU-SQL01", "10.20.10.22", 32768, "Not Started", "Windows Server 2022", "On", new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), 8 },
                    { new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000003"), 300, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), "Prod", "DC-REV-APP01", "10.20.10.31", 16384, "Not Started", "Windows Server 2019", "On", new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), 4 },
                    { new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000004"), 1200, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), "Prod", "DC-REV-SQL01", "10.20.10.32", 65536, "Not Started", "Windows Server 2019", "On", new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), 8 },
                    { new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000005"), 400, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), "Prod", "DC-DMS-APP01", "10.20.10.41", 16384, "In Progress", "Red Hat Enterprise Linux 9", "On", new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), 4 },
                    { new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000006"), 600, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), "Prod", "DC-DMS-IDX01", "10.20.10.42", 32768, "In Progress", "Red Hat Enterprise Linux 9", "On", new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), 8 },
                    { new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000007"), 150, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), "Prod", "DC-ENV-WEB01", "10.20.10.51", 8192, "Not Started", "Windows Server 2019", "On", new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), 2 },
                    { new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000008"), 250, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), "Prod", "DC-ENV-APP01", "10.20.10.52", 16384, "Blocked", "Windows Server 2019", "On", new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), 4 },
                    { new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000009"), 200, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), "Prod", "DC-FIN-APP01", "10.20.10.61", 16384, "Completed", "Windows Server 2022", "On", new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), 4 },
                    { new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000010"), 700, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), "Prod", "DC-FIN-SQL01", "10.20.10.62", 32768, "Completed", "Windows Server 2022", "On", new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), 8 }
                });

            migrationBuilder.InsertData(
                table: "ApplicationServers",
                columns: new[] { "Id", "ApplicationId", "CustomerId", "ProjectId", "ServerId" },
                values: new object[,]
                {
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000101"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000001"), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000001") },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000102"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000001"), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000002") },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000103"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000002"), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000003") },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000104"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000002"), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000004") },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000105"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000003"), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000005") },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000106"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000003"), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000006") },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000107"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000004"), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000007") },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000108"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000004"), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000008") },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000109"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000005"), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000009") },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000110"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000005"), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000010") }
                });

            migrationBuilder.InsertData(
                table: "AzureTargets",
                columns: new[] { "Id", "AzureHostname", "AzureIp", "BackupPolicy", "CreatedAt", "CustomerId", "Domain", "Notes", "OperatingSystem", "OrganisationalUnit", "ProjectId", "ResourceGroup", "ServerId", "Subnet", "Subscription", "UpdatedAt", "VNet", "VmSize" },
                values: new object[,]
                {
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000801"), "az-hou-app01", "10.80.10.4", "Enhanced-30Day", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), "demo-council.example", "POC target build example.", "Azure supported image", "OU=Azure,OU=Servers", new Guid("22222222-2222-2222-2222-222222222222"), "rg-lgr-prod-uks-01", new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000001"), "snet-prod-app", "LGR-Production", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), "vnet-lgr-prod-uks-01", "Standard_D4s_v5" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000802"), "az-hou-sql01", "10.80.20.4", "Enhanced-30Day", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), "demo-council.example", "POC target build example.", "Azure supported image", "OU=Azure,OU=Servers", new Guid("22222222-2222-2222-2222-222222222222"), "rg-lgr-prod-uks-01", new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000002"), "snet-prod-data", "LGR-Production", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), "vnet-lgr-data-uks-01", "Standard_E8s_v5" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000803"), "az-rev-app01", "10.80.10.5", "Enhanced-30Day", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), "demo-council.example", "POC target build example.", "Azure supported image", "OU=Azure,OU=Servers", new Guid("22222222-2222-2222-2222-222222222222"), "rg-lgr-prod-uks-01", new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000003"), "snet-prod-app", "LGR-Production", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), "vnet-lgr-prod-uks-01", "Standard_D4s_v5" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000804"), "az-dms-app01", "10.80.10.7", "Enhanced-30Day", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), "demo-council.example", "POC target build example.", "Azure supported image", "OU=Azure,OU=Servers", new Guid("22222222-2222-2222-2222-222222222222"), "rg-lgr-prod-uks-01", new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000005"), "snet-prod-app", "LGR-Production", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), "vnet-lgr-prod-uks-01", "Standard_D4s_v5" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000805"), "az-dms-idx01", "10.80.20.7", "Enhanced-30Day", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), "demo-council.example", "POC target build example.", "Azure supported image", "OU=Azure,OU=Servers", new Guid("22222222-2222-2222-2222-222222222222"), "rg-lgr-prod-uks-01", new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000006"), "snet-prod-data", "LGR-Production", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), "vnet-lgr-data-uks-01", "Standard_E8s_v5" }
                });

            migrationBuilder.InsertData(
                table: "IpAddresses",
                columns: new[] { "Id", "Address", "AllocatedAt", "CreatedAt", "CustomerId", "ProjectId", "ReservedAt", "ServerId", "Status", "SubnetId", "UpdatedAt" },
                values: new object[,]
                {
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000701"), "10.80.10.4", new DateTimeOffset(new DateTime(2026, 1, 29, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(2026, 1, 25, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000001"), "Allocated", new Guid("cccccccc-cccc-cccc-cccc-000000000201"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000702"), "10.80.10.5", null, new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(2026, 1, 25, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000003"), "Reserved", new Guid("cccccccc-cccc-cccc-cccc-000000000201"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000721"), "10.80.20.4", new DateTimeOffset(new DateTime(2026, 1, 29, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new DateTimeOffset(new DateTime(2026, 1, 25, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000002"), "Allocated", new Guid("cccccccc-cccc-cccc-cccc-000000000202"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) }
                });

            migrationBuilder.InsertData(
                table: "MigrationDecisions",
                columns: new[] { "Id", "ApplicationId", "CreatedAt", "CustomerId", "DecisionDate", "DecisionStatus", "MigrationScope", "MigrationStrategy", "ProjectId", "Reason", "Risk", "TargetPlatform", "UpdatedAt" },
                values: new object[,]
                {
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000401"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000001"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new DateOnly(2026, 2, 12), "Approved", "In Scope", "Rehost", new Guid("22222222-2222-2222-2222-222222222222"), "Vendor supports lift and optimise after migration.", "Medium", "Azure Virtual Machines", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000402"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000002"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new DateOnly(2026, 2, 18), "Approved", "In Scope", "Build Ahead", new Guid("22222222-2222-2222-2222-222222222222"), "Operating system refresh required before cutover.", "High", "Azure Virtual Machines", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000403"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000003"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), null, "Proposed", "In Scope", "Replatform", new Guid("22222222-2222-2222-2222-222222222222"), "Supported managed platform target.", "Medium", "Azure App Service and Azure SQL", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000404"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000004"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), null, "Draft", "Under Review", "Investigate", new Guid("22222222-2222-2222-2222-222222222222"), "Dependency discovery remains incomplete.", "High", "To be confirmed", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000405"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000005"), new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)), new Guid("11111111-1111-1111-1111-111111111111"), new DateOnly(2026, 1, 30), "Approved", "In Scope", "SaaS", new Guid("22222222-2222-2222-2222-222222222222"), "SaaS transition completed before infrastructure waves.", "Low", "Vendor SaaS", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) }
                });

            migrationBuilder.InsertData(
                table: "ReadinessChecks",
                columns: new[] { "Id", "ApplicationId", "CheckType", "Comment", "CustomerId", "ProjectId", "ServerId", "Status", "UpdatedAt" },
                values: new object[,]
                {
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001001"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000001"), "DiscoveryComplete", "Inventory owner confirmed.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, "Complete", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001002"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000001"), "MigrationDecisionApproved", "Decision recorded.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, "Complete", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001003"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000001"), "BusinessTestingDefined", "Test plan agreed.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, "Complete", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001004"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000002"), "DiscoveryComplete", "Inventory owner confirmed.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, "Complete", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001005"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000002"), "MigrationDecisionApproved", "Decision recorded.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, "Complete", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001006"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000002"), "BusinessTestingDefined", "Test lead action outstanding.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, "AtRisk", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001007"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000003"), "DiscoveryComplete", "Inventory owner confirmed.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, "Complete", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001008"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000003"), "MigrationDecisionApproved", "Decision recorded.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, "Complete", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001009"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000003"), "BusinessTestingDefined", "Test lead action outstanding.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, "AtRisk", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001010"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000004"), "DiscoveryComplete", "Inventory owner confirmed.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, "Complete", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001011"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000004"), "MigrationDecisionApproved", "Architecture decision required.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, "Blocked", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001012"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000004"), "BusinessTestingDefined", "Test plan agreed.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, "Complete", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001013"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000005"), "DiscoveryComplete", "Inventory owner confirmed.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, "Complete", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001014"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000005"), "MigrationDecisionApproved", "Decision recorded.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, "Complete", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001015"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000005"), "BusinessTestingDefined", "Test plan agreed.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), null, "Complete", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001016"), null, "AzureTargetDefined", "Target build reviewed.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000001"), "Complete", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001017"), null, "IpAllocated", "IP plan status recorded.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000001"), "Complete", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001018"), null, "AzureTargetDefined", "Target build reviewed.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000002"), "Complete", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001019"), null, "IpAllocated", "IP plan status recorded.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000002"), "Complete", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001020"), null, "AzureTargetDefined", "Target build reviewed.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000003"), "Complete", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001021"), null, "IpAllocated", "IP plan status recorded.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000003"), "NotStarted", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001022"), null, "AzureTargetDefined", "Target build reviewed.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000004"), "Complete", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001023"), null, "IpAllocated", "IP plan status recorded.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000004"), "NotStarted", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001024"), null, "AzureTargetDefined", "Target build reviewed.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000005"), "Complete", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001025"), null, "IpAllocated", "IP plan status recorded.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000005"), "NotStarted", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001026"), null, "AzureTargetDefined", "Target build reviewed.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000006"), "Complete", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001027"), null, "IpAllocated", "IP plan status recorded.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000006"), "NotStarted", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001028"), null, "AzureTargetDefined", "Target not yet designed.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000007"), "NotStarted", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001029"), null, "IpAllocated", "IP plan status recorded.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000007"), "NotStarted", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001030"), null, "AzureTargetDefined", "Target not yet designed.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000008"), "NotStarted", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001031"), null, "IpAllocated", "Network route decision blocked.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000008"), "Blocked", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001032"), null, "AzureTargetDefined", "Target not yet designed.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000009"), "NotStarted", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001033"), null, "IpAllocated", "IP plan status recorded.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000009"), "NotStarted", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001034"), null, "AzureTargetDefined", "Target not yet designed.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000010"), "NotStarted", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000001035"), null, "IpAllocated", "IP plan status recorded.", new Guid("11111111-1111-1111-1111-111111111111"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000010"), "NotStarted", new DateTimeOffset(new DateTime(2026, 1, 15, 9, 0, 0, 0, DateTimeKind.Unspecified), new TimeSpan(0, 0, 0, 0, 0)) }
                });

            migrationBuilder.InsertData(
                table: "WaveAssets",
                columns: new[] { "Id", "ApplicationId", "CustomerId", "MigrationWaveId", "ProjectId", "ServerId", "Status" },
                values: new object[,]
                {
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000901"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000001"), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("cccccccc-cccc-cccc-cccc-000000000301"), new Guid("22222222-2222-2222-2222-222222222222"), null, "Planned" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000902"), null, new Guid("11111111-1111-1111-1111-111111111111"), new Guid("cccccccc-cccc-cccc-cccc-000000000301"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000001"), "Planned" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000903"), null, new Guid("11111111-1111-1111-1111-111111111111"), new Guid("cccccccc-cccc-cccc-cccc-000000000301"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000002"), "Planned" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000904"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000003"), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("cccccccc-cccc-cccc-cccc-000000000302"), new Guid("22222222-2222-2222-2222-222222222222"), null, "Planned" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000905"), null, new Guid("11111111-1111-1111-1111-111111111111"), new Guid("cccccccc-cccc-cccc-cccc-000000000302"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000005"), "Planned" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000906"), null, new Guid("11111111-1111-1111-1111-111111111111"), new Guid("cccccccc-cccc-cccc-cccc-000000000302"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000006"), "Planned" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000907"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000002"), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("cccccccc-cccc-cccc-cccc-000000000303"), new Guid("22222222-2222-2222-2222-222222222222"), null, "Planned" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000908"), new Guid("aaaaaaaa-aaaa-aaaa-aaaa-000000000004"), new Guid("11111111-1111-1111-1111-111111111111"), new Guid("cccccccc-cccc-cccc-cccc-000000000303"), new Guid("22222222-2222-2222-2222-222222222222"), null, "Planned" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000909"), null, new Guid("11111111-1111-1111-1111-111111111111"), new Guid("cccccccc-cccc-cccc-cccc-000000000303"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000003"), "Planned" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000910"), null, new Guid("11111111-1111-1111-1111-111111111111"), new Guid("cccccccc-cccc-cccc-cccc-000000000303"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000004"), "Planned" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000911"), null, new Guid("11111111-1111-1111-1111-111111111111"), new Guid("cccccccc-cccc-cccc-cccc-000000000303"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000007"), "Planned" },
                    { new Guid("cccccccc-cccc-cccc-cccc-000000000912"), null, new Guid("11111111-1111-1111-1111-111111111111"), new Guid("cccccccc-cccc-cccc-cccc-000000000303"), new Guid("22222222-2222-2222-2222-222222222222"), new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000008"), "Planned" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_Applications_CustomerId_ProjectId",
                table: "Applications",
                columns: new[] { "CustomerId", "ProjectId" });

            migrationBuilder.CreateIndex(
                name: "IX_Applications_ProjectId",
                table: "Applications",
                column: "ProjectId");

            migrationBuilder.CreateIndex(
                name: "IX_ApplicationServers_ApplicationId",
                table: "ApplicationServers",
                column: "ApplicationId");

            migrationBuilder.CreateIndex(
                name: "IX_ApplicationServers_CustomerId_ApplicationId_ServerId",
                table: "ApplicationServers",
                columns: new[] { "CustomerId", "ApplicationId", "ServerId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ApplicationServers_ServerId",
                table: "ApplicationServers",
                column: "ServerId");

            migrationBuilder.CreateIndex(
                name: "IX_AuditEvents_CustomerId_ProjectId_ChangedAt",
                table: "AuditEvents",
                columns: new[] { "CustomerId", "ProjectId", "ChangedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_AzureTargets_CustomerId_ProjectId",
                table: "AzureTargets",
                columns: new[] { "CustomerId", "ProjectId" });

            migrationBuilder.CreateIndex(
                name: "IX_AzureTargets_CustomerId_ServerId",
                table: "AzureTargets",
                columns: new[] { "CustomerId", "ServerId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_AzureTargets_ServerId",
                table: "AzureTargets",
                column: "ServerId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Customers_Code",
                table: "Customers",
                column: "Code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_IpAddresses_CustomerId_ProjectId_Status",
                table: "IpAddresses",
                columns: new[] { "CustomerId", "ProjectId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_IpAddresses_CustomerId_ServerId",
                table: "IpAddresses",
                columns: new[] { "CustomerId", "ServerId" },
                unique: true,
                filter: "[ServerId] IS NOT NULL AND [Status] IN ('Reserved', 'Allocated')");

            migrationBuilder.CreateIndex(
                name: "IX_IpAddresses_CustomerId_SubnetId_Address",
                table: "IpAddresses",
                columns: new[] { "CustomerId", "SubnetId", "Address" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_IpAddresses_ServerId",
                table: "IpAddresses",
                column: "ServerId");

            migrationBuilder.CreateIndex(
                name: "IX_IpAddresses_SubnetId",
                table: "IpAddresses",
                column: "SubnetId");

            migrationBuilder.CreateIndex(
                name: "IX_LookupOptions_CustomerId_Group_Value",
                table: "LookupOptions",
                columns: new[] { "CustomerId", "Group", "Value" },
                unique: true,
                filter: "[CustomerId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_MigrationDecisions_ApplicationId",
                table: "MigrationDecisions",
                column: "ApplicationId");

            migrationBuilder.CreateIndex(
                name: "IX_MigrationDecisions_CustomerId_ProjectId",
                table: "MigrationDecisions",
                columns: new[] { "CustomerId", "ProjectId" });

            migrationBuilder.CreateIndex(
                name: "IX_MigrationWaves_CustomerId_ProjectId",
                table: "MigrationWaves",
                columns: new[] { "CustomerId", "ProjectId" });

            migrationBuilder.CreateIndex(
                name: "IX_Projects_CustomerId",
                table: "Projects",
                column: "CustomerId");

            migrationBuilder.CreateIndex(
                name: "IX_ReadinessChecks_ApplicationId",
                table: "ReadinessChecks",
                column: "ApplicationId");

            migrationBuilder.CreateIndex(
                name: "IX_ReadinessChecks_CustomerId_ProjectId",
                table: "ReadinessChecks",
                columns: new[] { "CustomerId", "ProjectId" });

            migrationBuilder.CreateIndex(
                name: "IX_ReadinessChecks_ServerId",
                table: "ReadinessChecks",
                column: "ServerId");

            migrationBuilder.CreateIndex(
                name: "IX_Runbooks_CustomerId_ProjectId",
                table: "Runbooks",
                columns: new[] { "CustomerId", "ProjectId" });

            migrationBuilder.CreateIndex(
                name: "IX_Runbooks_MigrationWaveId",
                table: "Runbooks",
                column: "MigrationWaveId");

            migrationBuilder.CreateIndex(
                name: "IX_RunbookTasks_CustomerId_ProjectId",
                table: "RunbookTasks",
                columns: new[] { "CustomerId", "ProjectId" });

            migrationBuilder.CreateIndex(
                name: "IX_RunbookTasks_RunbookId_Sequence",
                table: "RunbookTasks",
                columns: new[] { "RunbookId", "Sequence" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Servers_CustomerId_Hostname",
                table: "Servers",
                columns: new[] { "CustomerId", "Hostname" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Servers_CustomerId_ProjectId",
                table: "Servers",
                columns: new[] { "CustomerId", "ProjectId" });

            migrationBuilder.CreateIndex(
                name: "IX_Servers_ProjectId",
                table: "Servers",
                column: "ProjectId");

            migrationBuilder.CreateIndex(
                name: "IX_Subnets_CustomerId_ProjectId_Name",
                table: "Subnets",
                columns: new[] { "CustomerId", "ProjectId", "Name" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_WaveAssets_ApplicationId",
                table: "WaveAssets",
                column: "ApplicationId");

            migrationBuilder.CreateIndex(
                name: "IX_WaveAssets_CustomerId_MigrationWaveId",
                table: "WaveAssets",
                columns: new[] { "CustomerId", "MigrationWaveId" });

            migrationBuilder.CreateIndex(
                name: "IX_WaveAssets_MigrationWaveId",
                table: "WaveAssets",
                column: "MigrationWaveId");

            migrationBuilder.CreateIndex(
                name: "IX_WaveAssets_ServerId",
                table: "WaveAssets",
                column: "ServerId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ApplicationServers");

            migrationBuilder.DropTable(
                name: "AuditEvents");

            migrationBuilder.DropTable(
                name: "AzureTargets");

            migrationBuilder.DropTable(
                name: "IpAddresses");

            migrationBuilder.DropTable(
                name: "LookupOptions");

            migrationBuilder.DropTable(
                name: "MigrationDecisions");

            migrationBuilder.DropTable(
                name: "ReadinessChecks");

            migrationBuilder.DropTable(
                name: "RunbookTasks");

            migrationBuilder.DropTable(
                name: "WaveAssets");

            migrationBuilder.DropTable(
                name: "Subnets");

            migrationBuilder.DropTable(
                name: "Runbooks");

            migrationBuilder.DropTable(
                name: "Applications");

            migrationBuilder.DropTable(
                name: "Servers");

            migrationBuilder.DropTable(
                name: "MigrationWaves");

            migrationBuilder.DropTable(
                name: "Projects");

            migrationBuilder.DropTable(
                name: "Customers");
        }
    }
}
