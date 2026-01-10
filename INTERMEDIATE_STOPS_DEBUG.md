# Intermediate Stops Debug Guide

## Backend Status
✅ **Running on:** http://192.168.88.10:5056
✅ **Detailed logging enabled** - Search requests will show:
   - What locations are being searched
   - Each ride being checked
   - Intermediate stops found in each ride
   - Location matching results
   - Final match count

## How to Debug

### 1. Start Watching Backend Logs
```bash
tail -f /tmp/api.log | grep -E "🔍|🚗|✅|❌|📍|⏰|📊"
```

### 2. Search for a Ride in Mobile App
- Make sure to search for a route that has intermediate stops
- Example: If ride is Nagpur → Wardha → Chandrapur
  - Try searching: Nagpur → Wardha
  - Try searching: Wardha → Chandrapur
  - Try searching: Nagpur → Chandrapur

### 3. Check the Log Output
The log will show:
```
🔍 SEARCH REQUEST: 'Wardha' → 'Chandrapur' on 2026-01-04
⏰ Current IST: 2026-01-03 16:14:48, Min departure: 2026-01-03 16:19:48
📊 Found X total rides, Y after time filter

🚗 Checking Ride <ride-id>: Nagpur → Chandrapur
   IntermediateStops: ["Wardha"]
   Main route match: false
   Parsed 1 intermediate stops: Wardha
   Complete route: Nagpur → Wardha → Chandrapur
   ✅ Pickup matched at index 1: 'Wardha' matches 'Wardha'
   ✅ Dropoff matched at index 2: 'Chandrapur' matches 'Chandrapur'
   📍 Pickup index: 1, Dropoff index: 2, Match: true

✅ SEARCH COMPLETE: Found 1 matching rides
```

### 4. Common Issues to Look For

#### Issue: "IntermediateStops: NONE"
**Problem:** Ride doesn't have intermediate stops in database
**Solution:** Create a ride with intermediate stops using admin dashboard

#### Issue: "Parsed 0 intermediate stops" or JSON error
**Problem:** IntermediateStops field has invalid JSON
**Solution:** Check database - IntermediateStops should be: `["City1","City2","City3"]`

#### Issue: "Pickup index: -1" or "Dropoff index: -1"
**Problem:** Location names don't match
**Possible causes:**
- Different format: "Wardha" vs "Wardha, Maharashtra, India"
- Typo in location name
- Extra spaces or special characters

**Solution:** The `LocationsMatch()` function should handle this, but check exact names in logs

#### Issue: "Match: false" (when both indices are found)
**Problem:** Pickup comes after dropoff in the route (wrong direction)
**Solution:** User is searching backwards (e.g., searching Chandrapur → Nagpur when route is Nagpur → Chandrapur)

#### Issue: "Found 0 matching rides" but rides exist
**Problem:** Time filter removed all rides
**Check:** ⏰ line shows "Min departure" time - all rides must depart after this

### 5. Manual Database Check

Check rides with intermediate stops:
```sql
SELECT TOP 10
    Id,
    PickupLocation,
    DropoffLocation,
    IntermediateStops,
    TravelDate,
    DepartureTime,
    Status
FROM Rides
WHERE Status = 'scheduled'
    AND TravelDate >= CAST(GETDATE() AS DATE)
    AND IntermediateStops IS NOT NULL
    AND IntermediateStops != ''
ORDER BY TravelDate, DepartureTime;
```

Check the format of IntermediateStops:
```sql
SELECT IntermediateStops FROM Rides WHERE Id = '<ride-id>';
```

Should return something like:
```json
["Wardha, Maharashtra","Butibori"]
```

### 6. Test from Terminal

You can also test the API directly:
```bash
curl -X POST http://192.168.88.10:5056/api/v1/rides/search \
  -H "Content-Type: application/json" \
  -d '{
    "pickupLocation": {
      "address": "Wardha",
      "latitude": 20.0,
      "longitude": 78.0
    },
    "dropoffLocation": {
      "address": "Chandrapur",
      "latitude": 19.95,
      "longitude": 79.30
    },
    "travelDate": "2026-01-04",
    "passengerCount": 1
  }'
```

Then immediately check logs:
```bash
tail -100 /tmp/api.log | grep -A 20 "🔍 SEARCH REQUEST"
```

## What to Share if Still Not Working

1. **Backend logs from search:**
   ```bash
   tail -200 /tmp/api.log | grep -A 30 "🔍 SEARCH"
   ```

2. **Actual ride data from database:**
   ```sql
   SELECT Id, PickupLocation, DropoffLocation, IntermediateStops, TravelDate, DepartureTime
   FROM Rides
   WHERE IntermediateStops IS NOT NULL AND IntermediateStops != ''
   LIMIT 3;
   ```

3. **Exact search terms you're using in the mobile app**

4. **Screenshot of the search results (showing 0 results)**

## Quick Verification

To verify logging is working, just do any search from the mobile app and run:
```bash
tail -50 /tmp/api.log | grep "🔍"
```

You should see: `🔍 SEARCH REQUEST: '<pickup>' → '<dropoff>' on <date>`

If you don't see this, the backend isn't receiving the search request (check network/API endpoint in mobile app).
