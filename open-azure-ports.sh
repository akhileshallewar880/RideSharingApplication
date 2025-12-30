#!/bin/bash
# Open ports 80 and 81 in Azure NSG using Azure CLI

echo "🔧 Opening ports 80 and 81 in Azure Network Security Group..."

# Variables - UPDATE THESE
RESOURCE_GROUP="vanyatraVm_group"  # Your Azure resource group name
NSG_NAME="vanyatraVm-nsg"    # Your network security group name

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI not found. Please install: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Login check
echo "Checking Azure CLI login status..."
az account show &> /dev/null
if [ $? -ne 0 ]; then
    echo "Please login to Azure CLI:"
    az login
fi

# Open port 80 (HTTP) for Admin Dashboard
echo "Opening port 80 for Admin Dashboard..."
az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "$NSG_NAME" \
    --name AllowHTTP \
    --protocol tcp \
    --priority 100 \
    --destination-port-range 80 \
    --access Allow \
    --direction Inbound \
    --source-address-prefixes '*' \
    --destination-address-prefixes '*' \
    --description "Allow HTTP traffic for Admin Dashboard"

if [ $? -eq 0 ]; then
    echo "✅ Port 80 opened successfully"
else
    echo "⚠️  Port 80 may already be open or there was an error"
fi

# Open port 81 for Passenger Web App
echo "Opening port 81 for Passenger Web App..."
az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "$NSG_NAME" \
    --name AllowPort81 \
    --protocol tcp \
    --priority 110 \
    --destination-port-range 81 \
    --access Allow \
    --direction Inbound \
    --source-address-prefixes '*' \
    --destination-address-prefixes '*' \
    --description "Allow traffic for Passenger Web App"

if [ $? -eq 0 ]; then
    echo "✅ Port 81 opened successfully"
else
    echo "⚠️  Port 81 may already be open or there was an error"
fi

echo ""
echo "🎉 Port configuration complete!"
echo ""
echo "📋 Testing access (give it 1-2 minutes for rules to propagate):"
echo "   Admin: http://57.159.31.172/"
echo "   Passenger: http://57.159.31.172:81/"
echo ""
echo "🔍 Verify NSG rules:"
echo "   az network nsg rule list --resource-group $RESOURCE_GROUP --nsg-name $NSG_NAME --output table"
