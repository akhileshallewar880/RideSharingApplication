#!/bin/bash

# CORS Configuration Test Script
# Tests CORS configuration for vanyatra-app-service

echo "🧪 Testing CORS Configuration for Vanyatra App Service"
echo "======================================================"
echo ""

# Configuration
APP_SERVICE_URL="https://vayatra-app-service-baczabgbcbczg2b4.centralindia-01.azurewebsites.net"
TEST_ORIGIN="http://localhost:49371"
ENDPOINTS=(
    "/api/v1/admin/auth/login"
    "/api/v1/admin/auth/forgot-password"
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "📋 Test Configuration:"
echo "   App Service: $APP_SERVICE_URL"
echo "   Test Origin: $TEST_ORIGIN"
echo ""

# Test 1: Check if service is reachable
echo "Test 1: Checking if service is reachable..."
if curl -s --head "$APP_SERVICE_URL" | head -n 1 | grep -q "200\|301\|302"; then
    echo -e "${GREEN}✅ Service is reachable${NC}"
else
    echo -e "${RED}❌ Service is not reachable${NC}"
    echo "   Please check if the App Service is running"
    exit 1
fi
echo ""

# Test 2: Test preflight request for each endpoint
for endpoint in "${ENDPOINTS[@]}"; do
    echo "Test 2: Testing CORS preflight for $endpoint..."
    
    response=$(curl -s -X OPTIONS \
        -H "Origin: $TEST_ORIGIN" \
        -H "Access-Control-Request-Method: POST" \
        -H "Access-Control-Request-Headers: Content-Type, Authorization" \
        -i \
        "$APP_SERVICE_URL$endpoint" 2>&1)
    
    # Check for CORS headers
    if echo "$response" | grep -qi "Access-Control-Allow-Origin"; then
        allow_origin=$(echo "$response" | grep -i "Access-Control-Allow-Origin" | cut -d' ' -f2 | tr -d '\r')
        
        if [ "$allow_origin" = "*" ] || [ "$allow_origin" = "$TEST_ORIGIN" ]; then
            echo -e "${GREEN}✅ CORS preflight passed${NC}"
            echo "   Access-Control-Allow-Origin: $allow_origin"
        else
            echo -e "${YELLOW}⚠️  CORS configured but origin mismatch${NC}"
            echo "   Expected: $TEST_ORIGIN or *"
            echo "   Got: $allow_origin"
        fi
        
        # Check for credentials
        if echo "$response" | grep -qi "Access-Control-Allow-Credentials: true"; then
            echo -e "${GREEN}✅ Credentials allowed${NC}"
        else
            echo -e "${YELLOW}⚠️  Credentials not allowed (may cause auth issues)${NC}"
        fi
        
        # Check allowed methods
        if echo "$response" | grep -qi "Access-Control-Allow-Methods"; then
            methods=$(echo "$response" | grep -i "Access-Control-Allow-Methods" | cut -d' ' -f2- | tr -d '\r')
            echo "   Allowed Methods: $methods"
        fi
    else
        echo -e "${RED}❌ CORS preflight failed - No Access-Control-Allow-Origin header${NC}"
        echo ""
        echo "📝 Response Headers:"
        echo "$response" | head -20
        echo ""
        echo "🔧 Action Required:"
        echo "   1. Configure CORS in Azure Portal:"
        echo "      - Go to: App Services → vayatra-app-service-baczabgbcbczg2b4 → CORS"
        echo "      - Add origin: $TEST_ORIGIN"
        echo "      - Or add: * (for all origins)"
        echo "   2. Or deploy the updated backend code with CORS fix"
    fi
    echo ""
done

# Test 3: Test actual login request (without credentials)
echo "Test 3: Testing actual POST request to login endpoint..."
response=$(curl -s -X POST \
    -H "Origin: $TEST_ORIGIN" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d '{"email":"test@example.com","password":"test123"}' \
    -i \
    "$APP_SERVICE_URL/api/v1/admin/auth/login" 2>&1)

if echo "$response" | grep -qi "Access-Control-Allow-Origin"; then
    echo -e "${GREEN}✅ CORS headers present in POST response${NC}"
    allow_origin=$(echo "$response" | grep -i "Access-Control-Allow-Origin" | cut -d' ' -f2 | tr -d '\r')
    echo "   Access-Control-Allow-Origin: $allow_origin"
else
    echo -e "${RED}❌ CORS headers missing in POST response${NC}"
fi
echo ""

# Test 4: Check Azure CORS configuration (requires Azure CLI)
echo "Test 4: Checking Azure CORS configuration..."
if command -v az &> /dev/null; then
    echo "Fetching CORS settings from Azure..."
    cors_settings=$(az webapp cors show \
        --name vayatra-app-service-baczabgbcbczg2b4 \
        --resource-group vayatra-app-service_group \
        2>&1)
    
    if [ $? -eq 0 ]; then
        echo "📋 Azure CORS Settings:"
        echo "$cors_settings"
    else
        echo -e "${YELLOW}⚠️  Could not fetch Azure CORS settings${NC}"
        echo "   Error: $cors_settings"
        echo "   Please ensure you're logged in: az login"
    fi
else
    echo -e "${YELLOW}⚠️  Azure CLI not installed${NC}"
    echo "   Install from: https://aka.ms/azure-cli"
fi
echo ""

# Summary
echo "======================================================"
echo "🎯 Test Summary"
echo "======================================================"
echo ""
echo "If all tests passed (✅), your CORS is configured correctly."
echo "If any tests failed (❌), follow the instructions in CORS_FIX_GUIDE.md"
echo ""
echo "Quick Fix Commands:"
echo ""
echo "1. Configure CORS via Azure CLI:"
echo "   az webapp cors add \\"
echo "     --name vayatra-app-service-baczabgbcbczg2b4 \\"
echo "     --resource-group vayatra-app-service_group \\"
echo "     --allowed-origins '$TEST_ORIGIN'"
echo ""
echo "2. Or allow all origins (development only):"
echo "   az webapp cors add \\"
echo "     --name vayatra-app-service-baczabgbcbczg2b4 \\"
echo "     --resource-group vayatra-app-service_group \\"
echo "     --allowed-origins '*'"
echo ""
echo "3. Deploy backend changes:"
echo "   git add server/ride_sharing_application/RideSharing.API/Program.cs"
echo "   git commit -m 'fix: Update CORS configuration'"
echo "   git push origin main"
echo ""
