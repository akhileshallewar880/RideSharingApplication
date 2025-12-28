# Segment Pricing Feature - Backend API Requirements

## Overview
The mobile app now supports **segment-based pricing** for rides with intermediate stops. This allows drivers to set different prices for each segment of the journey, with smart auto-calculation and manual override capabilities.

## Changes Required in Backend API

### 1. Update Domain Model

**File:** `Models/Domain/Ride.cs`

Add new field to the `Ride` entity:

```csharp
public class Ride
{
    // ... existing fields ...
    
    /// <summary>
    /// JSON array of segment prices for routes with intermediate stops
    /// </summary>
    public string? SegmentPrices { get; set; }
    
    // Format: [
    //   {
    //     "fromLocation": "Allapalli",
    //     "toLocation": "Bhamragarh", 
    //     "price": 283.0,
    //     "suggestedPrice": 283.0,
    //     "isOverridden": false
    //   },
    //   ...
    // ]
}
```

### 2. Update DTOs

**File:** `Models/DTO/DriverRideDto.cs`

#### 2.1 Create SegmentPriceDto

```csharp
public class SegmentPriceDto
{
    public string FromLocation { get; set; } = string.Empty;
    public string ToLocation { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public decimal SuggestedPrice { get; set; }
    public bool IsOverridden { get; set; }
}
```

#### 2.2 Update ScheduleRideRequestDto

```csharp
public class ScheduleRideRequestDto
{
    // ... existing fields ...
    
    /// <summary>
    /// Optional: Segment-based pricing for routes with intermediate stops
    /// If not provided, use pricePerSeat for all segments
    /// </summary>
    public List<SegmentPriceDto>? SegmentPrices { get; set; }
}
```

#### 2.3 Update DriverRideDto (Response)

```csharp
public class DriverRideDto
{
    // ... existing fields ...
    
    /// <summary>
    /// Segment prices if configured by driver
    /// </summary>
    public List<SegmentPriceDto>? SegmentPrices { get; set; }
}
```

### 3. Database Migration

**Migration Name:** `AddSegmentPricingToRides`

```sql
ALTER TABLE Rides
ADD SegmentPrices NVARCHAR(MAX) NULL;
```

**Rollback:**
```sql
ALTER TABLE Rides
DROP COLUMN SegmentPrices;
```

### 4. Update Controller Logic

**File:** `Controllers/DriverRidesController.cs`

**Endpoint:** `POST /api/v1/driver/rides/schedule`

#### 4.1 Validation Rules

Add validation in the schedule endpoint:

```csharp
// Validate segment prices if provided
if (request.SegmentPrices != null && request.SegmentPrices.Any())
{
    // Must have intermediate stops to use segment pricing
    if (request.IntermediateStops == null || !request.IntermediateStops.Any())
    {
        return BadRequest(new ApiResponse<object>
        {
            Success = false,
            Message = "Segment prices require intermediate stops"
        });
    }
    
    // Total segments should match (pickup -> intermediate stops -> dropoff)
    var expectedSegments = request.IntermediateStops.Count + 1;
    if (request.SegmentPrices.Count != expectedSegments)
    {
        return BadRequest(new ApiResponse<object>
        {
            Success = false,
            Message = $"Expected {expectedSegments} segment prices, got {request.SegmentPrices.Count}"
        });
    }
    
    // All prices must be positive
    if (request.SegmentPrices.Any(sp => sp.Price <= 0))
    {
        return BadRequest(new ApiResponse<object>
        {
            Success = false,
            Message = "All segment prices must be greater than zero"
        });
    }
}
```

#### 4.2 Save Segment Prices

```csharp
// Serialize segment prices to JSON if provided
if (request.SegmentPrices != null && request.SegmentPrices.Any())
{
    ride.SegmentPrices = JsonSerializer.Serialize(request.SegmentPrices);
}
```

#### 4.3 Return Segment Prices in Response

