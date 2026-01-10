# 📱 OTP Banner Integration - Complete Guide

## ✅ What's Been Done

### 1. Created OTP Banner Folder Structure
- Created: `mobile/assets/images/otp_banners/`
- Added README with detailed instructions

### 2. Updated OTP Verification Screen
**File:** `mobile/lib/features/auth/presentation/screens/otp_verification_screen.dart`

Added features:
- ✨ **Auto-playing banner carousel** (rotates every 4 seconds)
- 📱 **3 custom banner slots** ready for your images
- 🎨 **Text overlay system** with gradient for readability
- 🔄 **Smooth transitions** with elegant animations
- 🛡️ **Fallback design** if images fail to load (yellow gradient)
- 📐 **Responsive design** adapts to all screen sizes

### 3. Updated pubspec.yaml
Added asset paths:
```yaml
assets:
  - assets/images/
  - assets/images/light/
  - assets/images/dark/
  - assets/images/otp_banners/  # ← New
```

### 4. Ran `flutter pub get`
✅ All dependencies resolved and new assets registered

---

## 📋 Your Action Items

### Step 1: Add Your Banner Images

Place your **3 custom banner images** in:
```
mobile/assets/images/otp_banners/
```

**Required file names:**
- `otp_banner_1.png` - Welcome/intro banner
- `otp_banner_2.png` - Safety/trust banner
- `otp_banner_3.png` - Community/connection banner

**Image specifications:**
- Format: PNG (recommended) or JPG
- Aspect ratio: 16:9 (landscape) or 3:2
- Recommended size: 1200x675px or 1080x720px
- Max file size: 500KB for best performance

### Step 2: Customize Banner Text (Optional)

The app adds text overlays on your banners. To customize:

**Edit:** `mobile/lib/features/auth/presentation/screens/otp_verification_screen.dart`

**Find the `_otpBanners` list (around line 32):**
```dart
final List<Map<String, String>> _otpBanners = [
  {
    'image': 'assets/images/otp_banners/otp_banner_1.png',
    'title': 'Welcome to VanYatra! 🚗',  // ← Edit this
    'subtitle': 'Your trusted rural ride booking platform',  // ← Edit this
  },
  {
    'image': 'assets/images/otp_banners/otp_banner_2.png',
    'title': 'Safe & Secure Rides',
    'subtitle': 'Verified drivers for your peace of mind',
  },
  {
    'image': 'assets/images/otp_banners/otp_banner_3.png',
    'title': 'Connect Rural Communities',
    'subtitle': 'Bridging distances, connecting lives',
  },
];
```

**Text styling features:**
- Title: Bold, large text
- Subtitle: Smaller descriptive text
- Both have shadow effects for readability
- Positioned at bottom-left with dark gradient overlay

### Step 3: Test the Banners

```bash
# Option 1: Hot Restart (recommended)
# Press 'R' in terminal where Flutter is running

# Option 2: Fresh Run
cd mobile
flutter run
```

Navigate to OTP screen by:
1. Open app
2. Enter phone number
3. Click "Continue with OTP"
4. You'll see the banner carousel on OTP verification screen

---

## 🎨 Banner Display Features

### Carousel Behavior
- **Auto-play:** Rotates every 4 seconds
- **Manual swipe:** Users can swipe to change banners
- **Smooth animations:** 800ms transition with ease curve
- **Center focus:** Enlarges the current banner

### Layout
- **Height:** 180px fixed height
- **Viewport:** 90% width (0.9 viewport fraction)
- **Margin:** 5px horizontal spacing
- **Border radius:** Large rounded corners
- **Shadow:** Subtle drop shadow for depth

### Text Overlay
- **Position:** Bottom-left corner (16px padding)
- **Background:** Dark gradient (transparent → 70% black)
- **Shadow:** Text shadows for contrast
- **Colors:** White text on dark overlay

### Error Handling
- If image fails to load: Shows yellow gradient fallback
- Logs error to console for debugging
- Gracefully continues without breaking UI

---

## 🔍 Troubleshooting

### Banners Not Showing?

**Check 1: File names match exactly**
```bash
cd mobile/assets/images/otp_banners/
ls -la
# Should show:
# otp_banner_1.png
# otp_banner_2.png
# otp_banner_3.png
```

**Check 2: Run pub get again**
```bash
cd mobile
flutter pub get
```

**Check 3: Hot restart (not hot reload)**
- Press `R` (capital R) in terminal, not `r`

**Check 4: Check console for errors**
Look for messages like:
```
Error loading banner image: ...
```

### Images Appear Stretched?

- Use 16:9 aspect ratio (e.g., 1920x1080, 1280x720)
- Or 3:2 ratio (e.g., 1200x800)

### Text Not Readable?

- Ensure images aren't too bright at the bottom
- The gradient overlay will help, but darker bottom areas work best
- Or adjust gradient opacity in the code (line ~590)

---

## 📂 File Structure

```
mobile/
├── assets/
│   └── images/
│       ├── otp_banners/
│       │   ├── README.md
│       │   ├── otp_banner_1.png  ← Add your image
│       │   ├── otp_banner_2.png  ← Add your image
│       │   └── otp_banner_3.png  ← Add your image
│       ├── light/
│       │   └── android_light_sq.png
│       └── dark/
│           └── android_dark_sq.png
├── lib/
│   └── features/
│       └── auth/
│           └── presentation/
│               └── screens/
│                   └── otp_verification_screen.dart  ← Banner logic
└── pubspec.yaml  ← Asset registration
```

---

## 🚀 Google Sign-In Button Status

### Changes Made
**File:** `mobile/lib/shared/widgets/buttons.dart`

- ✅ Simplified widget structure (removed GestureDetector/ClipRRect)
- ✅ Changed to InkWell for better tap feedback
- ✅ Added error logging for debugging
- ✅ Improved fallback UI

### Button Assets
- Light mode: `assets/images/light/android_light_sq.png` (9KB) ✅
- Dark mode: `assets/images/dark/android_dark_sq.png` (9.5KB) ✅

### Testing Needed
Please test the Google Sign-In button:
1. Run the app
2. Check if button appears on login screen
3. Check console for any error messages
4. Test tap functionality

If still not visible, check:
- Console errors: `flutter run --verbose`
- Theme mode (light vs dark)
- Asset paths in pubspec.yaml

---

## 📊 Banner Analytics (Admin)

The admin web OTP banner management screen shows mock analytics:
- Banner 1: 1,245 impressions, 45 clicks
- Banner 2: 892 impressions, 38 clicks
- Banner 3: 654 impressions, 29 clicks

Currently using mock data. Real analytics integration can be added later.

---

## 🎯 Next Steps

1. ☐ Add your 3 banner images to otp_banners folder
2. ☐ (Optional) Customize banner text in otp_verification_screen.dart
3. ☐ Run `flutter run` or hot restart
4. ☐ Test banner carousel on OTP screen
5. ☐ Test Google Sign-In button visibility
6. ☐ Report any issues

---

## 📞 Need Help?

If you encounter issues:
1. Check the console output for error messages
2. Verify file names match exactly (case-sensitive)
3. Ensure images are valid PNG/JPG files
4. Try `flutter clean && flutter pub get && flutter run`

---

**Status:** ✅ Code Complete | ⏳ Awaiting Banner Images

**Date:** January 2, 2026
