namespace RideSharing.API.Models.DTO
{
    /// <summary>
    /// Per-stop cumulative timing data stored in Ride.RouteStopsTimingJson at schedule time
    /// </summary>
    public class RouteStopTimingData
    {
        public string Location { get; set; } = string.Empty;
        public double CumulativeDistanceKm { get; set; }
        public int CumulativeDurationMinutes { get; set; }
    }

    // Request DTOs
    public class SegmentPriceDto
    {
        public string FromLocation { get; set; } = string.Empty;
        public string ToLocation { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public decimal SuggestedPrice { get; set; }
        public bool IsOverridden { get; set; }
    }

    public class ScheduleRideRequestDto
    {
        public LocationDto PickupLocation { get; set; }
        public LocationDto DropoffLocation { get; set; }
        public List<string>? IntermediateStops { get; set; } // NEW
        public DateTime TravelDate { get; set; }
        public string DepartureTime { get; set; }
        public string? VehicleType { get; set; } // Optional - will use from registered vehicle if not provided
        public Guid? VehicleModelId { get; set; } // NEW
        public int TotalSeats { get; set; }
        public decimal PricePerSeat { get; set; }
        public string? Route { get; set; }
        public bool ScheduleReturnTrip { get; set; } // NEW
        public string? ReturnDepartureTime { get; set; } // NEW - ISO format datetime string
        public List<SegmentPriceDto>? SegmentPrices { get; set; } // NEW - Segment-based pricing
    }

    public class StartTripRequestDto
    {
        public LocationDto StartLocation { get; set; }
        public DateTime ActualDepartureTime { get; set; }
    }

    public class VerifyOtpDto
    {
        public string Otp { get; set; }
    }

    public class VerifyQrCodeDto
    {
        public string QrData { get; set; }
    }

    public class CompleteTripRequestDto
    {
        public LocationDto EndLocation { get; set; }
        public DateTime ActualArrivalTime { get; set; }
        public decimal ActualDistance { get; set; }
    }

    public class CancelScheduledRideRequestDto
    {
        public string Reason { get; set; }
        public bool NotifyPassengers { get; set; }
    }

    // Response DTOs
    public class ScheduleRideResponseDto
    {
        public Guid RideId { get; set; }
        public string RideNumber { get; set; }
        public string PickupLocation { get; set; }
        public string DropoffLocation { get; set; }
        public DateTime TravelDate { get; set; }
        public string DepartureTime { get; set; }
        public int TotalSeats { get; set; }
        public int BookedSeats { get; set; }
        public int AvailableSeats { get; set; }
        public decimal PricePerSeat { get; set; }
        public string Status { get; set; }
        public DateTime CreatedAt { get; set; }
        public Guid? ReturnRideId { get; set; } // NEW
        public string? ReturnRideNumber { get; set; } // NEW
        public List<SegmentPriceDto>? SegmentPrices { get; set; } // NEW
    }

    public class DriverRidesResponseDto
    {
        public List<DriverRideDto> Rides { get; set; }
        public PaginationDto Pagination { get; set; }
    }

    public class DriverRideDto
    {
        public Guid RideId { get; set; }
        public string RideNumber { get; set; }
        public string PickupLocation { get; set; }
        public string DropoffLocation { get; set; }
        public List<string>? IntermediateStops { get; set; } // NEW
        public string Date { get; set; } // Changed from DateTime to string for formatted date (DD-MM-YYYY)
        public string DepartureTime { get; set; }
        public int TotalSeats { get; set; }
        public int BookedSeats { get; set; }
        public int AvailableSeats { get; set; }
        public decimal PricePerSeat { get; set; }
        public decimal EstimatedEarnings { get; set; }
        public string VehicleType { get; set; }
        public Guid? VehicleModelId { get; set; } // NEW
        public string Status { get; set; }
        public Guid? LinkedReturnRideId { get; set; } // NEW
        public bool IsReturnTrip { get; set; } // NEW: indicates if this is a return trip
        public List<SegmentPriceDto>? SegmentPrices { get; set; } // NEW
        public List<PassengerInfoDto>? Passengers { get; set; }
        public decimal? Distance { get; set; } // in kilometers
        public int? Duration { get; set; } // in minutes
    }

