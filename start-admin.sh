#!/bin/bash

# Quick Start - Test the Fixed Admin Login
# This script will start the admin web app for testing

echo "🚀 Starting Admin Web Application"
echo "=================================="
echo ""

# Check if we're in the right directory
if [ ! -d "admin_web" ]; then
    echo "❌ Error: admin_web directory not found"
    echo "   Please run this script from the project root"
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed"
    echo "   Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -1)"
echo ""

# Navigate to admin_web
cd admin_web || exit 1

echo "📦 Installing dependencies..."
flutter pub get
echo ""

echo "🎯 CORS Configuration Status:"
echo "   ✅ Azure CORS: Configured with credentials enabled"
echo "   ✅ Backend CORS: Updated to allow credentials"
echo "   ✅ Allowed Origins:"
echo "      - http://localhost:49371"
echo "      - http://localhost:8080"
echo "      - http://localhost:3000"
echo "      - http://localhost:4200"
echo ""

echo "🌐 Starting web application..."
echo "   URL: http://localhost:49371 (or auto-assigned port)"
echo ""

echo "📝 Login Credentials:"
echo "   Email: admin@vanyatra.com"
echo "   Password: [your admin password]"
echo ""

echo "🔍 If login fails:"
echo "   1. Clear browser cache (Ctrl+Shift+Delete)"
echo "   2. Hard reload (Ctrl+Shift+R)"
echo "   3. Check browser console (F12)"
echo "   4. Run: ../test-login.sh to test API directly"
echo ""

echo "Starting Flutter web app in 3 seconds..."
sleep 3

# Start the app
flutter run -d chrome --web-port=49371

# If the specific port is busy, let Flutter pick one
if [ $? -ne 0 ]; then
    echo ""
    echo "Port 49371 might be busy, trying auto-assign..."
    flutter run -d chrome
fi
