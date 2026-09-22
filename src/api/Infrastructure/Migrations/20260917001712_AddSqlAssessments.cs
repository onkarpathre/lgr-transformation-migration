using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LgrTransformationMigration.Api.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddSqlAssessments : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "SqlAssessments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CustomerId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ProjectId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SqlInstanceId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    SqlDatabaseId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    AssessmentStatus = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    ReadinessStatus = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    TargetPlatform = table.Column<string>(type: "nvarchar(80)", maxLength: 80, nullable: true),
                    TargetSqlVersion = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    MigrationApproach = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    Blockers = table.Column<string>(type: "nvarchar(4000)", maxLength: 4000, nullable: false),
                    Findings = table.Column<string>(type: "nvarchar(max)", maxLength: 8000, nullable: false),
                    Notes = table.Column<string>(type: "nvarchar(4000)", maxLength: 4000, nullable: false),
                    AssessedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    CreatedBy = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    UpdatedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: false),
                    UpdatedBy = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false),
                    DeletedAt = table.Column<DateTimeOffset>(type: "datetimeoffset", nullable: true),
                    DeletedBy = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    RowVersion = table.Column<byte[]>(type: "rowversion", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SqlAssessments", x => x.Id);
                    table.UniqueConstraint("AK_SqlAssessments_CustomerId_ProjectId_Id", x => new { x.CustomerId, x.ProjectId, x.Id });
                    table.CheckConstraint("CK_SqlAssessments_AssessmentStatus", "[AssessmentStatus] IN ('NotStarted', 'InProgress', 'Complete', 'Blocked')");
                    table.CheckConstraint("CK_SqlAssessments_ExactlyOneTarget", "(CASE WHEN [SqlInstanceId] IS NULL THEN 0 ELSE 1 END + CASE WHEN [SqlDatabaseId] IS NULL THEN 0 ELSE 1 END) = 1");
                    table.CheckConstraint("CK_SqlAssessments_MigrationApproach", "[MigrationApproach] IS NULL OR [MigrationApproach] IN ('Offline', 'Online', 'ToBeDetermined', 'NotApplicable')");
                    table.CheckConstraint("CK_SqlAssessments_ReadinessStatus", "[ReadinessStatus] IN ('NotAssessed', 'NotReady', 'AtRisk', 'ReadyWithConditions', 'Ready', 'Blocked')");
                    table.CheckConstraint("CK_SqlAssessments_TargetPlatform", "[TargetPlatform] IS NULL OR [TargetPlatform] IN ('AzureSqlDatabase', 'AzureSqlManagedInstance', 'SqlServerOnAzureVm', 'Retain', 'Retire', 'Investigate')");
                    table.ForeignKey(
                        name: "FK_SqlAssessments_Projects_CustomerId_ProjectId",
                        columns: x => new { x.CustomerId, x.ProjectId },
                        principalTable: "Projects",
                        principalColumns: new[] { "CustomerId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_SqlAssessments_SqlDatabases_CustomerId_ProjectId_SqlDatabaseId",
                        columns: x => new { x.CustomerId, x.ProjectId, x.SqlDatabaseId },
                        principalTable: "SqlDatabases",
                        principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_SqlAssessments_SqlInstances_CustomerId_ProjectId_SqlInstanceId",
                        columns: x => new { x.CustomerId, x.ProjectId, x.SqlInstanceId },
                        principalTable: "SqlInstances",
                        principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_SqlAssessments_Owner_Filter",
                table: "SqlAssessments",
                columns: new[] { "CustomerId", "ProjectId", "IsDeleted", "AssessmentStatus", "ReadinessStatus", "Id" });

            migrationBuilder.CreateIndex(
                name: "UX_SqlAssessments_Owner_Active_Database",
                table: "SqlAssessments",
                columns: new[] { "CustomerId", "ProjectId", "SqlDatabaseId" },
                unique: true,
                filter: "[IsDeleted] = 0 AND [SqlDatabaseId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "UX_SqlAssessments_Owner_Active_Instance",
                table: "SqlAssessments",
                columns: new[] { "CustomerId", "ProjectId", "SqlInstanceId" },
                unique: true,
                filter: "[IsDeleted] = 0 AND [SqlInstanceId] IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "SqlAssessments");
        }
    }
}
