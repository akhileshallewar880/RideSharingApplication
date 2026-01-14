using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RideSharing.API.CustomValidations;
using RideSharing.API.Data;
using RideSharing.API.Models.Domain;
using RideSharing.API.Models.DTO;
using RideSharing.API.Repositories.Interface;
using RideSharing.API.Services.Implementation;
using RideSharing.API.Services.Interface;
using System.Security.Claims;
using System.Text.Json;

namespace RideSharing.API.Controllers
{
    [Route("api/v1/admin/rides")]
    [ApiController]
    [Authorize(Roles = "admin,super_admin")]
    public class AdminRidesController : ControllerBase
    {
        private readonly IDriverRepository _driverRepository;
        private readonly IRideRepository _rideRepository;
        private readonly RouteDistanceService _routeDistanceService;
        private readonly IGoogleMapsService _googleMapsService;
        private readonly ILogger<AdminRidesController> _logger;
        private readonly RideSharingDbContext _context;

        public AdminRidesController(
            IDriverRepository driverRepository,
            IRideRepository rideRepository,
            RouteDistanceService routeDistanceService,
            IGoogleMapsService googleMapsService,
            ILogger<AdminRidesController> logger,
            RideSharingDbContext context)
        {
            _driverRepository = driverRepository;
            _rideRepository = rideRepository;
            _routeDistanceService = routeDistanceService;
            _googleMapsService = googleMapsService;
            _logger = logger;
            _context = context;
        }

