using System;
using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.DTO
{
    public record PaymentInitiateRequest(
        [Required] Guid BookingId,
        [Range(0, double.MaxValue)] decimal Amount,
        [Required] string Method,
        [Required] string ReturnUrl
    );

    public record PaymentInitiateResponse(
        [Required] string ProviderPaymentId,
        [Required] string PaymentUrl
    );

    public record PaymentWebhookDto(
        [Required] string Provider,
        [Required] string ProviderTransactionId,
        [Required] Guid BookingId,
        [Range(0, double.MaxValue)] decimal Amount,
        [Required] string Status
    );

    public record PaymentDto(
        [Required] Guid Id,
        [Required] Guid BookingId,
        [Range(0, double.MaxValue)] decimal Amount,
        [Required] string Method,
        [Required] string Status,
        [Required] DateTime CreatedAt
    );
}
