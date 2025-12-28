# RideSharing Application - Backend API Specification

## Base URLs
- **Development:** `http://localhost:5000`
- **Production:** `https://api.allapalliride.com`

## API Prefix
All endpoints are prefixed with `/api/v1`

## Response Format
All API responses follow this standard structure:

**Success Response:**
```json
{
  "success": true,
  "message": "Operation description",
  "data": { /* response data */ }
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Error description",
  "data": null,
  "errors": ["Validation error 1", "Validation error 2"]
}
```

---

## 1. Authentication APIs

### 1.1 Send OTP
**Endpoint:** `POST /api/v1/auth/send-otp`

**Description:** Initiates OTP-based authentication by sending a one-time password to the provided phone number

**Request:**
```json
{
  "phoneNumber": "+919812345678"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "OTP sent successfully to +919812345678",
  "data": {
    "phoneNumber": "+919812345678",
    "expiresAt": "2025-11-09T19:05:00Z"
  }
}
```

**Error Response (400 Bad Request):**
```json
{
  "success": false,
  "message": "Invalid phone number format",
  "data": null,
  "errors": ["Phone number must start with + and country code"]
}
```

---

### 1.2 Verify OTP
**Endpoint:** `POST /api/v1/auth/verify-otp`

**Description:** Verifies the OTP and returns authentication tokens for existing users or a temporary token for new users

**Request:**
```json
{
  "phoneNumber": "+919812345678",
  "otp": "1234"
}
```

**Response (200 OK) - Existing User:**
```json
{
  "success": true,
  "message": "OTP verified successfully",
  "data": {
    "isNewUser": false,
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tokenType": "Bearer",
    "expiresIn": 3600,
    "user": {
      "userId": "550e8400-e29b-41d4-a716-446655440000",
      "phoneNumber": "+919812345678",
      "name": "Akhilesh Allewar",
      "email": "akhilesh@example.com",
      "userType": "passenger"
    }
  }
}
```

**Response (200 OK) - New User:**
```json
{
  "success": true,
  "message": "OTP verified. Please complete registration",
  "data": {
    "isNewUser": true,
    "tempToken": "temp_eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "phoneNumber": "+919812345678"
  }
}
```

**Error Response (401 Unauthorized):**
```json
{
  "success": false,
  "message": "Invalid or expired OTP",
  "data": null
}
```

---

### 1.3 Complete Registration
**Endpoint:** `POST /api/v1/auth/complete-registration`

**Description:** Completes registration for new users after OTP verification

**Headers:** 
```
Authorization: Bearer {tempToken}
```

**Request:**
```json
{
  "name": "Akhilesh Allewar",
  "email": "akhilesh@example.com",
  "userType": "passenger",
  "dateOfBirth": "1995-05-15",
  "emergencyContact": "+919876543210"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Registration completed successfully",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tokenType": "Bearer",
    "expiresIn": 3600,
    "user": {
      "userId": "550e8400-e29b-41d4-a716-446655440000",
      "phoneNumber": "+919812345678",
      "name": "Akhilesh Allewar",
      "email": "akhilesh@example.com",
      "userType": "passenger"
    }
  }
}
```

---

### 1.4 Refresh Token
**Endpoint:** `POST /api/v1/auth/refresh-token`

**Description:** Refreshes expired access token using refresh token

**Request:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Token refreshed successfully",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tokenType": "Bearer",
    "expiresIn": 3600
  }
}
```

---

### 1.5 Logout
**Endpoint:** `POST /api/v1/auth/logout`

**Description:** Invalidates the current refresh token

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Request:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Logged out successfully",
  "data": null
}
```

---

## 2. User Profile APIs

### 2.1 Get User Profile
**Endpoint:** `GET /api/v1/users/profile`

