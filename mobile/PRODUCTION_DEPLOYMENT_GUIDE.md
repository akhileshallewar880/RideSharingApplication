# 🚀 VanYatra Mobile App - Production Deployment Guide

## ✅ Production Configuration Complete

**Date**: January 15, 2026  
**Version**: 1.0.1  
**Build**: 3

---

## 📱 Production API Configuration

### Azure App Service Endpoint
```
URL: https://vayatra-app-service-baczabgbcbczg2b4.centralindia-01.azurewebsites.net
Region: Central India
Protocol: HTTPS
API Version: /api/v1
```

### Updated Files
The following files have been configured with the production Azure App Service URL:

1. **`lib/app/constants/app_constants.dart`**
   - Updated `baseUrl` to Azure App Service domain
   - Updated `socketBaseUrl` for SignalR real-time tracking
   - Changed protocol from HTTP to HTTPS

2. **`lib/config/environment.dart`**
   - Updated default `apiBaseUrl`
   - Set `isProduction` to true

3. **`lib/features/passenger/presentation/screens/ride_checkout_screen.dart`**
   - Updated payment gateway base URL

4. **`build-production-apk.sh`**
   - Updated build script with new production URL
   - Incremented build number to 3

---

## 🔐 Security Configuration

### Keystore Details
- **File**: `android/release-keystore.jks`
- **Alias**: release-key
- **Validity**: 10,000 days
- **Organization**: VanYatra
- **Location**: Gadchiroli, Maharashtra, India

### APK Security Features
- ✅ Code obfuscation enabled
- ✅ Debug symbols separated
- ✅ Minification enabled
- ✅ Signed with release key
- ✅ HTTPS enforced for all API calls

---

## 📦 Build Configuration

### Version Information
```yaml
App Name: VanYatra
Package: com.allapalli.allapalli_ride
Version Name: 1.0.1
Version Code: 3
Min SDK: 23 (Android 6.0)
Target SDK: 34 (Android 14)
```

### Build Features
- **Obfuscation**: Enabled (`--obfuscate`)
- **Symbol Split**: Yes (stored in `build/app/outputs/symbols`)
- **Minify**: Enabled
- **Shrink Resources**: Enabled

---

## 🎯 APK Output Location

After successful build, the APK will be available at:
```
Location: mobile/release-builds/vanyatra-v1.0.1-build3-[timestamp].apk
Original: mobile/build/app/outputs/flutter-apk/app-release.apk
Size: ~89MB
```

Files generated:
- **APK File**: `vanyatra-v1.0.1-build3-[timestamp].apk`
- **Checksum**: `vanyatra-v1.0.1-build3-[timestamp].apk.sha256`

---

## 🚀 Deployment Steps

### 1. Test the APK
```bash
# Install on connected device
adb install -r release-builds/vanyatra-v1.0.1-build3-*.apk

# Check logs
adb logcat | grep -i vanyatra
```

### 2. Verify Functionality
- [ ] Login with OTP works
- [ ] Location services work
- [ ] Maps display correctly
- [ ] Ride booking functional
- [ ] Real-time tracking works
- [ ] Payment integration works
- [ ] Push notifications work
- [ ] Driver features work (if applicable)

### 3. Distribution Options

