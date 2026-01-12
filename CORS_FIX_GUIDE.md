# 🔧 CORS Error Fix Guide

## Problem
Admin web app running on `http://localhost:49371` cannot connect to Azure backend at `https://vayatra-app-service-baczabgbcbczg2b4.centralindia-01.azurewebsites.net` due to CORS policy blocking.

## Root Cause
Azure App Service has its own CORS configuration that overrides the application-level CORS settings in Program.cs.

## Solutions Implemented

### ✅ Solution 1: Updated Backend Code (DONE)
Modified `/server/ride_sharing_application/RideSharing.API/Program.cs` to properly handle CORS with credentials:

```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.SetIsOriginAllowed(origin => true) // Allow all origins dynamically
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials(); // Allow credentials (cookies, auth headers)
    });
});
```

### 🔧 Solution 2: Configure Azure App Service CORS (ACTION REQUIRED)

#### Option A: Via Azure Portal (Recommended for Quick Fix)
1. Go to https://portal.azure.com
2. Navigate to: **App Services** → **vayatra-app-service-baczabgbcbczg2b4**
3. Click on **CORS** (under API section in left menu)
4. Add allowed origins:
   - `http://localhost:49371` (your current development port)
   - `http://localhost:8080` (common Flutter web port)
   - `http://localhost:3000` (common React/Next.js port)
   - `*` (Allow all origins - **only for development, not production!**)
5. ✅ Check **Enable Access-Control-Allow-Credentials**
6. Click **Save** at the top
7. Wait 30 seconds for changes to propagate

#### Option B: Via Azure CLI
```bash
az webapp cors add \
  --name vayatra-app-service-baczabgbcbczg2b4 \
  --resource-group vayatra-app-service_group \
  --allowed-origins 'http://localhost:49371' 'http://localhost:8080' 'http://localhost:3000'

# Or allow all origins (development only!)
az webapp cors add \
  --name vayatra-app-service-baczabgbcbczg2b4 \
  --resource-group vayatra-app-service_group \
  --allowed-origins '*'
```

### 📦 Solution 3: Deploy Backend Changes

#### Automatic Deployment (GitHub Actions)
The code changes will be automatically deployed when you push to the main branch:

```bash
cd /Users/akhileshallewar/project_dev/RideBuisnessCodePrivate/vanyatra_rural_ride_booking
git add server/ride_sharing_application/RideSharing.API/Program.cs
git commit -m "fix: Update CORS configuration to allow credentials and all origins"
git push origin main
```

Then monitor the deployment:
- Go to: https://github.com/YOUR_USERNAME/YOUR_REPO/actions
- Watch the "Deploy .NET API to Azure App Service" workflow
- Deployment typically takes 3-5 minutes

#### Manual Deployment (If GitHub Actions is not set up)
```bash
cd server/ride_sharing_application
dotnet publish RideSharing.API -c Release -o ./publish

# Then upload via Azure Portal or use Azure CLI
az webapp deployment source config-zip \
  --resource-group vayatra-app-service_group \
  --name vayatra-app-service-baczabgbcbczg2b4 \
  --src ./publish.zip
```

## Testing the Fix

### 1. Verify Azure CORS Settings
```bash
az webapp cors show \
  --name vayatra-app-service-baczabgbcbczg2b4 \
  --resource-group vayatra-app-service_group
```

### 2. Test with curl
```bash
curl -X OPTIONS \
  -H "Origin: http://localhost:49371" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -v \
  https://vayatra-app-service-baczabgbcbczg2b4.centralindia-01.azurewebsites.net/api/v1/admin/auth/login
```

Look for these headers in the response:
- `Access-Control-Allow-Origin: http://localhost:49371` (or `*`)
- `Access-Control-Allow-Methods: POST, GET, OPTIONS, ...`
- `Access-Control-Allow-Headers: Content-Type, ...`
- `Access-Control-Allow-Credentials: true`

### 3. Test Admin Login
Run the admin web app and try to login:
```bash
cd admin_web
flutter run -d chrome
```

Expected result: Login should succeed without CORS errors.

## Production Considerations

⚠️ **IMPORTANT**: For production deployment:

1. **Replace `SetIsOriginAllowed(origin => true)` with specific origins:**
   ```csharp
   builder.Services.AddCors(options =>
   {
       options.AddPolicy("Production", policy =>
       {
           policy.WithOrigins(
                   "https://admin.vanyatra.com", // Your production admin domain
                   "https://vanyatra.com",        // Your production user domain
                   "http://localhost:49371"        // Keep for development
               )
               .AllowAnyMethod()
               .AllowAnyHeader()
               .AllowCredentials();
       });
   });
   ```

2. **Update Azure CORS to match:**
   - Remove `*` wildcard
   - Add only specific production domains

3. **Consider using environment variables:**
   ```csharp
   var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>();
   policy.WithOrigins(allowedOrigins)
   ```

## Troubleshooting

### CORS Error Still Occurs After Fix
1. **Clear browser cache**: Ctrl+Shift+Delete → Clear cache
2. **Hard reload**: Ctrl+Shift+R or Cmd+Shift+R
3. **Check Azure deployment**: Ensure new code is deployed
4. **Check Azure logs**: 
   ```bash
   az webapp log tail --name vayatra-app-service-baczabgbcbczg2b4 --resource-group vayatra-app-service_group
   ```
5. **Verify CORS headers**: Use browser DevTools → Network → Check response headers

### Preflight Request Fails
- Ensure OPTIONS method is allowed
- Check that `Access-Control-Allow-Methods` includes your request method
- Verify `Access-Control-Allow-Headers` includes your custom headers

### Authentication Issues After CORS Fix
- Ensure `AllowCredentials()` is set in both backend and Azure CORS
- Check that `withCredentials: true` is set in frontend HTTP client
- Verify JWT tokens are being sent in Authorization header

## Related Files Changed
- ✅ `/server/ride_sharing_application/RideSharing.API/Program.cs` - Updated CORS configuration

## Next Steps
1. Configure Azure CORS via Portal or CLI (Solution 2)
2. Deploy backend changes (Solution 3)
3. Test login functionality
4. Plan production CORS configuration
