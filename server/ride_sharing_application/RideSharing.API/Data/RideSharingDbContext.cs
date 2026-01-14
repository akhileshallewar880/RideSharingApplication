using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;

namespace RideSharing.API.Data
{
    public class RideSharingDbContext : DbContext
    {
        public RideSharingDbContext(DbContextOptions<RideSharingDbContext> dbContextOptions) : base(dbContextOptions)
        {

        }

        // DbSets for all main entities
        public DbSet<Models.Domain.User> Users { get; set; }
        public DbSet<Models.Domain.UserProfile> UserProfiles { get; set; }
        public DbSet<Models.Domain.Driver> Drivers { get; set; }
        public DbSet<Models.Domain.Vehicle> Vehicles { get; set; }
        public DbSet<Models.Domain.VehicleModel> VehicleModels { get; set; }
        public DbSet<Models.Domain.City> Cities { get; set; }
        public DbSet<Models.Domain.Ride> Rides { get; set; }
        public DbSet<Models.Domain.Booking> Bookings { get; set; }
        public DbSet<Models.Domain.Payment> Payments { get; set; }
        public DbSet<Models.Domain.Rating> Ratings { get; set; }
        public DbSet<Models.Domain.Notification> Notifications { get; set; }
        public DbSet<Models.Domain.Payout> Payouts { get; set; }
        public DbSet<Models.Domain.OTPVerification> OTPVerifications { get; set; }
        public DbSet<Models.Domain.RefreshToken> RefreshTokens { get; set; }
        public DbSet<Models.Domain.LocationTracking> LocationTrackings { get; set; }
        public DbSet<Models.Domain.PasswordResetToken> PasswordResetTokens { get; set; }
        public DbSet<Models.Domain.Banner> Banners { get; set; }
        public DbSet<Models.Domain.RouteSegment> RouteSegments { get; set; }
        public DbSet<Models.Domain.Coupon> Coupons { get; set; }
        public DbSet<Models.Domain.CouponUsage> CouponUsages { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // User Configuration
            modelBuilder.Entity<Models.Domain.User>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.PhoneNumber).IsUnique();
                entity.HasIndex(e => e.Email).IsUnique();
                entity.HasIndex(e => e.UserType);
                entity.Property(e => e.UserType).IsRequired();
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETUTCDATE()");
                entity.Property(e => e.UpdatedAt).HasDefaultValueSql("GETUTCDATE()");
            });

            // UserProfile Configuration
            modelBuilder.Entity<Models.Domain.UserProfile>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.UserId).IsUnique();
                entity.HasOne(e => e.User)
                    .WithOne(u => u.Profile)
                    .HasForeignKey<Models.Domain.UserProfile>(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.Property(e => e.Rating).HasPrecision(3, 2); // Rating: 0.00 to 5.00
            });

            // Driver Configuration
            modelBuilder.Entity<Models.Domain.Driver>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.UserId).IsUnique();
                entity.HasIndex(e => e.LicenseNumber).IsUnique();
                entity.HasIndex(e => e.IsOnline);
                entity.HasIndex(e => e.IsAvailable);
                entity.HasOne(e => e.User)
                    .WithOne(u => u.Driver)
                    .HasForeignKey<Models.Domain.Driver>(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
                entity.Property(e => e.TotalEarnings).HasPrecision(10, 2);
                entity.Property(e => e.PendingEarnings).HasPrecision(10, 2);
                entity.Property(e => e.AvailableForWithdrawal).HasPrecision(10, 2);
            });

            // Vehicle Configuration
            modelBuilder.Entity<Models.Domain.Vehicle>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.DriverId);
                entity.HasIndex(e => e.RegistrationNumber).IsUnique();
                entity.HasIndex(e => e.VehicleType);
                entity.HasOne(e => e.Driver)
                    .WithMany(d => d.Vehicles)
                    .HasForeignKey(e => e.DriverId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // VehicleModel Configuration
            modelBuilder.Entity<Models.Domain.VehicleModel>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.Type);
                entity.HasIndex(e => e.Brand);
                entity.HasIndex(e => e.IsActive);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETUTCDATE()");
                entity.Property(e => e.UpdatedAt).HasDefaultValueSql("GETUTCDATE()");
            });

            // Ride Configuration
            modelBuilder.Entity<Models.Domain.Ride>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.RideNumber).IsUnique();
                entity.HasIndex(e => e.DriverId);
                entity.HasIndex(e => e.TravelDate);
                entity.HasIndex(e => e.Status);
                entity.HasIndex(e => e.PickupLocation);
                entity.HasIndex(e => e.DropoffLocation);
                entity.Ignore(e => e.AvailableSeats);
                entity.Ignore(e => e.EstimatedEarnings);
                entity.HasOne(e => e.Driver)
                    .WithMany(d => d.Rides)
                    .HasForeignKey(e => e.DriverId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(e => e.Vehicle)
                    .WithMany(v => v.Rides)
                    .HasForeignKey(e => e.VehicleId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(e => e.VehicleModel)
                    .WithMany()
                    .HasForeignKey(e => e.VehicleModelId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.Property(e => e.PricePerSeat).HasPrecision(10, 2);
                entity.Property(e => e.PickupLatitude).HasPrecision(10, 8);
                entity.Property(e => e.PickupLongitude).HasPrecision(11, 8);
                entity.Property(e => e.DropoffLatitude).HasPrecision(10, 8);
                entity.Property(e => e.DropoffLongitude).HasPrecision(11, 8);
                entity.Property(e => e.Distance).HasPrecision(10, 2);
            });

            // Booking Configuration
            modelBuilder.Entity<Models.Domain.Booking>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.BookingNumber).IsUnique();
                entity.HasIndex(e => e.RideId);
                entity.HasIndex(e => e.PassengerId);
                entity.HasIndex(e => e.Status);
                entity.HasIndex(e => e.OTP);
                entity.HasOne(e => e.Ride)
                    .WithMany(r => r.Bookings)
                    .HasForeignKey(e => e.RideId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(e => e.Passenger)
                    .WithMany(u => u.Bookings)
                    .HasForeignKey(e => e.PassengerId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.Property(e => e.PricePerSeat).HasPrecision(10, 2);
                entity.Property(e => e.TotalFare).HasPrecision(10, 2);
                entity.Property(e => e.PlatformFee).HasPrecision(10, 2);
                entity.Property(e => e.TotalAmount).HasPrecision(10, 2);
                entity.Property(e => e.PickupLatitude).HasPrecision(10, 8);
                entity.Property(e => e.PickupLongitude).HasPrecision(11, 8);
                entity.Property(e => e.DropoffLatitude).HasPrecision(10, 8);
                entity.Property(e => e.DropoffLongitude).HasPrecision(11, 8);
            });

            // Payment Configuration
            modelBuilder.Entity<Models.Domain.Payment>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.TransactionId).IsUnique();
                entity.HasIndex(e => e.BookingId);
                entity.HasIndex(e => e.PaymentStatus);
                entity.HasOne(e => e.Booking)
                    .WithMany(b => b.Payments)
                    .HasForeignKey(e => e.BookingId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(e => e.Passenger)
                    .WithMany()
                    .HasForeignKey(e => e.PassengerId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(e => e.Driver)
                    .WithMany()
                    .HasForeignKey(e => e.DriverId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.Property(e => e.Amount).HasPrecision(10, 2);
                entity.Property(e => e.PlatformFee).HasPrecision(10, 2);
                entity.Property(e => e.DriverAmount).HasPrecision(10, 2);
            });

            // Rating Configuration
            modelBuilder.Entity<Models.Domain.Rating>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.BookingId);
                entity.HasIndex(e => e.RatedTo);
                entity.HasOne(e => e.Booking)
                    .WithMany(b => b.Ratings)
                    .HasForeignKey(e => e.BookingId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(e => e.Ride)
                    .WithMany(r => r.Ratings)
                    .HasForeignKey(e => e.RideId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(e => e.RatedByUser)
                    .WithMany()
                    .HasForeignKey(e => e.RatedBy)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(e => e.RatedToUser)
                    .WithMany()
                    .HasForeignKey(e => e.RatedTo)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // Notification Configuration
            modelBuilder.Entity<Models.Domain.Notification>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.UserId);
                entity.HasIndex(e => e.IsRead);
                entity.HasIndex(e => e.CreatedAt);
                entity.HasOne(e => e.User)
                    .WithMany(u => u.Notifications)
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Payout Configuration
            modelBuilder.Entity<Models.Domain.Payout>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.PayoutId).IsUnique();
                entity.HasIndex(e => e.DriverId);
                entity.HasIndex(e => e.Status);
                entity.HasOne(e => e.Driver)
                    .WithMany(d => d.Payouts)
                    .HasForeignKey(e => e.DriverId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.Property(e => e.Amount).HasPrecision(10, 2);
            });

            // OTPVerification Configuration
            modelBuilder.Entity<Models.Domain.OTPVerification>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.PhoneNumber);
                entity.HasIndex(e => e.CreatedAt);
            });

            // RefreshToken Configuration
            modelBuilder.Entity<Models.Domain.RefreshToken>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.Token).IsUnique();
                entity.HasIndex(e => e.UserId);
                entity.HasOne(e => e.User)
                    .WithMany(u => u.RefreshTokens)
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // City Configuration
            modelBuilder.Entity<Models.Domain.City>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.Name);
                entity.HasIndex(e => e.State);
                entity.HasIndex(e => e.District);
                entity.HasIndex(e => e.IsActive);
                // Note: Latitude/Longitude are float? type, no precision needed
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETUTCDATE()");
                entity.Property(e => e.UpdatedAt).HasDefaultValueSql("GETUTCDATE()");

                // Seed data for Maharashtra - Gadchiroli District cities
                entity.HasData(
                    new Models.Domain.City
                    {
                        Id = Guid.Parse("11111111-1111-1111-1111-111111111101"),
                        Name = "Gadchiroli",
                        State = "Maharashtra",
                        District = "Gadchiroli",
                        Pincode = "442605",
                        Latitude = 20.1809f,
                        Longitude = 80.0027f,
                        IsActive = true,
                        CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                        UpdatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
                    },
                    new Models.Domain.City
                    {
                        Id = Guid.Parse("11111111-1111-1111-1111-111111111102"),
                        Name = "Aheri",
                        State = "Maharashtra",
                        District = "Gadchiroli",
                        Pincode = "441701",
                        Latitude = 19.2856f,
                        Longitude = 80.7328f,
                        IsActive = true,
                        CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                        UpdatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
                    },
                    new Models.Domain.City
                    {
                        Id = Guid.Parse("11111111-1111-1111-1111-111111111103"),
                        Name = "Allapalli",
                        State = "Maharashtra",
                        District = "Gadchiroli",
                        Pincode = "441702",
                        Latitude = 19.4472f,
                        Longitude = 80.0572f,
                        IsActive = true,
                        CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                        UpdatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
                    },
                    new Models.Domain.City
                    {
                        Id = Guid.Parse("11111111-1111-1111-1111-111111111104"),
                        Name = "Armori",
                        State = "Maharashtra",
                        District = "Gadchiroli",
                        Pincode = "441208",
                        Latitude = 20.7450f,
                        Longitude = 80.0450f,
                        IsActive = true,
                        CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                        UpdatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
                    },
                    new Models.Domain.City
                    {
                        Id = Guid.Parse("11111111-1111-1111-1111-111111111105"),
                        Name = "Bhamragad",
                        State = "Maharashtra",
                        District = "Gadchiroli",
                        Pincode = "441902",
                        Latitude = 19.1142f,
                        Longitude = 80.3117f,
                        IsActive = true,
                        CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                        UpdatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
                    },
                    new Models.Domain.City
                    {
                        Id = Guid.Parse("11111111-1111-1111-1111-111111111106"),
                        Name = "Chamorshi",
                        State = "Maharashtra",
                        District = "Gadchiroli",
                        Pincode = "442603",
                        Latitude = 20.0447f,
                        Longitude = 79.8547f,
                        IsActive = true,
                        CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                        UpdatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
                    },
                    new Models.Domain.City
                    {
                        Id = Guid.Parse("11111111-1111-1111-1111-111111111107"),
                        Name = "Desaiganj (Vadasa)",
                        State = "Maharashtra",
                        District = "Gadchiroli",
                        Pincode = "441801",
                        Latitude = 20.4739f,
                        Longitude = 80.0744f,
                        IsActive = true,
                        CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                        UpdatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
                    },
                    new Models.Domain.City
                    {
                        Id = Guid.Parse("11111111-1111-1111-1111-111111111108"),
                        Name = "Dhanora",
                        State = "Maharashtra",
                        District = "Gadchiroli",
                        Pincode = "442605",
                        Latitude = 19.9194f,
                        Longitude = 79.7811f,
                        IsActive = true,
                        CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                        UpdatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
                    },
                    new Models.Domain.City
                    {
                        Id = Guid.Parse("11111111-1111-1111-1111-111111111109"),
                        Name = "Etapalli",
                        State = "Maharashtra",
                        District = "Gadchiroli",
                        Pincode = "441903",
                        Latitude = 19.3119f,
                        Longitude = 80.5278f,
                        IsActive = true,
                        CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                        UpdatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
                    },
                    new Models.Domain.City
                    {
                        Id = Guid.Parse("11111111-1111-1111-1111-111111111110"),
                        Name = "Korchi",
                        State = "Maharashtra",
                        District = "Gadchiroli",
                        Pincode = "441901",
                        Latitude = 19.4167f,
                        Longitude = 80.6167f,
                        IsActive = true,
                        CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                        UpdatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
                    },
                    new Models.Domain.City
                    {
                        Id = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                        Name = "Kurkheda",
                        State = "Maharashtra",
                        District = "Gadchiroli",
                        Pincode = "441209",
                        Latitude = 20.5089f,
                        Longitude = 80.1917f,
                        IsActive = true,
                        CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                        UpdatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
                    },
                    new Models.Domain.City
                    {
                        Id = Guid.Parse("11111111-1111-1111-1111-111111111112"),
                        Name = "Mulchera",
                        State = "Maharashtra",
                        District = "Gadchiroli",
                        Pincode = "441210",
                        Latitude = 20.4333f,
                        Longitude = 80.2833f,
                        IsActive = true,
                        CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                        UpdatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
                    },
                    new Models.Domain.City
                    {
                        Id = Guid.Parse("11111111-1111-1111-1111-111111111113"),
                        Name = "Sironcha",
                        State = "Maharashtra",
                        District = "Gadchiroli",
                        Pincode = "441104",
                        Latitude = 18.8314f,
                        Longitude = 81.0439f,
                        IsActive = true,
                        CreatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                        UpdatedAt = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc)
                    }
                );
            });

            // Banner Configuration
            modelBuilder.Entity<Models.Domain.Banner>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.IsActive);
                entity.HasIndex(e => e.TargetAudience);
                entity.HasIndex(e => new { e.StartDate, e.EndDate });
                entity.HasIndex(e => e.DisplayOrder);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETUTCDATE()");
                entity.Property(e => e.UpdatedAt).HasDefaultValueSql("GETUTCDATE()");
            });

            // Coupon Configuration
            modelBuilder.Entity<Models.Domain.Coupon>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.Code).IsUnique();
                entity.HasIndex(e => e.IsActive);
                entity.HasIndex(e => new { e.ValidFrom, e.ValidUntil });
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETUTCDATE()");
            });

            // CouponUsage Configuration
            modelBuilder.Entity<Models.Domain.CouponUsage>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => new { e.CouponId, e.UserId });
                entity.HasIndex(e => e.BookingId);
                entity.HasOne(e => e.Coupon)
                    .WithMany(c => c.CouponUsages)
                    .HasForeignKey(e => e.CouponId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(e => e.User)
                    .WithMany()
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.HasOne(e => e.Booking)
                    .WithMany()
                    .HasForeignKey(e => e.BookingId)
                    .OnDelete(DeleteBehavior.Restrict);
                entity.Property(e => e.UsedAt).HasDefaultValueSql("GETUTCDATE()");
            });
        }
    }
    
}