**Description:** Get current user's profile information

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Profile retrieved successfully",
  "data": {
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "phoneNumber": "+919812345678",
    "name": "Akhilesh Allewar",
    "email": "akhilesh@example.com",
    "profilePicture": "https://yourdomain.com/uploads/profiles/image.jpg",
    "dateOfBirth": "1995-05-15",
    "emergencyContact": "+919876543210",
    "rating": 4.5,
    "totalRides": 25,
    "createdAt": "2025-01-01T00:00:00Z"
  }
}
```

---

### 2.2 Update User Profile
**Endpoint:** `PUT /api/v1/users/profile`

**Description:** Update user profile information

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Request:**
```json
{
  "name": "Akhilesh Allewar Updated",
  "email": "newemail@example.com",
  "dateOfBirth": "1995-05-15",
  "emergencyContact": "+919876543210"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Akhilesh Allewar Updated",
    "email": "newemail@example.com",
    "updatedAt": "2025-11-09T19:00:00Z"
  }
}
```

---

### 2.3 Upload Profile Picture
**Endpoint:** `POST /api/v1/users/profile/picture`

**Description:** Upload or update profile picture

**Headers:** 
```
Authorization: Bearer {accessToken}
Content-Type: multipart/form-data
```

**Request (Form Data):**
```
file: [image file] (Max 5MB, JPEG/PNG/WebP)
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Profile picture uploaded successfully",
  "data": {
    "profilePictureUrl": "https://yourdomain.com/uploads/profiles/550e8400-e29b-41d4-a716.jpg"
  }
}
```

---

### 2.4 Delete Profile Picture
**Endpoint:** `DELETE /api/v1/users/profile/picture`

**Description:** Remove profile picture

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Profile picture deleted successfully",
  "data": null
}
```

---

## 3. Passenger Ride APIs

### 3.1 Search Available Rides
**Endpoint:** `POST /api/v1/rides/search`

**Description:** Search for available rides based on criteria

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Request:**
```json
{
  "pickupLocation": "Allapalli Bus Stand",
  "dropoffLocation": "Gadchiroli Railway Station",
  "travelDate": "2025-11-10",
  "passengerCount": 2,
  "vehicleType": "car"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Rides found",
  "data": {
    "availableRides": [
      {
        "rideId": "650e8400-e29b-41d4-a716-446655440000",
        "driverName": "John Driver",
        "driverRating": 4.8,
        "phoneNumber": "+919812345678",
        "vehicleType": "car",
        "vehicleModel": "Honda City",
        "vehicleNumber": "MH31AB1234",
        "pickupLocation": "Allapalli Bus Stand",
        "dropoffLocation": "Gadchiroli Railway Station",
        "departureTime": "2025-11-10 08:00",
        "pricePerSeat": 150.00,
        "availableSeats": 3,
        "totalSeats": 4,
        "estimatedDuration": "01:30"
      }
    ]
  }
}
```

---

### 3.2 Book a Ride
**Endpoint:** `POST /api/v1/rides/book`

**Description:** Book a ride for passenger

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Request:**
```json
{
  "rideId": "650e8400-e29b-41d4-a716-446655440000",
  "passengerCount": 2,
  "pickupLocation": {
    "address": "Allapalli Bus Stand",
    "latitude": 19.8735,
    "longitude": 80.1707
  },
  "dropoffLocation": {
    "address": "Gadchiroli Railway Station",
    "latitude": 20.1809,
    "longitude": 80.0050
  },
  "paymentMethod": "cash"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Ride booked successfully",
  "data": {
    "bookingNumber": "BK20251109001",
    "status": "confirmed",
    "otp": "5678",
    "rideId": "650e8400-e29b-41d4-a716-446655440000",
    "pickupLocation": "Allapalli Bus Stand",
    "dropoffLocation": "Gadchiroli Railway Station",
    "departureTime": "2025-11-10 08:00",
    "passengerCount": 2,
    "totalFare": 300.00,
    "paymentMethod": "cash",
    "paymentStatus": "pending",
    "driverDetails": {
      "name": "John Driver",
      "phoneNumber": "+919812345678",
      "rating": 4.8,
      "vehicleModel": "Honda City",
      "vehicleNumber": "MH31AB1234"
    },
    "bookedAt": "2025-11-09T19:00:00Z"
  }
}
```

---

### 3.3 Get Booking Details
**Endpoint:** `GET /api/v1/rides/bookings/{bookingId}`

