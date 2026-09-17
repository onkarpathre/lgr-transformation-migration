using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LgrTransformationMigration.Api.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddSqlDiscoveryImportHistory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "CommitIdempotencyKeyHash",
                table: "ImportBatches",
                type: "nchar(64)",
                fixedLength: true,
                maxLength: 64,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CommitResultJson",
                table: "ImportBatches",
                type: "nvarchar(2000)",
                maxLength: 2000,
                nullable: true);

            migrationBuilder.AddColumn<byte[]>(
                name: "RowVersion",
                table: "ImportBatches",
                type: "rowversion",
                rowVersion: true,
                nullable: false,
                defaultValue: new byte[0]);

            migrationBuilder.AddColumn<Guid>(
                name: "MatchedSqlDatabaseId",
                table: "DiscoveryImportRows",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "MatchedSqlInstanceId",
                table: "DiscoveryImportRows",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "NormalizedDatabaseName",
                table: "DiscoveryImportRows",
                type: "nvarchar(128)",
                maxLength: 128,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "NormalizedInstanceName",
                table: "DiscoveryImportRows",
                type: "nvarchar(128)",
                maxLength: 128,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ProposedAction",
                table: "DiscoveryImportRows",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ReconciliationFingerprint",
                table: "DiscoveryImportRows",
                type: "nchar(64)",
                fixedLength: true,
                maxLength: 64,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "SqlDatabaseDiscoverySnapshots",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SqlDatabaseId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ImportBatchId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SqlInstanceId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    SizeMb = table.Column<long>(type: "bigint", nullable: false),
                    CompatibilityLevel = table.Column<int>(type: "int", nullable: false),
                    RecoveryModel = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    Collation = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: true),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    ImportedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SqlDatabaseDiscoverySnapshots", x => x.Id);
                    table.CheckConstraint("CK_SqlDatabaseDiscoverySnapshots_CompatibilityLevel", "[CompatibilityLevel] >= 80 AND [CompatibilityLevel] <= 200");
                    table.CheckConstraint("CK_SqlDatabaseDiscoverySnapshots_SizeMb", "[SizeMb] >= 0");
                    table.ForeignKey(
                        name: "FK_SqlDatabaseDiscoverySnapshots_ImportBatches_CustomerId_ProjectId_ImportBatchId",
                        columns: x => new { x.CustomerId, x.ProjectId, x.ImportBatchId },
                        principalTable: "ImportBatches",
                        principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_SqlDatabaseDiscoverySnapshots_SqlDatabases_CustomerId_ProjectId_SqlDatabaseId",
                        columns: x => new { x.CustomerId, x.ProjectId, x.SqlDatabaseId },
                        principalTable: "SqlDatabases",
                        principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "SqlInstanceDiscoverySnapshots",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SqlInstanceId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ImportBatchId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ServerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    InstanceName = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    SqlVersion = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Edition = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Port = table.Column<int>(type: "int", nullable: true),
                    ServiceStatus = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    DiscoverySource = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    LastDiscoveredAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    ImportedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SqlInstanceDiscoverySnapshots", x => x.Id);
                    table.CheckConstraint("CK_SqlInstanceDiscoverySnapshots_Port", "[Port] IS NULL OR ([Port] >= 1 AND [Port] <= 65535)");
                    table.ForeignKey(
                        name: "FK_SqlInstanceDiscoverySnapshots_ImportBatches_CustomerId_ProjectId_ImportBatchId",
                        columns: x => new { x.CustomerId, x.ProjectId, x.ImportBatchId },
                        principalTable: "ImportBatches",
                        principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_SqlInstanceDiscoverySnapshots_SqlInstances_CustomerId_ProjectId_SqlInstanceId",
                        columns: x => new { x.CustomerId, x.ProjectId, x.SqlInstanceId },
                        principalTable: "SqlInstances",
                        principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_DiscoveryImportRows_CustomerId_ProjectId_MatchedSqlDatabaseId",
                table: "DiscoveryImportRows",
                columns: new[] { "CustomerId", "ProjectId", "MatchedSqlDatabaseId" });

            migrationBuilder.CreateIndex(
                name: "IX_DiscoveryImportRows_Owner_DatabaseMatch",
                table: "DiscoveryImportRows",
                columns: new[] { "CustomerId", "ProjectId", "MatchedSqlInstanceId", "NormalizedDatabaseName" });

            migrationBuilder.CreateIndex(
                name: "IX_DiscoveryImportRows_Owner_InstanceMatch",
                table: "DiscoveryImportRows",
                columns: new[] { "CustomerId", "ProjectId", "NormalizedHostname", "NormalizedInstanceName" });

            migrationBuilder.CreateIndex(
                name: "IX_ImportBatches_Owner_CommitIdempotencyKeyHash",
                table: "ImportBatches",
                columns: new[] { "CustomerId", "ProjectId", "CommitIdempotencyKeyHash" },
                filter: "[CommitIdempotencyKeyHash] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_SqlDatabaseDiscoverySnapshots_CustomerId_ProjectId_ImportBatchId",
                table: "SqlDatabaseDiscoverySnapshots",
                columns: new[] { "CustomerId", "ProjectId", "ImportBatchId" });

            migrationBuilder.CreateIndex(
                name: "IX_SqlDatabaseDiscoverySnapshots_Owner_History",
                table: "SqlDatabaseDiscoverySnapshots",
                columns: new[] { "CustomerId", "ProjectId", "SqlDatabaseId", "ImportedAt", "Id" },
                descending: new[] { false, false, false, true, false });

            migrationBuilder.CreateIndex(
                name: "IX_SqlInstanceDiscoverySnapshots_CustomerId_ProjectId_ImportBatchId",
                table: "SqlInstanceDiscoverySnapshots",
                columns: new[] { "CustomerId", "ProjectId", "ImportBatchId" });

            migrationBuilder.CreateIndex(
                name: "IX_SqlInstanceDiscoverySnapshots_Owner_History",
                table: "SqlInstanceDiscoverySnapshots",
                columns: new[] { "CustomerId", "ProjectId", "SqlInstanceId", "ImportedAt", "Id" },
                descending: new[] { false, false, false, true, false });

            migrationBuilder.AddForeignKey(
                name: "FK_DiscoveryImportRows_SqlDatabases_CustomerId_ProjectId_MatchedSqlDatabaseId",
                table: "DiscoveryImportRows",
                columns: new[] { "CustomerId", "ProjectId", "MatchedSqlDatabaseId" },
                principalTable: "SqlDatabases",
                principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_DiscoveryImportRows_SqlInstances_CustomerId_ProjectId_MatchedSqlInstanceId",
                table: "DiscoveryImportRows",
                columns: new[] { "CustomerId", "ProjectId", "MatchedSqlInstanceId" },
                principalTable: "SqlInstances",
                principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_DiscoveryImportRows_SqlDatabases_CustomerId_ProjectId_MatchedSqlDatabaseId",
                table: "DiscoveryImportRows");

            migrationBuilder.DropForeignKey(
                name: "FK_DiscoveryImportRows_SqlInstances_CustomerId_ProjectId_MatchedSqlInstanceId",
                table: "DiscoveryImportRows");

            migrationBuilder.DropTable(
                name: "SqlDatabaseDiscoverySnapshots");

            migrationBuilder.DropTable(
                name: "SqlInstanceDiscoverySnapshots");

            migrationBuilder.DropIndex(
                name: "IX_DiscoveryImportRows_CustomerId_ProjectId_MatchedSqlDatabaseId",
                table: "DiscoveryImportRows");

            migrationBuilder.DropIndex(
                name: "IX_DiscoveryImportRows_Owner_DatabaseMatch",
                table: "DiscoveryImportRows");

            migrationBuilder.DropIndex(
                name: "IX_DiscoveryImportRows_Owner_InstanceMatch",
                table: "DiscoveryImportRows");

            migrationBuilder.DropIndex(
                name: "IX_ImportBatches_Owner_CommitIdempotencyKeyHash",
                table: "ImportBatches");

            migrationBuilder.DropColumn(
                name: "CommitIdempotencyKeyHash",
                table: "ImportBatches");

            migrationBuilder.DropColumn(
                name: "CommitResultJson",
                table: "ImportBatches");

            migrationBuilder.DropColumn(
                name: "RowVersion",
                table: "ImportBatches");

            migrationBuilder.DropColumn(
                name: "MatchedSqlDatabaseId",
                table: "DiscoveryImportRows");

            migrationBuilder.DropColumn(
                name: "MatchedSqlInstanceId",
                table: "DiscoveryImportRows");

            migrationBuilder.DropColumn(
                name: "NormalizedDatabaseName",
                table: "DiscoveryImportRows");

            migrationBuilder.DropColumn(
                name: "NormalizedInstanceName",
                table: "DiscoveryImportRows");

            migrationBuilder.DropColumn(
                name: "ProposedAction",
                table: "DiscoveryImportRows");

            migrationBuilder.DropColumn(
                name: "ReconciliationFingerprint",
                table: "DiscoveryImportRows");
        }
    }
}
