using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;
using RideSharing.API.Models.Domain;

namespace RideSharing.API.Seeders
{
    public class CitiesSeeder
    {
        private readonly RideSharingDbContext _context;
        private readonly ILogger<CitiesSeeder> _logger;

        public CitiesSeeder(RideSharingDbContext context, ILogger<CitiesSeeder> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task SeedCitiesAsync()
        {
            var existingCount = await _context.Cities.CountAsync();
            if (existingCount > 0)
            {
                _logger.LogInformation("Cities table already has {Count} entries. Skipping seed.", existingCount);
                return;
            }

            _logger.LogInformation("Seeding cities for Gadchiroli / Vidarbha / Telangana service area...");

            var cities = new List<City>
            {
                // ── Gadchiroli District, Maharashtra ──────────────────────────────
                new City { Id = Guid.NewGuid(), Name = "Allapalli",   State = "Maharashtra", District = "Gadchiroli", Latitude = 19.3833f, Longitude = 79.7833f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Gadchiroli",  State = "Maharashtra", District = "Gadchiroli", Latitude = 20.1757f, Longitude = 80.0019f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Armori",      State = "Maharashtra", District = "Gadchiroli", Latitude = 20.0433f, Longitude = 80.0633f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Wadsa",       State = "Maharashtra", District = "Gadchiroli", SubLocation = "Desaiganj", Latitude = 20.3167f, Longitude = 79.9667f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Aheri",       State = "Maharashtra", District = "Gadchiroli", Latitude = 19.4319f, Longitude = 80.0055f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Sironcha",    State = "Maharashtra", District = "Gadchiroli", Latitude = 18.8500f, Longitude = 79.9700f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Bhamragad",   State = "Maharashtra", District = "Gadchiroli", Latitude = 19.4700f, Longitude = 80.3200f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Etapalli",    State = "Maharashtra", District = "Gadchiroli", Latitude = 19.6500f, Longitude = 80.2333f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Chamorshi",   State = "Maharashtra", District = "Gadchiroli", Latitude = 20.1167f, Longitude = 80.2000f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Kurkheda",    State = "Maharashtra", District = "Gadchiroli", Latitude = 20.0167f, Longitude = 80.1500f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Dhanora",     State = "Maharashtra", District = "Gadchiroli", Latitude = 20.3833f, Longitude = 80.1500f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Korchi",      State = "Maharashtra", District = "Gadchiroli", Latitude = 20.3000f, Longitude = 80.3333f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Mulchera",    State = "Maharashtra", District = "Gadchiroli", Latitude = 20.4833f, Longitude = 80.1167f, IsActive = true },

                // ── Chandrapur District, Maharashtra ──────────────────────────────
                new City { Id = Guid.NewGuid(), Name = "Chandrapur",  State = "Maharashtra", District = "Chandrapur", Latitude = 19.9615f, Longitude = 79.2961f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Mul",         State = "Maharashtra", District = "Chandrapur", Latitude = 20.0567f, Longitude = 79.6817f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Warora",      State = "Maharashtra", District = "Chandrapur", Latitude = 20.2333f, Longitude = 79.0167f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Bhadravati",  State = "Maharashtra", District = "Chandrapur", Latitude = 20.1500f, Longitude = 79.1667f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Rajura",      State = "Maharashtra", District = "Chandrapur", Latitude = 19.7833f, Longitude = 79.3500f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Gondpipri",   State = "Maharashtra", District = "Chandrapur", Latitude = 20.0000f, Longitude = 79.5167f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Sindewahi",   State = "Maharashtra", District = "Chandrapur", Latitude = 20.2833f, Longitude = 79.6500f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Chimur",      State = "Maharashtra", District = "Chandrapur", Latitude = 20.4500f, Longitude = 79.3333f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Nagbhid",     State = "Maharashtra", District = "Chandrapur", Latitude = 20.5667f, Longitude = 79.9000f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Brahmapuri",  State = "Maharashtra", District = "Chandrapur", Latitude = 20.6000f, Longitude = 79.8500f, IsActive = true },

                // ── Nagpur District, Maharashtra ──────────────────────────────────
                new City { Id = Guid.NewGuid(), Name = "Nagpur",      State = "Maharashtra", District = "Nagpur",     Latitude = 21.1458f, Longitude = 79.0882f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Kamptee",     State = "Maharashtra", District = "Nagpur",     Latitude = 21.2167f, Longitude = 79.1833f, IsActive = true },

                // ── Yavatmal District, Maharashtra ────────────────────────────────
                new City { Id = Guid.NewGuid(), Name = "Yavatmal",    State = "Maharashtra", District = "Yavatmal",   Latitude = 20.3888f, Longitude = 78.1204f, IsActive = true },

                // ── Adilabad / Kumram Bheem Asifabad District, Telangana ──────────
                new City { Id = Guid.NewGuid(), Name = "Adilabad",    State = "Telangana",   District = "Adilabad",   Latitude = 19.6641f, Longitude = 78.5320f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Mancherial",  State = "Telangana",   District = "Mancherial", Latitude = 18.8667f, Longitude = 79.4500f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Nirmal",      State = "Telangana",   District = "Nirmal",     Latitude = 19.0967f, Longitude = 78.3417f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Bellampalli", State = "Telangana",   District = "Mancherial", Latitude = 18.9167f, Longitude = 79.5000f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Asifabad",    State = "Telangana",   District = "Kumram Bheem Asifabad", Latitude = 19.3667f, Longitude = 79.2667f, IsActive = true },
                new City { Id = Guid.NewGuid(), Name = "Hyderabad",   State = "Telangana",   District = "Hyderabad",  Latitude = 17.3850f, Longitude = 78.4867f, IsActive = true },

                // ── Bastar / Dantewada District, Chhattisgarh ────────────────────
                new City { Id = Guid.NewGuid(), Name = "Jagdalpur",   State = "Chhattisgarh", District = "Bastar",   Latitude = 19.0756f, Longitude = 81.9984f, IsActive = true },
            };

            await _context.Cities.AddRangeAsync(cities);
            await _context.SaveChangesAsync();

            _logger.LogInformation("✅ Successfully seeded {Count} cities.", cities.Count);
        }
    }
}
