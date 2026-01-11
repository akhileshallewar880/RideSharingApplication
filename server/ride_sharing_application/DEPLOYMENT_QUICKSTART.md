# Quick Start: Azure Deployment Setup

## ✅ Completed Tasks

### 1. **Repository Cleanup**
- ✅ Deleted all SQL test files
- ✅ Deleted all EF Core migrations
- ✅ Removed sensitive files (Firebase keys, PEM keys)
- ✅ Removed temporary files and build artifacts
- ✅ Removed old script files

### 2. **.gitignore Updated**
- ✅ Added Azure-specific exclusions
- ✅ Added environment file exclusions
- ✅ Added log file exclusions
- ✅ Enhanced security patterns

### 3. **CI/CD Pipeline Created**
- ✅ GitHub Actions workflow: `.github/workflows/azure-deploy.yml`
- ✅ Configured for automatic deployment on push to main
- ✅ Set up build and publish steps

### 4. **Documentation Created**
- ✅ Comprehensive deployment guide: `AZURE_DEPLOYMENT.md`
- ✅ Example configuration file: `appsettings.example.json`

---

## 🚀 Next Steps to Deploy

### Step 1: Get Azure Publish Profile
1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **vayatra-app-service**
3. Click **Get publish profile** button (top menu)
4. Download the `.PublishSettings` file

### Step 2: Add GitHub Secret
1. Go to your GitHub repository
2. **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
   - Name: `AZURE_WEBAPP_PUBLISH_PROFILE`
   - Value: Paste entire XML content from publish profile
4. Click **Add secret**

### Step 3: Configure Azure App Service

#### Connection String
1. Azure Portal → **vayatra-app-service** → **Configuration**
2. **Connection strings** → **New connection string**
   - Name: `DefaultConnection`
   - Value: `Server=tcp:vayatra-server.database.windows.net,1433;Initial Catalog=vanyatra-server-db;Persist Security Info=False;User ID=vanyatraadminlogin;Password={YOUR_PASSWORD};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;`
   - Type: `SQLAzure`

#### Application Settings
Add these in **Application settings**:
```
ASPNETCORE_ENVIRONMENT = Production
Jwt__Secret = {your-jwt-secret-minimum-32-chars}
Jwt__Issuer = https://vayatra-app-service.azurewebsites.net
Jwt__Audience = https://vayatra-app-service.azurewebsites.net
Jwt__ExpiryInMinutes = 60
```

### Step 4: Deploy
```bash
git add .
git commit -m "Setup Azure deployment with CI/CD"
git push origin main
```

GitHub Actions will automatically deploy your app!

### Step 5: Run Database Migrations
After first deployment:
```bash
# Locally with Azure connection string
cd server/ride_sharing_application
dotnet ef migrations add InitialMigration --project RideSharing.API
dotnet ef database update --project RideSharing.API
```

### Step 6: Test Your API
Visit: `https://vayatra-app-service.azurewebsites.net`

---

## 📋 Configuration Checklist

- [ ] GitHub secret `AZURE_WEBAPP_PUBLISH_PROFILE` added
- [ ] Azure SQL connection string configured
- [ ] JWT settings added to App Service
- [ ] CORS configured (if needed)
- [ ] Code pushed to GitHub main branch
- [ ] GitHub Actions workflow ran successfully
- [ ] Database migrations applied
- [ ] API tested and working

---

## 🔍 Monitoring

### View Logs
```bash
# Azure CLI
az webapp log tail --name vayatra-app-service --resource-group vayatra-app-service_group

# Or in Azure Portal
App Service → Log stream
```

### GitHub Actions
- Repository → **Actions** tab
- View workflow runs and logs

---

## 🆘 Troubleshooting

**Deployment fails?**
- Check GitHub Actions logs
- Verify publish profile is valid
- Ensure .NET version matches (8.0.x)

**Can't connect to database?**
- Check connection string in Azure
- Verify Azure SQL firewall allows Azure services
- Test connection with Azure Data Studio

**500 errors?**
- Check App Service logs
- Verify all app settings are configured
- Check if migrations were applied

---

## 📚 Resources

- Full guide: [AZURE_DEPLOYMENT.md](AZURE_DEPLOYMENT.md)
- Example config: [appsettings.example.json](appsettings.example.json)
- GitHub Actions: [.github/workflows/azure-deploy.yml](../.github/workflows/azure-deploy.yml)

---

## 🎯 Your Azure Details

```
App Service:      vayatra-app-service
Resource Group:   vayatra-app-service_group
Database Server:  vayatra-server.database.windows.net
Database:         vanyatra-server-db
URL:              https://vayatra-app-service.azurewebsites.net
```

Good luck with your deployment! 🚀
