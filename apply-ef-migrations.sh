#!/bin/bash

# ============================================================================
# Entity Framework Migrations Script for Azure SQL Database
# ============================================================================

set -e  # Exit on error

echo "======================================"
echo "Entity Framework Migrations Script"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Navigate to the API project
PROJECT_PATH="/Users/akhileshallewar/project_dev/RideBuisnessCodePrivate/vanyatra_rural_ride_booking/server/ride_sharing_application/RideSharing.API"

echo "Navigating to project directory..."
cd "$PROJECT_PATH"
echo "Current directory: $(pwd)"
echo ""

# Step 1: Install EF Core tools if not already installed
echo "Step 1: Checking Entity Framework Core tools..."
if ! dotnet ef --version &> /dev/null; then
    echo -e "${YELLOW}EF Core tools not found. Installing...${NC}"
    dotnet tool install --global dotnet-ef
    
    # Update PATH if needed
    export PATH="$PATH:$HOME/.dotnet/tools"
    
    echo -e "${GREEN}✓ EF Core tools installed${NC}"
else
    echo -e "${GREEN}✓ EF Core tools already installed${NC}"
    dotnet ef --version
fi
echo ""

# Step 2: Check if Migrations folder exists
echo "Step 2: Checking existing migrations..."
if [ -d "Migrations" ]; then
    echo -e "${YELLOW}Migrations folder already exists!${NC}"
    echo "Do you want to remove existing migrations and create fresh ones?"
    read -p "Type 'yes' to remove existing migrations, or 'no' to skip: " REMOVE_EXISTING
    
    if [ "$REMOVE_EXISTING" = "yes" ]; then
        echo "Removing existing migrations..."
        rm -rf Migrations
        echo -e "${GREEN}✓ Existing migrations removed${NC}"
    else
        echo "Keeping existing migrations."
    fi
else
    echo "No existing migrations found."
fi
echo ""

# Step 3: Create initial migration
echo "Step 3: Creating Entity Framework migration..."
echo "This will analyze your DbContext and create migration files..."

if [ ! -d "Migrations" ]; then
    dotnet ef migrations add InitialCreate --context RideSharingDbContext --verbose
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Migration 'InitialCreate' created successfully${NC}"
    else
        echo -e "${RED}✗ Failed to create migration${NC}"
        exit 1
    fi
else
    echo "Migrations already exist. Skipping creation."
fi
echo ""

# Step 4: Generate SQL script
echo "Step 4: Generating SQL migration script..."
dotnet ef migrations script -o migration-script.sql --idempotent --context RideSharingDbContext

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ SQL script generated: migration-script.sql${NC}"
    echo "Location: $PROJECT_PATH/migration-script.sql"
else
    echo -e "${RED}✗ Failed to generate SQL script${NC}"
    exit 1
fi
echo ""

# Step 5: Show connection string options
echo "Step 5: Apply migrations to database..."
echo ""
echo -e "${YELLOW}IMPORTANT: Choose how to apply migrations:${NC}"
echo ""
echo "Option A - Apply to LOCAL database (for testing):"
echo "  1. Update appsettings.Development.json with your local SQL Server connection"
echo "  2. Run: dotnet ef database update --context RideSharingDbContext"
echo ""
echo "Option B - Apply to AZURE SQL database (recommended):"
echo "  Method 1 (Direct from local):"
echo "    1. Get Azure SQL connection string from Azure Portal"
echo "    2. Add it to appsettings.json or set environment variable"
echo "    3. Run: dotnet ef database update --context RideSharingDbContext"
echo ""
echo "  Method 2 (Manual via Azure Portal - SAFEST):"
echo "    1. Open Azure Portal -> Your SQL Database -> Query Editor"
echo "    2. Copy content from: migration-script.sql"
echo "    3. Paste and run in Query Editor"
echo "    4. Verify tables are created"
echo ""
echo -e "${GREEN}Migration files are ready!${NC}"
echo ""

# Step 6: Ask if user wants to apply now
echo "Do you want to apply migrations now?"
echo "1) Yes - Apply to database using connection in appsettings.json"
echo "2) No - I'll apply manually later"
read -p "Enter choice (1 or 2): " APPLY_CHOICE

if [ "$APPLY_CHOICE" = "1" ]; then
    echo ""
    echo "Applying migrations to database..."
    echo -e "${YELLOW}Note: This will use the connection string from your appsettings.json${NC}"
    echo ""
    
    dotnet ef database update --context RideSharingDbContext --verbose
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}✓ SUCCESS! Migrations applied!${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Verify tables in database"
        echo "2. If this was applied to Azure SQL, restart your Azure App Service"
        echo "3. Test the admin analytics API"
    else
        echo ""
        echo -e "${RED}✗ Failed to apply migrations${NC}"
        echo "You can apply manually using the generated migration-script.sql file"
    fi
else
    echo ""
    echo -e "${YELLOW}Migrations created but not applied.${NC}"
    echo ""
    echo "To apply later, use one of these methods:"
    echo ""
    echo "Method 1 - Using EF Core tools:"
    echo "  cd $PROJECT_PATH"
    echo "  dotnet ef database update --context RideSharingDbContext"
    echo ""
    echo "Method 2 - Using SQL script in Azure Portal:"
    echo "  1. Open: $PROJECT_PATH/migration-script.sql"
    echo "  2. Copy its contents"
    echo "  3. Run in Azure SQL Query Editor"
fi

echo ""
echo "======================================"
echo "Script completed!"
echo "======================================"
