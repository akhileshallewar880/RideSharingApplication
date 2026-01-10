# Google Sign-In with Automatic Phone Number Fetching

## 🎯 What Changed

### Problem
When users sign in with Google, the app was assigning a placeholder phone number "0000000000" even if the user had a phone number in their Google account.

### Solution
Now the app automatically fetches the phone number from the user's Google account (if available) and marks it as verified.

## ✅ Implementation

### 1. Added Phone Number Scope
**File:** `mobile/lib/core/services/auth_service.dart`

Added Google OAuth scope to request phone number access:
```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [
    'email',
    'profile',
    'https://www.googleapis.com/auth/user.phonenumbers.read', // NEW: Phone number scope
  ],
  serverClientId: '...',
);
```

### 2. Fetch Phone from Google People API
**Function:** `_fetchPhoneNumberFromGoogle()`

Automatically calls Google People API to retrieve phone number:
```dart
Future<String?> _fetchPhoneNumberFromGoogle(String? accessToken) async {
  // Calls: https://people.googleapis.com/v1/people/me?personFields=phoneNumbers
  // Returns: Cleaned phone number with country code (+91XXXXXXXXXX)
}
```

**Features:**
- ✅ Fetches phone number from Google account
- ✅ Cleans up formatting (removes spaces, dashes)
- ✅ Adds country code if missing (+91 for India)
- ✅ Handles errors gracefully (returns null if not available)

### 3. Updated Google Sign-In Flow
**Modified:** `signInWithGoogle()` method

**New Flow:**
```
1. User completes Google Sign-In
   ↓
2. Get ID token and access token
   ↓
3. Try to fetch phone number from Google People API
   ↓
4. If phone found:
   - Use Google's phone number
   - Mark as verified
   - Send to backend
   ↓
5. If phone NOT found:
   - Use unique placeholder (GOOGLE_xxxxx)
   - Mark as not verified
   - User can add phone later
   ↓
6. Backend creates/updates user
```

### 4. Backend Updates
**File:** `AuthController.cs`

**Changes:**
- Accept optional `PhoneNumber` from request
- If phone provided: Mark as verified, log as "verified"
- If no phone: Generate unique placeholder `GOOGLE_{guid}`
- Enhanced logging to track phone verification status

**Log Output:**
```
✅ Fetched phone number from Google: +919876543210
Google Sign-In - New user created: {UserId}, Email: {Email}, Phone: +919876543210, Verified: True
```

## 🔄 User Experience

### Scenario 1: User HAS Phone in Google Account
```
1. User taps "Sign in with Google"
   ↓
2. Google authentication completes
   ↓
3. App fetches phone: +919876543210 ✅
   ↓
4. Backend creates user with verified phone
   ↓
5. Navigate to home screen
```
**Result:** Phone automatically fetched and verified!

### Scenario 2: User DOESN'T Have Phone in Google Account
```
1. User taps "Sign in with Google"
   ↓
2. Google authentication completes
   ↓
3. App tries to fetch phone: None found ⚠️
   ↓
4. Backend creates user with placeholder: GOOGLE_a1b2c3d4e5
   ↓
5. User can add phone later from settings
```
**Result:** User can still sign in, add phone later

### Scenario 3: Manual Phone Entry (Fallback)
If Google doesn't have phone OR user wants different number:
```
1. User goes to Settings/Profile
   ↓
2. Taps "Add Phone Number"
   ↓
3. Firebase phone verification flow
   ↓
4. Phone verified and updated
```

## 📱 Required Permissions

### Google OAuth Consent Screen
You may need to configure the OAuth consent screen in Google Cloud Console:

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your project
3. Navigate to **APIs & Services** → **OAuth consent screen**
4. Under **Scopes**, add:
   - `.../auth/userinfo.email` ✅ (Already added)
   - `.../auth/userinfo.profile` ✅ (Already added)
   - `.../auth/user.phonenumbers.read` ⚠️ **NEW - Must add**

### Firebase Console
No changes needed - phone scope is OAuth-level, not Firebase-level.

## 🔍 Debug Logs

### Successful Phone Fetch
```
✅ Google Sign-In successful
   Email: user@gmail.com
   Name: John Doe
📱 Fetching phone number from Google People API...
✅ Found phone number: +919876543210
✅ Fetched phone number from Google: +919876543210
✅ Google authentication completed successfully
```

### No Phone Available
```
✅ Google Sign-In successful
   Email: user@gmail.com
   Name: John Doe
📱 Fetching phone number from Google People API...
⚠️ No phone numbers found in Google account
⚠️ No phone number found in Google account
```

### Backend Logs (With Phone)
```
Google Sign-In - Email: user@gmail.com, Name: John Doe
Using verified phone number from Google: +919876543210
Google Sign-In - New user created: {UserId}, Email: user@gmail.com, Phone: +919876543210, Verified: True
```

