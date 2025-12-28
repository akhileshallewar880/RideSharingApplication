using System;
using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.DTO
{
    public record RegisterUserDto(
        [Required, MinLength(2)] string UserName,
        [Required, EmailAddress] string Email,
        [Required, MinLength(6)] string Password,
        [Required] string Role
    );
}
