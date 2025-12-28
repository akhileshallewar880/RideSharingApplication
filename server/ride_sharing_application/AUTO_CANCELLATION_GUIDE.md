# Auto-Cancellation Configuration Guide

## Overview
This document explains the automatic cancellation system for rides and bookings that have passed their scheduled time without being started.

## Implementation Approaches

### 1. **Background Service (.NET) - Recommended**
A hosted service that runs continuously in your ASP.NET Core application.

#### Features:
- ✅ Runs automatically when the application starts
- ✅ Checks every 5 minutes (configurable)
- ✅ Cancels expired rides and bookings
- ✅ Sends notifications to drivers and passengers
- ✅ Marks paid bookings for refund
- ✅ Comprehensive logging

#### Configuration:
Add to `appsettings.json`:
```json
{
  "RideAutoCancellation": {
    "Enabled": true,
    "CheckIntervalMinutes": 5,
    "GracePeriodMinutes": 15,
    "EnableNotifications": true,
    "EnableAutoRefund": true
  }
}
```

#### Files Created:
- `/Services/Implementation/RideAutoCancellationService.cs`
- Registered in `Program.cs`

---

### 2. **SQL Server Stored Procedure + Agent Job**
Database-level automation using SQL Server features.

#### Features:
- ✅ Independent of application runtime
- ✅ Can run even when API is down
- ✅ Lightweight and efficient
- ⚠️ Requires SQL Server (not Express edition) for Agent Jobs
- ⚠️ More complex to monitor and debug

#### Files Created:
- `/Data/AutoCancelExpiredRides.sql`

#### Setup:
```sql
-- 1. Create the stored procedure
USE AllapalliRide;
GO
-- Execute the script in AutoCancelExpiredRides.sql

-- 2. Test in debug mode first
EXEC sp_AutoCancelExpiredRides @GracePeriodMinutes = 15, @Debug = 1;

-- 3. Execute for real
EXEC sp_AutoCancelExpiredRides @GracePeriodMinutes = 15, @Debug = 0;

-- 4. Create SQL Agent Job (uncomment the job creation section in the file)
```

---

## Configuration Parameters

### Grace Period
The time buffer after scheduled departure before automatic cancellation.
- **Default**: 15 minutes
- **Recommendation**: 10-20 minutes to allow for delays

### Check Interval
How often the system checks for expired rides.
- **Default**: 5 minutes
- **Recommendation**: 3-10 minutes for balance between responsiveness and performance

---

## Business Logic

### Ride Cancellation Criteria
A ride is automatically cancelled if ALL of the following are true:
1. Status is `scheduled` or `upcoming`
2. Travel date is in the past, OR
3. Travel date is today AND departure time + grace period has passed

### Booking Cancellation
When a ride is cancelled:
1. All bookings with status `pending`, `confirmed`, or `active` are cancelled
2. Bookings with `completed`, `cancelled`, or `refunded` status are NOT touched
3. If booking payment status is `paid`, it's marked as `refunded`

### Refund Process
- Bookings are marked with `PaymentStatus = 'refunded'`
- Actual refund processing should be handled by your payment gateway integration
- You need to implement the refund logic in the `TODO` section

### Notifications
Notifications are sent to:
- **Driver**: "Your ride {RideNumber} was automatically cancelled..."
- **Passengers**: "Your booking {BookingNumber} was automatically cancelled..."
  - Includes refund information if applicable

---

## Status Flow

### Ride Status Flow
```
scheduled/upcoming → cancelled (auto)
```

### Booking Status Flow
```
pending/confirmed/active → cancelled (if unpaid)
pending/confirmed/active → refunded (if paid)
```

---

## Testing

### 1. Test Background Service
```csharp
// In your test environment, create a ride with past date/time:
var testRide = new Ride {
    TravelDate = DateTime.Today.AddDays(-1),
    DepartureTime = new TimeSpan(10, 0, 0),
    Status = "scheduled"
};
// Save to database

// Wait for next check cycle (5 minutes) or restart the application
// Check logs for cancellation messages
```

