#!/bin/bash

# Azure App Service Configuration Script
# This script configures all required settings for the Vanyatra App Service

APP_NAME="vayatra-app-service"
RESOURCE_GROUP="vayatra-app-service_group"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Azure App Service Configuration ===${NC}\n"

# Prompt for database password
echo -e "${YELLOW}Enter your Azure SQL Database password:${NC}"
read -s DB_PASSWORD
echo ""

# Prompt for JWT secret (or generate one)
echo -e "${YELLOW}Enter a JWT secret key (minimum 32 characters) or press Enter to generate one:${NC}"
read JWT_SECRET

if [ -z "$JWT_SECRET" ]; then
    JWT_SECRET=$(openssl rand -base64 48)
    echo -e "${GREEN}Generated JWT secret: $JWT_SECRET${NC}"
fi

# Construct connection strings
CONN_STRING="Server=tcp:vayatra-server.database.windows.net,1433;Initial Catalog=vanyatra-server-db;User ID=vanyatraadminlogin;Password=${DB_PASSWORD};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

echo -e "\n${GREEN}Step 1: Setting Connection Strings...${NC}"
az webapp config connection-string set \
  --name "$APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --connection-string-type SQLAzure \
  --settings \
    RideSharingConnectionString="$CONN_STRING" \
    RideSharingAuthConnectionString="$CONN_STRING"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Connection strings configured successfully${NC}"
else
    echo -e "${RED}✗ Failed to configure connection strings${NC}"
    exit 1
fi

echo -e "\n${GREEN}Step 2: Setting Application Settings...${NC}"
az webapp config appsettings set \
  --name "$APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --settings \
    ASPNETCORE_ENVIRONMENT="Production" \
    JwtSettings__secretKey="$JWT_SECRET" \
    JwtSettings__validIssuer="https://vayatra-app-service.azurewebsites.net" \
    JwtSettings__validAudience="https://vayatra-app-service.azurewebsites.net"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Application settings configured successfully${NC}"
else
    echo -e "${RED}✗ Failed to configure application settings${NC}"
    exit 1
fi

echo -e "\n${GREEN}Step 3: Restarting App Service...${NC}"
az webapp restart --name "$APP_NAME" --resource-group "$RESOURCE_GROUP"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ App service restarted successfully${NC}"
else
    echo -e "${RED}✗ Failed to restart app service${NC}"
    exit 1
fi

echo -e "\n${GREEN}=== Configuration Complete ===${NC}"
echo -e "\n${YELLOW}Your app should be available at:${NC}"
echo -e "${GREEN}https://vayatra-app-service.azurewebsites.net${NC}\n"

echo -e "${YELLOW}Important: Save your JWT secret key securely:${NC}"
echo -e "${GREEN}$JWT_SECRET${NC}\n"
