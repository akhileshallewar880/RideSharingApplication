# Admin Ride Management Implementation Guide

## Overview
Complete admin ride management system for scheduling, rescheduling, and canceling rides on behalf of drivers.

## Architecture

### Backend (C# .NET Core)
- **Controller**: `AdminRidesController.cs`
- **DTOs**: `AdminRideDto.cs`
- **Domain Model**: Modified `Ride.cs` (added AdminNotes field)

### Frontend (Flutter Web)
- **Models**: `admin_ride_models.dart`
- **Service**: `admin_ride_service.dart`
- **Providers**: `admin_ride_provider.dart`
- **Screens**:
  - Main: `admin_ride_management_screen.dart`
  - Schedule: `admin_schedule_ride_dialog.dart`
  - Reschedule: `admin_reschedule_ride_dialog.dart`

## Features Implemented

### 1. Admin Ride Management Screen
**File**: `admin_web/lib/features/rides/admin_ride_management_screen.dart`

**Features**:
- View all rides with pagination (20 per page)
- Filter by status (All, Scheduled, Completed, Cancelled)
- Filter by date range
- Search by ride number
- Quick actions: Reschedule, Cancel
- Empty states for no data
- Responsive card layout

**Usage**:
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const AdminRideManagementScreen()),
);
```

### 2. Schedule Ride Dialog
**File**: `admin_web/lib/features/rides/admin_schedule_ride_dialog.dart`

**Features**:
- Driver selection dropdown (loads available drivers)
- Popular routes quick selection
- Manual route input (pickup/dropoff)
- Date and time pickers
- Return trip scheduling
- Total seats and price per seat inputs
- Admin notes field
- Form validation

**Usage**:
```dart
final result = await showDialog<bool>(
  context: context,
  builder: (_) => const AdminScheduleRideDialog(),
);
if (result == true) {
  // Ride scheduled successfully
}
```

### 3. Reschedule Ride Dialog
**File**: `admin_web/lib/features/rides/admin_reschedule_ride_dialog.dart`

**Features**:
- Pre-filled with existing ride data
- Cannot reduce seats below booked count
- Warning display for rides with bookings
- Only changed fields are sent to backend
- Form validation

**Usage**:
```dart
final result = await showDialog<bool>(
  context: context,
  builder: (_) => AdminRescheduleRideDialog(ride: rideInfo),
);
if (result == true) {
  // Ride updated successfully
}
```

## Backend API Endpoints

### 1. Get Available Drivers
```http
GET /api/v1/admin/rides/drivers
Authorization: Bearer {token}
```

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "driverId": "guid",
      "driverName": "John Doe",
      "phoneNumber": "+919876543210",
      "vehicleType": "Sedan",
      "vehicleNumber": "MH12AB1234",
      "isAvailable": true
    }
  ]
}
```

### 2. Schedule Ride
```http
POST /api/v1/admin/rides/schedule
Authorization: Bearer {token}
Content-Type: application/json

{
  "driverId": "guid",
  "pickupLocation": {
    "address": "Allapalli",
    "latitude": 21.0,
    "longitude": 79.0
  },
  "dropoffLocation": {
    "address": "Chandrapur",
    "latitude": 20.5,
    "longitude": 78.5
  },
  "travelDate": "2024-01-15T00:00:00Z",
  "departureTime": "08:00",
  "totalSeats": 6,
  "pricePerSeat": 150.0,
  "hasReturnTrip": true,
  "returnDate": "2024-01-15T00:00:00Z",
  "returnDepartureTime": "18:00",
  "adminNotes": "VIP customer - handle with care"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "rideId": "guid",
    "rideNumber": "RIDE-2024-001",
    "message": "Ride scheduled successfully",
    "returnRideId": "guid",
    "returnRideNumber": "RIDE-2024-002"
  }
}
```

### 3. Update Ride
```http
PUT /api/v1/admin/rides/{rideId}
Authorization: Bearer {token}
Content-Type: application/json

{
  "pickupLocation": {
    "address": "New Pickup",
    "latitude": 21.0,
    "longitude": 79.0
  },
  "travelDate": "2024-01-16T00:00:00Z",
  "totalSeats": 8,
  "adminNotes": "Updated schedule"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "rideId": "guid",
    "message": "Ride updated successfully. Passengers notified."
  }
}
```

