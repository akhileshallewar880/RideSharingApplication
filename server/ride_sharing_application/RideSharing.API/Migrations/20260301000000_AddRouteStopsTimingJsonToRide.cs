using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace RideSharing.API.Migrations
{
    /// <inheritdoc />
    public partial class AddRouteStopsTimingJsonToRide : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "RouteStopsTimingJson",
                table: "Rides",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "RouteStopsTimingJson",
                table: "Rides");
        }
    }
}
