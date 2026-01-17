# SignalR Live Tracking Fixes

## Issues Fixed

### 1. Method Name Mismatch
**Problem**: Admin web was calling `JoinRideRoom` and `LeaveRideRoom` but backend had `JoinRide` and `LeaveRide`

**Solution**: Updated frontend to call correct method names:
- Changed `JoinRideRoom` → `JoinRide`
- Changed `LeaveRideRoom` → `LeaveRide`

**Files Modified**:
- `admin_web/lib/core/services/signalr_service.dart`

### 2. Event Handler Mismatch
**Problem**: Frontend was listening for `ReceiveLocationUpdate` and `ReceiveRideStatusUpdate` but backend sends `LocationUpdate` and `TripStatus`

**Solution**: Updated event handlers to match backend events:
- `ReceiveLocationUpdate` → `LocationUpdate`
- `ReceiveRideStatusUpdate` → `TripStatus`
- Added `PassengerUpdate` handler
- Added `JoinedRide` confirmation handler
- Added `Error` handler

**Files Modified**:
- `admin_web/lib/core/services/signalr_service.dart`

### 3. Widget Disposal Error
**Problem**: `Bad state: Cannot use "ref" after the widget was disposed`

**Solution**: 
- Used `WidgetsBinding.instance.addPostFrameCallback` in `initState` with mounted check
- Added mounted check and try-catch in `dispose` method
- Ensured ref is only accessed when widget is still mounted

**Files Modified**:
- `admin_web/lib/features/tracking/widgets/ride_tracking_timeline.dart`

### 4. Missing Admin Monitoring Feature
**Problem**: Backend didn't have `JoinAllRidesRoom` for admin monitoring

**Solution**: Added admin monitoring methods to backend:
- `JoinAllRidesRoom()` - Admin joins monitoring room for all rides
- `LeaveAllRidesRoom()` - Admin leaves monitoring room
- Modified location broadcasting to also send updates to admin monitoring group
- Added admin role check (only admins can join)

**Files Modified**:
- `server/ride_sharing_application/RideSharing.API/Hubs/TrackingHub.cs`

## Backend Changes

### TrackingHub.cs
Added three new methods:

```csharp
public async Task JoinAllRidesRoom()
{
    // Admin joins "admin_all_rides" group
    // Validates user is admin
    // Sends confirmation via JoinedAllRides event
}

public async Task LeaveAllRidesRoom()
{
    // Admin leaves "admin_all_rides" group
}
```

Modified location broadcasting:
```csharp
// Now broadcasts to both ride-specific group AND admin monitoring group
await Clients.Group(groupName).SendAsync("LocationUpdate", locationMessage);
await Clients.Group("admin_all_rides").SendAsync("LocationUpdate", locationMessage);
```

## Frontend Changes

### signalr_service.dart
- Changed hub method invocations to match backend
- Updated all event handlers to match backend event names
- Events now properly parse complex objects instead of simple parameters

### ride_tracking_timeline.dart
- Fixed lifecycle management with proper mounted checks
- Used addPostFrameCallback for safe ref access in initState
- Added error handling in dispose to prevent crashes

## How It Works Now

1. **Admin opens ride details dialog**:
   - Widget calls `ref.read(liveTrackingProvider.notifier).trackRide(rideId)`
   - Provider invokes `JoinRide` on backend hub
   - Backend adds connection to ride-specific group `ride_{rideId}`
   - Backend sends `JoinedRide` confirmation

2. **Driver sends location update**:
   - Driver app calls `SendLocationUpdate` with coordinates
   - Backend broadcasts `LocationUpdate` event to:
     - All passengers in ride group (`ride_{rideId}`)
     - All admins in monitoring group (`admin_all_rides`)
   - Admin web receives event and updates UI with live location

3. **Admin closes ride details dialog**:
   - Widget dispose calls `stopTrackingRide(rideId)` (with mounted check)
   - Provider invokes `LeaveRide` on backend
   - Backend removes connection from ride group
   - No more location updates for that ride

4. **Admin can monitor all rides** (optional):
   - Call `joinAllRidesRoom()` once
   - Receive location updates for ALL active rides
   - Useful for overview/map screens

## Event Flow

```
Backend Event          Frontend Handler       Data Structure
--------------        ----------------       --------------
LocationUpdate    →   LocationUpdate         { rideId, location: {lat, lng, speed, heading}, estimatedArrival, remainingDistance }
TripStatus        →   TripStatus             { rideId, status, message, timestamp }
PassengerUpdate   →   PassengerUpdate        { rideId, bookingId, updateType, timestamp }
JoinedRide        →   JoinedRide             { rideId, timestamp }
Error             →   Error                  { message }
```

## Testing

1. **Test ride-specific tracking**:
   ```
   1. Admin opens ride details for active ride
   2. Check console for "SignalR: Joined ride room: {rideId}"
   3. Driver sends location update
   4. Verify admin sees live location with green badge
   5. Close dialog
   6. Check console for "SignalR: Left ride room: {rideId}"
   ```

2. **Test admin monitoring**:
   ```
   1. Call joinAllRidesRoom() on admin dashboard
   2. Check console for "SignalR: Joined all rides monitoring room"
   3. Any driver location update should appear in console
   4. Call leaveAllRidesRoom() when done
   ```

3. **Test error handling**:
   ```
   1. Open and quickly close ride details (rapid clicks)
   2. Should not see "Cannot use ref after disposed" error
   3. Should see graceful cleanup in console
   ```

## Deployment Checklist

- [ ] Backend changes deployed to Azure App Service
- [ ] Backend restarted to load new TrackingHub code
- [ ] Admin web rebuilt with new SignalR service
- [ ] Admin web deployed to Azure Static Web Apps
- [ ] Test with real driver location updates
- [ ] Verify no console errors during normal use
- [ ] Test rapid dialog open/close for disposal errors
- [ ] Verify admin monitoring feature (if used)

## Troubleshooting

**Issue**: Still seeing "Method does not exist" error
- **Fix**: Ensure backend was properly rebuilt and restarted. SignalR hub changes require app restart.

**Issue**: Location updates not appearing
- **Fix**: 
  1. Check driver is sending updates (`SendLocationUpdate`)
  2. Verify admin joined the ride room (`JoinRide` was called)
  3. Check browser console for SignalR connection status
  4. Verify JWT token is valid and not expired

**Issue**: Widget disposal errors
- **Fix**: Ensure you're using the updated ride_tracking_timeline.dart with mounted checks

**Issue**: Authentication errors
- **Fix**: 
  1. Check JWT token has correct claims (user_type: "admin")
  2. Verify token is included in SignalR connection (`accessTokenFactory`)
  3. Check token hasn't expired

## Security Notes

- ✅ All SignalR methods require authentication (`[Authorize]` on hub)
- ✅ `SendLocationUpdate` restricted to drivers only
- ✅ `JoinAllRidesRoom` restricted to admins only
- ✅ Ride-specific rooms can be joined by any authenticated user (passenger, driver, admin)
- ✅ All operations logged with user ID for audit trail

## Performance Considerations

- Location updates are broadcast, not stored (use database for historical data)
- Each admin connection in monitoring group receives ALL location updates
- Recommend: Only join all rides room when needed (e.g., overview map screen)
- Ride-specific tracking is more efficient for single ride monitoring

## Next Steps

1. Consider adding rate limiting for location updates (max 1 per second)
2. Add heartbeat/ping mechanism to detect disconnected drivers
3. Implement geofencing alerts (driver approaching pickup/dropoff)
4. Add route deviation detection
5. Store location history in database for trip replay
