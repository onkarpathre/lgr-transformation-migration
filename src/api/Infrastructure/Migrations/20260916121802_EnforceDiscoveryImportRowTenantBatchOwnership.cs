using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LgrTransformationMigration.Api.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class EnforceDiscoveryImportRowTenantBatchOwnership : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_DiscoveryImportRows_ImportBatches_ImportBatchId",
                table: "DiscoveryImportRows");

            migrationBuilder.DropIndex(
                name: "IX_DiscoveryImportRows_ImportBatchId",
                table: "DiscoveryImportRows");

            migrationBuilder.DropIndex(
                name: "IX_DiscoveryImportRows_ImportBatchId_RowNumber",
                table: "DiscoveryImportRows");

            migrationBuilder.CreateIndex(
                name: "IX_DiscoveryImportRows_CustomerId_ProjectId_ImportBatchId_RowNumber",
                table: "DiscoveryImportRows",
                columns: new[] { "CustomerId", "ProjectId", "ImportBatchId", "RowNumber" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_DiscoveryImportRows_ImportBatches_CustomerId_ProjectId_ImportBatchId",
                table: "DiscoveryImportRows",
                columns: new[] { "CustomerId", "ProjectId", "ImportBatchId" },
                principalTable: "ImportBatches",
                principalColumns: new[] { "CustomerId", "ProjectId", "Id" },
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_DiscoveryImportRows_ImportBatches_CustomerId_ProjectId_ImportBatchId",
                table: "DiscoveryImportRows");

            migrationBuilder.DropIndex(
                name: "IX_DiscoveryImportRows_CustomerId_ProjectId_ImportBatchId_RowNumber",
                table: "DiscoveryImportRows");

            migrationBuilder.CreateIndex(
                name: "IX_DiscoveryImportRows_ImportBatchId",
                table: "DiscoveryImportRows",
                column: "ImportBatchId");

            migrationBuilder.CreateIndex(
                name: "IX_DiscoveryImportRows_ImportBatchId_RowNumber",
                table: "DiscoveryImportRows",
                columns: new[] { "ImportBatchId", "RowNumber" },
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_DiscoveryImportRows_ImportBatches_ImportBatchId",
                table: "DiscoveryImportRows",
                column: "ImportBatchId",
                principalTable: "ImportBatches",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
