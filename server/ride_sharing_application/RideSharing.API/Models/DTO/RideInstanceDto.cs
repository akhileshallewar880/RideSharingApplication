using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.DTO
{
    public record RideInstanceDto(
        [Required] Guid Id,
        [Required] Guid TemplateId,
        [Required] DateTime RideDate,
        [Required] DateTime DepartureDateTime,
        [Range(1, 100)] int TotalSeats,
        [Range(0, 100)] int RemainingSeats,
        [Required] string Status
    );

    public record SearchRidesRequest(
        [Required, MinLength(2)] string Origin,
        [Required, MinLength(2)] string Destination,
        DateTime? Date = null
    );

    public record SearchRidesResponse(
        [Required] IEnumerable<RideInstanceDto> Rides
    );
}
