# Backend API Specification - RideSharing Application

## Base URL
```
Development: http://localhost:5000
Production: https://your-domain.com
```

## API Prefix
All APIs are prefixed with `/api/v1`

## Authentication
All authenticated endpoints require JWT token in header:
```
Authorization: Bearer {access_token}
```

## Response Format
All responses follow this structure:
```json
{
  "success": true,
  "message": "Success message",
  "data": { ... },
  "errors": null,
  "timestamp": "2025-11-09T19:00:00Z"
}
```

---

## 1. Authentication APIs

### 1.1 Send OTP
**Endpoint:** `POST /api/v1/auth/send-otp`

**Description:** Send OTP to phone number for authentication

**Request:**
```json
{
  "phoneNumber": "+919812345678",
  "purpose": "login"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "OTP sent successfully",
  "data": {
    "otpId": "550e8400-e29b-41d4-a716-446655440000",
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
  "errors": ["Phone number must include country code"]
}
```

---

### 1.2 Verify OTP
**Endpoint:** `POST /api/v1/auth/verify-otp`

**Description:** Verify OTP and return tokens for existing users or temp token for new users

**Request:**
```json
{
  "phoneNumber": "+919812345678",
  "otp": "1234",
  "otpId": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response - New User (200 OK):**
```json
{
  "success": true,
  "message": "OTP verified. Please complete registration",
  "data": {
    "isNewUser": true,
    "tempToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Response - Existing User (200 OK):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "isNewUser": false,
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tokenType": "Bearer",
    "expiresIn": 3600
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

**Description:** Complete user registration after OTP verification

**Headers:** 
```
Authorization: Bearer {tempToken}
```

**Request:**
```json
{
  "name": "Akhilesh Allewar",
  "email": "akhilesh@example.com",
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
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tokenType": "Bearer",
    "expiresIn": 3600
  }
}
```

---

### 1.4 Refresh Token
**Endpoint:** `POST /api/v1/auth/refresh-token`

**Description:** Get new access token using refresh token

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
    "tokenType": "Bearer",
    "expiresIn": 3600
  }
}
```

---

### 1.5 Logout
**Endpoint:** `POST /api/v1/auth/logout`

**Description:** Invalidate refresh token

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

**Description:** Get current user's profile

**Headers:** 
```
Authorization: Bearer {accessToken}
}
```

### 1.4 Refresh Token
**Endpoint:** `POST /auth/refresh-token`

**Request:**
```json
{
  "refreshToken": "jwt_refresh_token"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "accessToken": "new_jwt_access_token",
    "refreshToken": "new_jwt_refresh_token"
  }
}
```

### 1.5 Logout
**Endpoint:** `POST /auth/logout`

**Headers:** `Authorization: Bearer {accessToken}`

**Response:**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

## 2. User Profile APIs

### 2.1 Get User Profile
**Endpoint:** `GET /users/profile`

**Headers:** `Authorization: Bearer {accessToken}`

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "Akhilesh Allewar",
    "phoneNumber": "+919812345678",
    "email": "akhilesh@example.com",
    "userType": "passenger",
    "dateOfBirth": "1995-05-15",
    "address": "123 Main St, Allapalli",
    "emergencyContact": "+919876543210",
    "profilePicture": "https://cdn.example.com/profile.jpg",
    "isVerified": true,
    "rating": 4.8,
    "totalRides": 24,
    "createdAt": "2025-01-15T10:00:00Z"
  }
}
```

### 2.2 Update User Profile
**Endpoint:** `PUT /users/profile`

**Headers:** `Authorization: Bearer {accessToken}`

**Request:**
```json
{
  "name": "Akhilesh Allewar",
  "email": "newemail@example.com",
  "dateOfBirth": "1995-05-15",
  "address": "New Address, Allapalli",
  "emergencyContact": "+919876543210"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "id": "uuid",
    "name": "Akhilesh Allewar",
    "email": "newemail@example.com",
    "updatedAt": "2025-11-09T10:00:00Z"
  }
}
```

