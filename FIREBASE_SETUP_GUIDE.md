# Firebase Setup Guide - Fix Google Sign-In & Phone Auth

## 🔥 Critical Issues Found

### Issue 1: Google Sign-In Not Working
**Problem:** Your `google-services.json` file has an empty `oauth_client` array, which means Google Sign-In credentials are not configured.

### Issue 2: Firebase Phone Auth Not Working
**Problem:** OTP is still being sent to your backend instead of using Firebase Phone Authentication.

---

## ✅ Solution Steps

### Step 1: Enable Phone Authentication in Firebase Console

1. **Go to Firebase Console:**
   - Visit: https://console.firebase.google.com/
   - Select your project: `vanyatra-69e38`

2. **Enable Phone Authentication:**
   - Click on **"Authentication"** in the left menu
   - Click on **"Sign-in method"** tab
   - Find **"Phone"** in the list of providers
   - Click on **"Phone"** and toggle **"Enable"**
   - Click **"Save"**

   **Screenshot reference:**
   ```
   Authentication > Sign-in method
   ┌─────────────────────────────────────┐
   │ Phone                    [ Enable ] │  ← Click this toggle
   └─────────────────────────────────────┘
   ```

---

### Step 2: Fix Google Sign-In Configuration

#### 2.1: Enable Google Sign-In Provider

1. **In Firebase Console:**
   - Go to **Authentication > Sign-in method**
   - Find **"Google"** in the providers list
   - Click on **"Google"**
   - Toggle **"Enable"**
   - Set **Support email** (use your email)
   - Click **"Save"**

#### 2.2: Configure OAuth 2.0 Client in Google Cloud Console

1. **Go to Google Cloud Console:**
   - Visit: https://console.cloud.google.com/
   - Select project: `vanyatra-69e38`

2. **Create OAuth 2.0 Client ID:**
   - Go to **"APIs & Services" > "Credentials"**
   - Click **"+ CREATE CREDENTIALS"**
   - Select **"OAuth client ID"**

3. **Configure OAuth consent screen (if not done):**
   - User Type: **External**
   - App name: `VanYatra`
   - User support email: Your email
   - Developer contact: Your email
   - Click **"Save and Continue"**

4. **Create Android OAuth Client:**
   - Application type: **Android**
   - Name: `VanYatra Android Client`
   - Package name: `com.allapalli.allapalli_ride`
   - SHA-1 certificate fingerprint: `C8:58:76:47:2C:D9:8D:46:C8:A5:FD:75:96:20:02:B0:D8:33:F8:72`
   - Click **"Create"**

5. **Create Web OAuth Client (Required for Firebase):**
   - Click **"+ CREATE CREDENTIALS"** again
   - Select **"OAuth client ID"**
   - Application type: **Web application**
   - Name: `VanYatra Web Client (for Firebase)`
   - Click **"Create"**
   - **IMPORTANT:** Copy the **Client ID** that appears (starts with something like `657234227532-...googleusercontent.com`)

#### 2.3: Download Updated google-services.json

1. **Go back to Firebase Console:**
   - Project Settings (gear icon) > General tab
   - Scroll down to **"Your apps"** section
   - Find your Android app: `com.allapalli.allapalli_ride`
   - Click **"google-services.json"** to download the updated file

2. **Replace the old file:**
   ```bash
   # Backup old file
   cp mobile/android/app/google-services.json mobile/android/app/google-services.json.backup
   
   # Copy the new downloaded file to:
   mobile/android/app/google-services.json
   ```

3. **Verify the new file has OAuth clients:**
   - Open the new `google-services.json`
   - Look for `"oauth_client"` array
   - It should now have entries (not empty `[]`)

   **Should look like:**
   ```json
   "oauth_client": [
     {
       "client_id": "657234227532-xxxxx.apps.googleusercontent.com",
       "client_type": 1,
       "android_info": {
         "package_name": "com.allapalli.allapalli_ride",
         "certificate_hash": "c85876472c9d8d46c8a5fd759620002bd8033f872"
       }
     },
     {
       "client_id": "657234227532-yyyyy.apps.googleusercontent.com",
       "client_type": 3
     }
   ]
   ```

---

### Step 3: Verify App Configuration

