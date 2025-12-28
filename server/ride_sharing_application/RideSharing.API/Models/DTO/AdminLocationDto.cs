namespace RideSharing.API.Models.DTO
{
    public class AdminLocationDto
    {
        public Guid Id { get; set; }
        public string Name { get; set; }
        public string State { get; set; }
        public string District { get; set; }
        public string? SubLocation { get; set; }
        public string? Pincode { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }

    public class CreateLocationRequest
    {
        public string Name { get; set; }
        public string State { get; set; }
        public string District { get; set; }
        public string? SubLocation { get; set; }
        public string? Pincode { get; set; }
        public double Latitude { get; set; }
        public double Longitude { get; set; }
    }

    public class UpdateLocationRequest
    {
        public string? Name { get; set; }
        public string? State { get; set; }
        public string? District { get; set; }
        public string? SubLocation { get; set; }
        public string? Pincode { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public bool? IsActive { get; set; }
    }
}
