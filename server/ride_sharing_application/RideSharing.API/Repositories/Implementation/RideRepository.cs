using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;
using RideSharing.API.Models.Domain;
using RideSharing.API.Repositories.Interface;

namespace RideSharing.API.Repositories.Implementation
{
    public class RideRepository : IRideRepository
    {
        private readonly RideSharingDbContext _context;

        public RideRepository(RideSharingDbContext context)
        {
            _context = context;
        }

        public async Task<List<Ride>> SearchAvailableRidesAsync(
            string pickupLocation,
            string dropoffLocation,
            DateTime travelDate,
            int passengerCount,
            string? vehicleType)
        {
            Console.WriteLine($"\n🔍 SEARCH REQUEST: '{pickupLocation}' → '{dropoffLocation}' on {travelDate:yyyy-MM-dd}");
            
            // Calculate minimum departure time in Indian timezone (UTC+5:30)
            var istOffset = TimeSpan.FromHours(5.5);
            var nowIst = DateTime.UtcNow.Add(istOffset);
            var minDepartureDateTime = nowIst.AddMinutes(5);
            Console.WriteLine($"⏰ Current IST: {nowIst:yyyy-MM-dd HH:mm:ss}, Min departure: {minDepartureDateTime:yyyy-MM-dd HH:mm:ss}");
            
            var query = _context.Rides
                .Include(r => r.Driver)
                    .ThenInclude(d => d.User)
                    .ThenInclude(u => u.Profile)
                .Include(r => r.Vehicle)
                    .ThenInclude(v => v.VehicleModel)
                .Where(r => 
                    r.TravelDate.Date == travelDate.Date &&
                    r.Status == "scheduled" &&
                    (r.TotalSeats - r.BookedSeats) >= passengerCount);

            if (!string.IsNullOrEmpty(vehicleType))
            {
                query = query.Where(r => r.Vehicle.VehicleType == vehicleType);
            }

            // Filter rides that match the pickup and dropoff locations
            // This includes:
            // 1. Direct rides where main pickup/dropoff match
            // 2. Rides with intermediate stops (route segments) that match
            var rides = await query.ToListAsync();
            
            // Filter out rides departing in less than 5 minutes
            var ridesWithTimeCheck = rides.Where(r =>
            {
                var rideDepartureDateTime = r.TravelDate.Date.Add(r.DepartureTime);
                return rideDepartureDateTime >= minDepartureDateTime;
            }).ToList();
            
            Console.WriteLine($"📊 Found {rides.Count} total rides, {ridesWithTimeCheck.Count} after time filter");
            
            // Helper function to check if locations match (flexible matching)
            bool LocationsMatch(string location1, string location2)
            {
                if (string.IsNullOrEmpty(location1) || string.IsNullOrEmpty(location2))
                    return false;
                    
                var loc1Lower = location1.ToLower().Trim();
                var loc2Lower = location2.ToLower().Trim();
                
                // Exact match
                if (loc1Lower == loc2Lower) return true;
                
                // Contains match (either direction)
                if (loc1Lower.Contains(loc2Lower) || loc2Lower.Contains(loc1Lower)) return true;
                
                // Extract city names (text before first comma)
                var city1 = loc1Lower.Split(',')[0].Trim();
                var city2 = loc2Lower.Split(',')[0].Trim();
                
                // City name match
                if (city1 == city2) return true;
                if (city1.Contains(city2) || city2.Contains(city1)) return true;
                
                return false;
            }
            
            var matchingRides = ridesWithTimeCheck.Where(r => 
            {
                Console.WriteLine($"\n🚗 Checking Ride {r.Id}: {r.PickupLocation} → {r.DropoffLocation}");
                Console.WriteLine($"   IntermediateStops: {(string.IsNullOrEmpty(r.IntermediateStops) ? "NONE" : r.IntermediateStops)}");
                Console.WriteLine($"   SegmentPrices: {(string.IsNullOrEmpty(r.SegmentPrices) ? "NONE" : r.SegmentPrices.Substring(0, Math.Min(100, r.SegmentPrices.Length)))}...");
                
                // Check if main pickup and dropoff match
                bool mainRouteMatches = LocationsMatch(r.PickupLocation, pickupLocation) &&
                                       LocationsMatch(r.DropoffLocation, dropoffLocation);
                
                Console.WriteLine($"   Main route match: {mainRouteMatches}");
                if (mainRouteMatches) return true;
                
                // Try to get intermediate stops from IntermediateStops column first
                List<string>? intermediateStops = null;
                
                if (!string.IsNullOrEmpty(r.IntermediateStops))
                {
                    try
                    {
                        intermediateStops = System.Text.Json.JsonSerializer.Deserialize<List<string>>(r.IntermediateStops);
                        Console.WriteLine($"   ✅ Loaded {intermediateStops?.Count ?? 0} intermediate stops from IntermediateStops column");
                    }
                    catch
                    {
                        Console.WriteLine($"   ⚠️ Failed to parse IntermediateStops JSON");
                    }
                }
                
                // FALLBACK: Extract intermediate stops from SegmentPrices if IntermediateStops is empty
                if ((intermediateStops == null || !intermediateStops.Any()) && !string.IsNullOrEmpty(r.SegmentPrices))
                {
                    try
                    {
                        Console.WriteLine($"   🔄 IntermediateStops is empty, extracting from SegmentPrices...");
                        var segmentPrices = System.Text.Json.JsonSerializer.Deserialize<List<System.Text.Json.JsonElement>>(r.SegmentPrices);
                        if (segmentPrices != null && segmentPrices.Any())
                        {
                            intermediateStops = new List<string>();
                            // Extract ToLocation from all segments except the last one
                            // (last segment's ToLocation is the dropoff)
                            for (int i = 0; i < segmentPrices.Count - 1; i++)
                            {
                                if (segmentPrices[i].TryGetProperty("ToLocation", out var toLocation))
                                {
                                    var loc = toLocation.GetString();
                                    if (!string.IsNullOrEmpty(loc) && !intermediateStops.Contains(loc))
                                    {
                                        intermediateStops.Add(loc);
                                    }
                                }
                            }
                            Console.WriteLine($"   ✅ Extracted {intermediateStops.Count} intermediate stops from SegmentPrices: {string.Join(", ", intermediateStops)}");
                        }
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"   ⚠️ Failed to extract intermediate stops from SegmentPrices: {ex.Message}");
                    }
                }
                
                // Store extracted intermediate stops back to the ride object for API response
                if (intermediateStops != null && intermediateStops.Any())
                {
                    // Update the ride's IntermediateStops property so the API returns it
                    if (string.IsNullOrEmpty(r.IntermediateStops))
                    {
                        r.IntermediateStops = System.Text.Json.JsonSerializer.Serialize(intermediateStops);
                        Console.WriteLine($"   💾 Stored extracted intermediate stops to ride object");
                    }
                    
                    Console.WriteLine($"   Parsed {intermediateStops.Count} intermediate stops: {string.Join(", ", intermediateStops)}");
                    
                    // Get all unique locations in order (pickup -> intermediate stops -> dropoff)
                    var allLocations = new List<string> { r.PickupLocation };
                    allLocations.AddRange(intermediateStops);
                    allLocations.Add(r.DropoffLocation);
                    
                    Console.WriteLine($"   Complete route: {string.Join(" → ", allLocations)}");
                    
                    // Check if passenger's pickup and dropoff exist in sequence
                    int pickupIndex = -1;
                    int dropoffIndex = -1;
                    
                    for (int i = 0; i < allLocations.Count; i++)
                    {
                        if (pickupIndex == -1 && LocationsMatch(allLocations[i], pickupLocation))
                        {
                            pickupIndex = i;
                            Console.WriteLine($"   ✅ Pickup matched at index {i}: '{allLocations[i]}' matches '{pickupLocation}'");
                        }
                        if (dropoffIndex == -1 && LocationsMatch(allLocations[i], dropoffLocation))
                        {
                            dropoffIndex = i;
                            Console.WriteLine($"   ✅ Dropoff matched at index {i}: '{allLocations[i]}' matches '{dropoffLocation}'");
                        }
                    }
                    
                    bool isMatch = pickupIndex != -1 && dropoffIndex != -1 && pickupIndex < dropoffIndex;
                    Console.WriteLine($"   📍 Pickup index: {pickupIndex}, Dropoff index: {dropoffIndex}, Match: {isMatch}");
                    
                    // Pickup must come before dropoff in the route
                    return isMatch;
                }
                
                Console.WriteLine($"   ❌ No match for this ride");
                return false;
            }).ToList();
            
