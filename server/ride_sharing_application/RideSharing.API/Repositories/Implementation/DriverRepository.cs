using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;
using RideSharing.API.Models.Domain;
using RideSharing.API.Repositories.Interface;

namespace RideSharing.API.Repositories.Implementation
{
    public class DriverRepository : IDriverRepository
    {
        private readonly RideSharingDbContext _context;

        public DriverRepository(RideSharingDbContext context)
        {
            _context = context;
        }

        public async Task<Ride> CreateRideAsync(Ride ride)
        {
            // Generate ride number
            var count = await _context.Rides.CountAsync();
            ride.RideNumber = $"DR{DateTime.Now:yyMM}{(count + 1):D4}";
            ride.Status = "scheduled";
            ride.CreatedAt = DateTime.UtcNow;
            ride.UpdatedAt = DateTime.UtcNow;

            await _context.Rides.AddAsync(ride);
            await _context.SaveChangesAsync();
            return ride;
        }

        public async Task<List<Ride>> GetDriverRidesAsync(Guid driverId, string? status, int page, int limit)
        {
            var query = _context.Rides
                .Include(r => r.Vehicle)
                .Include(r => r.Bookings)
                    .ThenInclude(b => b.Passenger)
                    .ThenInclude(p => p.Profile)
                .Where(r => r.DriverId == driverId);

            if (!string.IsNullOrEmpty(status))
            {
                query = query.Where(r => r.Status == status);
            }

            return await query
                .OrderByDescending(r => r.TravelDate)
                .ThenByDescending(r => r.DepartureTime)
                .Skip((page - 1) * limit)
                .Take(limit)
                .ToListAsync();
        }

        public async Task<Ride?> GetRideWithBookingsAsync(Guid rideId)
        {
            return await _context.Rides
                .Include(r => r.Vehicle)
                .Include(r => r.Bookings)
                    .ThenInclude(b => b.Passenger)
                    .ThenInclude(p => p.Profile)
                .FirstOrDefaultAsync(r => r.Id == rideId);
        }

        public async Task<Ride> UpdateRideAsync(Ride ride)
        {
            ride.UpdatedAt = DateTime.UtcNow;
            _context.Rides.Update(ride);
            await _context.SaveChangesAsync();
            return ride;
        }

