namespace RideSharing.API.Models.DTO
{
    // Request DTOs
    public class SearchVehicleModelsRequestDto
    {
        public string? Query { get; set; }
        public string? Type { get; set; } // car, suv, van, bus
        public bool? Active { get; set; }
    }

    public class CreateVehicleModelDto
    {
        public string Name { get; set; }
        public string Brand { get; set; }
        public string Type { get; set; }
        public int SeatingCapacity { get; set; }
        public string? SeatingLayout { get; set; }
        public string? ImageUrl { get; set; }
        public List<string>? Features { get; set; }
        public string? Description { get; set; }
        public bool IsActive { get; set; } = true;
    }

    public class UpdateVehicleModelDto
    {
        public string Name { get; set; }
        public string Brand { get; set; }
        public string Type { get; set; }
        public int SeatingCapacity { get; set; }
        public string? SeatingLayout { get; set; }
        public string? ImageUrl { get; set; }
        public List<string>? Features { get; set; }
        public string? Description { get; set; }
        public bool IsActive { get; set; }
    }

    // Response DTOs
    public class VehicleModelDto
    {
        public Guid Id { get; set; }
        public string Name { get; set; }
        public string Brand { get; set; }
        public string Type { get; set; }
        public int SeatingCapacity { get; set; }
        public string? SeatingLayout { get; set; }
        public string? ImageUrl { get; set; }
        public List<string>? Features { get; set; }
        public string? Description { get; set; }
        public bool IsActive { get; set; }
    }

    public class VehicleModelsResponseDto
    {
        public List<VehicleModelDto> Vehicles { get; set; }
        public int Total { get; set; }
    }
}
