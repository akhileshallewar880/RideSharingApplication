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
            // Calculate minimum departure time (current time + 5 minutes)
            var now = DateTime.UtcNow;
            var minDepartureDateTime = now.AddMinutes(5);
            
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
            
            var matchingRides = ridesWithTimeCheck.Where(r => 
            {
                // Check if main pickup and dropoff match
                bool mainRouteMatches = r.PickupLocation.Contains(pickupLocation, StringComparison.OrdinalIgnoreCase) &&
                                       r.DropoffLocation.Contains(dropoffLocation, StringComparison.OrdinalIgnoreCase);
                
                if (mainRouteMatches) return true;
                
                // Check if any intermediate stops match the pickup and dropoff
                if (!string.IsNullOrEmpty(r.IntermediateStops))
                {
                    try
                    {
                        var intermediateStops = System.Text.Json.JsonSerializer.Deserialize<List<string>>(r.IntermediateStops);
                        if (intermediateStops != null && intermediateStops.Any())
                        {
                            // Get all unique locations in order (pickup -> intermediate stops -> dropoff)
                            var allLocations = new List<string> { r.PickupLocation };
                            allLocations.AddRange(intermediateStops);
                            allLocations.Add(r.DropoffLocation);
                            
                            // Check if passenger's pickup and dropoff exist in sequence
                            int pickupIndex = -1;
                            int dropoffIndex = -1;
                            
                            for (int i = 0; i < allLocations.Count; i++)
                            {
                                if (pickupIndex == -1 && allLocations[i].Contains(pickupLocation, StringComparison.OrdinalIgnoreCase))
                                {
                                    pickupIndex = i;
                                }
                                if (dropoffIndex == -1 && allLocations[i].Contains(dropoffLocation, StringComparison.OrdinalIgnoreCase))
                                {
                                    dropoffIndex = i;
                                }
                            }
                            
                            // Pickup must come before dropoff in the route
                            return pickupIndex != -1 && dropoffIndex != -1 && pickupIndex < dropoffIndex;
                        }
                    }
                    catch
                    {
                        // If JSON parsing fails, ignore intermediate stops
                    }
                }
                
                return false;
            }).ToList();

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
