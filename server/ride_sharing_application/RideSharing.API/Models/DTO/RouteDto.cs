using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.DTO
{
    public record RouteStopDto(
        [Range(0, int.MaxValue)] int StopOrder,
        [Required, MinLength(2)] string StopName,
        decimal? StopLat = null,
        decimal? StopLng = null
    );

    public record CreateRouteRequest(
        [Required] Guid DriverId,
        [Required, MinLength(2)] string RouteName,
        [Required, MinLength(2)] string Origin,
        [Required, MinLength(2)] string Destination,
        [Range(0, double.MaxValue)] decimal? DistanceKm,
        [Required, MinLength(1)] IEnumerable<RouteStopDto> Stops
    );

    public record RouteDto(
        [Required] Guid Id,
        [Required] Guid DriverId,
        [Required, MinLength(2)] string RouteName,
        [Required, MinLength(2)] string Origin,
        [Required, MinLength(2)] string Destination,
        [Range(0, double.MaxValue)] decimal? DistanceKm,
        [Required] IEnumerable<RouteStopDto> Stops
    );
}
