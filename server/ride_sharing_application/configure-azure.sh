#!/bin/bash

# Azure App Service — One-Time Configuration Script
# Sets ALL application settings required for startup and runtime.
# Run this once after creating the App Service, before the first deploy.

set -e

# ─── Edit these two values to match your Azure resources ───────────────────────
APP_NAME="VanYatraApp"
RESOURCE_GROUP="VanYatra_Resource_Group"
# ────────────────────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}=== Azure App Service — Full Configuration ===${NC}\n"

# ── Prerequisite checks ─────────────────────────────────────────────────────────
if ! command -v az &> /dev/null; then
    echo -e "${RED}✗ Azure CLI not found. Install: https://aka.ms/azure-cli${NC}"
    exit 1
fi

if ! az account show &> /dev/null; then
    echo -e "${RED}✗ Not logged in. Run: az login${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Azure CLI ready${NC}"
az account show --query "{Subscription:name, Id:id}" -o table
echo ""

# ── Collect secrets ─────────────────────────────────────────────────────────────
echo -e "${YELLOW}[1/5] Azure SQL Database password:${NC}"
read -rs DB_PASSWORD
echo ""

echo -e "${YELLOW}[2/5] JWT secret key (min 32 chars) — press Enter to auto-generate:${NC}"
read -r JWT_SECRET
if [ -z "$JWT_SECRET" ]; then
    JWT_SECRET=$(openssl rand -base64 48)
    echo -e "${CYAN}Generated: $JWT_SECRET${NC}"
fi
echo ""

echo -e "${YELLOW}[3/5] Google Maps API key:${NC}"
read -r GOOGLE_MAPS_API_KEY
echo ""

echo -e "${YELLOW}[4/5] Gmail address for sending emails (or press Enter to skip):${NC}"
read -r EMAIL_USERNAME
echo ""

if [ -n "$EMAIL_USERNAME" ]; then
    echo -e "${YELLOW}[5/5] Gmail App Password (not your account password):${NC}"
    read -rs EMAIL_PASSWORD
    echo ""
else
    EMAIL_PASSWORD=""
    echo -e "${CYAN}Skipping email configuration.${NC}"
fi

# ── Derive app URL ───────────────────────────────────────────────────────────────
APP_URL=$(az webapp show \
    --name "$APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "defaultHostName" -o tsv 2>/dev/null || echo "")

if [ -n "$APP_URL" ]; then
    WEBAPP_URL="https://$APP_URL"
else
    WEBAPP_URL="https://${APP_NAME}.azurewebsites.net"
fi
echo -e "${CYAN}App URL: $WEBAPP_URL${NC}\n"

# ── Connection strings ───────────────────────────────────────────────────────────
CONN_STRING="Server=tcp:vanyatradbserver.database.windows.net,1433;Initial Catalog=free-sql-db-7942255;Persist Security Info=False;User ID=vanyatra_server;Password=${DB_PASSWORD};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

echo -e "${GREEN}Step 1: Setting Connection Strings...${NC}"
az webapp config connection-string set \
  --name "$APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --connection-string-type SQLAzure \
  --settings \
    RideSharingConnectionString="$CONN_STRING" \
    RideSharingAuthConnectionString="$CONN_STRING"
echo -e "${GREEN}✓ Connection strings set${NC}\n"

# ── Application settings ─────────────────────────────────────────────────────────
echo -e "${GREEN}Step 2: Setting Application Settings...${NC}"

SETTINGS=(
    ASPNETCORE_ENVIRONMENT="Production"

    # JWT — required at startup (throws InvalidOperationException if missing)
    JwtSettings__secretKey="$JWT_SECRET"
    JwtSettings__validIssuer="$WEBAPP_URL"
    JwtSettings__validAudience="$WEBAPP_URL"

    # Google Maps — required (constructor throws if missing)
    GoogleMaps__ApiKey="$GOOGLE_MAPS_API_KEY"

    # App settings
    AppSettings__ResetPasswordUrl="${WEBAPP_URL}/reset-password"

    # Email (optional — only used when sending emails, not at startup)
    Email__SmtpHost="smtp.gmail.com"
    Email__SmtpPort="587"
    Email__FromEmail="noreply@vanyatra.com"
    Email__FromName="VanYatra"

    # Background services
    RideAutoCancellation__Enabled="true"
    RideAutoCancellation__DailyRunTime="23:30"
    RideAutoCancellation__EnableNotifications="true"
    RideAutoCancellation__EnableAutoRefund="true"
    RideAutoCancellation__BatchSize="100"
    RideAutoCancellation__QueryTimeout="300"

    BookingNoShow__Enabled="true"
    BookingNoShow__CheckIntervalMinutes="10"
    BookingNoShow__EnableNotifications="true"
    BookingNoShow__NoRefundForNoShow="true"
    BookingNoShow__BatchSize="100"
    BookingNoShow__QueryTimeout="300"
)

# Add email credentials only if provided
if [ -n "$EMAIL_USERNAME" ]; then
    SETTINGS+=(
        Email__Username="$EMAIL_USERNAME"
        Email__Password="$EMAIL_PASSWORD"
    )
fi

az webapp config appsettings set \
  --name "$APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --settings "${SETTINGS[@]}"

echo -e "${GREEN}✓ Application settings configured${NC}\n"

# ── Restart ──────────────────────────────────────────────────────────────────────
echo -e "${GREEN}Step 3: Restarting App Service...${NC}"
az webapp restart --name "$APP_NAME" --resource-group "$RESOURCE_GROUP"
echo -e "${GREEN}✓ App service restarted${NC}\n"

# ── Summary ──────────────────────────────────────────────────────────────────────
echo -e "${GREEN}=== Configuration Complete ===${NC}"
echo -e "\n${YELLOW}App URL:${NC} ${GREEN}${WEBAPP_URL}${NC}"
echo -e "${YELLOW}Swagger: ${NC}${GREEN}${WEBAPP_URL}/swagger${NC}"
echo -e "\n${YELLOW}Save your JWT secret key (you will need it if you ever recreate App Settings):${NC}"
echo -e "${CYAN}$JWT_SECRET${NC}\n"
echo -e "${YELLOW}Next step:${NC} Push to main (or trigger workflow manually) to deploy the code."
