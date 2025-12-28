using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;
using RideSharing.API.Models.Domain;
using FcmNotification = FirebaseAdmin.Messaging.Notification;

namespace RideSharing.API.Services.Implementation
{
    /// <summary>
    /// Background service to handle passenger no-shows.
    /// Marks bookings as no-show when the ride completes but passenger never verified (never traveled).
    /// </summary>
    public class BookingNoShowService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<BookingNoShowService> _logger;
        private readonly IConfiguration _configuration;
        private readonly TimeSpan _checkInterval;
        private readonly bool _enabled;
        private readonly bool _enableNotifications;
        private readonly bool _noRefundForNoShow;

        public BookingNoShowService(
            IServiceProvider serviceProvider,
            ILogger<BookingNoShowService> logger,
            IConfiguration configuration)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
            _configuration = configuration;
            
            _enabled = _configuration.GetValue<bool>("BookingNoShow:Enabled", true);
            _checkInterval = TimeSpan.FromMinutes(
                _configuration.GetValue<int>("BookingNoShow:CheckIntervalMinutes", 10)
            );
            _enableNotifications = _configuration.GetValue<bool>("BookingNoShow:EnableNotifications", true);
            _noRefundForNoShow = _configuration.GetValue<bool>("BookingNoShow:NoRefundForNoShow", true);
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            if (!_enabled)
            {
                _logger.LogInformation("Booking No-Show Service is disabled in configuration.");
                return;
            }

            _logger.LogInformation(
                "Booking No-Show Service started. Check interval: {CheckInterval}",
                _checkInterval);

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await ProcessNoShowBookingsAsync(stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error occurred while processing no-show bookings.");
                }

                await Task.Delay(_checkInterval, stoppingToken);
            }

            _logger.LogInformation("Booking No-Show Service stopped.");
        }

        private async Task ProcessNoShowBookingsAsync(CancellationToken cancellationToken)
        {
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<RideSharingDbContext>();

            // Find all bookings where:
            // 1. Ride status is "completed" (ride finished)
            // 2. Booking status is still "confirmed" or "active" (not completed/cancelled)
            // 3. Booking is NOT verified (passenger never showed up - no OTP verification)
            var noShowBookings = await dbContext.Bookings
                .Include(b => b.Ride)
                .Where(b => b.Ride.Status == "completed" &&
                           (b.Status == "confirmed" || b.Status == "active") &&
                           b.IsVerified == false)
                .ToListAsync(cancellationToken);

            if (noShowBookings.Any())
            {
                _logger.LogInformation($"Found {noShowBookings.Count} no-show bookings to process.");

                foreach (var booking in noShowBookings)
                {
                    await MarkAsNoShowAsync(booking, dbContext);
                }

                await dbContext.SaveChangesAsync(cancellationToken);
                _logger.LogInformation($"Successfully processed {noShowBookings.Count} no-show bookings.");
            }
        }

        private async Task MarkAsNoShowAsync(Booking booking, RideSharingDbContext dbContext)
        {
            try
            {
                _logger.LogInformation($"Marking booking {booking.BookingNumber} as no-show");

                // Update booking status to cancelled with no-show type
                booking.Status = "cancelled";
                booking.CancellationType = "system";
                booking.CancellationReason = "Passenger no-show: Did not travel despite confirmed booking";
                booking.CancelledAt = DateTime.UtcNow;
                booking.UpdatedAt = DateTime.UtcNow;

                // No refund for no-shows (policy decision)
                if (_noRefundForNoShow && booking.PaymentStatus == "paid")
                {
                    // Keep payment status as "paid" - no refund for no-shows
                    _logger.LogInformation($"No refund for no-show booking {booking.BookingNumber}");
                }
                else if (!_noRefundForNoShow && booking.PaymentStatus == "paid")
                {
                    // Optional: Issue refund even for no-shows
                    booking.PaymentStatus = "refunded";
                    booking.Status = "refunded";
                    _logger.LogInformation($"Refund issued for no-show booking {booking.BookingNumber}");
                }

                // Send notification if enabled
                if (_enableNotifications)
                {
                    var passengerExists = await dbContext.Users.AnyAsync(u => u.Id == booking.PassengerId);
                    if (passengerExists)
                    {
                        var notification = new RideSharing.API.Models.Domain.Notification
                        {
                            Id = Guid.NewGuid(),
                            UserId = booking.PassengerId,
                            Title = "Booking Marked as No-Show",
                            Message = $"Your booking {booking.BookingNumber} for {booking.Ride.TravelDate:dd MMM yyyy} was marked as no-show because you did not travel. " +
                                    (_noRefundForNoShow && booking.PaymentStatus == "paid" 
                                        ? "No refund will be issued as per our no-show policy." 
                                        : ""),
                            Type = "booking_noshow",
                            Data = booking.Id.ToString(),
                            IsRead = false,
                            CreatedAt = DateTime.UtcNow
                        };
                        await dbContext.Notifications.AddAsync(notification);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error marking booking {booking.BookingNumber} as no-show");
            }
        }
    }
}
