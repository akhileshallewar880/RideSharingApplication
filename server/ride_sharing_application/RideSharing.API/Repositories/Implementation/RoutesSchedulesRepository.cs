using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;
using RideSharing.API.Models.Domain;
using RideSharing.API.Models.DTO;
using RideSharing.API.Repositories.Interface;

namespace RideSharing.API.Repositories.Implementation
{
    public class RoutesSchedulesRepository : IRoutesSchedulesRepository
    {
        private readonly RideSharingDbContext _db;

        public RoutesSchedulesRepository(RideSharingDbContext db)
        {
            _db = db;
        }

        public async Task<RouteDto?> CreateRouteAsync(CreateRouteRequest req)
        {
            var driver = await _db.Drivers.FindAsync(req.DriverId);
            if (driver == null) return null;

            // In new schema, Routes are replaced by Rides
            // This method now creates a Ride template for backward compatibility
            var ride = new Ride
            {
                Id = Guid.NewGuid(),
                RideNumber = $"RIDE{DateTime.UtcNow:yyyyMMddHHmmss}",
                DriverId = req.DriverId,
                VehicleId = driver.Vehicles.FirstOrDefault()?.Id ?? Guid.Empty, // Use first available vehicle
                PickupLocation = req.Origin,
                PickupLatitude = 0, // Not provided in old API
                PickupLongitude = 0,
                DropoffLocation = req.Destination,
                DropoffLatitude = 0,
                DropoffLongitude = 0,
                TravelDate = DateTime.UtcNow.Date, // Default to today
                DepartureTime = TimeSpan.Zero, // Will be set by schedule template
                TotalSeats = 4, // Default
                BookedSeats = 0,
                PricePerSeat = 0, // Will be set by schedule template
                Status = "scheduled",
                Route = null, // Old RouteStops not mapped
                CreatedAt = DateTime.UtcNow
            };

            _db.Rides.Add(ride);
            await _db.SaveChangesAsync();

            return new RouteDto(
                ride.Id, ride.DriverId, $"{ride.PickupLocation} to {ride.DropoffLocation}",
                ride.PickupLocation, ride.DropoffLocation, req.DistanceKm,
                null // RouteStops not supported in new schema
            );
        }

        public async Task<RouteDto?> GetRouteAsync(Guid id)
        {
            var ride = await _db.Rides
                .FirstOrDefaultAsync(r => r.Id == id);

            if (ride == null) return null;

            return new RouteDto(
                ride.Id, ride.DriverId, $"{ride.PickupLocation} to {ride.DropoffLocation}",
                ride.PickupLocation, ride.DropoffLocation, 0,
                null // RouteStops not supported in new schema
            );
        }

        public async Task<IEnumerable<RouteDto>> SearchRoutesAsync(string origin, string destination)
        {
            var query = _db.Rides
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(origin))
                query = query.Where(r => r.PickupLocation == origin);

            if (!string.IsNullOrWhiteSpace(destination))
                query = query.Where(r => r.DropoffLocation == destination);

            var rides = await query.ToListAsync();

            return rides.Select(ride => new RouteDto(
                ride.Id, ride.DriverId, $"{ride.PickupLocation} to {ride.DropoffLocation}",
                ride.PickupLocation, ride.DropoffLocation, 0,
                null
            ));
        }

        public async Task<ScheduleTemplateDto?> CreateScheduleTemplateAsync(Guid routeId, CreateScheduleTemplateRequest req)
        {
            if (routeId != req.RouteId) return null;

            var ride = await _db.Rides.FindAsync(routeId);
            if (ride == null) return null;

            // Update the ride with schedule information
            ride.DepartureTime = req.DepartureTime;
            ride.TotalSeats = req.Capacity;
            ride.PricePerSeat = req.PricePerSeat;

            await _db.SaveChangesAsync();

            // Return a template DTO for backward compatibility
            return new ScheduleTemplateDto(
                Guid.NewGuid(), // New ID for the "template"
                routeId,
                req.DaysOfWeekMask,
                req.DepartureTime,
                req.Capacity,
                req.PricePerSeat,
                req.IsAutoConfirm
            );
        }

        public async Task<IEnumerable<ScheduleTemplateDto>> GetScheduleTemplatesAsync(Guid routeId)
        {
            var ride = await _db.Rides
                .FirstOrDefaultAsync(r => r.Id == routeId);

            if (ride == null) return Enumerable.Empty<ScheduleTemplateDto>();

            // Return ride info as a single template for backward compatibility
            return new[]
            {
                new ScheduleTemplateDto(
                    Guid.NewGuid(),
                    routeId,
                    127, // All days (default)
                    ride.DepartureTime,
                    ride.TotalSeats,
                    ride.PricePerSeat,
                    false
                )
            };
        }
    }
}