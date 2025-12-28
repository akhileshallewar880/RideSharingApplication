using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace RideSharing.API.Migrations
{
    /// <inheritdoc />
    public partial class AddRouteSegmentsTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "RouteSegments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    FromLocation = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    ToLocation = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    DistanceKm = table.Column<double>(type: "float", nullable: false),
                    DurationMinutes = table.Column<int>(type: "int", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RouteSegments", x => x.Id);
                });

            // Seed route segments data
            var now = DateTime.UtcNow;
            
            // Hyderabad Metro - Red Line (Raidurg to Ameerpet section)
            migrationBuilder.InsertData(
                table: "RouteSegments",
                columns: new[] { "Id", "FromLocation", "ToLocation", "DistanceKm", "DurationMinutes", "IsActive", "CreatedAt", "UpdatedAt" },
                values: new object[,]
                {
                    { Guid.NewGuid(), "Asian Living Gachibowli", "Wipro Circle", 3.5, 10, true, now, null },
                    { Guid.NewGuid(), "Wipro Circle", "Raidurg", 2.8, 8, true, now, null },
                    { Guid.NewGuid(), "Asian Living Gachibowli", "Raidurg", 6.3, 18, true, now, null },
                    { Guid.NewGuid(), "Raidurg", "Hitec City", 1.5, 3, true, now, null },
                    { Guid.NewGuid(), "Raidurg", "Durgam Cheruvu", 3.2, 6, true, now, null },
                    { Guid.NewGuid(), "Raidurg", "Madhapur", 4.8, 9, true, now, null },
                    { Guid.NewGuid(), "Raidurg", "Peddamma Gudi", 6.5, 12, true, now, null },
                    { Guid.NewGuid(), "Raidurg", "Jubilee Hills Checkpost", 8.2, 15, true, now, null },
                    { Guid.NewGuid(), "Raidurg", "Jubilee Hills", 10.1, 18, true, now, null },
                    { Guid.NewGuid(), "Raidurg", "Yousufguda", 12.3, 22, true, now, null },
                    { Guid.NewGuid(), "Raidurg", "Madhura Nagar", 14.2, 26, true, now, null },
                    { Guid.NewGuid(), "Raidurg", "Ameerpet", 16.5, 30, true, now, null },
                    { Guid.NewGuid(), "Hitec City", "Durgam Cheruvu", 1.7, 3, true, now, null },
                    { Guid.NewGuid(), "Hitec City", "Madhapur", 3.3, 6, true, now, null },
                    { Guid.NewGuid(), "Hitec City", "Peddamma Gudi", 5.0, 9, true, now, null },
                    { Guid.NewGuid(), "Hitec City", "Jubilee Hills Checkpost", 6.7, 12, true, now, null },
                    { Guid.NewGuid(), "Hitec City", "Jubilee Hills", 8.6, 15, true, now, null },
                    { Guid.NewGuid(), "Hitec City", "Yousufguda", 10.8, 19, true, now, null },
                    { Guid.NewGuid(), "Hitec City", "Madhura Nagar", 12.7, 23, true, now, null },
                    { Guid.NewGuid(), "Hitec City", "Ameerpet", 15.0, 27, true, now, null },
                    { Guid.NewGuid(), "Durgam Cheruvu", "Madhapur", 1.6, 3, true, now, null },
                    { Guid.NewGuid(), "Durgam Cheruvu", "Peddamma Gudi", 3.3, 6, true, now, null },
                    { Guid.NewGuid(), "Durgam Cheruvu", "Jubilee Hills Checkpost", 5.0, 9, true, now, null },
                    { Guid.NewGuid(), "Durgam Cheruvu", "Jubilee Hills", 6.9, 12, true, now, null },
                    { Guid.NewGuid(), "Durgam Cheruvu", "Yousufguda", 9.1, 16, true, now, null },
                    { Guid.NewGuid(), "Durgam Cheruvu", "Madhura Nagar", 11.0, 20, true, now, null },
                    { Guid.NewGuid(), "Durgam Cheruvu", "Ameerpet", 13.3, 24, true, now, null },
                    { Guid.NewGuid(), "Madhapur", "Peddamma Gudi", 1.7, 3, true, now, null },
                    { Guid.NewGuid(), "Madhapur", "Jubilee Hills Checkpost", 3.4, 6, true, now, null },
                    { Guid.NewGuid(), "Madhapur", "Jubilee Hills", 5.3, 9, true, now, null },
                    { Guid.NewGuid(), "Madhapur", "Yousufguda", 7.5, 13, true, now, null },
                    { Guid.NewGuid(), "Madhapur", "Madhura Nagar", 9.4, 17, true, now, null },
                    { Guid.NewGuid(), "Madhapur", "Ameerpet", 11.7, 21, true, now, null },
                    { Guid.NewGuid(), "Peddamma Gudi", "Jubilee Hills Checkpost", 1.7, 3, true, now, null },
                    { Guid.NewGuid(), "Peddamma Gudi", "Jubilee Hills", 3.6, 6, true, now, null },
                    { Guid.NewGuid(), "Peddamma Gudi", "Yousufguda", 5.8, 10, true, now, null },
                    { Guid.NewGuid(), "Peddamma Gudi", "Madhura Nagar", 7.7, 14, true, now, null },
                    { Guid.NewGuid(), "Peddamma Gudi", "Ameerpet", 10.0, 18, true, now, null },
                    { Guid.NewGuid(), "Jubilee Hills Checkpost", "Jubilee Hills", 1.9, 3, true, now, null },
                    { Guid.NewGuid(), "Jubilee Hills Checkpost", "Yousufguda", 4.1, 7, true, now, null },
                    { Guid.NewGuid(), "Jubilee Hills Checkpost", "Madhura Nagar", 6.0, 11, true, now, null },
                    { Guid.NewGuid(), "Jubilee Hills Checkpost", "Ameerpet", 8.3, 15, true, now, null },
                    { Guid.NewGuid(), "Jubilee Hills", "Yousufguda", 2.2, 4, true, now, null },
                    { Guid.NewGuid(), "Jubilee Hills", "Madhura Nagar", 4.1, 8, true, now, null },
                    { Guid.NewGuid(), "Jubilee Hills", "Ameerpet", 6.4, 12, true, now, null },
                    { Guid.NewGuid(), "Yousufguda", "Madhura Nagar", 1.9, 4, true, now, null },
                    { Guid.NewGuid(), "Yousufguda", "Ameerpet", 4.2, 8, true, now, null },
                    { Guid.NewGuid(), "Madhura Nagar", "Ameerpet", 2.3, 4, true, now, null },
                    
                    // Hyderabad Metro - Blue Line (Ameerpet to Secunderabad)
                    { Guid.NewGuid(), "Ameerpet", "SR Nagar", 2.1, 4, true, now, null },
                    { Guid.NewGuid(), "Ameerpet", "Prakash Nagar", 4.3, 8, true, now, null },
                    { Guid.NewGuid(), "Ameerpet", "Begumpet", 6.5, 12, true, now, null },
                    { Guid.NewGuid(), "Ameerpet", "Rasoolpura", 8.8, 16, true, now, null },
                    { Guid.NewGuid(), "Ameerpet", "Paradise", 11.2, 20, true, now, null },
                    { Guid.NewGuid(), "Ameerpet", "Parade Grounds", 13.5, 24, true, now, null },
                    { Guid.NewGuid(), "Ameerpet", "Secunderabad", 15.8, 28, true, now, null },
                    { Guid.NewGuid(), "SR Nagar", "Prakash Nagar", 2.2, 4, true, now, null },
                    { Guid.NewGuid(), "SR Nagar", "Begumpet", 4.4, 8, true, now, null },
                    { Guid.NewGuid(), "SR Nagar", "Rasoolpura", 6.7, 12, true, now, null },
                    { Guid.NewGuid(), "SR Nagar", "Paradise", 9.1, 16, true, now, null },
                    { Guid.NewGuid(), "SR Nagar", "Parade Grounds", 11.4, 20, true, now, null },
                    { Guid.NewGuid(), "SR Nagar", "Secunderabad", 13.7, 24, true, now, null },
                    { Guid.NewGuid(), "Prakash Nagar", "Begumpet", 2.2, 4, true, now, null },
                    { Guid.NewGuid(), "Prakash Nagar", "Rasoolpura", 4.5, 8, true, now, null },
                    { Guid.NewGuid(), "Prakash Nagar", "Paradise", 6.9, 12, true, now, null },
                    { Guid.NewGuid(), "Prakash Nagar", "Parade Grounds", 9.2, 16, true, now, null },
                    { Guid.NewGuid(), "Prakash Nagar", "Secunderabad", 11.5, 20, true, now, null },
                    { Guid.NewGuid(), "Begumpet", "Rasoolpura", 2.3, 4, true, now, null },
                    { Guid.NewGuid(), "Begumpet", "Paradise", 4.7, 8, true, now, null },
                    { Guid.NewGuid(), "Begumpet", "Parade Grounds", 7.0, 12, true, now, null },
                    { Guid.NewGuid(), "Begumpet", "Secunderabad", 9.3, 16, true, now, null },
                    { Guid.NewGuid(), "Rasoolpura", "Paradise", 2.4, 4, true, now, null },
                    { Guid.NewGuid(), "Rasoolpura", "Parade Grounds", 4.7, 8, true, now, null },
                    { Guid.NewGuid(), "Rasoolpura", "Secunderabad", 7.0, 12, true, now, null },
                    { Guid.NewGuid(), "Paradise", "Parade Grounds", 2.3, 4, true, now, null },
                    { Guid.NewGuid(), "Paradise", "Secunderabad", 4.6, 8, true, now, null },
                    { Guid.NewGuid(), "Parade Grounds", "Secunderabad", 2.3, 4, true, now, null },
                    { Guid.NewGuid(), "Raidurg", "Secunderabad", 32.3, 58, true, now, null },
                    
                    // Maharashtra Routes
                    { Guid.NewGuid(), "Allapalli", "Gondpipri", 82, 105, true, now, null },
                    { Guid.NewGuid(), "Allapalli", "Chandrapur", 124, 165, true, now, null },
                    { Guid.NewGuid(), "Allapalli", "Gadchiroli", 85, 110, true, now, null },
                    { Guid.NewGuid(), "Allapalli", "Nagpur", 210, 270, true, now, null },
                    { Guid.NewGuid(), "Allapalli", "Kurkheda", 135, 180, true, now, null },
                    { Guid.NewGuid(), "Allapalli", "Bramhapuri", 145, 195, true, now, null },
                    { Guid.NewGuid(), "Allapalli", "Armori", 150, 200, true, now, null },
                    { Guid.NewGuid(), "Allapalli", "Desaiganj", 100, 130, true, now, null },
                    { Guid.NewGuid(), "Gondpipri", "Chandrapur", 45, 60, true, now, null },
                    { Guid.NewGuid(), "Gondpipri", "Nagpur", 135, 175, true, now, null },
                    { Guid.NewGuid(), "Gondpipri", "Bramhapuri", 32, 40, true, now, null },
                    { Guid.NewGuid(), "Gondpipri", "Mul", 28, 35, true, now, null },
                    { Guid.NewGuid(), "Gondpipri", "Warora", 40, 50, true, now, null },
                    { Guid.NewGuid(), "Gondpipri", "Gadchiroli", 90, 120, true, now, null },
                    { Guid.NewGuid(), "Chandrapur", "Nagpur", 160, 210, true, now, null },
                    { Guid.NewGuid(), "Chandrapur", "Ballarpur", 18, 25, true, now, null },
                    { Guid.NewGuid(), "Chandrapur", "Bramhapuri", 68, 90, true, now, null },
                    { Guid.NewGuid(), "Chandrapur", "Mul", 25, 35, true, now, null },
                    { Guid.NewGuid(), "Chandrapur", "Warora", 75, 100, true, now, null },
                    { Guid.NewGuid(), "Chandrapur", "Rajura", 22, 30, true, now, null },
                    { Guid.NewGuid(), "Chandrapur", "Gadchiroli", 110, 145, true, now, null },
                    { Guid.NewGuid(), "Chandrapur", "Chimur", 42, 55, true, now, null },
                    { Guid.NewGuid(), "Nagpur", "Kamptee", 15, 25, true, now, null },
                    { Guid.NewGuid(), "Nagpur", "Umred", 55, 75, true, now, null },
                    { Guid.NewGuid(), "Nagpur", "Ramtek", 48, 65, true, now, null },
                    { Guid.NewGuid(), "Nagpur", "Katol", 62, 85, true, now, null },
                    { Guid.NewGuid(), "Nagpur", "Gondia", 95, 120, true, now, null },
                    { Guid.NewGuid(), "Nagpur", "Warora", 95, 125, true, now, null },
                    { Guid.NewGuid(), "Nagpur", "Bramhapuri", 120, 160, true, now, null },
                    { Guid.NewGuid(), "Gadchiroli", "Desaiganj", 38, 50, true, now, null },
                    { Guid.NewGuid(), "Gadchiroli", "Armori", 65, 85, true, now, null },
                    { Guid.NewGuid(), "Gadchiroli", "Kurkheda", 52, 70, true, now, null },
                    { Guid.NewGuid(), "Gadchiroli", "Aheri", 75, 95, true, now, null },
                    { Guid.NewGuid(), "Gadchiroli", "Bramhapuri", 88, 115, true, now, null },
                    { Guid.NewGuid(), "Gadchiroli", "Mulchera", 42, 55, true, now, null },
                    { Guid.NewGuid(), "Bramhapuri", "Mul", 58, 75, true, now, null },
                    { Guid.NewGuid(), "Bramhapuri", "Warora", 55, 70, true, now, null },
                    { Guid.NewGuid(), "Bramhapuri", "Armori", 45, 60, true, now, null },
                    { Guid.NewGuid(), "Bramhapuri", "Kurkheda", 52, 68, true, now, null },
                    { Guid.NewGuid(), "Kurkheda", "Armori", 12, 18, true, now, null },
                    { Guid.NewGuid(), "Kurkheda", "Desaiganj", 42, 55, true, now, null },
                    { Guid.NewGuid(), "Kurkheda", "Gondia", 70, 90, true, now, null },
                    { Guid.NewGuid(), "Ballarpur", "Rajura", 32, 40, true, now, null },
                    { Guid.NewGuid(), "Warora", "Mul", 52, 68, true, now, null },
                    { Guid.NewGuid(), "Gondia", "Tirora", 48, 62, true, now, null },
                    { Guid.NewGuid(), "Umred", "Chandrapur", 95, 125, true, now, null }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "RouteSegments");
        }
    }
}
