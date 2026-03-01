using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using RideSharing.API.CustomValidations;
using RideSharing.API.Data;
using RideSharing.API.Hubs;
using RideSharing.API.Models.Domain;
using RideSharing.API.Models.DTO;
using RideSharing.API.Repositories.Interface;
using RideSharing.API.Services.Implementation;

namespace RideSharing.API.Controllers
{
    [Route("api/v1/driver/rides")]
    [ApiController]
    [Authorize]
    public class DriverRidesController : ControllerBase
    {
        private readonly IDriverRepository _driverRepository;
        private readonly IRideRepository _rideRepository;
        private readonly RouteDistanceService _routeDistanceService;
        private readonly ILogger<DriverRidesController> _logger;
        private readonly RideSharingDbContext _context;
        private readonly RideSharing.API.Services.Notification.FCMNotificationService _fcmService;
        private readonly IHubContext<TrackingHub> _hubContext;

        public DriverRidesController(
            IDriverRepository driverRepository,
            IRideRepository rideRepository,
            RouteDistanceService routeDistanceService,
            ILogger<DriverRidesController> logger,
            RideSharingDbContext context,
            RideSharing.API.Services.Notification.FCMNotificationService fcmService,
            IHubContext<TrackingHub> hubContext)
        {
            _driverRepository = driverRepository;
            _rideRepository = rideRepository;
            _routeDistanceService = routeDistanceService;
            _logger = logger;
            _context = context;
            _fcmService = fcmService;
            _hubContext = hubContext;
        }

        /// <summary>
        /// Schedule a new ride
        /// </summary>
        [HttpPost("schedule")]
        [ValidateModel]
        public async Task<IActionResult> ScheduleRide([FromBody] ScheduleRideRequestDto request)
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                // Get driver info
                var driver = await _driverRepository.GetDriverByUserIdAsync(userGuid);
                if (driver == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Driver profile not found"));
                }

                // Get driver's vehicle
                var vehicle = await _driverRepository.GetDriverVehicleAsync(driver.Id);
                if (vehicle == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("No vehicle registered"));
                }

