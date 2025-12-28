using System;
using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.DTO
{
    // New detailed profile DTOs
    public class UserProfileDetailDto
    {
        public Guid Id { get; set; }
        public string Name { get; set; }
        public string PhoneNumber { get; set; }
        public string? Email { get; set; }
        public string UserType { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public string? Address { get; set; }
        public string? EmergencyContact { get; set; }
        public string? ProfilePicture { get; set; }
        public bool IsVerified { get; set; }
        public decimal Rating { get; set; }
        public int TotalRides { get; set; }
        public DateTime CreatedAt { get; set; }
        public string? VerificationStatus { get; set; } // For driver verification: 'pending', 'approved', 'rejected'
    }

    public class UpdateUserProfileDto
    {
        public string? Name { get; set; }
        public string? Email { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public string? Address { get; set; }
        public string? EmergencyContact { get; set; }
    }

    public class ProfilePictureResponseDto
    {
        public string ProfilePicture { get; set; }
        public string ProfilePictureUrl { get; set; }
    }
    
    // Legacy support - keep old records
    public record UserProfileDto(
        [Required] Guid Id,
        [Required, Phone] string Phone,
        [MinLength(2)] string? Name,
        [EmailAddress] string? Email,
        [Required] string Role,
        bool IsActive
    );

    public record UpdateProfileRequest(
        [MinLength(2)] string? Name,
        [EmailAddress] string? Email
    );
}