    public class DriverRideDetailsDto
    {
        public Guid RideId { get; set; }
        public string RideNumber { get; set; }
        public string PickupLocation { get; set; }
        public string DropoffLocation { get; set; }
        public decimal PickupLatitude { get; set; }
        public decimal PickupLongitude { get; set; }
        public decimal DropoffLatitude { get; set; }
        public decimal DropoffLongitude { get; set; }
        public List<string>? IntermediateStops { get; set; }
        public DateTime Date { get; set; }
        public string DepartureTime { get; set; }
        public int TotalSeats { get; set; }
        public int BookedSeats { get; set; }
        public int AvailableSeats { get; set; }
        public decimal PricePerSeat { get; set; }
        public decimal EstimatedEarnings { get; set; }
        public string VehicleType { get; set; }
        public string Status { get; set; }
        public bool CanStartTrip { get; set; }
        public int MinutesUntilDeparture { get; set; }
        public List<PassengerInfoDto> Passengers { get; set; }
        public RouteInfoDto? Route { get; set; }
        public decimal? Distance { get; set; } // in kilometers
        public int? Duration { get; set; } // in minutes
        public List<decimal>? SegmentDistances { get; set; } // distances for each segment in kilometers
    }

    public class StartTripResponseDto
    {
        public Guid RideId { get; set; }
        public string Status { get; set; }
        public DateTime StartedAt { get; set; }
        public int DelayMinutes { get; set; }
        public Guid TrackingId { get; set; }
    }

    public class VerifyPassengerResponseDto
    {
        public Guid BookingId { get; set; }
        public string PassengerName { get; set; }
        public int SeatNumber { get; set; }
        public bool IsVerified { get; set; }
        public DateTime VerifiedAt { get; set; }
    }

    public class CompleteTripResponseDto
    {
        public Guid RideId { get; set; }
        public string Status { get; set; }
        public DateTime CompletedAt { get; set; }
        public decimal TotalEarnings { get; set; }
        public string Duration { get; set; }
        public decimal Distance { get; set; }
    }

    public class CancelScheduledRideResponseDto
    {
        public Guid RideId { get; set; }
        public string Status { get; set; }
        public DateTime CancelledAt { get; set; }
        public int AffectedPassengers { get; set; }
    }

    // Helper DTOs
    public class PassengerInfoDto
    {
        public Guid? BookingId { get; set; }
        public Guid PassengerId { get; set; }
        public string Name { get; set; }
        public string PhoneNumber { get; set; }
        public int SeatNumber { get; set; }
        public int PassengerCount { get; set; }
        public string? Otp { get; set; }
        public bool IsVerified { get; set; }
        public string? PickupLocation { get; set; }
        public string? DropoffLocation { get; set; }
        public decimal? PickupLatitude { get; set; }
        public decimal? PickupLongitude { get; set; }
        public decimal? DropoffLatitude { get; set; }
        public decimal? DropoffLongitude { get; set; }
        public decimal TotalFare { get; set; }
        public decimal TotalAmount { get; set; }
        public string PaymentStatus { get; set; }
        public string BoardingStatus { get; set; }
    }

    public class RouteInfoDto
    {
        public decimal Distance { get; set; }
        public string Duration { get; set; }
        public List<object>? Waypoints { get; set; }
    }

    public class DriverCancelRideResponseDto
    {
        public Guid RideId { get; set; }
        public string Status { get; set; }
        public DateTime CancelledAt { get; set; }
    }

    public class UpdateRidePriceDto
    {
        public decimal PricePerSeat { get; set; }
    }

    public class UpdateRidePriceResponseDto
    {
        public Guid RideId { get; set; }
        public decimal PricePerSeat { get; set; }
        public DateTime UpdatedAt { get; set; }
    }

    public class UpdateSegmentPricesDto
    {
        public List<SegmentPriceDto> SegmentPrices { get; set; }
    }

    public class UpdateSegmentPricesResponseDto
    {
        public Guid RideId { get; set; }
        public List<SegmentPriceDto> SegmentPrices { get; set; }
        public DateTime UpdatedAt { get; set; }
    }

    public class UpdateRideScheduleDto
    {
        public string Date { get; set; } // dd-MM-yyyy format
        public string DepartureTime { get; set; } // HH:mm format
    }

    public class UpdateRideScheduleResponseDto
    {
        public Guid RideId { get; set; }
        public string Date { get; set; }
        public string DepartureTime { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}
