namespace RideSharing.API.Models.DTO
{
    // Legacy support
    public record CreatePayoutRequest(Guid DriverId, DateTime PeriodStart, DateTime PeriodEnd);
    public record PayoutDtoLegacy(Guid Id, Guid DriverId, decimal Amount, string Status, DateTime CreatedAt);
}