**Description:** Get specific booking details

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Booking details retrieved",
  "data": {
    "bookingNumber": "BK20251109001",
    "status": "confirmed",
    "otp": "5678",
    "rideId": "650e8400-e29b-41d4-a716-446655440000",
    "pickupLocation": "Allapalli Bus Stand",
    "dropoffLocation": "Gadchiroli Railway Station",
    "departureTime": "2025-11-10 08:00",
    "passengerCount": 2,
    "totalFare": 300.00,
    "paymentStatus": "pending",
    "driverDetails": {
      "name": "John Driver",
      "phoneNumber": "+919812345678",
      "rating": 4.8,
      "vehicleModel": "Honda City",
      "vehicleNumber": "MH31AB1234"
    }
  }
}
```

---

### 3.4 Cancel Booking
**Endpoint:** `POST /api/v1/rides/bookings/{bookingId}/cancel`

**Description:** Cancel a booking

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Request:**
```json
{
  "reason": "Change of plans",
  "cancellationType": "passenger"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Booking cancelled successfully",
  "data": {
    "bookingId": "750e8400-e29b-41d4-a716-446655440000",
    "status": "cancelled",
    "refundAmount": 270.00,
    "cancellationCharge": 30.00,
    "cancelledAt": "2025-11-09T19:00:00Z"
  }
}
```

---

### 3.5 Get Ride History
**Endpoint:** `GET /api/v1/rides/history`

**Description:** Get passenger's ride history

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Query Parameters:**
```
?status=completed&page=1&pageSize=10
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Ride history retrieved",
  "data": {
    "rides": [
      {
        "bookingNumber": "BK20251109001",
        "pickupLocation": "Allapalli Bus Stand",
        "dropoffLocation": "Gadchiroli Railway Station",
        "travelDate": "2025-11-10",
        "timeSlot": "08:00",
        "vehicleType": "car",
        "totalFare": 300.00,
        "status": "completed",
        "rating": 5
      }
    ],
    "pagination": {
      "currentPage": 1,
      "itemsPerPage": 10,
      "totalItems": 25,
      "totalPages": 3
    }
  }
}
```

---

### 3.6 Rate Ride
**Endpoint:** `POST /api/v1/rides/bookings/{bookingId}/rate`

**Description:** Rate completed ride and driver

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Request:**
```json
{
  "rating": 5,
  "comment": "Excellent ride, driver was very professional"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Rating submitted successfully",
  "data": {
    "ratingId": "850e8400-e29b-41d4-a716-446655440000",
    "rating": 5,
    "submittedAt": "2025-11-09T19:00:00Z"
  }
}
```

---

## 4. Driver Ride Management APIs

### 4.1 Schedule a Ride
**Endpoint:** `POST /api/v1/driver/rides/schedule`

**Description:** Schedule a new ride as driver

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Request:**
```json
{
  "pickupLocation": "Allapalli Bus Stand",
  "dropoffLocation": "Gadchiroli Railway Station",
  "departureTime": "2025-11-10T08:00:00",
  "totalSeats": 4,
  "pricePerSeat": 150.00,
  "vehicleType": "car"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Ride scheduled successfully",
  "data": {
    "rideId": "950e8400-e29b-41d4-a716-446655440000",
    "rideNumber": "RD20251109001",
    "departureTime": "2025-11-10T08:00:00",
    "status": "scheduled",
    "createdAt": "2025-11-09T19:00:00Z"
  }
}
```

---

### 4.2 Get Active Rides
**Endpoint:** `GET /api/v1/driver/rides/active`

**Description:** Get driver's active/scheduled rides

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Active rides retrieved",
  "data": {
    "rides": [
      {
        "rideId": "950e8400-e29b-41d4-a716-446655440000",
        "rideNumber": "RD20251109001",
        "pickupLocation": "Allapalli Bus Stand",
        "dropoffLocation": "Gadchiroli Railway Station",
        "departureTime": "2025-11-10T08:00:00",
        "totalSeats": 4,
        "bookedSeats": 2,
        "availableSeats": 2,
        "pricePerSeat": 150.00,
        "estimatedEarnings": 300.00,
        "status": "scheduled"
      }
    ]
  }
}
```

---

### 4.3 Get Ride Details with Passengers
**Endpoint:** `GET /api/v1/driver/rides/{rideId}`

**Description:** Get detailed ride info including passenger list

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Ride details retrieved",
  "data": {
    "rideId": "950e8400-e29b-41d4-a716-446655440000",
    "rideNumber": "RD20251109001",
    "pickupLocation": "Allapalli Bus Stand",
    "dropoffLocation": "Gadchiroli Railway Station",
    "departureTime": "2025-11-10T08:00:00",
    "status": "in_progress",
    "totalSeats": 4,
    "bookedSeats": 2,
    "passengers": [
      {
        "bookingId": "750e8400-e29b-41d4-a716-446655440000",
        "passengerName": "Akhilesh Allewar",
        "phoneNumber": "+919812345678",
        "passengerCount": 2,
        "pickupLocation": "Allapalli Bus Stand",
        "dropoffLocation": "Gadchiroli Railway Station",
        "otp": "5678",
        "paymentStatus": "pending",
        "boardingStatus": "not_boarded"
      }
    ]
  }
}
```

---

### 4.4 Start Trip
**Endpoint:** `POST /api/v1/driver/rides/{rideId}/start`

**Description:** Start the ride/trip

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Trip started successfully",
  "data": {
    "rideId": "950e8400-e29b-41d4-a716-446655440000",
    "status": "in_progress",
    "startedAt": "2025-11-10T08:00:00Z"
  }
}
```

