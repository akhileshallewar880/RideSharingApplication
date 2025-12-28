namespace RideSharing.API.Models.DTO
{
    public record CreateRatingRequest(Guid BookingId, byte Rating, string? Comment = null);
    public record RatingDto(Guid Id, Guid BookingId, byte Rating, string? Comment, DateTime CreatedAt);
}
