using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;

namespace RideSharing.API.Controllers
{
    [Route("api/v1/admin/analytics")]
    [ApiController]
    [Authorize(Roles = "admin,super_admin")] // Requires admin or super_admin role
    public class AdminAnalyticsController : ControllerBase
    {
        private readonly RideSharingDbContext _context;

        public AdminAnalyticsController(RideSharingDbContext context)
        {
            _context = context;
        }

        // GET: api/v1/AdminAnalytics/dashboard?startDate=2024-01-01&endDate=2024-12-31
        [HttpGet("dashboard")]
        public async Task<IActionResult> GetDashboardAnalytics([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
        {
            try
            {
                var start = startDate ?? DateTime.UtcNow.AddDays(-30);
                var end = endDate ?? DateTime.UtcNow;

                // Total and Active Drivers
                var totalDrivers = await _context.Drivers.CountAsync();
                var activeDrivers = await _context.Drivers
                    .CountAsync(d => d.IsOnline && d.IsAvailable);

                // Pending Verifications
                var pendingVerifications = await _context.Drivers
                    .CountAsync(d => d.VerificationStatus == "pending");

                // Total Passengers
                var totalPassengers = await _context.Users
                    .CountAsync(u => u.UserType == "passenger");

                // Total Rides
                var totalRides = await _context.Rides
                    .CountAsync(r => r.TravelDate >= start && r.TravelDate <= end);

                // Completed Rides
                var completedRides = await _context.Rides
                    .CountAsync(r => r.Status == "completed" && r.TravelDate >= start && r.TravelDate <= end);

                // Active Rides
                var activeRides = await _context.Rides
                    .CountAsync(r => r.Status == "active");

                // Total Revenue (from completed bookings)
                var totalRevenue = await _context.Bookings
                    .Where(b => b.Status == "completed" && b.CreatedAt >= start && b.CreatedAt <= end)
                    .SumAsync(b => b.TotalAmount);

                // Platform Fee Revenue
                var platformFeeRevenue = await _context.Bookings
                    .Where(b => b.Status == "completed" && b.CreatedAt >= start && b.CreatedAt <= end)
                    .SumAsync(b => b.PlatformFee);

                // Daily Stats (last 30 days)
                var dailyStats = await _context.Bookings
                    .Where(b => b.Status == "completed" && b.CreatedAt >= start && b.CreatedAt <= end)
                    .GroupBy(b => b.CreatedAt.Date)
                    .Select(g => new
                    {
                        Date = g.Key,
                        Revenue = g.Sum(b => b.TotalAmount),
                        Rides = g.Count(),
                        PlatformFees = g.Sum(b => b.PlatformFee)
                    })
                    .OrderByDescending(s => s.Date)
                    .Take(30)
                    .ToListAsync();

                return Ok(new
                {
                    success = true,
                    data = new
                    {
                        overview = new
                        {
                            totalDrivers,
                            activeDrivers,
                            pendingVerifications,
                            totalPassengers,
                            totalRides,
                            completedRides,
                            activeRides,
                            totalRevenue = Math.Round(totalRevenue, 2),
                            platformFeeRevenue = Math.Round(platformFeeRevenue, 2)
                        },
                        dailyStats
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    success = false,
                    message = "Failed to fetch dashboard analytics",
                    error = ex.Message
                });
            }
        }

        // GET: api/v1/AdminAnalytics/revenue?grouping=day
        [HttpGet("revenue")]
        public async Task<IActionResult> GetRevenueAnalytics([FromQuery] string grouping = "day")
        {
            try
            {
                var revenueData = grouping.ToLower() switch
                {
                    "day" => await _context.Bookings
                        .Where(b => b.Status == "completed" && b.CreatedAt >= DateTime.UtcNow.AddDays(-30))
                        .GroupBy(b => b.CreatedAt.Date)
                        .Select(g => new
                        {
                            Period = g.Key.ToString("yyyy-MM-dd"),
                            Revenue = g.Sum(b => b.TotalAmount),
                            PlatformFees = g.Sum(b => b.PlatformFee),
                            Bookings = g.Count()
                        })
                        .OrderBy(r => r.Period)
                        .ToListAsync(),

                    "week" => await _context.Bookings
                        .Where(b => b.Status == "completed" && b.CreatedAt >= DateTime.UtcNow.AddDays(-90))
                        .GroupBy(b => new { Year = b.CreatedAt.Year, Week = (b.CreatedAt.DayOfYear / 7) })
                        .Select(g => new
                        {
                            Period = $"{g.Key.Year}-W{g.Key.Week}",
                            Revenue = g.Sum(b => b.TotalAmount),
                            PlatformFees = g.Sum(b => b.PlatformFee),
                            Bookings = g.Count()
                        })
                        .OrderBy(r => r.Period)
                        .ToListAsync(),

                    "month" => await _context.Bookings
                        .Where(b => b.Status == "completed" && b.CreatedAt >= DateTime.UtcNow.AddYears(-1))
                        .GroupBy(b => new { b.CreatedAt.Year, b.CreatedAt.Month })
                        .Select(g => new
                        {
                            Period = $"{g.Key.Year}-{g.Key.Month:D2}",
                            Revenue = g.Sum(b => b.TotalAmount),
                            PlatformFees = g.Sum(b => b.PlatformFee),
                            Bookings = g.Count()
                        })
                        .OrderBy(r => r.Period)
                        .ToListAsync(),

                    _ => throw new ArgumentException("Invalid grouping parameter. Use 'day', 'week', or 'month'.")
                };

                return Ok(new
                {
                    success = true,
                    grouping,
                    data = revenueData
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    success = false,
                    message = "Failed to fetch revenue analytics",
                    error = ex.Message
                });
            }
        }

        // GET: api/v1/AdminAnalytics/drivers
        [HttpGet("drivers")]
        public async Task<IActionResult> GetDriverAnalytics()
        {
            try
            {
                // Total Drivers Stats
                var totalDrivers = await _context.Drivers.CountAsync();
                var activeDrivers = await _context.Drivers.CountAsync(d => d.IsOnline);
                var verificationPending = await _context.Drivers.CountAsync(d => d.VerificationStatus == "pending");
                var verifiedDrivers = await _context.Drivers.CountAsync(d => d.IsVerified);

                // Top Performers (by total earnings)
                var topDrivers = await _context.Drivers
                    .Include(d => d.User)
                    .OrderByDescending(d => d.TotalEarnings)
                    .Take(10)
                    .Select(d => new
                    {
                        d.Id,
                        DriverPhone = d.User.PhoneNumber,
                        DriverEmail = d.User.Email,
                        TotalRides = d.Rides.Count(r => r.Status == "completed"),
                        TotalEarnings = Math.Round(d.TotalEarnings, 2),
                        AvailableForWithdrawal = Math.Round(d.AvailableForWithdrawal, 2),
                        IsOnline = d.IsOnline,
                        IsAvailable = d.IsAvailable,
                        VerificationStatus = d.VerificationStatus
                    })
                    .ToListAsync();

                // Driver Verification Status Breakdown
                var verificationStatus = await _context.Drivers
                    .GroupBy(d => d.VerificationStatus)
                    .Select(g => new
                    {
                        Status = g.Key,
                        Count = g.Count()
                    })
                    .ToListAsync();

                return Ok(new
                {
                    success = true,
                    data = new
                    {
                        overview = new
                        {
                            totalDrivers,
                            activeDrivers,
                            verificationPending,
                            verifiedDrivers
                        },
                        topDrivers,
                        verificationStatus
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    success = false,
                    message = "Failed to fetch driver analytics",
                    error = ex.Message
                });
            }
        }

        // GET: api/v1/AdminAnalytics/rides
        [HttpGet("rides")]
        public async Task<IActionResult> GetRideAnalytics()
        {
            try
            {
                // Ride Status Breakdown
                var ridesByStatus = await _context.Rides
                    .GroupBy(r => r.Status)
                    .Select(g => new
                    {
                        Status = g.Key,
                        Count = g.Count()
                    })
                    .ToListAsync();

                // Daily Ride Stats (last 30 days)
                var dailyRideStats = await _context.Rides
                    .Where(r => r.CreatedAt >= DateTime.UtcNow.AddDays(-30))
                    .GroupBy(r => r.CreatedAt.Date)
                    .Select(g => new
                    {
                        Date = g.Key.ToString("yyyy-MM-dd"),
                        TotalRides = g.Count(),
                        Distance = g.Sum(r => r.Distance ?? 0),
                        EstimatedEarnings = g.Sum(r => r.EstimatedEarnings)
                    })
                    .OrderByDescending(s => s.Date)
                    .Take(30)
                    .ToListAsync();

                // Peak Hours Analysis (group by hour of day)
                var peakHours = await _context.Bookings
                    .Where(b => b.CreatedAt >= DateTime.UtcNow.AddDays(-30))
                    .GroupBy(b => b.CreatedAt.Hour)
                    .Select(g => new
                    {
                        Hour = g.Key,
                        Bookings = g.Count()
                    })
                    .OrderByDescending(h => h.Bookings)
                    .ToListAsync();

                return Ok(new
                {
                    success = true,
                    data = new
                    {
                        ridesByStatus,
                        dailyRideStats,
                        peakHours
                    }
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    success = false,
                    message = "Failed to fetch ride analytics",
                    error = ex.Message
                });
            }
        }

        // Helper method to get ISO week number
        private int GetWeekNumber(DateTime date)
        {
            var culture = System.Globalization.CultureInfo.CurrentCulture;
            return culture.Calendar.GetWeekOfYear(date, System.Globalization.CalendarWeekRule.FirstFourDayWeek, DayOfWeek.Monday);
        }
    }
}
