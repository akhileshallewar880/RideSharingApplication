using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using RideSharing.API.CustomValidations;
using RideSharing.API.Data;
using RideSharing.API.Models.DTO;
using RideSharing.API.Repositories.Interface;
using RideSharing.API.Services.Implementation;
using RideSharing.API.Services.Interface;

namespace RideSharing.API.Controllers
{
    [Route("api/v1/rides")]
    [ApiController]
    [Authorize]
    public class RidesController : ControllerBase
    {
        private readonly IRideRepository _rideRepository;
        private readonly RideSharingDbContext _context;
        private readonly ILogger<RidesController> _logger;
        private readonly RouteDistanceService _routeDistanceService;
        private readonly IFileUploadService _fileUploadService;
        private readonly RideSharing.API.Services.Notification.FCMNotificationService _fcmService;

        public RidesController(
            IRideRepository rideRepository, 
            RideSharingDbContext context, 
            ILogger<RidesController> logger, 
            RouteDistanceService routeDistanceService,
            IFileUploadService fileUploadService,
            RideSharing.API.Services.Notification.FCMNotificationService fcmService)
        {
            _rideRepository = rideRepository;
            _context = context;
            _logger = logger;
            _routeDistanceService = routeDistanceService;
            _fileUploadService = fileUploadService;
            _fcmService = fcmService;
        }

