# Phone Number Autofill Feature Implementation

## 📱 Overview

This feature allows users to automatically fetch and select their existing phone numbers from their device when tapping on the phone number input field. Once selected, the phone number is populated, and the user can proceed to the OTP verification screen.

## ✨ Features Implemented

### 1. **Phone Number Hint Picker**
- When user taps on the empty phone number input field
- Google Account Picker shows up with phone numbers associated with the device
- User selects a phone number from the list
- Phone number is automatically populated in the input field

### 2. **Autofill Hints**
- Standard Android autofill framework support
- Phone number field is marked with `AutofillHints.telephoneNumber`
- Automatically suggests phone numbers from autofill services
- Works with password managers and Google Autofill

### 3. **Seamless Navigation**
- After phone number is populated, user can tap "Send OTP"
- App sends OTP via Firebase Auth
- Automatically navigates to OTP verification screen
- User enters OTP to complete authentication

## 🔧 Technical Implementation

### Files Modified

#### 1. **PhoneField Widget** (`mobile/lib/shared/widgets/input_fields.dart`)
```dart
/// Phone number input field with country code and autofill support
class PhoneField extends StatelessWidget {
  final String? label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enableAutofill;
  
  const PhoneField({
    super.key,
    this.label,
    this.controller,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.enableAutofill = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: label ?? 'Phone Number',
      hint: 'Enter 10-digit mobile number',
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.phone,
      validator: validator,
      onChanged: onChanged,
      prefixIcon: Icons.phone_outlined,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      // Enable phone autofill hints
      autofillHints: enableAutofill ? [AutofillHints.telephoneNumber] : null,
    );
  }
}
```

**Changes:**
- Added `enableAutofill` parameter (default: `true`)
- Added `autofillHints` parameter to enable native autofill
- Passes `AutofillHints.telephoneNumber` to underlying TextField

#### 2. **CustomTextField Widget** (`mobile/lib/shared/widgets/input_fields.dart`)
```dart
class CustomTextField extends StatefulWidget {
  // ... other parameters
  final Iterable<String>? autofillHints;
  
  const CustomTextField({
    // ... other parameters
    this.autofillHints,
  });
}

// In TextFormField:
TextFormField(
  // ... other parameters
  autofillHints: widget.autofillHints,
)
```

**Changes:**
- Added `autofillHints` parameter to support autofill framework
- Passes hints to underlying TextFormField

#### 3. **Login Screen** (`mobile/lib/features/auth/presentation/screens/login_screen.dart`)

**Imports Added:**
```dart
import 'package:sms_autofill/sms_autofill.dart';
```

**New Method Added:**
```dart
/// Show phone number hint picker
Future<void> _showPhoneNumberPicker() async {
  try {
    final hint = await SmsAutoFill().hint;
    if (hint != null && mounted) {
      // Extract only the phone number digits (remove +91 or any country code)
      String phoneNumber = hint.replaceAll(RegExp(r'[^\d]'), '');
      
      // If it starts with 91 (country code), remove it
      if (phoneNumber.length > 10 && phoneNumber.startsWith('91')) {
        phoneNumber = phoneNumber.substring(2);
      }
      
      // Take only the last 10 digits
      if (phoneNumber.length > 10) {
        phoneNumber = phoneNumber.substring(phoneNumber.length - 10);
      }
      
      setState(() {
        _phoneController.text = phoneNumber;
      });
    }
  } catch (e) {
    print('Error getting phone hint: $e');
  }
}
```

**UI Changes:**
```dart
// Wrapped Form with AutofillGroup
AutofillGroup(
  child: Form(
    key: _formKey,
    child: Column(
      // ... existing code
    ),
  ),
)

// Wrapped PhoneField with GestureDetector
GestureDetector(
  onTap: () {
    // Show phone number picker when field is tapped
    if (_phoneController.text.isEmpty) {
      _showPhoneNumberPicker();
    }
  },
  child: PhoneField(
    label: 'Mobile Number',
    controller: _phoneController,
    validator: _validatePhone,
  ),
)
```

**Changes:**
- Wrapped Form with `AutofillGroup` for native autofill support
- Added `GestureDetector` to detect tap on phone field
- Calls `_showPhoneNumberPicker()` when empty field is tapped
- Handles phone number extraction and formatting

