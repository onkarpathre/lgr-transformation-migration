using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LgrTransformationMigration.Api.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDiscoveryImport : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "DiscoveryMethod",
                table: "Servers",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ExternalSourceId",
                table: "Servers",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "FirstDiscoveredAt",
                table: "Servers",
                type: "datetimeoffset",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Host",
                table: "Servers",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "HypervisorType",
                table: "Servers",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastDiscoveredAt",
                table: "Servers",
                type: "datetimeoffset",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "LastImportBatchId",
                table: "Servers",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LastImportedAt",
                table: "Servers",
                type: "datetimeoffset",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "MigrationScope",
                table: "Servers",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "MigrationStrategy",
                table: "Servers",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "OsArchitecture",
                table: "Servers",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "OsFamily",
                table: "Servers",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Processor",
                table: "Servers",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SupportStatus",
                table: "Servers",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "ImportBatches",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SourceType = table.Column<string>(type: "nvarchar(80)", maxLength: 80, nullable: false),
                    OriginalFileName = table.Column<string>(type: "nvarchar(260)", maxLength: 260, nullable: false),
                    StoredFileName = table.Column<string>(type: "nvarchar(260)", maxLength: 260, nullable: true),
                    FileHash = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false),
                    FileSizeBytes = table.Column<long>(type: "bigint", nullable: false),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    UploadedBy = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    UploadedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    PreviewedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    CommittedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    TotalRows = table.Column<int>(type: "int", nullable: false),
                    ValidRows = table.Column<int>(type: "int", nullable: false),
                    CreateCount = table.Column<int>(type: "int", nullable: false),
                    UpdateCount = table.Column<int>(type: "int", nullable: false),
                    UnchangedCount = table.Column<int>(type: "int", nullable: false),
                    WarningCount = table.Column<int>(type: "int", nullable: false),
                    RejectCount = table.Column<int>(type: "int", nullable: false),
                    Notes = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ImportBatches", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ImportBatches_Projects_ProjectId",
                        column: x => x.ProjectId,
                        principalTable: "Projects",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "DiscoveryImportRows",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ImportBatchId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    RowNumber = table.Column<int>(type: "int", nullable: false),
                    SourceRecordId = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    SourceType = table.Column<string>(type: "nvarchar(80)", maxLength: 80, nullable: false),
                    RawDataJson = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    NormalizedHostname = table.Column<string>(type: "nvarchar(253)", maxLength: 253, nullable: true),
                    Classification = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    ValidationStatus = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    ValidationMessagesJson = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    MatchedEntityId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    ProposedChangesJson = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DiscoveryImportRows", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DiscoveryImportRows_ImportBatches_ImportBatchId",
                        column: x => x.ImportBatchId,
                        principalTable: "ImportBatches",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_DiscoveryImportRows_Servers_MatchedEntityId",
                        column: x => x.MatchedEntityId,
                        principalTable: "Servers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ServerDiscoverySnapshots",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ServerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ImportBatchId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ExternalSourceId = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    Hostname = table.Column<string>(type: "nvarchar(253)", maxLength: 253, nullable: false),
                    Environment = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    MigrationIntent = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    IpAddresses = table.Column<string>(type: "nvarchar(2000)", maxLength: 2000, nullable: true),
                    OperatingSystem = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    Dependencies = table.Column<string>(type: "nvarchar(4000)", maxLength: 4000, nullable: true),
                    SoftwareCount = table.Column<int>(type: "int", nullable: true),
                    DatabaseInstanceCount = table.Column<int>(type: "int", nullable: true),
                    WebAppCount = table.Column<int>(type: "int", nullable: true),
                    FileShareCount = table.Column<int>(type: "int", nullable: true),
                    SecurityRisks = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    SupportStatus = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    ApplicationNames = table.Column<string>(type: "nvarchar(4000)", maxLength: 4000, nullable: true),
                    IssueCount = table.Column<int>(type: "int", nullable: true),
                    Tags = table.Column<string>(type: "nvarchar(4000)", maxLength: 4000, nullable: true),
                    Host = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    MemoryMb = table.Column<int>(type: "int", nullable: true),
                    DiskCount = table.Column<int>(type: "int", nullable: true),
                    VCores = table.Column<int>(type: "int", nullable: true),
                    AllocatedStorageGb = table.Column<int>(type: "int", nullable: true),
                    NetworkAdapterCount = table.Column<int>(type: "int", nullable: true),
                    MacAddress = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    BootType = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    OsFamily = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    OsArchitecture = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    Processor = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    ResourceType = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    PowerStatus = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    HypervisorType = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    DiscoveryMethod = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    ConnectedAppliance = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    FirstDiscoveredAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    LastUpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    ImportedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ServerDiscoverySnapshots", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ServerDiscoverySnapshots_ImportBatches_ImportBatchId",
                        column: x => x.ImportBatchId,
                        principalTable: "ImportBatches",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_ServerDiscoverySnapshots_Servers_ServerId",
                        column: x => x.ServerId,
                        principalTable: "Servers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.UpdateData(
                table: "Servers",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000001"),
                columns: new[] { "DiscoveryMethod", "ExternalSourceId", "FirstDiscoveredAt", "Host", "HypervisorType", "LastDiscoveredAt", "LastImportBatchId", "LastImportedAt", "MigrationScope", "MigrationStrategy", "OsArchitecture", "OsFamily", "Processor", "SupportStatus" },
                values: new object[] { null, null, null, null, null, null, null, null, "", "", null, null, null, null });

            migrationBuilder.UpdateData(
                table: "Servers",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000002"),
                columns: new[] { "DiscoveryMethod", "ExternalSourceId", "FirstDiscoveredAt", "Host", "HypervisorType", "LastDiscoveredAt", "LastImportBatchId", "LastImportedAt", "MigrationScope", "MigrationStrategy", "OsArchitecture", "OsFamily", "Processor", "SupportStatus" },
                values: new object[] { null, null, null, null, null, null, null, null, "", "", null, null, null, null });

            migrationBuilder.UpdateData(
                table: "Servers",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000003"),
                columns: new[] { "DiscoveryMethod", "ExternalSourceId", "FirstDiscoveredAt", "Host", "HypervisorType", "LastDiscoveredAt", "LastImportBatchId", "LastImportedAt", "MigrationScope", "MigrationStrategy", "OsArchitecture", "OsFamily", "Processor", "SupportStatus" },
                values: new object[] { null, null, null, null, null, null, null, null, "", "", null, null, null, null });

            migrationBuilder.UpdateData(
                table: "Servers",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000004"),
                columns: new[] { "DiscoveryMethod", "ExternalSourceId", "FirstDiscoveredAt", "Host", "HypervisorType", "LastDiscoveredAt", "LastImportBatchId", "LastImportedAt", "MigrationScope", "MigrationStrategy", "OsArchitecture", "OsFamily", "Processor", "SupportStatus" },
                values: new object[] { null, null, null, null, null, null, null, null, "", "", null, null, null, null });

            migrationBuilder.UpdateData(
                table: "Servers",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000005"),
                columns: new[] { "DiscoveryMethod", "ExternalSourceId", "FirstDiscoveredAt", "Host", "HypervisorType", "LastDiscoveredAt", "LastImportBatchId", "LastImportedAt", "MigrationScope", "MigrationStrategy", "OsArchitecture", "OsFamily", "Processor", "SupportStatus" },
                values: new object[] { null, null, null, null, null, null, null, null, "", "", null, null, null, null });

            migrationBuilder.UpdateData(
                table: "Servers",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000006"),
                columns: new[] { "DiscoveryMethod", "ExternalSourceId", "FirstDiscoveredAt", "Host", "HypervisorType", "LastDiscoveredAt", "LastImportBatchId", "LastImportedAt", "MigrationScope", "MigrationStrategy", "OsArchitecture", "OsFamily", "Processor", "SupportStatus" },
                values: new object[] { null, null, null, null, null, null, null, null, "", "", null, null, null, null });

            migrationBuilder.UpdateData(
                table: "Servers",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000007"),
                columns: new[] { "DiscoveryMethod", "ExternalSourceId", "FirstDiscoveredAt", "Host", "HypervisorType", "LastDiscoveredAt", "LastImportBatchId", "LastImportedAt", "MigrationScope", "MigrationStrategy", "OsArchitecture", "OsFamily", "Processor", "SupportStatus" },
                values: new object[] { null, null, null, null, null, null, null, null, "", "", null, null, null, null });

            migrationBuilder.UpdateData(
                table: "Servers",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000008"),
                columns: new[] { "DiscoveryMethod", "ExternalSourceId", "FirstDiscoveredAt", "Host", "HypervisorType", "LastDiscoveredAt", "LastImportBatchId", "LastImportedAt", "MigrationScope", "MigrationStrategy", "OsArchitecture", "OsFamily", "Processor", "SupportStatus" },
                values: new object[] { null, null, null, null, null, null, null, null, "", "", null, null, null, null });

            migrationBuilder.UpdateData(
                table: "Servers",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000009"),
                columns: new[] { "DiscoveryMethod", "ExternalSourceId", "FirstDiscoveredAt", "Host", "HypervisorType", "LastDiscoveredAt", "LastImportBatchId", "LastImportedAt", "MigrationScope", "MigrationStrategy", "OsArchitecture", "OsFamily", "Processor", "SupportStatus" },
                values: new object[] { null, null, null, null, null, null, null, null, "", "", null, null, null, null });

            migrationBuilder.UpdateData(
                table: "Servers",
                keyColumn: "Id",
                keyValue: new Guid("bbbbbbbb-bbbb-bbbb-bbbb-000000000010"),
                columns: new[] { "DiscoveryMethod", "ExternalSourceId", "FirstDiscoveredAt", "Host", "HypervisorType", "LastDiscoveredAt", "LastImportBatchId", "LastImportedAt", "MigrationScope", "MigrationStrategy", "OsArchitecture", "OsFamily", "Processor", "SupportStatus" },
                values: new object[] { null, null, null, null, null, null, null, null, "", "", null, null, null, null });

            migrationBuilder.CreateIndex(
                name: "IX_Servers_LastImportBatchId",
                table: "Servers",
                column: "LastImportBatchId");

            migrationBuilder.CreateIndex(
                name: "IX_DiscoveryImportRows_CustomerId",
                table: "DiscoveryImportRows",
                column: "CustomerId");

            migrationBuilder.CreateIndex(
                name: "IX_DiscoveryImportRows_CustomerId_ProjectId_Classification",
                table: "DiscoveryImportRows",
                columns: new[] { "CustomerId", "ProjectId", "Classification" });

            migrationBuilder.CreateIndex(
                name: "IX_DiscoveryImportRows_ImportBatchId",
                table: "DiscoveryImportRows",
                column: "ImportBatchId");

            migrationBuilder.CreateIndex(
                name: "IX_DiscoveryImportRows_ImportBatchId_RowNumber",
                table: "DiscoveryImportRows",
                columns: new[] { "ImportBatchId", "RowNumber" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_DiscoveryImportRows_MatchedEntityId",
                table: "DiscoveryImportRows",
                column: "MatchedEntityId");

            migrationBuilder.CreateIndex(
                name: "IX_DiscoveryImportRows_ProjectId",
                table: "DiscoveryImportRows",
                column: "ProjectId");

            migrationBuilder.CreateIndex(
                name: "IX_ImportBatches_CustomerId",
                table: "ImportBatches",
                column: "CustomerId");

            migrationBuilder.CreateIndex(
                name: "IX_ImportBatches_CustomerId_FileHash",
                table: "ImportBatches",
                columns: new[] { "CustomerId", "FileHash" });

            migrationBuilder.CreateIndex(
                name: "IX_ImportBatches_CustomerId_ProjectId_Status",
                table: "ImportBatches",
                columns: new[] { "CustomerId", "ProjectId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_ImportBatches_CustomerId_ProjectId_UploadedAt",
                table: "ImportBatches",
                columns: new[] { "CustomerId", "ProjectId", "UploadedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_ImportBatches_ProjectId",
                table: "ImportBatches",
                column: "ProjectId");

            migrationBuilder.CreateIndex(
                name: "IX_ServerDiscoverySnapshots_CustomerId",
                table: "ServerDiscoverySnapshots",
                column: "CustomerId");

            migrationBuilder.CreateIndex(
                name: "IX_ServerDiscoverySnapshots_CustomerId_ProjectId_ServerId_ImportedAt",
                table: "ServerDiscoverySnapshots",
                columns: new[] { "CustomerId", "ProjectId", "ServerId", "ImportedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_ServerDiscoverySnapshots_ImportBatchId",
                table: "ServerDiscoverySnapshots",
                column: "ImportBatchId");

            migrationBuilder.CreateIndex(
                name: "IX_ServerDiscoverySnapshots_ProjectId",
                table: "ServerDiscoverySnapshots",
                column: "ProjectId");

            migrationBuilder.CreateIndex(
                name: "IX_ServerDiscoverySnapshots_ServerId",
                table: "ServerDiscoverySnapshots",
                column: "ServerId");

            migrationBuilder.AddForeignKey(
                name: "FK_Servers_ImportBatches_LastImportBatchId",
                table: "Servers",
                column: "LastImportBatchId",
                principalTable: "ImportBatches",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Servers_ImportBatches_LastImportBatchId",
                table: "Servers");

            migrationBuilder.DropTable(
                name: "DiscoveryImportRows");

            migrationBuilder.DropTable(
                name: "ServerDiscoverySnapshots");

            migrationBuilder.DropTable(
                name: "ImportBatches");

            migrationBuilder.DropIndex(
                name: "IX_Servers_LastImportBatchId",
                table: "Servers");

            migrationBuilder.DropColumn(
                name: "DiscoveryMethod",
                table: "Servers");

            migrationBuilder.DropColumn(
                name: "ExternalSourceId",
                table: "Servers");

            migrationBuilder.DropColumn(
                name: "FirstDiscoveredAt",
                table: "Servers");

            migrationBuilder.DropColumn(
                name: "Host",
                table: "Servers");

            migrationBuilder.DropColumn(
                name: "HypervisorType",
                table: "Servers");

            migrationBuilder.DropColumn(
                name: "LastDiscoveredAt",
                table: "Servers");

            migrationBuilder.DropColumn(
                name: "LastImportBatchId",
                table: "Servers");

            migrationBuilder.DropColumn(
                name: "LastImportedAt",
                table: "Servers");

            migrationBuilder.DropColumn(
                name: "MigrationScope",
                table: "Servers");

            migrationBuilder.DropColumn(
                name: "MigrationStrategy",
                table: "Servers");

            migrationBuilder.DropColumn(
                name: "OsArchitecture",
                table: "Servers");

            migrationBuilder.DropColumn(
                name: "OsFamily",
                table: "Servers");

            migrationBuilder.DropColumn(
                name: "Processor",
                table: "Servers");

            migrationBuilder.DropColumn(
                name: "SupportStatus",
                table: "Servers");
        }
    }
}
