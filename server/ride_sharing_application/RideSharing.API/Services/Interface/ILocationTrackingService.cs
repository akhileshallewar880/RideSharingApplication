using RideSharing.API.Models.Domain;
using RideSharing.API.Models.DTO;

namespace RideSharing.API.Services.Interface
{
    /// <summary>
    /// Service interface for location tracking operations
    /// </summary>
    public interface ILocationTrackingService
    {
        Task<LocationTracking> SaveLocationUpdateAsync(
            Guid rideId,
            Guid driverId,
            decimal latitude,
            decimal longitude,
            decimal speed,
            decimal heading,
            decimal accuracy);

        Task<LocationHistoryResponse> GetLocationHistoryAsync(Guid rideId, DateTime? startTime = null, DateTime? endTime = null, int limit = 100);
        
        Task<LocationTracking?> GetLatestLocationAsync(Guid rideId);
        
        Task<RideMetricsDto?> CalculateRideMetricsAsync(Guid rideId);
        
        Task<LiveTrackingStatusDto?> GetLiveTrackingStatusAsync(Guid rideId, Guid? passengerId = null);
        
        Task<double> CalculateDistanceAsync(decimal lat1, decimal lon1, decimal lat2, decimal lon2);
        
        Task CleanupOldLocationDataAsync(int daysToKeep = 30);
    }
}