#### 4. **Android Manifest** (`mobile/android/app/src/main/AndroidManifest.xml`)
```xml
<!-- Phone number hint permission for autofill -->
<uses-permission android:name="android.permission.READ_PHONE_NUMBERS" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
```

**Changes:**
- Added permissions to access phone numbers for hint picker
- Required for `SmsAutoFill().hint` to work

## 🎯 User Flow

```
1. User taps on "Mobile Number" input field
   ↓
2. If field is empty, phone hint picker is triggered
   ↓
3. Google Account Picker appears with phone numbers
   ↓
4. User selects their phone number
   ↓
5. Phone number is automatically populated (last 10 digits only)
   ↓
6. User taps "Send OTP" button
   ↓
7. Firebase sends OTP via SMS
   ↓
8. App navigates to OTP Verification Screen
   ↓
9. User enters OTP (auto-filled via SMS Retriever API)
   ↓
10. Authentication complete
```

## 🔐 Permissions Required

### Android
```xml
<!-- For phone number hint picker -->
<uses-permission android:name="android.permission.READ_PHONE_NUMBERS" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />

<!-- Already existing for SMS OTP -->
<uses-permission android:name="android.permission.RECEIVE_SMS" />
<uses-permission android:name="android.permission.READ_SMS" />
```

### iOS
Phone number autofill works natively via iOS keychain and doesn't require additional permissions.

## 📦 Dependencies Used

### Already in pubspec.yaml
```yaml
dependencies:
  sms_autofill: ^2.3.0  # For phone hint and SMS autofill
```

No additional dependencies needed!

## 🧪 Testing

### Test Scenarios

1. **Empty Field Tap**
   - Tap on empty phone number field
   - Verify Google Account Picker appears
   - Select a phone number
   - Verify only 10 digits are populated (without country code)

2. **Field with Existing Text**
   - Enter some digits manually
   - Tap on field
   - Verify picker doesn't trigger (only when empty)

3. **Autofill Framework**
   - Clear field
   - Tap on field
   - Check if autofill suggestions appear
   - Select from autofill dropdown

4. **Complete Flow**
   - Tap field → Select number → Send OTP → Navigate to OTP screen
   - Verify seamless navigation

### Test Devices
- Android 8.0+ (for full phone hint support)
- iOS 12+ (for native autofill)

## 🎨 UI/UX Considerations

1. **Non-intrusive**: Only triggers when field is empty
2. **Manual Entry Available**: Users can still type manually
3. **Format Handling**: Automatically extracts 10-digit Indian number
4. **Error Handling**: Gracefully handles cases where hint is unavailable

## 🚀 Future Enhancements

1. **Multiple Numbers**: Show all available numbers in a custom dialog
2. **SIM Card Detection**: Prioritize SIM card numbers
3. **Contact Integration**: Allow selecting from contacts (with permission)
4. **Smart Formatting**: Auto-format as user types (XXX-XXX-XXXX)

## ⚙️ Configuration

### Enable/Disable Autofill
```dart
PhoneField(
  enableAutofill: false,  // Disable autofill hints
  // ... other parameters
)
```

### Customize Behavior
To modify the phone hint picker behavior, edit `_showPhoneNumberPicker()` in login_screen.dart

## 🐛 Troubleshooting

### Phone Hint Not Showing
1. Ensure Google Play Services is installed and updated
2. Check that permissions are granted in AndroidManifest.xml
3. User must have at least one Google account signed in
4. Device must have phone numbers associated with Google account

### Wrong Number Format
- Check the regex and substring logic in `_showPhoneNumberPicker()`
- Verify country code removal logic

### Autofill Not Working
1. Ensure `AutofillGroup` wraps the Form
2. Check that `autofillHints` is properly passed
3. Enable autofill service in device settings

## 📝 Notes

- Phone hint picker requires user interaction (tap)
- Works best with Google Play Services
- Respects user privacy - requires user selection
- Falls back gracefully if unavailable
- Compatible with all existing validation logic

## ✅ Summary

The phone number autofill feature is now fully implemented and integrated with the existing authentication flow. Users can:

1. ✅ Tap on phone number field
2. ✅ See their saved phone numbers
3. ✅ Select a number automatically
4. ✅ Proceed to OTP verification seamlessly

This enhancement significantly improves the user experience by reducing manual typing and potential errors!
