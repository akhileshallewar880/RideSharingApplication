#!/bin/bash

# VanYatra Splash Screen - Quick Test Script
# This script helps you quickly test the new splash screen

echo "🎨 VanYatra Splash Screen Test"
echo "================================"
echo ""

# Change to mobile directory
cd "$(dirname "$0")/mobile" || exit 1

echo "📱 Available devices:"
flutter devices
echo ""

echo "🔍 Select testing option:"
echo "  1) Run on Android Emulator (if available)"
echo "  2) Run on iOS Simulator (macOS only)"
echo "  3) Run on connected device"
echo "  4) Build Android APK"
echo "  5) Hot restart (if already running)"
echo "  6) Clean and run"
echo ""

read -p "Enter option (1-6): " option
echo ""

case $option in
  1)
    echo "🤖 Launching on Android..."
    flutter run -d emulator
    ;;
  2)
    echo "🍎 Launching on iOS Simulator..."
    flutter run -d ios
    ;;
  3)
    echo "📱 Select a device from the list above"
    read -p "Enter device ID: " device_id
    echo "🚀 Launching on $device_id..."
    flutter run -d "$device_id"
    ;;
  4)
    echo "📦 Building Android APK..."
    flutter build apk --release
    echo ""
    echo "✅ APK built successfully!"
    echo "📁 Location: build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "To install on connected device:"
    echo "  adb install build/app/outputs/flutter-apk/app-release.apk"
    ;;
  5)
    echo "♻️ Hot restarting..."
    echo "Type 'R' in the Flutter console or use:"
    echo "  flutter attach"
    ;;
  6)
    echo "🧹 Cleaning project..."
    flutter clean
    echo "📦 Getting dependencies..."
    flutter pub get
    echo "🎨 Regenerating splash assets..."
    dart run flutter_native_splash:create
    dart run flutter_launcher_icons
    echo "🚀 Running app..."
    flutter run
    ;;
  *)
    echo "❌ Invalid option"
    exit 1
    ;;
esac

echo ""
echo "✨ Testing Tips:"
echo "  • Watch for native splash (green background + logo)"
echo "  • Observe in-app animations (icon scale, shimmer, text slide)"
echo "  • Check smooth transitions between splash and home"
echo "  • Try force-closing and reopening to see full experience"
echo "  • Test in both light and dark mode"
echo ""
echo "🎯 What to Look For:"
echo "  ✓ Instant native splash appearance"
echo "  ✓ Icon scales in with gold glow"
echo "  ✓ Shimmer effect on icon"
echo "  ✓ Text logo slides up smoothly"
echo "  ✓ Tagline with gold border appears"
echo "  ✓ Loading indicator spins"
echo "  ✓ Smooth transition to next screen"
echo ""
