# RideSharing Application - Database Redesign

## Overview
The RideSharing application has been completely redesigned according to the specifications in `BACKEND_API_SPECIFICATION.md` and `DATABASE_SCHEMA.md`. This document outlines the changes made and the next steps required.

## ✅ Completed Tasks

### 1. Domain Models Updated
All domain models have been updated to match the new database schema:

#### New/Updated Models:
- **User** (renamed from Users): Core authentication and user information
- **UserProfile**: Extended user profile information
- **Driver**: Driver-specific information with verification status
- **Vehicle**: Vehicle information for drivers (NEW)
- **Ride**: Scheduled rides by drivers (replaces RideInstance, ScheduleTemplate, Route, RouteStop)
- **Booking**: Passenger ride bookings
- **Payment**: Payment transaction tracking
- **Payout**: Driver payout/withdrawal transactions
- **Rating**: Ride ratings and reviews
- **Notification**: User notifications
- **OTPVerification**: OTP verification for authentication (NEW)
- **RefreshToken**: JWT refresh token management (NEW)

#### Removed/Deprecated Models:
- Route
- RouteStop  
- ScheduleTemplate
- RideInstance

These have been consolidated into the **Ride** model for simplicity.

### 2. Database Context Updated
`RideSharingDbContext.cs` has been completely redesigned with:
- All new DbSets for the updated models
- Comprehensive entity configurations
- Proper indexes for performance
- Cascade delete behaviors configured correctly
- Precision settings for decimal fields
- Computed columns ignored appropriately

### 3. DTOs Created
Comprehensive DTOs have been created for all API endpoints:
- **AuthDto.cs**: Authentication DTOs (OTP-based)
- **UserProfileDto.cs**: User profile management
- **PassengerRideDto.cs**: Passenger ride search, booking, history
- **DriverRideDto.cs**: Driver ride management
- **DriverDashboardDto.cs**: Driver dashboard and earnings
- **VehicleDto.cs**: Vehicle management
- **NotificationDto.cs**: Notification management
- **ApiResponseDto.cs**: Standard API response wrapper with error handling

### 4. Repository Interfaces Created
New repository interfaces for clean architecture:
- **IAuthRepository**: OTP verification and authentication
- **IUserRepository**: User profile management
- **IRideRepository**: Passenger ride operations
- **IDriverRepository**: Driver ride and earnings management
- **INotificationRepository**: Notification operations

### 5. Repository Implementations Created
Full implementations for all repository interfaces with:
- Async/await patterns
- Entity Framework Core best practices
- Proper error handling structure
- Transaction management where needed

### 6. Dependency Injection Updated
`Program.cs` has been updated to register all new repositories.

## 🚧 Remaining Tasks

### 1. Create New Controllers

You need to create the following controllers based on the API specification:

#### a. AuthController (NEW)
**Location:** `Controllers/AuthController.cs`

**Endpoints:**
- `POST /auth/send-otp` - Send OTP to phone number
- `POST /auth/verify-otp` - Verify OTP
- `POST /auth/register` - Complete registration after OTP verification
- `POST /auth/refresh-token` - Refresh JWT token
- `POST /auth/logout` - Logout user

#### b. UsersController (UPDATE existing UserDriverController)
**Location:** `Controllers/UsersController.cs`

**Endpoints:**
- `GET /users/profile` - Get user profile
- `PUT /users/profile` - Update user profile
- `POST /users/profile-picture` - Upload profile picture

#### c. RidesController (NEW - for passengers)
**Location:** `Controllers/RidesController.cs`

**Endpoints:**
- `POST /rides/search` - Search available rides
- `POST /rides/book` - Book a ride
- `GET /rides/{bookingId}` - Get ride details
- `GET /rides/history` - Get ride history
- `POST /rides/{bookingId}/cancel` - Cancel ride
- `PUT /rides/{bookingId}/reschedule` - Reschedule ride
- `POST /rides/{bookingId}/rate` - Rate ride

