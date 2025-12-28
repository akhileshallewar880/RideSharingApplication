#!/bin/bash

# Admin Login Fix - Quick Setup Script
# This script helps you generate a password hash and provides SQL to update the database

echo "======================================"
echo "Admin Login Fix - Password Hash Setup"
echo "======================================"
echo ""

# Check if API is built
if [ ! -f "RideSharing.API/bin/Debug/net8.0/RideSharing.API.dll" ]; then
    echo "Building API..."
    cd RideSharing.API
    dotnet build
    cd ..
fi

echo "Starting API temporarily to generate password hash..."
echo ""
echo "IMPORTANT: Once the API starts, open another terminal and run:"
echo ""
echo "curl -X POST http://localhost:5056/api/v1/admin/generate-password-hash \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"password\":\"Admin@123\",\"email\":\"admin@allapalliride.com\"}'"
echo ""
echo "Copy the hash from the response and use it in the SQL query."
echo ""
echo "Press Ctrl+C to stop the API after generating the hash."
echo ""
echo "======================================"
echo ""

# Start the API
cd RideSharing.API
dotnet run
