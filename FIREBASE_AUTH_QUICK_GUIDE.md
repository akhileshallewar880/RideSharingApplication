# Firebase Phone Auth - Quick Reference

## 🎯 What Was Done
✅ Added Firebase phone authentication  
✅ Implemented SMS auto-fetch for Android  
✅ Updated login and OTP screens  
✅ Added Android SMS permissions  
✅ Updated route configuration  

## 🔥 Firebase Console Setup (REQUIRED!)

### 1. Enable Phone Authentication
1. Go to https://console.firebase.google.com/
2. Select VanYatra project
3. **Authentication** → **Sign-in method** → Enable **Phone**

### 2. Add Android SHA-1
1. **Project Settings** → **Your apps** → Android app
2. Add SHA-1 fingerprint:
   ```
   C8:58:76:47:2C:D9:8D:46:C8:A5:FD:75:96:20:02:B0:D8:33:F8:72
   ```
3. Download new `google-services.json`
4. Replace `android/app/google-services.json`

### 3. Test It!
```bash
cd mobile
flutter run
```

## 📱 How Auto OTP Works

1. User enters phone number → Sends OTP via Firebase
2. SMS arrives → App auto-detects (Android only)
3. OTP auto-fills → Verifies automatically
4. Success! → User authenticated

## ⚠️ Important

- **Android Only:** Auto OTP fetch only works on Android devices
- **iOS:** Users must manually enter OTP
- **Format:** Firebase sends 6-digit OTP, app uses first 4 digits
- **Requires:** Google Play Services on device
- **Testing:** Use real phone number, not emulator phone

## 📝 Modified Files

1. `lib/core/services/firebase_auth_service.dart` - New service
2. `lib/features/auth/presentation/screens/login_screen.dart` - Firebase integration
3. `lib/features/auth/presentation/screens/otp_verification_screen.dart` - Auto OTP
4. `lib/main.dart` - Route updates
5. `android/app/src/main/AndroidManifest.xml` - SMS permissions
6. `pubspec.yaml` - Added firebase_auth, sms_autofill

## 🐛 Troubleshooting

**OTP not sending?**
- Check Firebase Console → Phone auth enabled?
- Verify SHA-1 fingerprint added
- Update google-services.json

**Auto-fetch not working?**
- Android device only
- Check Play Services installed
- Verify SMS permissions granted
- Look for "📱 SMS Auto-fetch initialized" in logs

**Verification failing?**
- Check phone format: +91XXXXXXXXXX
- Verify OTP within 30 seconds
- Check Firebase Console for errors

## 🚀 Next Steps

1. ✅ Complete Firebase Console setup above
2. ✅ Test on Android device with real phone number
3. ✅ Verify auto OTP fetch works
4. ✅ Check error handling
5. ⚠️ Add release SHA-1 before production deploy

## 📖 Full Documentation

See [FIREBASE_PHONE_AUTH_SETUP.md](FIREBASE_PHONE_AUTH_SETUP.md) for complete details.

---

**Status:** ✅ Implementation Complete  
**Needs:** Firebase Console Configuration  
**Testing:** Ready to test on device
