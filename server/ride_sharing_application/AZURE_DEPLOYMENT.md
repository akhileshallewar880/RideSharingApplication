# Azure Deployment Guide

## Overview
This guide covers deploying the Vanyatra Ride Sharing .NET API to Azure App Service with CI/CD via GitHub Actions.

## Azure Resources
- **App Service**: vayatra-app-service
- **Resource Group**: vayatra-app-service_group
- **Database**: vanyatra-server-db (Azure SQL Database)
- **Server**: vayatra-server.database.windows.net

## Prerequisites
- Azure App Service and Azure SQL Database already configured
- GitHub repository with the code
- Azure CLI installed (optional, for local management)

## Configuration Steps

### 1. Configure App Service Connection String

In Azure Portal:
1. Go to **App Service** → vayatra-app-service
2. Navigate to **Configuration** → **Connection strings**
3. Add a new connection string:
   - **Name**: `DefaultConnection`
   - **Value**: `Server=tcp:vayatra-server.database.windows.net,1433;Initial Catalog=vanyatra-server-db;Persist Security Info=False;User ID=vanyatraadminlogin;Password={your_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;`
   - **Type**: SQLAzure
4. Click **Save**

### 2. Configure App Service Settings

Add the following Application Settings in Azure Portal:
1. Go to **Configuration** → **Application settings**
2. Add these settings:
   ```
   ASPNETCORE_ENVIRONMENT = Production
   JWT_SECRET = {your-jwt-secret-key}
   JWT_ISSUER = https://vayatra-app-service.azurewebsites.net
   JWT_AUDIENCE = https://vayatra-app-service.azurewebsites.net
   ```

### 3. Configure CORS (if needed)

If your frontend is on a different domain:
1. Go to **CORS** in App Service
2. Add allowed origins:
   ```
   https://your-frontend-domain.com
   http://localhost:4200 (for development)
   ```

### 4. Setup GitHub Actions CI/CD

#### Get Publish Profile
1. In Azure Portal, go to your App Service
2. Click **Get publish profile** (Download)
3. Copy the entire XML content

#### Add GitHub Secret
1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `AZURE_WEBAPP_PUBLISH_PROFILE`
5. Value: Paste the publish profile XML
6. Click **Add secret**

### 5. Deploy Your Application

The GitHub Actions workflow (`.github/workflows/azure-deploy.yml`) will automatically deploy when:
- You push to the `main` branch
- Changes are detected in `server/ride_sharing_application/**`
- You manually trigger the workflow

To manually trigger:
1. Go to **Actions** tab in GitHub
2. Select "Deploy .NET API to Azure App Service"
3. Click **Run workflow**

## Database Migration

After first deployment, run migrations:

```bash
# Option 1: Using dotnet CLI (locally with Azure connection)
dotnet ef database update --project ./server/ride_sharing_application/RideSharing.API

# Option 2: Create migrations locally and run on Azure
# Create new migration
cd server/ride_sharing_application
dotnet ef migrations add InitialMigration --project RideSharing.API
dotnet ef database update --project RideSharing.API
```

**Note**: Ensure your local connection string points to Azure SQL Database when running migrations.

## Environment Variables Reference

| Variable | Description | Location |
|----------|-------------|----------|
| `DefaultConnection` | Azure SQL connection string | Connection Strings |
| `JWT_SECRET` | Secret key for JWT token generation | Application Settings |
| `JWT_ISSUER` | Token issuer URL | Application Settings |
| `JWT_AUDIENCE` | Token audience URL | Application Settings |
| `ASPNETCORE_ENVIRONMENT` | Runtime environment (Production) | Application Settings |

## Firebase Configuration

If using Firebase:
1. **DO NOT** commit Firebase JSON key to repository
2. Store Firebase configuration in Azure Key Vault (recommended)
3. Or add as App Service Application Setting:
   - Upload Firebase JSON to Azure and reference via path
   - Or store as JSON string in Application Settings

## Monitoring and Logs

### View Application Logs
1. Go to **App Service** → **Log stream**
2. Or use Azure CLI:
   ```bash
   az webapp log tail --name vayatra-app-service --resource-group vayatra-app-service_group
   ```

### Application Insights (Recommended)
1. Enable Application Insights in App Service
2. Add Application Insights SDK to your .NET project
3. Monitor performance, errors, and usage

## Troubleshooting

### Deployment Fails
- Check GitHub Actions logs for build errors
- Verify publish profile is correct and not expired
- Ensure .NET version matches (currently 8.0.x)

### Database Connection Issues
- Verify connection string in App Service Configuration
- Check firewall rules on Azure SQL Server (allow Azure services)
- Ensure password is correct

### 500 Errors After Deployment
- Check App Service logs
- Verify all configuration settings are correct
- Check if migrations were applied to database

## Security Best Practices

1. **Never commit secrets** to repository
2. Use **Azure Key Vault** for sensitive data
3. Enable **Managed Identity** for App Service to access resources
4. Configure **Azure SQL firewall** to allow only App Service IP
5. Enable **HTTPS only** in App Service
6. Regularly rotate secrets and keys

## Useful Commands

```bash
# View app service logs
az webapp log tail --name vayatra-app-service --resource-group vayatra-app-service_group

# Restart app service
az webapp restart --name vayatra-app-service --resource-group vayatra-app-service_group

# Update connection string
az webapp config connection-string set --name vayatra-app-service \
  --resource-group vayatra-app-service_group \
  --connection-string-type SQLAzure \
  --settings DefaultConnection="your-connection-string"

# View app settings
az webapp config appsettings list --name vayatra-app-service \
  --resource-group vayatra-app-service_group
```

## Next Steps

1. ✅ Push code to GitHub main branch
2. ✅ Verify GitHub Actions workflow completes successfully
3. ✅ Test API endpoints: https://vayatra-app-service.azurewebsites.net
4. ✅ Run database migrations
5. ✅ Configure custom domain (if needed)
6. ✅ Enable Application Insights for monitoring
7. ✅ Set up staging slot for blue-green deployments (optional)

## Support

For issues:
- Check GitHub Actions logs
- Review Azure App Service logs
- Check Application Insights (if enabled)
- Review Azure SQL Database query performance
