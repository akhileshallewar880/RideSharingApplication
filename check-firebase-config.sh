#!/bin/bash

# Firebase Configuration Verification Script
# Run this to verify your Firebase setup

echo "🔍 VanYatra Firebase Configuration Checker"
echo "==========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check 1: google-services.json exists
echo -n "1. Checking if google-services.json exists... "
if [ -f "mobile/android/app/google-services.json" ]; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${RED}✗ Missing${NC}"
    echo "   Please download google-services.json from Firebase Console"
    exit 1
fi

# Check 2: OAuth clients configured
echo -n "2. Checking OAuth client configuration... "
OAUTH_COUNT=$(grep -o '"oauth_client"' mobile/android/app/google-services.json | wc -l)
OAUTH_ENTRIES=$(cat mobile/android/app/google-services.json | grep -A 30 '"oauth_client"' | grep -c '"client_id"')

if [ "$OAUTH_ENTRIES" -gt 0 ]; then
    echo -e "${GREEN}✓ Found $OAUTH_ENTRIES OAuth client(s)${NC}"
else
    echo -e "${RED}✗ OAuth clients not configured${NC}"
    echo "   Your oauth_client array is empty. Please:"
    echo "   1. Enable Google Sign-In in Firebase Console"
    echo "   2. Create OAuth 2.0 clients in Google Cloud Console"
    echo "   3. Download updated google-services.json"
fi

# Check 3: Package name
echo -n "3. Verifying package name... "
PACKAGE_NAME=$(grep -o '"package_name": *"[^"]*"' mobile/android/app/google-services.json | head -1 | cut -d'"' -f4)
EXPECTED_PACKAGE="com.allapalli.allapalli_ride"

if [ "$PACKAGE_NAME" = "$EXPECTED_PACKAGE" ]; then
    echo -e "${GREEN}✓ Correct ($PACKAGE_NAME)${NC}"
else
    echo -e "${RED}✗ Mismatch${NC}"
    echo "   Expected: $EXPECTED_PACKAGE"
    echo "   Found: $PACKAGE_NAME"
fi

# Check 4: minSdkVersion
echo -n "4. Checking minSdkVersion... "
MIN_SDK=$(grep "minSdkVersion" mobile/android/app/build.gradle | grep -o '[0-9]\+' | head -1)

if [ "$MIN_SDK" -ge 23 ]; then
    echo -e "${GREEN}✓ Correct ($MIN_SDK)${NC}"
else
    echo -e "${RED}✗ Too low ($MIN_SDK)${NC}"
    echo "   Firebase Auth requires minSdkVersion 23 or higher"
fi

# Check 5: Firebase dependencies
echo -n "5. Checking Firebase dependencies... "
if grep -q "firebase_auth:" mobile/pubspec.yaml && \
   grep -q "firebase_core:" mobile/pubspec.yaml; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${RED}✗ Missing${NC}"
    echo "   Please run: flutter pub get"
fi

# Check 6: Firebase initialization in main.dart
echo -n "6. Checking Firebase initialization... "
if grep -q "Firebase.initializeApp" mobile/lib/main.dart; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${YELLOW}⚠ Not found${NC}"
    echo "   Firebase.initializeApp() should be called in main.dart"
fi

# Check 7: FirebaseAuthService exists
echo -n "7. Checking FirebaseAuthService... "
if [ -f "mobile/lib/core/services/firebase_auth_service.dart" ]; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${RED}✗ Missing${NC}"
    echo "   FirebaseAuthService not found"
fi

# Check 8: SHA-1 fingerprint (show current)
echo ""
echo "8. Current Debug SHA-1 Fingerprint:"
echo -e "   ${BLUE}Expected: C8:58:76:47:2C:D9:8D:46:C8:A5:FD:75:96:20:02:B0:D8:33:F8:72${NC}"
echo -n "   Actual:   "

if [ -f "$HOME/.android/debug.keystore" ]; then
    CURRENT_SHA1=$(keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep "SHA1:" | cut -d' ' -f3)
    
    if [ "$CURRENT_SHA1" = "C8:58:76:47:2C:D9:8D:46:C8:A5:FD:75:96:20:02:B0:D8:33:F8:72" ]; then
        echo -e "${GREEN}$CURRENT_SHA1 ✓${NC}"
    else
        echo -e "${YELLOW}$CURRENT_SHA1${NC}"
        echo -e "   ${YELLOW}⚠ SHA-1 mismatch! Update it in Firebase Console${NC}"
    fi
else
    echo -e "${YELLOW}Debug keystore not found${NC}"
fi

echo ""
echo "==========================================="
echo ""

# Summary
echo "📋 Configuration Summary:"
echo ""
echo "Project Details:"
echo "  • Project ID: vanyatra-69e38"
echo "  • Package: $PACKAGE_NAME"
echo "  • Min SDK: $MIN_SDK"
echo ""
echo "Firebase Console Tasks (Manual):"
echo "  1. Enable Phone Authentication"
echo "     → Firebase Console > Authentication > Sign-in method > Phone"
echo ""
echo "  2. Enable Google Sign-In"
echo "     → Firebase Console > Authentication > Sign-in method > Google"
echo ""
echo "  3. Create OAuth 2.0 clients in Google Cloud Console"
echo "     → console.cloud.google.com > APIs & Services > Credentials"
echo "     → Create Android client with package name and SHA-1"
echo "     → Create Web client for Firebase"
echo ""
echo "  4. Download updated google-services.json"
echo "     → Firebase Console > Project Settings > Your apps"
echo "     → Download google-services.json"
echo "     → Replace mobile/android/app/google-services.json"
echo ""
echo "  5. Verify SHA-1 in Firebase Console"
echo "     → Firebase Console > Project Settings > Your apps"
echo "     → SHA certificate fingerprints section"
echo ""

if [ "$OAUTH_ENTRIES" -eq 0 ]; then
    echo -e "${RED}⚠ CRITICAL: OAuth clients not configured!${NC}"
    echo "   This is why Google Sign-In is failing."
    echo "   Follow the guide in FIREBASE_SETUP_GUIDE.md"
    echo ""
fi

echo "After completing Firebase Console tasks:"
echo "  1. Download new google-services.json"
echo "  2. Run: cd mobile && flutter clean && flutter pub get"
echo "  3. Run: flutter build apk --debug"
echo "  4. Test the app"
echo ""
echo "For detailed instructions, see: FIREBASE_SETUP_GUIDE.md"
echo ""