### 2.3 Upload Profile Picture
**Endpoint:** `POST /users/profile-picture`

**Headers:** 
- `Authorization: Bearer {accessToken}`
- `Content-Type: multipart/form-data`

**Request:** Form-data with file upload

**Response:**
```json
{
  "success": true,
  "message": "Profile picture uploaded",
  "data": {
    "profilePicture": "https://cdn.example.com/profile_new.jpg"
  }
}
```

---

## 3. Passenger Ride APIs

### 3.1 Search Available Rides
**Endpoint:** `POST /rides/search`

**Headers:** `Authorization: Bearer {accessToken}`

**Request:**
```json
{
  "pickupLocation": {
    "address": "Allapalli",
    "latitude": 19.9876,
    "longitude": 79.8765
  },
  "dropoffLocation": {
    "address": "Chandrapur",
    "latitude": 19.9506,
    "longitude": 79.2961
  },
  "travelDate": "2025-11-12",
  "passengerCount": 4,
  "vehicleType": "shared_van"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "availableRides": [
      {
        "rideId": "uuid",
        "driverId": "uuid",
        "driverName": "Rajesh Kumar",
        "driverRating": 4.8,
        "vehicleType": "shared_van",
        "vehicleModel": "Toyota Innova Crysta",
        "vehicleNumber": "MH 34 AB 1234",
        "totalSeats": 7,
        "availableSeats": 3,
        "departureTime": "06:00 AM",
        "pricePerSeat": 850,
        "totalPrice": 3400,
        "estimatedDuration": "2 hours",
        "distance": 65.5
      }
    ]
  }
}
```

### 3.2 Book Ride
**Endpoint:** `POST /rides/book`

**Headers:** `Authorization: Bearer {accessToken}`

**Request:**
```json
{
  "rideId": "uuid",
  "passengerCount": 4,
  "pickupLocation": {
    "address": "Allapalli",
    "latitude": 19.9876,
    "longitude": 79.8765
  },
  "dropoffLocation": {
    "address": "Chandrapur",
    "latitude": 19.9506,
    "longitude": 79.2961
  },
  "paymentMethod": "cash"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Ride booked successfully",
  "data": {
    "bookingId": "uuid",
    "rideId": "uuid",
    "bookingNumber": "ALR2401234",
    "status": "confirmed",
    "otp": "1234",
    "qrCode": "data:image/png;base64...",
    "pickupLocation": "Allapalli",
    "dropoffLocation": "Chandrapur",
    "travelDate": "2025-11-12",
    "departureTime": "06:00 AM",
    "passengerCount": 4,
    "totalFare": 3400,
    "driverDetails": {
      "name": "Rajesh Kumar",
      "phoneNumber": "+919876543210",
      "rating": 4.8,
      "vehicleModel": "Toyota Innova Crysta",
      "vehicleNumber": "MH 34 AB 1234"
    },
    "createdAt": "2025-11-09T10:00:00Z"
  }
}
```

### 3.3 Get Ride Details
**Endpoint:** `GET /rides/{bookingId}`

**Headers:** `Authorization: Bearer {accessToken}`

**Response:**
```json
{
  "success": true,
  "data": {
    "bookingId": "uuid",
    "bookingNumber": "ALR2401234",
    "status": "confirmed",
    "otp": "1234",
    "qrCode": "data:image/png;base64...",
    "pickupLocation": "Allapalli",
    "dropoffLocation": "Chandrapur",
    "travelDate": "2025-11-12",
    "departureTime": "06:00 AM",
    "passengerCount": 4,
    "totalFare": 3400,
    "paymentStatus": "pending",
    "driverDetails": {
      "id": "uuid",
      "name": "Rajesh Kumar",
      "phoneNumber": "+919876543210",
      "rating": 4.8,
      "vehicleModel": "Toyota Innova Crysta",
      "vehicleNumber": "MH 34 AB 1234",
      "profilePicture": "https://cdn.example.com/driver.jpg"
    },
    "trackingStatus": {
      "currentStatus": "waiting",
      "estimatedArrival": "06:00 AM",
      "driverLocation": {
        "latitude": 19.9876,
        "longitude": 79.8765
      }
    },
    "createdAt": "2025-11-09T10:00:00Z"
  }
}
```

