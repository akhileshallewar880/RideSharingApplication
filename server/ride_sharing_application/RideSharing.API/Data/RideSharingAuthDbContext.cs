using System;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace RideSharing.API.Data;

public class RideSharingAuthDbContext : IdentityDbContext
{
    public RideSharingAuthDbContext(DbContextOptions<RideSharingAuthDbContext> options) : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);
        // Further customization of the model can be done here
        var passengerRoleId = "acd23580-0924-4c76-902d-d2704b924df6";
        var driverRoleId = "6e5fd24c-6986-4b49-8b64-6de2814e8fcd";
        var adminRoleId = "363b8955-eb40-43a1-9e06-3cab627affa5";

        var roles = new List<IdentityRole>
        {
            new IdentityRole
            {
                Id = passengerRoleId,
                Name = "Passenger",
                NormalizedName = "PASSENGER",
                ConcurrencyStamp = passengerRoleId
            },
            new IdentityRole
            {
                Id = driverRoleId,
                Name = "Driver",
                NormalizedName = "DRIVER",
                ConcurrencyStamp = driverRoleId
            },
            new IdentityRole
            {
                Id = adminRoleId,
                Name = "Admin",
                NormalizedName = "ADMIN",
                ConcurrencyStamp = adminRoleId
            }
        };

        builder.Entity<IdentityRole>().HasData(roles);
    }


}