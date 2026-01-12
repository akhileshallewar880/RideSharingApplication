# Analytics 500 Error - FIX

## Problem
Analytics endpoint returning 500 Internal Server Error because of route mismatch.

## Root Cause
- **Frontend** was calling: `/api/v1/admin/analytics/dashboard`
- **Backend** expected: `/api/v1/AdminAnalytics/dashboard` (with capitalization)

## What Was Fixed ✅

### 1. Backend Route (AdminAnalyticsController.cs)
```csharp
// BEFORE:
[Route("api/v1/[controller]")]  // Resolves to /api/v1/AdminAnalytics

// AFTER:
[Route("api/v1/admin/analytics")]  // Explicitly /api/v1/admin/analytics
```

### 2. Frontend Constant (app_constants.dart)
```dart
// BEFORE:
static const String analyticsEndpoint = '/analytics';

// AFTER:
static const String analyticsEndpoint = '/admin/analytics';
```

### 3. Frontend Service (analytics_service.dart)
Now consistently uses `AppConstants.analyticsEndpoint` for all calls.

## Files Modified
1. ✅ `/server/ride_sharing_application/RideSharing.API/Controllers/AdminAnalyticsController.cs`
2. ✅ `/admin_web/lib/core/constants/app_constants.dart`
3. ✅ `/admin_web/lib/core/services/analytics_service.dart`

## How to Deploy

### Option 1: Automatic Deployment (GitHub Actions)
```bash
cd /Users/akhileshallewar/project_dev/RideBuisnessCodePrivate/vanyatra_rural_ride_booking

# Stage changes
git add server/ride_sharing_application/RideSharing.API/Controllers/AdminAnalyticsController.cs
git add admin_web/lib/core/constants/app_constants.dart
git add admin_web/lib/core/services/analytics_service.dart

# Commit
git commit -m "fix: Correct analytics endpoint route mismatch (500 error fix)"

# Push - this will trigger auto-deployment
git push origin main
```

Then monitor: https://github.com/YOUR_USERNAME/YOUR_REPO/actions

### Option 2: Test Locally First
```bash
# Test backend locally
cd server/ride_sharing_application/RideSharing.API
dotnet run

# Test frontend (in another terminal)
cd admin_web
flutter run -d chrome
```

### Option 3: Manual Backend Deployment
```bash
cd server/ride_sharing_application/RideSharing.API
dotnet publish -c Release -o ./publish

# Deploy via Azure CLI
az webapp deployment source config-zip \
  --resource-group vayatra-app-service_group \
  --name vayatra-app-service \
  --src publish.zip
```

## How to Test After Deployment

### 1. Wait for Deployment
- GitHub Actions: ~3-5 minutes
- Manual: ~2-3 minutes

### 2. Restart Flutter App
```bash
cd admin_web
# Stop current app (Ctrl+C)
flutter run -d chrome --web-port=49371
```

### 3. Test Analytics
1. Login to admin web app
2. Navigate to Analytics dashboard
3. Should see data without 500 error

### 4. Verify with curl
```bash
# Get your auth token from browser (F12 → Application → Local Storage → admin_auth_token)
TOKEN="your_token_here"

curl -X GET \
  -H "Authorization: Bearer $TOKEN" \
  "https://vayatra-app-service-baczabgbcbczg2b4.centralindia-01.azurewebsites.net/api/v1/admin/analytics/dashboard?startDate=2025-12-14T00:00:00&endDate=2026-01-13T00:00:00"
```

Expected: `HTTP 200` with JSON data

## Troubleshooting

### Still Getting 500 Error?
1. **Check deployment status:**
   ```bash
   az webapp log tail --name vayatra-app-service --resource-group vayatra-app-service_group
   ```

2. **Verify route is updated:**
   ```bash
   # Check if new code is deployed
   curl -I https://vayatra-app-service-baczabgbcbczg2b4.centralindia-01.azurewebsites.net/api/v1/admin/analytics/dashboard
   ```

3. **Check authorization:**
   - Ensure you're logged in as admin
   - Token must have admin or super_admin role

### Backend Not Starting?
Check Azure App Service:
- Portal → App Service → Overview → Check status
- Portal → App Service → Deployment Center → Check last deployment

### Frontend Still Using Old Endpoint?
```bash
cd admin_web
flutter clean
flutter pub get
flutter run -d chrome
```

## Summary
- ✅ Fixed route capitalization mismatch
- ✅ Made endpoint path explicit and consistent
- ✅ Updated frontend constants
- 🚀 Ready to deploy

**Status:** Fixed, pending deployment
**Impact:** Analytics dashboard will work after backend deployment
