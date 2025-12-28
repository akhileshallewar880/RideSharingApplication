namespace RideSharing.API.Models.DTO
{
    // New detailed notification DTOs
    public class NotificationDetailDto
    {
        public Guid Id { get; set; }
        public string Type { get; set; }
        public string Title { get; set; }
        public string Message { get; set; }
        public string? Data { get; set; }
        public bool IsRead { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? ReadAt { get; set; }
    }

    public class CreateNotificationRequestDto
    {
        public string Type { get; set; }
        public string Title { get; set; }
        public string Message { get; set; }
        public string? Data { get; set; }
    }

    public class NotificationsResponseDto
    {
        public List<NotificationDetailDto> Notifications { get; set; }
        public int UnreadCount { get; set; }
        public PaginationDto Pagination { get; set; }
    }
    
    // Legacy support - keep old record
    public record NotificationDto(
        Guid Id,
        Guid? UserId,
        string Type,
        string Payload,
        DateTime? SentAt
    );
}
