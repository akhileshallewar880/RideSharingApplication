# Browser Version - Setup & Deployment Guide

## ✅ Changes Made

### 1. **Web-Compatible Firebase Phone Authentication**
- Modified `firebase_phone_service.dart` to support web platform using reCAPTCHA
- Modified `firebase_auth_service.dart` to support web platform using reCAPTCHA
- Added reCAPTCHA container to `web/index.html`
- Automatically detects platform (web vs mobile) and uses appropriate authentication method

### 2. **Skip Authentication Flow for Web**
- Modified `main.dart` to bypass splash and login screens on web
- Web users go directly to `PassengerHomeScreen`
- Authentication triggered via bottom sheet when user tries to book a ride

### 3. **Authentication Flow on Web**

#### For Unauthenticated Users:
1. User opens browser app → lands directly on home screen
2. User can browse available rides without logging in
3. When user clicks "Book Ride", they see verification bottom sheet
4. User enters phone number → Firebase sends OTP (with reCAPTCHA verification)
5. User enters OTP → authenticated → booking proceeds

#### reCAPTCHA Behavior:
- Google Firebase automatically shows reCAPTCHA widget when sending OTP on web
- This is a security requirement for web-based phone authentication
- reCAPTCHA verifies user is not a bot before sending SMS

---

## 🚀 Running Browser Version Locally

### Development Mode (with hot reload)
```bash
cd mobile
flutter run -d chrome
```

### Production Build
```bash
cd mobile
flutter build web --release
```

Then serve the `build/web` directory:
```bash
# Option 1: Using Python
cd build/web
python3 -m http.server 8000

# Option 2: Using Node.js
npx serve build/web

# Option 3: Using PHP
cd build/web
php -S localhost:8000
```

Access at: `http://localhost:8000`

---

## 🌐 Deploying to Production

### Option 1: Azure Static Web Apps (Recommended)

**Manual Deployment:**
```bash
cd mobile
flutter build web --release
cd build/web

# Install Azure CLI if not already installed
# brew install azure-cli  # macOS
# az login

# Deploy (replace with your Static Web App details)
az staticwebapp upload \
  --name your-app-name \
  --resource-group your-resource-group \
  --source .
```

**Automated Deployment (GitHub Actions):**

Create `.github/workflows/deploy-passenger-web.yml`:
```yaml
name: Deploy Passenger Web

on:
  push:
    branches:
      - main
    paths:
      - 'mobile/**'

jobs:
  build_and_deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      
      - name: Install dependencies
        run: |
          cd mobile
          flutter pub get
      
      - name: Build web
        run: |
          cd mobile
          flutter build web --release
      
      - name: Deploy to Azure Static Web Apps
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          action: "upload"
          app_location: "mobile/build/web"
          skip_app_build: true
```

### Option 2: Firebase Hosting

```bash
cd mobile

# Build web version
flutter build web --release

# Install Firebase CLI if not already installed
# npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase (if not already initialized)
firebase init hosting

# Deploy
firebase deploy --only hosting
```

### Option 3: Netlify

```bash
cd mobile
flutter build web --release

# Install Netlify CLI
# npm install -g netlify-cli

# Deploy
netlify deploy --dir=build/web --prod
```

---

## 🔒 Firebase Configuration

### Test Phone Numbers (for testing without SMS)

Add test phone numbers in Firebase Console:
1. Go to Firebase Console → Authentication → Sign-in method → Phone
2. Scroll to "Phone numbers for testing"
3. Add test numbers with static OTP codes

Example:
- Phone: +91 9876543210
- OTP: 123456

### reCAPTCHA Settings

Firebase automatically configures reCAPTCHA for web. If you need to customize:

1. Go to Firebase Console → Authentication → Settings → App Check
2. Configure reCAPTCHA v2/v3 settings
3. Add your domain to authorized domains

---

## 🧪 Testing

### Local Testing
```bash
# Run in Chrome
flutter run -d chrome

# Run in different browsers (if installed)
flutter run -d edge
flutter run -d safari
```

### Testing Authentication Flow
1. Open browser app
2. Navigate around the home screen (should work without login)
3. Click "Book Ride"
4. Verify bottom sheet appears
5. Enter phone number
6. Verify reCAPTCHA appears
7. Complete reCAPTCHA
8. Enter OTP received via SMS
9. Verify authentication succeeds

---

## ⚠️ Important Notes

### 1. **SMS Quota**
- Firebase Phone Auth on web counts towards SMS quota
- Use test phone numbers for development
- Monitor usage in Firebase Console

### 2. **reCAPTCHA**
- Required for web phone authentication
- Cannot be disabled
- Users must complete reCAPTCHA before receiving OTP

### 3. **Domain Whitelisting**
- Add your production domain to Firebase authorized domains
- Go to Firebase Console → Authentication → Settings → Authorized domains

### 4. **CORS**
- If using custom domain, configure CORS on backend
- Allow requests from your web app domain

### 5. **Browser Compatibility**
- Tested on Chrome, Firefox, Safari, Edge
- Modern browsers with JavaScript enabled required
- reCAPTCHA requires cookies enabled

---

## 🐛 Troubleshooting

### "Firebase Exception" Error
**Cause:** reCAPTCHA not properly initialized or domain not whitelisted

**Fix:**
1. Clear browser cache
2. Verify domain is in Firebase authorized domains
3. Check browser console for detailed error
4. Ensure `recaptcha-container` div exists in `web/index.html`

### OTP Not Received
**Cause:** SMS quota exceeded or phone number not valid

**Fix:**
1. Use test phone numbers for development
2. Check Firebase Console → Authentication → Usage
3. Upgrade Firebase plan if quota exceeded

### reCAPTCHA Appears Too Often
**Cause:** Firebase security threshold triggered

**Fix:**
1. Add domain to authorized domains
2. Use test phone numbers in development
3. Contact Firebase support if issue persists in production

---

## 📱 Differences from Mobile App

| Feature | Mobile App | Browser Version |
|---------|------------|----------------|
| Initial Screen | Splash → Login | Home Screen (skip auth) |
| Authentication | Required on launch | On-demand (when booking) |
| reCAPTCHA | Not shown | Required for OTP |
| Auto OTP Detection | Yes (Android) | No |
| Push Notifications | Yes | Limited (requires service worker) |
| Offline Support | Yes (with Hive) | Limited |

---

## 🎯 Next Steps

1. **Add Domain to Firebase:**
   - Production domain
   - Staging domain (if any)

2. **Configure Backend CORS:**
   - Allow requests from web app domain
   - Update CORS policy in server

3. **Monitor Usage:**
   - Track SMS quota in Firebase
   - Monitor authentication success rate

4. **User Experience:**
   - Test on different browsers
   - Verify reCAPTCHA experience
   - Test on mobile browsers vs desktop

---

## 🔗 Useful Resources

- [Firebase Phone Auth for Web](https://firebase.google.com/docs/auth/web/phone-auth)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Azure Static Web Apps Docs](https://docs.microsoft.com/azure/static-web-apps/)
- [Firebase Hosting Docs](https://firebase.google.com/docs/hosting)
