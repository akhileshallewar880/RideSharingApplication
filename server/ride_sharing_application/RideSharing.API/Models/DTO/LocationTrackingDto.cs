namespace RideSharing.API.Models.DTO
{
    /// <summary>
    /// DTO for location tracking data
    /// </summary>
    public class LocationTrackingDto
    {
        public Guid Id { get; set; }
        public Guid RideId { get; set; }
        public Guid DriverId { get; set; }
        public decimal Latitude { get; set; }
        public decimal Longitude { get; set; }
        public decimal Speed { get; set; }
        public decimal Heading { get; set; }
        public decimal Accuracy { get; set; }
        public DateTime Timestamp { get; set; }
    }

    /// <summary>
    /// Request DTO for saving location update
    /// </summary>
    public class SaveLocationUpdateRequest
    {
        public Guid RideId { get; set; }
        public decimal Latitude { get; set; }
        public decimal Longitude { get; set; }
        public decimal Speed { get; set; }
        public decimal Heading { get; set; }
        public decimal Accuracy { get; set; }
    }

    /// <summary>
    /// Response with location history for a ride
    /// </summary>
    public class LocationHistoryResponse
    {
        public Guid RideId { get; set; }
        public List<LocationTrackingDto> Locations { get; set; } = new();
        public int TotalCount { get; set; }
        public double TotalDistanceKm { get; set; }
        public DateTime? FirstLocation { get; set; }
        public DateTime? LastLocation { get; set; }
    }

    /// <summary>
    /// Ride metrics calculated from location data
    /// </summary>
    public class RideMetricsDto
    {
        public Guid RideId { get; set; }
        public decimal? CurrentLatitude { get; set; }
        public decimal? CurrentLongitude { get; set; }
        public decimal? CurrentSpeed { get; set; }
        public double? RemainingDistanceKm { get; set; }
        public int? EstimatedArrivalMinutes { get; set; }
        public double? AverageSpeedKmh { get; set; }
        public double? TotalDistanceCoveredKm { get; set; }
        public DateTime? LastUpdateTime { get; set; }
    }

    /// <summary>
    /// Live tracking status for passengers
    /// </summary>
    public class LiveTrackingStatusDto
    {
        public Guid RideId { get; set; }
        public string Status { get; set; } = string.Empty;
        public LocationTrackingDto? CurrentLocation { get; set; }
        public double? DistanceToPickup { get; set; }
        public int? EtaToPickup { get; set; }
        public double? DistanceToDropoff { get; set; }
        public int? EtaToDropoff { get; set; }
        public DateTime? LastUpdated { get; set; }
        public bool IsDriverOnline { get; set; }
    }

    /// <summary>
    /// Request to get location updates within a time range
    /// </summary>
    public class LocationHistoryRequest
    {
        public Guid RideId { get; set; }
        public DateTime? StartTime { get; set; }
        public DateTime? EndTime { get; set; }
        public int? Limit { get; set; } = 100;
    }
}
