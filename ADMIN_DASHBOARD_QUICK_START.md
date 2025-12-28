# 🚀 Quick Start Guide - Admin Dashboard

## Step-by-Step Testing Instructions

### ✅ Prerequisites Check
- [x] Backend API built successfully
- [x] Flutter dependencies installed
- [ ] SQL Server running
- [ ] Admin user created in database

---

## 🔧 Step 1: Create Admin User

### Execute SQL Script
```bash
# Option 1: SQL Server Management Studio (SSMS)
1. Open SSMS
2. Connect to your SQL Server instance
3. Open file: server/ride_sharing_application/AddAkhileshAdmin.sql
4. Click Execute (or press F5)
5. Verify output shows "Admin user verified successfully"

# Option 2: Command Line (sqlcmd)
cd /Users/akhileshallewar/project_dev/taxi-booking-app/server/ride_sharing_application
sqlcmd -S localhost -d RideSharingDb -i AddAkhileshAdmin.sql

# Option 3: Azure Data Studio
1. Open Azure Data Studio
2. Connect to database
3. Open AddAkhileshAdmin.sql
4. Run script
```

**Credentials Created:**
- Email: `akhileshallewar880@gmail.com`
- Password: `Akhilesh@22`
- Role: `admin`

---

## 🖥️ Step 2: Start Backend API

```bash
cd /Users/akhileshallewar/project_dev/taxi-booking-app/server/ride_sharing_application/RideSharing.API

# Start the API
dotnet run

# Expected output:
# info: Microsoft.Hosting.Lifetime[14]
#       Now listening on: http://localhost:5056
# info: Microsoft.Hosting.Lifetime[0]
#       Application started. Press Ctrl+C to shut down.
```

**Verify API is running:**
```bash
curl http://localhost:5056/api/v1/health
# Should return 200 OK or API info
```

---

## 🎨 Step 3: Start Flutter Admin Web App

```bash
cd /Users/akhileshallewar/project_dev/taxi-booking-app/admin_web

# Run in Chrome (recommended for debugging)
flutter run -d chrome

# OR run for production build
flutter run -d chrome --release

# Expected output:
# Launching lib/main.dart on Chrome in debug mode...
# Running with sound null safety
# Built build/web/main.dart.js
# Serving web app on http://localhost:xxxxx/
```

---

## 🧪 Step 4: Test Login

### Navigate to Login
1. Browser should automatically open to `http://localhost:xxxxx/`
2. App will check auth and redirect to `/login`

### Login with Admin Credentials
```
Email: akhileshallewar880@gmail.com
Password: Akhilesh@22
```

**Expected Results:**
- ✅ Login button shows loading indicator
- ✅ API receives request (check backend console logs)
- ✅ JWT token stored in secure storage
- ✅ Redirect to `/dashboard`
- ✅ Sidebar shows "Allapalli Ride Admin Control Center"
- ✅ User email shown in bottom of sidebar

**Troubleshooting:**
- If "Invalid credentials": Check SQL script was executed
- If "Network error": Verify API is running on localhost:5056
- If "CORS error": Check Program.cs has AllowAnyOrigin()

---

## 🗺️ Step 5: Test Live Tracking Screen

### Navigate to Live Tracking
1. Click **"Live Tracking"** in sidebar (map icon)
2. OR type URL: `http://localhost:xxxxx/#/tracking`

### Expected Results:
- ✅ Breadcrumb shows "Dashboard > Live Tracking"
- ✅ Quick stats show "Active Rides: 1, Available: 1, Offline: 1"
- ✅ Google Maps loads with 3 markers
- ✅ Driver sidebar shows 3 drivers
- ✅ Search box functional
- ✅ Filter chips work (All/Active/Available/Offline)

### Test Interactions:
1. **Search:** Type "Rajesh" → List filters to 1 driver
2. **Filter:** Click "Active" chip → Map shows only green markers
3. **Click Driver Card:** Map zooms to driver location
4. **Clear Search:** Delete text → All drivers reappear