#### Option A: Google Play Store
1. Go to [Google Play Console](https://play.google.com/console)
2. Create new app or select existing app
3. Upload APK to Internal Testing track first
4. Test thoroughly
5. Promote to Production when ready

#### Option B: Direct Distribution
```bash
# Generate download link or QR code
# Distribute via:
- Email
- WhatsApp
- Website download
- Firebase App Distribution
```

#### Option C: Firebase App Distribution
```bash
# Install Firebase CLI if not installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy to Firebase App Distribution
firebase appdistribution:distribute \
  release-builds/vanyatra-v1.0.1-build3-*.apk \
  --app YOUR_FIREBASE_APP_ID \
  --groups testers
```

---

## 🔍 API Endpoints

All API requests will use the Azure App Service:

### Base URLs
```
API Base: https://vayatra-app-service-baczabgbcbczg2b4.centralindia-01.azurewebsites.net/api/v1
SignalR: https://vayatra-app-service-baczabgbcbczg2b4.centralindia-01.azurewebsites.net/tracking
```

### Key Endpoints
- **Auth**: `/api/v1/auth/*`
- **Passenger**: `/api/v1/passenger/*`
- **Driver**: `/api/v1/driver/*`
- **Rides**: `/api/v1/rides/*`
- **Bookings**: `/api/v1/bookings/*`
- **Payments**: `/api/v1/payments/*`
- **Real-time Tracking**: `/tracking` (SignalR Hub)

---

## 🔧 Troubleshooting

### Common Issues

#### 1. APK Installation Fails
```bash
# Clear app data and retry
adb uninstall com.allapalli.allapalli_ride
adb install -r release-builds/vanyatra-v1.0.1-build3-*.apk
```

#### 2. API Connection Issues
- Verify Azure App Service is running
- Check CORS configuration on backend
- Verify SSL certificate is valid
- Test API endpoint manually:
  ```bash
  curl https://vayatra-app-service-baczabgbcbczg2b4.centralindia-01.azurewebsites.net/api/v1/health
  ```

#### 3. Push Notifications Not Working
- Verify Firebase configuration
- Check FCM token registration
- Verify backend is sending notifications correctly

#### 4. Location Permissions
- Ensure location permissions are granted in Android settings
- Check background location permission (Android 10+)

---

## 📊 Build Script Features

The `build-production-apk.sh` script provides:
- ✅ Automated clean and build
- ✅ Keystore verification
- ✅ Version management
- ✅ SHA-256 checksum generation
- ✅ Organized output directory
- ✅ Build artifact archiving
- ✅ Detailed logging

### Running the Build Script
```bash
cd mobile
./build-production-apk.sh
```

---

## 📝 Release Checklist

Before releasing to production:

### Pre-Release
- [ ] All features tested on physical devices
- [ ] API endpoints verified with production server
- [ ] Push notifications tested
- [ ] Payment integration tested
- [ ] Location tracking tested
- [ ] App performance benchmarked
- [ ] Memory leaks checked
- [ ] Battery usage optimized

### Security
- [ ] ProGuard/R8 obfuscation enabled
- [ ] API keys secured
- [ ] HTTPS enforced
- [ ] Certificate pinning implemented (if required)
- [ ] Sensitive data encrypted

### Compliance
- [ ] Privacy policy updated
- [ ] Terms of service reviewed
- [ ] Permissions properly explained
- [ ] GDPR compliance (if applicable)
- [ ] Store listing prepared

### Distribution
- [ ] App icon finalized
- [ ] Screenshots captured
- [ ] Store description written
- [ ] Release notes prepared
- [ ] Support email configured

---

## 🔄 Rebuilding for Updates

To rebuild with updated code:

```bash
cd mobile

# Update version in pubspec.yaml
# version: 1.0.2+4  # Increment version and build number

# Update build script if needed
nano build-production-apk.sh

# Run build
./build-production-apk.sh
```

---

## 📞 Support & Monitoring

### Monitoring Tools
- **Firebase Crashlytics**: Monitor app crashes
- **Firebase Analytics**: Track user behavior
- **Azure App Insights**: Monitor API performance

### Support Channels
- Email: support@vanyatra.com (configure)
- Phone: +91-XXXXXXXXXX (configure)
- In-app support chat (implement if needed)

---

## 🎉 Success Criteria

Production deployment is successful when:
- ✅ APK installs without errors
- ✅ All features work as expected
- ✅ API calls succeed with Azure App Service
- ✅ Real-time tracking functions properly
- ✅ Payments process successfully
- ✅ No critical crashes in first 24 hours
- ✅ User feedback is positive

---

**Build Status**: In Progress  
**Expected Completion**: 2-3 minutes  
**Next Step**: Test APK on physical device

Last Updated: January 15, 2026
