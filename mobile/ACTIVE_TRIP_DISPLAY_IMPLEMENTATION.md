# Active Trip Display Implementation

## Overview
This feature allows passengers to see a dedicated "Trip in Progress" card on their home screen when they have been verified by the driver with an OTP and the trip is actively in progress. The card provides a quick overview of the trip status and allows passengers to tap to view full live tracking.

## Implementation Date
December 2024

## Changes Made

### 1. Model Updates

#### File: `mobile/lib/core/models/passenger_ride_models.dart`

**BookingDetails Model:**
- Added `isVerified` field (boolean) to track if passenger has been verified by driver
- Updated constructor to include `isVerified` with default value `false`
- Updated `fromJson` factory to parse `isVerified` from API response

```dart
class BookingDetails {
  // ... existing fields
  final bool isVerified;

  BookingDetails({
    // ... existing parameters
    this.isVerified = false,
  });

  factory BookingDetails.fromJson(Map<String, dynamic> json) {
    return BookingDetails(
      // ... existing fields
      isVerified: json['isVerified'] ?? false,
    );
  }
}
```

**RideHistoryItem Model:**
- Added `isVerified` field (boolean) to track verification status
- Added `rideId` field (String?) for navigation to tracking screen
- Updated constructor with default values
- Updated `fromJson` factory to parse new fields

```dart
class RideHistoryItem {
  // ... existing fields
  final bool isVerified;
  final String? rideId;

  RideHistoryItem({
    // ... existing parameters
    this.isVerified = false,
    this.rideId,
  });

  factory RideHistoryItem.fromJson(Map<String, dynamic> json) {
    return RideHistoryItem(
      // ... existing fields
      isVerified: json['isVerified'] ?? false,
      rideId: json['rideId']?.toString(),
    );
  }
}
```

### 2. UI Components

#### File: `mobile/lib/features/passenger/presentation/screens/passenger_home_screen.dart`

**New Import:**
```dart
import 'package:allapalli_ride/features/passenger/presentation/screens/passenger_tracking_screen.dart';
```

**New Widget: `_buildActiveTripCard`**

Created a comprehensive active trip card that displays:
- **Header**: "Trip in Progress" with pulsing green indicator showing live status
- **Status Badge**: "Boarded" indicator with green accent
- **Route Display**: Pickup and dropoff locations with icon indicators
- **Driver Information**: Driver name, vehicle model, and vehicle number
- **Call Button**: Quick access to call driver
- **Tracking Hint**: Prompts user to tap for full tracking view

**Design Features:**
- Blue gradient background (different from green scheduled ride banner)
- Pulsing animation on live indicator for visual feedback
- Professional card layout with proper spacing and hierarchy
- Tap entire card to navigate to full tracking screen

**Navigation:**
- Converts `RideHistoryItem` to `BookingResponse` format
- Passes booking details to `PassengerTrackingScreen`
- Uses Material page route for smooth transition

### 3. Home Screen Logic Update

**Updated `_buildHomeContent` method:**

```dart
Widget _buildHomeContent(bool isDark) {
  final rideState = ref.watch(passengerRideNotifierProvider);
  
  // Check for active verified trip first
  final activeTrip = rideState.rideHistory.firstWhere(
    (r) => r.isVerified && 
           (r.status.toLowerCase() == 'active' || 
            r.status.toLowerCase() == 'in_progress' ||
            r.status.toLowerCase() == 'ongoing'),
    orElse: () => RideHistoryItem(...), // Empty ride
  );
  
  final upcomingRides = rideState.rideHistory
      .where((r) => r.status.toLowerCase() == 'scheduled' || 
                    r.status.toLowerCase() == 'confirmed')
      .toList();
  
  return Container(
    // ... layout
    children: [
      // Show active trip card if passenger is verified
      if (activeTrip.bookingNumber.isNotEmpty)
        _buildActiveTripCard(activeTrip, isDark)
      // Otherwise show scheduled ride banner
      else if (upcomingRides.isNotEmpty)
        _buildScheduledRideBanner(upcomingRides.first, isDark),
      // ... rest of home screen
    ],
  );
}
```

**Priority Logic:**
1. **First Priority**: Active verified trip (isVerified=true AND status=active/in_progress/ongoing)
2. **Second Priority**: Upcoming scheduled rides (status=scheduled/confirmed)
3. **Default**: Regular booking interface

## User Flow

### 1. Before Verification
```
Passenger books ride 
→ Status: "scheduled" or "confirmed"
→ Home screen shows: Green "Upcoming Ride" banner
→ isVerified: false
```

### 2. Driver Starts and Verifies
```
Driver starts ride
→ Driver enters OTP from passenger
→ Backend verifies OTP
→ Backend updates: isVerified = true, status = "active"
→ Frontend receives updated booking data
```

### 3. After Verification
```
Home screen automatically updates
→ Shows: Blue "Trip in Progress" card with "Boarded" badge
→ Displays: Live status indicator (pulsing green dot)
→ Shows: Driver info, vehicle details, route
→ User can tap card → Opens full tracking screen
```

### 4. During Trip
```
Passenger taps active trip card
→ Navigates to PassengerTrackingScreen
→ Shows: Google Map with live driver location
→ Shows: Trip progress timeline with intermediate stops
→ Shows: ETA, driver details, contact buttons
→ Real-time location updates via locationTrackingProvider
```

### 5. Trip Completion
```
Driver completes trip
→ Status changes to "completed"
→ isVerified becomes irrelevant
→ Card disappears from home screen
→ Trip moves to ride history
```

## Backend Requirements

The backend API must return the following fields in ride/booking responses:

