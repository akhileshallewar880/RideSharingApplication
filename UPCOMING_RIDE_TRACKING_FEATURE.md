# Upcoming Ride Tracking Feature

## Overview
Passengers can now track upcoming rides in real-time, with appropriate status messages when the driver hasn't started yet.

## Features Implemented

### 1. **Tappable Upcoming Ride Card**
- Upcoming ride card now navigates to live tracking screen
- Shows ride details and current status
- Validates ride ID before navigation

### 2. **Driver Status Detection**
- Checks if driver has started the ride using location data and socket connection
- Shows "Driver yet to start" when ride hasn't begun
- Shows "Heading towards [Next Stop]" when driver is en route

### 3. **Smart Status Display**

#### When Driver Has Started:
```
Header:
- "Heading towards"
- [Next Stop Name]
- "Arriving at 3:45 PM"
- "On time"

Timeline:
- Shows current position with green indicator
- Completed stops marked with green checkmark
- Upcoming stops in grey
```

#### When Driver Hasn't Started:
```
Header:
- "Driver yet to start"
- "Waiting for driver to begin"
- "Scheduled: 3:45 PM"
- "Not started"

Timeline:
- Shows "Waiting" badge in orange
- All stops shown in grey (pending)
- No current position indicator
```

## Technical Implementation

### Files Modified

1. **passenger_home_screen.dart**
   - Updated `_buildFloatingUpcomingRideCard()` to navigate to live tracking
   - Added navigation with ride details

2. **passenger_live_tracking_screen.dart**
   - Added `hasDriverStarted` flag based on location and socket connection
   - Conditional UI rendering based on driver status
   - Updated header to show appropriate messaging
   - Added "Waiting" badge to timeline when driver hasn't started

## User Experience

### Upcoming Ride → Live Tracking Flow:
1. User sees upcoming ride card on home screen (green)
2. Taps on upcoming ride card
3. Opens live tracking screen
4. Shows one of two states:
   - **Not Started**: "Driver yet to start" with scheduled time
   - **Started**: Real-time tracking with driver location

### Timeline Behavior:
- **Not Started**: All stops grey, "Waiting" badge shown
- **Started**: Current stop green with pulse, completed stops with checkmarks, upcoming stops grey

## Status Indicators

| Condition | Header Status | Timeline Badge | Time Display |
|-----------|---------------|----------------|--------------|
| Driver not started | "Driver yet to start" | 🟠 Waiting | "Scheduled: 3:45 PM" |
| Driver started | "Heading towards [Stop]" | None | "Arriving at 3:45 PM" |

## Testing Checklist

- [ ] Tap upcoming ride card → navigates to tracking screen
- [ ] When driver offline → shows "Driver yet to start"
- [ ] When driver offline → shows "Waiting" badge
- [ ] When driver offline → shows "Scheduled" time
- [ ] When driver online → shows "Heading towards"
- [ ] When driver online → shows actual arrival time
- [ ] When driver online → timeline shows current position
- [ ] Timeline updates in real-time as driver moves
- [ ] Back button returns to home screen

## Next Enhancements

1. **Push Notifications**: Notify passenger when driver starts
2. **Estimated Wait Time**: Show minutes until driver starts
3. **Driver Profile**: Show driver photo and vehicle details before start
4. **Pre-trip Chat**: Enable messaging before ride starts
