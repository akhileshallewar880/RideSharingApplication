# Driver Ride Scheduling - 30 Minute Buffer Implementation

## Overview
Implemented time conflict validation to ensure drivers can only schedule new rides at least **30 minutes after** the estimated arrival time of their previous ride.

## Business Logic
- **Scenario**: Driver schedules ride from Allapalli to Chandrapur
  - Departure: 12:00 PM
  - Estimated arrival: 3:00 PM (based on route duration)
  - Next ride available: **3:30 PM** (arrival + 30 min buffer)

## Implementation Details

### 1. Frontend Validation (`schedule_ride_screen.dart`)

**Location**: `mobile/lib/features/driver/screens/schedule_ride_screen.dart`

**Changes Made**:
- Added time conflict validation in `_scheduleRide()` method
- Fetches all active rides from the dashboard state
- Calculates estimated arrival time for each existing ride
- Compares new ride's departure time with existing rides' arrival windows

**Key Code**:
```dart
// Validate time conflicts with existing rides
final activeRides = ref.read(driverDashboardNotifierProvider).activeRides;
final newRideDeparture = DateTime(
  selectedDate.year,
  selectedDate.month,
  selectedDate.day,
  selectedTime.hour,
  selectedTime.minute,
);

for (var existingRide in activeRides) {
  // Skip cancelled or completed rides
  if (existingRide.status == 'Cancelled' || existingRide.status == 'Completed') {
    continue;
  }

  // Parse existing ride's date and time
  final dateParts = existingRide.date.split('-');
  final existingDate = DateTime(
    int.parse(dateParts[2]), // year
    int.parse(dateParts[1]), // month
    int.parse(dateParts[0]), // day
  );

  // Parse time with AM/PM support
  final timeParts = existingRide.time.replaceAll(RegExp(r'\s*(AM|PM)\s*', caseSensitive: false), '').split(':');
  int hour = int.parse(timeParts[0]);
  final minute = int.parse(timeParts[1]);
  final isAM = existingRide.time.toUpperCase().contains('AM');

  // Convert to 24-hour format
  if (!isAM && hour != 12) {
    hour += 12;
  } else if (isAM && hour == 12) {
    hour = 0;
  }

  final existingDeparture = DateTime(
    existingDate.year,
    existingDate.month,
    existingDate.day,
    hour,
    minute,
  );

  // Calculate arrival time (departure + duration + 30 min buffer)
  final duration = existingRide.duration ?? 180; // default 3 hours
  final arrivalWithBuffer = existingDeparture.add(Duration(minutes: duration + 30));

  // Check if new ride conflicts with existing ride's arrival window
  if (newRideDeparture.isBefore(arrivalWithBuffer)) {
    _showErrorSnackBar(
      'Time conflict: You have a ride scheduled from ${existingRide.pickupLocation} '
      'to ${existingRide.dropoffLocation} at ${existingRide.time}. '
      'You can schedule your next ride after ${DateFormat('hh:mm a').format(arrivalWithBuffer)}.',
    );
    return;
  }
}
```

**Date/Time Parsing**:
- **Date Format**: `dd-MM-yyyy` (e.g., "27-12-2025")
  - Splits by `-` and reverses to year-month-day for DateTime constructor
- **Time Format**: `hh:mm tt` (e.g., "03:00 PM")
  - Strips AM/PM indicator
  - Converts 12-hour format to 24-hour:
    - PM: add 12 to hour (except for 12 PM)
    - AM: use hour as-is (except 12 AM → 0)

### 2. Backend Validation (`DriverRidesController.cs`)

**Location**: `server/ride_sharing_application/RideSharing.API/Controllers/DriverRidesController.cs`

**Changes Made**:
- Added time conflict validation in `ScheduleRide` endpoint
- Checks all existing non-cancelled/completed rides for the driver
- Calculates arrival time using ride's Duration field
- Returns BadRequest with detailed error message if conflict detected

