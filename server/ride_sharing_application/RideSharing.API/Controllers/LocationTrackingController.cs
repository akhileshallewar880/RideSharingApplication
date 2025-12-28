using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using RideSharing.API.Models.DTO;
using RideSharing.API.Services.Interface;
using System.Security.Claims;

namespace RideSharing.API.Controllers
{
    [Route("api/v1/tracking")]
    [ApiController]
    [Authorize]
    public class LocationTrackingController : ControllerBase
    {
        private readonly ILocationTrackingService _locationTrackingService;
        private readonly ILogger<LocationTrackingController> _logger;

        public LocationTrackingController(
            ILocationTrackingService locationTrackingService,
            ILogger<LocationTrackingController> logger)
        {
            _locationTrackingService = locationTrackingService;
            _logger = logger;
        }

        /// <summary>
        /// Get location history for a ride
        /// </summary>
        /// <param name="rideId">The ride ID</param>
        /// <param name="startTime">Optional start time filter</param>
        /// <param name="endTime">Optional end time filter</param>
        /// <param name="limit">Maximum number of records (default: 100)</param>
        /// <returns>Location history with distance metrics</returns>
        [HttpGet("rides/{rideId}/history")]
        [ProducesResponseType(typeof(LocationHistoryResponse), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetLocationHistory(
            [FromRoute] Guid rideId,
            [FromQuery] DateTime? startTime = null,
            [FromQuery] DateTime? endTime = null,
            [FromQuery] int limit = 100)
        {
            try
            {
                var history = await _locationTrackingService.GetLocationHistoryAsync(
                    rideId, startTime, endTime, limit);

                if (history.TotalCount == 0)
                {
                    return NotFound(new { message = "No location data found for this ride" });
                }

                return Ok(history);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting location history for ride {RideId}", rideId);
                return StatusCode(500, new { message = "An error occurred while retrieving location history" });
            }
        }

        /// <summary>
        /// Get latest location for a ride
        /// </summary>
        /// <param name="rideId">The ride ID</param>
        /// <returns>Latest location update</returns>
        [HttpGet("rides/{rideId}/latest")]
        [ProducesResponseType(typeof(LocationTrackingDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetLatestLocation([FromRoute] Guid rideId)
        {
            try
            {
                var location = await _locationTrackingService.GetLatestLocationAsync(rideId);

                if (location == null)
                {
                    return NotFound(new { message = "No location data found for this ride" });
                }

                var locationDto = new LocationTrackingDto
                {
                    Id = location.Id,
                    RideId = location.RideId,
                    DriverId = location.DriverId,
                    Latitude = location.Latitude,
                    Longitude = location.Longitude,
                    Speed = location.Speed,
                    Heading = location.Heading,
                    Accuracy = location.Accuracy,
                    Timestamp = location.Timestamp
                };

                return Ok(locationDto);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting latest location for ride {RideId}", rideId);
                return StatusCode(500, new { message = "An error occurred while retrieving location" });
            }
        }

        /// <summary>
        /// Get ride metrics (distance, ETA, speed)
        /// </summary>
        /// <param name="rideId">The ride ID</param>
        /// <returns>Calculated ride metrics</returns>
        [HttpGet("rides/{rideId}/metrics")]
        [ProducesResponseType(typeof(RideMetricsDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetRideMetrics([FromRoute] Guid rideId)
        {
            try
            {
                var metrics = await _locationTrackingService.CalculateRideMetricsAsync(rideId);

                if (metrics == null)
                {
                    return NotFound(new { message = "Ride not found or no location data available" });
                }

                return Ok(metrics);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calculating metrics for ride {RideId}", rideId);
                return StatusCode(500, new { message = "An error occurred while calculating ride metrics" });
            }
        }

        /// <summary>
        /// Get live tracking status for passengers
        /// </summary>
        /// <param name="rideId">The ride ID</param>
        /// <returns>Live tracking status with driver location and ETA</returns>
        [HttpGet("rides/{rideId}/live-status")]
        [ProducesResponseType(typeof(LiveTrackingStatusDto), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetLiveTrackingStatus([FromRoute] Guid rideId)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                Guid? passengerId = null;

                if (!string.IsNullOrEmpty(userId) && Guid.TryParse(userId, out var uid))
                {
                    passengerId = uid;
                }

                var status = await _locationTrackingService.GetLiveTrackingStatusAsync(rideId, passengerId);

                if (status == null)
                {
                    return NotFound(new { message = "Ride not found" });
                }

                return Ok(status);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting live tracking status for ride {RideId}", rideId);
                return StatusCode(500, new { message = "An error occurred while retrieving tracking status" });
            }
        }

        /// <summary>
        /// Save location update (alternative to SignalR for offline scenarios)
        /// </summary>
        /// <param name="request">Location update data</param>
        /// <returns>Saved location record</returns>
        [HttpPost("location")]
        [Authorize(Policy = "DriverOnly")]
        [ProducesResponseType(typeof(LocationTrackingDto), StatusCodes.Status201Created)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> SaveLocationUpdate([FromBody] SaveLocationUpdateRequest request)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var driverId))
                {
                    return Unauthorized(new { message = "Invalid user ID" });
                }

                var location = await _locationTrackingService.SaveLocationUpdateAsync(
                    request.RideId,
                    driverId,
                    request.Latitude,
                    request.Longitude,
                    request.Speed,
                    request.Heading,
                    request.Accuracy
                );

                var locationDto = new LocationTrackingDto
                {
                    Id = location.Id,
                    RideId = location.RideId,
                    DriverId = location.DriverId,
                    Latitude = location.Latitude,
                    Longitude = location.Longitude,
                    Speed = location.Speed,
                    Heading = location.Heading,
                    Accuracy = location.Accuracy,
                    Timestamp = location.Timestamp
                };

                return CreatedAtAction(
                    nameof(GetLatestLocation),
                    new { rideId = request.RideId },
                    locationDto
                );
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error saving location update");
                return StatusCode(500, new { message = "An error occurred while saving location update" });
            }
        }

        /// <summary>
        /// Batch save location updates (for offline sync)
        /// </summary>
        /// <param name="requests">List of location updates</param>
        /// <returns>Number of saved records</returns>
        [HttpPost("location/batch")]
        [Authorize(Policy = "DriverOnly")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> BatchSaveLocationUpdates([FromBody] List<SaveLocationUpdateRequest> requests)
        {
            try
            {
                var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var driverId))
                {
                    return Unauthorized(new { message = "Invalid user ID" });
                }

                var savedCount = 0;
                foreach (var request in requests)
                {
                    try
                    {
                        await _locationTrackingService.SaveLocationUpdateAsync(
                            request.RideId,
                            driverId,
                            request.Latitude,
                            request.Longitude,
                            request.Speed,
                            request.Heading,
                            request.Accuracy
                        );
                        savedCount++;
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "Failed to save location update in batch");
                    }
                }

                return Ok(new { 
                    message = $"Successfully saved {savedCount} of {requests.Count} location updates",
                    savedCount,
                    totalCount = requests.Count
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error batch saving location updates");
                return StatusCode(500, new { message = "An error occurred while saving location updates" });
            }
        }

        /// <summary>
        /// Calculate distance between two coordinates
        /// </summary>
        [HttpGet("distance")]
        [ProducesResponseType(typeof(object), StatusCodes.Status200OK)]
        public async Task<IActionResult> CalculateDistance(
            [FromQuery] decimal lat1,
            [FromQuery] decimal lon1,
            [FromQuery] decimal lat2,
            [FromQuery] decimal lon2)
        {
            try
            {
                var distance = await _locationTrackingService.CalculateDistanceAsync(lat1, lon1, lat2, lon2);
                
                return Ok(new { 
                    distanceKm = distance,
                    distanceMeters = distance * 1000
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calculating distance");
                return StatusCode(500, new { message = "An error occurred while calculating distance" });
            }
        }
    }
}