```csharp
// Deserialize segment prices for response
List<SegmentPriceDto>? segmentPrices = null;
if (!string.IsNullOrEmpty(ride.SegmentPrices))
{
    segmentPrices = JsonSerializer.Deserialize<List<SegmentPriceDto>>(ride.SegmentPrices);
}

return new DriverRideDto
{
    // ... existing fields ...
    SegmentPrices = segmentPrices
};
```

### 5. Passenger Booking Logic

**File:** `Controllers/PassengerBookingController.cs` or similar

When a passenger books a ride with intermediate stops, calculate the price based on segments:

#### 5.1 Price Calculation Logic

```csharp
private decimal CalculateBookingPrice(Ride ride, string pickupLocation, string dropoffLocation)
{
    // If no segment prices, use base price
    if (string.IsNullOrEmpty(ride.SegmentPrices))
    {
        return ride.PricePerSeat;
    }
    
    var segmentPrices = JsonSerializer.Deserialize<List<SegmentPriceDto>>(ride.SegmentPrices);
    if (segmentPrices == null || !segmentPrices.Any())
    {
        return ride.PricePerSeat;
    }
    
    // Build complete route
    var allStops = new List<string> { ride.PickupLocation };
    if (!string.IsNullOrEmpty(ride.IntermediateStops))
    {
        var intermediateStops = JsonSerializer.Deserialize<List<string>>(ride.IntermediateStops);
        if (intermediateStops != null)
        {
            allStops.AddRange(intermediateStops);
        }
    }
    allStops.Add(ride.DropoffLocation);
    
    // Find pickup and dropoff indices
    var pickupIndex = allStops.FindIndex(s => s.Equals(pickupLocation, StringComparison.OrdinalIgnoreCase));
    var dropoffIndex = allStops.FindIndex(s => s.Equals(dropoffLocation, StringComparison.OrdinalIgnoreCase));
    
    // If locations not found in route, use base price
    if (pickupIndex == -1 || dropoffIndex == -1 || pickupIndex >= dropoffIndex)
    {
        return ride.PricePerSeat;
    }
    
    // Sum prices of segments between pickup and dropoff
    decimal totalPrice = 0;
    for (int i = pickupIndex; i < dropoffIndex && i < segmentPrices.Count; i++)
    {
        totalPrice += segmentPrices[i].Price;
    }
    
    return totalPrice;
}
```

#### 5.2 Usage in Booking Endpoint

```csharp
// Calculate price based on passenger's pickup and dropoff
var pricePerSeat = CalculateBookingPrice(ride, request.PickupLocation, request.DropoffLocation);

var booking = new Booking
{
    // ... other fields ...
    PricePerSeat = pricePerSeat,
    TotalAmount = pricePerSeat * request.PassengerCount
};
```

### 6. API Request/Response Examples

#### 6.1 Schedule Ride with Segment Pricing

**Request:**
```json
POST /api/v1/driver/rides/schedule
Content-Type: application/json
Authorization: Bearer {token}

{
  "pickupLocation": {
    "address": "Allapalli",
    "latitude": 19.5,
    "longitude": 80.0
  },
  "dropoffLocation": {
    "address": "Chandrapur",
    "latitude": 19.95,
    "longitude": 79.3
  },
  "intermediateStops": ["Bhamragarh", "Mul"],
  "travelDate": "2025-11-30T00:00:00Z",
  "departureTime": "06:00",
  "vehicleType": "SUV",
  "vehicleModelId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "totalSeats": 7,
  "pricePerSeat": 850,
  "segmentPrices": [
    {
      "fromLocation": "Allapalli",
      "toLocation": "Bhamragarh",
      "price": 300,
      "suggestedPrice": 283,
      "isOverridden": true
    },
    {
      "fromLocation": "Bhamragarh",
      "toLocation": "Mul",
      "price": 250,
      "suggestedPrice": 283,
      "isOverridden": true
    },
    {
      "fromLocation": "Mul",
      "toLocation": "Chandrapur",
      "price": 300,
      "suggestedPrice": 284,
      "isOverridden": true
    }
  ],
  "scheduleReturnTrip": false
}
```