### 3.4 Get Ride History
**Endpoint:** `GET /rides/history`

**Headers:** `Authorization: Bearer {accessToken}`

**Query Parameters:**
- `status` (optional): `all`, `completed`, `upcoming`, `cancelled`
- `page` (optional): page number (default: 1)
- `limit` (optional): items per page (default: 20)

**Response:**
```json
{
  "success": true,
  "data": {
    "rides": [
      {
        "bookingId": "uuid",
        "bookingNumber": "ALR2401234",
        "pickupLocation": "Allapalli",
        "dropoffLocation": "Chandrapur",
        "date": "2025-11-05",
        "timeSlot": "6:00 AM - 7:00 AM",
        "vehicleType": "shared_van",
        "vehicleModel": "Toyota Innova Crysta",
        "vehicleNumber": "MH 34 AB 1234",
        "fare": 850,
        "status": "completed",
        "passengerCount": 4,
        "driverName": "Rajesh Kumar",
        "driverRating": 4.8,
        "otp": "1234",
        "completedAt": "2025-11-05T08:00:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 3,
      "totalItems": 45,
      "itemsPerPage": 20
    }
  }
}
```

### 3.5 Cancel Ride
**Endpoint:** `POST /rides/{bookingId}/cancel`

**Headers:** `Authorization: Bearer {accessToken}`

**Request:**
```json
{
  "reason": "Change of plans",
  "cancellationType": "passenger"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Ride cancelled successfully",
  "data": {
    "bookingId": "uuid",
    "status": "cancelled",
    "refundAmount": 3400,
    "refundStatus": "processing",
    "cancelledAt": "2025-11-09T10:00:00Z"
  }
}
```

### 3.6 Reschedule Ride
**Endpoint:** `PUT /rides/{bookingId}/reschedule`

**Headers:** `Authorization: Bearer {accessToken}`

**Request:**
```json
{
  "newRideId": "uuid",
  "newTravelDate": "2025-11-13",
  "newDepartureTime": "07:00 AM"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Ride rescheduled successfully",
  "data": {
    "bookingId": "uuid",
    "newTravelDate": "2025-11-13",
    "newDepartureTime": "07:00 AM",
    "updatedAt": "2025-11-09T10:00:00Z"
  }
}
```

### 3.7 Rate Ride
**Endpoint:** `POST /rides/{bookingId}/rate`

**Headers:** `Authorization: Bearer {accessToken}`

**Request:**
```json
{
  "rating": 5,
  "review": "Excellent service, on-time departure",
  "driverId": "uuid"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Rating submitted successfully",
  "data": {
    "bookingId": "uuid",
    "rating": 5,
    "review": "Excellent service, on-time departure",
    "ratedAt": "2025-11-09T10:00:00Z"
  }
}
```

---

## 4. Driver Ride Management APIs

### 4.1 Schedule New Ride
**Endpoint:** `POST /driver/rides/schedule`

**Headers:** `Authorization: Bearer {accessToken}`

