using System;
using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.DTO
{
    public record DriverOnboardRequest(
        [Required] Guid UserId,
        [Required, MinLength(2)] string VehicleNumber,
        [Required, MinLength(2)] string VehicleType,
        [Range(1, 100)] int SeatingCapacity,
        string? KycDocUrl
    );

    public record DriverDto(
        [Required] Guid Id,
        [Required] Guid UserId,
        [Required, MinLength(2)] string VehicleNumber,
        [Required, MinLength(2)] string VehicleType,
        [Range(1, 100)] int SeatingCapacity,
        [Required] string KycStatus
    );
}