        /// <summary>
        /// Search available rides based on criteria
        /// </summary>
        [HttpPost("search")]
        [ValidateModel]
        public async Task<IActionResult> SearchRides([FromBody] SearchRidesRequestDto request)
        {
            try
            {
                var rides = await _rideRepository.SearchAvailableRidesAsync(
                    request.PickupLocation.Address,
                    request.DropoffLocation.Address,
                    request.TravelDate,
                    request.PassengerCount,
                    request.VehicleType
                );

                var availableRides = new List<AvailableRideDto>();
                
                foreach (var ride in rides)
                {
                    // Parse intermediate stops if available
                    List<string>? intermediateStops = null;
                    if (!string.IsNullOrEmpty(ride.IntermediateStops))
                    {
                        try
                        {
                            intermediateStops = System.Text.Json.JsonSerializer.Deserialize<List<string>>(ride.IntermediateStops);
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, $"Failed to parse intermediate stops for ride {ride.Id}");
                        }
                    }
                    
                    // Count ratings for this driver (ratings given TO the driver's User ID)
                    var driverUserId = ride.Driver?.UserId ?? Guid.Empty;
                    var driverRatingCount = driverUserId != Guid.Empty 
                        ? _context.Ratings.Count(r => r.RatedTo == driverUserId)
                        : 0;
                    
                    var ratingDetails = driverUserId != Guid.Empty
                        ? string.Join(", ", _context.Ratings
                            .Where(r => r.RatedTo == driverUserId)
                            .Select(r => r.RatingValue)
                            .ToList()
                            .Select(v => $"{v}★"))
                        : "none";
                    
                    _logger.LogInformation($"🔍 Driver {ride.DriverId} ({ride.Driver?.User?.Profile?.Name}), UserId={driverUserId}: Rating={ride.Driver?.User?.Profile?.Rating}, Count={driverRatingCount}, Details: {ratingDetails}");

                    // Calculate distance and duration FOR THE PASSENGER'S SPECIFIC JOURNEY
                    double distanceKm = 0;
                    int durationMinutes = 0;
                    List<RideStopWithTimeDto>? routeStopsWithTiming = null;
                    
                    // Get departure time from TimeSpan
                    int depHour = ride.DepartureTime.Hours;
                    int depMinute = ride.DepartureTime.Minutes;
                    
                    _logger.LogInformation($"🚕 Processing ride {ride.RideNumber}");
                    _logger.LogInformation($"   Driver route: {ride.PickupLocation} → {ride.DropoffLocation}");
                    _logger.LogInformation($"   Passenger search: {request.PickupLocation.Address} → {request.DropoffLocation.Address}");
                    _logger.LogInformation($"   Departure: {depHour:D2}:{depMinute:D2}");
                    
                    // ALWAYS calculate for passenger's specific locations
                    // Step 1: Calculate passenger's journey duration
                    var passengerJourneyInfo = _routeDistanceService.GetDistanceAndDuration(
                        request.PickupLocation.Address,
                        request.DropoffLocation.Address);
                    
                    if (passengerJourneyInfo != null)
                    {
                        int passengerJourneyMinutes = passengerJourneyInfo.Value.durationMinutes;
                        distanceKm = passengerJourneyInfo.Value.distanceKm;
                        durationMinutes = passengerJourneyMinutes;
                        
                        _logger.LogInformation($"   Passenger journey: {passengerJourneyMinutes} min, {distanceKm:F1} km");
                        
                        // Step 2: Calculate when driver reaches passenger's pickup location
                        var driverToPassengerPickup = _routeDistanceService.GetDistanceAndDuration(
                            ride.PickupLocation,
                            request.PickupLocation.Address);
                        
                        int pickupDelayMinutes = driverToPassengerPickup?.durationMinutes ?? 0;
                        
                        _logger.LogInformation($"   Driver to passenger pickup: {pickupDelayMinutes} min");
                        
                        // Step 3: Calculate arrival times
                        int passengerPickupTotalMinutes = depHour * 60 + depMinute + pickupDelayMinutes;
                        int passengerPickupHour = (passengerPickupTotalMinutes / 60) % 24;
                        int passengerPickupMinute = passengerPickupTotalMinutes % 60;
                        
                        int passengerDropoffTotalMinutes = passengerPickupTotalMinutes + passengerJourneyMinutes;
                        int passengerDropoffHour = (passengerDropoffTotalMinutes / 60) % 24;
                        int passengerDropoffMinute = passengerDropoffTotalMinutes % 60;
                        
                        _logger.LogInformation($"   Passenger pickup time: {passengerPickupHour:D2}:{passengerPickupMinute:D2}");
                        _logger.LogInformation($"   Passenger dropoff time: {passengerDropoffHour:D2}:{passengerDropoffMinute:D2}");
                        
                        // Step 4: Build route stops with timing for passenger's journey
                        routeStopsWithTiming = new List<RideStopWithTimeDto>();
                        
                        // Add passenger's pickup location
                        routeStopsWithTiming.Add(new RideStopWithTimeDto
                        {
                            Location = request.PickupLocation.Address,
                            ArrivalTime = $"{passengerPickupHour:D2}:{passengerPickupMinute:D2}",
                            CumulativeDurationMinutes = 0
                        });
                        
                        // Add passenger's dropoff location
                        routeStopsWithTiming.Add(new RideStopWithTimeDto
                        {
                            Location = request.DropoffLocation.Address,
                            ArrivalTime = $"{passengerDropoffHour:D2}:{passengerDropoffMinute:D2}",
                            CumulativeDurationMinutes = passengerJourneyMinutes
                        });
                        
                        _logger.LogInformation($"✅ Route stops created: 2 stops for passenger's journey");
                    }
                    
                    // Legacy code - only used if passenger journey calculation fails
                    if (routeStopsWithTiming == null && intermediateStops != null && intermediateStops.Count > 0)
                    {
                        // Multi-leg route with intermediate stops
                        var cities = new List<string> { ride.PickupLocation };
                        cities.AddRange(intermediateStops);
                        cities.Add(ride.DropoffLocation);
                        
                        var routeInfo = _routeDistanceService.CalculateMultiLegRoute(cities);
                        if (routeInfo != null)
                        {
                            distanceKm = routeInfo.Value.totalDistanceKm;
                            durationMinutes = routeInfo.Value.totalDurationMinutes;
                            
                            // Build route stops with timing information
                            routeStopsWithTiming = new List<RideStopWithTimeDto>();
                            int cumulativeMinutes = 0;
                            
                            // Add pickup location
                            routeStopsWithTiming.Add(new RideStopWithTimeDto
                            {
                                Location = ride.PickupLocation,
                                ArrivalTime = $"{depHour:D2}:{depMinute:D2}",
                                CumulativeDurationMinutes = 0
                            });
                            
                            // Add intermediate stops with calculated arrival times
                            for (int i = 0; i < routeInfo.Value.segments.Count; i++)
                            {
                                var segment = routeInfo.Value.segments[i];
                                cumulativeMinutes += segment.DurationMinutes;
                                
                                // Calculate arrival time at this stop
                                int totalMinutes = depHour * 60 + depMinute + cumulativeMinutes;
                                int arrHour = (totalMinutes / 60) % 24;
                                int arrMinute = totalMinutes % 60;
                                string arrivalTime = $"{arrHour:D2}:{arrMinute:D2}";
                                
                                routeStopsWithTiming.Add(new RideStopWithTimeDto
                                {
                                    Location = segment.ToLocation,
                                    ArrivalTime = arrivalTime,
                                    CumulativeDurationMinutes = cumulativeMinutes
                                });
                            }
                            
                            // Add passenger-specific pickup and dropoff times if they differ from driver's route
                            // This helps passengers see their exact pickup/dropoff times
                            if (!ride.PickupLocation.Equals(request.PickupLocation.Address, StringComparison.OrdinalIgnoreCase))
                            {
                                // Calculate passenger pickup time from driver pickup
                                var pickupSegment = _routeDistanceService.GetDistanceAndDuration(ride.PickupLocation, request.PickupLocation.Address);
                                if (pickupSegment != null)
                                {
                                    int pickupMinutes = pickupSegment.Value.durationMinutes;
                                    int pickupTotalMinutes = depHour * 60 + depMinute + pickupMinutes;
                                    int pickupArrHour = (pickupTotalMinutes / 60) % 24;
                                    int pickupArrMinute = pickupTotalMinutes % 60;
                                    
                                    routeStopsWithTiming.Add(new RideStopWithTimeDto
                                    {
                                        Location = request.PickupLocation.Address,
                                        ArrivalTime = $"{pickupArrHour:D2}:{pickupArrMinute:D2}",
                                        CumulativeDurationMinutes = pickupMinutes
                                    });
                                }
                            }
                            
                            if (!ride.DropoffLocation.Equals(request.DropoffLocation.Address, StringComparison.OrdinalIgnoreCase))
                            {
                                // Calculate passenger dropoff time from driver pickup
                                var dropoffSegment = _routeDistanceService.GetDistanceAndDuration(ride.PickupLocation, request.DropoffLocation.Address);
                                if (dropoffSegment != null)
                                {
                                    int dropoffMinutes = dropoffSegment.Value.durationMinutes;
                                    int dropoffTotalMinutes = depHour * 60 + depMinute + dropoffMinutes;
                                    int dropoffArrHour = (dropoffTotalMinutes / 60) % 24;
                                    int dropoffArrMinute = dropoffTotalMinutes % 60;
                                    
                                    routeStopsWithTiming.Add(new RideStopWithTimeDto
                                    {
                                        Location = request.DropoffLocation.Address,
                                        ArrivalTime = $"{dropoffArrHour:D2}:{dropoffArrMinute:D2}",
                                        CumulativeDurationMinutes = dropoffMinutes
                                    });
                                }
                            }
                        }
                    }
                    else
                    {
                        // Direct route - calculate times for passenger's specific locations
                        // First, check if passenger locations match driver's route
                        bool passengerMatchesDriver = 
                            ride.PickupLocation.Equals(request.PickupLocation.Address, StringComparison.OrdinalIgnoreCase) &&
                            ride.DropoffLocation.Equals(request.DropoffLocation.Address, StringComparison.OrdinalIgnoreCase);
                        
                        if (passengerMatchesDriver)
                        {
                            // Simple case: passenger journey matches driver journey exactly
                            var routeInfo = _routeDistanceService.GetDistanceAndDuration(ride.PickupLocation, ride.DropoffLocation);
                            if (routeInfo != null)
                            {
                                distanceKm = routeInfo.Value.distanceKm;
                                durationMinutes = routeInfo.Value.durationMinutes;
                                
                                // Build simple route stops (pickup and dropoff only)
                                routeStopsWithTiming = new List<RideStopWithTimeDto>();
                                
                                // Add pickup
                                routeStopsWithTiming.Add(new RideStopWithTimeDto
                                {
                                    Location = ride.PickupLocation,
                                    ArrivalTime = $"{depHour:D2}:{depMinute:D2}",
                                    CumulativeDurationMinutes = 0
                                });
                                
                                // Add dropoff with calculated arrival time
                                int totalMinutes = depHour * 60 + depMinute + durationMinutes;
                                int arrHour = (totalMinutes / 60) % 24;
                                int arrMinute = totalMinutes % 60;
                                string arrivalTime = $"{arrHour:D2}:{arrMinute:D2}";
                                
                                routeStopsWithTiming.Add(new RideStopWithTimeDto
                                {
                                    Location = ride.DropoffLocation,
                                    ArrivalTime = arrivalTime,
                                    CumulativeDurationMinutes = durationMinutes
                                });
                            }
                        }
                        else
                        {
                            // Complex case: passenger has different pickup/dropoff along the route
                            // Calculate journey time specifically for the passenger's segment
                            var passengerRouteInfo = _routeDistanceService.GetDistanceAndDuration(
                                request.PickupLocation.Address, 
                                request.DropoffLocation.Address);
                            
                            if (passengerRouteInfo != null)
                            {
                                // Calculate when driver reaches passenger's pickup location
                                var driverToPassengerPickup = _routeDistanceService.GetDistanceAndDuration(
                                    ride.PickupLocation,
                                    request.PickupLocation.Address);
                                
                                int passengerPickupDelayMinutes = driverToPassengerPickup?.durationMinutes ?? 0;
                                int passengerJourneyMinutes = passengerRouteInfo.Value.durationMinutes;
                                
                                routeStopsWithTiming = new List<RideStopWithTimeDto>();
                                
                                // Add driver's original stops for context
                                routeStopsWithTiming.Add(new RideStopWithTimeDto
                                {
                                    Location = ride.PickupLocation,
                                    ArrivalTime = $"{depHour:D2}:{depMinute:D2}",
                                    CumulativeDurationMinutes = 0
                                });
                                
                                // Add passenger's pickup location with calculated time
                                int passengerPickupTotalMinutes = depHour * 60 + depMinute + passengerPickupDelayMinutes;
                                int passengerPickupHour = (passengerPickupTotalMinutes / 60) % 24;
                                int passengerPickupMinute = passengerPickupTotalMinutes % 60;
                                
                                routeStopsWithTiming.Add(new RideStopWithTimeDto
                                {
                                    Location = request.PickupLocation.Address,
                                    ArrivalTime = $"{passengerPickupHour:D2}:{passengerPickupMinute:D2}",
                                    CumulativeDurationMinutes = passengerPickupDelayMinutes
                                });
                                
                                // Add passenger's dropoff location
                                int passengerDropoffTotalMinutes = passengerPickupTotalMinutes + passengerJourneyMinutes;
                                int passengerDropoffHour = (passengerDropoffTotalMinutes / 60) % 24;
                                int passengerDropoffMinute = passengerDropoffTotalMinutes % 60;
                                
                                routeStopsWithTiming.Add(new RideStopWithTimeDto
                                {
                                    Location = request.DropoffLocation.Address,
                                    ArrivalTime = $"{passengerDropoffHour:D2}:{passengerDropoffMinute:D2}",
                                    CumulativeDurationMinutes = passengerPickupDelayMinutes + passengerJourneyMinutes
                                });
                                
                                // Add driver's final destination
                                var driverFullRoute = _routeDistanceService.GetDistanceAndDuration(ride.PickupLocation, ride.DropoffLocation);
                                if (driverFullRoute != null)
                                {
                                    int driverTotalMinutes = depHour * 60 + depMinute + driverFullRoute.Value.durationMinutes;
                                    int driverArrHour = (driverTotalMinutes / 60) % 24;
                                    int driverArrMinute = driverTotalMinutes % 60;
                                    
                                    routeStopsWithTiming.Add(new RideStopWithTimeDto
                                    {
                                        Location = ride.DropoffLocation,
                                        ArrivalTime = $"{driverArrHour:D2}:{driverArrMinute:D2}",
                                        CumulativeDurationMinutes = driverFullRoute.Value.durationMinutes
                                    });
                                }
                                
                                // Update distance and duration for passenger's specific segment
                                distanceKm = passengerRouteInfo.Value.distanceKm;
                                durationMinutes = passengerJourneyMinutes;
                            }
                        }
                    }
                    
                    // Format duration as "H:mm" (e.g., "5:08" for 5 hours 8 minutes)
                    int hours = durationMinutes / 60;
                    int minutes = durationMinutes % 60;
                    string formattedDuration = $"{hours}:{minutes:D2}";

                    // Calculate segment pricing based on driver's entered segment prices
                    decimal segmentPrice = ride.PricePerSeat;
                    double passengerDistanceKm = distanceKm;
                    
                    // Parse segment prices if available
                    if (!string.IsNullOrEmpty(ride.SegmentPrices))
                    {
                        try
                        {
                            _logger.LogInformation($"💰 Parsing segment prices for ride {ride.Id}: {ride.SegmentPrices}");
                            
                            var options = new System.Text.Json.JsonSerializerOptions
                            {
                                PropertyNameCaseInsensitive = true
                            };
                            var segmentPrices = System.Text.Json.JsonSerializer.Deserialize<List<SegmentPriceDto>>(ride.SegmentPrices, options);
                            
                            if (segmentPrices != null && segmentPrices.Any())
                            {
                                _logger.LogInformation($"💰 Found {segmentPrices.Count} segment prices");
                                _logger.LogInformation($"💰 Searching for: {request.PickupLocation.Address} → {request.DropoffLocation.Address}");
                                
                                // Find the segment that matches passenger's journey
                                foreach (var segment in segmentPrices)
                                {
                                    _logger.LogInformation($"💰 Checking segment: {segment.FromLocation} → {segment.ToLocation} = ₹{segment.Price}");
                                    
                                    // Check if this segment matches the passenger's pickup and dropoff
                                    bool matchesPickup = segment.FromLocation.Equals(request.PickupLocation.Address, StringComparison.OrdinalIgnoreCase) ||
                                                       request.PickupLocation.Address.Contains(segment.FromLocation, StringComparison.OrdinalIgnoreCase) ||
                                                       segment.FromLocation.Contains(request.PickupLocation.Address, StringComparison.OrdinalIgnoreCase);
                                    
                                    bool matchesDropoff = segment.ToLocation.Equals(request.DropoffLocation.Address, StringComparison.OrdinalIgnoreCase) ||
                                                        request.DropoffLocation.Address.Contains(segment.ToLocation, StringComparison.OrdinalIgnoreCase) ||
                                                        segment.ToLocation.Contains(request.DropoffLocation.Address, StringComparison.OrdinalIgnoreCase);
                                    
                                    _logger.LogInformation($"💰 Pickup match: {matchesPickup}, Dropoff match: {matchesDropoff}");
                                    
                                    if (matchesPickup && matchesDropoff)
                                    {
                                        // Found matching segment, use the driver's entered price
                                        segmentPrice = segment.Price;
                                        _logger.LogInformation($"✅ Using driver's segment price: {segment.FromLocation} → {segment.ToLocation} = ₹{segmentPrice}");
                                        
                                        // Also get the segment distance
                                        var segmentInfo = _routeDistanceService.GetDistanceAndDuration(segment.FromLocation, segment.ToLocation);
                                        if (segmentInfo != null)
                                        {
                                            passengerDistanceKm = segmentInfo.Value.distanceKm;
                                        }
                                        break;
                                    }
                                }
                            }
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "Failed to parse segment prices for ride {RideId}", ride.Id);
                        }
                    }
                    else
                    {
                        _logger.LogInformation($"💰 No segment prices found for ride {ride.Id}, using full price ₹{ride.PricePerSeat}");
                    }

                    // Get booked seats for this ride
                    var bookedSeats = await GetBookedSeatsForRideAsync(ride.Id);

                    availableRides.Add(new AvailableRideDto
                    {
                        RideId = ride.Id,
                        DriverId = ride.DriverId,
                        DriverName = ride.Driver?.User?.Profile?.Name ?? "Unknown",
                        DriverRating = ride.Driver?.User?.Profile?.Rating ?? 0,
                        DriverRatingCount = driverRatingCount,
                        VehicleType = ride.Vehicle?.VehicleType ?? "Unknown",
                        VehicleModel = $"{ride.Vehicle?.Make} {ride.Vehicle?.Model}",
                        VehicleNumber = ride.Vehicle?.RegistrationNumber ?? "",
                        VehicleSeatingCapacity = ride.Vehicle?.VehicleModel?.SeatingCapacity ?? ride.TotalSeats,
                        TotalSeats = ride.TotalSeats,
                        AvailableSeats = ride.TotalSeats - ride.BookedSeats,
                        DepartureTime = $"{depHour:D2}:{depMinute:D2}",
                        PricePerSeat = segmentPrice,
                        TotalPrice = segmentPrice * request.PassengerCount,
                        EstimatedDuration = formattedDuration,
                        Distance = (decimal)passengerDistanceKm,
                        PickupLocation = ride.PickupLocation,
                        DropoffLocation = ride.DropoffLocation,
                        IntermediateStops = intermediateStops,
                        RouteStopsWithTiming = routeStopsWithTiming,
                        SeatingLayout = ride.Vehicle?.VehicleModel?.SeatingLayout,
                        BookedSeats = bookedSeats
                    });
                }

