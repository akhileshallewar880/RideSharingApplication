namespace RideSharing.API.Models.DTO
{
    // Request DTOs
    public class SearchRidesRequestDto
    {
        public LocationDto PickupLocation { get; set; }
        public LocationDto DropoffLocation { get; set; }
        public DateTime TravelDate { get; set; }
        public int PassengerCount { get; set; }
        public string? VehicleType { get; set; }
    }

    public class BookRideRequestDto
    {
        public Guid RideId { get; set; }
        public int PassengerCount { get; set; }
        public LocationDto PickupLocation { get; set; }
        public LocationDto DropoffLocation { get; set; }
        public string PaymentMethod { get; set; } // cash, upi, card, wallet
        public List<string>? SelectedSeats { get; set; } // ["P1", "P2", "P5"]
    }

    public class CancelRideRequestDto
    {
        public string Reason { get; set; }
        public string CancellationType { get; set; }
    }

    public class RescheduleRideRequestDto
    {
        public Guid NewRideId { get; set; }
        public DateTime NewTravelDate { get; set; }
        public string NewDepartureTime { get; set; }
    }

    public class RateRideRequestDto
    {
        public int Rating { get; set; }
        public string? Review { get; set; }
        public Guid DriverId { get; set; }
    }

    // Response DTOs
    public class SearchRidesResponseDto
    {
        public List<AvailableRideDto> AvailableRides { get; set; }
    }

    public class RideStopWithTimeDto
    {
        public string Location { get; set; }
        public string ArrivalTime { get; set; } // HH:mm format
        public int CumulativeDurationMinutes { get; set; }
    }

    public class AvailableRideDto
    {
        public Guid RideId { get; set; }
        public Guid DriverId { get; set; }
        public string DriverName { get; set; }
        public decimal DriverRating { get; set; }
        public int DriverRatingCount { get; set; }
        public string VehicleType { get; set; }
        public string VehicleModel { get; set; }
        public string VehicleNumber { get; set; }
        public int VehicleSeatingCapacity { get; set; }
        public int TotalSeats { get; set; }
        public int AvailableSeats { get; set; }
        public string DepartureTime { get; set; }
        public decimal PricePerSeat { get; set; }
        public decimal TotalPrice { get; set; }
        public string EstimatedDuration { get; set; }
        public decimal Distance { get; set; }
        public string PickupLocation { get; set; }
        public string DropoffLocation { get; set; }
        public List<string>? IntermediateStops { get; set; }
        public List<RideStopWithTimeDto>? RouteStopsWithTiming { get; set; }
        public string? SeatingLayout { get; set; } // JSON string with seat configuration
        public List<string>? BookedSeats { get; set; } // List of already booked seat IDs
    }

    public class BookingResponseDto
    {
        public Guid BookingId { get; set; }
        public Guid RideId { get; set; }
        public string BookingNumber { get; set; }
        public string Status { get; set; }
        public string Otp { get; set; }
        public string? QrCode { get; set; }
        public string PickupLocation { get; set; }
        public string DropoffLocation { get; set; }
        public DateTime TravelDate { get; set; }
        public string DepartureTime { get; set; }
        public int PassengerCount { get; set; }
        public decimal TotalFare { get; set; }
        public List<string>? SelectedSeats { get; set; }
        public string? SeatingArrangementImage { get; set; }
        public DriverDetailsDto DriverDetails { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class BookingDetailsDto
    {
        public Guid BookingId { get; set; }
        public string BookingNumber { get; set; }
        public string Status { get; set; }
        public string Otp { get; set; }
        public string? QrCode { get; set; }
        public string PickupLocation { get; set; }
        public string DropoffLocation { get; set; }
        public DateTime TravelDate { get; set; }
        public string DepartureTime { get; set; }
        public int PassengerCount { get; set; }
        public decimal TotalFare { get; set; }
        public string PaymentStatus { get; set; }
        public List<string>? SelectedSeats { get; set; }
        public string? SeatingArrangementImage { get; set; }
        public DriverDetailsDto DriverDetails { get; set; }
        public TrackingStatusDto? TrackingStatus { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class RideHistoryDto
    {
        public List<RideHistoryItemDto> Rides { get; set; }
        public PaginationDto Pagination { get; set; }
    }

    public class RideHistoryItemDto
    {
        public Guid BookingId { get; set; }
        public string BookingNumber { get; set; }
        public string PickupLocation { get; set; }
        public string DropoffLocation { get; set; }
        public DateTime Date { get; set; }
        public string TimeSlot { get; set; }
        public string VehicleType { get; set; }
        public string VehicleModel { get; set; }
        public string VehicleNumber { get; set; }
        public decimal Fare { get; set; }
        public string Status { get; set; }
        public int PassengerCount { get; set; }
        public string DriverName { get; set; }
        public Guid? DriverId { get; set; }
        public string? DriverPhoneNumber { get; set; }
        public decimal DriverRating { get; set; }
        public int? PassengerRating { get; set; } // The rating given by passenger for this specific ride
        public string Otp { get; set; }
        public DateTime? CompletedAt { get; set; }
        public bool IsVerified { get; set; }
        public Guid? RideId { get; set; }
        public List<string>? IntermediateStops { get; set; }
        public List<string>? SelectedSeats { get; set; }
        public string? SeatingArrangementImage { get; set; }
    }

    public class CancelRideResponseDto
    {
        public Guid BookingId { get; set; }
        public string Status { get; set; }
        public decimal RefundAmount { get; set; }
        public string RefundStatus { get; set; }
        public DateTime CancelledAt { get; set; }
    }

    public class RescheduleRideResponseDto
    {
        public Guid BookingId { get; set; }
        public DateTime NewTravelDate { get; set; }
        public string NewDepartureTime { get; set; }
        public DateTime UpdatedAt { get; set; }
    }

    public class RateRideResponseDto
    {
        public Guid BookingId { get; set; }
        public int Rating { get; set; }
        public string? Review { get; set; }
        public DateTime RatedAt { get; set; }
    }

    // Helper DTOs
    public class LocationDto
    {
        public string Address { get; set; }
        public decimal Latitude { get; set; }
        public decimal Longitude { get; set; }
    }

    public class DriverDetailsDto
    {
        public Guid Id { get; set; }
        public string Name { get; set; }
        public string PhoneNumber { get; set; }
        public decimal Rating { get; set; }
        public string VehicleModel { get; set; }
        public string VehicleNumber { get; set; }
        public string? ProfilePicture { get; set; }
    }

    public class TrackingStatusDto
    {
        public string CurrentStatus { get; set; }
        public string EstimatedArrival { get; set; }
        public LocationDto? DriverLocation { get; set; }
    }

    public class PaginationDto
    {
        public int CurrentPage { get; set; }
        public int TotalPages { get; set; }
        public int TotalItems { get; set; }
        public int ItemsPerPage { get; set; }
    }
}