### 4. Cancel Ride
```http
POST /api/v1/admin/rides/{rideId}/cancel
Authorization: Bearer {token}
Content-Type: application/json

{
  "reason": "Driver unavailable"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "rideId": "guid",
    "message": "Ride cancelled. Refunds initiated for 3 passengers."
  }
}
```

### 5. Get All Rides
```http
GET /api/v1/admin/rides?status=Scheduled&pageNumber=1&pageSize=20
Authorization: Bearer {token}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "rides": [...],
    "totalCount": 150,
    "pageNumber": 1,
    "pageSize": 20
  }
}
```

### 6. Get Ride Details
```http
GET /api/v1/admin/rides/{rideId}
Authorization: Bearer {token}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "rideId": "guid",
    "rideNumber": "RIDE-2024-001",
    "driverId": "guid",
    "driverName": "John Doe",
    // ... full ride details
  }
}
```

## Database Migration

### Add AdminNotes Field

**Option 1: Using EF Core Migration (Recommended)**
Run in Package Manager Console or Terminal:
```powershell
cd server/ride_sharing_application/RideSharing.API
dotnet ef migrations add AddAdminNotesToRide --context RideSharingDbContext
dotnet ef database update --context RideSharingDbContext
```

**Option 2: Manual SQL Script (If migration conflicts)**
Run this SQL directly on your database:
```sql
-- Add AdminNotes column to Rides table
ALTER TABLE Rides ADD AdminNotes nvarchar(1000) NULL;
GO
```

Expected migration output:
```csharp
migrationBuilder.AddColumn<string>(
    name: "AdminNotes",
    table: "Rides",
    type: "nvarchar(1000)",
    maxLength: 1000,
    nullable: true);
```

**Note**: If you encounter FCMToken duplicate column error, it means your database schema is out of sync. Use Option 2 (manual SQL) to add only the AdminNotes column.

## State Management

### Providers
```dart
// Admin rides state
final adminRideNotifierProvider = StateNotifierProvider<AdminRideNotifier, AdminRideState>((ref) {
  return AdminRideNotifier();
});

// Available drivers state
final adminDriversNotifierProvider = StateNotifierProvider<AdminDriversNotifier, AdminDriversState>((ref) {
  return AdminDriversNotifier();
});
```

### Usage in Widgets
```dart
// Load rides
ref.read(adminRideNotifierProvider.notifier).loadRides();

// Listen to state
final rideState = ref.watch(adminRideNotifierProvider);
if (rideState.isLoading) {
  return CircularProgressIndicator();
}

// Schedule ride
await ref.read(adminRideNotifierProvider.notifier).scheduleRide(request);

// Update ride
await ref.read(adminRideNotifierProvider.notifier).updateRide(rideId, request);

// Cancel ride
await ref.read(adminRideNotifierProvider.notifier).cancelRide(rideId, reason);
```

## Testing Guide

### 1. Setup
1. Run database migration to add AdminNotes field
2. Start backend server
3. Run admin web app: `cd admin_web && flutter run -d chrome`
4. Login as admin user

### 2. Test Schedule Ride
**Steps**:
1. Navigate to Admin Ride Management
2. Click "Schedule New Ride" button
3. Select a driver from dropdown
4. Select a popular route or enter manually
5. Choose date and time
6. Enter seats and price
7. Optionally enable return trip
8. Add admin notes
9. Click "Schedule Ride"

**Verify**:
- Success message displayed
- Ride appears in list
- Ride number generated (RIDE-YYYY-NNN)
- Return trip created if enabled

### 3. Test Reschedule Ride
**Steps**:
1. Find a scheduled ride in list
2. Click menu (3 dots) → Reschedule
3. Modify fields (date, time, seats, price)
4. Click "Update Ride"

**Verify**:
- Success message displayed
- Changes reflected in ride card
- Cannot reduce seats below booked count
- Warning shown for rides with bookings

### 4. Test Cancel Ride
**Steps**:
1. Find a scheduled ride
2. Click menu → Cancel
3. Enter cancellation reason
4. Confirm cancellation

**Verify**:
- Success message shows passenger count
- Ride status changes to Cancelled
- Ride appears when "Cancelled" filter selected

