#!/bin/bash

# Quick CORS Fix for Azure App Service
# This script configures CORS to allow localhost origins

echo "🔧 Configuring CORS for Azure App Service"
echo "=========================================="
echo ""

APP_NAME="vayatra-app-service"
RESOURCE_GROUP="vayatra-app-service_group"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed"
    echo ""
    echo "Please install Azure CLI:"
    echo "  macOS: brew install azure-cli"
    echo "  Or visit: https://aka.ms/azure-cli"
    echo ""
    echo "Alternative: Configure manually via Azure Portal"
    echo "  1. Go to https://portal.azure.com"
    echo "  2. Navigate to: App Services → $APP_NAME"
    echo "  3. Click 'CORS' in the left menu (under API section)"
    echo "  4. Add: http://localhost:49371"
    echo "  5. Or add: * (for all origins)"
    echo "  6. Check 'Enable Access-Control-Allow-Credentials'"
    echo "  7. Click Save"
    exit 1
fi

# Check if logged in
echo "📝 Checking Azure login status..."
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure"
    echo ""
    echo "Please login first:"
    echo "  az login"
    echo ""
    exit 1
fi

echo "✅ Logged in to Azure"
echo ""

# Show current account
echo "📋 Current Azure Account:"
az account show --query "{Name:name, SubscriptionId:id, TenantId:tenantId}" -o table
echo ""

# Get current CORS settings
echo "📋 Current CORS Settings:"
az webapp cors show \
  --name "$APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  2>&1 || echo "Could not fetch current CORS settings"
echo ""

# Ask for confirmation
echo "🎯 This script will configure CORS to allow:"
echo "   - http://localhost:49371 (current development port)"
echo "   - http://localhost:8080 (common Flutter port)"
echo "   - http://localhost:3000 (common web dev port)"
echo ""
echo "⚠️  Note: For production, you should restrict to specific domains"
echo ""
read -p "Continue? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelled"
    exit 1
fi

# Add CORS origins
echo ""
echo "🔧 Adding CORS origins..."

# Remove all existing CORS origins first
echo "   Clearing existing CORS settings..."
az webapp cors remove \
  --name "$APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --allowed-origins all \
  2>&1 || echo "   (Could not clear existing settings, continuing...)"

# Add new CORS origins
echo "   Adding new CORS origins..."
az webapp cors add \
  --name "$APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --allowed-origins \
    'http://localhost:49371' \
    'http://localhost:8080' \
    'http://localhost:3000' \
    'http://127.0.0.1:49371' \
    'http://127.0.0.1:8080' \
    'http://127.0.0.1:3000'

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ CORS configuration updated successfully!"
else
    echo ""
    echo "❌ Failed to update CORS configuration"
    echo "   Please try manually via Azure Portal"
    exit 1
fi

# Show updated CORS settings
echo ""
echo "📋 Updated CORS Settings:"
az webapp cors show \
  --name "$APP_NAME" \
  --resource-group "$RESOURCE_GROUP"

echo ""
echo "🎉 CORS Configuration Complete!"
echo ""
echo "⏳ Please wait 30-60 seconds for changes to propagate"
echo ""
echo "🧪 Test the configuration:"
echo "   1. Run: ./test-cors.sh"
echo "   2. Or try logging in to the admin web app"
echo ""
echo "📝 If issues persist:"
echo "   1. Check Azure Portal: CORS settings"
echo "   2. Restart the App Service"
echo "   3. Clear browser cache"
echo ""
