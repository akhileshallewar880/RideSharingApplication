# Admin Web App Deployment Guide

## ✅ Current Status

- **Static Web App**: Created and configured
- **App Name**: vanyatra-admin
- **Resource Group**: vanyatraVm_group
- **URL**: https://red-moss-0860f7400.2.azurestaticapps.net
- **Location**: East Asia
- **Build**: Ready in `admin_web/build/web/`
- **GitHub Actions**: Configured and ready

## 🚀 Deployment Options

### Option 1: GitHub Actions (RECOMMENDED - Automated)

The GitHub Actions workflow has been configured. Follow these steps:

#### Step 1: Add GitHub Secret

1. Go to your GitHub repository: https://github.com/akhileshallewar880/vanyatra_rural_ride_booking

2. Navigate to **Settings** → **Secrets and variables** → **Actions**

3. Click **New repository secret**

4. Add the following secret:
   - **Name**: `AZURE_STATIC_WEB_APPS_API_TOKEN_RED_MOSS_0860F7400`
   - **Value**: `4bbdbea327c605b3774e1ab010eb09af4d56530a9f12c6eb6171195d4895f01c02-62780cc7-208a-4328-947e-6877241fa08d00010280860f7400`

#### Step 2: Push to GitHub

```bash
cd /Users/akhileshallewar/project_dev/RideBuisnessCodePrivate/vanyatra_rural_ride_booking

# Add the updated workflow file
git add .github/workflows/azure-static-web-apps-red-moss-0860f7400.yml

# Commit
git commit -m "Configure GitHub Actions for admin web deployment"

# Push to main branch
git push origin main
```

#### Step 3: Monitor Deployment

- Go to: https://github.com/akhileshallewar880/vanyatra_rural_ride_booking/actions
- Watch the deployment progress
- Once completed (green checkmark), your app will be live

#### Step 4: Manual Trigger (Optional)

If you want to deploy immediately without pushing code:
1. Go to: https://github.com/akhileshallewar880/vanyatra_rural_ride_booking/actions
2. Click on "Azure Static Web Apps CI/CD - Admin Web"
3. Click "Run workflow" → "Run workflow"

---

### Option 2: Azure Portal (Manual Upload)

If you prefer manual deployment:

1. **Go to Azure Portal**:
   - Visit: https://portal.azure.com
   - Navigate to: Resource Groups → vanyatraVm_group → vanyatra-admin

2. **Upload via Portal**:
   - Look for deployment options in the Static Web App overview
   - Upload the build files from `admin_web/build/web/`
   
   OR upload the zip file:
   ```bash
   cd admin_web/build/web
   zip -r ../../../admin-web-deployment.zip .
   ```

3. **Wait for Deployment**: Takes 2-5 minutes

---

### Option 3: Azure Static Web Apps CLI

#### Install the CLI:
```bash
npm install -g @azure/static-web-apps-cli
```

#### Deploy:
```bash
cd /Users/akhileshallewar/project_dev/RideBuisnessCodePrivate/vanyatra_rural_ride_booking

swa deploy \
  --app-location admin_web/build/web \
  --deployment-token "4bbdbea327c605b3774e1ab010eb09af4d56530a9f12c6eb6171195d4895f01c02-62780cc7-208a-4328-947e-6877241fa08d00010280860f7400"
```

---

## 🔍 Verification

After deployment, verify your app at:
**https://red-moss-0860f7400.2.azurestaticapps.net**

Expected behavior:
- ✅ Admin login page loads
- ✅ CSS and assets load correctly
- ✅ Flutter web app initializes
- ✅ Can navigate to login form

## 📋 Configuration Files

### Static Web App Config
Location: `admin_web/staticwebapp.config.json`

Features:
- SPA routing (fallback to index.html)
- CORS headers for API calls
- MIME types for .json and .wasm
- 404 handling

### GitHub Actions Workflow
Location: `.github/workflows/azure-static-web-apps-red-moss-0860f7400.yml`

Triggers:
- Push to main branch (when admin_web/** changes)
- Manual trigger via workflow_dispatch
- Pull requests

Build Process:
1. Checkout code
2. Setup Flutter 3.24.0
3. Install dependencies
4. Build Flutter web (HTML renderer)
5. Deploy to Azure Static Web Apps

---

## 🔧 Troubleshooting

### Issue: GitHub Actions fails with authentication error
**Solution**: Make sure the GitHub secret is added correctly (see Step 1 above)

### Issue: Build fails in GitHub Actions
**Solution**: Check Flutter version compatibility. Current config uses Flutter 3.24.0

### Issue: App shows blank page after deployment
**Solution**: 
1. Check browser console for errors
2. Verify staticwebapp.config.json is included
3. Ensure base href in index.html is correct

### Issue: API calls fail with CORS errors
**Solution**: The staticwebapp.config.json already includes CORS headers. Verify your backend API URL is correct in the Flutter app.

---

## 📝 Quick Commands

### Rebuild Flutter web:
```bash
cd admin_web
flutter build web --release --web-renderer html
```

### Create deployment zip:
```bash
cd admin_web/build/web
zip -r ../../../admin-web-deployment.zip .
```

### Check Azure Static Web App status:
```bash
az staticwebapp show \
  --name vanyatra-admin \
  --resource-group vanyatraVm_group \
  --query "{url:defaultHostname,location:location,branch:branch}" \
  -o table
```

### View deployment history:
```bash
az staticwebapp show \
  --name vanyatra-admin \
  --resource-group vanyatraVm_group \
  --query "contentDistributionEndpoint" \
  -o tsv
```

---

## 🎯 Next Steps

1. **Add GitHub Secret** (Most Important!)
2. **Push to GitHub** to trigger automatic deployment
3. **Verify deployment** at https://red-moss-0860f7400.2.azurestaticapps.net
4. **Test admin login** and all features
5. **Monitor** via Azure Portal and GitHub Actions

---

## 📞 Support

If you encounter issues:
1. Check GitHub Actions logs
2. Check Azure Portal → vanyatra-admin → Logs
3. Review browser console for client-side errors
4. Verify API endpoints are correct in Flutter app

**Last Updated**: January 15, 2026
