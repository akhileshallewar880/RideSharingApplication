using RideSharing.API.Models.Domain;

namespace RideSharing.API.Repositories.Interface
{
    public interface IUserRepository
    {
        Task<User?> GetUserByIdAsync(Guid id);
        Task<UserProfile?> GetUserProfileAsync(Guid userId);
        Task<UserProfile> UpdateUserProfileAsync(UserProfile profile);
        Task<string> UploadProfilePictureAsync(Guid userId, Stream fileStream, string fileName);
    }
}
