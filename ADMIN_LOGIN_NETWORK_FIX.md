# 🌐 Admin Login - Network & CORS Fix

## 🐛 Problem
Admin web app login API not being hit - no logs appearing in dotnet console.

## ✅ Fixes Applied

### 1. **CORS Configuration Updated** ✅
Changed from restrictive origins to allow all origins for development:

```csharp
// ❌ BEFORE: Only specific ports
policy.WithOrigins("http://localhost:3000", "http://localhost:8080", "http://localhost:5173")

// ✅ AFTER: Allow all origins (development)
policy.AllowAnyOrigin()
      .AllowAnyMethod()
      .AllowAnyHeader()
```

### 2. **Enhanced Logging** ✅

#### Backend (AdminController.cs):
- Added detailed logging when login request is received
- Logs email, request body, and validation failures

#### Frontend (admin_auth_service.dart):
- Added console logging for:
  - Login request start
  - API URL being called
  - Response status
  - Error details (type, message, response)

---

## 🧪 Testing Steps

### Step 1: Restart API
```bash
cd server/ride_sharing_application/RideSharing.API
dotnet run
```

Look for startup message showing the API is listening:
```
Now listening on: http://localhost:5056
```

### Step 2: Run Admin Web App
```bash
cd admin_web
flutter run -d chrome
```

Or:
```bash
flutter run -d web-server --web-port 8080
```

### Step 3: Check Browser Console

Open browser DevTools (F12) and watch for these Flutter logs:
```
🔐 Admin Login - Starting login request...
📍 URL: http://192.168.88.20:5056/api/v1/admin/auth/login
📧 Email: admin@allapalliride.com
```

### Step 4: Check API Console

You should now see these logs in the dotnet console:
```
=== Admin Login Request Received ===
Email: admin@allapalliride.com
Request Body: {"email":"admin@allapalliride.com","password":"..."}
```

---

## 🔍 Troubleshooting

### Issue 1: CORS Error in Browser Console

**Error:**
```
Access to XMLHttpRequest at 'http://192.168.88.20:5056/api/v1/admin/auth/login' 
from origin 'http://localhost:XXXX' has been blocked by CORS policy
```

**Solution:** ✅ Already fixed - API now allows all origins

### Issue 2: Connection Refused

**Error in Browser:**
```
net::ERR_CONNECTION_REFUSED
```

**Checks:**
1. Is API running? Check terminal
2. Is API listening on correct IP/port?
   ```bash
   # Check Program.cs or run:
   netstat -an | grep 5056
   ```
3. Is firewall blocking? Try `http://localhost:5056` instead of `192.168.88.20:5056`

**Quick Fix:** Update admin_web baseUrl:
```dart
// Try localhost first
static const String baseUrl = 'http://localhost:5056/api/v1';
// Or your machine's IP
static const String baseUrl = 'http://192.168.88.20:5056/api/v1';
```

### Issue 3: API Not Logging Requests

**If API console is silent:**

1. Check API is actually running
2. Check the URL in Flutter app logs matches API address
3. Try testing API directly:
   ```bash
   curl -X POST http://192.168.88.20:5056/api/v1/admin/auth/login \
     -H 'Content-Type: application/json' \
     -d '{"email":"admin@allapalliride.com","password":"Admin@123"}'
   ```

### Issue 4: Network Not Reachable

**If using IP address (192.168.88.20):**

1. Ensure both API and admin_web are on same network
2. Check firewall allows connections on port 5056
3. Try localhost instead if running on same machine

---

## 📊 Expected Flow

### 1. User clicks Login in Admin Dashboard
```
Flutter UI → admin_login_screen.dart
```

### 2. Flutter calls API
```dart
// admin_auth_service.dart logs:
🔐 Admin Login - Starting login request...
📍 URL: http://192.168.88.20:5056/api/v1/admin/auth/login
```

### 3. API receives request
```csharp
// AdminController.cs logs:
=== Admin Login Request Received ===
Email: admin@allapalliride.com
```

### 4. API processes and responds
```csharp
// Success:
Admin login successful: admin@allapalliride.com

// Or failure:
Admin login attempt failed: Invalid password
```

### 5. Flutter handles response
```dart
// Success:
✅ Login successful for user: admin@allapalliride.com

// Or error:
❌ DioException during login: Invalid email or password
```

---

## 🎯 Quick Verification

### Check API is accessible:
```bash
curl http://192.168.88.20:5056/api/v1/admin/auth/login
```

Should return:
```json
{"type":"https://tools.ietf.org/html/rfc7231#section-6.5.1","title":"Unsupported Media Type",...}
```
(This means API is responding, just needs proper headers)

### Check with proper headers:
```bash
curl -X POST http://192.168.88.20:5056/api/v1/admin/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"test","password":"test"}'
```

Should return:
```json
{"success":false,"message":"Invalid email or password","data":null}
```
(This confirms API is working!)

---

## ✅ Success Indicators

You'll know it's working when:

1. ✅ Browser console shows Flutter making the request
2. ✅ API console shows "Admin Login Request Received"
3. ✅ API console shows authentication attempt (success or failure)
4. ✅ Flutter console shows response received
5. ✅ No CORS errors in browser

---

## 🔧 Configuration Files Modified

1. **Program.cs** - CORS policy updated
2. **AdminController.cs** - Added request logging
3. **admin_auth_service.dart** - Added detailed logging

---

## 📝 Next Steps

Once you see the API logs:
1. ✅ Verify the request is reaching the API
2. 🔐 Follow the password hash setup (see ADMIN_LOGIN_FIX_GUIDE.md)
3. 🧪 Test successful login

---

## 🚀 Quick Start Commands

```bash
# Terminal 1: Start API
cd server/ride_sharing_application/RideSharing.API
dotnet run

# Terminal 2: Start Admin Web
cd admin_web
flutter run -d chrome

# Terminal 3: Test API directly
curl -X POST http://192.168.88.20:5056/api/v1/admin/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@allapalliride.com","password":"Admin@123"}'
```

Watch both API and browser consoles for logs! 📊
