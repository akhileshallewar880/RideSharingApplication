using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;
using RideSharing.API.Services.Notification;

namespace RideSharing.API.Controllers;

[Route("api/v1/admin/notifications")]
[ApiController]
[Authorize(Roles = "admin")]
public class AdminNotificationsController : ControllerBase
{
    private readonly RideSharingDbContext _context;
    private readonly FCMNotificationService _fcmService;
    private readonly ILogger<AdminNotificationsController> _logger;

    public AdminNotificationsController(
        RideSharingDbContext context,
        FCMNotificationService fcmService,
        ILogger<AdminNotificationsController> logger)
    {
        _context = context;
        _fcmService = fcmService;
        _logger = logger;
    }

    /// <summary>
    /// Send custom notification to users
    /// </summary>
    [HttpPost("send")]
    public async Task<IActionResult> SendCustomNotification([FromBody] SendNotificationRequest request)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(request.Title) || string.IsNullOrWhiteSpace(request.Description))
            {
                return BadRequest(new { message = "Title and description are required" });
            }

            // Get FCM tokens based on target audience
            List<string> fcmTokens = new List<string>();

            if (request.TargetAudience == "drivers" || request.TargetAudience == "all")
            {
                var driverTokens = await _context.Users
                    .Where(u => u.UserType == "driver" && !string.IsNullOrEmpty(u.FCMToken))
                    .Select(u => u.FCMToken!)
                    .ToListAsync();
                fcmTokens.AddRange(driverTokens);
            }

            if (request.TargetAudience == "passengers" || request.TargetAudience == "all")
            {
                var passengerTokens = await _context.Users
                    .Where(u => u.UserType == "passenger" && !string.IsNullOrEmpty(u.FCMToken))
                    .Select(u => u.FCMToken!)
                    .ToListAsync();
                fcmTokens.AddRange(passengerTokens);
            }

            if (!fcmTokens.Any())
            {
                return Ok(new
                {
                    success = true,
                    message = "No users found with FCM tokens",
                    sentCount = 0,
                    targetAudience = request.TargetAudience
                });
            }

            // Remove duplicates
            fcmTokens = fcmTokens.Distinct().ToList();

            // Prepare notification data
            var data = new Dictionary<string, string>
            {
                { "type", "admin_announcement" },
                { "title", request.Title }
            };

            if (!string.IsNullOrWhiteSpace(request.Banner))
            {
                data.Add("banner", request.Banner);
            }

            // Send notification using multicast
            await _fcmService.SendMulticastNotificationAsync(
                fcmTokens,
                request.Title,
                request.Description,
                data
            );

            _logger.LogInformation($"Admin sent notification to {fcmTokens.Count} users. Audience: {request.TargetAudience}");

            return Ok(new
            {
                success = true,
                message = $"Notification sent successfully",
                sentCount = fcmTokens.Count,
                targetAudience = request.TargetAudience
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending admin notification");
            return StatusCode(500, new { message = "Failed to send notification", error = ex.Message });
        }
    }

    /// <summary>
    /// Get statistics for notification targets
    /// </summary>
    [HttpGet("statistics")]
    public async Task<IActionResult> GetStatistics()
    {
        try
        {
            var totalUsers = await _context.Users.CountAsync();
            var driversWithTokens = await _context.Users
                .Where(u => u.UserType == "driver" && !string.IsNullOrEmpty(u.FCMToken))
                .CountAsync();
            var passengersWithTokens = await _context.Users
                .Where(u => u.UserType == "passenger" && !string.IsNullOrEmpty(u.FCMToken))
                .CountAsync();
            var totalDrivers = await _context.Users.Where(u => u.UserType == "driver").CountAsync();
            var totalPassengers = await _context.Users.Where(u => u.UserType == "passenger").CountAsync();

            return Ok(new
            {
                success = true,
                data = new
                {
                    totalUsers,
                    totalDrivers,
                    totalPassengers,
                    driversWithNotifications = driversWithTokens,
                    passengersWithNotifications = passengersWithTokens,
                    totalWithNotifications = driversWithTokens + passengersWithTokens
                }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching notification statistics");
            return StatusCode(500, new { message = "Failed to fetch statistics" });
        }
    }
}

public class SendNotificationRequest
{
    public string Title { get; set; } = string.Empty;
    public string? Banner { get; set; }
    public string Description { get; set; } = string.Empty;
    public string TargetAudience { get; set; } = "all"; // "all", "drivers", "passengers"
}