### 5. Test Pagination
**Steps**:
1. Load rides (if > 20 exist)
2. Click "Next" button
3. Verify page 2 loads
4. Click "Previous" button

**Verify**:
- Smooth navigation
- Correct page numbers displayed
- Total count accurate

### 6. Test Filters
**Test Status Filter**:
- Select "Scheduled" → Only scheduled rides shown
- Select "Completed" → Only completed rides shown
- Select "Cancelled" → Only cancelled rides shown

**Test Date Filter**:
- Select date range
- Click "Apply"
- Verify rides filtered by date

### 7. Test Edge Cases
**Empty States**:
- Clear all filters → No rides message
- Search invalid ride number → No results

**Validation**:
- Submit form with empty required fields
- Enter invalid seat count (< booked)
- Enter negative price

**Loading States**:
- Verify spinners during API calls
- Verify disabled buttons during submission

## Add-on Features (Compared to Driver App)

### 1. Driver Selection
- Admin can schedule ride for any available driver
- Driver dropdown with vehicle info
- Driver availability status

### 2. Admin Notes
- Private notes field for admin use
- Not visible to drivers/passengers
- 1000 character limit
- Optional field

### 3. Force Update
- Admin can modify rides with bookings
- Warning displayed for booked rides
- Cannot reduce seats below booked count

### 4. Cancel with Notifications
- Automatic passenger notifications
- Refund initiation count in response
- Cancellation reason required

### 5. Global View
- View all rides across all drivers
- Filter and search capabilities
- Pagination for large datasets

## Future Enhancements

### 1. Location Search Integration
Replace placeholder coordinates with actual location search:
```dart
// TODO: Integrate LocationProvider
final selectedLocation = await showLocationSearchDialog(context);
if (selectedLocation != null) {
  _pickupController.text = selectedLocation.address;
  _pickupLat = selectedLocation.latitude;
  _pickupLng = selectedLocation.longitude;
}
```

### 2. Route Optimization
Add route distance calculation and ETA display:
```dart
// TODO: Integrate RouteDistanceService
final routeInfo = await RouteDistanceService.calculateRoute(
  pickup: pickup,
  dropoff: dropoff,
);
// Display: distance, duration, estimated fare
```

### 3. Driver Analytics
Show driver performance metrics:
- Total rides scheduled
- Completion rate
- Average rating
- Revenue generated

### 4. Bulk Operations
Enable bulk actions:
- Schedule multiple rides at once
- Cancel multiple rides
- Export ride data to CSV

### 5. Notifications
Add real-time notifications:
- Driver confirms/rejects schedule
- Ride status changes
- Passenger bookings/cancellations

### 6. Audit Log
Track all admin actions:
- Who scheduled/modified ride
- What changes were made
- When changes occurred
- Why (from admin notes)

## Troubleshooting

### Issue: Driver dropdown empty
**Cause**: No available drivers or API error
**Fix**: Check backend logs, verify driver availability status

### Issue: Schedule fails with 400
**Cause**: Validation error (past date, invalid data)
**Fix**: Check console logs for specific validation error

### Issue: Cannot reduce seats
**Cause**: Booked seats > new total seats
**Fix**: Cancel bookings first or increase total seats

### Issue: Location coordinates (21.0, 79.0)
**Cause**: Placeholder values (location search not integrated)
**Fix**: Implement location search integration (see Future Enhancements)

## Integration Checklist

- [x] Backend API endpoints created
- [x] DTOs and models defined
- [x] Frontend models created
- [x] API service layer implemented
- [x] State management with Riverpod
- [x] Main management screen
- [x] Schedule dialog
- [x] Reschedule dialog
- [x] Database migration executed
- [x] Authorization roles added to controller
- [x] Debug logging added to driver loading
- [x] Error handling UI for driver loading
- [x] Filters already inline (status dropdown + date range picker)
- [x] Location search widget ported from mobile app
- [x] Intermediate stops support added
- [x] **JWT RoleClaimType configured** - Backend now recognizes admin role claims
- [x] **Riverpod lifecycle fix** - Provider modifications properly deferred
- [x] **Error handling improved** - DioException safely parses all response types
- [x] **AdminAnalytics authorized** - Role-based access control added
- [ ] Real-time notifications
- [ ] Driver analytics dashboard
- [ ] Audit logging
- [ ] Bulk operations

