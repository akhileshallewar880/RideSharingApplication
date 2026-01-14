#!/bin/bash

# Database Verification and Troubleshooting Guide
# Run this after restarting the Azure App Service

set -e

APP_NAME="vayatra-app-service"
RESOURCE_GROUP="vayatra-app-service_group"

echo "================================"
echo "DATABASE ISSUE DIAGNOSIS"
echo "================================"
echo ""

echo "📋 PROBLEM:"
echo "   Admin analytics returning 500 error:"
echo "   'Invalid object name 'Drivers''"
echo ""

echo "🔍 ROOT CAUSE:"
echo "   Database tables haven't been created in Azure SQL"
echo "   The Drivers table (and possibly others) don't exist"
echo ""

echo "✅ SOLUTION:"
echo "   1. The app has database initialization code in Program.cs"
echo "   2. This code runs automatically on app startup"
echo "   3. It creates all required tables using Entity Framework"
echo ""

echo "🔄 STEPS TO FIX:"
echo "   Step 1: Restart the Azure App Service"
echo "   Step 2: Monitor startup logs to verify table creation"
echo "   Step 3: Test the analytics endpoint again"
echo ""

echo "================================"
echo "STEP 1: RESTART APP SERVICE"
echo "================================"
echo ""

if ! command -v az &> /dev/null; then
    echo "⚠️  Azure CLI not installed. Manual steps:"
    echo "   1. Go to Azure Portal: https://portal.azure.com"
    echo "   2. Navigate to: $APP_NAME"
    echo "   3. Click 'Restart' button"
    echo "   4. Wait 2-3 minutes for startup"
    echo ""
    exit 0
fi

if ! az account show &> /dev/null; then
    echo "⚠️  Not logged in to Azure CLI. Manual steps:"
    echo "   1. Run: az login"
    echo "   2. Then run this script again"
    echo ""
    echo "   OR restart manually in Portal:"
    echo "   https://portal.azure.com"
    exit 0
fi

echo "Current status:"
az webapp show --name $APP_NAME --resource-group $RESOURCE_GROUP --query "{name:name, state:state}" -o table

echo ""
read -p "Restart the app now? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔄 Restarting..."
    az webapp restart --name $APP_NAME --resource-group $RESOURCE_GROUP
    echo "✅ Restart command sent"
    echo ""
    echo "⏳ Waiting 30 seconds for startup..."
    sleep 30
fi

echo ""
echo "================================"
echo "STEP 2: CHECK STARTUP LOGS"
echo "================================"
echo ""
echo "Looking for these log messages:"
echo "   ✅ 'Starting database schema creation...'"
echo "   ✅ 'Auth database schema created/verified'"
echo "   ✅ 'Application database schema creation completed'"
echo ""

echo "📝 To view live logs, run:"
echo "   az webapp log tail --name $APP_NAME --resource-group $RESOURCE_GROUP"
echo ""

echo "Or view in Azure Portal:"
echo "   https://portal.azure.com/#@/resource/subscriptions/YOUR_SUB_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Web/sites/$APP_NAME/logStream"
echo ""

echo "================================"
echo "STEP 3: VERIFY DATABASE TABLES"
echo "================================"
echo ""
echo "Expected tables to be created:"
echo "   - Drivers"
echo "   - Users"  
echo "   - Rides"
echo "   - Bookings"
echo "   - VehicleModels"
echo "   - Locations"
echo "   - Banners"
echo "   - Notifications"
echo "   - RouteDistances"
echo "   - ScheduledRides"
echo "   - And more..."
echo ""

echo "================================"
echo "STEP 4: TEST ANALYTICS ENDPOINT"
echo "================================"
echo ""
echo "Test the admin analytics endpoint:"
echo "   1. Open admin web: https://YOUR_ADMIN_URL"
echo "   2. Login with super_admin account"
echo "   3. Check if analytics dashboard loads"
echo "   4. Check browser console for errors"
echo ""

echo "================================"
echo "ALTERNATIVE: MANUAL DATABASE SETUP"
echo "================================"
echo ""
echo "If restart doesn't work, you may need to:"
echo "   1. Connect to Azure SQL Database"
echo "   2. Run EF migrations manually"
echo "   3. Or execute SQL scripts to create tables"
echo ""
echo "Command to generate SQL script:"
echo "   cd server/ride_sharing_application/RideSharing.API"
echo "   dotnet ef migrations script -o schema.sql"
echo ""

echo "================================"
echo "TROUBLESHOOTING"
echo "================================"
echo ""
echo "If tables still don't exist after restart:"
echo ""
echo "1. Check connection string in Azure App Service:"
echo "   az webapp config connection-string list \\"
echo "     --name $APP_NAME \\"
echo "     --resource-group $RESOURCE_GROUP"
echo ""
echo "2. Check app logs for errors:"
echo "   az webapp log tail --name $APP_NAME --resource-group $RESOURCE_GROUP"
echo ""
echo "3. Verify database exists and is accessible:"
echo "   - Check Azure SQL server firewall rules"
echo "   - Verify connection string is correct"
echo "   - Test connection from Azure App Service"
echo ""
echo "4. Check if database initialization code is running:"
echo "   Look for these errors in logs:"
echo "   - Connection timeout"
echo "   - Authentication failed"
echo "   - Permission denied"
echo ""
