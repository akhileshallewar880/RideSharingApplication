#!/bin/bash

# Test Phone Authentication Setup
# Run this to verify Firebase Phone Auth is properly configured

echo "📱 Firebase Phone Auth Configuration Test"
echo "=========================================="
echo ""

cd mobile || exit

echo "1️⃣ Checking pubspec.yaml for Firebase dependencies..."
if grep -q "firebase_auth:" pubspec.yaml; then
    echo "   ✅ firebase_auth found in pubspec.yaml"
else
    echo "   ❌ firebase_auth NOT found in pubspec.yaml"
    exit 1
fi

echo ""
echo "2️⃣ Checking Android build.gradle for Firebase Auth..."
if grep -q "firebase-auth" android/app/build.gradle; then
    echo "   ✅ Firebase Auth dependency found"
else
    echo "   ❌ Firebase Auth dependency MISSING - This is the problem!"
    echo "   Adding it now..."
    exit 1
fi

echo ""
echo "3️⃣ Checking google-services.json..."
if [ -f "android/app/google-services.json" ]; then
    echo "   ✅ google-services.json exists"
    PROJECT_ID=$(grep -o '"project_id": "[^"]*' android/app/google-services.json | sed 's/"project_id": "//')
    echo "   Project ID: $PROJECT_ID"
else
    echo "   ❌ google-services.json NOT found"
    exit 1
fi

echo ""
echo "4️⃣ Checking Firebase initialization in main.dart..."
if grep -q "Firebase.initializeApp" lib/main.dart; then
    echo "   ✅ Firebase initialization found"
else
    echo "   ❌ Firebase initialization NOT found"
    exit 1
fi

echo ""
echo "5️⃣ Checking FirebasePhoneService..."
if [ -f "lib/core/services/firebase_phone_service.dart" ]; then
    echo "   ✅ FirebasePhoneService exists"
else
    echo "   ❌ FirebasePhoneService NOT found"
    exit 1
fi

echo ""
echo "6️⃣ Checking phone entry screen..."
if [ -f "lib/features/auth/presentation/screens/phone_number_entry_screen.dart" ]; then
    echo "   ✅ Phone number entry screen exists"
else
    echo "   ❌ Phone number entry screen NOT found"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ All checks passed!"
echo ""
echo "🚀 Next steps:"
echo "   1. Run: flutter clean && flutter pub get"
echo "   2. Enable Phone auth in Firebase Console"
echo "   3. Add test phone number (optional):"
echo "      Phone: +919511803142"
echo "      Code: 123456"
echo "   4. Run: flutter run"
echo "   5. Test phone authentication"
echo ""
echo "📖 See PHONE_AUTH_FIX.md for detailed instructions"
