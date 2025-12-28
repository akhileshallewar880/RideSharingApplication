using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace RideSharing.API.Migrations
{
    /// <inheritdoc />
    public partial class AddVehicleModelAndEnhanceRide : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "IntermediateStops",
                table: "Rides",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsReturnTrip",
                table: "Rides",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<Guid>(
                name: "LinkedReturnRideId",
                table: "Rides",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "VehicleModelId",
                table: "Rides",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "VehicleModels",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Brand = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Type = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    SeatingCapacity = table.Column<int>(type: "int", nullable: false),
                    ImageUrl = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    Features = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETUTCDATE()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_VehicleModels", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Rides_VehicleModelId",
                table: "Rides",
                column: "VehicleModelId");

            migrationBuilder.CreateIndex(
                name: "IX_VehicleModels_Brand",
                table: "VehicleModels",
                column: "Brand");

            migrationBuilder.CreateIndex(
                name: "IX_VehicleModels_IsActive",
                table: "VehicleModels",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_VehicleModels_Type",
                table: "VehicleModels",
                column: "Type");

            migrationBuilder.AddForeignKey(
                name: "FK_Rides_VehicleModels_VehicleModelId",
                table: "Rides",
                column: "VehicleModelId",
                principalTable: "VehicleModels",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Rides_VehicleModels_VehicleModelId",
                table: "Rides");

            migrationBuilder.DropTable(
                name: "VehicleModels");

            migrationBuilder.DropIndex(
                name: "IX_Rides_VehicleModelId",
                table: "Rides");

            migrationBuilder.DropColumn(
                name: "IntermediateStops",
                table: "Rides");

            migrationBuilder.DropColumn(
                name: "IsReturnTrip",
                table: "Rides");

            migrationBuilder.DropColumn(
                name: "LinkedReturnRideId",
                table: "Rides");

            migrationBuilder.DropColumn(
                name: "VehicleModelId",
                table: "Rides");
        }
    }
}
