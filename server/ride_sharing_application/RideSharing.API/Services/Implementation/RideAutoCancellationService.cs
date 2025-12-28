using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;
using RideSharing.API.Models.Domain;
using FcmNotification = FirebaseAdmin.Messaging.Notification;

namespace RideSharing.API.Services.Implementation
{
    /// <summary>
    /// Background service to automatically cancel rides and bookings at end of day (11:30 PM)
    /// for all rides scheduled that day that never started.
    /// </summary>
    public class RideAutoCancellationService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<RideAutoCancellationService> _logger;
        private readonly IConfiguration _configuration;
        private readonly TimeSpan _dailyRunTime; // 11:30 PM by default
        private readonly bool _enabled;
        private readonly bool _enableNotifications;
        private readonly bool _enableAutoRefund;

        public RideAutoCancellationService(
            IServiceProvider serviceProvider,
            ILogger<RideAutoCancellationService> logger,
            IConfiguration configuration)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
            _configuration = configuration;
            
            // Load configuration settings
            _enabled = _configuration.GetValue<bool>("RideAutoCancellation:Enabled", true);
            
            // Parse daily run time (default: 23:30 = 11:30 PM)
            var runTimeString = _configuration.GetValue<string>("RideAutoCancellation:DailyRunTime", "23:30");
            if (!TimeSpan.TryParse(runTimeString, out _dailyRunTime))
            {
                _dailyRunTime = new TimeSpan(23, 30, 0); // Default to 11:30 PM
                _logger.LogWarning("Invalid DailyRunTime format. Using default 23:30 (11:30 PM)");
            }
            
            _enableNotifications = _configuration.GetValue<bool>("RideAutoCancellation:EnableNotifications", true);
            _enableAutoRefund = _configuration.GetValue<bool>("RideAutoCancellation:EnableAutoRefund", true);
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            if (!_enabled)
            {
                _logger.LogInformation("Ride Auto-Cancellation Service is disabled in configuration.");
                return;
            }

            _logger.LogInformation(
                "Ride Auto-Cancellation Service started. Daily run time: {RunTime}",
                _dailyRunTime.ToString(@"hh\:mm"));

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    var delay = GetDelayUntilNextRun();
                    _logger.LogInformation(
                        "Next auto-cancellation check scheduled in {Hours} hours and {Minutes} minutes",
                        delay.Hours, delay.Minutes);

                    // Wait until the scheduled time
                    await Task.Delay(delay, stoppingToken);

