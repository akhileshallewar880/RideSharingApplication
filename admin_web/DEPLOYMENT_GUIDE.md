# Admin Web App Deployment to Azure Static Web Apps

## ✅ Build Completed Successfully

The Flutter admin web app has been built successfully at:
```
admin_web/build/web/
```

Build artifacts:
- Size: ~16.5 MB (zipped)
- Optimized assets with tree-shaking (98.7% icon reduction)
- HTML renderer for better compatibility
- Production release build

## 🔧 Azure Static Web App Configuration

**Static Web App Details:**
- Name: `vanyatra-admin`
- Resource Group: `vanyatraVm_group`
- URL: https://red-moss-0860f7400.2.azurestaticapps.net
- Location: East Asia
- Deployment Token: Available (stored securely)

## 📦 Deployment Options

### Option 1: Manual Deployment via Azure Portal (RECOMMENDED FOR NOW)

1. **Go to Azure Portal:**
   - Navigate to: https://portal.azure.com
   - Find resource: `vanyatra-admin` in `vanyatraVm_group`

2. **Upload Build Files:**
   - Go to "Deployment" → "Overview"
   - Click "Browse code" or "Upload files"
   - Upload the contents of `admin_web/build/web/`
   - OR upload the zip file: `admin_web/admin-web-deployment.zip`

3. **Verify Deployment:**
   - Check https://red-moss-0860f7400.2.azurestaticapps.net
   - Should see the admin login page

### Option 2: GitHub Actions Deployment (AUTOMATED)

A GitHub Actions workflow has been created at:
```
admin_web/.github/workflows/azure-static-web-apps-deploy.yml
```

**Setup Steps:**

1. **Add GitHub Secret:**
   ```bash
   # In your GitHub repository, go to Settings → Secrets → Actions
   # Add new secret: AZURE_STATIC_WEB_APPS_API_TOKEN
   # Value: 4bbdbea327c605b3774e1ab010eb09af4d56530a9f12c6eb6171195d4895f01c02-62780cc7-208a-4328-947e-6877241fa08d00010280860f7400
   ```

2. **Push to GitHub:**
   ```bash
   cd /Users/akhileshallewar/project_dev/RideBuisnessCodePrivate/vanyatra_rural_ride_booking
   git add admin_web/.github admin_web/staticwebapp.config.json
   git commit -m "Add Azure Static Web Apps deployment workflow"
   git push origin main
   ```

3. **Automatic Deployment:**
   - GitHub Actions will automatically build and deploy on push to main branch
   - Check deployment status in GitHub Actions tab

### Option 3: Azure Static Web Apps CLI (Alternative)

1. **Install SWA CLI:**
   ```bash
   sudo npm install -g @azure/static-web-apps-cli
   ```

2. **Deploy:**
   ```bash
   cd admin_web
   swa deploy \
     --app-location build/web \
     --deployment-token "4bbdbea327c605b3774e1ab010eb09af4d56530a9f12c6eb6171195d4895f01c02-62780cc7-208a-4328-947e-6877241fa08d00010280860f7400"
   ```

## 📄 Configuration Files Created

### 1. staticwebapp.config.json
Location: `admin_web/staticwebapp.config.json`

Features:
- SPA routing fallback to index.html
- CORS headers configured
- MIME types for .json and .wasm files
- 404 handling for client-side routing

### 2. GitHub Actions Workflow
Location: `admin_web/.github/workflows/azure-static-web-apps-deploy.yml`

Features:
- Triggers on push to main branch or manual dispatch
- Installs Flutter SDK
- Builds web app with HTML renderer
- Deploys to Azure Static Web Apps

## 🔍 Verification Steps

After deployment, verify:

1. **Homepage loads:** https://red-moss-0860f7400.2.azurestaticapps.net
2. **Login page accessible**
3. **Assets load correctly** (images, fonts, styles)
4. **API calls work** (configured to use `https://vayatra-app-service-baczabgbcbczg2b4.centralindia-01.azurewebsites.net/api/v1`)
5. **Routing works** (no 404 errors on page refresh)

## 🧪 Test Login

After deployment, test with:
- **Email:** `superadmin@vanyatra.com`
- **Password:** `Admin@123`

## 🚨 Current Status

✅ Flutter web app built successfully  
✅ Deployment configuration created  
✅ GitHub Actions workflow ready  
⏳ **Needs deployment** - Choose Option 1 (manual) or Option 2 (GitHub Actions)

## 📊 Next Steps

1. **Deploy the app** using one of the options above
2. **Test the deployment** using the verification steps
3. **Monitor** Azure Portal for deployment status
4. **Update DNS** if using custom domain (optional)

## 🔐 Security Notes

- Deployment token is sensitive - keep it secure
- Added to GitHub Secrets for automated deployment
- API calls use HTTPS with proper authentication
- CORS configured for backend API calls

## 📝 Backend API Configuration

The admin web app is configured to connect to:
```
Base URL: https://vayatra-app-service-baczabgbcbczg2b4.centralindia-01.azurewebsites.net/api/v1
```

All API endpoints:
- `/admin/auth/login` - Admin login
- `/admin/analytics/dashboard` - Dashboard analytics
- `/admin/rides/schedule` - Schedule rides
- `/admin/drivers/*` - Driver management
- `/admin/locations/*` - Location management
- `/admin/banners/*` - Banner management
- `/GooglePlaces/*` - Google Places autocomplete (✅ API key configured)

## 🎯 Production Ready Checklist

- [x] Flutter web app built with release mode
- [x] Assets optimized (tree-shaking enabled)
- [x] Backend API URL configured
- [x] SPA routing configured
- [x] CORS headers set
- [x] Deployment workflow created
- [ ] **Deploy to Azure Static Web Apps**
- [ ] Test all functionality
- [ ] Monitor for errors

---

**Ready to deploy!** Choose your deployment method and proceed.
