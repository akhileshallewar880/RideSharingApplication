# 🚀 Admin Web App Deployment - Quick Start

## Status: ✅ Ready to Deploy

Your admin web app is configured and ready for deployment to Azure Static Web Apps!

---

## 📋 What Has Been Done

### 1. ✅ GitHub Actions Workflow Configured
- File: `.github/workflows/azure-static-web-apps-red-moss-0860f7400.yml`
- Auto-builds Flutter web app on push to main
- Deploys to Azure Static Web Apps automatically
- Manual trigger available

### 2. ✅ Static Web App Configuration
- File: `admin_web/staticwebapp.config.json`
- SPA routing configured
- CORS headers added
- MIME types set for .wasm and .json

### 3. ✅ Deployment Scripts Created
- File: `deploy-admin-web.sh` (local deployment helper)
- File: `ADMIN_WEB_DEPLOYMENT_GUIDE.md` (detailed guide)

### 4. ✅ Files Committed to Git
- Ready to push to GitHub

---

## 🎯 Next Steps (IMPORTANT!)

### Step 1: Add GitHub Secret (REQUIRED)

**This is the MOST IMPORTANT step!**

1. Go to: https://github.com/akhileshallewar880/vanyatra_rural_ride_booking/settings/secrets/actions

2. Click **"New repository secret"**

3. Add this secret:
   ```
   Name: AZURE_STATIC_WEB_APPS_API_TOKEN_RED_MOSS_0860F7400
   
   Value: 4bbdbea327c605b3774e1ab010eb09af4d56530a9f12c6eb6171195d4895f01c02-62780cc7-208a-4328-947e-6877241fa08d00010280860f7400
   ```

4. Click **"Add secret"**

### Step 2: Push to GitHub

```bash
git push origin main
```

### Step 3: Monitor Deployment

1. Go to: https://github.com/akhileshallewar880/vanyatra_rural_ride_booking/actions
2. Watch the "Azure Static Web Apps CI/CD - Admin Web" workflow
3. Wait for green checkmark (takes 3-5 minutes)

### Step 4: Access Your Admin Web App

Once deployed, visit:
**https://red-moss-0860f7400.2.azurestaticapps.net**

---

## 🔄 Alternative: Manual Trigger

If you don't want to push yet, you can manually trigger deployment:

1. Go to: https://github.com/akhileshallewar880/vanyatra_rural_ride_booking/actions
2. Click "Azure Static Web Apps CI/CD - Admin Web"
3. Click "Run workflow" → "Run workflow"
4. Wait for completion

---

## 📊 Your Azure Static Web App Details

| Property | Value |
|----------|-------|
| **App Name** | vanyatra-admin |
| **Resource Group** | vanyatraVm_group |
| **URL** | https://red-moss-0860f7400.2.azurestaticapps.net |
| **Location** | East Asia |
| **Repository** | https://github.com/akhileshallewar880/vanyatra_rural_ride_booking |
| **Branch** | main |

---

## 🎨 What Will Be Deployed

- **Admin Login Page**
- **Driver Management** (verification, activation, deactivation)
- **Ride Monitoring** (real-time active rides, cancellation)
- **Analytics Dashboard** (metrics, charts, revenue tracking)
- **User Interface** (responsive, Material Design 3)

---

## ✅ Verification Checklist

After deployment, verify:
- [ ] Admin login page loads
- [ ] CSS and styling are applied correctly
- [ ] Flutter app initializes without errors
- [ ] Can enter credentials (test login)
- [ ] No console errors in browser
- [ ] Assets and images load correctly

---

## 🐛 Troubleshooting

### If GitHub Actions fails:
1. Check that the secret was added correctly (Step 1 above)
2. Verify secret name matches exactly: `AZURE_STATIC_WEB_APPS_API_TOKEN_RED_MOSS_0860F7400`
3. Review GitHub Actions logs for specific errors

### If app shows blank page:
1. Open browser console (F12)
2. Check for JavaScript errors
3. Verify network requests are completing
4. Check that `staticwebapp.config.json` is deployed

### If API calls fail:
1. Check CORS configuration in `staticwebapp.config.json`
2. Verify backend API URL in Flutter app configuration
3. Test API endpoint directly

---

## 📞 Support Resources

- **GitHub Actions**: https://github.com/akhileshallewar880/vanyatra_rural_ride_booking/actions
- **Azure Portal**: https://portal.azure.com (search for "vanyatra-admin")
- **Detailed Guide**: `ADMIN_WEB_DEPLOYMENT_GUIDE.md`
- **Azure Static Web Apps Docs**: https://learn.microsoft.com/azure/static-web-apps/

---

## 🔑 Important Commands

```bash
# Check git status
git status

# Push to GitHub (triggers deployment)
git push origin main

# Check Azure Static Web App
az staticwebapp show --name vanyatra-admin --resource-group vanyatraVm_group

# Get deployment token
az staticwebapp secrets list --name vanyatra-admin --resource-group vanyatraVm_group

# Rebuild Flutter web
cd admin_web && flutter build web --release --web-renderer html
```

---

## 🎉 You're Almost There!

Just complete Step 1 (add GitHub secret) and Step 2 (push to GitHub), and your admin web app will be live!

**Last Updated**: January 15, 2026
