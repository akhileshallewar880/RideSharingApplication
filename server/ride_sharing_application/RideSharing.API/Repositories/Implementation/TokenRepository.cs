using System;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Identity;
using Microsoft.IdentityModel.Tokens;
using RideSharing.API.Repositories.Interface;

namespace RideSharing.API.Repositories.Implementation;

public class TokenRepository : ITokenRepository
{
    private readonly IConfiguration configuration;
    public TokenRepository(IConfiguration configuration)
    {
        this.configuration = configuration;
    }
    public string CreateJwtToken(IdentityUser user, List<string> roles)
    {
        // Implementation for creating JWT token
        // Create Claims from user and roles
        var claimms = new List<Claim>();
            if (!string.IsNullOrWhiteSpace(user.Email))
            {
                claimms.Add(new Claim(ClaimTypes.Email, user.Email));
            }
            // Always include user id
            claimms.Add(new Claim(ClaimTypes.NameIdentifier, user.Id));

            foreach (var role in roles)
            {
                claimms.Add(new Claim(ClaimTypes.Role, role));
            }

            // Note: appsettings uses 'secretKey' (lowercase 's'); ensure we read the correct key
            var secret = configuration["JwtSettings:secretKey"] ?? configuration["JwtSettings:SecretKey"];
            if (string.IsNullOrWhiteSpace(secret))
            {
                throw new InvalidOperationException("JWT secret key is not configured. Set JwtSettings:secretKey.");
            }
            var key = new SymmetricSecurityKey(System.Text.Encoding.UTF8.GetBytes(secret));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var token = new System.IdentityModel.Tokens.Jwt.JwtSecurityToken(
                
                issuer: configuration["JwtSettings:validIssuer"],
                audience: configuration["JwtSettings:validAudience"],
                claims: claimms,
                expires: DateTime.Now.AddHours(3),
                signingCredentials: creds
            );
            // Generate Token
            return new JwtSecurityTokenHandler().WriteToken(token);
    }

    public string CreateJwtToken(Guid userId, string phoneNumber, List<string> roles)
    {
        // Create Claims from userId, phoneNumber and roles
        var claims = new List<Claim>
        {
            new Claim("userId", userId.ToString()),
            new Claim("phoneNumber", phoneNumber),
            new Claim(ClaimTypes.NameIdentifier, userId.ToString())
        };

        foreach (var role in roles)
        {
            claims.Add(new Claim(ClaimTypes.Role, role));
        }

        var secret = configuration["JwtSettings:secretKey"] ?? configuration["JwtSettings:SecretKey"];
        if (string.IsNullOrWhiteSpace(secret))
        {
            throw new InvalidOperationException("JWT secret key is not configured. Set JwtSettings:secretKey.");
        }
        var key = new SymmetricSecurityKey(System.Text.Encoding.UTF8.GetBytes(secret));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: configuration["JwtSettings:validIssuer"],
            audience: configuration["JwtSettings:validAudience"],
            claims: claims,
            expires: DateTime.Now.AddHours(3),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
