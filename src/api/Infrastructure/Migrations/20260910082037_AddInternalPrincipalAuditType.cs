using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LgrTransformationMigration.Api.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddInternalPrincipalAuditType : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ActorPrincipalType",
                table: "AuditEvents",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ActorPrincipalType",
                table: "AuditEvents");
        }
    }
}
