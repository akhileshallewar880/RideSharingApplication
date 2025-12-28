namespace RideSharing.API.Models.DTO
{
    public class VehicleDto
    {
        public Guid VehicleId { get; set; }
        public string VehicleType { get; set; }
        public string Make { get; set; }
        public string Model { get; set; }
        public int Year { get; set; }
        public string RegistrationNumber { get; set; }
        public string Color { get; set; }
        public int TotalSeats { get; set; }
        public string? FuelType { get; set; }
        public VehicleDocumentsDto Documents { get; set; }
        public List<string>? Features { get; set; }
    }

    public class UpdateVehicleDto
    {
        public string? Color { get; set; }
        public List<string>? Features { get; set; }
    }

    public class VehicleDocumentsDto
    {
        public DocumentInfoDto Registration { get; set; }
        public DocumentInfoDto Insurance { get; set; }
        public DocumentInfoDto Permit { get; set; }
    }

    public class DocumentInfoDto
    {
        public bool Verified { get; set; }
        public DateTime? ExpiryDate { get; set; }
    }

    public class UpdateVehicleResponseDto
    {
        public Guid VehicleId { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}