1. **Check SHA-1 is added in Firebase Console:**
   - Firebase Console > Project Settings > General
   - Scroll to **"Your apps"** > Android app
   - Expand **"SHA certificate fingerprints"**
   - Verify: `C8:58:76:47:2C:D9:8D:46:C8:A5:FD:75:96:20:02:B0:D8:33:F8:72` is listed
   - If not, click **"Add fingerprint"** and paste it

2. **Verify minSdkVersion:**
   - Open `mobile/android/app/build.gradle`
   - Check: `minSdkVersion 23` (already fixed ✅)

---

### Step 4: Rebuild and Test

1. **Clean and rebuild:**
   ```bash
   cd mobile
   flutter clean
   flutter pub get
   flutter build apk --debug
   ```

2. **Test Phone Authentication:**
   - Enter your phone number on login screen
   - Firebase should send OTP (check console for logs)
   - OTP should auto-fill in the app

3. **Test Google Sign-In:**
   - Click on Google Sign-In button
   - Should show Google account picker
   - Should successfully authenticate

---

## 🔍 Verification Checklist

After completing all steps, verify:

- [ ] Phone authentication is **enabled** in Firebase Console
- [ ] Google Sign-In is **enabled** in Firebase Console
- [ ] OAuth 2.0 client (Android) is created with correct package name and SHA-1
- [ ] OAuth 2.0 client (Web) is created for Firebase
- [ ] New `google-services.json` downloaded and replaced
- [ ] `oauth_client` array in `google-services.json` is **not empty**
- [ ] SHA-1 fingerprint is added in Firebase Console
- [ ] App rebuilt after replacing `google-services.json`
- [ ] Phone OTP is sent via Firebase (not backend)
- [ ] Google Sign-In shows account picker

---

## 🐛 Troubleshooting

### Phone Auth Still Not Working?

1. **Check Firebase Console Logs:**
   - Firebase Console > Authentication > Users
   - Check if any auth attempts are logged

2. **Enable Test Phone Numbers (Optional for testing):**
   - Firebase Console > Authentication > Sign-in method
   - Scroll to **"Phone"** section
   - Add test phone numbers with static OTP codes

3. **Check app logs:**
   ```bash
   flutter run
   # Look for Firebase authentication logs
   ```

### Google Sign-In Still Failing?

1. **Verify OAuth client:**
   ```bash
   # Check if google-services.json has oauth_client entries
   cat mobile/android/app/google-services.json | grep -A 20 "oauth_client"
   ```

2. **Check SHA-1 hash matches:**
   ```bash
   # Generate current SHA-1
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # Should match: C8:58:76:47:2C:D9:8D:46:C8:A5:FD:75:96:20:02:B0:D8:33:F8:72
   ```

3. **Verify package name:**
   - Should be exactly: `com.allapalli.allapalli_ride`
   - Check in: `mobile/android/app/build.gradle` → `applicationId`
   - Check in: `mobile/android/app/src/main/AndroidManifest.xml` → `package`

4. **Re-download google-services.json:**
   - Wait 5-10 minutes after creating OAuth clients
   - Download again from Firebase Console
   - Firebase needs time to propagate the changes

---

## 📱 Current Configuration Summary

- **Project ID:** `vanyatra-69e38`
- **Package Name:** `com.allapalli.allapalli_ride`
- **SHA-1 Debug:** `C8:58:76:47:2C:D9:8D:46:C8:A5:FD:75:96:20:02:B0:D8:33:F8:72`
- **minSdkVersion:** `23`
- **Firebase Core:** `2.27.0`
- **Firebase Auth:** `4.16.0`
- **Firebase Messaging:** `14.7.19`

---

## 🎯 Expected Behavior After Fix

1. **Phone Authentication:**
   - Enter phone number → Firebase sends OTP
   - OTP auto-fills in the app
   - Verification happens through Firebase, not your backend

2. **Google Sign-In:**
   - Click Google Sign-In button
   - Google account picker appears
   - Select account → Automatically signed in
   - Navigates to home screen based on user type

---

## 📞 Need Help?

If you still face issues after following all steps:

1. Check Firebase Console logs
2. Check Flutter app logs (`flutter run --verbose`)
3. Verify all OAuth clients are created correctly
4. Ensure `google-services.json` is in the correct location
5. Try uninstalling and reinstalling the app

**Remember:** After downloading the new `google-services.json`, you MUST rebuild the app for changes to take effect!
