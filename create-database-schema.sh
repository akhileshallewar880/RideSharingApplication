#!/bin/bash

# Manual Database Schema Creation Script
# Use this if automatic initialization on app startup isn't working

set -e

echo "================================"
echo "MANUAL DATABASE SCHEMA CREATION"
echo "================================"
echo ""

cd "$(dirname "$0")/server/ride_sharing_application/RideSharing.API"

echo "📍 Current directory: $(pwd)"
echo ""

# Check if dotnet is installed
if ! command -v dotnet &> /dev/null; then
    echo "❌ .NET SDK is not installed"
    echo "Please install: https://dotnet.microsoft.com/download"
    exit 1
fi

echo "✅ .NET SDK found: $(dotnet --version)"
echo ""

echo "================================"
echo "OPTION 1: Generate SQL Script"
echo "================================"
echo ""
echo "This will generate a SQL script file that you can run manually in Azure SQL"
echo ""

read -p "Generate SQL script? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔨 Generating SQL schema script..."
    
    # Check if there are migrations
    if [ -d "Migrations" ] && [ "$(ls -A Migrations)" ]; then
        echo "✅ Found existing migrations"
        echo "📝 Generating migration SQL script..."
        dotnet ef migrations script -o database-schema.sql --idempotent
        
        if [ -f "database-schema.sql" ]; then
            echo "✅ SQL script generated: database-schema.sql"
            echo ""
            echo "📋 To apply this script:"
            echo "   1. Go to Azure Portal: https://portal.azure.com"
            echo "   2. Navigate to your SQL Database"
            echo "   3. Click 'Query editor'"
            echo "   4. Copy and paste the contents of database-schema.sql"
            echo "   5. Click 'Run'"
            echo ""
            echo "File location: $(pwd)/database-schema.sql"
        else
            echo "❌ Failed to generate SQL script"
        fi
    else
        echo "⚠️  No migrations found. Creating initial migration..."
        echo ""
        
        # Create initial migration
        dotnet ef migrations add InitialCreate
        
        echo "✅ Migration created"
        echo "📝 Generating SQL script..."
        dotnet ef migrations script -o database-schema.sql --idempotent
        
        if [ -f "database-schema.sql" ]; then
            echo "✅ SQL script generated: database-schema.sql"
        else
            echo "❌ Failed to generate SQL script"
        fi
    fi
fi

echo ""
echo "================================"
echo "OPTION 2: Apply Directly to Database"
echo "================================"
echo ""
echo "⚠️  WARNING: This will apply changes directly to your database"
echo "   Make sure connection strings are configured correctly"
echo ""

read -p "Apply migrations to database now? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔄 Applying database migrations..."
    echo ""
    
    # Check for connection string
    if [ -z "$ConnectionStrings__RideSharingConnectionString" ]; then
        echo "⚠️  Connection string not found in environment"
        echo ""
        echo "Please set the connection string:"
        echo "  export ConnectionStrings__RideSharingConnectionString='YOUR_CONNECTION_STRING'"
        echo ""
        echo "Or update appsettings.json with your Azure SQL connection string"
        echo ""
        exit 1
    fi
    
    echo "📝 Using connection string from environment"
    echo ""
    
    # Apply migrations
    dotnet ef database update
    
    if [ $? -eq 0 ]; then
        echo "✅ Database migrations applied successfully!"
        echo ""
        echo "🎉 All tables should now exist in your Azure SQL database"
    else
        echo "❌ Failed to apply migrations"
        echo ""
        echo "Common issues:"
        echo "  - Connection string is incorrect"
        echo "  - Database doesn't exist"
        echo "  - Firewall is blocking connection"
        echo "  - Insufficient permissions"
    fi
fi

echo ""
echo "================================"
echo "OPTION 3: Database Update via Azure"
echo "================================"
echo ""
echo "If local update doesn't work, you can update from Azure:"
echo ""
echo "1. Enable SSH in Azure App Service"
echo "2. Connect via SSH"
echo "3. Navigate to /home/site/wwwroot"
echo "4. Run: dotnet ef database update"
echo ""

echo "================================"
echo "VERIFICATION"
echo "================================"
echo ""
echo "After creating tables, verify in Azure Portal:"
echo ""
echo "1. Go to your SQL Database"
echo "2. Click 'Query editor'"
echo "3. Run this query:"
echo ""
echo "   SELECT TABLE_NAME"
echo "   FROM INFORMATION_SCHEMA.TABLES"
echo "   WHERE TABLE_TYPE = 'BASE TABLE'"
echo "   ORDER BY TABLE_NAME;"
echo ""
echo "Expected tables:"
echo "  - Drivers"
echo "  - Users"
echo "  - Rides"
echo "  - Bookings"
echo "  - VehicleModels"
echo "  - Locations"
echo "  - Banners"
echo "  - Notifications"
echo "  - RouteDistances"
echo "  - And more..."
echo ""

echo "================================"
echo "DONE"
echo "================================"
