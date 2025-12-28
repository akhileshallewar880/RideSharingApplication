using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;

namespace RideSharing.API.Seeders
{
    public class VehicleModelSeatingLayoutSeeder
    {
        private readonly RideSharingDbContext _context;

        public VehicleModelSeatingLayoutSeeder(RideSharingDbContext context)
        {
            _context = context;
        }

        public async Task SeedSeatingLayoutsAsync()
        {
            Console.WriteLine("🪑 Starting seating layout seeding...");

            // 1. Sedan (4 Seater) - 2-3 layout
            var sedans = await _context.VehicleModels
                .Where(v => v.SeatingCapacity == 4 || v.Type == "sedan")
                .ToListAsync();

            foreach (var sedan in sedans)
            {
                if (string.IsNullOrEmpty(sedan.SeatingLayout))
                {
                    sedan.SeatingLayout = @"{
  ""layout"": ""2-3"",
  ""rows"": 2,
  ""seats"": [
    {""id"": ""P1"", ""row"": 1, ""position"": ""left""},
    {""id"": ""P2"", ""row"": 1, ""position"": ""right""},
    {""id"": ""P3"", ""row"": 2, ""position"": ""left""},
    {""id"": ""P4"", ""row"": 2, ""position"": ""center""},
    {""id"": ""P5"", ""row"": 2, ""position"": ""right""}
  ]
}";
                    Console.WriteLine($"✅ Added seating layout to {sedan.Name} (Sedan/4-seater)");
                }
            }

            // 2. SUV/Ertiga (7 Seater) - 2-2-3 layout
            var suvs = await _context.VehicleModels
                .Where(v => v.SeatingCapacity == 7 || v.Type == "suv")
                .ToListAsync();

            foreach (var suv in suvs)
            {
                if (string.IsNullOrEmpty(suv.SeatingLayout))
                {
                    suv.SeatingLayout = @"{
  ""layout"": ""2-2-3"",
  ""rows"": 3,
  ""seats"": [
    {""id"": ""P1"", ""row"": 1, ""position"": ""left""},
    {""id"": ""P2"", ""row"": 1, ""position"": ""right""},
    {""id"": ""P3"", ""row"": 2, ""position"": ""left""},
    {""id"": ""P4"", ""row"": 2, ""position"": ""right""},
    {""id"": ""P5"", ""row"": 3, ""position"": ""left""},
    {""id"": ""P6"", ""row"": 3, ""position"": ""center""},
    {""id"": ""P7"", ""row"": 3, ""position"": ""right""}
  ]
}";
                    Console.WriteLine($"✅ Added seating layout to {suv.Name} (SUV/7-seater)");
                }
            }

            // 3. Van (9 Seater) - 2-3-4 layout
            var vans = await _context.VehicleModels
                .Where(v => (v.SeatingCapacity >= 9 && v.SeatingCapacity <= 10) || v.Type == "van")
                .ToListAsync();

            foreach (var van in vans)
            {
                if (string.IsNullOrEmpty(van.SeatingLayout))
                {
                    van.SeatingLayout = @"{
  ""layout"": ""2-3-4"",
  ""rows"": 3,
  ""seats"": [
    {""id"": ""P1"", ""row"": 1, ""position"": ""left""},
    {""id"": ""P2"", ""row"": 1, ""position"": ""right""},
    {""id"": ""P3"", ""row"": 2, ""position"": ""left""},
    {""id"": ""P4"", ""row"": 2, ""position"": ""center""},
    {""id"": ""P5"", ""row"": 2, ""position"": ""right""},
    {""id"": ""P6"", ""row"": 3, ""position"": ""left""},
    {""id"": ""P7"", ""row"": 3, ""position"": ""center""},
    {""id"": ""P8"", ""row"": 3, ""position"": ""center""},
    {""id"": ""P9"", ""row"": 3, ""position"": ""right""}
  ]
}";
                    Console.WriteLine($"✅ Added seating layout to {van.Name} (Van/9-seater)");
                }
            }

            // 4. Tempo (12-14 Seater) - 2-2-2-2-2-2 layout
            var tempos = await _context.VehicleModels
                .Where(v => (v.SeatingCapacity >= 12 && v.SeatingCapacity <= 14) || v.Type == "tempo")
                .ToListAsync();

            foreach (var tempo in tempos)
            {
                if (string.IsNullOrEmpty(tempo.SeatingLayout))
                {
                    tempo.SeatingLayout = @"{
  ""layout"": ""2-2-2-2-2-2"",
  ""rows"": 6,
  ""seats"": [
    {""id"": ""P1"", ""row"": 1, ""position"": ""left""},
    {""id"": ""P2"", ""row"": 1, ""position"": ""right""},
    {""id"": ""P3"", ""row"": 2, ""position"": ""left""},
    {""id"": ""P4"", ""row"": 2, ""position"": ""right""},
    {""id"": ""P5"", ""row"": 3, ""position"": ""left""},
    {""id"": ""P6"", ""row"": 3, ""position"": ""right""},
    {""id"": ""P7"", ""row"": 4, ""position"": ""left""},
    {""id"": ""P8"", ""row"": 4, ""position"": ""right""},
    {""id"": ""P9"", ""row"": 5, ""position"": ""left""},
    {""id"": ""P10"", ""row"": 5, ""position"": ""right""},
    {""id"": ""P11"", ""row"": 6, ""position"": ""left""},
    {""id"": ""P12"", ""row"": 6, ""position"": ""right""}
  ]
}";
                    Console.WriteLine($"✅ Added seating layout to {tempo.Name} (Tempo/12-14 seater)");
                }
            }

            await _context.SaveChangesAsync();

            var updatedCount = await _context.VehicleModels
                .Where(v => v.SeatingLayout != null && v.SeatingLayout != "")
                .CountAsync();

            Console.WriteLine($"\n✅ Seeding complete! {updatedCount} vehicle models now have seating layouts.");
            Console.WriteLine("🎉 Seat selection will now appear in the booking flow!\n");
        }
    }
}
