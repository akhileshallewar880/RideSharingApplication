using RideSharing.API.Models.Domain;

namespace RideSharing.API.Repositories.Interface
{
    public interface IDriverRepository
    {
        // Ride Management
        Task<Ride> CreateRideAsync(Ride ride);
        Task<List<Ride>> GetDriverRidesAsync(Guid driverId, string? status, int page, int limit);
        Task<Ride?> GetRideWithBookingsAsync(Guid rideId);
        Task<Ride> UpdateRideAsync(Ride ride);
        Task<bool> StartTripAsync(Guid rideId, DateTime actualDepartureTime);
        Task<Booking?> VerifyPassengerOTPAsync(Guid rideId, string otp);
        Task<bool> CompleteTripAsync(Guid rideId, DateTime actualArrivalTime, decimal actualDistance);
        Task<bool> CancelRideAsync(Guid rideId, string reason);
        
        // Dashboard & Earnings
        Task<Driver?> GetDriverByUserIdAsync(Guid userId);
        Task<Driver> UpdateDriverAsync(Driver driver);
        Task<decimal> GetTodayEarningsAsync(Guid driverId);
        Task<int> GetTodayRidesCountAsync(Guid driverId);
        Task<List<Payment>> GetDriverEarningsAsync(Guid driverId, DateTime startDate, DateTime endDate);
        Task<List<Payout>> GetDriverPayoutsAsync(Guid driverId, int page, int limit);
        Task<Payout> RequestPayoutAsync(Payout payout);
        Task<bool> UpdateDriverOnlineStatusAsync(Guid driverId, bool isOnline);
        
        // Vehicle Management
        Task<Vehicle?> GetDriverVehicleAsync(Guid driverId);
        Task<Vehicle> UpdateVehicleAsync(Vehicle vehicle);
    }
}
