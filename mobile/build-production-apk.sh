#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   VanYatra Production APK Build Script    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Configuration
PRODUCTION_URL="https://vayatra-app-service-baczabgbcbczg2b4.centralindia-01.azurewebsites.net"
APP_VERSION="1.0.1"
BUILD_NUMBER="3"

echo -e "${YELLOW}📋 Build Configuration:${NC}"
echo -e "   API URL: ${PRODUCTION_URL}"
echo -e "   Version: ${APP_VERSION}"
echo -e "   Build Number: ${BUILD_NUMBER}"
echo ""

# Step 1: Clean previous builds
echo -e "${BLUE}🧹 Step 1: Cleaning previous builds...${NC}"
flutter clean
echo -e "${GREEN}✅ Clean completed${NC}"
echo ""

# Step 2: Get dependencies
echo -e "${BLUE}📦 Step 2: Getting dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# Step 3: Verify keystore
echo -e "${BLUE}🔐 Step 3: Verifying keystore configuration...${NC}"
if [ -f "android/key.properties" ]; then
    echo -e "${GREEN}✅ Keystore configuration found${NC}"
else
    echo -e "${RED}❌ ERROR: android/key.properties not found${NC}"
    echo -e "${YELLOW}Please create keystore configuration first${NC}"
    exit 1
fi

if [ -f "android/release-keystore.jks" ]; then
    echo -e "${GREEN}✅ Release keystore found${NC}"
else
    echo -e "${RED}❌ ERROR: android/release-keystore.jks not found${NC}"
    echo -e "${YELLOW}Please create release keystore first${NC}"
    exit 1
fi
echo ""

# Step 4: Build APK
echo -e "${BLUE}🔨 Step 4: Building production APK...${NC}"
echo -e "${YELLOW}This may take a few minutes...${NC}"
echo ""

flutter build apk \
    --release \
    --build-name="${APP_VERSION}" \
    --build-number="${BUILD_NUMBER}" \
    --dart-define=API_BASE_URL="${PRODUCTION_URL}" \
    --dart-define=PRODUCTION=true \
    --obfuscate \
    --split-debug-info=build/app/outputs/symbols

BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ APK build completed successfully!${NC}"
else
    echo ""
    echo -e "${RED}❌ APK build failed!${NC}"
    exit 1
fi

# Step 5: Locate and display APK info
echo ""
echo -e "${BLUE}📱 Step 5: APK Build Information${NC}"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo -e "${GREEN}✅ APK Location:${NC} ${APK_PATH}"
    echo -e "${GREEN}✅ APK Size:${NC} ${APK_SIZE}"
    echo ""
    
    # Display APK details
    echo -e "${BLUE}APK Details:${NC}"
    echo "  - Version Name: ${APP_VERSION}"
    echo "  - Version Code: ${BUILD_NUMBER}"
    echo "  - API URL: ${PRODUCTION_URL}"
    echo "  - Obfuscated: Yes"
    echo "  - Signed: Yes (Release)"
    echo ""
else
    echo -e "${RED}❌ APK file not found at expected location${NC}"
    exit 1
fi

# Step 6: Create output directory and copy APK
echo -e "${BLUE}📦 Step 6: Organizing build artifacts...${NC}"
OUTPUT_DIR="release-builds"
mkdir -p "${OUTPUT_DIR}"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_APK="${OUTPUT_DIR}/vanyatra-v${APP_VERSION}-build${BUILD_NUMBER}-${TIMESTAMP}.apk"

cp "${APK_PATH}" "${OUTPUT_APK}"
echo -e "${GREEN}✅ APK copied to:${NC} ${OUTPUT_APK}"
echo ""

# Step 7: Generate SHA-256 checksum
echo -e "${BLUE}🔒 Step 7: Generating checksums...${NC}"
CHECKSUM=$(shasum -a 256 "${OUTPUT_APK}" | cut -d ' ' -f 1)
echo "${CHECKSUM}  ${OUTPUT_APK}" > "${OUTPUT_APK}.sha256"
echo -e "${GREEN}✅ SHA-256:${NC} ${CHECKSUM}"
echo -e "${GREEN}✅ Checksum saved to:${NC} ${OUTPUT_APK}.sha256"
echo ""

# Summary
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        Build Completed Successfully!       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📱 Production APK Ready for Deployment:${NC}"
echo -e "   📄 File: ${OUTPUT_APK}"
echo -e "   📏 Size: ${APK_SIZE}"
echo -e "   🔐 SHA-256: ${CHECKSUM}"
echo ""
echo -e "${YELLOW}📋 Next Steps:${NC}"
echo "   1. Test the APK on a physical device"
echo "   2. Upload to Google Play Console or distribute directly"
echo "   3. Verify all features work in production"
echo ""
echo -e "${BLUE}🚀 To install on device:${NC}"
echo "   adb install -r ${OUTPUT_APK}"
echo ""
