# Ride Card Layout Improvements

## Summary
Improved ride card layout in search results with better information hierarchy and real database-backed rating count.

## Changes Made

### 1. Backend - Added DriverRatingCount Field

**File:** `server/ride_sharing_application/RideSharing.API/Models/DTO/PassengerRideDto.cs`

- Added `DriverRatingCount` property to `AvailableRideDto` class
- This field will contain the actual count of ratings from the database

```csharp
public int DriverRatingCount { get; set; }
```

### 2. Backend - Query Actual Rating Count

**File:** `server/ride_sharing_application/RideSharing.API/Controllers/RidesController.cs`

- Updated `SearchRides` endpoint to count actual driver ratings from database
- Queries `Ratings` table with filter: `RatedTo == ride.DriverId && RatingType == "Driver"`
- Populates `DriverRatingCount` field in the response

```csharp
var driverRatingCount = _context.Ratings
    .Count(r => r.RatedTo == ride.DriverId && r.RatingType == "Driver");
```

### 3. Frontend - Restructured Ride Card Layout

**File:** `mobile/lib/features/passenger/presentation/screens/ride_results_screen.dart`

#### Layout Changes:

**Top Row:**
- ✅ Moved seats count to top left (previously at bottom)
- ✅ Shows "X Seats Left" with seat icon
- ✅ Discount badge remains at top right

**Time Section:**
- ✅ Shows departure time — duration — arrival time in one row
- ✅ Duration displayed in "5hr 8m" format (converted from "5:08")
- ✅ Added origin and destination names below the times
- ✅ Names are displayed using short format (city name only, before comma)

**Driver Section:**
- ✅ Moved number plate below driver name and vehicle info
- ✅ Structure:
  ```
  Driver Name ✓
  Vehicle Type Model
  [MH 12 AB 1234]
  ```

**Removed:**
- ❌ Old duration and seats row (previously showed "5:08 • 4 Seats (Comfortable)")
- ❌ This was redundant as seats moved to top and duration moved to time row

#### New Helper Functions:

1. **`_formatDuration(String duration)`**
   - Converts "5:08" format to "5hr 8m"
   - Handles both "HH:mm" and "Xh Ym" formats
   - Returns clean duration text

2. **`_getShortName(String location)`**
   - Extracts city name from full address
   - Splits by comma and returns first part
   - Example: "Allapalli, Maharashtra 441111" → "Allapalli"

## Visual Layout

### Before:
```
┌────────────────────────────┐
│ [MH 12 AB 1234]  [DISCOUNT]│
│                            │
│ From: Allapalli ▸ ...      │
│                            │
│ 6:00 AM — 11:08 AM    ₹499 │
│                            │
│ 5:08 • 4 Seats (Comfortable)│
│                            │
│ Driver Name ✓              │
│ SUV Mahindra Scorpio       │
│                      ⭐ 4.8│
└────────────────────────────┘
```

### After:
```
┌────────────────────────────┐
│ 🪑 4 Seats Left    [DISCOUNT]│
│                            │
│ From: Allapalli ▸ ...      │
│                            │
│ 6:00 AM — 5hr 8m — 11:08 AM│
│ Allapalli         Chandrapur│
│                       ₹499 │
│                            │
│ Driver Name ✓              │
│ SUV Mahindra Scorpio       │
│ [MH 12 AB 1234]            │
│                      ⭐ 4.8│
│                       (324)│
└────────────────────────────┘
```

## Benefits

1. **Better Information Hierarchy:**
   - Seats availability (most important for booking decision) is now prominent at top
   - Duration is inline with times for better context
   - Number plate is with driver info where it belongs contextually

2. **More Compact:**
   - Removed redundant duration/seats row
   - Locations shown below times instead of separate section
   - Cleaner, less cluttered appearance

3. **Real Data:**
   - Rating count now shows actual number of ratings from database
   - Previously showed placeholder/incorrect data
   - Users can trust the rating credibility

4. **Better Readability:**
   - Duration in "5hr 8m" format is more intuitive than "5:08"
   - Short location names reduce clutter
   - Number plate clearly associated with vehicle

## Testing Notes

- Test with different seat counts (1-7 seats)
- Test with different duration formats
- Test with long location names (should truncate gracefully)
- Verify rating count displays correctly from database
- Check layout on different screen sizes

## API Response Changes

The backend now returns:
```json
{
  "driverRating": 4.8,
  "driverRatingCount": 324  // ← NEW FIELD
}
```

Frontend already had field in model, so no changes needed to `AvailableRide` class.
