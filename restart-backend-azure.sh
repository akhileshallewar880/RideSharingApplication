#!/bin/bash

# Script to restart Azure App Service to trigger database initialization
# This will re-run the database schema creation code in Program.cs

set -e

APP_NAME="vayatra-app-service"
RESOURCE_GROUP="vayatra-app-service_group"

echo "🔄 Restarting Azure App Service: $APP_NAME"
echo "This will trigger database schema creation/verification..."

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed"
    echo "Please install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure"
    echo "Please run: az login"
    exit 1
fi

echo "📋 Current app status:"
az webapp show --name $APP_NAME --resource-group $RESOURCE_GROUP --query "state" -o tsv

echo ""
echo "🔄 Restarting app..."
az webapp restart --name $APP_NAME --resource-group $RESOURCE_GROUP

echo "✅ App restarted successfully!"
echo ""
echo "⏳ Waiting 30 seconds for app to start up..."
sleep 30

echo "📋 New app status:"
az webapp show --name $APP_NAME --resource-group $RESOURCE_GROUP --query "state" -o tsv

echo ""
echo "📝 Check logs to verify database initialization:"
echo "   az webapp log tail --name $APP_NAME --resource-group $RESOURCE_GROUP"
echo ""
echo "Or view in Azure Portal:"
echo "   https://portal.azure.com/#@/resource/subscriptions/YOUR_SUB_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Web/sites/$APP_NAME/logStream"
