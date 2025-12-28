using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.DTO
{
    public record CreateBookingRequest(
        [Required] Guid RideInstanceId,
        [Required] Guid PassengerUserId,
        [Range(1, 10)] int Seats = 1,
        bool PayNow = true,
        string? PaymentMethod = null
    );

    public record CreateBookingResponse(
        [Required] Guid BookingId,
        [Required] string Status,
        [Range(0, double.MaxValue)] decimal Amount,
        string? PaymentUrl
    );

    public record BookingDto(
        [Required] Guid Id,
        [Required] Guid RideInstanceId,
        [Required] Guid PassengerUserId,
        [Range(1, 10)] int SeatsBooked,
        [Required] string Status,
        [Required] DateTime CreatedAt
    );

    public record CancelBookingRequest(
        [Required] Guid BookingId,
        [Required] Guid CancelledByUserId,
        string? Reason = null
    );

    public record CancelBookingResponse(
        bool Cancelled,
        string? RefundStatus = null
    );
}
