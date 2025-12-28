using Microsoft.AspNetCore.Mvc;
using RideSharing.API.Seeders;
using RideSharing.API.Data;

namespace RideSharing.API.Controllers
{
    [Route("api/v1/seed")]
    [ApiController]
    public class SeedController : ControllerBase
    {
        private readonly RideSharingDbContext _context;

        public SeedController(RideSharingDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Seed seating layouts for vehicle models
        /// Call this once to add seating arrangements to all vehicle models
        /// </summary>
        [HttpPost("seating-layouts")]
        public async Task<IActionResult> SeedSeatingLayouts()
        {
            try
            {
                var seeder = new VehicleModelSeatingLayoutSeeder(_context);
                await seeder.SeedSeatingLayoutsAsync();
                
                return Ok(new { 
                    success = true, 
                    message = "✅ Seating layouts seeded successfully! Refresh your app to see seat selection." 
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { 
                    success = false, 
                    message = $"Error seeding layouts: {ex.Message}" 
                });
            }
        }
    }
}
