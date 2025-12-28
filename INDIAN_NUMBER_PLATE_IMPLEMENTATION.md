# Indian Number Plate Display Implementation

## Overview
Implemented authentic Indian vehicle number plate display to help passengers easily identify their booked vehicles. The design matches real Indian number plates with tri-color stripe (Saffron, White, Green) and IND marker.

## Business Requirement
> "passenger is able to find the vehicle easily, however we are showing vehicle model, but if we show a number plate with the exact real number plate design which I have attached will be good option"

## Implementation Details

### 1. Created Reusable Number Plate Widget
**File:** `/mobile/lib/shared/widgets/indian_number_plate.dart`

#### Features:
- **Authentic Design**: White background with black border, tri-color stripe (🟧⬜🟩), and "IND" marker
- **Smart Formatting**: Automatically parses and formats various input formats
  - Input: `MH40BP4231` or `MH 40 BP 4231`
  - Output: `MH 40BP 4231` (standardized format)
- **Scalable**: Adjustable size via `scale` parameter
- **Two Variants**:
  - `IndianNumberPlate`: Full-sized with customizable scale
  - `CompactIndianNumberPlate`: Pre-scaled 0.7x version for smaller displays

#### Design Specifications:
```dart
- Background: White (#FFFFFF)
- Border: Black, 2px
- Tri-color Stripe: 4px width
  - Saffron (#FF9933)
  - White (#FFFFFF)  
  - Green (#138808)
- Text: 
  - IND: 10px, Bold, Black
  - Number: 16px, Extra Bold (900), Monospace, Black
- Shadow: Optional black shadow with 0.2 opacity
```

### 2. Updated Data Models
**File:** `/mobile/lib/core/models/passenger_ride_models.dart`

#### Changes:
- Added `vehicleNumber` field to `RideHistoryItem` model
- Updated `fromJson()` to parse `vehicleNumber` from API response
- Field Type: `String?` (nullable)

```dart
class RideHistoryItem {
  // ... existing fields
  final String? vehicleNumber;
  
  factory RideHistoryItem.fromJson(Map<String, dynamic> json) {
    return RideHistoryItem(
      // ... existing fields
      vehicleNumber: json['vehicleNumber'],
    );
  }
}
```

### 3. Updated Ride History Screen
**File:** `/mobile/lib/features/passenger/presentation/screens/ride_history_screen.dart`

#### Changes:
- Imported `indian_number_plate.dart` widget
- Replaced vehicle model text with `CompactIndianNumberPlate` widget
- Vehicle model now shown as secondary info in parentheses
- Example: `[MH 40BP 4231] (Maruti Swift)`

**Before:**
```dart
Icon(Icons.directions_car) + Text('Vehicle: Maruti Swift')
```

**After:**
```dart
CompactIndianNumberPlate(vehicleNumber: ride.vehicleNumber!) 
+ Text('(Maruti Swift)')  // Optional, if available
```

### 4. Updated Home Screen Banner
**File:** `/mobile/lib/features/passenger/presentation/screens/passenger_home_screen.dart`

#### Changes:
- Imported `indian_number_plate.dart` widget
- Replaced vehicle text with scaled Indian number plate in scheduled ride banner
- Number plate displayed on white background with shadow for visibility on green banner
- Scale: 0.8x with additional 0.85 transform scale for optimal sizing

**Visual Impact:**
- OTP on left (green gradient container)
- Number plate on right (authentic white plate with tri-color)
- Both prominently displayed in green banner
- Plate stands out clearly against green background

## User Experience Benefits

### 1. **Easy Vehicle Identification** ✅
- Passengers can quickly spot their vehicle using the number plate
- Matches the actual physical plate on the vehicle
- No confusion between similar vehicle models

### 2. **Authentic Design** ✅
- Uses real Indian number plate format with IND marker
- Tri-color stripe represents Indian flag
- Professional and recognizable design

### 3. **Better Visibility** ✅
- White background stands out on colored cards
- Bold, monospace font improves readability
- Shadow adds depth for better contrast

### 4. **Smart Formatting** ✅
- Handles various input formats automatically
- Adds spaces for readability: `MH 40BP 4231`
- Consistent display across the app

## Display Locations