### 2. Test SQL Stored Procedure
```sql
-- Insert test data
INSERT INTO Rides (Id, RideNumber, DriverId, VehicleId, 
    PickupLocation, PickupLatitude, PickupLongitude,
    DropoffLocation, DropoffLatitude, DropoffLongitude,
    TravelDate, DepartureTime, TotalSeats, PricePerSeat, Status)
VALUES (
    NEWID(), 'TEST001', 
    (SELECT TOP 1 Id FROM Drivers),
    (SELECT TOP 1 Id FROM Vehicles),
    'Test Pickup', 0, 0,
    'Test Dropoff', 0, 0,
    '2024-01-01', '10:00:00', 4, 100.00, 'scheduled'
);

-- Run in debug mode to see what would be cancelled
EXEC sp_AutoCancelExpiredRides @GracePeriodMinutes = 15, @Debug = 1;

-- Execute for real
EXEC sp_AutoCancelExpiredRides @GracePeriodMinutes = 15, @Debug = 0;
```

---

## Monitoring

### Background Service Logs
Check application logs for:
```
[Information] Ride Auto-Cancellation Service started.
[Information] Found X expired rides to cancel.
[Information] Cancelling ride {RideNumber}
[Information] Successfully cancelled X expired rides.
```

### SQL Server Logs
```sql
-- Check recent cancellations
SELECT TOP 100 *
FROM Rides
WHERE Status = 'cancelled' 
    AND CancellationReason LIKE '%Automatically cancelled%'
ORDER BY UpdatedAt DESC;

SELECT TOP 100 *
FROM Bookings
WHERE CancellationType = 'system'
ORDER BY CancelledAt DESC;
```

---

## Recommendations

### Which Approach to Use?

**Use Background Service (.NET) if:**
- ✅ You want application-level control
- ✅ You need integrated logging and monitoring
- ✅ You're using SQL Server Express (no Agent Jobs)
- ✅ You want easier debugging and testing

**Use SQL Server Agent Job if:**
- ✅ You want database-level automation
- ✅ Your application might have downtime
- ✅ You have SQL Server Standard/Enterprise
- ✅ You prefer database-centric operations

**Use Both if:**
- ✅ You want maximum reliability
- ✅ Background service as primary, SQL job as backup

---

## Next Steps

### 1. Implement Refund Processing
```csharp
// In RideAutoCancellationService.cs, replace the TODO:
// TODO: Trigger refund process through payment gateway

// Example:
if (booking.PaymentStatus == "paid")
{
    await _paymentService.ProcessRefundAsync(booking.Id);
}
```

### 2. Add Configuration Management
Modify `RideAutoCancellationService.cs` to read from configuration:
```csharp
private readonly TimeSpan _checkInterval;
private readonly int _gracePeriodMinutes;

public RideAutoCancellationService(
    IServiceProvider serviceProvider,
    IConfiguration configuration,
    ILogger<RideAutoCancellationService> logger)
{
    _checkInterval = TimeSpan.FromMinutes(
        configuration.GetValue<int>("RideAutoCancellation:CheckIntervalMinutes", 5)
    );
    _gracePeriodMinutes = configuration.GetValue<int>(
        "RideAutoCancellation:GracePeriodMinutes", 15
    );
}
```

### 3. Add Metrics/Analytics
Track cancellation metrics:
- Number of auto-cancelled rides per day
- Most common cancellation reasons
- Refund amounts processed
- Driver/passenger notification delivery rates

---

## Troubleshooting

### Issue: Service not running
**Check:**
```bash
# Verify service is registered
dotnet run
# Look for startup log: "Ride Auto-Cancellation Service started."
```

### Issue: Rides not being cancelled
**Check:**
1. Service is running: Check logs
2. Database connectivity: Check connection string
3. Grace period: Ensure ride is truly expired
4. Ride status: Must be 'scheduled' or 'upcoming'

### Issue: Notifications not sent
**Check:**
1. Notifications table exists
2. User IDs are valid
3. Application has write access to Notifications table

---

## Database Indexes for Performance

Ensure these indexes exist for optimal performance:
```sql
-- On Rides table
CREATE INDEX IX_Rides_Status_TravelDate 
ON Rides(Status, TravelDate) 
INCLUDE (DepartureTime, DriverId);

-- On Bookings table
CREATE INDEX IX_Bookings_RideId_Status 
ON Bookings(RideId, Status) 
INCLUDE (PaymentStatus, PassengerId);
```

---

## Security Considerations

1. **Grace Period**: Too short might frustrate users; too long delays cleanup
2. **Refunds**: Ensure proper validation before processing
3. **Notifications**: Verify user exists before sending
4. **Logging**: Log all cancellations for audit trail
5. **Error Handling**: Failed cancellations should retry or alert admins

---

## Support

For questions or issues:
1. Check application logs: `/logs/ridesharingapi-*.log`
2. Review database cancellation records
3. Verify configuration settings
4. Test with debug mode enabled
