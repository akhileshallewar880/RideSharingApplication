using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using RideSharing.API.Services.Interface;
using System.Security.Claims;

namespace RideSharing.API.Hubs
{
    /// <summary>
    /// SignalR Hub for real-time ride tracking
    /// Handles location updates, ride status changes, and passenger notifications
    /// </summary>
    [Authorize]
    public class TrackingHub : Hub
    {
        private readonly ILocationTrackingService _locationTrackingService;
        private readonly ILogger<TrackingHub> _logger;

        public TrackingHub(
            ILocationTrackingService locationTrackingService,
            ILogger<TrackingHub> logger)
        {
            _locationTrackingService = locationTrackingService;
            _logger = logger;
        }

        /// <summary>
        /// Called when a client connects
        /// </summary>
        public override async Task OnConnectedAsync()
        {
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var userType = Context.User?.FindFirst("user_type")?.Value;
            
            _logger.LogInformation("User {UserId} ({UserType}) connected to tracking hub. ConnectionId: {ConnectionId}",
                userId, userType, Context.ConnectionId);

            await base.OnConnectedAsync();
        }

        /// <summary>
        /// Called when a client disconnects
        /// </summary>
        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            if (exception != null)
            {
                _logger.LogError(exception, "User {UserId} disconnected with error. ConnectionId: {ConnectionId}",
                    userId, Context.ConnectionId);
            }
            else
            {
                _logger.LogInformation("User {UserId} disconnected from tracking hub. ConnectionId: {ConnectionId}",
                    userId, Context.ConnectionId);
            }

            await base.OnDisconnectedAsync(exception);
        }

        /// <summary>
        /// Join a ride room to receive real-time updates
        /// </summary>
        /// <param name="rideId">The ride ID to join</param>
        public async Task JoinRide(string rideId)
        {
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var userType = Context.User?.FindFirst("user_type")?.Value;
            
            if (string.IsNullOrEmpty(rideId))
            {
                _logger.LogWarning("User {UserId} attempted to join ride with empty rideId", userId);
                return;
            }

            var groupName = GetRideGroupName(rideId);
            await Groups.AddToGroupAsync(Context.ConnectionId, groupName);
            
            _logger.LogInformation("User {UserId} ({UserType}) joined ride room: {RideId}", 
                userId, userType, rideId);

            // Send confirmation to the client
            await Clients.Caller.SendAsync("JoinedRide", new { rideId, timestamp = DateTime.UtcNow });
        }

        /// <summary>
        /// Leave a ride room
        /// </summary>
        /// <param name="rideId">The ride ID to leave</param>
        public async Task LeaveRide(string rideId)
        {
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            if (string.IsNullOrEmpty(rideId))
            {
                return;
            }

            var groupName = GetRideGroupName(rideId);
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, groupName);
            
