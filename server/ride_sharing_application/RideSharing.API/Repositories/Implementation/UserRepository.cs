using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;
using RideSharing.API.Models.Domain;
using RideSharing.API.Repositories.Interface;

namespace RideSharing.API.Repositories.Implementation
{
    public class UserRepository : IUserRepository
    {
        private readonly RideSharingDbContext _context;

        public UserRepository(RideSharingDbContext context)
        {
            _context = context;
        }

        public async Task<User?> GetUserByIdAsync(Guid id)
        {
            return await _context.Users
                .Include(u => u.Profile)
                .FirstOrDefaultAsync(u => u.Id == id);
        }

        public async Task<UserProfile?> GetUserProfileAsync(Guid userId)
        {
            return await _context.UserProfiles
                .Include(p => p.User) // Include User to get UserType
                .FirstOrDefaultAsync(p => p.UserId == userId);
        }

        public async Task<UserProfile> UpdateUserProfileAsync(UserProfile profile)
        {
            profile.UpdatedAt = DateTime.UtcNow;
            _context.UserProfiles.Update(profile);
            await _context.SaveChangesAsync();
            return profile;
        }

        public async Task<string> UploadProfilePictureAsync(Guid userId, Stream fileStream, string fileName)
        {
            // TODO: Implement actual file upload logic (e.g., to Azure Blob Storage, AWS S3, or local storage)
            // For now, return a placeholder URL
            var profilePictureUrl = $"https://cdn.example.com/profiles/{userId}/{fileName}";
            
            var profile = await GetUserProfileAsync(userId);
            if (profile != null)
            {
                profile.ProfilePicture = profilePictureUrl;
                profile.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }

            return profilePictureUrl;
        }
    }
}