**Request:**
```json
{
  "pickupLocation": {
    "address": "Allapalli",
    "latitude": 19.9876,
    "longitude": 79.8765
  },
  "dropoffLocation": {
    "address": "Chandrapur",
    "latitude": 19.9506,
    "longitude": 79.2961
  },
  "travelDate": "2025-11-12",
  "departureTime": "06:00 AM",
  "vehicleType": "shared_van",
  "totalSeats": 7,
  "pricePerSeat": 850,
  "route": "via NH353"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Ride scheduled successfully",
  "data": {
    "rideId": "uuid",
    "rideNumber": "DR2401",
    "pickupLocation": "Allapalli",
    "dropoffLocation": "Chandrapur",
    "travelDate": "2025-11-12",
    "departureTime": "06:00 AM",
    "totalSeats": 7,
    "bookedSeats": 0,
    "availableSeats": 7,
    "pricePerSeat": 850,
    "status": "scheduled",
    "createdAt": "2025-11-09T10:00:00Z"
  }
}
```

### 4.2 Get Driver's Rides
**Endpoint:** `GET /driver/rides`

**Headers:** `Authorization: Bearer {accessToken}`

**Query Parameters:**
- `status` (optional): `upcoming`, `scheduled`, `completed`, `cancelled`
- `page` (optional): page number (default: 1)
- `limit` (optional): items per page (default: 20)

**Response:**
```json
{
  "success": true,
  "data": {
    "rides": [
      {
        "rideId": "uuid",
        "rideNumber": "DR2401",
        "pickupLocation": "Allapalli",
        "dropoffLocation": "Chandrapur",
        "date": "2025-11-09",
        "departureTime": "06:00 AM",
        "totalSeats": 7,
        "bookedSeats": 4,
        "availableSeats": 3,
        "pricePerSeat": 850,
        "estimatedEarnings": 3400,
        "vehicleType": "shared_van",
        "status": "upcoming",
        "passengers": [
          {
            "passengerId": "uuid",
            "name": "Rahul Sharma",
            "phoneNumber": "+919876543210",
            "seatNumber": 1,
            "otp": "1234",
            "isVerified": false
          }
        ]
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 2,
      "totalItems": 25,
      "itemsPerPage": 20
    }
  }
}
```

### 4.3 Get Ride Details
**Endpoint:** `GET /driver/rides/{rideId}`

**Headers:** `Authorization: Bearer {accessToken}`

**Response:**
```json
{
  "success": true,
  "data": {
    "rideId": "uuid",
    "rideNumber": "DR2401",
    "pickupLocation": "Allapalli",
    "dropoffLocation": "Chandrapur",
    "date": "2025-11-09",
    "departureTime": "06:00 AM",
    "totalSeats": 7,
    "bookedSeats": 4,
    "availableSeats": 3,
    "pricePerSeat": 850,
    "estimatedEarnings": 3400,
    "vehicleType": "shared_van",
    "status": "upcoming",
    "canStartTrip": false,
    "minutesUntilDeparture": 45,
    "passengers": [
      {
        "bookingId": "uuid",
        "passengerId": "uuid",
        "name": "Rahul Sharma",
        "phoneNumber": "+919876543210",
        "seatNumber": 1,
        "passengerCount": 2,
        "otp": "1234",
        "isVerified": false,
        "pickupLocation": "Allapalli Main Square",
        "dropoffLocation": "Chandrapur Railway Station"
      }
    ],
    "route": {
      "distance": 65.5,
      "duration": "2 hours",
      "waypoints": []
    }
  }
}
```

### 4.4 Start Trip
**Endpoint:** `POST /driver/rides/{rideId}/start`

**Headers:** `Authorization: Bearer {accessToken}`

**Request:**
```json
{
  "startLocation": {
    "latitude": 19.9876,
    "longitude": 79.8765
  },
  "actualDepartureTime": "2025-11-09T06:05:00Z"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Trip started successfully",
  "data": {
    "rideId": "uuid",
    "status": "active",
    "startedAt": "2025-11-09T06:05:00Z",
    "delayMinutes": 5,
    "trackingId": "uuid"
  }
}
```

### 4.5 Verify Passenger OTP
**Endpoint:** `POST /driver/rides/{rideId}/verify-otp`

**Headers:** `Authorization: Bearer {accessToken}`

