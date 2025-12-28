using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace RideSharing.API.Migrations
{
    /// <inheritdoc />
    public partial class AddSegmentPricingToRides : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "SegmentPrices",
                table: "Rides",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "SegmentPrices",
                table: "Rides");
        }
    }
}
