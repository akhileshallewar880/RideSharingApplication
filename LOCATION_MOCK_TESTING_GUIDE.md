# 📍 Location Mock Testing Guide for Driver Tracking

## 🎯 Overview
This guide shows you how to use a location mocking app to test the driver tracking feature by moving the vehicle icon through different stops on the route.

## 📱 Recommended Mock Location Apps

### For Android:
1. **Fake GPS Location** (Best option)
   - Download from Play Store
   - Easy to use with map interface
   - Can save favorite locations

2. **GPS Joystick** 
   - More advanced with movement simulation
   - Can set speed and auto-move

### For iOS:
1. **iTools** (Computer-based)
2. **3uTools** (Computer-based)
3. **Location Faker** (requires developer mode)

## 🔧 Setup Steps

### Step 1: Enable Developer Options (Android)
1. Go to **Settings** → **About Phone**
2. Tap **Build Number** 7 times
3. Go back to **Settings** → **Developer Options**
4. Enable **Allow Mock Locations** or **Select mock location app**
5. Select your location mocking app

### Step 2: Install & Configure Mock App
1. Install **Fake GPS Location** from Play Store
2. Open the app and grant all permissions
3. In Developer Options, set this app as the mock location app

## 🚗 How to Test Driver Tracking

### Step 1: Start a Ride
1. Open the taxi booking app as a **Driver**
2. Go to your **Dashboard** or **Rides** screen
3. Tap on an **active ride** to open the tracking screen

### Step 2: View Route Information
When the tracking screen opens, check the **console logs**. You'll see:

```
📍 ========== ROUTE STOPS WITH COORDINATES ==========
Stop 1/4: Nagpur
  📌 Latitude: 21.1458
  📌 Longitude: 79.0882
  🚶 Pickups: 2, Dropoffs: 0

Stop 2/4: Chandrapur
  📌 Latitude: 19.9615
  📌 Longitude: 79.2961
  🚶 Pickups: 1, Dropoffs: 0

Stop 3/4: Gondia
  📌 Latitude: 21.4540
  📌 Longitude: 80.1974
  🚶 Pickups: 0, Dropoffs: 1

Stop 4/4: Bhandara
  📌 Latitude: 21.1704
  📌 Longitude: 79.6504
  🚶 Pickups: 0, Dropoffs: 2
====================================================
```

### Step 3: Set Initial Location
1. Open your **Fake GPS Location** app
2. Search for the **first stop location** (e.g., "Nagpur")
3. Or manually enter the coordinates from the logs:
   - Latitude: `21.1458`
   - Longitude: `79.0882`
4. Tap **Play** button to set this location
5. Go back to the taxi app

### Step 4: Monitor Location Updates
The app will show logs every few seconds:

```
🎯 ========== LOCATION UPDATE ==========
📍 Current Device Location:
   Latitude: 21.1458
   Longitude: 79.0882
   Accuracy: 10.0m

🚗 Current Stop: 1/4 - Nagpur

🔍 Checking distances to all stops:
✅ Stop 1: Nagpur
     Distance: 0.00km
⏸️ Stop 2: Chandrapur
     Distance: 195.23km
⏸️ Stop 3: Gondia
     Distance: 102.45km
⏸️ Stop 4: Bhandara
     Distance: 75.30km

🔶 Closest Stop: 1 - Nagpur
   Distance: 0.000km
   Threshold: 0.5km

✓ Already at this stop
======================================
```

### Step 5: Move to Next Stop
When you're ready to move to the next stop:

1. The logs will show:
```
💡 NEXT TARGET: Stop 2 - Chandrapur
   Set your location to:
   📌 Lat: 19.9615
   📌 Lng: 79.2961
```

2. In **Fake GPS Location** app:
   - Clear current location (tap Stop)
   - Search for "Chandrapur" or enter coordinates
   - Tap **Play** to set new location

3. Go back to taxi app and wait 5-10 seconds

4. You'll see the vehicle icon **move** between stops!

5. When you reach the stop, logs will show:
```
✨ STOP REACHED! Moving from Stop 1 to Stop 2
```

### Step 6: Complete the Route
Repeat Step 5 for each remaining stop:
- Stop 3: Gondia (21.4540, 80.1974)
- Stop 4: Bhandara (21.1704, 79.6504)

## 📊 Understanding the Icons

- ✅ = Within 500m of this stop (reachable)
- 🔵 = Current stop you're at
- ⏸️ = Not close to this stop yet
- ✨ = Stop reached!
- ✓ = Already at this stop

## 🎨 Visual Cues in the App

### Train-Style Timeline:
- **Yellow/Orange Circle with Car** = Current position
- **Green Circle with Checkmark** = Passed stop
- **Gray Circle** = Upcoming stop
- **Green Line** = Completed segment
- **Gray Line** = Remaining segment

### Car Icon Between Stops:
- When moving between stops, you'll see a **yellow circle with car icon** smoothly animating along the gray line
- This shows real-time progress between two stops

## ⚡ Quick Testing Tips

1. **Start at Stop 1**: Always begin with the first stop coordinates
2. **Wait 5-10 seconds**: After changing location, wait for GPS to update
3. **Check Console**: Look for "LOCATION UPDATE" logs to confirm
4. **Distance Threshold**: Vehicle must be within 0.5km (500m) to register stop
5. **Sequential Movement**: You must reach stops in order (1→2→3→4)

## 🐛 Troubleshooting

### Vehicle Not Moving?
- Check if mock location is enabled in Developer Options
- Ensure Fake GPS app is set as the mock location app
- Try restarting the taxi app
- Check console logs for "Current Device Location" to verify coordinates

### Wrong Coordinates?
- Double-check you're entering Latitude first, then Longitude
- Use exact coordinates from console logs
- Make sure you didn't swap lat/lng values

### App Crashing?
- Disable "High Accuracy" GPS mode
- Grant all location permissions to both apps
- Try a different mock location app

## 📝 Example Test Scenario

```
1. Open driver tracking screen
2. Set location to: 21.1458, 79.0882 (Nagpur)
3. See vehicle at Stop 1 ✓
4. Set location to: 19.9615, 79.2961 (Chandrapur)
5. Watch vehicle move along timeline 🚗
6. See "STOP REACHED!" message ✨
7. Repeat for remaining stops
```

## 🎯 Success Indicators

You'll know it's working when:
- ✅ Console shows "LOCATION UPDATE" every few seconds
- ✅ Distance to stops is calculated correctly
- ✅ Car icon appears on timeline
- ✅ "STOP REACHED!" message appears
- ✅ Stop changes from gray to green with checkmark
- ✅ Progress bar/distance updates

## 📞 Need Help?

If you're stuck:
1. Check the console logs carefully
2. Verify coordinates match exactly
3. Ensure location permissions are granted
4. Try restarting both apps
5. Use a different mock location app

---

**Happy Testing! 🚗💨**
