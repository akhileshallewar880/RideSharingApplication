using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.DTO
{
    public class AdminScheduleRideRequestDto
    {
        [Required]
        public Guid DriverId { get; set; }

        [Required]
        public LocationDto PickupLocation { get; set; } = null!;

        [Required]
        public LocationDto DropoffLocation { get; set; } = null!;

        public List<string>? IntermediateStops { get; set; }  // For backward compatibility - string addresses only
        
        public List<LocationDto>? IntermediateStopLocations { get; set; }  // New: Full location data with coordinates

        public List<SegmentPriceDto>? SegmentPrices { get; set; }

        [Required]
        public DateTime TravelDate { get; set; }

        [Required]
        public string DepartureTime { get; set; } = null!; // HH:mm format

        [Required]
        [Range(1, 50)]
        public int TotalSeats { get; set; }

        [Required]
        [Range(0.01, 100000)]
        public decimal PricePerSeat { get; set; }

        public Guid? VehicleModelId { get; set; }

        public bool ScheduleReturnTrip { get; set; }

        public string? ReturnDepartureTime { get; set; } // DateTime string for return trip

        [MaxLength(1000)]
        public string? AdminNotes { get; set; }
    }

    public class AdminUpdateRideRequestDto
    {
        public LocationDto? PickupLocation { get; set; }

        public LocationDto? DropoffLocation { get; set; }

        public List<string>? IntermediateStops { get; set; }

        public List<SegmentPriceDto>? SegmentPrices { get; set; }

        public DateTime? TravelDate { get; set; }

        public string? DepartureTime { get; set; } // HH:mm format

        [Range(1, 50)]
        public int? TotalSeats { get; set; }

        [Range(0.01, 100000)]
        public decimal? PricePerSeat { get; set; }

        [MaxLength(1000)]
        public string? AdminNotes { get; set; }
    }

    public class AdminCancelRideRequestDto
    {
        [Required]
        [MaxLength(500)]
        public string Reason { get; set; } = null!;

        public bool NotifyPassengers { get; set; } = true;
    }

    public class AdminScheduleRideResponseDto
    {
        public Guid RideId { get; set; }
        public string RideNumber { get; set; } = null!;
        public Guid DriverId { get; set; }
        public string DriverName { get; set; } = null!;
        public string PickupLocation { get; set; } = null!;
        public string DropoffLocation { get; set; } = null!;
        public DateTime TravelDate { get; set; }
        public string DepartureTime { get; set; } = null!;
        public int TotalSeats { get; set; }
        public int BookedSeats { get; set; }
        public int AvailableSeats { get; set; }
        public decimal PricePerSeat { get; set; }
        public string Status { get; set; } = null!;
        public DateTime CreatedAt { get; set; }
        public string? AdminNotes { get; set; }
        public Guid? ReturnRideId { get; set; }
        public string? ReturnRideNumber { get; set; }
    }

    public class AdminCancelRideResponseDto
    {
        public Guid RideId { get; set; }
        public string RideNumber { get; set; } = null!;
        public string Status { get; set; } = null!;
        public DateTime CancelledAt { get; set; }
        public string Reason { get; set; } = null!;
        public bool NotificationsSent { get; set; }
    }

    public class AdminDriverInfoDto
    {
        public Guid DriverId { get; set; }
        public string Name { get; set; } = null!;
        public string Phone { get; set; } = null!;
        public string LicenseNumber { get; set; } = null!;
        public string? VehicleNumber { get; set; }
        public string? VehicleModel { get; set; }
        public int VehicleSeats { get; set; }
        public bool IsAvailable { get; set; }
    }

    public class AdminRideInfoDto
    {
        public Guid RideId { get; set; }
        public string RideNumber { get; set; } = null!;
        public Guid DriverId { get; set; }
        public string DriverName { get; set; } = null!;
        public string PickupLocation { get; set; } = null!;
        public string DropoffLocation { get; set; } = null!;
        public DateTime TravelDate { get; set; }
        public string DepartureTime { get; set; } = null!;
        public int TotalSeats { get; set; }
        public int BookedSeats { get; set; }
        public int AvailableSeats { get; set; }
        public decimal PricePerSeat { get; set; }
        public string Status { get; set; } = null!;
        public string? VehicleNumber { get; set; }
        public string? VehicleModel { get; set; }
        public DateTime CreatedAt { get; set; }
        public string? AdminNotes { get; set; }
        public List<SegmentPriceDto>? SegmentPrices { get; set; }
        public List<string>? IntermediateStops { get; set; }
        public decimal? Distance { get; set; } // in kilometers
        public int? Duration { get; set; } // in minutes
        public decimal? PickupLatitude { get; set; }
        public decimal? PickupLongitude { get; set; }
        public decimal? DropoffLatitude { get; set; }
        public decimal? DropoffLongitude { get; set; }
    }

    public class CalculateRouteRequestDto
    {
        [Required]
        public List<RouteLocationDto> Locations { get; set; } = null!;
    }

    public class RouteLocationDto
    {
        public string? Name { get; set; }
        public decimal? Latitude { get; set; }
        public decimal? Longitude { get; set; }
    }
}