**Mock Data Visible:**
- 🟢 Rajesh Kumar (Active) - MH 31 AB 1234
- 🟡 Amit Sharma (Available) - MH 31 CD 5678
- 🔴 Suresh Patil (Offline) - MH 31 EF 9012

---

## 👥 Step 6: Test User Management Screen

### Navigate to User Management
1. Click **"User Management"** in sidebar (people icon)
2. OR type URL: `http://localhost:xxxxx/#/users`

### Expected Results:
- ✅ Breadcrumb shows "Dashboard > User Management"
- ✅ Stats cards show: Total Users: 4, Active: 3, Drivers: 1, Passengers: 2
- ✅ Table shows 4 users with badges
- ✅ "Create Admin User" button visible
- ✅ Search and filter dropdowns functional

### Test Interactions:

#### 1. Search User
```
Type: "akhilesh"
Expected: Table filters to show only akhileshallewar880@gmail.com
```

#### 2. Filter by User Type
```
Select: "Drivers"
Expected: Table shows only rajesh.kumar@example.com (driver badge)
```

#### 3. Filter by Status
```
Select: "Blocked"
Expected: Table shows only blocked.user@example.com (red status)
```

#### 4. Block User
```
1. Click ⛔ (block icon) next to "amit.sharma@example.com"
2. Modal appears: "Are you sure you want to block..."
3. Click "Block"
4. Success toast appears
5. User status changes to 🔴 BLOCKED
6. Icon changes to ✅ (unblock)
```

#### 5. Unblock User
```
1. Click ✅ (unblock icon) next to blocked user
2. Modal appears: "Are you sure you want to unblock..."
3. Click "Unblock"
4. Success toast appears
5. User status changes to 🟢 ACTIVE
```

#### 6. Delete User
```
1. Click 🗑️ (delete icon) next to "amit.sharma@example.com"
2. Modal appears: "Are you sure you want to delete... cannot be undone"
3. Click "Delete"
4. Success toast appears
5. User removed from table
```

#### 7. Create Admin User
```
1. Click "Create Admin User" button (top right)
2. Dialog appears with form fields
3. Fill in:
   - Email: test.admin@example.com
   - Phone: +919876543220
   - Password: TestAdmin@123
   - Role: Admin (dropdown)
4. Click "Create"
5. Success toast appears
6. Dialog closes
```

**Mock Data Visible:**
| Email | Type | Status | Actions |
|-------|------|--------|---------|
| akhileshallewar880@gmail.com | 🟣 ADMIN | 🟢 ACTIVE | 👁️ ⛔ |
| rajesh.kumar@example.com | 🟡 DRIVER | 🟢 ACTIVE | 👁️ ⛔ 🗑️ |
| amit.sharma@example.com | 🔵 PASSENGER | 🟢 ACTIVE | 👁️ ⛔ 🗑️ |
| blocked.user@example.com | 🔵 PASSENGER | 🔴 BLOCKED | 👁️ ✅ 🗑️ |

---

## 📊 Step 7: Test Analytics Dashboard (Optional)

### Navigate to Analytics
1. Click **"Analytics"** in sidebar
2. Should show existing analytics dashboard
3. Verify data loads (may be dummy data for now)

---

## 🔍 Step 8: Verify Backend API Endpoints