**Key Code**:
```csharp
// Validate time conflicts with existing rides
var driverId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
var existingRides = await _context.DriverRides
    .Where(r => r.DriverId == driverId && 
                r.Status != "Cancelled" && 
                r.Status != "Completed")
    .ToListAsync();

foreach (var existingRide in existingRides)
{
    var existingDepartureDateTime = DateTime.Parse($"{existingRide.Date} {existingRide.Time}");
    
    // Calculate arrival time (departure + duration + 30 min buffer)
    var arrivalDateTime = existingDepartureDateTime.AddMinutes(existingRide.Duration ?? 180);
    var bufferTime = arrivalDateTime.AddMinutes(30);
    
    // Check if new ride conflicts
    if (rideData.DepartureDateTime < bufferTime)
    {
        return BadRequest(new
        {
            message = $"Time conflict: You have ride {existingRide.RideNumber} scheduled at {existingRide.Time}. " +
                     $"You can schedule your next ride after {bufferTime:hh:mm tt}.",
            existingRideNumber = existingRide.RideNumber,
            conflictTime = bufferTime
        });
    }
}
```

### 3. Data Model Updates

**Frontend Model** (`driver_models.dart`):
```dart
class DriverRide {
  final double? distance;  // in kilometers
  final int? duration;     // in minutes
  
  // Constructor and fromJson updated
  DriverRide.fromJson(Map<String, dynamic> json)
    : distance = json['distance']?.toDouble(),
      duration = json['duration'],
      // ... other fields
}
```

**Backend DTO** (`DriverRideDto.cs`):
```csharp
public class DriverRideDto
{
    public decimal? Distance { get; set; }
    public int? Duration { get; set; }
    // ... other properties
}
```

**Backend API Response** (`GetActiveRides`):
```csharp
Distance = rideDistance?.Distance,
Duration = rideDistance?.Duration,
```

## Validation Flow

### Frontend Flow:
1. User selects date, time, and locations for new ride
2. System fetches all active rides from dashboard state
3. For each existing ride:
   - Parse date (dd-MM-yyyy) and time (hh:mm tt)
   - Calculate arrival time: departure + duration
   - Add 30-minute buffer
   - Check if new ride's departure < arrival + buffer
4. If conflict found: Show error with specific times
5. If no conflict: Proceed with API call

### Backend Flow:
1. Receive ride scheduling request
2. Query database for driver's existing non-cancelled/completed rides
3. For each existing ride:
   - Parse date and time
   - Calculate arrival time: departure + duration
   - Add 30-minute buffer
   - Check if new ride's departure < arrival + buffer
4. If conflict found: Return BadRequest with ride number and conflict time
5. If no conflict: Create ride and return success

## Error Messages

**Frontend**:
```
Time conflict: You have a ride scheduled from Allapalli 
to Chandrapur at 12:00 PM. You can schedule your next 
ride after 03:30 PM.
```

**Backend**:
```json
{
  "message": "Time conflict: You have ride RD-001 scheduled at 12:00 PM. You can schedule your next ride after 03:30 PM.",
  "existingRideNumber": "RD-001",
  "conflictTime": "2025-12-27T15:30:00"
}
```

## Default Values
- **Default Duration**: 180 minutes (3 hours) when duration is null
- **Buffer Time**: 30 minutes (fixed)

## Testing Checklist
- [ ] Schedule ride from Allapalli to Chandrapur at 12:00 PM
- [ ] Verify backend calculates duration correctly
- [ ] Attempt to schedule another ride before 3:30 PM
- [ ] Verify error message displays correctly
- [ ] Attempt to schedule ride after 3:30 PM
- [ ] Verify ride creation succeeds
- [ ] Test with multiple existing rides
- [ ] Test edge cases: overnight rides, same-day multiple rides
- [ ] Verify date/time parsing for different formats

## Files Modified
1. `mobile/lib/features/driver/screens/schedule_ride_screen.dart`
2. `mobile/lib/features/driver/models/driver_models.dart`
3. `server/ride_sharing_application/RideSharing.API/Controllers/DriverRidesController.cs`
4. `server/ride_sharing_application/RideSharing.API/DTOs/DriverRideDto.cs`

## Compilation Status
✅ Frontend: No errors
✅ Backend: Build succeeded (24 warnings, 0 errors)

## Notes
- Both frontend and backend validate independently for defense-in-depth
- Frontend validation provides immediate feedback (better UX)
- Backend validation ensures data integrity (security)
- Duration is calculated by `RouteDistanceService` based on predefined route data
- Time parsing handles 12-hour AM/PM format correctly