**Request:**
```json
{
  "otp": "1234"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Passenger verified successfully",
  "data": {
    "bookingId": "uuid",
    "passengerName": "Rahul Sharma",
    "seatNumber": 1,
    "isVerified": true,
    "verifiedAt": "2025-11-09T06:05:00Z"
  }
}
```

### 4.6 Verify Passenger QR Code
**Endpoint:** `POST /driver/rides/{rideId}/verify-qr`

**Headers:** `Authorization: Bearer {accessToken}`

**Request:**
```json
{
  "qrData": "encrypted_booking_data"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Passenger verified successfully",
  "data": {
    "bookingId": "uuid",
    "passengerName": "Rahul Sharma",
    "seatNumber": 1,
    "isVerified": true,
    "verifiedAt": "2025-11-09T06:05:00Z"
  }
}
```

### 4.7 Complete Trip
**Endpoint:** `POST /driver/rides/{rideId}/complete`

**Headers:** `Authorization: Bearer {accessToken}`

**Request:**
```json
{
  "endLocation": {
    "latitude": 19.9506,
    "longitude": 79.2961
  },
  "actualArrivalTime": "2025-11-09T08:10:00Z",
  "actualDistance": 67.2
}
```

**Response:**
```json
{
  "success": true,
  "message": "Trip completed successfully",
  "data": {
    "rideId": "uuid",
    "status": "completed",
    "completedAt": "2025-11-09T08:10:00Z",
    "totalEarnings": 3400,
    "duration": "2 hours 10 minutes",
    "distance": 67.2
  }
}
```

### 4.8 Cancel Scheduled Ride
**Endpoint:** `POST /driver/rides/{rideId}/cancel`

**Headers:** `Authorization: Bearer {accessToken}`

**Request:**
```json
{
  "reason": "Vehicle breakdown",
  "notifyPassengers": true
}
```

**Response:**
```json
{
  "success": true,
  "message": "Ride cancelled successfully",
  "data": {
    "rideId": "uuid",
    "status": "cancelled",
    "cancelledAt": "2025-11-09T10:00:00Z",
    "affectedPassengers": 4
  }
}
```

---

## 5. Driver Dashboard & Earnings APIs

### 5.1 Get Driver Dashboard
**Endpoint:** `GET /driver/dashboard`

**Headers:** `Authorization: Bearer {accessToken}`

**Response:**
```json
{
  "success": true,
  "data": {
    "driver": {
      "id": "uuid",
      "name": "Rajesh Kumar",
      "rating": 4.8,
      "totalRides": 156,
      "isOnline": false
    },
    "todayStats": {
      "totalRides": 3,
      "totalEarnings": 2550,
      "onlineHours": 6.5
    },
    "upcomingRide": {
      "rideId": "uuid",
      "pickupLocation": "Allapalli",
      "dropoffLocation": "Chandrapur",
      "departureTime": "06:00 AM",
      "bookedSeats": 4,
      "totalSeats": 7
    },
    "pendingEarnings": 12500,
    "availableForWithdrawal": 8000
  }
}
```

### 5.2 Update Online Status
**Endpoint:** `PUT /driver/status`

**Headers:** `Authorization: Bearer {accessToken}`

**Request:**
```json
{
  "isOnline": true
}
```

**Response:**
```json
{
  "success": true,
  "message": "Status updated successfully",
  "data": {
    "isOnline": true,
    "updatedAt": "2025-11-09T10:00:00Z"
  }
}
```

### 5.3 Get Earnings Summary
**Endpoint:** `GET /driver/earnings`

**Headers:** `Authorization: Bearer {accessToken}`

**Query Parameters:**
- `period` (optional): `today`, `week`, `month`, `year`, `custom`
- `startDate` (optional): for custom period
- `endDate` (optional): for custom period

