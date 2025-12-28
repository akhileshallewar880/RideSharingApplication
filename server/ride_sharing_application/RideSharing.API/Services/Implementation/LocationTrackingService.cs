using Microsoft.EntityFrameworkCore;
using RideSharing.API.Data;
using RideSharing.API.Models.Domain;
using RideSharing.API.Models.DTO;
using RideSharing.API.Services.Interface;

namespace RideSharing.API.Services.Implementation
{
    /// <summary>
    /// Service for managing location tracking and ride metrics
    /// </summary>
    public class LocationTrackingService : ILocationTrackingService
    {
        private readonly RideSharingDbContext _context;
        private readonly ILogger<LocationTrackingService> _logger;

        public LocationTrackingService(
            RideSharingDbContext context,
            ILogger<LocationTrackingService> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Save a new location update
        /// </summary>
        public async Task<LocationTracking> SaveLocationUpdateAsync(
            Guid rideId,
            Guid driverId,
            decimal latitude,
            decimal longitude,
            decimal speed,
            decimal heading,
            decimal accuracy)
        {
            var locationTracking = new LocationTracking
            {
                Id = Guid.NewGuid(),
                RideId = rideId,
                DriverId = driverId,
                Latitude = latitude,
                Longitude = longitude,
                Speed = speed,
                Heading = heading,
                Accuracy = accuracy,
                Timestamp = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow
            };

            _context.LocationTrackings.Add(locationTracking);
            await _context.SaveChangesAsync();

            _logger.LogDebug("Saved location update for ride {RideId} at ({Lat}, {Lon})", 
                rideId, latitude, longitude);

            return locationTracking;
        }

        /// <summary>
        /// Get location history for a ride
        /// </summary>
        public async Task<LocationHistoryResponse> GetLocationHistoryAsync(
            Guid rideId,
            DateTime? startTime = null,
            DateTime? endTime = null,
            int limit = 100)
        {
            var query = _context.LocationTrackings
                .Where(lt => lt.RideId == rideId)
                .AsQueryable();

            if (startTime.HasValue)
                query = query.Where(lt => lt.Timestamp >= startTime.Value);

            if (endTime.HasValue)
                query = query.Where(lt => lt.Timestamp <= endTime.Value);

            var locations = await query
                .OrderByDescending(lt => lt.Timestamp)
                .Take(limit)
                .Select(lt => new LocationTrackingDto
                {
                    Id = lt.Id,
                    RideId = lt.RideId,
                    DriverId = lt.DriverId,
                    Latitude = lt.Latitude,
                    Longitude = lt.Longitude,
                    Speed = lt.Speed,
                    Heading = lt.Heading,
                    Accuracy = lt.Accuracy,
                    Timestamp = lt.Timestamp
                })
                .ToListAsync();

            // Calculate total distance
            double totalDistance = 0;
            for (int i = 0; i < locations.Count - 1; i++)
            {
                var dist = await CalculateDistanceAsync(
                    locations[i].Latitude,
                    locations[i].Longitude,
                    locations[i + 1].Latitude,
                    locations[i + 1].Longitude
                );
                totalDistance += dist;
            }

            return new LocationHistoryResponse
            {
                RideId = rideId,
                Locations = locations,
                TotalCount = locations.Count,
                TotalDistanceKm = totalDistance,
                FirstLocation = locations.LastOrDefault()?.Timestamp,
                LastLocation = locations.FirstOrDefault()?.Timestamp
            };
        }

        /// <summary>
        /// Get the latest location for a ride
        /// </summary>
        public async Task<LocationTracking?> GetLatestLocationAsync(Guid rideId)
        {
            return await _context.LocationTrackings
                .Where(lt => lt.RideId == rideId)
                .OrderByDescending(lt => lt.Timestamp)
                .FirstOrDefaultAsync();
        }

        /// <summary>
        /// Calculate ride metrics (distance, ETA, average speed)
        /// </summary>
        public async Task<RideMetricsDto?> CalculateRideMetricsAsync(Guid rideId)
        {
            var ride = await _context.Rides
                .Include(r => r.Bookings)
                .FirstOrDefaultAsync(r => r.Id == rideId);

            if (ride == null)
                return null;

            var latestLocation = await GetLatestLocationAsync(rideId);
            if (latestLocation == null)
                return null;

            // Get all locations for this ride
            var locations = await _context.LocationTrackings
                .Where(lt => lt.RideId == rideId)
                .OrderBy(lt => lt.Timestamp)
                .ToListAsync();

            // Calculate total distance covered
            double totalDistanceCovered = 0;
            for (int i = 0; i < locations.Count - 1; i++)
            {
                var dist = await CalculateDistanceAsync(
                    locations[i].Latitude,
                    locations[i].Longitude,
                    locations[i + 1].Latitude,
                    locations[i + 1].Longitude
                );
                totalDistanceCovered += dist;
            }

            // Calculate average speed
            double? averageSpeed = null;
            if (locations.Count > 0)
            {
                var totalTime = (locations.Last().Timestamp - locations.First().Timestamp).TotalHours;
                if (totalTime > 0)
                {
                    averageSpeed = totalDistanceCovered / totalTime;
                }
            }

            // Calculate remaining distance to destination
            // Assuming dropoff location coordinates are stored (you may need to parse from IntermediateStops)
            double? remainingDistance = null;
            int? eta = null;

            // If we have destination coordinates, calculate remaining distance
            // For now, using placeholder logic
            if (ride.Distance.HasValue)
            {
                remainingDistance = Math.Max(0, (double)ride.Distance.Value - totalDistanceCovered);
                
                // Calculate ETA based on average speed or current speed
                var speedKmh = latestLocation.Speed > 0 
                    ? (double)(latestLocation.Speed * 3.6m) // m/s to km/h
                    : averageSpeed ?? 40.0; // Default 40 km/h

                if (speedKmh > 5) // Only calculate if moving
                {
                    eta = (int)Math.Round((remainingDistance.Value / speedKmh) * 60); // minutes
                }
            }

            return new RideMetricsDto
            {
                RideId = rideId,
                CurrentLatitude = latestLocation.Latitude,
                CurrentLongitude = latestLocation.Longitude,
                CurrentSpeed = latestLocation.Speed,
                RemainingDistanceKm = remainingDistance,
                EstimatedArrivalMinutes = eta,
                AverageSpeedKmh = averageSpeed,
                TotalDistanceCoveredKm = totalDistanceCovered,
                LastUpdateTime = latestLocation.Timestamp
            };
        }

        /// <summary>
        /// Get live tracking status for passengers
        /// </summary>
        public async Task<LiveTrackingStatusDto?> GetLiveTrackingStatusAsync(Guid rideId, Guid? passengerId = null)
        {
            var ride = await _context.Rides
                .Include(r => r.Bookings)
                .FirstOrDefaultAsync(r => r.Id == rideId);

            if (ride == null)
                return null;

            var latestLocation = await GetLatestLocationAsync(rideId);
            var isDriverOnline = latestLocation != null && 
                                 (DateTime.UtcNow - latestLocation.Timestamp).TotalMinutes < 5;

            LocationTrackingDto? currentLocationDto = null;
            if (latestLocation != null)
            {
                currentLocationDto = new LocationTrackingDto
                {
                    Id = latestLocation.Id,
                    RideId = latestLocation.RideId,
                    DriverId = latestLocation.DriverId,
                    Latitude = latestLocation.Latitude,
                    Longitude = latestLocation.Longitude,
                    Speed = latestLocation.Speed,
                    Heading = latestLocation.Heading,
                    Accuracy = latestLocation.Accuracy,
                    Timestamp = latestLocation.Timestamp
                };
            }

            // Calculate distance to passenger pickup/dropoff if needed
            double? distanceToPickup = null;
            double? distanceToDropoff = null;
            int? etaToPickup = null;
            int? etaToDropoff = null;

            if (passengerId.HasValue && latestLocation != null)
            {
                var booking = ride.Bookings.FirstOrDefault(b => b.PassengerId == passengerId.Value);
                if (booking != null)
                {
                    // TODO: Calculate actual distances when pickup/dropoff coordinates are available
                    // For now, using placeholder values
                }
            }

            return new LiveTrackingStatusDto
            {
                RideId = rideId,
                Status = ride.Status,
                CurrentLocation = currentLocationDto,
                DistanceToPickup = distanceToPickup,
                EtaToPickup = etaToPickup,
                DistanceToDropoff = distanceToDropoff,
                EtaToDropoff = etaToDropoff,
                LastUpdated = latestLocation?.Timestamp,
                IsDriverOnline = isDriverOnline
            };
        }

        /// <summary>
        /// Calculate distance between two coordinates using Haversine formula
        /// Returns distance in kilometers
        /// </summary>
        public Task<double> CalculateDistanceAsync(decimal lat1, decimal lon1, decimal lat2, decimal lon2)
        {
            const double earthRadiusKm = 6371;

            var dLat = DegreesToRadians((double)(lat2 - lat1));
            var dLon = DegreesToRadians((double)(lon2 - lon1));

            var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                    Math.Cos(DegreesToRadians((double)lat1)) * Math.Cos(DegreesToRadians((double)lat2)) *
                    Math.Sin(dLon / 2) * Math.Sin(dLon / 2);

            var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
            var distance = earthRadiusKm * c;

            return Task.FromResult(distance);
        }

        /// <summary>
        /// Cleanup old location data to save storage
        /// </summary>
        public async Task CleanupOldLocationDataAsync(int daysToKeep = 30)
        {
            var cutoffDate = DateTime.UtcNow.AddDays(-daysToKeep);
            
            var oldLocations = await _context.LocationTrackings
                .Where(lt => lt.CreatedAt < cutoffDate)
                .ToListAsync();

            if (oldLocations.Any())
            {
                _context.LocationTrackings.RemoveRange(oldLocations);
                await _context.SaveChangesAsync();
                
                _logger.LogInformation("Cleaned up {Count} old location records older than {Days} days",
                    oldLocations.Count, daysToKeep);
            }
        }

        private static double DegreesToRadians(double degrees)
        {
            return degrees * Math.PI / 180.0;
        }
    }
}
