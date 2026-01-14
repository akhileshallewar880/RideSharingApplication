#!/bin/bash

# Emergency Backend Deployment Script
# Use this if GitHub Actions isn't deploying automatically

echo "🚀 Manual Backend Deployment to Azure"
echo "======================================"
echo ""

APP_NAME="vayatra-app-service"
RESOURCE_GROUP="vayatra-app-service_group"
PROJECT_PATH="server/ride_sharing_application"

# Check if in correct directory
if [ ! -d "$PROJECT_PATH" ]; then
    echo "❌ Error: Must run from project root"
    exit 1
fi

# Check if Azure CLI is installed and logged in
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI not installed"
    exit 1
fi

if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure. Run: az login"
    exit 1
fi

echo "✅ Prerequisites check passed"
echo ""

# Navigate to project
cd "$PROJECT_PATH" || exit 1

echo "📦 Step 1: Building project..."
dotnet clean
dotnet restore
dotnet build -c Release

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo "✅ Build successful"
echo ""

echo "📦 Step 2: Publishing project..."
rm -rf ./publish
dotnet publish RideSharing.API -c Release -o ./publish

if [ $? -ne 0 ]; then
    echo "❌ Publish failed"
    exit 1
fi

echo "✅ Publish successful"
echo ""

echo "📦 Step 3: Creating deployment package..."
cd publish
zip -r ../deploy.zip . > /dev/null 2>&1
cd ..

echo "✅ Package created"
echo ""

echo "🚀 Step 4: Deploying to Azure..."
az webapp deployment source config-zip \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_NAME" \
    --src deploy.zip

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deployment successful!"
    echo ""
    echo "⏳ Waiting for app to restart..."
    sleep 10
    
    echo "🧪 Testing endpoint..."
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        "https://vayatra-app-service-baczabgbcbczg2b4.centralindia-01.azurewebsites.net/api/v1/admin/analytics/dashboard")
    
    if [ "$response" = "401" ] || [ "$response" = "200" ]; then
        echo "✅ Backend is responding (HTTP $response)"
    else
        echo "⚠️  Backend returned HTTP $response"
        echo "   Check logs: az webapp log tail --name $APP_NAME --resource-group $RESOURCE_GROUP"
    fi
    
    echo ""
    echo "🎉 Deployment Complete!"
    echo ""
    echo "Next steps:"
    echo "1. Restart your Flutter app"
    echo "2. Clear browser cache (Ctrl+Shift+Delete)"
    echo "3. Try logging in again"
else
    echo ""
    echo "❌ Deployment failed"
    echo "   Check Azure Portal for details"
    exit 1
fi

# Cleanup
rm -f deploy.zip

echo ""