**Response:**
```json
{
  "success": true,
  "data": {
    "summary": {
      "totalEarnings": 45600,
      "totalRides": 54,
      "averageEarningsPerRide": 844,
      "totalDistance": 3542,
      "onlineHours": 156
    },
    "breakdown": {
      "cashCollected": 32000,
      "onlinePayments": 13600,
      "commission": 4560,
      "netEarnings": 41040
    },
    "chartData": [
      {
        "date": "2025-11-01",
        "earnings": 2550,
        "rides": 3
      }
    ]
  }
}
```

### 5.4 Get Payout History
**Endpoint:** `GET /driver/payouts`

**Headers:** `Authorization: Bearer {accessToken}`

**Query Parameters:**
- `page` (optional): page number (default: 1)
- `limit` (optional): items per page (default: 20)

**Response:**
```json
{
  "success": true,
  "data": {
    "payouts": [
      {
        "payoutId": "uuid",
        "amount": 8000,
        "status": "completed",
        "method": "bank_transfer",
        "transactionId": "TXN123456",
        "requestedAt": "2025-11-01T10:00:00Z",
        "completedAt": "2025-11-02T15:30:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalItems": 95,
      "itemsPerPage": 20
    }
  }
}
```

### 5.5 Request Payout
**Endpoint:** `POST /driver/payouts/request`

**Headers:** `Authorization: Bearer {accessToken}`

**Request:**
```json
{
  "amount": 8000,
  "method": "bank_transfer",
  "bankDetails": {
    "accountNumber": "1234567890",
    "ifscCode": "SBIN0001234",
    "accountHolderName": "Rajesh Kumar"
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Payout request submitted",
  "data": {
    "payoutId": "uuid",
    "amount": 8000,
    "status": "pending",
    "estimatedCompletionDate": "2025-11-11",
    "requestedAt": "2025-11-09T10:00:00Z"
  }
}
```

---

## 6. Vehicle Management APIs

### 6.1 Get Vehicle Details
**Endpoint:** `GET /driver/vehicle`

**Headers:** `Authorization: Bearer {accessToken}`

**Response:**
```json
{
  "success": true,
  "data": {
    "vehicleId": "uuid",
    "vehicleType": "shared_van",
    "make": "Toyota",
    "model": "Innova Crysta",
    "year": 2020,
    "registrationNumber": "MH 34 AB 1234",
    "color": "White",
    "totalSeats": 7,
    "fuelType": "Diesel",
    "documents": {
      "registration": {
        "verified": true,
        "expiryDate": "2030-05-15"
      },
      "insurance": {
        "verified": true,
        "expiryDate": "2026-05-15"
      },
      "permit": {
        "verified": true,
        "expiryDate": "2026-12-31"
      }
    },
    "features": ["AC", "Music System", "USB Charging"]
  }
}
```

### 6.2 Update Vehicle Details
**Endpoint:** `PUT /driver/vehicle`

**Headers:** `Authorization: Bearer {accessToken}`

**Request:**
```json
{
  "color": "Silver",
  "features": ["AC", "Music System", "USB Charging", "WiFi"]
}
```

**Response:**
```json
{
  "success": true,
  "message": "Vehicle details updated",
  "data": {
    "vehicleId": "uuid",
    "updatedAt": "2025-11-09T10:00:00Z"
  }
}
```

---

## 7. Notifications APIs

### 7.1 Get Notifications
**Endpoint:** `GET /notifications`

**Headers:** `Authorization: Bearer {accessToken}`

**Query Parameters:**
- `page` (optional): page number (default: 1)
- `limit` (optional): items per page (default: 20)
- `unreadOnly` (optional): boolean (default: false)

**Response:**
```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "uuid",
        "type": "ride_reminder",
        "title": "Upcoming Ride Reminder",
        "message": "Your ride to Chandrapur starts in 15 minutes",
        "data": {
          "rideId": "uuid",
          "bookingId": "uuid"
        },
        "isRead": false,
        "createdAt": "2025-11-09T05:45:00Z"
      }
    ],
    "unreadCount": 3,
    "pagination": {
      "currentPage": 1,
      "totalPages": 2,
      "totalItems": 35,
      "itemsPerPage": 20
    }
  }
}
```