            Console.WriteLine($"\n✅ SEARCH COMPLETE: Found {matchingRides.Count} matching rides\n");

            return matchingRides
                .OrderBy(r => r.DepartureTime)
                .ToList();
        }

        public async Task<Ride?> GetRideByIdAsync(Guid rideId)
        {
            var ride = await _context.Rides
                .Include(r => r.Driver)
                    .ThenInclude(d => d.User)
                    .ThenInclude(u => u.Profile)
                .Include(r => r.Vehicle)
                .FirstOrDefaultAsync(r => r.Id == rideId);

            if (ride != null)
            {
                // Explicitly load bookings with passengers and profiles
                await _context.Entry(ride)
                    .Collection(r => r.Bookings)
                    .Query()
                    .Include(b => b.Passenger)
                        .ThenInclude(p => p.Profile)
                    .LoadAsync();
            }

            return ride;
        }

        public async Task<Booking> CreateBookingAsync(Booking booking)
        {
            // Generate OTP
            var random = new Random();
            booking.OTP = random.Next(1000, 9999).ToString();
            booking.Status = "confirmed";
            booking.PaymentStatus = "pending";
            booking.CreatedAt = DateTime.UtcNow;
            booking.UpdatedAt = DateTime.UtcNow;

            await _context.Bookings.AddAsync(booking);

            // Update ride booked seats
            var ride = await _context.Rides.FindAsync(booking.RideId);
            if (ride != null)
            {
                ride.BookedSeats += booking.PassengerCount;
                ride.UpdatedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
            return booking;
        }

        public async Task<Booking?> GetBookingByIdAsync(Guid bookingId)
        {
            return await _context.Bookings
                .Include(b => b.Ride)
                    .ThenInclude(r => r.Driver)
                    .ThenInclude(d => d.User)
                    .ThenInclude(u => u.Profile)
                .Include(b => b.Ride.Vehicle)
                .Include(b => b.Passenger)
                    .ThenInclude(p => p.Profile)
                .FirstOrDefaultAsync(b => b.Id == bookingId);
        }

        public async Task<List<Booking>> GetUserBookingsAsync(Guid userId, string? status, int page, int limit)
        {
            var query = _context.Bookings
                .Include(b => b.Ride)
                    .ThenInclude(r => r.Driver)
                    .ThenInclude(d => d.User)
                    .ThenInclude(u => u.Profile)
                .Include(b => b.Ride.Vehicle)
                .Where(b => b.PassengerId == userId);

            if (!string.IsNullOrEmpty(status) && status != "all")
            {
                query = query.Where(b => b.Status == status);
            }

            return await query
                .OrderByDescending(b => b.CreatedAt)
                .Skip((page - 1) * limit)
                .Take(limit)
                .ToListAsync();
        }

        public async Task<Booking> UpdateBookingAsync(Booking booking)
        {
            booking.UpdatedAt = DateTime.UtcNow;
            _context.Bookings.Update(booking);
            await _context.SaveChangesAsync();
            return booking;
        }

        public async Task<bool> CancelBookingAsync(Guid bookingId, string reason, string cancellationType)
        {
            var booking = await _context.Bookings.FindAsync(bookingId);
            if (booking == null) return false;

            booking.Status = "cancelled";
            booking.CancellationType = cancellationType;
            booking.CancellationReason = reason;
            booking.CancelledAt = DateTime.UtcNow;
            booking.UpdatedAt = DateTime.UtcNow;

            // Update ride booked seats
            var ride = await _context.Rides.FindAsync(booking.RideId);
            if (ride != null)
            {
                ride.BookedSeats -= booking.PassengerCount;
                ride.UpdatedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<Rating> CreateRatingAsync(Rating rating)
        {
            rating.CreatedAt = DateTime.UtcNow;
            await _context.Ratings.AddAsync(rating);
            await _context.SaveChangesAsync();

            Console.WriteLine($"✅ Rating saved: BookingId={rating.BookingId}, RatedTo={rating.RatedTo}, Value={rating.RatingValue}");

            // Update user profile rating
            var userProfile = await _context.UserProfiles.FirstOrDefaultAsync(p => p.UserId == rating.RatedTo);
            if (userProfile != null)
            {
                var allRatings = await _context.Ratings
                    .Where(r => r.RatedTo == rating.RatedTo)
                    .Select(r => r.RatingValue)
                    .ToListAsync();

                var ratingCount = allRatings.Count;
                var avgRating = (decimal)allRatings.Average();
                
                Console.WriteLine($"📊 Driver {rating.RatedTo} stats: Count={ratingCount}, OldAvg={userProfile.Rating}, NewAvg={avgRating}");
                
                userProfile.Rating = avgRating;
                await _context.SaveChangesAsync();
                
                Console.WriteLine($"✅ Profile updated for driver {rating.RatedTo}");
            }
            else
            {
                Console.WriteLine($"⚠️ UserProfile not found for RatedTo={rating.RatedTo}");
            }

            return rating;
        }
    }
}
