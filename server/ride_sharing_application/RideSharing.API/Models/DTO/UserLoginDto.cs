using System;
using System.ComponentModel.DataAnnotations;

namespace RideSharing.API.Models.DTO;

public class UserLoginDto
{
    [Required, EmailAddress] public string UserName { get; set; }
    [Required, MinLength(6)] public string Password { get; set; }
}
