# SignalR Live Tracking Deployment Guide

## Overview
This guide will help you deploy the SignalR live tracking fixes to Azure.

## Changes Summary
1. ✅ Fixed SignalR method name mismatches (JoinRideRoom → JoinRide)
2. ✅ Fixed SignalR event handler mismatches (ReceiveLocationUpdate → LocationUpdate)
3. ✅ Fixed widget disposal errors with proper lifecycle management
4. ✅ Added admin monitoring feature (JoinAllRidesRoom)
5. ✅ Updated location broadcasting to include admin group

## Prerequisites
- Azure CLI installed and logged in
- Access to Azure subscription
- Backend and admin web apps already deployed

## Step 1: Deploy Backend Changes

### 1.1 Navigate to backend directory
```bash
cd server/ride_sharing_application
```

### 1.2 Build the backend
```bash
dotnet build --configuration Release
```

### 1.3 Publish the backend
```bash
dotnet publish RideSharing.API/RideSharing.API.csproj -c Release -o ./publish
```

### 1.4 Deploy to Azure App Service

**Option A: Using Azure CLI**
```bash
# Get your app service name
APP_SERVICE_NAME="your-app-service-name"

# Create a zip file
cd publish
zip -r ../publish.zip .
cd ..

# Deploy to Azure
az webapp deployment source config-zip \
  --resource-group your-resource-group \
  --name $APP_SERVICE_NAME \
  --src publish.zip
```

**Option B: Using VS Code Azure Extension**
1. Right-click on `RideSharing.API` project
2. Select "Deploy to Web App"
3. Choose your Azure subscription and app service
4. Confirm deployment

**Option C: Using FTP/FTPS**
1. Get deployment credentials from Azure Portal
2. Use FileZilla or another FTP client
3. Upload contents of `publish/` to `/site/wwwroot/`

### 1.5 Restart the App Service
```bash
az webapp restart --name $APP_SERVICE_NAME --resource-group your-resource-group
```

Or restart from Azure Portal:
1. Go to App Service
2. Click "Restart" button
3. Wait for restart to complete

### 1.6 Verify Backend Deployment
```bash
# Check if the app is running
curl https://your-app-service-name.azurewebsites.net/health

# Check SignalR hub endpoint
curl https://your-app-service-name.azurewebsites.net/tracking
```

## Step 2: Deploy Admin Web Changes

### 2.1 Navigate to admin web directory
```bash
cd /Users/akhileshallewar/project_dev/RideBuisnessCodePrivate/vanyatra_rural_ride_booking/admin_web
```

### 2.2 Build admin web
```bash
flutter clean
flutter pub get
flutter build web --release --no-tree-shake-icons
```

### 2.3 Deploy to Azure Static Web Apps

**Option A: Using Azure CLI**
```bash
# Install Static Web Apps CLI (one time)
npm install -g @azure/static-web-apps-cli

# Get your static web app name
STATIC_WEB_APP="your-static-web-app-name"

# Deploy
az staticwebapp deploy \
  --name $STATIC_WEB_APP \
  --resource-group your-resource-group \
  --source build/web \
  --no-use-keychain
```

**Option B: Using SWA CLI**
```bash
swa deploy ./build/web \
  --deployment-token $DEPLOYMENT_TOKEN \
  --env production
```

**Option C: Manual Upload via Portal**
1. Go to Azure Portal → Static Web Apps
2. Click on your static web app
3. Go to "Deployment" → "Deployment Center"
4. Upload `build/web` folder contents

### 2.4 Verify Admin Web Deployment
```bash
# Check if admin web is accessible
curl https://your-static-web-app.azurestaticapps.net

# Check for the updated SignalR service
curl https://your-static-web-app.azurestaticapps.net/assets/AssetManifest.json
```

## Step 3: Verify Live Tracking

### 3.1 Test SignalR Connection
1. Open admin web in browser
2. Open browser console (F12)
3. Log in as admin
4. Look for: `SignalR: Connected successfully`

### 3.2 Test Ride-Specific Tracking
1. Navigate to "Rides" page
2. Click on any scheduled or in-progress ride
3. Check console for: `SignalR: Joined ride room: {rideId}`
4. If driver is active, you should see: `SignalR: Location update - Ride: {rideId}`
5. Look for green "LIVE" badge with coordinates in timeline
6. Close dialog
7. Check console for: `SignalR: Left ride room: {rideId}`

### 3.3 Test with Real Driver
1. Have a driver start a ride in the driver app
2. Driver should send location updates
3. Admin should see location updates in real-time
4. Verify coordinates match driver's actual location

## Step 4: Monitor and Troubleshoot

### 4.1 Backend Logs
```bash
# Stream backend logs
az webapp log tail \
  --name your-app-service-name \
  --resource-group your-resource-group

# Download logs
az webapp log download \
  --name your-app-service-name \
  --resource-group your-resource-group \
  --log-file backend-logs.zip
```

Look for:
- ✅ `User {UserId} (admin) connected to tracking hub`
- ✅ `User {UserId} (admin) joined ride room: {RideId}`
- ✅ `Driver {UserId} sent location update for ride {RideId}`
- ❌ `Method does not exist` - **If you see this, backend didn't restart properly**