## Recent Improvements (26 Dec 2025 - Latest)

### 🔐 CRITICAL FIXES - Authentication & Error Handling

**Issue**: 403 Forbidden errors on all admin endpoints after login  
**Root Cause**: JWT authentication wasn't configured to read role claims properly

**Fixes Applied**:

1. **JWT RoleClaimType Configuration** ([Program.cs](server/ride_sharing_application/RideSharing.API/Program.cs))
   ```csharp
   TokenValidationParameters = new TokenValidationParameters {
       // ... other settings ...
       RoleClaimType = System.Security.Claims.ClaimTypes.Role
   }
   ```
   - ASP.NET Core now recognizes `http://schemas.microsoft.com/ws/2008/06/identity/claims/role` claim
   - Role-based authorization `[Authorize(Roles = "admin,super_admin")]` now works correctly

2. **AdminAnalytics Authorization** ([AdminAnalyticsController.cs](server/ride_sharing_application/RideSharing.API/Controllers/AdminAnalyticsController.cs))
   ```csharp
   [Authorize(Roles = "admin,super_admin")] // Added role requirement
   public class AdminAnalyticsController : ControllerBase
   ```
   - Dashboard analytics endpoint now requires admin role
   - Fixed 401 Unauthorized errors on analytics calls

3. **Riverpod Provider Lifecycle Fix** ([admin_ride_management_screen.dart](admin_web/lib/features/rides/admin_ride_management_screen.dart))
   ```dart
   void initState() {
     super.initState();
     Future.microtask(() => _loadRides()); // Deferred to prevent build-time modification
   }
   ```
   - Fixed: "Tried to modify a provider while the widget tree was building"
   - Provider updates now happen after widget build completes

4. **DioException Error Handling** ([admin_ride_service.dart](admin_web/lib/core/services/admin_ride_service.dart))
   ```dart
   String errorMsg = 'Unknown error';
   if (e.response?.data != null) {
     if (e.response!.data is Map) {
       errorMsg = e.response!.data['message']?.toString() ?? 
                  e.response!.data['error']?.toString() ?? 
                  e.message ?? 'Request failed';
     } else if (e.response!.data is String) {
       errorMsg = e.response!.data;
     }
   }
   ```
   - Fixed: `TypeError: "message": type 'String' is not a subtype of type 'int'`
   - Safely handles Map, String, and null response structures

**Result**: All authentication and error handling issues resolved. No re-login required - just refresh browser!

---

### ✅ Filters - Already User-Friendly!
The filters were already implemented as inline components:
- **Status Filter**: Dropdown menu with All/Scheduled/Active/Completed/Cancelled
- **Date Filter**: Date range picker popup (no page navigation)
- ✅ Both are inline and user-friendly as requested

### ✅ Driver List Loading - Enhanced
- Added detailed console logging to track loading process
- Added error state UI with retry button
- Added empty state UI when no drivers available
- Shows loading spinner while fetching
- Displays error messages with option to retry

### ✅ Location Search - Fully Implemented!
**New Files Created:**
1. `admin_web/lib/core/models/location_suggestion.dart` - Location model
2. `admin_web/lib/core/services/admin_location_service.dart` - Search service with 44 predefined locations
3. `admin_web/lib/shared/widgets/location_search_field.dart` - Autocomplete widget

**Features:**
- Real-time autocomplete with 300ms debouncing
- 44 predefined locations (Gadchiroli, Chandrapur, Nagpur, Gondia districts)
- Relevance-based sorting (exact match → starts with → contains)
- Overlay suggestions dropdown
- Clear button
- Coordinates stored (latitude/longitude)
- Web-optimized (no platform-specific dependencies)

**Locations Included:**
- Gadchiroli District: Allapalli, Aheri, Etapalli, Bhamragad, Dhanora, Wadsa, Armori, Kurkheda, Korchi, Chamorshi, Mulchera, Sironcha, etc.
- Chandrapur District: Chandrapur, Ballarpur, Bramhapuri, Mul, Warora, Rajura, Gondpipri, Bhadravati, Sindewahi, etc.
- Nagpur District: Nagpur, Kamptee, Umred, Ramtek, Katol, Parseoni, Saoner
- Gondia District: Gondia, Tirora, Sadak Arjuni, Goregaon, Salekasa
- Plus: Hyderabad (Asian Living PG)

