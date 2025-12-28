using RideSharing.API.Models.Domain;
using RideSharing.API.Models.DTO;

namespace RideSharing.API.Repositories.Interface
{
    public interface IRideRepository
    {
        Task<List<Ride>> SearchAvailableRidesAsync(
            string pickupLocation,
            string dropoffLocation,
            DateTime travelDate,
            int passengerCount,
            string? vehicleType);
        
        Task<Ride?> GetRideByIdAsync(Guid rideId);
        Task<Booking> CreateBookingAsync(Booking booking);
        Task<Booking?> GetBookingByIdAsync(Guid bookingId);
        Task<List<Booking>> GetUserBookingsAsync(Guid userId, string? status, int page, int limit);
        Task<Booking> UpdateBookingAsync(Booking booking);
        Task<bool> CancelBookingAsync(Guid bookingId, string reason, string cancellationType);
        Task<Rating> CreateRatingAsync(Rating rating);
    }
}
