# Ride Auto-Cancellation - Mobile Integration Guide

## Overview
The backend now automatically cancels rides and bookings that have passed their scheduled time without starting. This document explains how the mobile app should handle these cancellations.

---

## What Gets Auto-Cancelled?

### Rides
- **Status**: `scheduled` or `upcoming`
- **Condition**: Travel date/time + 15 minute grace period has passed
- **New Status**: `cancelled`
- **Cancellation Reason**: "Automatically cancelled: Scheduled time passed without departure"

### Bookings
- **Related to cancelled rides**
- **New Status**: `cancelled` (if unpaid) or `refunded` (if paid)
- **Cancellation Type**: `system`
- **Cancellation Reason**: Same as ride

---

## API Changes

### 1. Ride Status Values
The `status` field can now be:
- `scheduled` - Future ride
- `upcoming` - Ride happening soon
- `active` - Ride in progress
- `completed` - Ride finished
- **`cancelled`** - Ride cancelled (manual or auto)

### 2. Booking Status Values
The `status` field can now be:
- `pending` - Payment pending
- `confirmed` - Booking confirmed
- `active` - Ride started
- `completed` - Ride completed
- **`cancelled`** - Booking cancelled
- **`refunded`** - Booking cancelled with refund

### 3. Cancellation Type
New field: `cancellationType`
- `passenger` - Cancelled by passenger
- `driver` - Cancelled by driver
- **`system`** - Auto-cancelled by system

---

## Notifications

Users will receive push notifications when rides/bookings are auto-cancelled:

### Driver Notification
```json
{
  "id": "...",
  "userId": "driver-id",
  "title": "Ride Automatically Cancelled",
  "message": "Your ride DR2401 was automatically cancelled because the scheduled departure time has passed.",
  "type": "ride_cancelled",
  "referenceId": "ride-id",
  "isRead": false,
  "createdAt": "2025-12-23T10:30:00Z"
}
```

### Passenger Notification
```json
{
  "id": "...",
  "userId": "passenger-id",
  "title": "Booking Automatically Cancelled",
  "message": "Your booking ALR2401234 was automatically cancelled because the ride did not depart as scheduled. A refund has been initiated.",
  "type": "booking_cancelled",
  "referenceId": "booking-id",
  "isRead": false,
  "createdAt": "2025-12-23T10:30:00Z"
}
```

---

## Mobile App Changes Required

### 1. Handle Cancelled Status in UI

#### Ride List (Driver App)
```dart
// In ride list item widget
Widget buildRideStatus(Ride ride) {
  if (ride.status == 'cancelled') {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.cancel, color: Colors.red, size: 16),
          SizedBox(width: 4),
          Text(
            'Cancelled',
            style: TextStyle(
              color: Colors.red.shade900,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  // ... other statuses
}
```

#### Booking List (Passenger App)
```dart
Widget buildBookingStatus(Booking booking) {
  Color statusColor;
  IconData statusIcon;
  String statusText;
  
  switch (booking.status) {
    case 'cancelled':
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Cancelled';
      break;
    case 'refunded':
      statusColor = Colors.orange;
      statusIcon = Icons.money_off;
      statusText = 'Refunded';
      break;
    // ... other statuses
  }
  
  return Chip(
    avatar: Icon(statusIcon, size: 16, color: statusColor),
    label: Text(statusText),
    backgroundColor: statusColor.withOpacity(0.1),
  );
}
```

### 2. Show Cancellation Details

#### Ride Detail Screen (Driver)
```dart
if (ride.status == 'cancelled' && ride.cancellationReason != null) {
  return Card(
    color: Colors.red.shade50,
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Cancellation Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(ride.cancellationReason ?? 'No reason provided'),
        ],
      ),
    ),
  );
}
```

#### Booking Detail Screen (Passenger)
```dart
if (booking.cancellationType == 'system') {
  return AlertDialog(
    icon: Icon(Icons.info_outline, color: Colors.orange),
    title: Text('Auto-Cancelled Booking'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(booking.cancellationReason ?? ''),
        if (booking.status == 'refunded')
          Padding(
            padding: EdgeInsets.only(top: 16),
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A refund of ₹${booking.totalAmount} has been initiated and will be processed within 5-7 business days.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('OK'),
      ),
    ],
  );
}
```