        /// <summary>
        /// Admin: Schedule a new ride for a driver
        /// </summary>
        [HttpPost("schedule")]
        [ValidateModel]
        public async Task<IActionResult> AdminScheduleRide([FromBody] AdminScheduleRideRequestDto request)
        {
            try
            {
                // Verify admin role
                var userRole = User.FindFirst(ClaimTypes.Role)?.Value?.ToLower();
                if (userRole != "admin" && userRole != "super_admin")
                {
                    return Forbid();
                }

                // Get driver with user profile
                var driver = await _context.Drivers
                    .Include(d => d.User)
                    .ThenInclude(u => u.Profile)
                    .FirstOrDefaultAsync(d => d.Id == request.DriverId && d.IsVerified);

                if (driver == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Driver not found or not verified"));
                }

                // Get driver's vehicle with model
                var vehicle = await _context.Vehicles
                    .Include(v => v.VehicleModel)
                    .FirstOrDefaultAsync(v => v.DriverId == driver.Id);

                if (vehicle == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Driver does not have a registered vehicle"));
                }

                // Parse departure time
                if (!TimeSpan.TryParse(request.DepartureTime, out var departureTime))
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Invalid departure time format. Use HH:mm format"));
                }

                // Prepare intermediate stops and segment prices JSON
                string? intermediateStopsJson = null;
                string? segmentPricesJson = null;
                decimal totalDistance = 0;
                int totalDuration = 0;

                if (request.IntermediateStops != null && request.IntermediateStops.Any())
                {
                    intermediateStopsJson = System.Text.Json.JsonSerializer.Serialize(request.IntermediateStops);
                }

                if (request.SegmentPrices != null && request.SegmentPrices.Any())
                {
                    segmentPricesJson = System.Text.Json.JsonSerializer.Serialize(request.SegmentPrices);
                }

                // Calculate route using Google Maps API for accurate multi-stop distance
                try
                {
                    _logger.LogInformation("🗺️  Calculating route with Google Maps: {Pickup} → {Dropoff}", 
                        request.PickupLocation.Address, request.DropoffLocation.Address);
                    
                    // Debug: Log incoming request data
                    _logger.LogInformation("📥 IntermediateStopLocations count: {Count}", 
                        request.IntermediateStopLocations?.Count ?? 0);
                    _logger.LogInformation("📥 IntermediateStops count: {Count}", 
                        request.IntermediateStops?.Count ?? 0);
                    
                    if (request.IntermediateStopLocations != null && request.IntermediateStopLocations.Any())
                    {
                        foreach (var loc in request.IntermediateStopLocations)
                        {
                            _logger.LogInformation("📍 Intermediate stop: {Address} ({Lat}, {Lng})", 
                                loc.Address, loc.Latitude, loc.Longitude);
                        }
                    }

                    // Build waypoints list from IntermediateStopLocations if available
                    List<(decimal lat, decimal lng)>? waypoints = null;
                    
                    if (request.IntermediateStopLocations != null && request.IntermediateStopLocations.Any())
                    {
                        // We have full location data with coordinates - use Google Maps API
                        waypoints = request.IntermediateStopLocations
                            .Select(loc => (lat: loc.Latitude, lng: loc.Longitude))
                            .ToList();
                        
                        _logger.LogInformation("🎯 Using {Count} intermediate stops with coordinates for Google Maps", waypoints.Count);
                    }
                    else if (request.IntermediateStops != null && request.IntermediateStops.Any())
                    {
                        // Only have addresses without coordinates - fall back to database calculation
                        _logger.LogWarning("⚠️  Intermediate stops provided without coordinates, using database calculation");
                        
                        var cities = new List<string> { request.PickupLocation.Address };
                        cities.AddRange(request.IntermediateStops);
                        cities.Add(request.DropoffLocation.Address);
                        
                        var dbRouteResult = _routeDistanceService.CalculateMultiLegRoute(cities);
                        if (dbRouteResult != null)
                        {
                            totalDistance = (decimal)dbRouteResult.Value.totalDistanceKm;
                            totalDuration = dbRouteResult.Value.totalDurationMinutes;
                            _logger.LogInformation("✅ Route calculated from database: {Distance}km, {Duration}min",
                                totalDistance, totalDuration);
                        }
                    }
                    
                    // If we have waypoints or no intermediate stops, use Google Maps API
                    if (waypoints != null || request.IntermediateStops == null || !request.IntermediateStops.Any())
                    {
                        var directionsResult = await _googleMapsService.GetDirectionsAsync(
                            request.PickupLocation.Latitude,
                            request.PickupLocation.Longitude,
                            request.DropoffLocation.Latitude,
                            request.DropoffLocation.Longitude,
                            waypoints
                        );

                        if (directionsResult != null)
                        {
                            totalDistance = (decimal)directionsResult.DistanceKm;
                            totalDuration = directionsResult.DurationMinutes;
                            _logger.LogInformation("✅ Route calculated with Google Maps: {Distance}km, {Duration}min",
                                totalDistance, totalDuration);
                        }
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
                    DropoffLocation = request.DropoffLocation.Address,
                    DropoffLatitude = request.DropoffLocation.Latitude,
                    DropoffLongitude = request.DropoffLocation.Longitude,
                    IntermediateStops = intermediateStopsJson,
                    SegmentPrices = segmentPricesJson,
                    TravelDate = request.TravelDate,
                    DepartureTime = departureTime,
                    TotalSeats = request.TotalSeats,
                    BookedSeats = 0,
                    PricePerSeat = request.PricePerSeat,
                    Distance = totalDistance,
                    Duration = totalDuration,
                    Status = "scheduled",
                    IsReturnTrip = false,
                    CreatedAt = DateTime.UtcNow,
                    AdminNotes = request.AdminNotes
                };

                ride = await _driverRepository.CreateRideAsync(ride);

                var driverName = driver.User?.Profile?.Name ?? "Unknown Driver";
                var driverPhone = driver.User?.PhoneNumber ?? "N/A";
                
                _logger.LogInformation("✅ Admin scheduled ride - RideId: {RideId}, RideNumber: {RideNumber}, DriverId: {DriverId}, DriverName: {DriverName}, DriverPhone: {DriverPhone}, DriverUserId: {DriverUserId}",
                    ride.Id, ride.RideNumber, driver.Id, driverName, driverPhone, driver.UserId);

                var response = new AdminScheduleRideResponseDto
                {
                    RideId = ride.Id,
                    RideNumber = ride.RideNumber,
                    DriverId = driver.Id,
                    DriverName = driverName,
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
                    AdminNotes = ride.AdminNotes
                };

                // Handle return trip if requested
                if (request.ScheduleReturnTrip && !string.IsNullOrEmpty(request.ReturnDepartureTime))
                {
                    if (!DateTime.TryParse(request.ReturnDepartureTime, out var returnDepartureDateTime))
                    {
                        return BadRequest(ApiResponseDto<object>.ErrorResponse("Invalid return departure time format"));
                    }

                    var outboundDateTime = request.TravelDate.Date + departureTime;
                    if (returnDepartureDateTime <= outboundDateTime)
                    {
                        return BadRequest(ApiResponseDto<object>.ErrorResponse("Return trip must be scheduled after outbound trip"));
                    }

                    var returnRide = new Ride
                    {
                        Id = Guid.NewGuid(),
                        RideNumber = $"RIDE{DateTime.UtcNow:yyyyMMddHHmmss}R",
                        DriverId = driver.Id,
                        VehicleId = vehicle.Id,
                        VehicleModelId = request.VehicleModelId ?? vehicle.VehicleModelId,
                        PickupLocation = request.DropoffLocation.Address,
                        PickupLatitude = request.DropoffLocation.Latitude,
                        PickupLongitude = request.DropoffLocation.Longitude,
                        DropoffLocation = request.PickupLocation.Address,
                        DropoffLatitude = request.PickupLocation.Latitude,
                        DropoffLongitude = request.PickupLocation.Longitude,
                        IntermediateStops = intermediateStopsJson != null && request.IntermediateStops != null
                            ? System.Text.Json.JsonSerializer.Serialize(Enumerable.Reverse(request.IntermediateStops).ToList())
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
                        Status = "scheduled",
                        IsReturnTrip = true,
                        LinkedReturnRideId = ride.Id,
                        CreatedAt = DateTime.UtcNow,
                        AdminNotes = request.AdminNotes
                    };

                    returnRide = await _driverRepository.CreateRideAsync(returnRide);

                    ride.LinkedReturnRideId = returnRide.Id;
                    await _driverRepository.UpdateRideAsync(ride);

                    response.ReturnRideId = returnRide.Id;
                    response.ReturnRideNumber = returnRide.RideNumber;
                }

                _logger.LogInformation("✅ Admin scheduled ride {RideNumber} for driver {DriverName}",
                    ride.RideNumber, driverName);

                return Ok(ApiResponseDto<AdminScheduleRideResponseDto>.SuccessResponse(response, "Ride scheduled successfully by admin"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in admin schedule ride");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while scheduling ride"));
            }
        }

