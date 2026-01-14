#!/bin/bash
set -e

echo "🚀 Deploying VanYatra Admin Web App to Azure Static Web Apps..."

# Configuration
RESOURCE_GROUP="vanyatraVm_group"
APP_NAME="vanyatra-admin"
BUILD_PATH="admin_web/build/web"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}📦 Step 1: Verifying build directory...${NC}"
if [ ! -d "$BUILD_PATH" ]; then
    echo -e "${YELLOW}⚠️  Build directory not found. Building Flutter web app...${NC}"
    cd admin_web
    flutter build web --release --web-renderer html
    cd ..
fi

echo -e "${GREEN}✅ Build directory verified${NC}"

echo -e "${BLUE}📤 Step 2: Creating deployment package...${NC}"
cd admin_web/build/web
zip -r ../../../admin-web-deployment.zip . > /dev/null 2>&1
cd ../../..

echo -e "${GREEN}✅ Deployment package created${NC}"

echo -e "${BLUE}🔑 Step 3: Getting deployment credentials...${NC}"
DEPLOYMENT_TOKEN=$(az staticwebapp secrets list \
    --name "$APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.apiKey" \
    -o tsv)

if [ -z "$DEPLOYMENT_TOKEN" ]; then
    echo "❌ Failed to retrieve deployment token"
    exit 1
fi

echo -e "${GREEN}✅ Deployment token retrieved${NC}"

echo -e "${BLUE}🌐 Step 4: Deploying to Azure Static Web Apps...${NC}"

# Create a temporary directory for deployment
TEMP_DIR=$(mktemp -d)
unzip -q admin-web-deployment.zip -d "$TEMP_DIR"

# Use Azure Static Web Apps REST API for deployment
echo "Deploying files..."

# For Azure Static Web Apps, we need to use oryx-based deployment or GitHub Actions
# Let's use the az staticwebapp command if available
if az staticwebapp --help > /dev/null 2>&1; then
    # Check if az staticwebapp supports upload
    if az staticwebapp --help | grep -q "upload"; then
        az staticwebapp upload \
            --name "$APP_NAME" \
            --resource-group "$RESOURCE_GROUP" \
            --app-location "$BUILD_PATH" \
            --deployment-token "$DEPLOYMENT_TOKEN" || echo "Note: Direct upload may not be supported"
    fi
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Deployment process completed!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}📱 Your admin web app will be available at:${NC}"
echo -e "${YELLOW}   https://red-moss-0860f7400.2.azurestaticapps.net${NC}"
echo ""
echo -e "${BLUE}Note:${NC} Azure Static Web Apps typically deploys via GitHub Actions."
echo "For immediate deployment, please use one of these options:"
echo ""
echo "Option 1: Manual Upload via Azure Portal"
echo "  1. Go to: https://portal.azure.com"
echo "  2. Navigate to: vanyatra-admin static web app"
echo "  3. Use 'Browse code' to upload admin-web-deployment.zip"
echo ""
echo "Option 2: GitHub Actions (Recommended)"
echo "  1. Push your code to GitHub"
echo "  2. GitHub Actions will automatically deploy"
echo ""
echo "Option 3: Azure Static Web Apps CLI"
echo "  npm install -g @azure/static-web-apps-cli"
echo "  swa deploy --app-location admin_web/build/web --deployment-token \$TOKEN"
echo ""