### Required Fields
```json
{
  "bookingNumber": "string",
  "rideId": "string",
  "status": "active|in_progress|ongoing",
  "isVerified": true,
  "pickupLocation": "string",
  "dropoffLocation": "string",
  "driverName": "string",
  "vehicleModel": "string",
  "vehicleNumber": "string",
  "otp": "string",
  "scheduledDeparture": "string (ISO date)",
  "totalFare": number
}
```

### Status Values for Active Trip
The frontend recognizes these status values as "active":
- `"active"`
- `"in_progress"`
- `"ongoing"`

### Verification Flow Backend Logic
1. Driver starts ride → status changes to "active"
2. Driver enters passenger OTP
3. Backend validates OTP against booking
4. If valid: Set `isVerified = true` in booking record
5. Return updated booking to frontend via API or WebSocket

## Testing Checklist

### Manual Testing
- [ ] Book a ride and verify it shows as "Upcoming Ride" (green banner)
- [ ] Simulate driver verification (set isVerified=true in test data)
- [ ] Verify active trip card appears (blue card with "Boarded" badge)
- [ ] Verify pulsing indicator animation works
- [ ] Tap active trip card and verify navigation to tracking screen
- [ ] Verify tracking screen shows correct booking details
- [ ] Verify driver information displays correctly
- [ ] Test call button functionality
- [ ] Verify card disappears when trip is completed
- [ ] Test with multiple rides (active + scheduled)
- [ ] Test dark mode appearance

### Edge Cases
- [ ] No rides → Only show booking interface
- [ ] Scheduled ride only → Show green banner
- [ ] Active ride only → Show blue active card
- [ ] Both active and scheduled → Show only active card (priority)
- [ ] Multiple active rides → Show first active ride
- [ ] Missing driver/vehicle info → Gracefully handle with defaults
- [ ] Missing rideId → Handle navigation error

### Data Validation
- [ ] Verify isVerified defaults to false for new bookings
- [ ] Verify fromJson parses isVerified correctly
- [ ] Verify rideId is properly passed to tracking screen
- [ ] Test with null/missing fields in API response

## Known Limitations

1. **Single Active Trip Display**: Currently shows only one active trip at a time. If passenger has multiple active trips, only the first one is displayed.

2. **Real-time Update Dependency**: Card appearance depends on ride history being refreshed. Consider implementing WebSocket/polling for real-time status updates if not already present.

3. **Driver Contact**: Call button is displayed but requires phone dialer integration to be functional.

## Future Enhancements

### Potential Improvements
1. **Multiple Active Trips**: Support displaying multiple active trips in a scrollable list
2. **Intermediate Stops Preview**: Show mini timeline of stops directly on the card
3. **Live ETA**: Display estimated time to destination on the card
4. **Distance Covered**: Show progress bar or percentage of trip completed
5. **Map Preview**: Small map preview on the card showing driver's current location
6. **Push Notifications**: Alert passenger when driver verifies them
7. **Sound/Haptic Feedback**: Provide feedback when trip status changes
8. **Auto-refresh**: Periodically refresh ride history to detect status changes

### Integration Opportunities
- Integrate with notification system for real-time status updates
- Add deep linking to open tracking screen from push notifications
- Connect with analytics to track feature usage
- Add crash reporting for navigation errors

## Dependencies

### Flutter Packages
- `flutter_animate`: For pulsing indicator animation
- `flutter_riverpod`: State management
- `google_maps_flutter`: Tracking screen map display

### Internal Dependencies
- `locationTrackingProvider`: Real-time driver location updates
- `passengerRideNotifierProvider`: Ride history and booking state
- `LocationService`: Location detection and service area validation

## Related Files

### Modified Files
1. `mobile/lib/core/models/passenger_ride_models.dart`
   - Added `isVerified` and `rideId` fields to models

2. `mobile/lib/features/passenger/presentation/screens/passenger_home_screen.dart`
   - Added `_buildActiveTripCard` widget
   - Updated `_buildHomeContent` logic to prioritize active trips
   - Added import for `PassengerTrackingScreen`

### Related Existing Files
1. `mobile/lib/features/passenger/presentation/screens/passenger_tracking_screen.dart`
   - Full-featured tracking screen with Google Maps
   - Already implemented with real-time updates

2. `mobile/lib/core/providers/location_tracking_provider.dart`
   - Provides real-time driver location data
   - Used by tracking screen

3. `mobile/lib/core/providers/passenger_ride_provider.dart`
   - Manages ride history and booking state
   - Provides data for active trip detection

## Performance Considerations

1. **Efficient Filtering**: Uses `firstWhere` with `orElse` for O(n) active trip lookup
2. **Conditional Rendering**: Only renders active card when data exists
3. **Animation Performance**: Pulsing animation runs on GPU for smooth 60fps
4. **List Filtering**: Filters ride history once per rebuild (acceptable for typical list sizes)

## Accessibility

- Card has proper semantic labels for screen readers
- Sufficient color contrast ratios (white text on dark blue background)
- Touch target size meets minimum 48x48 dp guidelines
- Clear visual hierarchy and text sizing
- Status indicators use both color and text for visibility

## Maintenance Notes

### When Updating Backend API
- Ensure `isVerified` field is included in all booking/ride responses
- Document status value changes (if adding new status types)
- Maintain backward compatibility (default isVerified to false if missing)

### When Modifying UI
- Keep color scheme consistent with app theme
- Test animations on low-end devices for performance
- Maintain responsive layout for various screen sizes
- Update dark mode styles if changing colors

### Code Quality
- Widget is self-contained and testable
- Clear separation of concerns (UI, navigation, data)
- Proper null safety handling
- Comprehensive comments for future maintainers

---

## Summary

This implementation provides passengers with clear, real-time feedback about their trip status once verified by the driver. The blue "Trip in Progress" card serves as both an informational display and a quick navigation point to full tracking functionality, enhancing the overall user experience during active rides.
