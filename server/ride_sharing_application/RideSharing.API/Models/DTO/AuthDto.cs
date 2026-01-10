using System;
using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.DTO
{
    // New DTOs for OTP-based authentication
    public class SendOtpRequestDto
    {
        [Required]
        public string PhoneNumber { get; set; }
        public string CountryCode { get; set; } = "+91";
    }

    public class VerifyOtpRequestDto
    {
        [Required]
        public string PhoneNumber { get; set; }
        public string CountryCode { get; set; } = "+91";
        [Required]
        public string Otp { get; set; }
        [Required]
        public string OtpId { get; set; }
    }

    public class CompleteRegistrationDto
    {
        [Required]
        public string Name { get; set; }
        public string? Email { get; set; }
        [Required]
        public string UserType { get; set; } // passenger or driver
        public DateTime? DateOfBirth { get; set; }
        public string? Address { get; set; }
        public string? EmergencyContact { get; set; }
        
        // Driver-specific fields
        public string? CurrentCityId { get; set; }
        public string? CurrentCityName { get; set; }
        public string? VehicleModelId { get; set; }
        public string? VehicleNumber { get; set; }
    }

    public class RefreshTokenRequestDto
    {
        [Required]
        public string RefreshToken { get; set; }
    }

    public class SendOtpResponseDto
    {
        public string OtpId { get; set; }
        public int ExpiresIn { get; set; }
        public bool IsExistingUser { get; set; }
    }

    public class VerifyOtpResponseDto
    {
        public bool IsNewUser { get; set; }
        public string TempToken { get; set; }
        public string PhoneNumber { get; set; }
    }

    public class FirebasePhoneAuthRequestDto
    {
        [Required]
        public string FirebaseIdToken { get; set; }
        [Required]
        public string PhoneNumber { get; set; }
    }

    public class AuthResponseDto
    {
        public UserDto User { get; set; }
        public string AccessToken { get; set; }
        public string RefreshToken { get; set; }
    }

    public class TokenResponseDto
    {
        public string AccessToken { get; set; }
        public string RefreshToken { get; set; }
    }

    public class UserDto
    {
        public string UserId { get; set; }
        public string Name { get; set; }
        public string PhoneNumber { get; set; }
        public string? Email { get; set; }
        public string UserType { get; set; }
        public string? ProfilePicture { get; set; }
        public bool IsVerified { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class GoogleSignInRequestDto
    {
        [Required]
        public string IdToken { get; set; }
        
        [Required, EmailAddress]
        public string Email { get; set; }
        
        public string? Name { get; set; }
        
        public string? PhotoUrl { get; set; }
        
        [Phone]
        public string? PhoneNumber { get; set; } // Optional: Firebase-verified phone number
    }
    
    // Legacy support - keep old records
    public record SendOtpRequest(
        [Required, Phone] string Phone
    );

    public record SendOtpResponse(
        bool OtpSent
    );

    public record VerifyOtpRequest(
        [Required, Phone] string Phone,
        [Required, MinLength(4), MaxLength(8)] string Otp
    );

    public record VerifyOtpResponse(
        [Required] string AccessToken,
        [Required] Guid UserId,
        [Required] string Role
    );
}