                // Parse departure time
                if (!TimeSpan.TryParse(request.DepartureTime, out var departureTime))
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Invalid departure time format"));
                }

                // Serialize intermediate stops if provided
                string? intermediateStopsJson = null;
                if (request.IntermediateStops != null && request.IntermediateStops.Any())
                {
                    intermediateStopsJson = System.Text.Json.JsonSerializer.Serialize(request.IntermediateStops);
                }

                // Validate and serialize segment prices if provided
                string? segmentPricesJson = null;
                if (request.SegmentPrices != null && request.SegmentPrices.Any())
                {
                    // Must have intermediate stops to use segment pricing
                    if (request.IntermediateStops == null || !request.IntermediateStops.Any())
                    {
                        return BadRequest(ApiResponseDto<object>.ErrorResponse("Segment prices require intermediate stops"));
                    }

                    // Total segments should match (pickup -> intermediate stops -> dropoff)
                    var expectedSegments = request.IntermediateStops.Count + 1;
                    if (request.SegmentPrices.Count != expectedSegments)
                    {
                        return BadRequest(ApiResponseDto<object>.ErrorResponse(
                            $"Expected {expectedSegments} segment prices, got {request.SegmentPrices.Count}"));
                    }

                    // All prices must be positive
                    if (request.SegmentPrices.Any(sp => sp.Price <= 0))
                    {
                        return BadRequest(ApiResponseDto<object>.ErrorResponse("All segment prices must be greater than zero"));
                    }

                    segmentPricesJson = System.Text.Json.JsonSerializer.Serialize(request.SegmentPrices);
                }

                // Check for duplicate ride (same date and time within 15 minutes)
                var existingRides = await _driverRepository.GetDriverRidesAsync(driver.Id, null, 1, 1000);
                var duplicateRide = existingRides.FirstOrDefault(r =>
                    r.Status != "cancelled" &&
                    r.Status != "completed" &&
                    r.TravelDate.Date == request.TravelDate.Date &&
                    Math.Abs((r.DepartureTime - departureTime).TotalMinutes) < 15
                );

                if (duplicateRide != null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse(
                        $"A ride is already scheduled at {duplicateRide.DepartureTime:hh\\:mm} on this date. Ride number: {duplicateRide.RideNumber}"
                    ));
                }

                // **NEW: Check for time conflicts - driver must have 30-minute buffer after previous ride arrival**
                var newRideDepartureDateTime = request.TravelDate.Date + departureTime;
                foreach (var existingRide in existingRides.Where(r => 
                    r.Status != "cancelled" && r.Status != "completed"))
                {
                    var existingDepartureDateTime = existingRide.TravelDate.Date + existingRide.DepartureTime;
                    
                    // Calculate estimated arrival time (departure + duration)
                    var existingArrivalDateTime = existingDepartureDateTime;
                    if (existingRide.Duration.HasValue)
                    {
                        existingArrivalDateTime = existingDepartureDateTime.AddMinutes(existingRide.Duration.Value);
                    }
                    
                    // Add 30-minute buffer after arrival
                    var earliestNextRideTime = existingArrivalDateTime.AddMinutes(30);
                    
                    // Check if new ride departs before the buffer period ends
                    if (newRideDepartureDateTime >= existingDepartureDateTime && 
                        newRideDepartureDateTime < earliestNextRideTime)
                    {
                        return BadRequest(ApiResponseDto<object>.ErrorResponse(
                            $"Cannot schedule ride at {departureTime:hh\\:mm}. You have an existing ride " +
                            $"(#{existingRide.RideNumber}) from {existingRide.PickupLocation} to {existingRide.DropoffLocation} " +
                            $"departing at {existingRide.DepartureTime:hh\\:mm} and arriving around {existingArrivalDateTime:hh\\:mm tt}. " +
                            $"Please schedule your next ride after {earliestNextRideTime:hh\\:mm tt} (30-minute buffer after arrival)."
                        ));
                    }
                }

                // **Calculate route distance and ETA using coordinates for reliable timing**
                decimal? totalDistance = null;
                int? totalDuration = null;
                List<decimal>? segmentDistances = null;
                string? routeStopsTimingJson = null;

                try
                {
                    // Build stops list with coordinates
                    var stopsWithCoords = new List<(string name, double lat, double lng)>();
                    stopsWithCoords.Add((request.PickupLocation.Address,
                        (double)request.PickupLocation.Latitude,
                        (double)request.PickupLocation.Longitude));

                    // Look up intermediate stop coordinates from Cities table using IDs
                    if (request.IntermediateStopsIds != null && request.IntermediateStopsIds.Any())
                    {
                        foreach (var stopId in request.IntermediateStopsIds)
                        {
                            var city = await _context.Cities.FindAsync(stopId);
                            if (city != null)
                            {
                                stopsWithCoords.Add((city.Name,
                                    (double)(city.Latitude ?? 0),
                                    (double)(city.Longitude ?? 0)));
                            }
                        }
                    }
                    else if (request.IntermediateStops != null && request.IntermediateStops.Any())
                    {
                        foreach (var stop in request.IntermediateStops)
                            stopsWithCoords.Add((stop, 0, 0));
                    }

                    stopsWithCoords.Add((request.DropoffLocation.Address,
                        (double)request.DropoffLocation.Latitude,
                        (double)request.DropoffLocation.Longitude));

                    _logger.LogInformation("🗺️  Calculating route: {Route}", string.Join(" → ", stopsWithCoords.Select(s => s.name)));

                    var routeResult = await _routeDistanceService.CalculateMultiLegRouteByCoordinatesAsync(stopsWithCoords);

                    if (routeResult != null)
                    {
                        totalDistance = (decimal)routeResult.Value.totalDistanceKm;
                        totalDuration = routeResult.Value.totalDurationMinutes;
                        segmentDistances = routeResult.Value.segments.Select(s => (decimal)s.DistanceKm).ToList();

                        _logger.LogInformation("✅ Route calculated: {Distance}km, {Duration}min",
                            totalDistance, totalDuration);

                        // Build per-stop cumulative timing and store as JSON
                        var stopTimings = new List<RouteStopTimingData>();
                        double cumDistKm = 0;
                        int cumDurMin = 0;
                        stopTimings.Add(new RouteStopTimingData
                        {
                            Location = stopsWithCoords[0].name,
                            CumulativeDistanceKm = 0,
                            CumulativeDurationMinutes = 0
                        });
                        foreach (var seg in routeResult.Value.segments)
                        {
                            cumDistKm += seg.DistanceKm;
                            cumDurMin += seg.DurationMinutes;
                            stopTimings.Add(new RouteStopTimingData
                            {
                                Location = seg.ToLocation,
                                CumulativeDistanceKm = Math.Round(cumDistKm, 2),
                                CumulativeDurationMinutes = cumDurMin
                            });
                            _logger.LogInformation("   📍 {From} → {To}: {Distance}km, {Duration}min (cum: {CumDist}km, {CumDur}min)",
                                seg.FromLocation, seg.ToLocation, seg.DistanceKm, seg.DurationMinutes, Math.Round(cumDistKm, 2), cumDurMin);
                        }
                        routeStopsTimingJson = System.Text.Json.JsonSerializer.Serialize(stopTimings);
                    }
                    else
                    {
                        _logger.LogWarning("⚠️  Could not calculate route distance/duration");
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "❌ Error calculating route");
                }

                // Create main ride
                var ride = new Ride
                {
                    Id = Guid.NewGuid(),
                    RideNumber = $"RIDE{DateTime.UtcNow:yyyyMMddHHmmss}",
                    DriverId = driver.Id,
                    VehicleId = vehicle.Id,
                    VehicleModelId = request.VehicleModelId ?? vehicle.VehicleModelId,
                    PickupLocation = request.PickupLocation.Address,
                    PickupLatitude = request.PickupLocation.Latitude,
                    PickupLongitude = request.PickupLocation.Longitude,
                    PickupCityId = request.PickupLocationId,
                    DropoffLocation = request.DropoffLocation.Address,
                    DropoffLatitude = request.DropoffLocation.Latitude,
                    DropoffLongitude = request.DropoffLocation.Longitude,
                    DropoffCityId = request.DropoffLocationId,
                    IntermediateStops = intermediateStopsJson,
                    IntermediateStopIds = request.IntermediateStopsIds != null && request.IntermediateStopsIds.Any()
                        ? System.Text.Json.JsonSerializer.Serialize(request.IntermediateStopsIds)
                        : null,
                    SegmentPrices = segmentPricesJson,
                    TravelDate = request.TravelDate,
                    DepartureTime = departureTime,
                    TotalSeats = request.TotalSeats,
                    BookedSeats = 0,
                    PricePerSeat = request.PricePerSeat,
                    Distance = totalDistance,
                    Duration = totalDuration,
                    RouteStopsTimingJson = routeStopsTimingJson,
                    Status = "scheduled",
                    IsReturnTrip = false,
                    CreatedAt = DateTime.UtcNow
                };

                ride = await _driverRepository.CreateRideAsync(ride);

                var response = new ScheduleRideResponseDto
                {
                    RideId = ride.Id,
                    RideNumber = ride.RideNumber,
                    PickupLocation = ride.PickupLocation,
                    DropoffLocation = ride.DropoffLocation,
                    TravelDate = ride.TravelDate,
                    DepartureTime = ride.DepartureTime.ToString(@"hh\:mm"),
                    TotalSeats = ride.TotalSeats,
                    BookedSeats = ride.BookedSeats,
                    AvailableSeats = ride.TotalSeats - ride.BookedSeats,
                    PricePerSeat = ride.PricePerSeat,
                    Status = ride.Status,
                    CreatedAt = ride.CreatedAt,
                    SegmentPrices = request.SegmentPrices
                };

                // Handle return trip if requested
                if (request.ScheduleReturnTrip && !string.IsNullOrEmpty(request.ReturnDepartureTime))
                {
                    // Parse return departure date/time
                    if (!DateTime.TryParse(request.ReturnDepartureTime, out var returnDepartureDateTime))
                    {
                        return BadRequest(ApiResponseDto<object>.ErrorResponse("Invalid return departure time format"));
                    }

                    // Validate return time is after outbound trip
                    var outboundDateTime = request.TravelDate.Date + departureTime;
                    if (returnDepartureDateTime <= outboundDateTime)
                    {
                        return BadRequest(ApiResponseDto<object>.ErrorResponse("Return trip must be scheduled after outbound trip"));
                    }

                    // Build reversed per-stop timing for return trip
                    string? returnRouteStopsTimingJson = null;
                    if (routeStopsTimingJson != null)
                    {
                        try
                        {
                            var outboundStops = System.Text.Json.JsonSerializer.Deserialize<List<RouteStopTimingData>>(routeStopsTimingJson);
                            if (outboundStops != null && outboundStops.Count >= 2)
                            {
                                // Reverse the stop order; recalculate cumulative values from the reversed segments
                                var returnStops = new List<RouteStopTimingData>();
                                double retCumDist = 0;
                                int retCumDur = 0;
                                returnStops.Add(new RouteStopTimingData
                                {
                                    Location = outboundStops.Last().Location,
                                    CumulativeDistanceKm = 0,
                                    CumulativeDurationMinutes = 0
                                });
                                for (int i = outboundStops.Count - 1; i >= 1; i--)
                                {
                                    var segDist = outboundStops[i].CumulativeDistanceKm - outboundStops[i - 1].CumulativeDistanceKm;
                                    var segDur = outboundStops[i].CumulativeDurationMinutes - outboundStops[i - 1].CumulativeDurationMinutes;
                                    retCumDist += segDist;
                                    retCumDur += segDur;
                                    returnStops.Add(new RouteStopTimingData
                                    {
                                        Location = outboundStops[i - 1].Location,
                                        CumulativeDistanceKm = Math.Round(retCumDist, 2),
                                        CumulativeDurationMinutes = retCumDur
                                    });
                                }
                                returnRouteStopsTimingJson = System.Text.Json.JsonSerializer.Serialize(returnStops);
                            }
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "❌ Error building return trip route timings");
                        }
                    }

                    // Create return ride with swapped locations
                    var returnRide = new Ride
                    {
                        Id = Guid.NewGuid(),
                        RideNumber = $"RIDE{DateTime.UtcNow:yyyyMMddHHmmss}R",
                        DriverId = driver.Id,
                        VehicleId = vehicle.Id,
                        VehicleModelId = request.VehicleModelId ?? vehicle.VehicleModelId,
                        PickupLocation = request.DropoffLocation.Address, // Swapped
                        PickupLatitude = request.DropoffLocation.Latitude,
                        PickupLongitude = request.DropoffLocation.Longitude,
                        PickupCityId = request.DropoffLocationId, // Swapped
                        DropoffLocation = request.PickupLocation.Address, // Swapped
                        DropoffLatitude = request.PickupLocation.Latitude,
                        DropoffLongitude = request.PickupLocation.Longitude,
                        DropoffCityId = request.PickupLocationId, // Swapped
                        IntermediateStops = intermediateStopsJson != null && request.IntermediateStops != null
                            ? System.Text.Json.JsonSerializer.Serialize(Enumerable.Reverse(request.IntermediateStops).ToList())
                            : null,
                        IntermediateStopIds = request.IntermediateStopsIds != null && request.IntermediateStopsIds.Any()
                            ? System.Text.Json.JsonSerializer.Serialize(Enumerable.Reverse(request.IntermediateStopsIds).ToList())
                            : null,
                        SegmentPrices = segmentPricesJson != null && request.SegmentPrices != null
                            ? System.Text.Json.JsonSerializer.Serialize(Enumerable.Reverse(request.SegmentPrices).ToList())
                            : null,
                        TravelDate = returnDepartureDateTime.Date,
                        DepartureTime = returnDepartureDateTime.TimeOfDay,
                        TotalSeats = request.TotalSeats,
                        BookedSeats = 0,
                        PricePerSeat = request.PricePerSeat,
                        Distance = totalDistance,
                        Duration = totalDuration,
                        RouteStopsTimingJson = returnRouteStopsTimingJson,
                        Status = "scheduled",
                        IsReturnTrip = true,
                        LinkedReturnRideId = ride.Id,
                        CreatedAt = DateTime.UtcNow
                    };

                    returnRide = await _driverRepository.CreateRideAsync(returnRide);

                    // Link the outbound ride to return ride
                    ride.LinkedReturnRideId = returnRide.Id;
                    await _driverRepository.UpdateRideAsync(ride);

                    response.ReturnRideId = returnRide.Id;
                    response.ReturnRideNumber = returnRide.RideNumber;
                }

                return Ok(ApiResponseDto<ScheduleRideResponseDto>.SuccessResponse(response, "Ride scheduled successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error scheduling ride");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while scheduling ride"));
            }
        }

        /// <summary>
        /// Get driver's active and upcoming rides
        /// </summary>
        [HttpGet("active")]
        public async Task<IActionResult> GetActiveRides()
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                _logger.LogInformation("🔍 GetActiveRides: Extracted userId from token: {UserId}", userId);
                
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    _logger.LogWarning("⚠️ GetActiveRides: Invalid or missing userId in token");
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                var driver = await _driverRepository.GetDriverByUserIdAsync(userGuid);
                if (driver == null)
                {
                    _logger.LogWarning("⚠️ GetActiveRides: No driver profile found for userId: {UserId}", userGuid);
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Driver profile not found"));
                }

                _logger.LogInformation("✅ GetActiveRides: Found driver - DriverId: {DriverId}, UserId: {UserId}, Phone: {Phone}", 
                    driver.Id, userGuid, driver.User?.PhoneNumber ?? "N/A");

                // Get both scheduled and active rides
                var rides = await _driverRepository.GetDriverRidesAsync(driver.Id, null, 1, 100);
                _logger.LogInformation("📋 GetActiveRides: Retrieved {Count} rides for driver {DriverId}", rides.Count, driver.Id);

                var activeRides = rides.Select(r => new DriverRideDto
                {
                    RideId = r.Id,
                    RideNumber = r.RideNumber,
                    PickupLocation = r.PickupLocation,
                    DropoffLocation = r.DropoffLocation,
                    IntermediateStops = string.IsNullOrEmpty(r.IntermediateStops) 
                        ? null 
                        : System.Text.Json.JsonSerializer.Deserialize<List<string>>(r.IntermediateStops),
                    Date = r.TravelDate.ToString("dd-MM-yyyy"),
                    DepartureTime = DateTime.Today.Add(r.DepartureTime).ToString("hh:mm tt"),
                    TotalSeats = r.TotalSeats,
                    BookedSeats = r.BookedSeats,
                    AvailableSeats = r.TotalSeats - r.BookedSeats,
                    PricePerSeat = r.PricePerSeat,
                    EstimatedEarnings = r.PricePerSeat * r.BookedSeats,
                    Status = r.Status,
                    VehicleType = r.Vehicle?.VehicleType ?? "",
                    VehicleModelId = r.VehicleModelId,
                    LinkedReturnRideId = r.LinkedReturnRideId,
                    IsReturnTrip = r.IsReturnTrip,
                    SegmentPrices = string.IsNullOrEmpty(r.SegmentPrices)
                        ? null
                        : System.Text.Json.JsonSerializer.Deserialize<List<SegmentPriceDto>>(r.SegmentPrices),
                    Distance = r.Distance,
                    Duration = r.Duration
                }).ToList();

                return Ok(ApiResponseDto<List<DriverRideDto>>.SuccessResponse(activeRides));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving active rides");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while retrieving rides"));
            }
        }

        /// <summary>
        /// Get specific ride details with passenger information
        /// </summary>
        [HttpGet("{rideId}")]
        public async Task<IActionResult> GetRideDetails(Guid rideId)
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                var driver = await _driverRepository.GetDriverByUserIdAsync(userGuid);
                if (driver == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Driver profile not found"));
                }

                var ride = await _rideRepository.GetRideByIdAsync(rideId);
                if (ride == null || ride.DriverId != driver.Id)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Ride not found"));
                }

                _logger.LogInformation("Ride {RideId} has {BookingCount} bookings", rideId, ride.Bookings?.Count ?? 0);
                if (ride.Bookings != null)
                {
                    foreach (var booking in ride.Bookings)
                    {
                        _logger.LogInformation("Booking {BookingId}: Passenger={PassengerId}, PassengerLoaded={PassengerLoaded}, ProfileLoaded={ProfileLoaded}, ProfileName={ProfileName}",
                            booking.Id, booking.PassengerId, booking.Passenger != null, booking.Passenger?.Profile != null, booking.Passenger?.Profile?.Name ?? "NULL");
                    }
                }

                // Parse intermediate stops from JSON
                List<string>? intermediateStops = null;
                if (!string.IsNullOrEmpty(ride.IntermediateStops))
                {
                    try
                    {
                        intermediateStops = System.Text.Json.JsonSerializer.Deserialize<List<string>>(ride.IntermediateStops);
                    }
                    catch
                    {
                        _logger.LogWarning("Failed to parse IntermediateStops for ride {RideId}", rideId);
                    }
                }

                // Parse intermediate stop IDs from JSON
                List<Guid>? intermediateStopIds = null;
                if (!string.IsNullOrEmpty(ride.IntermediateStopIds))
                {
                    try
                    {
                        intermediateStopIds = System.Text.Json.JsonSerializer.Deserialize<List<Guid>>(ride.IntermediateStopIds);
                    }
                    catch
                    {
                        _logger.LogWarning("Failed to parse IntermediateStopIds for ride {RideId}", rideId);
                    }
                }

                // Build a stop-name → city-ID lookup for deriving passenger location IDs
                static string NormalizeStopName(string name) => name.Split(',')[0].Trim().ToLowerInvariant();

                var stopNameToId = new Dictionary<string, Guid?>(StringComparer.OrdinalIgnoreCase);
                stopNameToId[NormalizeStopName(ride.PickupLocation)] = ride.PickupCityId;
                stopNameToId[NormalizeStopName(ride.DropoffLocation)] = ride.DropoffCityId;
                if (intermediateStops != null && intermediateStopIds != null)
                {
                    for (int i = 0; i < intermediateStops.Count && i < intermediateStopIds.Count; i++)
                        stopNameToId[NormalizeStopName(intermediateStops[i])] = intermediateStopIds[i];
                }

                var passengers = ride.Bookings?.Where(b => b.Status != "cancelled").Select(b =>
                {
                    stopNameToId.TryGetValue(NormalizeStopName(b.PickupLocation), out var pickupId);
                    stopNameToId.TryGetValue(NormalizeStopName(b.DropoffLocation), out var dropoffId);
                    return new PassengerInfoDto
                    {
                        BookingId = b.Id,
                        PassengerId = b.PassengerId,
                        Name = b.Passenger?.Profile?.Name ?? b.Passenger?.PhoneNumber ?? "Unknown",
                        PhoneNumber = b.Passenger?.PhoneNumber ?? "",
                        PickupLocation = b.PickupLocation,
                        DropoffLocation = b.DropoffLocation,
                        PickupLocationId = pickupId,
                        DropoffLocationId = dropoffId,
                        PickupLatitude = b.PickupLatitude,
                        PickupLongitude = b.PickupLongitude,
                        DropoffLatitude = b.DropoffLatitude,
                        DropoffLongitude = b.DropoffLongitude,
                        PassengerCount = b.PassengerCount,
                        Otp = b.OTP,
                        IsVerified = b.IsVerified,
                        TotalFare = b.TotalFare,
                        TotalAmount = b.TotalAmount,
                        PaymentStatus = b.PaymentStatus ?? "pending",
                        BoardingStatus = b.IsVerified ? "boarded" : "pending"
                    };
                }).ToList();

                // Calculate segment distances using coordinate-based method
                List<decimal>? segmentDistances = null;
                if (intermediateStops != null && intermediateStops.Any())
                {
                    try
                    {
                        // Build stops with coordinates: look up each city by ID, fallback to name-based
                        var stopsWithCoords = new List<(string name, double lat, double lng)>
                        {
                            (ride.PickupLocation, (double)ride.PickupLatitude, (double)ride.PickupLongitude)
                        };
                        for (int i = 0; i < intermediateStops.Count; i++)
                        {
                            double lat = 0, lng = 0;
                            if (intermediateStopIds != null && i < intermediateStopIds.Count)
                            {
                                var city = await _context.Cities.FindAsync(intermediateStopIds[i]);
                                if (city != null)
                                {
                                    lat = (double)(city.Latitude ?? 0);
                                    lng = (double)(city.Longitude ?? 0);
                                }
                            }
                            stopsWithCoords.Add((intermediateStops[i], lat, lng));
                        }
                        stopsWithCoords.Add((ride.DropoffLocation, (double)ride.DropoffLatitude, (double)ride.DropoffLongitude));

                        var routeResult = await _routeDistanceService.CalculateMultiLegRouteByCoordinatesAsync(stopsWithCoords);
                        if (routeResult != null)
                        {
                            segmentDistances = routeResult.Value.segments.Select(s => (decimal)s.DistanceKm).ToList();
                            _logger.LogInformation("📊 Calculated {Count} segment distances for ride {RideNumber}",
                                segmentDistances.Count, ride.RideNumber);
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "Failed to calculate segment distances for ride {RideId}", rideId);
                    }
                }

                var rideDetails = new DriverRideDetailsDto
                {
                    RideId = ride.Id,
                    RideNumber = ride.RideNumber,
                    PickupLocation = ride.PickupLocation,
                    DropoffLocation = ride.DropoffLocation,
                    PickupLatitude = ride.PickupLatitude,
                    PickupLongitude = ride.PickupLongitude,
                    DropoffLatitude = ride.DropoffLatitude,
                    DropoffLongitude = ride.DropoffLongitude,
                    PickupLocationId = ride.PickupCityId,
                    DropoffLocationId = ride.DropoffCityId,
                    IntermediateStops = intermediateStops,
                    IntermediateStopsIds = intermediateStopIds?.Select(id => id.ToString()).ToList(),
                    DepartureTime = ride.DepartureTime.ToString(@"hh\:mm"),
                    TotalSeats = ride.TotalSeats,
                    BookedSeats = ride.BookedSeats,
                    AvailableSeats = ride.TotalSeats - ride.BookedSeats,
                    PricePerSeat = ride.PricePerSeat,
                    VehicleType = ride.Vehicle?.VehicleType ?? "",
                    Status = ride.Status,
                    Distance = ride.Distance,
                    Duration = ride.Duration,
                    SegmentDistances = segmentDistances,
                    Passengers = passengers ?? new List<PassengerInfoDto>()
                };

                return Ok(ApiResponseDto<DriverRideDetailsDto>.SuccessResponse(rideDetails));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving ride details");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while retrieving ride details"));
            }
        }

        /// <summary>
        /// Start a trip (when driver begins the ride)
        /// </summary>
        [HttpPost("{rideId}/start")]
        public async Task<IActionResult> StartTrip(Guid rideId, [FromBody] StartTripRequestDto? request)
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                var driver = await _driverRepository.GetDriverByUserIdAsync(userGuid);
                if (driver == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Driver profile not found"));
                }

                var success = await _driverRepository.StartTripAsync(rideId, DateTime.UtcNow);
                if (!success)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Failed to start trip"));
                }

                var ride = await _rideRepository.GetRideByIdAsync(rideId);
                var scheduledTime = DateTime.Today.Add(ride?.DepartureTime ?? TimeSpan.Zero);
                var delayMinutes = (int)(DateTime.UtcNow - scheduledTime).TotalMinutes;

                var response = new StartTripResponseDto
                {
                    RideId = rideId,
                    Status = "active",
                    StartedAt = DateTime.UtcNow,
                    DelayMinutes = delayMinutes > 0 ? delayMinutes : 0,
                    TrackingId = Guid.NewGuid()
                };

                return Ok(ApiResponseDto<StartTripResponseDto>.SuccessResponse(response, "Trip started successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error starting trip");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while starting trip"));
            }
        }

        /// <summary>
        /// Verify passenger OTP at pickup
        /// </summary>
        [HttpPost("{rideId}/verify-otp")]
        [ValidateModel]
        public async Task<IActionResult> VerifyOtp(Guid rideId, [FromBody] VerifyOtpDto request)
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                var driver = await _driverRepository.GetDriverByUserIdAsync(userGuid);
                if (driver == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Driver profile not found"));
                }

                var booking = await _driverRepository.VerifyPassengerOTPAsync(rideId, request.Otp);
                if (booking == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Invalid OTP or booking"));
                }

                // Send SignalR OTP verification event to passenger
                try
                {
                    var passenger = await _context.Users.FindAsync(booking.PassengerId);
                    var passengerProfile = await _context.UserProfiles
                        .FirstOrDefaultAsync(p => p.UserId == booking.PassengerId);
                    var passengerName = passengerProfile?.Name ?? passenger?.PhoneNumber ?? "Passenger";
                    
                    var otpVerifiedEvent = new
                    {
                        rideId = rideId.ToString(),
                        bookingId = booking.Id.ToString(),
                        bookingNumber = booking.BookingNumber,
                        passengerName = passengerName,
                        timestamp = DateTime.UtcNow.ToString("o"),
                        isVerified = true
                    };

                    // Send to specific ride room
                    var rideGroupName = $"ride_{rideId}";
                    await _hubContext.Clients.Group(rideGroupName).SendAsync("OtpVerified", otpVerifiedEvent);
                    _logger.LogInformation($"🎉 SignalR OTP verification event sent for booking {booking.BookingNumber}");
                }
                catch (Exception signalREx)
                {
                    _logger.LogError(signalREx, "❌ Failed to send SignalR OTP verification event");
                    // Don't fail the verification if SignalR fails
                }

                // Send ride started notification to passenger
                try
                {
                    var passenger = await _context.Users.FindAsync(booking.PassengerId);
                    if (passenger != null && !string.IsNullOrEmpty(passenger.FCMToken))
                    {
                        _logger.LogInformation($"📱 Sending ride started notification to passenger");
                        await _fcmService.SendRideStartedAsync(
                            passenger.FCMToken,
                            booking.RideId,
                            booking.BookingNumber
                        );
                    }
                }
                catch (Exception notifEx)
                {
                    _logger.LogError(notifEx, "❌ Failed to send ride started notification");
                    // Don't fail the verification if notification fails
                }

                return Ok(ApiResponseDto<string>.SuccessResponse("success", "Passenger verified successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error verifying OTP");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while verifying OTP"));
            }
        }

        /// <summary>
        /// Complete a trip and update earnings
        /// </summary>
        [HttpPost("{rideId}/complete")]
        [ValidateModel]
        public async Task<IActionResult> CompleteTrip(Guid rideId, [FromBody] CompleteTripRequestDto request)
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                var driver = await _driverRepository.GetDriverByUserIdAsync(userGuid);
                if (driver == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Driver profile not found"));
                }

                var success = await _driverRepository.CompleteTripAsync(rideId, DateTime.UtcNow, 0);
                if (!success)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Failed to complete trip"));
                }

                // Send ride completed notification to all passengers
                try
                {
                    var bookings = await _context.Bookings
                        .Where(b => b.RideId == rideId && b.Status != "cancelled")
                        .ToListAsync();
                    
                    foreach (var booking in bookings)
                    {
                        var passenger = await _context.Users.FindAsync(booking.PassengerId);
                        if (passenger != null && !string.IsNullOrEmpty(passenger.FCMToken))
                        {
                            _logger.LogInformation($"📱 Sending ride completed notification to passenger {booking.PassengerId}");
                            await _fcmService.SendRideCompletedAsync(
                                passenger.FCMToken,
                                booking.BookingNumber,
                                booking.TotalAmount
                            );
                        }
                    }
                }
                catch (Exception notifEx)
                {
                    _logger.LogError(notifEx, "❌ Failed to send ride completed notifications");
                    // Don't fail the completion if notifications fail
                }

                return Ok(ApiResponseDto<string>.SuccessResponse("success", "Trip completed successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error completing trip");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while completing trip"));
            }
        }

        /// <summary>
        /// Cancel a scheduled ride
        /// </summary>
        [HttpPost("{rideId}/cancel")]
        [ValidateModel]
        public async Task<IActionResult> CancelRide(Guid rideId, [FromBody] CancelRideRequestDto request)
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                var driver = await _driverRepository.GetDriverByUserIdAsync(userGuid);
                if (driver == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Driver profile not found"));
                }

                var ride = await _rideRepository.GetRideByIdAsync(rideId);
                if (ride == null || ride.DriverId != driver.Id)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Ride not found"));
                }

                // Update ride status and save changes
                var success = await _driverRepository.CancelRideAsync(rideId, request.Reason ?? "No reason provided");
                if (!success)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Failed to cancel ride"));
                }

                var response = new DriverCancelRideResponseDto
                {
                    RideId = rideId,
                    Status = "cancelled",
                    CancelledAt = DateTime.UtcNow
                };

                return Ok(ApiResponseDto<DriverCancelRideResponseDto>.SuccessResponse(response, "Ride cancelled successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error cancelling ride");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while cancelling ride"));
            }
        }

        /// <summary>
        /// Update price per seat for a scheduled ride
        /// </summary>
        [HttpPut("{rideId}/price")]
        public async Task<IActionResult> UpdateRidePrice(Guid rideId, [FromBody] UpdateRidePriceDto request)
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                var driver = await _driverRepository.GetDriverByUserIdAsync(userGuid);
                if (driver == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Driver profile not found"));
                }

                var ride = await _rideRepository.GetRideByIdAsync(rideId);
                if (ride == null || ride.DriverId != driver.Id)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Ride not found"));
                }

                // Validate ride status - can only update price for scheduled rides
                if (ride.Status != "scheduled")
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Can only update price for scheduled rides"));
                }
                // Validate no passengers have booked
                if (ride.BookedSeats > 0)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Cannot update price after passengers have booked"));
                }

                // Validate not within 15 minutes of departure
                var departureDateTime = ride.TravelDate.Date.Add(ride.DepartureTime);
                var minutesUntilDeparture = (departureDateTime - DateTime.Now).TotalMinutes;
                if (minutesUntilDeparture < 15)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Cannot update price within 15 minutes of departure"));
                }
                // Validate price
                if (request.PricePerSeat <= 0)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Price must be greater than 0"));
                }

                // Update price
                ride.PricePerSeat = request.PricePerSeat;
                ride.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                _logger.LogInformation($"Updated price for ride {rideId} to ₹{request.PricePerSeat}");

                var response = new UpdateRidePriceResponseDto
                {
                    RideId = rideId,
                    PricePerSeat = ride.PricePerSeat,
                    UpdatedAt = ride.UpdatedAt
                };

                return Ok(ApiResponseDto<UpdateRidePriceResponseDto>.SuccessResponse(response, "Price updated successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating ride price");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while updating price"));
            }
        }

        /// <summary>
        /// Update segment prices for a scheduled ride
        /// </summary>
        [HttpPut("{rideId}/segment-prices")]
        public async Task<IActionResult> UpdateSegmentPrices(Guid rideId, [FromBody] UpdateSegmentPricesDto request)
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                var driver = await _driverRepository.GetDriverByUserIdAsync(userGuid);
                if (driver == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Driver profile not found"));
                }

                var ride = await _rideRepository.GetRideByIdAsync(rideId);
                if (ride == null || ride.DriverId != driver.Id)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Ride not found"));
                }

                // Validate ride status - can only update prices for scheduled rides
                if (ride.Status != "scheduled")
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Can only update prices for scheduled rides"));
                }

                // Validate no passengers have booked
                if (ride.BookedSeats > 0)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Cannot update segment prices after passengers have booked"));
                }

                // Validate not within 15 minutes of departure
                var departureDateTime = ride.TravelDate.Date.Add(ride.DepartureTime);
                var minutesUntilDeparture = (departureDateTime - DateTime.Now).TotalMinutes;
                if (minutesUntilDeparture < 15)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Cannot update segment prices within 15 minutes of departure"));
                }

                // Validate that ride has intermediate stops
                if (string.IsNullOrEmpty(ride.IntermediateStops))
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Ride has no intermediate stops"));
                }

                var intermediateStops = System.Text.Json.JsonSerializer.Deserialize<List<string>>(ride.IntermediateStops);
                if (intermediateStops == null || !intermediateStops.Any())
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Invalid intermediate stops data"));
                }

                // Validate segment count
                var expectedSegments = intermediateStops.Count + 1;
                if (request.SegmentPrices == null || request.SegmentPrices.Count != expectedSegments)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse(
                        $"Expected {expectedSegments} segment prices, got {request.SegmentPrices?.Count ?? 0}"));
                }

                // Validate all prices are positive
                if (request.SegmentPrices.Any(s => s.Price <= 0))
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("All prices must be greater than 0"));
                }

                // Serialize and update segment prices
                var segmentPricesJson = System.Text.Json.JsonSerializer.Serialize(request.SegmentPrices);
                ride.SegmentPrices = segmentPricesJson;
                ride.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                _logger.LogInformation($"Updated segment prices for ride {rideId}");

                var response = new UpdateSegmentPricesResponseDto
                {
                    RideId = rideId,
                    SegmentPrices = request.SegmentPrices,
                    UpdatedAt = ride.UpdatedAt
                };

                return Ok(ApiResponseDto<UpdateSegmentPricesResponseDto>.SuccessResponse(response, "Segment prices updated successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating segment prices");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while updating segment prices"));
            }
        }

        /// <summary>
        /// Update schedule (date and time) for a ride
        /// </summary>
        [HttpPut("{rideId}/schedule")]
        public async Task<IActionResult> UpdateRideSchedule(Guid rideId, [FromBody] UpdateRideScheduleDto request)
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                var driver = await _driverRepository.GetDriverByUserIdAsync(userGuid);
                if (driver == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Driver profile not found"));
                }

                var ride = await _rideRepository.GetRideByIdAsync(rideId);
                if (ride == null || ride.DriverId != driver.Id)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Ride not found"));
                }

                // Validate ride status - can only reschedule scheduled rides
                if (ride.Status != "scheduled")
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Can only reschedule scheduled rides"));
                }

                // Validate no passengers have booked
                if (ride.BookedSeats > 0)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Cannot reschedule after passengers have booked"));
                }

                // Validate not within 15 minutes of departure
                var currentDepartureDateTime = ride.TravelDate.Date.Add(ride.DepartureTime);
                var minutesUntilDeparture = (currentDepartureDateTime - DateTime.Now).TotalMinutes;
                if (minutesUntilDeparture < 15)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Cannot reschedule within 15 minutes of departure"));
                }

                // Parse and validate new schedule
                if (!DateOnly.TryParseExact(request.Date, "dd-MM-yyyy", out var newDate))
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Invalid date format. Use dd-MM-yyyy"));
                }

                if (!TimeSpan.TryParse(request.DepartureTime, out var newDepartureTime))
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Invalid time format"));
                }

                // Convert DateOnly to DateTime for comparison and storage
                var newTravelDate = newDate.ToDateTime(TimeOnly.FromTimeSpan(newDepartureTime));

                // Validate the new schedule is in the future
                if (newTravelDate <= DateTime.Now)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Departure time must be in the future"));
                }

                // Check for time conflicts with other driver's rides (excluding current ride)
                var activeRides = await _context.Rides
                    .Where(r => r.DriverId == driver.Id
                        && r.Id != rideId
                        && (r.Status == "scheduled" || r.Status == "in_progress"))
                    .ToListAsync();

                foreach (var existingRide in activeRides)
                {
                    var existingDateTime = existingRide.TravelDate.Date.Add(existingRide.DepartureTime);
                    var timeDifference = Math.Abs((newTravelDate - existingDateTime).TotalMinutes);

                    if (timeDifference < 30) // 30-minute buffer
                    {
                        return BadRequest(ApiResponseDto<object>.ErrorResponse(
                            $"Time conflict with ride {existingRide.RideNumber}. Maintain at least 30 minutes gap."));
                    }
                }

                // Update schedule
                ride.TravelDate = newTravelDate.Date; // Store date part
                ride.DepartureTime = newDepartureTime;
                ride.UpdatedAt = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                _logger.LogInformation($"Updated schedule for ride {rideId} to {request.Date} at {request.DepartureTime}");

                var response = new UpdateRideScheduleResponseDto
                {
                    RideId = rideId,
                    Date = ride.TravelDate.ToString("dd-MM-yyyy"),
                    DepartureTime = ride.DepartureTime.ToString(@"hh\:mm"),
                    UpdatedAt = ride.UpdatedAt
                };

                return Ok(ApiResponseDto<UpdateRideScheduleResponseDto>.SuccessResponse(response, "Schedule updated successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating ride schedule");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while updating schedule"));
            }
        }
    }
}
