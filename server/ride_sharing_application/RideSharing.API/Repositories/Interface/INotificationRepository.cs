using RideSharing.API.Models.Domain;

namespace RideSharing.API.Repositories.Interface
{
    public interface INotificationRepository
    {
        Task<List<Notification>> GetUserNotificationsAsync(Guid userId, bool? unreadOnly, int page, int limit);
        Task<int> GetUnreadCountAsync(Guid userId);
        Task<bool> MarkAsReadAsync(Guid notificationId);
        Task<bool> MarkAllAsReadAsync(Guid userId);
        Task<Notification> CreateNotificationAsync(Notification notification);
        Task UpdateFCMTokenAsync(Guid userId, string fcmToken);
    }
}