### 4.2 Admin Web Logs
Open browser console and look for:
- ✅ `SignalR: Connected successfully`
- ✅ `SignalR: Joined ride room: {rideId}`
- ✅ `SignalR: Location update - Ride: {rideId}, Lat: X, Lng: Y`
- ❌ `SignalR: Error joining ride room` - **Check backend logs**

### 4.3 Common Issues

**Issue 1: "Method does not exist" error**
- **Cause**: Backend not properly restarted or old code still cached
- **Fix**: 
  ```bash
  az webapp restart --name $APP_SERVICE_NAME --resource-group your-resource-group
  # Wait 30 seconds
  # Test again
  ```

**Issue 2: "Cannot use ref after disposed" error**
- **Cause**: Old admin web code still cached in browser
- **Fix**:
  - Hard refresh browser (Ctrl+Shift+R or Cmd+Shift+R)
  - Clear browser cache
  - Verify deployment timestamp in Azure Portal

**Issue 3: SignalR connection fails**
- **Cause**: Authentication token expired or invalid
- **Fix**:
  - Log out and log back in
  - Check JWT token in browser dev tools (Application → Local Storage)
  - Verify token has `user_type: admin` claim

**Issue 4: Location updates not appearing**
- **Cause**: Driver not sending updates OR admin not in room
- **Fix**:
  - Check driver app is active and sending updates
  - Verify admin joined room (check console for "Joined ride room")
  - Check network tab for SignalR websocket connection
  - Verify backend logs show driver location updates

## Step 5: Performance Testing

### 5.1 Test Multiple Admins
1. Open admin web in multiple browser tabs/windows
2. Each should connect independently
3. Verify all receive location updates
4. Check backend logs for multiple connections

### 5.2 Test Rapid Dialog Open/Close
1. Rapidly click on ride → close dialog (10+ times)
2. Should NOT see disposal errors
3. Should see clean joins/leaves in logs
4. Memory should not leak (check Chrome Task Manager)

### 5.3 Test Admin Monitoring (Optional)
If using the admin monitoring feature:
1. Call `joinAllRidesRoom()` from console
2. Should receive updates for ALL active rides
3. More network traffic, use carefully
4. Call `leaveAllRidesRoom()` when done

## Step 6: Rollback Plan (If Needed)

If something goes wrong:

### Backend Rollback
```bash
# Deploy previous version from Git
git checkout <previous-commit>
cd server/ride_sharing_application
dotnet publish RideSharing.API/RideSharing.API.csproj -c Release -o ./publish
# Deploy to Azure (see Step 1.4)
az webapp restart --name $APP_SERVICE_NAME --resource-group your-resource-group
```

### Admin Web Rollback
```bash
# Deploy previous version from Git
git checkout <previous-commit>
cd admin_web
flutter build web --release --no-tree-shake-icons
# Deploy to Azure (see Step 2.3)
```

## Step 7: Post-Deployment Checklist

- [ ] Backend deployed and restarted
- [ ] Admin web built and deployed
- [ ] SignalR connection established (check console)
- [ ] Ride-specific tracking works (green LIVE badge)
- [ ] No "Method does not exist" errors
- [ ] No "Cannot use ref after disposed" errors
- [ ] Multiple admins can connect simultaneously
- [ ] Rapid dialog open/close doesn't cause errors
- [ ] Backend logs show proper joins/leaves
- [ ] Location updates appear in real-time
- [ ] Performance is acceptable (no lag)

## Architecture Overview

```
Driver App                    Backend                     Admin Web
─────────                     ───────                     ─────────
                              TrackingHub
SendLocationUpdate()    →     SaveLocationUpdate()
                              ↓
                              Broadcast to:
                              1. ride_{rideId} group
                              2. admin_all_rides group
                                                          ← LocationUpdate event
                                                          Update timeline UI
                                                          Show green LIVE badge

Admin clicks ride      →      JoinRide(rideId)
                              Add to ride group
                              Send JoinedRide event      → Confirmation received
                              
Driver location change →      LocationUpdate event       → Update coordinates
                                                          Update timestamp
                                                          "Just now" / "2m ago"

Admin closes dialog    →      LeaveRide(rideId)
                              Remove from ride group
```

## Security Notes

- All SignalR methods require authentication
- JWT token must be valid and not expired
- `SendLocationUpdate` restricted to drivers only
- `JoinAllRidesRoom` restricted to admins only
- All operations logged with user ID for audit

## Support

If you encounter issues:
1. Check browser console for errors
2. Check backend logs in Azure Portal
3. Verify network tab shows websocket connection
4. Test with simple curl commands
5. Review SIGNALR_FIXES.md for detailed troubleshooting

## Next Improvements

Consider implementing:
- [ ] Rate limiting for location updates
- [ ] Heartbeat/ping for disconnected drivers
- [ ] Geofencing alerts
- [ ] Route deviation detection
- [ ] Historical trip replay from database
- [ ] Push notifications for admin alerts