### 7.2 Mark Notification as Read
**Endpoint:** `PUT /notifications/{notificationId}/read`

**Headers:** `Authorization: Bearer {accessToken}`

**Response:**
```json
{
  "success": true,
  "message": "Notification marked as read"
}
```

### 7.3 Mark All as Read
**Endpoint:** `PUT /notifications/read-all`

**Headers:** `Authorization: Bearer {accessToken}`

**Response:**
```json
{
  "success": true,
  "message": "All notifications marked as read"
}
```

---

## 8. Real-time Tracking APIs (WebSocket)

### 8.1 Connect to Tracking
**WebSocket Endpoint:** `wss://api.allapalliride.com/v1/tracking`

**Connection:**
```javascript
const ws = new WebSocket('wss://api.allapalliride.com/v1/tracking?token={accessToken}');
```

**Subscribe to Ride Tracking (Passenger):**
```json
{
  "action": "subscribe",
  "channel": "ride_tracking",
  "bookingId": "uuid"
}
```

**Subscribe to Ride Updates (Driver):**
```json
{
  "action": "subscribe",
  "channel": "driver_ride",
  "rideId": "uuid"
}
```

**Location Update (Driver):**
```json
{
  "action": "location_update",
  "rideId": "uuid",
  "location": {
    "latitude": 19.9876,
    "longitude": 79.8765,
    "speed": 45.5,
    "heading": 180
  },
  "timestamp": "2025-11-09T06:30:00Z"
}
```

**Server Response (Location Update):**
```json
{
  "type": "location_update",
  "rideId": "uuid",
  "driverLocation": {
    "latitude": 19.9876,
    "longitude": 79.8765
  },
  "estimatedArrival": "2025-11-09T08:00:00Z",
  "remainingDistance": 45.2
}
```

---

## 9. Admin APIs (Optional)

### 9.1 Get System Statistics
**Endpoint:** `GET /admin/stats`

**Headers:** `Authorization: Bearer {adminToken}`

**Response:**
```json
{
  "success": true,
  "data": {
    "totalUsers": 1250,
    "totalPassengers": 1050,
    "totalDrivers": 200,
    "activeRides": 15,
    "todayRides": 120,
    "todayRevenue": 102000,
    "platformCommission": 10200
  }
}
```

---

## Error Responses

### Standard Error Format
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": {}
  }
}
```

### Common Error Codes
- `AUTH_REQUIRED` - Authentication token missing
- `AUTH_INVALID` - Invalid or expired token
- `VALIDATION_ERROR` - Request validation failed
- `NOT_FOUND` - Resource not found
- `PERMISSION_DENIED` - User doesn't have permission
- `RIDE_NOT_AVAILABLE` - Ride is no longer available
- `INSUFFICIENT_SEATS` - Not enough seats available
- `BOOKING_CANCELLED` - Booking has been cancelled
- `OTP_INVALID` - Invalid OTP provided
- `OTP_EXPIRED` - OTP has expired
- `RIDE_ALREADY_STARTED` - Cannot modify started ride
- `PAYMENT_FAILED` - Payment processing failed
- `SERVER_ERROR` - Internal server error

### HTTP Status Codes
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `409` - Conflict
- `422` - Unprocessable Entity
- `500` - Internal Server Error
- `503` - Service Unavailable

---

## Rate Limiting
- **Authentication endpoints**: 5 requests per minute
- **General endpoints**: 100 requests per minute
- **WebSocket connections**: 1 connection per user

## Pagination
All list endpoints support pagination with query parameters:
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20, max: 100)

## Versioning
API version is included in the URL: `/v1/`
Breaking changes will increment the version number.
