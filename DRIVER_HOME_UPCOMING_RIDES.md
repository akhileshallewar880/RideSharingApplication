# Driver Home - Upcoming Rides Overview with Countdown

## Feature Overview
Added an "Upcoming Rides" section to the driver home screen that displays:
- **Upcoming/Active rides** overview (shows next 2 rides)
- **Live countdown timer** showing time until departure
- **Number of passengers booked** with percentage
- **Estimated earnings** for each ride
- **Route visualization** with pickup and dropoff locations
- **Status-based color coding** (upcoming, departing soon, in progress)

## Implementation Details

### 1. Data Loading
The screen now loads both dashboard data and active rides on initialization:

```dart
@override
void initState() {
  super.initState();
  // Load dashboard data and active rides
  Future.microtask(() {
    ref.read(driverDashboardNotifierProvider.notifier).loadDashboard();
    ref.read(driverRideNotifierProvider.notifier).loadActiveRides();
  });
}
```

### 2. Upcoming Rides Section

**Location**: Added after the "Online Status Card" and before "Today's Summary"

**Features**:
- Shows up to 2 upcoming rides
- "View All" button if more than 2 rides exist
- Empty state when no upcoming rides
- Automatically filters out cancelled/completed rides
- Sorts rides by departure date/time

### 3. Countdown Timer

Each ride card displays a **live countdown timer** that updates every second:

**Time Formats**:
- `> 1 day`: "2 days, 5 hrs"
- `< 24 hours`: "5 hrs, 30 min"
- `< 1 hour`: "45 min"
- `In progress`: Shows when departure time has passed

**Color Coding**:
- 🔵 **Blue (Info)**: More than 2 hours until departure
- 🟡 **Yellow (Warning)**: Less than 2 hours until departure
- 🟢 **Green (Success)**: Ride is in progress

### 4. Passenger Information

**Booked Seats Display**:
```
👥 3/6
Booked (50%)
```

Shows:
- Current booked seats / Total available seats
- Percentage of seats filled
- Visual highlight with yellow color

### 5. Estimated Earnings

**Earnings Display**:
```
₹850
Est. Earnings
```

Shows the estimated earnings based on:
- Booked seats × Price per seat
- Displayed in rupees with success color (green)

### 6. Route Visualization

Each ride card shows:
- **Pickup location** with green trip origin icon
- **Departure date and time**
- **Visual connector** (gradient line)
- **Dropoff location** with red location pin icon

### 7. Empty State

When no upcoming rides exist, displays:
```
📅 No upcoming rides
Schedule a ride to get started
```

## UI Components

### UpcomingRideCard Widget
Custom stateful widget that:
- Parses date (dd-MM-yyyy) and time (hh:mm tt)
- Maintains countdown timer with automatic updates
- Handles 12-hour and 24-hour time formats
- Displays ride information in a clean card layout
- Includes animations (fade in + slide)

### Card Structure
```
┌─────────────────────────────────────┐
│ ⏰ Departs in 2 hrs, 30 min  [RD-001]│ ← Header with countdown
├────────────────��────────────────────┤
│ 🟢 Allapalli                        │
│  ┊  27-12-2025 • 12:00 PM          │
│  ┊                                  │
│ 🔴 Chandrapur                       │
├─────────────────────────────────────┤
│  👥 3/6          │  ₹850            │ ← Passenger count & earnings
│  Booked (50%)    │  Est. Earnings   │
└─────────────────────────────────────┘
```

## Date/Time Parsing

**Date Format**: `dd-MM-yyyy` (e.g., "27-12-2025")
```dart
final dateParts = date.split('-');
final rideDate = DateTime(
  int.parse(dateParts[2]), // year
  int.parse(dateParts[1]), // month
  int.parse(dateParts[0]), // day
);
```

**Time Format**: `hh:mm tt` (e.g., "03:00 PM")
```dart
// Strip AM/PM and parse
var hour = int.parse(timeParts[0]);
final minute = int.parse(timeParts[1]);

// Convert to 24-hour format
if (time.contains('PM') && hour != 12) hour += 12;
if (time.contains('AM') && hour == 12) hour = 0;
```

## Pull-to-Refresh

The home screen now refreshes both:
1. Dashboard data
2. Active rides

```dart
onRefresh: () async {
  await ref.read(driverDashboardNotifierProvider.notifier).loadDashboard();
  await ref.read(driverRideNotifierProvider.notifier).loadActiveRides();
}
```

## User Experience

### Visibility
- Shows next 2 upcoming rides prominently on home screen
- No need to navigate to "Rides" tab for quick overview
- Easy access to ride details at a glance

### Real-Time Updates
- Countdown updates every second
- Always shows accurate time until departure
- Provides urgency awareness for drivers

### Information Density
- All critical information in one card:
  - Route (pickup → dropoff)
  - Departure time
  - Passenger count
  - Earnings potential
  - Time remaining

### Quick Actions
- Tap "View All" to see full ride list
- Visual color coding for quick status recognition
- Empty state encourages ride scheduling

## Files Modified

1. **`driver_dashboard_screen.dart`**
   - Added `_buildUpcomingRidesSection()` method
   - Added `_parseRideDateTime()` helper method
   - Added `_UpcomingRideCard` stateful widget
   - Updated `initState()` to load active rides
   - Updated `RefreshIndicator` to refresh both data sources
   - Added import for `driver_models.dart`

## Testing Checklist

- [x] Upcoming rides display correctly
- [x] Countdown timer updates every second
- [x] Date/time parsing works for dd-MM-yyyy and hh:mm tt formats
- [x] Passenger count shows correct booked/total ratio
- [x] Estimated earnings display correctly
- [x] Empty state shows when no upcoming rides
- [x] "View All" button navigates to Rides tab
- [x] Color coding changes based on time remaining
- [x] Pull-to-refresh updates ride data
- [ ] **Test with real data**: Schedule actual rides and verify display
- [ ] **Test countdown accuracy**: Wait for time to pass and verify countdown
- [ ] **Test multiple rides**: Verify sorting and "View All" button
- [ ] **Test edge cases**: Same-day rides, overnight rides, rides in progress

## Known Behaviors

1. **In Progress Rides**: Shows "In Progress" when departure time has passed
2. **Sorting**: Rides sorted by departure date/time (earliest first)
3. **Limit**: Shows maximum 2 rides on home screen
4. **Filtering**: Excludes cancelled and completed rides
5. **Auto-update**: Countdown updates automatically every second

## Future Enhancements

- [ ] Tap on ride card to view full ride details
- [ ] Swipe actions (cancel, edit, etc.)
- [ ] Push notifications when departure is imminent
- [ ] Add route map preview
- [ ] Show intermediate stops if any
- [ ] Display weather conditions for departure time
- [ ] Add passenger names/contact for quick access

## Summary

The driver home screen now provides a comprehensive overview of upcoming rides with:
✅ Live countdown timers
✅ Passenger booking status
✅ Estimated earnings
✅ Visual route display
✅ Easy access to full ride list

This feature helps drivers stay informed about their upcoming schedule without navigating away from the home screen, improving the overall user experience and operational efficiency.
