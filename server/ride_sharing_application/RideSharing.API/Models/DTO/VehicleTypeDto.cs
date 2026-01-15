namespace RideSharing.API.Models.DTO
{
    public class VehicleTypeDto
    {
        public Guid Id { get; set; }
        public string Name { get; set; }
        public string DisplayName { get; set; }
        public string? Icon { get; set; }
        public string? Description { get; set; }
        public decimal BasePrice { get; set; }
        public decimal PricePerKm { get; set; }
        public decimal PricePerMinute { get; set; }
        public int MinSeats { get; set; }
        public int MaxSeats { get; set; }
        public bool IsActive { get; set; }
        public int DisplayOrder { get; set; }
        public string? Category { get; set; }
        public List<string>? Features { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }

    public class CreateVehicleTypeDto
    {
        public string Name { get; set; }
        public string DisplayName { get; set; }
        public string? Icon { get; set; }
        public string? Description { get; set; }
        public decimal BasePrice { get; set; }
        public decimal PricePerKm { get; set; }
        public decimal PricePerMinute { get; set; }
        public int MinSeats { get; set; }
        public int MaxSeats { get; set; }
        public bool IsActive { get; set; }
        public int DisplayOrder { get; set; }
        public string? Category { get; set; }
        public List<string>? Features { get; set; }
    }

    public class UpdateVehicleTypeDto
    {
        public string? Name { get; set; }
        public string? DisplayName { get; set; }
        public string? Icon { get; set; }
        public string? Description { get; set; }
        public decimal? BasePrice { get; set; }
        public decimal? PricePerKm { get; set; }
        public decimal? PricePerMinute { get; set; }
        public int? MinSeats { get; set; }
        public int? MaxSeats { get; set; }
        public bool? IsActive { get; set; }
        public int? DisplayOrder { get; set; }
        public string? Category { get; set; }
        public List<string>? Features { get; set; }
    }

    public class VehicleTypesResponseDto
    {
        public List<VehicleTypeDto> VehicleTypes { get; set; }
        public int Total { get; set; }
    }
}
