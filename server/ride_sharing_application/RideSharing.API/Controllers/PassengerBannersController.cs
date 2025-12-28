using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;

namespace RideSharing.API.Controllers;

[Route("api/v1/passenger/banners")]
[ApiController]
public class PassengerBannersController : ControllerBase
{
    private readonly RideSharingDbContext _context;
    private readonly ILogger<PassengerBannersController> _logger;

    public PassengerBannersController(
        RideSharingDbContext context,
        ILogger<PassengerBannersController> logger)
    {
        _context = context;
        _logger = logger;
    }

    /// <summary>
    /// Get active banners for passengers
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetActiveBanners()
    {
        try
        {
            // First, get ALL banners to debug
            var allBanners = await _context.Banners.ToListAsync();
            
            if (allBanners.Count == 0)
            {
                return Ok(new
                {
                    success = true,
                    data = new List<object>(),
                    count = 0,
                    message = "No banners in database"
                });
            }

            var now = DateTime.UtcNow;

            var banners = await _context.Banners
                .Where(b =>
                    b.IsActive &&
                    (b.TargetAudience == "all" || b.TargetAudience == "passenger"))
                .OrderBy(b => b.DisplayOrder)
                .ThenByDescending(b => b.CreatedAt)
                .ToListAsync();

            // Filter by dates - treat DB dates as UTC for comparison
            var activeBanners = banners.Where(b =>
            {
                // Treat database dates as UTC (they're stored without timezone)
                var startDate = b.StartDate.Kind == DateTimeKind.Utc ? b.StartDate : DateTime.SpecifyKind(b.StartDate, DateTimeKind.Utc);
                var endDate = b.EndDate.Kind == DateTimeKind.Utc ? b.EndDate : DateTime.SpecifyKind(b.EndDate, DateTimeKind.Utc);
                
                return startDate <= now && endDate >= now;
            }).ToList();

            return Ok(new
            {
                success = true,
                data = activeBanners,
                count = activeBanners.Count,
                debug = new 
                {
                    totalInDb = allBanners.Count,
                    afterIsActiveFilter = banners.Count,
                    afterDateFilter = activeBanners.Count,
                    sampleBanner = allBanners.FirstOrDefault() != null ? new 
                    {
                        title = allBanners.First().Title,
                        isActive = allBanners.First().IsActive,
                        targetAudience = allBanners.First().TargetAudience,
                        startDate = allBanners.First().StartDate,
                        endDate = allBanners.First().EndDate
                    } : null
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving active banners");
            return StatusCode(500, new { success = false, message = "Error retrieving banners", error = ex.Message });
        }
    }

    /// <summary>
    /// Record banner impression
    /// </summary>
    [HttpPost("{id}/impression")]
    public async Task<IActionResult> RecordImpression(Guid id)
    {
        try
        {
            var banner = await _context.Banners.FindAsync(id);

            if (banner == null)
            {
                return NotFound(new { success = false, message = "Banner not found" });
            }

            banner.ImpressionCount++;
            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Impression recorded" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error recording impression for banner {BannerId}", id);
            // Don't return error to client - fail silently for analytics
            return Ok(new { success = true, message = "Impression recorded" });
        }
    }

    /// <summary>
    /// Record banner click
    /// </summary>
    [HttpPost("{id}/click")]
    public async Task<IActionResult> RecordClick(Guid id)
    {
        try
        {
            var banner = await _context.Banners.FindAsync(id);

            if (banner == null)
            {
                return NotFound(new { success = false, message = "Banner not found" });
            }

            banner.ClickCount++;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                success = true,
                message = "Click recorded",
                actionType = banner.ActionType,
                actionUrl = banner.ActionUrl
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error recording click for banner {BannerId}", id);
            // Don't return error to client - fail silently for analytics
            return Ok(new { success = true, message = "Click recorded" });
        }
    }
}
