using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace RideSharing.API.Migrations
{
    /// <inheritdoc />
    public partial class AddSeatingArrangementFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "SeatingLayout",
                table: "VehicleModels",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SeatingArrangementImage",
                table: "Bookings",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SelectedSeats",
                table: "Bookings",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "SeatingLayout",
                table: "VehicleModels");

            migrationBuilder.DropColumn(
                name: "SeatingArrangementImage",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "SelectedSeats",
                table: "Bookings");
        }
    }
}