### 1. Ride History Screen (Bookings Tab)
- Compact number plate shown for all rides with vehicle number
- Vehicle model shown as secondary info in parentheses
- Clean, modern card layout

### 2. Home Screen Banner
- Scheduled ride banner shows number plate prominently
- Scaled to fit banner layout (0.68x effective size)
- Displayed on right side next to OTP

### 3. Future Locations (Existing in other screens)
- Ride Results Screen: Already has compact number plate
- Ride Checkout Screen: Already has full-size number plate
- Ride Tracking Screen: Can be added for consistency

## Technical Details

### Widget Parameters

#### `IndianNumberPlate`
```dart
IndianNumberPlate(
  vehicleNumber: 'MH40BP4231',  // Required: vehicle registration number
  scale: 1.0,                    // Optional: size multiplier (default: 1.0)
  showShadow: true,              // Optional: show shadow (default: true)
)
```

#### `CompactIndianNumberPlate`
```dart
CompactIndianNumberPlate(
  vehicleNumber: 'MH40BP4231',  // Required: vehicle registration number
  showShadow: false,             // Optional: show shadow (default: false)
)
// Automatically uses scale: 0.7
```

### Format Support
The widget automatically handles these formats:
- `MH40BP4231` → `MH 40BP 4231`
- `MH 40 BP 4231` → `MH 40BP 4231`
- `MH40BP1234` → `MH 40BP 1234`
- Invalid formats → Displayed as-is with smart spacing

### Pattern Recognition
- State Code: 2 letters (e.g., MH, DL, KA)
- District Code: 1-2 digits (e.g., 40, 01)
- Series: 1-2 letters (e.g., BP, A)
- Number: 1-4 digits (e.g., 4231, 123)

## API Requirements

### Expected Response Fields
The backend should include `vehicleNumber` in these endpoints:

1. **Ride History API**: `GET /api/bookings/history`
```json
{
  "bookingNumber": "BKG123",
  "vehicleNumber": "MH40BP4231",  // ← Required
  "vehicleModel": "Maruti Swift",
  // ... other fields
}
```

2. **Available Rides API**: Already included
3. **Booking Response API**: Should include in driverDetails

### Fallback Behavior
- If `vehicleNumber` is null or empty: Widget not shown
- If `vehicleModel` is available: Show as secondary text
- If both missing: Neither displayed (graceful degradation)

## Testing Checklist

- [x] Created reusable Indian number plate widget
- [x] Added vehicleNumber field to RideHistoryItem model
- [x] Updated ride history screen to display number plate
- [x] Updated home screen banner to display number plate
- [x] Fixed compilation errors
- [x] Number plate formatting works correctly
- [ ] Test with real API data
- [ ] Verify visibility on different backgrounds
- [ ] Test with various number plate formats
- [ ] Verify on different screen sizes

## Files Modified

1. ✅ `/mobile/lib/shared/widgets/indian_number_plate.dart` - **CREATED**
2. ✅ `/mobile/lib/core/models/passenger_ride_models.dart` - Modified
3. ✅ `/mobile/lib/features/passenger/presentation/screens/ride_history_screen.dart` - Modified
4. ✅ `/mobile/lib/features/passenger/presentation/screens/passenger_home_screen.dart` - Modified

## Design Reference
Based on attached image showing Indian number plate format:
- White background with black border
- "IND" prefix with tri-color stripe
- Format: `MH 40BP 4231`
- Bold, uppercase letters
- Professional appearance

## Next Steps

1. **Backend**: Ensure all ride/booking APIs return `vehicleNumber` field
2. **Testing**: Test with real data from API
3. **Consistency**: Consider updating other screens (if not already done)
4. **Enhancement**: Add animation on number plate appearance
5. **Localization**: Support other countries' plate formats if needed

## Impact Summary

### Before:
- Text display: "Vehicle: Maruti Swift"
- Generic car icon
- Hard to identify specific vehicle

### After:
- Authentic number plate: `[IND | MH 40BP 4231]`
- Tri-color Indian flag stripe
- Easy vehicle identification at pickup location
- Professional, native appearance

---

**Implementation Date:** December 22, 2025  
**Status:** ✅ Complete - Ready for Testing with Real API Data
