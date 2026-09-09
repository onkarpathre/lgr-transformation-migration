using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LgrTransformationMigration.Api.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddSqlInventory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "CorrelationId",
                table: "AuditEvents",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddUniqueConstraint(
                name: "AK_Servers_CustomerId_ProjectId_Id",
                table: "Servers",
                columns: new[] { "CustomerId", "ProjectId", "Id" });

            migrationBuilder.AddUniqueConstraint(
                name: "AK_Projects_CustomerId_Id",
                table: "Projects",
                columns: new[] { "CustomerId", "Id" });

            migrationBuilder.AddUniqueConstraint(
                name: "AK_ImportBatches_CustomerId_ProjectId_Id",
                table: "ImportBatches",
                columns: new[] { "CustomerId", "ProjectId", "Id" });

            migrationBuilder.CreateTable(
                name: "SqlInstances",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ServerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    InstanceName = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    NormalizedInstanceName = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    SqlVersion = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Edition = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Port = table.Column<int>(type: "int", nullable: true),
                    ServiceStatus = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    DiscoverySource = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    ServiceAccountName = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    LastDiscoveredAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    LastImportBatchId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    LastImportedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    CreatedBy = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    UpdatedBy = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false),
                    DeletedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    DeletedBy = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    RowVersion = table.Column<byte[]>(type: "rowversion", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SqlInstances", x => x.Id);
                    table.UniqueConstraint("AK_SqlInstances_CustomerId_ProjectId_Id", x => new { x.CustomerId, x.ProjectId, x.Id });
                    table.CheckConstraint("CK_SqlInstances_Port", "[Port] IS NULL OR ([Port] >= 1 AND [Port] <= 65535)");
                    table.ForeignKey(
                        name: "FK_SqlInstances_ImportBatches_CustomerId_ProjectId_LastImportBatchId",
                        columns: x => new { x.CustomerId, x.ProjectId, x.LastImportBatchId },
                        principalTable: "ImportBatches",
                        principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_SqlInstances_Projects_CustomerId_ProjectId",
                        columns: x => new { x.CustomerId, x.ProjectId },
                        principalTable: "Projects",
                        principalColumns: new[] { "CustomerId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_SqlInstances_Servers_CustomerId_ProjectId_ServerId",
                        columns: x => new { x.CustomerId, x.ProjectId, x.ServerId },
                        principalTable: "Servers",
                        principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "SqlDatabases",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SqlInstanceId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    NormalizedName = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    SizeMb = table.Column<long>(type: "bigint", nullable: false),
                    CompatibilityLevel = table.Column<int>(type: "int", nullable: false),
                    RecoveryModel = table.Column<string>(type: "nvarchar(30)", maxLength: 30, nullable: false),
                    Collation = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: true),
                    Status = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    LastImportBatchId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    LastImportedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    CreatedBy = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    UpdatedBy = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false),
                    DeletedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    DeletedBy = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    RowVersion = table.Column<byte[]>(type: "rowversion", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SqlDatabases", x => x.Id);
                    table.UniqueConstraint("AK_SqlDatabases_CustomerId_ProjectId_Id", x => new { x.CustomerId, x.ProjectId, x.Id });
                    table.CheckConstraint("CK_SqlDatabases_CompatibilityLevel", "[CompatibilityLevel] >= 80 AND [CompatibilityLevel] <= 200");
                    table.CheckConstraint("CK_SqlDatabases_SizeMb", "[SizeMb] >= 0");
                    table.ForeignKey(
                        name: "FK_SqlDatabases_ImportBatches_CustomerId_ProjectId_LastImportBatchId",
                        columns: x => new { x.CustomerId, x.ProjectId, x.LastImportBatchId },
                        principalTable: "ImportBatches",
                        principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_SqlDatabases_Projects_CustomerId_ProjectId",
                        columns: x => new { x.CustomerId, x.ProjectId },
                        principalTable: "Projects",
                        principalColumns: new[] { "CustomerId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_SqlDatabases_SqlInstances_CustomerId_ProjectId_SqlInstanceId",
                        columns: x => new { x.CustomerId, x.ProjectId, x.SqlInstanceId },
                        principalTable: "SqlInstances",
                        principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_SqlDatabases_CustomerId_ProjectId_LastImportBatchId",
                table: "SqlDatabases",
                columns: new[] { "CustomerId", "ProjectId", "LastImportBatchId" });

            migrationBuilder.CreateIndex(
                name: "IX_SqlDatabases_Owner_Active_Name",
                table: "SqlDatabases",
                columns: new[] { "CustomerId", "ProjectId", "IsDeleted", "NormalizedName" });

            migrationBuilder.CreateIndex(
                name: "IX_SqlDatabases_Owner_Active_Status",
                table: "SqlDatabases",
                columns: new[] { "CustomerId", "ProjectId", "IsDeleted", "Status" });

            migrationBuilder.CreateIndex(
                name: "UX_SqlDatabases_Owner_Instance_NormalizedName_Active",
                table: "SqlDatabases",
                columns: new[] { "CustomerId", "ProjectId", "SqlInstanceId", "NormalizedName" },
                unique: true,
                filter: "[IsDeleted] = 0");

            migrationBuilder.CreateIndex(
                name: "IX_SqlInstances_CustomerId_ProjectId_LastImportBatchId",
                table: "SqlInstances",
                columns: new[] { "CustomerId", "ProjectId", "LastImportBatchId" });

            migrationBuilder.CreateIndex(
                name: "IX_SqlInstances_Owner_Active_Name",
                table: "SqlInstances",
                columns: new[] { "CustomerId", "ProjectId", "IsDeleted", "NormalizedInstanceName" });

            migrationBuilder.CreateIndex(
                name: "IX_SqlInstances_Owner_Active_ServiceStatus",
                table: "SqlInstances",
                columns: new[] { "CustomerId", "ProjectId", "IsDeleted", "ServiceStatus" });

            migrationBuilder.CreateIndex(
                name: "UX_SqlInstances_Owner_Server_NormalizedName_Active",
                table: "SqlInstances",
                columns: new[] { "CustomerId", "ProjectId", "ServerId", "NormalizedInstanceName" },
                unique: true,
                filter: "[IsDeleted] = 0");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "SqlDatabases");

            migrationBuilder.DropTable(
                name: "SqlInstances");

            migrationBuilder.DropUniqueConstraint(
                name: "AK_Servers_CustomerId_ProjectId_Id",
                table: "Servers");

            migrationBuilder.DropUniqueConstraint(
                name: "AK_Projects_CustomerId_Id",
                table: "Projects");

            migrationBuilder.DropUniqueConstraint(
                name: "AK_ImportBatches_CustomerId_ProjectId_Id",
                table: "ImportBatches");

            migrationBuilder.DropColumn(
                name: "CorrelationId",
                table: "AuditEvents");
        }
    }
}