**Response:**
```json
{
  "success": true,
  "message": "Ride scheduled successfully",
  "data": {
    "rideId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "rideNumber": "RIDE20251130060000",
    "pickupLocation": "Allapalli",
    "dropoffLocation": "Chandrapur",
    "intermediateStops": ["Bhamragarh", "Mul"],
    "travelDate": "2025-11-30T00:00:00Z",
    "departureTime": "06:00",
    "totalSeats": 7,
    "bookedSeats": 0,
    "availableSeats": 7,
    "pricePerSeat": 850,
    "segmentPrices": [
      {
        "fromLocation": "Allapalli",
        "toLocation": "Bhamragarh",
        "price": 300,
        "suggestedPrice": 283,
        "isOverridden": true
      },
      {
        "fromLocation": "Bhamragarh",
        "toLocation": "Mul",
        "price": 250,
        "suggestedPrice": 283,
        "isOverridden": true
      },
      {
        "fromLocation": "Mul",
        "toLocation": "Chandrapur",
        "price": 300,
        "suggestedPrice": 284,
        "isOverridden": true
      }
    ],
    "status": "scheduled",
    "createdAt": "2025-11-29T15:30:00Z"
  }
}
```

#### 6.2 Passenger Booking Price Calculation Example

**Scenario:** Passenger books from Bhamragarh to Chandrapur

**Calculation:**
- Segment 2 (Bhamragarh → Mul): ₹250
- Segment 3 (Mul → Chandrapur): ₹300
- **Total Price per Seat: ₹550** (instead of ₹850 for full journey)

For 2 passengers: **Total Amount: ₹1,100**

### 7. Backward Compatibility

- `segmentPrices` field is **optional**
- If not provided, system falls back to `pricePerSeat` for all segments
- Existing rides without segment pricing continue to work
- Passengers booking on rides without segment pricing use base `pricePerSeat`

### 8. Database Indexing (Optional but Recommended)

Consider indexing for performance:

```sql
-- If querying by segment pricing frequently
CREATE INDEX IX_Rides_SegmentPrices 
ON Rides(SegmentPrices) 
WHERE SegmentPrices IS NOT NULL;
```

### 9. Testing Checklist

- [ ] Schedule ride without segment pricing (backward compatibility)
- [ ] Schedule ride with segment pricing and intermediate stops
- [ ] Validate error when segment count doesn't match route segments
- [ ] Validate error when segment prices are negative or zero
- [ ] Validate error when segment pricing provided without intermediate stops
- [ ] Calculate passenger booking price for full journey
- [ ] Calculate passenger booking price for partial journey (pickup/dropoff at intermediate stops)
- [ ] Verify segment prices are returned in ride details API
- [ ] Verify segment prices stored correctly in database
- [ ] Test with return trip scheduling

### 10. Known Considerations

1. **Rounding:** Suggested prices may have decimal values - mobile app rounds to nearest integer for display
2. **Currency:** All prices are in INR (₹)
3. **Validation:** Frontend validates segment count matches route, but backend should validate again
4. **Override Flag:** The `isOverridden` flag is informational only - not used for business logic
5. **Return Trips:** Segment prices should be reversed for return journeys (handled by frontend)

---

## Summary

The segment pricing feature enhances the ride scheduling system by allowing:
- ✅ Drivers to set different prices for each route segment
- ✅ Auto-calculated smart suggestions based on base price
- ✅ Manual override capability per segment
- ✅ Accurate pricing for passengers boarding at intermediate stops
- ✅ Full backward compatibility with existing pricing model

**Priority:** Medium (enhancement)  
**Breaking Changes:** None (fully backward compatible)  
**Estimated Backend Effort:** 4-6 hours

**Questions or Issues?** Contact the mobile development team.
