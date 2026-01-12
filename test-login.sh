#!/bin/bash

# Quick Login Test
# Tests the complete login flow with the fixed CORS configuration

echo "🧪 Testing Admin Login with Fixed CORS"
echo "======================================"
echo ""

API_URL="https://vayatra-app-service-baczabgbcbczg2b4.centralindia-01.azurewebsites.net/api/v1/admin/auth/login"
ORIGIN="http://localhost:49371"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "📋 Test Configuration:"
echo "   API URL: $API_URL"
echo "   Origin: $ORIGIN"
echo ""

# Prompt for credentials
echo "Please enter admin credentials:"
read -p "Email: " EMAIL
read -sp "Password: " PASSWORD
echo ""
echo ""

echo "🔐 Testing login..."
echo ""

# Make login request
response=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Origin: $ORIGIN" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" \
  -i \
  "$API_URL" 2>&1)

# Check for CORS headers
if echo "$response" | grep -qi "Access-Control-Allow-Origin"; then
    echo -e "${GREEN}✅ CORS headers present${NC}"
    allow_origin=$(echo "$response" | grep -i "Access-Control-Allow-Origin" | cut -d' ' -f2 | tr -d '\r')
    echo "   Access-Control-Allow-Origin: $allow_origin"
    
    if echo "$response" | grep -qi "Access-Control-Allow-Credentials: true"; then
        echo -e "${GREEN}✅ Credentials allowed${NC}"
    fi
else
    echo -e "${RED}❌ CORS headers missing${NC}"
fi

echo ""

# Check HTTP status
if echo "$response" | grep -q "HTTP/[0-9.]* 200"; then
    echo -e "${GREEN}✅ Login successful (HTTP 200)${NC}"
    
    # Extract token (if present)
    if echo "$response" | grep -q "\"token\""; then
        echo -e "${GREEN}✅ Token received${NC}"
        echo ""
        echo "Response body:"
        echo "$response" | sed -n '/^{/,/^}/p' | jq '.' 2>/dev/null || echo "$response" | sed -n '/^{/,/^}/p'
    else
        echo -e "${YELLOW}⚠️  No token in response${NC}"
    fi
elif echo "$response" | grep -q "HTTP/[0-9.]* 401"; then
    echo -e "${RED}❌ Login failed (HTTP 401 - Unauthorized)${NC}"
    echo "   Check your credentials"
elif echo "$response" | grep -q "HTTP/[0-9.]* 400"; then
    echo -e "${RED}❌ Login failed (HTTP 400 - Bad Request)${NC}"
    echo "   Check request format"
else
    echo -e "${YELLOW}⚠️  Unexpected response${NC}"
    echo ""
    echo "Full response:"
    echo "$response"
fi

echo ""
echo "======================================"
echo "🎯 Summary"
echo "======================================"
echo ""

if echo "$response" | grep -q "HTTP/[0-9.]* 200" && echo "$response" | grep -qi "Access-Control-Allow-Origin"; then
    echo -e "${GREEN}✅ Everything is working!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run the admin web app: cd admin_web && flutter run -d chrome"
    echo "2. Login with your credentials"
    echo "3. Start managing your ride-sharing platform!"
else
    echo -e "${RED}❌ Something went wrong${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check if credentials are correct"
    echo "2. Verify Azure App Service is running"
    echo "3. Check Azure App Service logs: az webapp log tail --name vayatra-app-service --resource-group vayatra-app-service_group"
fi

echo ""