---

### 4.5 Verify Passenger OTP
**Endpoint:** `POST /api/v1/driver/rides/{rideId}/verify-otp`

**Description:** Verify passenger boarding with OTP

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Request:**
```json
{
  "otp": "5678"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Passenger verified successfully",
  "data": {
    "bookingId": "750e8400-e29b-41d4-a716-446655440000",
    "passengerName": "Akhilesh Allewar",
    "boardingStatus": "boarded",
    "verifiedAt": "2025-11-10T08:05:00Z"
  }
}
```

---

### 4.6 Complete Trip
**Endpoint:** `POST /api/v1/driver/rides/{rideId}/complete`

**Description:** Mark trip as completed

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Trip completed successfully",
  "data": {
    "rideId": "950e8400-e29b-41d4-a716-446655440000",
    "status": "completed",
    "totalEarnings": 300.00,
    "completedAt": "2025-11-10T09:30:00Z"
  }
}
```

---

### 4.7 Cancel Ride
**Endpoint:** `POST /api/v1/driver/rides/{rideId}/cancel`

**Description:** Cancel scheduled ride

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Request:**
```json
{
  "reason": "Vehicle breakdown"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Ride cancelled successfully",
  "data": {
    "rideId": "950e8400-e29b-41d4-a716-446655440000",
    "status": "cancelled",
    "cancelledAt": "2025-11-09T19:00:00Z"
  }
}
```

---

## 5. Driver Dashboard APIs

### 5.1 Get Dashboard
**Endpoint:** `GET /api/v1/driver/dashboard`

**Description:** Get driver dashboard summary

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Dashboard data retrieved",
  "data": {
    "driver": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "John Driver",
      "rating": 4.8,
      "totalRides": 150,
      "isOnline": true
    },
    "todayStats": {
      "totalRides": 5,
      "totalEarnings": 1500.00,
      "onlineHours": 8.5
    },
    "pendingEarnings": 1200.00,
    "availableForWithdrawal": 5000.00
  }
}
```

---

### 5.2 Get Earnings
**Endpoint:** `GET /api/v1/driver/earnings`

**Description:** Get detailed earnings breakdown

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Query Parameters:**
```
?startDate=2025-11-01&endDate=2025-11-09
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Earnings retrieved",
  "data": {
    "summary": {
      "totalEarnings": 15000.00,
      "totalRides": 50,
      "averageEarningsPerRide": 300.00,
      "totalDistance": 500.0,
      "onlineHours": 100.5
    },
    "breakdown": {
      "cashCollected": 8000.00,
      "onlinePayments": 7000.00,
      "commission": 1500.00,
      "netEarnings": 13500.00
    },
    "chartData": []
  }
}
```

---

### 5.3 Get Payout History
**Endpoint:** `GET /api/v1/driver/payouts`

**Description:** Get payout history

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Query Parameters:**
```
?page=1&pageSize=10
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Payout history retrieved",
  "data": {
    "payouts": [
      {
        "payoutId": "a50e8400-e29b-41d4-a716-446655440000",
        "amount": 5000.00,
        "status": "completed",
        "method": "bank_transfer",
        "requestedAt": "2025-11-01T00:00:00Z",
        "completedAt": "2025-11-02T00:00:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "itemsPerPage": 10,
      "totalItems": 5,
      "totalPages": 1
    }
  }
}
```

---

### 5.4 Request Payout
**Endpoint:** `POST /api/v1/driver/payouts/request`

**Description:** Request withdrawal of available earnings

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Request:**
```json
{
  "amount": 5000.00,
  "method": "bank_transfer"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Payout request submitted successfully",
  "data": {
    "payoutId": "b50e8400-e29b-41d4-a716-446655440000",
    "amount": 5000.00,
    "status": "pending",
    "requestedAt": "2025-11-09T19:00:00Z"
  }
}
```

---

### 5.5 Update Online Status
**Endpoint:** `PUT /api/v1/driver/status`

**Description:** Update driver online/offline status

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Request:**
```json
{
  "isOnline": true
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Status updated successfully",
  "data": {
    "isOnline": true,
    "updatedAt": "2025-11-09T19:00:00Z"
  }
}
```

---

## 6. Vehicle Management APIs

### 6.1 Get Vehicle Details
**Endpoint:** `GET /api/v1/driver/vehicles`

