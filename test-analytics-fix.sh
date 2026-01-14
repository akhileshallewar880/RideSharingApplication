#!/bin/bash

# Test Analytics Endpoint After Database Fix
# This script tests if the analytics endpoint now works (returns 200 instead of 500)

set -e

echo "================================"
echo "ANALYTICS ENDPOINT TEST"
echo "================================"
echo ""

# You need to provide a valid JWT token
echo "⚠️  You need a valid JWT token to test"
echo ""
echo "To get a token:"
echo "  1. Open admin web app"
echo "  2. Open browser DevTools (F12)"
echo "  3. Go to Application/Storage > Local Storage"
echo "  4. Copy the 'authToken' value"
echo ""

read -p "Paste your JWT token (or press Enter to skip): " TOKEN

if [ -z "$TOKEN" ]; then
    echo "❌ No token provided - cannot test"
    echo ""
    echo "Manual test steps:"
    echo "  1. Open: https://vayatra-app-service-baczabgbcbczg2b4.centralindia-01.azurewebsites.net/swagger"
    echo "  2. Click 'Authorize' button"
    echo "  3. Enter: Bearer YOUR_TOKEN"
    echo "  4. Test: GET /api/v1/admin/analytics/dashboard"
    echo "  5. Should return 200 OK (not 500)"
    exit 0
fi

API_URL="https://vayatra-app-service-baczabgbcbczg2b4.centralindia-01.azurewebsites.net/api/v1/admin/analytics/dashboard"

echo "🧪 Testing analytics endpoint..."
echo "URL: $API_URL"
echo ""

# Test the endpoint
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$API_URL" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

# Split response and status code
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "HTTP Status: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ SUCCESS! Analytics endpoint is working"
    echo ""
    echo "Response:"
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    echo ""
    echo "🎉 Database tables created successfully!"
    echo "The 'Invalid object name Drivers' error is FIXED"
elif [ "$HTTP_CODE" = "401" ]; then
    echo "⚠️  Unauthorized (401) - Token may be invalid or expired"
    echo "Please get a fresh token and try again"
elif [ "$HTTP_CODE" = "500" ]; then
    echo "❌ Still getting 500 error"
    echo ""
    echo "Response:"
    echo "$BODY" | jq '.' 2>/dev/null || echo "$BODY"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check app logs: az webapp log tail --name vayatra-app-service --resource-group vayatra-app-service_group"
    echo "  2. Verify database connection string"
    echo "  3. Check if database initialization succeeded"
    echo "  4. Run: ./DATABASE_FIX_GUIDE.sh"
else
    echo "⚠️  Unexpected status code: $HTTP_CODE"
    echo "Response: $BODY"
fi

echo ""
echo "================================"
echo "NEXT STEPS"
echo "================================"
echo ""

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Everything is working!"
    echo ""
    echo "Test in admin web app:"
    echo "  1. Login to admin web"
    echo "  2. Check analytics dashboard"
    echo "  3. Should see data (counts may be 0)"
    echo "  4. No console errors"
else
    echo "If still having issues:"
    echo "  1. Check Azure logs for errors"
    echo "  2. Verify database tables exist"
    echo "  3. Run diagnostic: ./DATABASE_FIX_GUIDE.sh"
    echo "  4. May need to restart app again"
fi
