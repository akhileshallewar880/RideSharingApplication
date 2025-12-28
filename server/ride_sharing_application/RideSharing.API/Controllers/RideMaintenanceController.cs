using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;
using RideSharing.API.Models.Domain;

namespace RideSharing.API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class RideMaintenanceController : ControllerBase
    {
        private readonly RideSharingDbContext _dbContext;
        private readonly ILogger<RideMaintenanceController> _logger;
        private readonly IConfiguration _configuration;
        private readonly IServiceProvider _serviceProvider;

        public RideMaintenanceController(
            RideSharingDbContext dbContext,
            ILogger<RideMaintenanceController> logger,
            IConfiguration configuration,
            IServiceProvider serviceProvider)
        {
            _dbContext = dbContext;
            _logger = logger;
            _configuration = configuration;
            _serviceProvider = serviceProvider;
        }

        /// <summary>
        /// Manually trigger auto-cancellation of expired rides
        /// </summary>
        /// <param name="date">Optional: specific date to cancel rides for (format: yyyy-MM-dd). If not provided, uses today's date.</param>
        /// <returns>Summary of cancelled rides and bookings</returns>
        [HttpPost("cancel-expired-rides")]
        // [Authorize(Roles = "Admin")] // Uncomment to require admin authorization
        public async Task<IActionResult> CancelExpiredRides([FromQuery] DateTime? date = null, [FromQuery] int batchSize = 100)
        {
            try
            {
                var enableNotifications = _configuration.GetValue<bool>("RideAutoCancellation:EnableNotifications", true);
                var enableAutoRefund = _configuration.GetValue<bool>("RideAutoCancellation:EnableAutoRefund", true);

                var targetDate = date?.Date ?? DateTime.UtcNow.Date;
                
                _logger.LogInformation("Manual cancellation triggered for date: {Date}", targetDate);

                int totalCancelledRides = 0;
                int totalCancelledBookings = 0;
                int totalRefundedBookings = 0;
                bool hasMore = true;

                // Process in batches to avoid memory/timeout issues
                while (hasMore)
                {
                    // Find expired rides in batches (no tracking for better performance)
                    var expiredRidesBatch = await _dbContext.Rides
                        .AsNoTracking()
                        .Where(r => (r.Status == "scheduled" || r.Status == "upcoming") &&
                                   r.TravelDate.Date <= targetDate)
                        .Take(batchSize)
                        .Select(r => new { r.Id, r.RideNumber, r.TravelDate, r.DriverId })
                        .ToListAsync();

                    if (!expiredRidesBatch.Any())
                    {
                        hasMore = false;
                        break;
                    }

                    var rideIds = expiredRidesBatch.Select(r => r.Id).ToList();

                    // Get actual tracked entities
                    var rides = await _dbContext.Rides
                        .Where(r => rideIds.Contains(r.Id))
                        .ToListAsync();

                    // Get bookings separately to avoid tracking issues
                    var bookings = await _dbContext.Bookings
                        .Where(b => rideIds.Contains(b.RideId) && 
                               b.Status != "completed" && b.Status != "cancelled" && b.Status != "refunded")
                        .ToListAsync();

                    // Get all unique user IDs in one query
                    var allUserIds = expiredRidesBatch.Select(r => r.DriverId)
                        .Union(bookings.Select(b => b.PassengerId))
                        .Distinct()
                        .ToList();

                    var existingUserIds = await _dbContext.Users
                        .Where(u => allUserIds.Contains(u.Id))
                        .Select(u => u.Id)
                        .ToListAsync();

                    var existingUserSet = new HashSet<Guid>(existingUserIds);

                    // Process rides
                    foreach (var ride in rides)
                    {
                        try
                        {
                            ride.Status = "cancelled";
                            ride.CancellationReason = $"Manually cancelled: Ride scheduled for {ride.TravelDate:yyyy-MM-dd} never started";
                            ride.UpdatedAt = DateTime.UtcNow;

                            var rideBookings = bookings.Where(b => b.RideId == ride.Id).ToList();

                            foreach (var booking in rideBookings)
                            {
                                booking.Status = "cancelled";
                                booking.CancellationType = "system";
                                booking.CancellationReason = $"Ride manually cancelled: Scheduled ride for {ride.TravelDate:yyyy-MM-dd} never started";
                                booking.CancelledAt = DateTime.UtcNow;
                                booking.UpdatedAt = DateTime.UtcNow;

                                totalCancelledBookings++;

                                if (enableAutoRefund && booking.PaymentStatus == "paid")
                                {
                                    booking.PaymentStatus = "refunded";
                                    booking.Status = "refunded";
                                    totalRefundedBookings++;
                                }
                            }

                            totalCancelledRides++;
                        }
                        catch (Exception rideEx)
                        {
                            _logger.LogError(rideEx, $"Failed to cancel ride {ride.RideNumber}");
                        }
                    }

                    // Save changes for this batch
                    await _dbContext.SaveChangesAsync();

                    // Send notifications separately (non-blocking)
                    if (enableNotifications)
                    {
                        _ = Task.Run(async () =>
                        {
                            try
                            {
                                using var scope = _serviceProvider.CreateScope();
                                var notifDbContext = scope.ServiceProvider.GetRequiredService<RideSharingDbContext>();

                                foreach (var ride in expiredRidesBatch)
                                {
                                    if (existingUserSet.Contains(ride.DriverId))
                                    {
                                        notifDbContext.Notifications.Add(new Notification
                                        {
                                            Id = Guid.NewGuid(),
                                            UserId = ride.DriverId,
                                            Title = "Ride Cancelled",
                                            Message = $"Your ride {ride.RideNumber} scheduled for {ride.TravelDate:dd MMM yyyy} was cancelled as it never started.",
                                            Type = "ride_cancelled",
                                            Data = ride.Id.ToString(),
                                            IsRead = false,
                                            CreatedAt = DateTime.UtcNow
                                        });
                                    }
                                }

                                var rideBookings = bookings.Where(b => rideIds.Contains(b.RideId));
                                foreach (var booking in rideBookings)
                                {
                                    if (existingUserSet.Contains(booking.PassengerId))
                                    {
                                        notifDbContext.Notifications.Add(new Notification
                                        {
                                            Id = Guid.NewGuid(),
                                            UserId = booking.PassengerId,
                                            Title = "Booking Cancelled",
                                            Message = $"Your booking {booking.BookingNumber} was cancelled as the ride never started. " +
                                                    (booking.PaymentStatus == "refunded" ? "A full refund has been initiated." : ""),
                                            Type = "booking_cancelled",
                                            Data = booking.Id.ToString(),
                                            IsRead = false,
                                            CreatedAt = DateTime.UtcNow
                                        });
                                    }
                                }

                                await notifDbContext.SaveChangesAsync();
                            }
                            catch (Exception ex)
                            {
                                _logger.LogError(ex, "Error sending notifications in background");
                            }
                        });
                    }

                    _logger.LogInformation($"Processed batch: {rides.Count} rides");
                }

                _logger.LogInformation(
                    $"Manual cancellation completed: {totalCancelledRides} rides, {totalCancelledBookings} bookings cancelled, {totalRefundedBookings} refunds initiated");

                return Ok(new
                {
                    success = true,
                    message = $"Successfully cancelled expired rides for date {targetDate:yyyy-MM-dd}",
                    cancelledRides = totalCancelledRides,
                    cancelledBookings = totalCancelledBookings,
                    refundedBookings = totalRefundedBookings,
                    processedAt = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during manual ride cancellation");
                
                var innerMessage = ex.InnerException?.Message ?? ex.Message;
                var stackTrace = ex.InnerException?.StackTrace ?? ex.StackTrace;
                
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while cancelling rides",
                    error = ex.Message,
                    innerError = innerMessage,
                    details = stackTrace
                });
            }
        }

        /// <summary>
        /// Get summary of rides that would be cancelled (dry run)
        /// </summary>
        [HttpGet("preview-expired-rides")]
        // [Authorize(Roles = "Admin")] // Uncomment to require admin authorization
        public async Task<IActionResult> PreviewExpiredRides([FromQuery] DateTime? date = null)
        {
            try
            {
                var targetDate = date?.Date ?? DateTime.UtcNow.Date;

                var expiredRides = await _dbContext.Rides
                    .Include(r => r.Bookings)
                    .Where(r => (r.Status == "scheduled" || r.Status == "upcoming") &&
                               r.TravelDate.Date <= targetDate)
                    .Select(r => new
                    {
                        r.Id,
                        r.RideNumber,
                        r.TravelDate,
                        r.DepartureTime,
                        r.Status,
                        r.PickupLocation,
                        r.DropoffLocation,
                        BookingsCount = r.Bookings.Count(b => b.Status != "completed" && b.Status != "cancelled" && b.Status != "refunded"),
                        PaidBookingsCount = r.Bookings.Count(b => b.PaymentStatus == "paid" && b.Status != "completed" && b.Status != "cancelled" && b.Status != "refunded")
                    })
                    .ToListAsync();

                return Ok(new
                {
                    success = true,
                    targetDate = targetDate.ToString("yyyy-MM-dd"),
                    ridesToCancel = expiredRides.Count,
                    totalBookingsAffected = expiredRides.Sum(r => r.BookingsCount),
                    totalRefundsRequired = expiredRides.Sum(r => r.PaidBookingsCount),
                    rides = expiredRides
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error previewing expired rides");
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while previewing rides",
                    error = ex.Message
                });
            }
        }

        /// <summary>
        /// Manually process no-show bookings for completed rides
        /// </summary>
        /// <returns>Summary of no-show bookings processed</returns>
        [HttpPost("process-no-shows")]
        // [Authorize(Roles = "Admin")] // Uncomment to require admin authorization
        public async Task<IActionResult> ProcessNoShows([FromQuery] int batchSize = 100)
        {
            try
            {
                var enableNotifications = _configuration.GetValue<bool>("BookingNoShow:EnableNotifications", true);
                var noRefundForNoShow = _configuration.GetValue<bool>("BookingNoShow:NoRefundForNoShow", true);

                _logger.LogInformation("Manual no-show processing triggered");

                int totalProcessed = 0;
                int totalRefundsDenied = 0;
                bool hasMore = true;

                // Process in batches
                while (hasMore)
                {
                    // Find no-show bookings in batches (no tracking)
                    var noShowBookingsBatch = await _dbContext.Bookings
                        .AsNoTracking()
                        .Where(b => b.Ride.Status == "completed" &&
                                   (b.Status == "confirmed" || b.Status == "active") &&
                                   b.IsVerified == false)
                        .Take(batchSize)
                        .Select(b => new { 
                            b.Id, 
                            b.BookingNumber, 
                            b.PassengerId, 
                            b.PaymentStatus,
                            RideNumber = b.Ride.RideNumber,
                            TravelDate = b.Ride.TravelDate
                        })
                        .ToListAsync();

                    if (!noShowBookingsBatch.Any())
                    {
                        hasMore = false;
                        break;
                    }

                    var bookingIds = noShowBookingsBatch.Select(b => b.Id).ToList();

                    // Get tracked entities
                    var bookings = await _dbContext.Bookings
                        .Where(b => bookingIds.Contains(b.Id))
                        .ToListAsync();

                    // Get existing user IDs in one query
                    var passengerIds = noShowBookingsBatch.Select(b => b.PassengerId).Distinct().ToList();
                    var existingUserIds = await _dbContext.Users
                        .Where(u => passengerIds.Contains(u.Id))
                        .Select(u => u.Id)
                        .ToListAsync();

                    var existingUserSet = new HashSet<Guid>(existingUserIds);

                    foreach (var booking in bookings)
                    {
                        booking.Status = "cancelled";
                        booking.CancellationType = "system";
                        booking.CancellationReason = "Passenger no-show: Did not travel despite confirmed booking";
                        booking.CancelledAt = DateTime.UtcNow;
                        booking.UpdatedAt = DateTime.UtcNow;

                        // No refund policy for no-shows
                        if (noRefundForNoShow && booking.PaymentStatus == "paid")
                        {
                            totalRefundsDenied++;
                        }
                        else if (!noRefundForNoShow && booking.PaymentStatus == "paid")
                        {
                            booking.PaymentStatus = "refunded";
                            booking.Status = "refunded";
                        }

                        totalProcessed++;
                    }

                    // Save changes for this batch
                    await _dbContext.SaveChangesAsync();

                    // Send notifications in background
                    if (enableNotifications)
                    {
                        _ = Task.Run(async () =>
                        {
                            try
                            {
                                using var scope = _serviceProvider.CreateScope();
                                var notifDbContext = scope.ServiceProvider.GetRequiredService<RideSharingDbContext>();

                                foreach (var booking in noShowBookingsBatch)
                                {
                                    if (existingUserSet.Contains(booking.PassengerId))
                                    {
                                        notifDbContext.Notifications.Add(new Notification
                                        {
                                            Id = Guid.NewGuid(),
                                            UserId = booking.PassengerId,
                                            Title = "Booking Cancelled - No Show",
                                            Message = $"Your booking {booking.BookingNumber} for ride {booking.RideNumber} on {booking.TravelDate:dd MMM yyyy} was cancelled as you did not travel. " +
                                                    (noRefundForNoShow && booking.PaymentStatus == "paid" ? "No refund is applicable for no-show bookings." : ""),
                                            Type = "booking_noshow",
                                            Data = booking.Id.ToString(),
                                            IsRead = false,
                                            CreatedAt = DateTime.UtcNow
                                        });
                                    }
                                }

                                await notifDbContext.SaveChangesAsync();
                            }
                            catch (Exception ex)
                            {
                                _logger.LogError(ex, "Error sending no-show notifications in background");
                            }
                        });
                    }

                    _logger.LogInformation($"Processed batch: {bookings.Count} no-show bookings");
                }

                _logger.LogInformation($"Manual no-show processing completed: {totalProcessed} bookings processed, {totalRefundsDenied} refunds denied");

                return Ok(new
                {
                    success = true,
                    message = "Successfully processed no-show bookings",
                    processedBookings = totalProcessed,
                    refundsDenied = totalRefundsDenied,
                    processedAt = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during manual no-show processing");
                
                var innerMessage = ex.InnerException?.Message ?? ex.Message;
                var stackTrace = ex.InnerException?.StackTrace ?? ex.StackTrace;
                
                return StatusCode(500, new
                {
                    success = false,
                    message = "An error occurred while processing no-shows",
                    error = ex.Message,
                    innerError = innerMessage,
                    details = stackTrace
                });
            }
        }
    }
}