**Description:** Get driver's vehicle information

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Vehicle details retrieved",
  "data": {
    "vehicleId": "c50e8400-e29b-41d4-a716-446655440000",
    "vehicleType": "car",
    "make": "Honda",
    "model": "City",
    "year": 2020,
    "registrationNumber": "MH31AB1234",
    "color": "Silver",
    "totalSeats": 4,
    "fuelType": "Petrol",
    "features": ["AC", "Music System"],
    "documents": {
      "registration": {
        "verified": true,
        "expiryDate": "2026-12-31"
      },
      "insurance": {
        "verified": true,
        "expiryDate": "2026-06-30"
      },
      "permit": {
        "verified": true,
        "expiryDate": "2026-12-31"
      }
    }
  }
}
```

---

### 6.2 Update Vehicle
**Endpoint:** `PUT /api/v1/driver/vehicles`

**Description:** Update vehicle information

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Request:**
```json
{
  "color": "Black",
  "features": ["AC", "Music System", "GPS"]
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Vehicle updated successfully",
  "data": {
    "vehicleId": "c50e8400-e29b-41d4-a716-446655440000",
    "updatedAt": "2025-11-09T19:00:00Z"
  }
}
```

---

### 6.3 Upload Vehicle Documents
**Endpoint:** `POST /api/v1/driver/vehicles/documents`

**Description:** Upload vehicle documents

**Headers:** 
```
Authorization: Bearer {accessToken}
Content-Type: multipart/form-data
```

**Request (Form Data):**
```
file: [document file] (Max 10MB, JPEG/PNG/PDF)
documentType: registration|insurance|permit
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Document uploaded successfully. Verification pending",
  "data": {
    "documentUrl": "https://yourdomain.com/uploads/vehicles/doc.pdf",
    "documentType": "registration",
    "uploadedAt": "2025-11-09T19:00:00Z"
  }
}
```

---

### 6.4 Toggle Vehicle Status
**Endpoint:** `PUT /api/v1/driver/vehicles/status`

**Description:** Activate/deactivate vehicle

**Headers:** 
```
Authorization: Bearer {accessToken}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Vehicle status updated successfully",
  "data": {
    "vehicleId": "c50e8400-e29b-41d4-a716-446655440000",
    "isActive": false,
    "updatedAt": "2025-11-09T19:00:00Z"
  }
}
```

---

## Error Codes

| Status Code | Description |
|-------------|-------------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request - Invalid input |
| 401 | Unauthorized - Invalid or missing token |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource doesn't exist |
| 409 | Conflict - Resource already exists |
| 422 | Unprocessable Entity - Validation failed |
| 500 | Internal Server Error |

## Common Error Response Format
```json
{
  "success": false,
  "message": "Error description",
  "data": null,
  "errors": [
    "Field 'phoneNumber' is required",
    "Invalid date format"
  ],
  "timestamp": "2025-11-09T19:00:00Z"
}
```

---

## Notes for Flutter Integration

### 1. **Base URL Configuration**
```dart
const String baseUrl = 'http://localhost:5000/api/v1';
```

### 2. **Authentication Header**
```dart
headers: {
  'Authorization': 'Bearer $accessToken',
  'Content-Type': 'application/json',
}
```

### 3. **File Upload (Multipart)**
```dart
var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/users/profile/picture'));
request.headers['Authorization'] = 'Bearer $accessToken';
request.files.add(await http.MultipartFile.fromPath('file', filePath));
```

### 4. **Token Management**
- Store `accessToken` and `refreshToken` securely using `flutter_secure_storage`
- Implement automatic token refresh when receiving 401 errors
- Clear tokens on logout

### 5. **Date/Time Format**
- All dates are in ISO 8601 format: `2025-11-09T19:00:00Z`
- Convert to local time in Flutter app as needed

### 6. **Error Handling**
```dart
if (response.statusCode == 200) {
  final data = jsonDecode(response.body);
  if (data['success']) {
    // Handle success
  } else {
    // Handle API error
  }
} else {
  // Handle HTTP error
}
```

### 7. **OTP Flow**
1. Call `/auth/send-otp`
2. User enters OTP
3. Call `/auth/verify-otp`
4. If `isNewUser == true`, call `/auth/complete-registration`
5. Store tokens

### 8. **Image URLs**
- Profile pictures and documents return relative URLs
- Prepend base domain to display images
- Handle null values for missing images

---

## API Testing with Swagger
Access Swagger UI at: `http://localhost:5000/swagger`

All endpoints are documented and can be tested directly from Swagger interface.