### 3. Filter Out Cancelled Rides

#### Active Rides Tab (Driver)
```dart
Future<List<Ride>> fetchActiveRides() async {
  final response = await apiService.getRides();
  
  // Filter out cancelled rides from active tab
  return response.rides
      .where((ride) => ride.status != 'cancelled')
      .toList();
}
```

#### Create Separate History Tab
```dart
Future<List<Ride>> fetchRideHistory() async {
  final response = await apiService.getRides();
  
  // Show completed and cancelled rides in history
  return response.rides
      .where((ride) => 
          ride.status == 'completed' || 
          ride.status == 'cancelled')
      .toList();
}
```

### 4. Handle Real-Time Updates

If a ride gets cancelled while user is viewing it:

```dart
// Using WebSocket or polling
void handleRideUpdate(Ride updatedRide) {
  if (updatedRide.status == 'cancelled') {
    // Show alert to user
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Ride Cancelled'),
        content: Text(
          updatedRide.cancellationReason ??
          'This ride has been cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to list
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

### 5. Refresh Booking Lists

Implement pull-to-refresh to get latest status:

```dart
Future<void> refreshBookings() async {
  setState(() => isLoading = true);
  
  try {
    final bookings = await apiService.getMyBookings();
    setState(() {
      myBookings = bookings;
      isLoading = false;
    });
  } catch (e) {
    // Handle error
    setState(() => isLoading = false);
  }
}

// In build method
RefreshIndicator(
  onRefresh: refreshBookings,
  child: ListView.builder(
    itemCount: myBookings.length,
    itemBuilder: (context, index) {
      return BookingListItem(booking: myBookings[index]);
    },
  ),
)
```

---

## Testing

### Test Scenarios

1. **Create Past Ride**
   - Create a ride with past date/time
   - Wait 5 minutes (or restart backend)
   - Verify ride status changes to `cancelled`

2. **Create Booking for Past Ride**
   - Create a booking
   - Wait for auto-cancellation
   - Verify booking status changes to `cancelled` or `refunded`

3. **Notification Reception**
   - Ensure notification appears when ride is cancelled
   - Test notification navigation to ride/booking details

4. **UI Updates**
   - Verify cancelled rides show appropriate UI
   - Test that active rides list excludes cancelled rides
   - Check history tab includes cancelled rides

---

## API Endpoints to Test

### Get Rides
```
GET /api/rides
```
Response should include `cancelled` rides with `cancellationReason`.

### Get Bookings
```
GET /api/bookings/my-bookings
```
Response should include cancelled bookings with `cancellationType` = `system`.

### Get Notifications
```
GET /api/notifications
```
Should include auto-cancellation notifications.

---

## Constants Updates

Update your app constants file:

```dart
// lib/app/constants/app_constants.dart

class RideStatus {
  static const String scheduled = 'scheduled';
  static const String upcoming = 'upcoming';
  static const String active = 'active';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
}

class BookingStatus {
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String active = 'active';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String refunded = 'refunded';
}

class CancellationType {
  static const String passenger = 'passenger';
  static const String driver = 'driver';
  static const String system = 'system';
}

class NotificationType {
  static const String rideCreated = 'ride_created';
  static const String bookingConfirmed = 'booking_confirmed';
  static const String rideCancelled = 'ride_cancelled';
  static const String bookingCancelled = 'booking_cancelled';
}
```

---

## User Experience Recommendations

### For Drivers
1. Show cancelled rides in a separate "History" or "Past Rides" tab
2. Display cancellation reason clearly
3. Provide option to create a new ride with same details
4. Show grace period information when creating rides

### For Passengers
1. Clear refund status and timeline
2. Easy rebooking option
3. Notification with explanation
4. Contact support option for refund queries

---

## Questions?

- Backend API: Check API documentation
- Auto-cancellation settings: See `AUTO_CANCELLATION_GUIDE.md`
- Database schema: See `DATABASE_SCHEMA.md`