### Backend Logs (Without Phone)
```
Google Sign-In - Email: user@gmail.com, Name: Jane Doe
No phone number provided, using placeholder: GOOGLE_a1b2c3d4e5
Google Sign-In - New user created: {UserId}, Email: user@gmail.com, Phone: GOOGLE_a1b2c3d4e5, Verified: False
```

## 🐛 Troubleshooting

### Issue: "403 Forbidden" from Google People API
**Cause:** Phone number scope not enabled in OAuth consent screen
**Solution:** Add `user.phonenumbers.read` scope in Google Cloud Console

### Issue: Phone number still shows as "0000000000"
**Cause:** Using old code, backend not updated
**Solutions:**
1. Rebuild frontend: `flutter clean && flutter run`
2. Restart backend: Stop and restart .NET server
3. Delete test user from database
4. Sign in again

### Issue: Phone format incorrect
**Current:** +919876543210 (Indian format)
**Solution:** Phone cleaning logic adds +91 by default
**For other countries:** Update the logic in `_fetchPhoneNumberFromGoogle()`

## ✅ Testing

### Test with Google Account (Has Phone)
1. Sign in with Google account that has phone number
2. Check logs for "✅ Fetched phone number from Google"
3. Verify backend logs show "Verified: True"
4. Check database - phone should be real number, not placeholder

### Test with Google Account (No Phone)
1. Sign in with Google account without phone number
2. Check logs for "⚠️ No phone number found"
3. Verify backend logs show "using placeholder"
4. Check database - phone should be GOOGLE_xxxxx format

### Verify Database
```sql
SELECT 
    Email,
    PhoneNumber,
    UserType,
    IsEmailVerified,
    CreatedAt
FROM Users
WHERE Email LIKE '%@gmail.com'
ORDER BY CreatedAt DESC;
```

**Expected Results:**
- ✅ Phone: +919876543210 (real number) OR GOOGLE_xxxxx (unique)
- ✅ IsEmailVerified: 1 (true)
- ✅ No duplicate "0000000000" entries

## 📊 Success Criteria

✅ **Working Correctly:**
- Phone number automatically fetched from Google
- Real phone numbers stored in database
- Unique placeholders for users without phone
- No more "0000000000" duplicates
- Verified flag tracked correctly

❌ **Needs Fix:**
- Still seeing "0000000000" in database
- 403 errors from Google People API
- Phone numbers not fetched

## 🎉 Benefits

### Before This Fix
- ❌ All Google users got "0000000000"
- ❌ Duplicate key violations
- ❌ Phone verification required for everyone
- ❌ Manual phone entry always needed

### After This Fix
- ✅ Real phone numbers fetched automatically
- ✅ Unique placeholders (no duplicates)
- ✅ Phone verification only if needed
- ✅ Seamless user experience

## 📝 Database Schema Reference

### Users Table
```sql
PhoneNumber VARCHAR(20) UNIQUE  -- Real phone OR unique placeholder
IsEmailVerified BIT             -- Always TRUE for Google users
Email VARCHAR(255)              -- From Google account
UserType VARCHAR(50)            -- Default: 'passenger'
```

### Expected Values
| Scenario | PhoneNumber | IsEmailVerified |
|----------|------------|-----------------|
| Google (has phone) | +919876543210 | TRUE |
| Google (no phone) | GOOGLE_a1b2c3d4e5 | TRUE |
| OTP registration | +919876543210 | FALSE |

## 🔄 Migration Path

### For Existing Users with "0000000000"
Run SQL to clean up:
```sql
-- Update existing Google users with unique placeholders
UPDATE Users
SET PhoneNumber = 'GOOGLE_' + LEFT(CAST(NEWID() AS VARCHAR(36)), 10)
WHERE PhoneNumber = '0000000000'
  AND Email IS NOT NULL
  AND Email LIKE '%@gmail.com';
```

## 📚 Related Documentation

- [GOOGLE_SIGNIN_PHONE_VERIFICATION_COMPLETE.md](GOOGLE_SIGNIN_PHONE_VERIFICATION_COMPLETE.md) - Manual phone entry flow
- [GOOGLE_SIGNIN_PHONE_QUICK_START.md](GOOGLE_SIGNIN_PHONE_QUICK_START.md) - Quick testing guide

## ✨ Summary

Now when users sign in with Google:
1. ✅ App automatically fetches phone from Google account
2. ✅ Phone is marked as verified (no OTP needed)
3. ✅ Fallback to unique placeholder if no phone
4. ✅ No more duplicate "0000000000" errors
5. ✅ Users can add/update phone later if needed

**Result:** Seamless Google Sign-In with intelligent phone number handling! 🎊