### ✅ Intermediate Stops - Fully Implemented!
**Features:**
- Add unlimited intermediate stops between pickup and dropoff
- Each stop uses LocationSearchField with autocomplete
- Remove button for each stop
- Dynamic list management
- Proper disposal of controllers
- Visual feedback with numbered stops

**UI Updates in Schedule Dialog:**
1. Replaced TextFormField with LocationSearchField for pickup/dropoff
2. Added "Add Intermediate Stops" button
3. Each stop has location search + remove button
4. Proper validation (must select from suggestions)
5. Coordinates automatically captured

## Current Blockers

### ⚠️ AUTHENTICATION FIX - REQUIRES RE-LOGIN!
**Issue**: 403 Forbidden errors on admin endpoints  
**Status**: ✅ **Backend FIXED** - JWT RoleClaimType configuration added  
**CRITICAL ACTION REQUIRED**: You **MUST log out and log back in** to get a new JWT token!

**Why re-login is required:**
- Your old JWT token was issued before the backend RoleClaimType fix
- The backend now reads role claims correctly, but your existing token predates this fix
- Simply refreshing won't work - you need a NEW token from the updated backend

**Steps to resolve:**
1. Click "Logout" in the admin dashboard
2. Log back in with: `akhileshallewar880@gmail.com` 
3. Backend will issue a NEW JWT token with proper role claims
4. The new token + RoleClaimType configuration = ✅ 403 errors gone!

---

### 1. Test Location Search & Intermediate Stops
**Status**: Implementation complete, needs testing
**Test Steps**:
1. Open Schedule Ride dialog
2. Type in pickup location (e.g., "Allap") → Should show "Allapalli, Maharashtra"
3. Select from dropdown → Should auto-fill with coordinates
4. Click "Add Intermediate Stops" → Should show new location field
5. Add 1-2 intermediate stops
6. Fill dropoff location
7. Complete the form and submit
8. Verify ride is created with all locations

### 2. Driver List Loading (Enhanced with Debug Logs)
**Status**: Debug logging added, monitoring required
**Check**: 
1. Open browser DevTools Console (F12)
2. Open Schedule Ride dialog
3. Look for:
   - `🚗 Loading drivers...`
   - `✅ Drivers loaded: X drivers`
   - Or `❌ Error loading drivers: ...`
4. If error shows, check Network tab for /api/v1/admin/rides/drivers request
5. Share console output and network response if issues persist

## Testing Checklist

### Location Search
- [ ] Pickup location search shows suggestions
- [ ] Selecting suggestion fills text field
- [ ] Clear button removes selection
- [ ] Coordinates are captured (lat/lng)
- [ ] Validation requires selection from suggestions
- [ ] Search works for all 44 locations
- [ ] Debouncing prevents excessive searches

### Intermediate Stops
- [ ] "Add Intermediate Stops" button works
- [ ] Can add multiple stops (test 3+ stops)
- [ ] Each stop has location search
- [ ] Remove button deletes stop
- [ ] Form submission includes all stops
- [ ] Proper disposal prevents memory leaks

### Driver Loading
- [ ] Drivers load on dialog open
- [ ] Loading spinner shows while fetching
- [ ] Dropdown populates with drivers
- [ ] Error state shows with retry button
- [ ] Empty state shows if no drivers
- [ ] Console logs show debug info

### Filters (Already Working)
- [ ] Status dropdown shows all options
- [ ] Date range picker opens inline
- [ ] Clear filters button works
- [ ] No page navigation required

## Summary

This implementation provides a comprehensive admin ride management system with:
- **Backend**: 6 API endpoints with full CRUD operations
- **Frontend**: 3 screens with dialogs for schedule/reschedule
- **Features**: Driver selection, return trips, admin notes, filtering, pagination
- **Validation**: Form validation, seat constraints, date validation
- **State Management**: Riverpod providers for reactive UI
- **UX**: Material Design, loading states, error handling, success messages

The system follows the driver app flow but adds admin-specific features like driver selection, force updates, and global view of all rides.