### Test Analytics Endpoints
```bash
# Get dashboard analytics
curl -X GET "http://localhost:5056/api/v1/AdminAnalytics/dashboard" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Get revenue analytics (daily)
curl -X GET "http://localhost:5056/api/v1/AdminAnalytics/revenue?grouping=day" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Get driver analytics
curl -X GET "http://localhost:5056/api/v1/AdminAnalytics/drivers" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Get ride analytics
curl -X GET "http://localhost:5056/api/v1/AdminAnalytics/rides" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Test User Management Endpoints
```bash
# Get paginated users
curl -X GET "http://localhost:5056/api/v1/AdminUsers?page=1&limit=20" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Get specific user
curl -X GET "http://localhost:5056/api/v1/AdminUsers/{userId}" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Block user
curl -X PUT "http://localhost:5056/api/v1/AdminUsers/{userId}/block" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"block": true, "reason": "Testing"}'
```

**Note:** Replace `YOUR_JWT_TOKEN` with actual token from login response or browser localStorage.

---

## 🎉 Success Checklist

- [ ] SQL script executed successfully
- [ ] Backend API started and running on port 5056
- [ ] Flutter web app started and accessible in browser
- [ ] Login successful with admin credentials
- [ ] Redirected to dashboard after login
- [ ] Sidebar navigation working
- [ ] Live Tracking screen loads with Google Maps
- [ ] 3 driver markers visible on map
- [ ] Driver list sidebar functional
- [ ] Search and filters work in Live Tracking
- [ ] User Management screen loads with table
- [ ] 4 users visible in table
- [ ] User type and status badges display correctly
- [ ] Search and filters work in User Management
- [ ] Block/Unblock confirmation modals appear
- [ ] Delete confirmation modal appears
- [ ] Create Admin dialog opens and closes
- [ ] Success toasts appear for actions
- [ ] No console errors in browser DevTools
- [ ] No errors in Flutter terminal
- [ ] No errors in backend API terminal

---

## 🐛 Troubleshooting

### Issue: Login fails with "Invalid credentials"
**Solution:**
1. Verify SQL script executed: Check Users table in database
2. Verify password hash exists for admin user
3. Check backend logs for BCrypt verification errors

### Issue: Maps not loading
**Solution:**
1. Check browser console for API key errors
2. Verify google_maps_flutter_web package installed
3. Check index.html has Google Maps script tag

### Issue: "Network error" on API calls
**Solution:**
1. Verify backend API is running: `curl http://localhost:5056`
2. Check AppConstants.baseUrl in app_constants.dart
3. Verify CORS enabled in Program.cs

### Issue: Sidebar navigation not working
**Solution:**
1. Check routes defined in main.dart
2. Verify AdminLayout wraps each screen
3. Check currentRoute prop matches route path

### Issue: Data table not showing users
**Solution:**
1. Replace mock data with real API call
2. Check AdminUsersController endpoints
3. Verify JWT token in request headers

---

## 📱 Test on Different Browsers

### Chrome (Recommended)
```bash
flutter run -d chrome
```

### Edge
```bash
flutter run -d edge
```

### Safari (macOS only)
```bash
flutter run -d safari
```

---

## 🔄 Next Steps After Testing

1. **Connect Real Data:**
   - Replace mock data in LiveTrackingScreen with SignalR
   - Replace mock data in UserManagementScreen with API calls
   - Wire up analytics dashboard to AdminAnalyticsController

2. **Implement SignalR:**
   - Backend: Create tracking hub methods
   - Mobile: Send location updates
   - Frontend: Subscribe to location events

3. **Add More Features:**
   - User detail screen/dialog
   - Notifications management
   - Finance dashboard
   - Settings page

4. **Polish UI:**
   - Add loading skeletons
   - Improve error messages
   - Add empty states
   - Optimize mobile layout

---

## 📞 Support

**Documentation:**
- [ADMIN_DASHBOARD_IMPLEMENTATION_COMPLETE.md](ADMIN_DASHBOARD_IMPLEMENTATION_COMPLETE.md)
- [ADMIN_DASHBOARD_VISUAL_GUIDE.md](ADMIN_DASHBOARD_VISUAL_GUIDE.md)

**Key Files:**
- Backend: `server/ride_sharing_application/RideSharing.API/Controllers/Admin*.cs`
- Frontend: `admin_web/lib/features/tracking/` and `admin_web/lib/features/users/`
- Routing: `admin_web/lib/main.dart`
- Layout: `admin_web/lib/shared/layouts/admin_layout.dart`

---

**Happy Testing! 🎉**

**Last Updated:** December 25, 2024