        public async Task<bool> StartTripAsync(Guid rideId, DateTime actualDepartureTime)
        {
            var ride = await _context.Rides.FindAsync(rideId);
            if (ride == null) return false;

            ride.Status = "active";
            ride.ActualDepartureTime = actualDepartureTime;
            ride.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<Booking?> VerifyPassengerOTPAsync(Guid rideId, string otp)
        {
            var booking = await _context.Bookings
                .Include(b => b.Passenger)
                    .ThenInclude(p => p.Profile)
                .FirstOrDefaultAsync(b => b.RideId == rideId && b.OTP == otp);

            if (booking != null)
            {
                booking.IsVerified = true;
                booking.VerifiedAt = DateTime.UtcNow;
                booking.UpdatedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }

            return booking;
        }

        public async Task<bool> CompleteTripAsync(Guid rideId, DateTime actualArrivalTime, decimal actualDistance)
        {
            var ride = await _context.Rides.FindAsync(rideId);
            if (ride == null) return false;

            ride.Status = "completed";
            ride.ActualArrivalTime = actualArrivalTime;
            ride.Distance = actualDistance;
            ride.UpdatedAt = DateTime.UtcNow;

            // Update all bookings status
            var bookings = await _context.Bookings
                .Where(b => b.RideId == rideId)
                .ToListAsync();

            foreach (var booking in bookings)
            {
                booking.Status = "completed";
                booking.UpdatedAt = DateTime.UtcNow;
            }

            // Update driver earnings
            var driver = await _context.Drivers.FindAsync(ride.DriverId);
            if (driver != null)
            {
                var totalEarnings = ride.PricePerSeat * ride.BookedSeats;
                driver.TotalEarnings += totalEarnings;
                driver.PendingEarnings += totalEarnings;
            }

            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> CancelRideAsync(Guid rideId, string reason)
        {
            var ride = await _context.Rides.FindAsync(rideId);
            if (ride == null) return false;

            ride.Status = "cancelled";
            ride.CancellationReason = reason;
            ride.UpdatedAt = DateTime.UtcNow;

            // Cancel all associated bookings
            var bookings = await _context.Bookings
                .Where(b => b.RideId == rideId && b.Status != "cancelled")
                .ToListAsync();

            foreach (var booking in bookings)
            {
                booking.Status = "cancelled";
                booking.CancellationType = "driver";
                booking.CancellationReason = reason;
                booking.CancelledAt = DateTime.UtcNow;
                booking.UpdatedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<Driver?> GetDriverByUserIdAsync(Guid userId)
        {
            return await _context.Drivers
                .Include(d => d.User)
                    .ThenInclude(u => u.Profile)
                .Include(d => d.Vehicles)
                .FirstOrDefaultAsync(d => d.UserId == userId);
        }

        public async Task<Driver> UpdateDriverAsync(Driver driver)
        {
            driver.UpdatedAt = DateTime.UtcNow;
            _context.Drivers.Update(driver);
            await _context.SaveChangesAsync();
            return driver;
        }

        public async Task<decimal> GetTodayEarningsAsync(Guid driverId)
        {
            var today = DateTime.UtcNow.Date;
            var completedRides = await _context.Rides
                .Where(r => r.DriverId == driverId &&
                           r.Status == "completed" &&
                           r.TravelDate.Date == today)
                .ToListAsync();

            return completedRides.Sum(r => r.PricePerSeat * r.BookedSeats);
        }

        public async Task<int> GetTodayRidesCountAsync(Guid driverId)
        {
            var today = DateTime.UtcNow.Date;
            return await _context.Rides
                .CountAsync(r => r.DriverId == driverId &&
                               r.Status == "completed" &&
                               r.TravelDate.Date == today);
        }

        public async Task<List<Payment>> GetDriverEarningsAsync(Guid driverId, DateTime startDate, DateTime endDate)
        {
            return await _context.Payments
                .Include(p => p.Booking)
                .Where(p => p.DriverId == driverId &&
                           p.CreatedAt >= startDate &&
                           p.CreatedAt <= endDate)
                .OrderByDescending(p => p.CreatedAt)
                .ToListAsync();
        }

        public async Task<List<Payout>> GetDriverPayoutsAsync(Guid driverId, int page, int limit)
        {
            return await _context.Payouts
                .Where(p => p.DriverId == driverId)
                .OrderByDescending(p => p.RequestedAt)
                .Skip((page - 1) * limit)
                .Take(limit)
                .ToListAsync();
        }

        public async Task<Payout> RequestPayoutAsync(Payout payout)
        {
            // Generate payout ID
            var count = await _context.Payouts.CountAsync();
            payout.PayoutId = $"PO{DateTime.Now:yyMM}{(count + 1):D4}";
            payout.Status = "pending";
            payout.RequestedAt = DateTime.UtcNow;

            await _context.Payouts.AddAsync(payout);

            // Update driver's pending earnings
            var driver = await _context.Drivers.FindAsync(payout.DriverId);
            if (driver != null)
            {
                driver.PendingEarnings -= payout.Amount;
            }

            await _context.SaveChangesAsync();
            return payout;
        }

        public async Task<bool> UpdateDriverOnlineStatusAsync(Guid driverId, bool isOnline)
        {
            var driver = await _context.Drivers.FindAsync(driverId);
            if (driver == null) return false;

            driver.IsOnline = isOnline;
            driver.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<Vehicle?> GetDriverVehicleAsync(Guid driverId)
        {
            return await _context.Vehicles
                .FirstOrDefaultAsync(v => v.DriverId == driverId && v.IsActive);
        }

        public async Task<Vehicle> UpdateVehicleAsync(Vehicle vehicle)
        {
            vehicle.UpdatedAt = DateTime.UtcNow;
            _context.Vehicles.Update(vehicle);
            await _context.SaveChangesAsync();
            return vehicle;
        }
    }
}