                var response = new SearchRidesResponseDto
                {
                    AvailableRides = availableRides
                };

                return Ok(ApiResponseDto<SearchRidesResponseDto>.SuccessResponse(response));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error searching rides");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while searching rides"));
            }
        }

        /// <summary>
        /// Book a ride
        /// </summary>
        [HttpPost("book")]
        [ValidateModel]
        public async Task<IActionResult> BookRide([FromBody] BookRideRequestDto request)
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                // Get ride details
                var ride = await _rideRepository.GetRideByIdAsync(request.RideId);
                if (ride == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Ride not found"));
                }

                // Check availability
                if (ride.TotalSeats - ride.BookedSeats < request.PassengerCount)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Not enough seats available"));
                }

                // Validate selected seats if provided
                List<string>? selectedSeats = null;
                if (request.SelectedSeats != null && request.SelectedSeats.Any())
                {
                    // Validate seat count matches passenger count
                    if (request.SelectedSeats.Count != request.PassengerCount)
                    {
                        return BadRequest(ApiResponseDto<object>.ErrorResponse($"Selected seats count ({request.SelectedSeats.Count}) must match passenger count ({request.PassengerCount})"));
                    }

                    // Get currently booked seats
                    var bookedSeats = await GetBookedSeatsForRideAsync(request.RideId);
                    
                    // Check if any selected seats are already booked
                    var conflictingSeats = request.SelectedSeats.Intersect(bookedSeats).ToList();
                    if (conflictingSeats.Any())
                    {
                        return BadRequest(ApiResponseDto<object>.ErrorResponse($"Selected seats are already booked: {string.Join(", ", conflictingSeats)}"));
                    }

                    selectedSeats = request.SelectedSeats;
                }

                // Calculate price based on segment pricing if available
                var pricePerSeat = CalculateBookingPrice(ride, request.PickupLocation.Address, request.DropoffLocation.Address);

                // Create booking
                var booking = new RideSharing.API.Models.Domain.Booking
                {
                    Id = Guid.NewGuid(),
                    BookingNumber = $"BKG{DateTime.UtcNow:yyyyMMddHHmmss}",
                    RideId = request.RideId,
                    PassengerId = userGuid,
                    PassengerCount = request.PassengerCount,
                    SeatNumbers = selectedSeats != null ? string.Join(", ", selectedSeats) : null,
                    SelectedSeats = selectedSeats != null ? System.Text.Json.JsonSerializer.Serialize(selectedSeats) : null,
                    PickupLocation = request.PickupLocation.Address,
                    PickupLatitude = request.PickupLocation.Latitude,
                    PickupLongitude = request.PickupLocation.Longitude,
                    DropoffLocation = request.DropoffLocation.Address,
                    DropoffLatitude = request.DropoffLocation.Latitude,
                    DropoffLongitude = request.DropoffLocation.Longitude,
                    PricePerSeat = pricePerSeat,
                    TotalFare = pricePerSeat * request.PassengerCount,
                    PlatformFee = pricePerSeat * request.PassengerCount * 0.1m,
                    TotalAmount = pricePerSeat * request.PassengerCount * 1.1m,
                    OTP = new Random().Next(1000, 9999).ToString(),
                    Status = "pending",
                    CreatedAt = DateTime.UtcNow
                };

                booking = await _rideRepository.CreateBookingAsync(booking);

                // Send booking confirmation notification to passenger
                try
                {
                    var passenger = await _context.Users.FindAsync(userGuid);
                    if (passenger != null && !string.IsNullOrEmpty(passenger.FCMToken))
                    {
                        _logger.LogInformation($"📱 Sending booking confirmation to passenger: {passenger.FCMToken.Substring(0, Math.Min(20, passenger.FCMToken.Length))}...");
                        await _fcmService.SendBookingConfirmationAsync(passenger.FCMToken, booking);
                    }
                    else
                    {
                        _logger.LogWarning($"⚠️ No FCM token found for passenger {userGuid}. Notification not sent.");
                    }
                }
                catch (Exception notifEx)
                {
                    _logger.LogError(notifEx, "❌ Failed to send booking confirmation notification to passenger");
                    // Don't fail the booking if notification fails
                }

                // Send new booking notification to driver
                try
                {
                    var driver = await _context.Drivers
                        .Include(d => d.User)
                        .FirstOrDefaultAsync(d => d.Id == ride.DriverId);
                    
                    if (driver?.User != null && !string.IsNullOrEmpty(driver.User.FCMToken))
                    {
                        var passengerName = (await _context.UserProfiles.FirstOrDefaultAsync(p => p.UserId == userGuid))?.Name ?? "Passenger";
                        _logger.LogInformation($"📱 Sending new booking notification to driver: {driver.User.FCMToken.Substring(0, Math.Min(20, driver.User.FCMToken.Length))}...");
                        await _fcmService.SendNewBookingToDriverAsync(
                            driver.User.FCMToken,
                            passengerName,
                            booking.PickupLocation,
                            booking.DropoffLocation,
                            booking.PassengerCount,
                            booking.BookingNumber
                        );
                    }
                    else
                    {
                        _logger.LogWarning($"⚠️ No FCM token found for driver {ride.DriverId}. Notification not sent.");
                    }
                }
                catch (Exception notifEx)
                {
                    _logger.LogError(notifEx, "❌ Failed to send new booking notification to driver");
                    // Don't fail the booking if notification fails
                }

                var response = new BookingResponseDto
                {
                    BookingId = booking.Id,
                    RideId = booking.RideId,
                    BookingNumber = booking.BookingNumber,
                    Status = booking.Status,
                    Otp = booking.OTP,
                    PickupLocation = booking.PickupLocation,
                    DropoffLocation = booking.DropoffLocation,
                    TravelDate = ride.TravelDate,
                    DepartureTime = ride.DepartureTime.ToString(@"hh\:mm"),
                    PassengerCount = booking.PassengerCount,
                    TotalFare = booking.TotalAmount,
                    SelectedSeats = selectedSeats,
                    DriverDetails = new DriverDetailsDto
                    {
                        Id = ride.DriverId,
                        Name = ride.Driver?.User?.Profile?.Name ?? "",
                        PhoneNumber = ride.Driver?.User?.PhoneNumber ?? "",
                        Rating = ride.Driver?.User?.Profile?.Rating ?? 0,
                        VehicleModel = $"{ride.Vehicle?.Make} {ride.Vehicle?.Model}",
                        VehicleNumber = ride.Vehicle?.RegistrationNumber ?? ""
                    },
                    CreatedAt = booking.CreatedAt
                };

                return Ok(ApiResponseDto<BookingResponseDto>.SuccessResponse(response, "Ride booked successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error booking ride");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while booking ride"));
            }
        }

        /// <summary>
        /// Get booking details
        /// </summary>
        [HttpGet("bookings/{bookingId}")]
        public async Task<IActionResult> GetBooking(Guid bookingId)
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                var booking = await _rideRepository.GetBookingByIdAsync(bookingId);
                if (booking == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Booking not found"));
                }

                // Verify booking belongs to user
                if (booking.PassengerId != userGuid)
                {
                    return Forbid();
                }

                var response = new BookingResponseDto
                {
                    BookingId = booking.Id,
                    RideId = booking.RideId,
                    BookingNumber = booking.BookingNumber,
                    Status = booking.Status,
                    Otp = booking.OTP,
                    PickupLocation = booking.PickupLocation,
                    DropoffLocation = booking.DropoffLocation,
                    TravelDate = booking.Ride?.TravelDate ?? DateTime.Now,
                    DepartureTime = booking.Ride?.DepartureTime.ToString(@"hh\:mm") ?? "",
                    PassengerCount = booking.PassengerCount,
                    TotalFare = booking.TotalAmount,
                    DriverDetails = new DriverDetailsDto
                    {
                        Id = booking.Ride?.DriverId ?? Guid.Empty,
                        Name = booking.Ride?.Driver?.User?.Profile?.Name ?? "",
                        PhoneNumber = booking.Ride?.Driver?.User?.PhoneNumber ?? "",
                        Rating = booking.Ride?.Driver?.User?.Profile?.Rating ?? 0,
                        VehicleModel = $"{booking.Ride?.Vehicle?.Make} {booking.Ride?.Vehicle?.Model}",
                        VehicleNumber = booking.Ride?.Vehicle?.RegistrationNumber ?? ""
                    },
                    CreatedAt = booking.CreatedAt
                };

                return Ok(ApiResponseDto<BookingResponseDto>.SuccessResponse(response));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving booking");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while retrieving booking"));
            }
        }

        /// <summary>
        /// Cancel a booking
        /// </summary>
        [HttpPost("bookings/{bookingId}/cancel")]
        [ValidateModel]
        public async Task<IActionResult> CancelBooking(Guid bookingId, [FromBody] CancelRideRequestDto request)
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                var success = await _rideRepository.CancelBookingAsync(bookingId, request.Reason, request.CancellationType);
                if (!success)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Failed to cancel booking"));
                }

                // Get booking details for notifications
                var booking = await _rideRepository.GetBookingByIdAsync(bookingId);
                if (booking != null)
                {
                    // Send cancellation notification to passenger
                    try
                    {
                        var passenger = await _context.Users.FindAsync(booking.PassengerId);
                        if (passenger != null && !string.IsNullOrEmpty(passenger.FCMToken))
                        {
                            _logger.LogInformation($"📱 Sending cancellation notification to passenger");
                            await _fcmService.SendBookingCancelledAsync(
                                passenger.FCMToken,
                                booking.BookingNumber,
                                request.Reason ?? "No reason provided"
                            );
                        }
                    }
                    catch (Exception notifEx)
                    {
                        _logger.LogError(notifEx, "❌ Failed to send cancellation notification to passenger");
                    }

                    // Send cancellation notification to driver
                    try
                    {
                        var ride = await _rideRepository.GetRideByIdAsync(booking.RideId);
                        if (ride != null)
                        {
                            var driver = await _context.Drivers
                                .Include(d => d.User)
                                .FirstOrDefaultAsync(d => d.Id == ride.DriverId);
                            
                            if (driver?.User != null && !string.IsNullOrEmpty(driver.User.FCMToken))
                            {
                                var passengerName = (await _context.UserProfiles.FirstOrDefaultAsync(p => p.UserId == booking.PassengerId))?.Name ?? "Passenger";
                                _logger.LogInformation($"📱 Sending cancellation notification to driver");
                                await _fcmService.SendBookingCancelledAsync(
                                    driver.User.FCMToken,
                                    booking.BookingNumber,
                                    $"{passengerName} cancelled their booking"
                                );
                            }
                        }
                    }
                    catch (Exception notifEx)
                    {
                        _logger.LogError(notifEx, "❌ Failed to send cancellation notification to driver");
                    }
                }

                return Ok(ApiResponseDto<string>.SuccessResponse("success", "Booking cancelled successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error cancelling booking");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while cancelling booking"));
            }
        }

        /// <summary>
        /// Get ride history for passenger
        /// </summary>
        [HttpGet("history")]
        public async Task<IActionResult> GetRideHistory(
            [FromQuery] string? status = null,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                var bookings = await _rideRepository.GetUserBookingsAsync(userGuid, status, page, pageSize);
                var total = bookings.Count;

                // Get all booking IDs to query ratings
                var bookingIds = bookings.Select(b => b.Id).ToList();
                
                _logger.LogInformation($"🔍 Querying ratings for user {userGuid} and {bookingIds.Count} bookings");
                
                // First, check ALL ratings for these bookings (without filters)
                var allRatingsForBookings = await _context.Ratings
                    .Where(r => bookingIds.Contains(r.BookingId))
                    .ToListAsync();
                
                _logger.LogInformation($"📊 Total ratings found for these bookings: {allRatingsForBookings.Count}");
                foreach (var rating in allRatingsForBookings)
                {
                    _logger.LogInformation($"   - Booking {rating.BookingId}: RatedBy={rating.RatedBy}, RatingType={rating.RatingType}, Value={rating.RatingValue}");
                }
                
                // Query all ratings for these bookings where the current user is the rater
                // Group by BookingId to handle multiple ratings for same booking (take most recent)
                var passengerRatings = (await _context.Ratings
                    .Where(r => bookingIds.Contains(r.BookingId) && r.RatedBy == userGuid && r.RatingType == "passenger_to_driver")
                    .OrderByDescending(r => r.CreatedAt)
                    .ToListAsync())
                    .GroupBy(r => r.BookingId)
                    .ToDictionary(g => g.Key, g => g.First().RatingValue);

                _logger.LogInformation($"✅ Found {passengerRatings.Count} ratings for user {userGuid}");
                foreach (var rating in passengerRatings)
                {
                    _logger.LogInformation($"   - Booking {rating.Key}: Rating {rating.Value}");
                }

                // Debug logging for intermediate stops
                foreach (var booking in bookings)
                {
                    _logger.LogInformation($"🔍 Booking {booking.BookingNumber}: Ride={booking.Ride != null}, IntermediateStops raw JSON={booking.Ride?.IntermediateStops}");
                }

                var rideHistory = bookings.Select(b =>
                {
                    List<string>? intermediateStops = null;
                    if (!string.IsNullOrEmpty(b.Ride?.IntermediateStops))
                    {
                        try
                        {
                            intermediateStops = System.Text.Json.JsonSerializer.Deserialize<List<string>>(b.Ride.IntermediateStops);
                            _logger.LogInformation($"✅ Deserialized {intermediateStops?.Count ?? 0} intermediate stops for {b.BookingNumber}");
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, $"❌ Failed to deserialize intermediate stops for {b.BookingNumber}");
                        }
                    }
                    else
                    {
                        _logger.LogWarning($"⚠️  No intermediate stops data for {b.BookingNumber}");
                    }

                    // Check if passenger has rated this booking
                    int? passengerRating = null;
                    if (passengerRatings.ContainsKey(b.Id))
                    {
                        passengerRating = passengerRatings[b.Id];
                        _logger.LogInformation($"✅ Found rating {passengerRating} for booking {b.BookingNumber} (ID: {b.Id})");
                    }
                    else
                    {
                        _logger.LogWarning($"⚠️ No rating found for booking {b.BookingNumber} (ID: {b.Id})");
                    }

                    return new RideHistoryItemDto
                    {
                        BookingId = b.Id,
                        BookingNumber = b.BookingNumber,
                        PickupLocation = b.PickupLocation,
                        DropoffLocation = b.DropoffLocation,
                        Date = b.Ride?.TravelDate ?? DateTime.Now,
                        TimeSlot = b.Ride?.DepartureTime.ToString(@"hh\:mm") ?? "",
                        VehicleType = b.Ride?.Vehicle?.VehicleType ?? "",
                        VehicleModel = $"{b.Ride?.Vehicle?.Make} {b.Ride?.Vehicle?.Model}",
                        VehicleNumber = b.Ride?.Vehicle?.RegistrationNumber ?? "",
                        Fare = b.TotalAmount,
                        Status = b.Status,
                        PassengerCount = b.PassengerCount,
                            DriverName = b.Ride?.Driver?.User?.Profile?.Name ?? "",
                            DriverId = b.Ride?.Driver?.User?.Id,
                        DriverRating = b.Ride?.Driver?.User?.Profile?.Rating ?? 0,
                        PassengerRating = passengerRating,
                        Otp = b.OTP,
                        CompletedAt = null, // No CompletedAt field in Booking
                        IsVerified = b.IsVerified,
                        RideId = b.RideId,
                        IntermediateStops = intermediateStops
                    };
                }).ToList();

                var response = new RideHistoryDto
                {
                    Rides = rideHistory,
                    Pagination = new PaginationDto
                    {
                        CurrentPage = page,
                        ItemsPerPage = pageSize,
                        TotalItems = total,
                        TotalPages = (int)Math.Ceiling(total / (double)pageSize)
                    }
                };

                return Ok(ApiResponseDto<RideHistoryDto>.SuccessResponse(response));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving ride history");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while retrieving ride history"));
            }
        }

        /// <summary>
        /// Rate a completed ride
        /// </summary>
        [HttpPost("bookings/{bookingId}/rate")]
        [ValidateModel]
        public async Task<IActionResult> RateRide(Guid bookingId, [FromBody] RateRideRequestDto request)
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                // Get booking to validate
                var booking = await _rideRepository.GetBookingByIdAsync(bookingId);
                if (booking == null || booking.PassengerId != userGuid)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Invalid booking"));
                }

                if (booking.Status != "completed")
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Can only rate completed rides"));
                }

                // Validate required fields
                if (booking.RideId == Guid.Empty)
                {
                    _logger.LogError($"Booking {bookingId} has no RideId");
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Ride information not available for this booking"));
                }

                // Get the driver's user ID from the ride
                var ride = await _context.Rides
                    .Include(r => r.Driver)
                    .FirstOrDefaultAsync(r => r.Id == booking.RideId);
                
                if (ride?.Driver?.UserId == null)
                {
                    _logger.LogError($"Driver information not found for ride {booking.RideId}");
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Driver information not available"));
                }

                // Create rating - RatedTo should be the driver's User ID, not Driver ID
                var rating = new RideSharing.API.Models.Domain.Rating
                {
                    Id = Guid.NewGuid(),
                    BookingId = bookingId,
                    RideId = booking.RideId,
                    RatedBy = userGuid,
                    RatedTo = ride.Driver.UserId,  // Use driver's User ID
                    RatingType = "passenger_to_driver",
                    RatingValue = request.Rating,
                    Review = request.Review,
                    CreatedAt = DateTime.UtcNow
                };

                _logger.LogInformation($"Creating rating for booking {bookingId}: {request.Rating} stars");
                await _rideRepository.CreateRatingAsync(rating);
                _logger.LogInformation($"Rating created successfully for booking {bookingId}");

                return Ok(ApiResponseDto<string>.SuccessResponse("success", "Rating submitted successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error submitting rating");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while submitting rating"));
            }
        }

        /// <summary>
        /// Calculate booking price based on segment pricing if available
        /// </summary>
        private decimal CalculateBookingPrice(RideSharing.API.Models.Domain.Ride ride, string pickupLocation, string dropoffLocation)
        {
            // If no segment prices, use base price
            if (string.IsNullOrEmpty(ride.SegmentPrices))
            {
                return ride.PricePerSeat;
            }

            try
            {
                var segmentPrices = System.Text.Json.JsonSerializer.Deserialize<List<SegmentPriceDto>>(ride.SegmentPrices);
                if (segmentPrices == null || !segmentPrices.Any())
                {
                    return ride.PricePerSeat;
                }

                // Build complete route
                var allStops = new List<string> { ride.PickupLocation };
                if (!string.IsNullOrEmpty(ride.IntermediateStops))
                {
                    var intermediateStops = System.Text.Json.JsonSerializer.Deserialize<List<string>>(ride.IntermediateStops);
                    if (intermediateStops != null)
                    {
                        allStops.AddRange(intermediateStops);
                    }
                }
                allStops.Add(ride.DropoffLocation);

                // Find pickup and dropoff indices
                var pickupIndex = allStops.FindIndex(s => s.Equals(pickupLocation, StringComparison.OrdinalIgnoreCase));
                var dropoffIndex = allStops.FindIndex(s => s.Equals(dropoffLocation, StringComparison.OrdinalIgnoreCase));

                // If locations not found in route, use base price
                if (pickupIndex == -1 || dropoffIndex == -1 || pickupIndex >= dropoffIndex)
                {
                    return ride.PricePerSeat;
                }

                // Sum prices of segments between pickup and dropoff
                decimal totalPrice = 0;
                for (int i = pickupIndex; i < dropoffIndex && i < segmentPrices.Count; i++)
                {
                    totalPrice += segmentPrices[i].Price;
                }

                return totalPrice > 0 ? totalPrice : ride.PricePerSeat;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Error calculating segment-based price, falling back to base price");
                return ride.PricePerSeat;
            }
        }

        /// <summary>
        /// Get booked seats for a ride
        /// </summary>
        private async Task<List<string>> GetBookedSeatsForRideAsync(Guid rideId)
        {
            try
            {
                var bookings = await _context.Bookings
                    .Where(b => b.RideId == rideId && b.Status != "cancelled")
                    .ToListAsync();

                var bookedSeats = new List<string>();
                foreach (var booking in bookings)
                {
                    if (!string.IsNullOrEmpty(booking.SelectedSeats))
                    {
                        var seats = System.Text.Json.JsonSerializer.Deserialize<List<string>>(booking.SelectedSeats);
                        if (seats != null)
                        {
                            bookedSeats.AddRange(seats);
                        }
                    }
                }

                return bookedSeats;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Error getting booked seats for ride {RideId}", rideId);
                return new List<string>();
            }
        }

        /// <summary>
        /// Upload seating arrangement screenshot for a booking
        /// </summary>
        [HttpPost("bookings/{bookingId}/seating-image")]
        public async Task<IActionResult> UploadSeatingArrangementImage(Guid bookingId, [FromForm] IFormFile image)
        {
            try
            {
                var userId = User.FindFirst("userId")?.Value;
                if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
                {
                    return Unauthorized(ApiResponseDto<object>.ErrorResponse("Invalid token"));
                }

                // Get booking
                var booking = await _context.Bookings
                    .FirstOrDefaultAsync(b => b.Id == bookingId);

                if (booking == null)
                {
                    return NotFound(ApiResponseDto<object>.ErrorResponse("Booking not found"));
                }

                // Verify booking belongs to user
                if (booking.PassengerId != userGuid)
                {
                    return Forbid();
                }

                // Validate file
                if (image == null || image.Length == 0)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("No image file provided"));
                }

                // Validate file type
                var allowedTypes = new[] { "image/jpeg", "image/jpg", "image/png" };
                if (!allowedTypes.Contains(image.ContentType.ToLower()))
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("Invalid file type. Only JPG and PNG are allowed"));
                }

                // Validate file size (max 5MB)
                if (image.Length > 5 * 1024 * 1024)
                {
                    return BadRequest(ApiResponseDto<object>.ErrorResponse("File size exceeds 5MB limit"));
                }

                // Delete old image if exists
                if (!string.IsNullOrEmpty(booking.SeatingArrangementImage))
                {
                    await _fileUploadService.DeleteFileAsync(booking.SeatingArrangementImage);
                }

                // Upload new image
                using var stream = image.OpenReadStream();
                var imageUrl = await _fileUploadService.UploadFileAsync(stream, image.FileName, "bookings");
                
                // Update booking
                booking.SeatingArrangementImage = imageUrl;
                booking.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                return Ok(ApiResponseDto<object>.SuccessResponse(new { ImageUrl = imageUrl }, "Screenshot uploaded successfully"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading seating arrangement screenshot");
                return StatusCode(500, ApiResponseDto<object>.ErrorResponse("An error occurred while uploading screenshot"));
            }
        }
    }
}
