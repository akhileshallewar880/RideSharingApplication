using System;
using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.DTO
{
    public record CreateScheduleTemplateRequest(
        [Required] Guid RouteId,
        [Range(1, 127)] byte DaysOfWeekMask,
        [Required] TimeSpan DepartureTime,
        [Range(1, 100)] int Capacity,
        [Range(0, double.MaxValue)] decimal PricePerSeat,
        bool IsAutoConfirm = true
    );

    public record ScheduleTemplateDto(
        [Required] Guid Id,
        [Required] Guid RouteId,
        [Range(1, 127)] byte DaysOfWeekMask,
        [Required] TimeSpan DepartureTime,
        [Range(1, 100)] int Capacity,
        [Range(0, double.MaxValue)] decimal PricePerSeat,
        bool IsAutoConfirm
    );
}