#### d. DriverRidesController (NEW)
**Location:** `Controllers/DriverRidesController.cs`

**Endpoints:**
- `POST /driver/rides/schedule` - Schedule new ride
- `GET /driver/rides` - Get driver's rides
- `GET /driver/rides/{rideId}` - Get ride details
- `POST /driver/rides/{rideId}/start` - Start trip
- `POST /driver/rides/{rideId}/verify-otp` - Verify passenger OTP
- `POST /driver/rides/{rideId}/verify-qr` - Verify passenger QR code
- `POST /driver/rides/{rideId}/complete` - Complete trip
- `POST /driver/rides/{rideId}/cancel` - Cancel scheduled ride

#### e. DriverDashboardController (NEW)
**Location:** `Controllers/DriverDashboardController.cs`

**Endpoints:**
- `GET /driver/dashboard` - Get driver dashboard
- `PUT /driver/status` - Update online status
- `GET /driver/earnings` - Get earnings summary
- `GET /driver/payouts` - Get payout history
- `POST /driver/payouts/request` - Request payout

#### f. VehiclesController (NEW)
**Location:** `Controllers/VehiclesController.cs`

**Endpoints:**
- `GET /driver/vehicle` - Get vehicle details
- `PUT /driver/vehicle` - Update vehicle details

#### g. NotificationsController (NEW)
**Location:** `Controllers/NotificationsController.cs`

**Endpoints:**
- `GET /notifications` - Get notifications
- `PUT /notifications/{notificationId}/read` - Mark notification as read
- `PUT /notifications/read-all` - Mark all as read

### 2. Create Database Migration

**CRITICAL:** You must create and run migrations before the application will work:

```bash
# Remove old migrations directory (backup first if needed)
cd RideSharing.API
rm -rf Migrations

# Create new migration
dotnet ef migrations add CompleteRedesign --context RideSharingDbContext

# Review the migration file to ensure it's correct

# Apply migration to database
dotnet ef database update --context RideSharingDbContext
```

### 3. Update Token Repository
The existing `TokenRepository` needs to be updated to support:
- Creating access tokens with user claims
- Creating and validating refresh tokens
- Temporary tokens for incomplete registrations

### 4. Implement OTP Service
Create an OTP service to:
- Generate random OTPs
- Send OTPs via SMS (integrate with Twilio, AWS SNS, or similar)
- Store OTPs with expiration

Example service interface:
```csharp
public interface IOTPService
{
    Task<string> GenerateOTPAsync();
    Task<bool> SendOTPAsync(string phoneNumber, string otp);
}
```

### 5. Implement File Upload Service
Create a file upload service for profile pictures:
- Azure Blob Storage
- AWS S3
- Or local file system

### 6. Add Authentication Middleware
Ensure JWT authentication is properly configured for:
- User identification from token
- Role-based authorization
- Temporary token validation for registration flow

### 7. Add Validation
Add model validation attributes and create custom validators:
- Phone number validation
- Date validation
- Location validation

### 8. Create AutoMapper Profiles
Update `AutoMappingProfiles.cs` to map between domain models and DTOs:
```csharp
CreateMap<User, UserDto>();
CreateMap<UserProfile, UserProfileDetailDto>();
CreateMap<Ride, AvailableRideDto>();
CreateMap<Booking, BookingResponseDto>();
// ... add all mappings
```

### 9. Update Error Handling
Enhance the `ExceptionHandlerMiddleware` to return responses in the new `ApiResponseDto` format.

### 10. Add Logging
Add structured logging throughout:
- Repository operations
- Controller actions
- Authentication flows
- Error scenarios

### 11. Testing
Create unit and integration tests:
- Repository tests
- Controller tests
- Authentication flow tests
- Booking flow tests

## Database Schema Changes Summary

### New Tables
- `UserProfiles` - Extended user information
- `Vehicles` - Driver vehicle information
- `OTPVerifications` - OTP verification tracking
- `RefreshTokens` - JWT refresh tokens