        /// <summary>
        /// Admin: Update/Reschedule an existing ride
        /// </summary>
        [HttpPut("{rideId}")]
        [ValidateModel]
        public async Task<IActionResult> AdminUpdateRide(Guid rideId, [FromBody] AdminUpdateRideRequestDto request)
        {
            try
            {
                // Verify admin role
                var userRole = User.FindFirst(ClaimTypes.Role)?.Value?.ToLower();
                if (userRole != "admin" && userRole != "super_admin")
                {
                    return Forbid();
                }

                var ride = await _context.Rides
                    .Include(r => r.Driver)
                    .ThenInclude(d => d.User)
                    .ThenInclude(u => u.Profile)
                    .FirstOrDefaultAsync(r => r.Id == rideId);

                if (ride == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Ride not found"));
                }

                // Check if ride can be updated
                if (ride.Status.ToLower() == "completed" || ride.Status.ToLower() == "cancelled")
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Cannot update completed or cancelled rides"));
                }

                // Update fields if provided
                if (request.TravelDate.HasValue)
                {
                    ride.TravelDate = request.TravelDate.Value;
                }

                if (!string.IsNullOrEmpty(request.DepartureTime))
                {
                    if (TimeSpan.TryParse(request.DepartureTime, out var departureTime))
                    {
                        ride.DepartureTime = departureTime;
                    }
                }

                if (request.TotalSeats.HasValue)
                {
                    // Validate that new seat count is not less than booked seats
                    if (request.TotalSeats.Value < ride.BookedSeats)
                    {
                        return BadRequest(ApiResponseDto<object>.ErrorResponse(
                            $"Cannot reduce seats below booked count ({ride.BookedSeats})"));
                    }
                    ride.TotalSeats = request.TotalSeats.Value;
                }

                if (request.PricePerSeat.HasValue)
                {
                    ride.PricePerSeat = request.PricePerSeat.Value;
                }

                if (!string.IsNullOrEmpty(request.AdminNotes))
                {
                    ride.AdminNotes = request.AdminNotes;
                }

                if (request.PickupLocation != null)
                {
                    ride.PickupLocation = request.PickupLocation.Address;
                    ride.PickupLatitude = request.PickupLocation.Latitude;
                    ride.PickupLongitude = request.PickupLocation.Longitude;
                }

                if (request.DropoffLocation != null)
                {
                    ride.DropoffLocation = request.DropoffLocation.Address;
                    ride.DropoffLatitude = request.DropoffLocation.Latitude;
                    ride.DropoffLongitude = request.DropoffLocation.Longitude;
                }

                // Update intermediate stops if provided
                if (request.IntermediateStops != null)
                {
                    ride.IntermediateStops = request.IntermediateStops.Any()
                        ? System.Text.Json.JsonSerializer.Serialize(request.IntermediateStops)
                        : null;
                }

                // Update segment prices if provided
                if (request.SegmentPrices != null)
                {
                    ride.SegmentPrices = request.SegmentPrices.Any()
                        ? System.Text.Json.JsonSerializer.Serialize(request.SegmentPrices)
                        : null;
                }

                ride.UpdatedAt = DateTime.UtcNow;

                await _driverRepository.UpdateRideAsync(ride);

                var driverName = ride.Driver?.User?.Profile?.Name ?? "Unknown Driver";

                var response = new AdminScheduleRideResponseDto
                {
                    RideId = ride.Id,
                    RideNumber = ride.RideNumber,
                    DriverId = ride.DriverId,
                    DriverName = driverName,
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
                    AdminNotes = ride.AdminNotes
                };

                _logger.LogInformation("✅ Admin updated ride {RideNumber}", ride.RideNumber);

                return Ok(ApiResponseDto<AdminScheduleRideResponseDto>.SuccessResponse(response, "Ride updated successfully by admin"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in admin update ride");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while updating ride"));
            }
        }