                    if (!stoppingToken.IsCancellationRequested)
                    {
                        await CancelExpiredRidesAsync(stoppingToken);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error occurred while cancelling expired rides.");
                    // Wait 1 hour before retrying in case of error
                    await Task.Delay(TimeSpan.FromHours(1), stoppingToken);
                }
            }

            _logger.LogInformation("Ride Auto-Cancellation Service stopped.");
        }

        private TimeSpan GetDelayUntilNextRun()
        {
            var now = DateTime.Now;
            var nextRun = DateTime.Today.Add(_dailyRunTime);
            
            // If the scheduled time has already passed today, schedule for tomorrow
            if (now > nextRun)
            {
                nextRun = nextRun.AddDays(1);
            }
            
            return nextRun - now;
        }

        private async Task CancelExpiredRidesAsync(CancellationToken cancellationToken)
        {
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<RideSharingDbContext>();

            var currentUtcTime = DateTime.UtcNow;
            var currentDate = currentUtcTime.Date;

            _logger.LogInformation("Running daily auto-cancellation check for date: {Date}", currentDate);

            // Find all rides scheduled for today or earlier that never started
            // Status should be 'scheduled' or 'upcoming' and the travel date has passed or is today
            var expiredRides = await dbContext.Rides
                .Include(r => r.Bookings)
                .Where(r => (r.Status == "scheduled" || r.Status == "upcoming") &&
                           r.TravelDate.Date <= currentDate)
                .ToListAsync(cancellationToken);

            if (expiredRides.Any())
            {
                _logger.LogInformation($"Found {expiredRides.Count} expired rides to cancel for date {currentDate:yyyy-MM-dd}.");

                foreach (var ride in expiredRides)
                {
                    await CancelRideAndBookingsAsync(ride, dbContext, cancellationToken);
                }

                await dbContext.SaveChangesAsync(cancellationToken);
                _logger.LogInformation($"Successfully cancelled {expiredRides.Count} expired rides and their bookings.");
            }
            else
            {
                _logger.LogInformation("No expired rides found for cancellation.");
            }
        }

        private async Task CancelRideAndBookingsAsync(
            Ride ride, 
            RideSharingDbContext dbContext, 
            CancellationToken cancellationToken)
        {
            try
            {
                // Update ride status
                ride.Status = "cancelled";
                ride.CancellationReason = $"Automatically cancelled at end of day: Ride scheduled for {ride.TravelDate:yyyy-MM-dd} never started";
                ride.UpdatedAt = DateTime.UtcNow;

                _logger.LogInformation($"Cancelling ride {ride.RideNumber}");

                // Cancel all associated bookings that are not already completed or cancelled
                var activeBookings = ride.Bookings
                    .Where(b => b.Status != "completed" && b.Status != "cancelled" && b.Status != "refunded")
                    .ToList();

                foreach (var booking in activeBookings)
                {
                    booking.Status = "cancelled";
                    booking.CancellationType = "system";
                    booking.CancellationReason = $"Ride automatically cancelled at end of day: Scheduled ride for {ride.TravelDate:yyyy-MM-dd} never started";
                    booking.CancelledAt = DateTime.UtcNow;
                    booking.UpdatedAt = DateTime.UtcNow;

                    // If payment was made and auto-refund is enabled, mark for refund
                    if (_enableAutoRefund && booking.PaymentStatus == "paid")
                    {
                        booking.PaymentStatus = "refunded";
                        booking.Status = "refunded";
                        
                        // TODO: Trigger refund process through payment gateway
                        // await _paymentService.ProcessRefundAsync(booking.Id);
                        _logger.LogInformation($"Booking {booking.BookingNumber} marked for refund.");
                    }

                    _logger.LogInformation($"Cancelled booking {booking.BookingNumber} for ride {ride.RideNumber}");
                }

                // Send notifications if enabled
                if (_enableNotifications)
                {
                    await SendCancellationNotificationsAsync(ride, activeBookings, dbContext);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error cancelling ride {ride.RideNumber}");
            }
        }

        private async Task SendCancellationNotificationsAsync(
            Ride ride, 
            List<Booking> cancelledBookings, 
            RideSharingDbContext dbContext)
        {
            try
            {
                // Verify driver exists before creating notification
                var driverExists = await dbContext.Users.AnyAsync(u => u.Id == ride.DriverId);
                if (driverExists)
                {
                    var driverNotification = new RideSharing.API.Models.Domain.Notification
                    {
                        Id = Guid.NewGuid(),
                        UserId = ride.DriverId,
                        Title = "Ride Automatically Cancelled",
                        Message = $"Your ride {ride.RideNumber} scheduled for {ride.TravelDate:dd MMM yyyy} was automatically cancelled at end of day as it never started.",
                        Type = "ride_cancelled",
                        Data = ride.Id.ToString(),
                        IsRead = false,
                        CreatedAt = DateTime.UtcNow
                    };
                    await dbContext.Notifications.AddAsync(driverNotification);
                }
                else
                {
                    _logger.LogWarning($"Skipping notification for driver {ride.DriverId} - user not found");
                }

                // Create notifications for all passengers
                foreach (var booking in cancelledBookings)
                {
                    var passengerExists = await dbContext.Users.AnyAsync(u => u.Id == booking.PassengerId);
                    if (passengerExists)
                    {
                        var passengerNotification = new RideSharing.API.Models.Domain.Notification
                        {
                            Id = Guid.NewGuid(),
                            UserId = booking.PassengerId,
                            Title = "Booking Automatically Cancelled",
                            Message = $"Your booking {booking.BookingNumber} for {ride.TravelDate:dd MMM yyyy} was automatically cancelled at end of day as the ride never started. " +
                                    (booking.PaymentStatus == "refunded" ? "A full refund has been initiated." : ""),
                            Type = "booking_cancelled",
                            Data = booking.Id.ToString(),
                            IsRead = false,
                            CreatedAt = DateTime.UtcNow
                        };
                        await dbContext.Notifications.AddAsync(passengerNotification);
                    }
                    else
                    {
                        _logger.LogWarning($"Skipping notification for passenger {booking.PassengerId} - user not found");
                    }
                }

                _logger.LogInformation($"Notifications created for ride {ride.RideNumber} cancellation.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error sending notifications for ride {ride.RideNumber}");
            }
        }
    }
}
