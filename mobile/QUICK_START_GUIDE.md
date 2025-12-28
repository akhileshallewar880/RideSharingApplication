# Quick Start Guide - API Integration

## 🚀 What's Ready

All the backend integration infrastructure is complete:
- ✅ 6 Services (auth, profile, passenger rides, driver rides, dashboard, vehicle)
- ✅ 6 Riverpod Providers for state management
- ✅ All models and DTOs
- ✅ Dio HTTP client with auto token refresh
- ✅ Error handling and logging

## 📝 How to Use in Your Screens

### 1. Convert Widget to ConsumerWidget

**Before:**
```dart
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ...
}
```

**After:**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Now you have access to 'ref'
}
```

### 2. Watch State in build() Method

```dart
@override
Widget build(BuildContext context) {
  // Watch the auth state
  final authState = ref.watch(authNotifierProvider);
  
  // Use the state
  if (authState.isLoading) {
    return Center(child: CircularProgressIndicator());
  }
  
  if (authState.errorMessage != null) {
    // Show error
    SnackBar(content: Text(authState.errorMessage!));
  }
  
  // Your UI
  return Scaffold(...);
}
```

### 3. Call Provider Methods

```dart
// In your button onPressed or form submission
Future<void> _handleLogin() async {
  final phoneNumber = _phoneController.text;
  
  // Call the provider method
  await ref.read(authNotifierProvider.notifier).sendOtp(phoneNumber);
  
  // Check the result
  final state = ref.read(authNotifierProvider);
  if (state.errorMessage == null) {
    // Success - navigate to OTP screen
    Navigator.pushNamed(context, '/otp', arguments: phoneNumber);
  }
}
```

## 🎯 Example: Update Login Screen

Here's a complete example of updating the login screen:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider.dart';
import '../../../app/widgets/custom_text_field.dart';
import '../../../app/widgets/custom_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  
  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _sendOtp() async {
    final phoneNumber = _phoneController.text.trim();
    
    if (phoneNumber.isEmpty || phoneNumber.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid 10-digit phone number')),
      );
      return;
    }
    
    // Call the auth provider
    await ref.read(authNotifierProvider.notifier).sendOtp(phoneNumber);
    
    // Check result
    final state = ref.read(authNotifierProvider);
    if (state.errorMessage == null) {
      // Success - navigate to OTP screen
      Navigator.pushNamed(context, '/otp', arguments: phoneNumber);
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to Allapalli Ride',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 40),
              
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter your 10-digit phone number',
                keyboardType: TextInputType.phone,
                maxLength: 10,
                enabled: !authState.isLoading,
              ),
              
              SizedBox(height: 24),
              
              CustomButton(
                text: 'Send OTP',
                onPressed: authState.isLoading ? null : _sendOtp,
                isLoading: authState.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## 📚 Common Patterns

### Pattern 1: Load Data on Screen Init
```dart
@override
void initState() {
  super.initState();
  // Load data when screen opens
  Future.microtask(() {
    ref.read(userProfileNotifierProvider.notifier).loadProfile();
  });
}
```

### Pattern 2: Handle Form Submission
```dart
Future<void> _handleSubmit() async {
  final success = await ref.read(passengerRideNotifierProvider.notifier)
    .bookRide(bookingRequest);
  
  if (success) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ride booked successfully!')),
    );
  }
}
```

### Pattern 3: Display List from State
```dart
@override
Widget build(BuildContext context) {
  final rideState = ref.watch(passengerRideNotifierProvider);
  
  if (rideState.isLoading) {
    return Center(child: CircularProgressIndicator());
  }
  
  return ListView.builder(
    itemCount: rideState.availableRides.length,
    itemBuilder: (context, index) {
      final ride = rideState.availableRides[index];
      return RideCard(ride: ride);
    },
  );
}
```

### Pattern 4: Pull to Refresh
```dart
Future<void> _refresh() async {
  await ref.read(passengerRideNotifierProvider.notifier).loadRideHistory();
}

@override
Widget build(BuildContext context) {
  return RefreshIndicator(
    onRefresh: _refresh,
    child: ListView(...),
  );
}
```

## 🔍 Available Providers

Import from `lib/core/providers/`:

1. **authNotifierProvider** - Authentication
2. **userProfileNotifierProvider** - User profile
3. **passengerRideNotifierProvider** - Passenger rides
4. **driverRideNotifierProvider** - Driver rides
5. **driverDashboardNotifierProvider** - Driver dashboard
6. **vehicleNotifierProvider** - Vehicle management

## ⚡ Quick Tips

1. **Always watch in build()**: Use `ref.watch()` in the build method to rebuild on state changes
2. **Read for actions**: Use `ref.read()` in event handlers and methods
3. **Check loading**: Always check `state.isLoading` before making API calls
4. **Handle errors**: Display `state.errorMessage` to users
5. **Clear errors**: Errors persist until the next API call
6. **Dispose controllers**: Don't forget to dispose TextEditingControllers

## 🧪 Testing Your Integration

1. **Start the backend**: Make sure backend is running on `http://localhost:5000`
2. **Test OTP flow**: Login → Send OTP → Verify OTP → Complete Registration
3. **Check network tab**: Use Dio logging to see API requests/responses
4. **Verify token refresh**: Check that 401 errors trigger auto token refresh
5. **Test error handling**: Try with backend offline to see error messages

## 📞 API Methods Available

### Auth Provider
- `sendOtp(phoneNumber)`
- `verifyOtp(phoneNumber, otp)`
- `completeRegistration(request)`
- `logout()`

### Profile Provider
- `loadProfile()`
- `updateProfile(request)`
- `uploadProfilePicture(file)`
- `deleteProfilePicture()`

### Passenger Ride Provider
- `searchRides(request)`
- `bookRide(request)`
- `loadBookingDetails(bookingId)`
- `cancelBooking(bookingId, reason)`
- `loadRideHistory(status, page, pageSize)`
- `rateRide(bookingId, request)`

### Driver Ride Provider
- `scheduleRide(request)`
- `loadActiveRides()`
- `loadRideDetails(rideId)`
- `startTrip(rideId)`
- `verifyPassengerOtp(rideId, bookingId, otp)`
- `completeTrip(rideId)`
- `cancelRide(rideId, reason)`

### Driver Dashboard Provider
- `loadDashboard()`
- `updateOnlineStatus(isOnline)`
- `loadEarnings(startDate, endDate)`
- `loadPayoutHistory(page, pageSize)`
- `requestPayout(amount, method)`

### Vehicle Provider
- `loadVehicle()`
- `updateVehicle(request)`
- `uploadDocument(file, documentType)`
- `deleteDocument(documentType)`

## 🎨 Next Steps

1. Start with authentication screens (highest priority)
2. Move to passenger home screen
3. Update driver dashboard
4. Add remaining screens one by one
5. Test each flow thoroughly
6. Add error handling UI components
7. Polish loading states and animations

## 💡 Need Help?

- Check `API_INTEGRATION_COMPLETE.md` for detailed implementation guide
- See `lib/core/services/` for available API methods
- Look at `lib/core/models/` for request/response structures
- Review `BACKEND_API_SPECIFICATION_Updated.md` for backend API details

---

**Ready to integrate!** Start with the authentication screens and work your way through the app. All the hard work of setting up services and state management is done! 🚀