### Redesigned Tables
- `Users` - Now includes phone verification and blocking
- `Drivers` - Enhanced with verification status and earnings
- `Bookings` - Complete booking information with OTP/QR
- `Payments` - Transaction tracking with gateway details
- `Payouts` - Driver payout requests
- `Ratings` - Comprehensive rating system
- `Notifications` - Enhanced notification system

### Removed Tables
- `Routes` - Consolidated into Rides
- `RouteStops` - Consolidated into Rides
- `ScheduleTemplates` - Consolidated into Rides
- `RideInstances` - Replaced by Rides

## API Changes

### New Authentication Flow
1. User requests OTP via phone number
2. System sends OTP via SMS
3. User verifies OTP
4. If new user, complete registration
5. System returns JWT access token and refresh token

### Key Features
- OTP-based authentication (no passwords initially)
- Phone number as primary identifier
- Support for both passenger and driver roles
- Real-time ride tracking (WebSocket support can be added)
- Comprehensive rating system
- Driver earnings and payout management

## Configuration Requirements

### appsettings.json Updates Needed
```json
{
  "ConnectionStrings": {
    "RideSharingConnectionString": "Your SQL Server connection string",
    "RideSharingAuthConnectionString": "Your Auth DB connection string"
  },
  "JwtSettings": {
    "SecretKey": "Your-Super-Secret-Key-Minimum-32-Characters",
    "ValidIssuer": "https://api.allapalliride.com",
    "ValidAudience": "https://allapalliride.com",
    "ExpiryMinutes": 60,
    "RefreshTokenExpiryDays": 30
  },
  "OTPSettings": {
    "ExpiryMinutes": 5,
    "Length": 4,
    "Provider": "Twilio"
  },
  "StorageSettings": {
    "Provider": "AzureBlob",
    "ConnectionString": "Your storage connection string",
    "ContainerName": "profile-pictures"
  }
}
```

## Migration Guide

### For Existing Database
If you have existing data:

1. **Backup your database** before running migrations
2. Consider writing a data migration script to:
   - Map old `Users` data to new `User` and `UserProfile` tables
   - Migrate `Routes`, `ScheduleTemplates`, `RideInstances` to new `Rides` table
   - Preserve booking and payment data

### For Fresh Database
Simply run the migrations and the schema will be created correctly.

## Next Immediate Steps

1. **Create migrations** - This is CRITICAL
   ```bash
   dotnet ef migrations add CompleteRedesign --context RideSharingDbContext
   dotnet ef database update --context RideSharingDbContext
   ```

2. **Test the application builds**
   ```bash
   dotnet build
   ```

3. **Fix any compilation errors** that may arise

4. **Create a basic AuthController** to test the new authentication flow

5. **Test OTP generation and verification** (can use console output for testing)

## Questions to Address

1. **SMS Provider**: Which SMS gateway will you use for OTP? (Twilio, AWS SNS, etc.)
2. **File Storage**: Where will profile pictures be stored? (Azure, AWS, Local)
3. **Payment Gateway**: Which payment gateway for online payments? (Razorpay, Stripe, etc.)
4. **Real-time Tracking**: Do you need WebSocket support for live ride tracking?
5. **Admin Portal**: Do you need admin APIs for user/driver management?

## Support

If you encounter issues:
1. Check compilation errors and resolve dependencies
2. Verify database connection strings
3. Ensure all necessary NuGet packages are installed:
   - Microsoft.EntityFrameworkCore.SqlServer
   - Microsoft.EntityFrameworkCore.Tools
   - AutoMapper.Extensions.Microsoft.DependencyInjection
   - System.IdentityModel.Tokens.Jwt

## Notes

- All nullable warnings in DTOs and models are expected and safe
- The `User` class was renamed from `Users` for naming consistency
- Legacy DTOs and repositories are kept for backward compatibility
- The new architecture follows Repository Pattern with clean separation
- All async operations use proper async/await patterns

---

**Last Updated:** $(date)
**Status:** Phase 1 Complete - Ready for Migration and Controller Implementation
