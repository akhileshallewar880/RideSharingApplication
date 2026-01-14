#!/bin/bash

# Test Analytics API - Direct Database Error Check

echo "🔍 Testing Analytics API to verify database issue"
echo "=================================================="
echo ""

API_BASE="https://vayatra-app-service-baczabgbcbczg2b4.centralindia-01.azurewebsites.net"

# Step 1: Get a real JWT token by logging in
echo "Step 1: Login to get JWT token"
echo "------------------------------"
read -p "Enter admin email: " EMAIL
read -sp "Enter admin password: " PASSWORD
echo ""

LOGIN_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  "$API_BASE/api/v1/admin/auth/login" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token // .data.token // empty' 2>/dev/null)

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo "❌ Login failed. Response:"
    echo "$LOGIN_RESPONSE" | jq '.' 2>/dev/null || echo "$LOGIN_RESPONSE"
    exit 1
fi

echo "✅ Login successful!"
echo "Token (first 50 chars): ${TOKEN:0:50}..."
echo ""

# Step 2: Test analytics endpoint
echo "Step 2: Test Analytics Dashboard API"
echo "-----------------------------------"

ANALYTICS_RESPONSE=$(curl -s -X GET \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  "$API_BASE/api/v1/admin/analytics/dashboard")

echo "Response:"
echo "$ANALYTICS_RESPONSE" | jq '.' 2>/dev/null || echo "$ANALYTICS_RESPONSE"
echo ""

# Step 3: Check for database error
if echo "$ANALYTICS_RESPONSE" | grep -q "Invalid object name"; then
    echo "❌ DATABASE ERROR CONFIRMED:"
    echo "   Error message contains 'Invalid object name'"
    echo ""
    echo "   This means the database tables don't exist!"
    echo ""
    
    TABLE_NAME=$(echo "$ANALYTICS_RESPONSE" | grep -oP "Invalid object name '\K[^']+")
    if [ -n "$TABLE_NAME" ]; then
        echo "   Missing table: $TABLE_NAME"
    fi
    
    echo ""
    echo "🔧 SOLUTION NEEDED:"
    echo "   The automatic database initialization didn't work"
    echo "   We need to manually create the database schema"
    echo ""
    
elif echo "$ANALYTICS_RESPONSE" | grep -q '"success":true'; then
    echo "✅ API working correctly!"
    echo "   Database tables exist and query succeeded"
    echo ""
    
elif echo "$ANALYTICS_RESPONSE" | grep -q "401\|Unauthorized"; then
    echo "⚠️  Authorization issue (token might be invalid)"
    echo ""
    
else
    echo "⚠️  Unknown response"
    echo ""
fi

# Step 4: Test other endpoints to see scope of issue
echo "Step 3: Test Other Admin Endpoints"
echo "----------------------------------"

echo "Testing: GET /api/v1/admin/rides..."
RIDES_RESPONSE=$(curl -s -X GET \
  -H "Authorization: Bearer $TOKEN" \
  "$API_BASE/api/v1/admin/rides?page=1&pageSize=5")

if echo "$RIDES_RESPONSE" | grep -q "Invalid object name"; then
    echo "❌ Rides endpoint also has database error"
else
    echo "✅ Rides endpoint response:"
    echo "$RIDES_RESPONSE" | jq -r '.message // .error // "Success"' 2>/dev/null
fi

echo ""
echo "=================================================="
echo "DIAGNOSIS COMPLETE"
echo "=================================================="
echo ""

if echo "$ANALYTICS_RESPONSE" | grep -q "Invalid object name"; then
    echo "🔴 CONFIRMED: Database tables are missing"
    echo ""
    echo "Next steps:"
    echo "  1. Run: ./create-database-schema.sh"
    echo "  2. Or manually create tables in Azure SQL"
    echo "  3. Or check Azure logs for initialization errors"
else
    echo "Status: Check responses above for details"
fi