            _logger.LogInformation("User {UserId} left ride room: {RideId}", userId, rideId);
        }

        /// <summary>
        /// Driver sends location update
        /// </summary>
        public async Task SendLocationUpdate(LocationUpdateRequest request)
        {
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var userType = Context.User?.FindFirst("user_type")?.Value;

            // Verify user is a driver
            if (userType != "driver")
            {
                _logger.LogWarning("Non-driver user {UserId} attempted to send location update", userId);
                await Clients.Caller.SendAsync("Error", new { message = "Only drivers can send location updates" });
                return;
            }

            try
            {
                // Parse and validate ride ID
                if (!Guid.TryParse(request.RideId, out var rideId))
                {
                    await Clients.Caller.SendAsync("Error", new { message = "Invalid ride ID" });
                    return;
                }

                // Save location update
                var locationUpdate = await _locationTrackingService.SaveLocationUpdateAsync(
                    rideId,
                    Guid.Parse(userId!),
                    (decimal)request.Location.Latitude,
                    (decimal)request.Location.Longitude,
                    (decimal)request.Location.Speed,
                    (decimal)request.Location.Heading,
                    (decimal)request.Location.Accuracy
                );

                // Calculate ETA and remaining distance (if passengers are waiting)
                var metrics = await _locationTrackingService.CalculateRideMetricsAsync(rideId);

                // Broadcast to all passengers in the ride
                var groupName = GetRideGroupName(request.RideId);
                await Clients.Group(groupName).SendAsync("LocationUpdate", new
                {
                    rideId = request.RideId,
                    location = new
                    {
                        request.Location.Latitude,
                        request.Location.Longitude,
                        request.Location.Speed,
                        request.Location.Heading,
                        timestamp = locationUpdate.Timestamp
                    },
                    estimatedArrival = metrics?.EstimatedArrivalMinutes,
                    remainingDistance = metrics?.RemainingDistanceKm
                });

                _logger.LogDebug("Driver {UserId} sent location update for ride {RideId}", userId, request.RideId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing location update from driver {UserId}", userId);
                await Clients.Caller.SendAsync("Error", new { message = "Failed to process location update" });
            }
        }

        /// <summary>
        /// Notify that passenger has boarded
        /// </summary>
        public async Task NotifyPassengerBoarded(PassengerBoardedRequest request)
        {
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var userType = Context.User?.FindFirst("user_type")?.Value;

            if (userType != "driver")
            {
                await Clients.Caller.SendAsync("Error", new { message = "Only drivers can notify passenger boarding" });
                return;
            }

            try
            {
                var groupName = GetRideGroupName(request.RideId);
                
                await Clients.Group(groupName).SendAsync("PassengerUpdate", new
                {
                    rideId = request.RideId,
                    bookingId = request.BookingId,
                    passengerName = request.PassengerName,
                    updateType = "boarded",
                    timestamp = DateTime.UtcNow
                });

                _logger.LogInformation("Passenger {PassengerName} boarded ride {RideId}", 
                    request.PassengerName, request.RideId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error notifying passenger boarded");
            }
        }

        /// <summary>
        /// Notify that payment has been collected
        /// </summary>
        public async Task NotifyPaymentCollected(PaymentCollectedRequest request)
        {
            var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var userType = Context.User?.FindFirst("user_type")?.Value;

            if (userType != "driver")
            {
                await Clients.Caller.SendAsync("Error", new { message = "Only drivers can notify payment collection" });
                return;
            }

            try
            {
                var groupName = GetRideGroupName(request.RideId);
                
                await Clients.Group(groupName).SendAsync("PassengerUpdate", new
                {
                    rideId = request.RideId,
                    bookingId = request.BookingId,
                    updateType = "payment_collected",
                    amount = request.Amount,
                    timestamp = DateTime.UtcNow
                });

                _logger.LogInformation("Payment collected for booking {BookingId} on ride {RideId}: {Amount}", 
                    request.BookingId, request.RideId, request.Amount);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error notifying payment collected");
            }
        }

        /// <summary>
        /// Notify ride status change (started, completed, etc.)
        /// </summary>
        public async Task NotifyRideStatusChange(string rideId, string status, string? message = null)
        {
            var groupName = GetRideGroupName(rideId);
            
            await Clients.Group(groupName).SendAsync("TripStatus", new
            {
                rideId,
                status,
                message,
                timestamp = DateTime.UtcNow
            });

            _logger.LogInformation("Ride {RideId} status changed to: {Status}", rideId, status);
        }

        /// <summary>
        /// Get ride group name for SignalR groups
        /// </summary>
        private static string GetRideGroupName(string rideId) => $"ride_{rideId}";
    }

    #region Request Models

    public class LocationUpdateRequest
    {
        public string RideId { get; set; } = string.Empty;
        public LocationData Location { get; set; } = new();
    }

    public class LocationData
    {
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public double Speed { get; set; }
        public double Heading { get; set; }
        public double Accuracy { get; set; }
    }

    public class PassengerBoardedRequest
    {
        public string RideId { get; set; } = string.Empty;
        public string BookingId { get; set; } = string.Empty;
        public string PassengerName { get; set; } = string.Empty;
    }

    public class PaymentCollectedRequest
    {
        public string RideId { get; set; } = string.Empty;
        public string BookingId { get; set; } = string.Empty;
        public decimal Amount { get; set; }
    }

    #endregion
}
