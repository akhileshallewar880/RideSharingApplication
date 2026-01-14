# Debug API 500 Error - Admin Web

## Issue
Admin web app getting 500 internal server error while APIs return 200 in Swagger.

## Common Causes

### 1. **Browser Console is Key**
Open browser DevTools (F12) and check:
- **Console tab**: Look for JavaScript errors or CORS errors
- **Network tab**: Click on failing request to see:
  - Request URL
  - Request Headers (check Authorization header)
  - Response Headers
  - Response Body (actual error message)
  - Status code

### 2. **Possible Root Causes**

#### A. CORS Preflight Failure
**Symptom**: Browser console shows CORS error
**Solution**: Already configured in backend, but check Azure CORS settings:
```bash
az resource show \
  --name vayatra-app-service/config/web \
  --resource-group vayatra-app-service_group \
  --resource-type "Microsoft.Web/sites/config" \
  --query properties.cors
```

#### B. Invalid/Expired Token
**Symptom**: 401 Unauthorized or 500 error
**Solution**: 
1. Clear browser storage (F12 > Application > Clear storage)
2. Login again
3. Check token in browser console:
```javascript
// Run in browser console
localStorage.getItem('admin_auth_token')
```

#### C. Response Format Mismatch
**Symptom**: 500 error with JSON parsing errors in console
**Solution**: Check if backend response matches expected format

#### D. Missing Headers
**Symptom**: 500 error  
**Solution**: Check if `Content-Type: application/json` is set

## Debugging Steps

### Step 1: Enable Detailed Logging
Already added logging interceptor to see all requests/responses in browser console.

### Step 2: Run Admin Web with Logging
```bash
cd admin_web
flutter clean
flutter pub get
flutter run -d chrome --web-port=49371
```

### Step 3: Check Browser Console
1. Open DevTools (F12)
2. Go to Console tab
3. Look for API request logs (🌐, ✅, ❌ emojis)
4. Look for any error messages

### Step 4: Check Network Tab
1. Open DevTools (F12)
2. Go to Network tab
3. Filter by XHR
4. Click on failed request
5. Check:
   - **Headers** tab: Request/Response headers
   - **Preview/Response** tab: Actual error message
   - **Timing** tab: Where time is spent

### Step 5: Test Specific Endpoint
If analytics endpoint fails, test it directly:
```bash
# Get token from browser console
TOKEN="paste_your_token_here"

# Test endpoint
curl -X GET \
  "https://vayatra-app-service-baczabgbcbczg2b4.centralindia-01.azurewebsites.net/api/v1/admin/analytics/dashboard" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -v
```

## Quick Fixes

### Fix 1: Clear Cache and Restart
```bash
cd admin_web
flutter clean
flutter pub get
flutter run -d chrome --web-port=49371
```

### Fix 2: Check Azure CORS Settings
```bash
az resource update \
  --name vayatra-app-service/config/web \
  --resource-group vayatra-app-service_group \
  --resource-type "Microsoft.Web/sites/config" \
  --set properties.cors.supportCredentials=true \
  --set properties.cors.allowedOrigins="['http://localhost:49371','http://localhost:8080','http://127.0.0.1:49371','*']"
```

### Fix 3: Restart Azure App Service
```bash
az webapp restart \
  --name vayatra-app-service \
  --resource-group vayatra-app-service_group
```

## Expected Console Output (Normal)
```
🌐 API Request: POST https://vayatra-app-service.../api/v1/admin/auth/login
📦 Headers: {Content-Type: application/json, Accept: application/json}
✅ API Response: 200 - /admin/auth/login
```

## Error Console Output (Problem)
```
🌐 API Request: GET https://vayatra-app-service.../api/v1/admin/analytics/dashboard
📦 Headers: {Content-Type: application/json, Authorization: Bearer xxx}
❌ API Error: 500 - /admin/analytics/dashboard
❌ Error Type: DioExceptionType.badResponse
❌ Error Message: Http status error [500]
❌ Response Data: {actual error from backend}
```

## Next Steps
1. Run the app and check browser console
2. Find the ❌ error log
3. Copy the "Response Data" 
4. Share it to diagnose the actual backend error