        /// <summary>
        /// Admin: Cancel a ride
        /// </summary>
        [HttpPost("{rideId}/cancel")]
        [ValidateModel]
        public async Task<IActionResult> AdminCancelRide(Guid rideId, [FromBody] AdminCancelRideRequestDto request)
        {
            try
            {
                // Verify admin role
                var userRole = User.FindFirst(ClaimTypes.Role)?.Value?.ToLower();
                if (userRole != "admin" && userRole != "super_admin")
                {
                    return Forbid();
                }

                var ride = await _context.Rides.FirstOrDefaultAsync(r => r.Id == rideId);
                if (ride == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Ride not found"));
                }

                var reason = $"[ADMIN CANCELLED] {request.Reason}";
                var success = await _driverRepository.CancelRideAsync(rideId, reason);
                
                if (!success)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Failed to cancel ride"));
                }

                // If notify passengers is requested, send notifications
                if (request.NotifyPassengers)
                {
                    // TODO: Implement passenger notification logic
                    _logger.LogInformation("📧 Notifying passengers about ride {RideNumber} cancellation", ride.RideNumber);
                }

                var response = new AdminCancelRideResponseDto
                {
                    RideId = rideId,
                    RideNumber = ride.RideNumber,
                    Status = "cancelled",
                    CancelledAt = DateTime.UtcNow,
                    Reason = reason,
                    NotificationsSent = request.NotifyPassengers
                };

                _logger.LogInformation("✅ Admin cancelled ride {RideNumber}", ride.RideNumber);

                return Ok(ApiResponseDto<AdminCancelRideResponseDto>.SuccessResponse(response, "Ride cancelled successfully by admin"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in admin cancel ride");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while cancelling ride"));
            }
        }

        /// <summary>
        /// Admin: Get all drivers for scheduling
        /// </summary>
        [HttpGet("drivers")]
        public async Task<IActionResult> GetAvailableDrivers([FromQuery] DateTime? date = null)
        {
            try
            {
                // Verify admin role
                var userRole = User.FindFirst(ClaimTypes.Role)?.Value?.ToLower();
                if (userRole != "admin" && userRole != "super_admin")
                {
                    return Forbid();
                }

                var drivers = await _context.Drivers
                    .Include(d => d.User)
                    .ThenInclude(u => u.Profile)
                    .Include(d => d.Vehicles)
                    .ThenInclude(v => v.VehicleModel)
                    .Where(d => d.IsVerified && d.User.IsActive)
                    .ToListAsync();

                var driverList = drivers.Select(d => new AdminDriverInfoDto
                {
                    DriverId = d.Id,
                    Name = d.User?.Profile?.Name ?? "Unknown",
                    Phone = d.User?.PhoneNumber ?? "",
                    LicenseNumber = d.LicenseNumber,
                    VehicleNumber = d.Vehicles.FirstOrDefault()?.RegistrationNumber,
                    VehicleModel = d.Vehicles.FirstOrDefault()?.VehicleModel?.Name,
                    VehicleSeats = d.Vehicles.FirstOrDefault()?.VehicleModel?.SeatingCapacity ?? 0,
                    IsAvailable = d.IsAvailable
                }).ToList();

                return Ok(ApiResponseDto<List<AdminDriverInfoDto>>.SuccessResponse(driverList, "Drivers retrieved successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting available drivers");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while retrieving drivers"));
            }
        }

        /// <summary>
        /// Admin: Get all rides with filters
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetAllRides(
            [FromQuery] string? status = null,
            [FromQuery] Guid? driverId = null,
            [FromQuery] DateTime? fromDate = null,
            [FromQuery] DateTime? toDate = null,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 20)
        {
            try
            {
                // Verify admin role
                var userRole = User.FindFirst(ClaimTypes.Role)?.Value?.ToLower();
                if (userRole != "admin" && userRole != "super_admin")
                {
                    return Forbid();
                }

                var query = _context.Rides
                    .Include(r => r.Driver)
                    .ThenInclude(d => d.User)
                    .ThenInclude(u => u.Profile)
                    .Include(r => r.Vehicle)
                    .ThenInclude(v => v!.VehicleModel)
                    .AsQueryable();

                // Apply filters
                if (!string.IsNullOrEmpty(status))
                {
                    query = query.Where(r => r.Status.ToLower() == status.ToLower());
                }

                if (driverId.HasValue)
                {
                    query = query.Where(r => r.DriverId == driverId.Value);
                }

                if (fromDate.HasValue)
                {
                    query = query.Where(r => r.TravelDate >= fromDate.Value.Date);
                }

                if (toDate.HasValue)
                {
                    query = query.Where(r => r.TravelDate <= toDate.Value.Date);
                }

                var totalCount = await query.CountAsync();
                
                var rides = await query
                    .OrderByDescending(r => r.CreatedAt)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .ToListAsync();

                var rideList = rides.Select(r => new AdminRideInfoDto
                {
                    RideId = r.Id,
                    RideNumber = r.RideNumber,
                    DriverId = r.DriverId,
                    DriverName = r.Driver?.User?.Profile?.Name ?? "Unknown",
                    PickupLocation = r.PickupLocation,
                    DropoffLocation = r.DropoffLocation,
                    TravelDate = r.TravelDate,
                    DepartureTime = r.DepartureTime.ToString(@"hh\:mm"),
                    TotalSeats = r.TotalSeats,
                    BookedSeats = r.BookedSeats,
                    AvailableSeats = r.TotalSeats - r.BookedSeats,
                    PricePerSeat = r.PricePerSeat,
                    Status = r.Status,
                    VehicleNumber = r.Vehicle?.RegistrationNumber,
                    VehicleModel = r.Vehicle?.VehicleModel?.Name,
                    CreatedAt = r.CreatedAt,
                    AdminNotes = r.AdminNotes,
                    SegmentPrices = !string.IsNullOrEmpty(r.SegmentPrices) 
                        ? JsonSerializer.Deserialize<List<SegmentPriceDto>>(r.SegmentPrices) 
                        : null,
                    IntermediateStops = !string.IsNullOrEmpty(r.IntermediateStops)
                        ? JsonSerializer.Deserialize<List<string>>(r.IntermediateStops)
                        : null,
                    Distance = r.Distance,
                    Duration = r.Duration
                }).ToList();

                var response = new
                {
                    rides = rideList,
                    totalCount,
                    page,
                    pageSize,
                    totalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
                };

                return Ok(ApiResponseDto<object>.SuccessResponse(response, "Rides retrieved successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting rides");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while retrieving rides"));
            }
        }

        /// <summary>
        /// Admin: Get ride details by ID
        /// </summary>
        [HttpGet("{rideId}")]
        public async Task<IActionResult> GetRideDetails(Guid rideId)
        {
            try
            {
                // Verify admin role
                var userRole = User.FindFirst(ClaimTypes.Role)?.Value?.ToLower();
                if (userRole != "admin" && userRole != "super_admin")
                {
                    return Forbid();
                }

                var ride = await _context.Rides
                    .Include(r => r.Driver)
                    .ThenInclude(d => d.User)
                    .ThenInclude(u => u.Profile)
                    .Include(r => r.Vehicle)
                    .ThenInclude(v => v!.VehicleModel)
                    .FirstOrDefaultAsync(r => r.Id == rideId);

                if (ride == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Ride not found"));
                }

                var rideInfo = new AdminRideInfoDto
                {
                    RideId = ride.Id,
                    RideNumber = ride.RideNumber,
                    DriverId = ride.DriverId,
                    DriverName = ride.Driver?.User?.Profile?.Name ?? "Unknown",
                    PickupLocation = ride.PickupLocation,
                    DropoffLocation = ride.DropoffLocation,
                    TravelDate = ride.TravelDate,
                    DepartureTime = ride.DepartureTime.ToString(@"hh\:mm"),
                    TotalSeats = ride.TotalSeats,
                    BookedSeats = ride.BookedSeats,
                    AvailableSeats = ride.TotalSeats - ride.BookedSeats,
                    PricePerSeat = ride.PricePerSeat,
                    Status = ride.Status,
                    VehicleNumber = ride.Vehicle?.RegistrationNumber,
                    VehicleModel = ride.Vehicle?.VehicleModel?.Name,
                    CreatedAt = ride.CreatedAt,
                    AdminNotes = ride.AdminNotes,
                    Distance = ride.Distance,
                    Duration = ride.Duration
                };

                return Ok(ApiResponseDto<AdminRideInfoDto>.SuccessResponse(rideInfo, "Ride details retrieved successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting ride details");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while retrieving ride details"));
            }
        }

        /// <summary>
        /// Calculate route distance and duration for multiple locations using Google Maps API
        /// </summary>
        [HttpPost("calculate-route")]
        public async Task<IActionResult> CalculateRoute([FromBody] CalculateRouteRequestDto request)
        {
            try
            {
                if (request?.Locations == null || request.Locations.Count < 2)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("At least 2 locations are required"));
                }

                _logger.LogInformation("🗺️  Calculating route with Google Maps for {Count} locations", request.Locations.Count);

                // First location is origin, last is destination, rest are waypoints
                var origin = request.Locations[0];
                var destination = request.Locations[^1];
                var waypoints = request.Locations.Count > 2 
                    ? request.Locations.Skip(1).Take(request.Locations.Count - 2).ToList() 
                    : null;

                if (origin.Latitude == null || origin.Longitude == null ||
                    destination.Latitude == null || destination.Longitude == null)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("All locations must have latitude and longitude"));
                }

                // Use Google Maps Directions API for multi-stop routes
                var waypointCoords = waypoints?.Where(w => w.Latitude != null && w.Longitude != null)
                    .Select(w => (lat: w.Latitude!.Value, lng: w.Longitude!.Value))
                    .ToList();

                var result = await _googleMapsService.GetDirectionsAsync(
                    origin.Latitude.Value,
                    origin.Longitude.Value,
                    destination.Latitude.Value,
                    destination.Longitude.Value,
                    waypointCoords
                );

                if (result == null)
                {
                    _logger.LogWarning("⚠️  Google Maps API returned null result");
                    return Ok(ApiResponseDto<object>.SuccessResponse(new
                    {
                        distanceKm = 0,
                        durationMinutes = 0,
                        distanceText = "Unable to calculate",
                        durationText = "Unable to calculate",
                        message = "Unable to calculate route"
                    }, "Route calculation unavailable"));
                }

                _logger.LogInformation("✅ Route calculated: {Distance}km, {Duration}min", 
                    result.DistanceKm, result.DurationMinutes);

                return Ok(ApiResponseDto<object>.SuccessResponse(new
                {
                    distanceKm = result.DistanceKm,
                    durationMinutes = result.DurationMinutes,
                    distanceText = $"{result.DistanceKm:F1} km",
                    durationText = FormatDuration(result.DurationMinutes),
                    polyline = result.Polyline
                }, "Route calculated successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calculating route with Google Maps");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while calculating route"));
            }
        }

        private string FormatDuration(int minutes)
        {
            if (minutes < 60)
                return $"{minutes} min";
            
            int hours = minutes / 60;
            int mins = minutes % 60;
            
            if (mins == 0)
                return $"{hours} hr";
            
            return $"{hours} hr {mins} min";
        }
    }
}
