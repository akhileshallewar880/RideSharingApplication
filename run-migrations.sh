#!/bin/bash

# Entity Framework Core Migrations - Create and Apply
# Run this script to generate migrations and update the database

set -e

cd "$(dirname "$0")/server/ride_sharing_application/RideSharing.API"

echo "================================================"
echo "🔧 Entity Framework Core Migrations"
echo "================================================"
echo ""

# Check if dotnet is installed
if ! command -v dotnet &> /dev/null; then
    echo "❌ .NET SDK is not installed"
    echo "Install from: https://dotnet.microsoft.com/download"
    exit 1
fi

echo "✅ .NET SDK found: $(dotnet --version)"
echo ""

# Check if EF Core tools are installed
if ! dotnet ef --version &> /dev/null; then
    echo "📦 Installing Entity Framework Core tools..."
    dotnet tool install --global dotnet-ef
    echo "✅ EF Core tools installed"
else
    echo "✅ EF Core tools found: $(dotnet ef --version)"
fi

echo ""
echo "================================================"
echo "STEP 1: Create Initial Migration"
echo "================================================"
echo ""

# Remove existing migrations folder if it exists
if [ -d "Migrations" ]; then
    echo "⚠️  Migrations folder already exists"
    read -p "Do you want to delete existing migrations and create fresh? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf Migrations
        echo "✅ Deleted existing migrations"
    fi
fi

# Create initial migration
echo "📝 Creating initial migration..."
dotnet ef migrations add InitialCreate --context RideSharingDbContext --verbose

if [ $? -eq 0 ]; then
    echo "✅ Migration created successfully!"
else
    echo "❌ Migration creation failed"
    exit 1
fi

echo ""
echo "================================================"
echo "STEP 2: Review Migration"
echo "================================================"
echo ""
echo "Migration files created in Migrations/ folder"
echo "You can review the generated SQL before applying"
echo ""

# Generate SQL script for review
echo "📄 Generating SQL script for review..."
dotnet ef migrations script -o migration-script.sql --idempotent --context RideSharingDbContext

if [ -f "migration-script.sql" ]; then
    echo "✅ SQL script generated: migration-script.sql"
    echo "   (Safe to run multiple times - uses idempotent operations)"
else
    echo "⚠️  SQL script generation failed"
fi

echo ""
echo "================================================"
echo "STEP 3: Apply Migration to Database"
echo "================================================"
echo ""
echo "⚠️  WARNING: This will modify your Azure SQL Database"
echo ""

# Check for connection string
if [ -z "$ConnectionStrings__RideSharingConnectionString" ]; then
    echo "❌ Connection string not found in environment"
    echo ""
    echo "Please set your Azure SQL connection string:"
    echo "  export ConnectionStrings__RideSharingConnectionString='YOUR_CONNECTION_STRING'"
    echo ""
    echo "Or update appsettings.json with your connection string"
    echo ""
    echo "You can also run the migration from Azure Portal:"
    echo "  1. Upload migration-script.sql to Azure"
    echo "  2. Run it in SQL Database Query Editor"
    echo ""
    exit 1
fi

read -p "Apply migration to database now? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Applying migration to database..."
    dotnet ef database update --context RideSharingDbContext --verbose
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Migration applied successfully!"
        echo "✅ All database tables created!"
    else
        echo ""
        echo "❌ Migration failed"
        echo ""
        echo "Try running the SQL script manually:"
        echo "  1. Open migration-script.sql"
        echo "  2. Copy contents"
        echo "  3. Run in Azure SQL Query Editor"
        exit 1
    fi
fi

echo ""
echo "================================================"
echo "✅ MIGRATION COMPLETE"
echo "================================================"
echo ""
echo "Files created:"
echo "  📁 Migrations/ - EF Core migration files"
echo "  📄 migration-script.sql - SQL script for manual execution"
echo ""
echo "Next steps:"
echo "  1. Test your application"
echo "  2. Verify tables exist in database"
echo "  3. Check analytics endpoint returns 200 OK"
echo ""
