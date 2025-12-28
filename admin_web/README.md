# VanYatra Admin Dashboard

A Flutter Web application for managing the VanYatra taxi booking system. This admin dashboard provides comprehensive tools for driver verification, ride monitoring, analytics, and system management.

## Features

### 🔐 Authentication
- Secure admin login with JWT token authentication
- Role-based access control
- Auto token refresh

### 👨‍✈️ Driver Management
- **Driver Verification Queue**: Review pending driver registrations
- **Document Viewer**: View driving licenses, RC books, and profile photos
- **Approve/Reject**: Quick actions with notes and rejection reasons
- **Driver List**: Search and filter all drivers by status
- **Activation Controls**: Activate or deactivate driver accounts

### 🚗 Ride Monitoring
- **Real-time Active Rides**: Monitor all ongoing rides
- **Auto-refresh**: Updates every 30 seconds
- **Ride Details**: Complete ride information with passenger and driver details
- **Admin Cancellation**: Cancel rides with reason tracking
- **Status Tracking**: Visual status indicators for ride states

### 📊 Analytics Dashboard
- **Key Metrics**: 
  - Total/Active Drivers
  - Pending Verifications
  - Total/Completed/Active Rides
  - Revenue Tracking
  - Passenger Statistics
- **Interactive Charts**:
  - Daily Revenue Line Chart
  - Daily Rides Bar Chart
  - Driver Status Distribution
- **Date Range Filtering**: Custom date range analysis

### 🎨 User Interface
- **Responsive Design**: Desktop-optimized with mobile support
- **Data Tables**: Sortable, filterable tables for large datasets
- **Material Design 3**: Modern, clean interface
- **Dark Sidebar**: Professional navigation menu
- **Status Indicators**: Color-coded chips for quick status recognition

## Technology Stack

- **Framework**: Flutter 3.x (Web)
- **State Management**: Riverpod 2.6.1
- **HTTP Client**: Dio 5.4.3
- **Charts**: FL Chart 0.68.0
- **Data Tables**: Data Table 2 (2.5.12)
- **Secure Storage**: Flutter Secure Storage 9.2.2
- **Date Formatting**: Intl 0.19.0

## Project Structure

```
admin_web/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart          # API endpoints, validation rules
│   │   ├── models/
│   │   │   └── admin_models.dart           # Data models
│   │   ├── providers/
│   │   │   ├── admin_auth_provider.dart    # Auth state management
│   │   │   ├── driver_provider.dart        # Driver data management
│   │   │   ├── ride_provider.dart          # Ride data management
│   │   │   └── analytics_provider.dart     # Analytics state
│   │   ├── services/
│   │   │   ├── admin_auth_service.dart     # Auth API calls
│   │   │   ├── driver_service.dart         # Driver API calls
│   │   │   ├── ride_service.dart           # Ride API calls
│   │   │   └── analytics_service.dart      # Analytics API calls
│   │   └── theme/
│   │       └── admin_theme.dart            # App theme and colors
│   ├── features/
│   │   ├── auth/
│   │   │   └── admin_login_screen.dart     # Login page
│   │   ├── drivers/
│   │   │   ├── driver_verification_list_screen.dart    # List view
│   │   │   └── driver_verification_detail_screen.dart  # Detail view
│   │   ├── rides/
│   │   │   └── ride_monitoring_screen.dart # Active rides
│   │   └── analytics/
│   │       └── analytics_dashboard_screen.dart # Dashboard
│   ├── shared/
│   │   └── layouts/
│   │       └── admin_layout.dart           # Main layout with sidebar
│   └── main.dart                           # App entry point
├── web/
│   ├── index.html                          # Web entry point
│   └── manifest.json                       # PWA configuration
├── pubspec.yaml                            # Dependencies
└── analysis_options.yaml                   # Linter rules
```

## Setup Instructions

### Prerequisites
- Flutter SDK 3.0.0 or higher
- Dart SDK
- Web browser (Chrome recommended)

### Installation

1. **Navigate to the admin_web directory**:
   ```bash
   cd /Users/akhileshallewar/project_dev/taxi-booking-app/admin_web
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Update API Configuration** (if needed):
   Edit `lib/core/constants/app_constants.dart`:
   ```dart
   static const String baseUrl = 'http://192.168.88.7:5056/api/v1';
   ```

4. **Run the application**:
   ```bash
   flutter run -d chrome
   ```

### Building for Production

```bash
# Build web app
flutter build web --release

# Output will be in build/web/
```

### Deployment

1. **Deploy to Firebase Hosting**:
   ```bash
   firebase init hosting
   firebase deploy
   ```

2. **Deploy to any web server**:
   Copy contents of `build/web/` to your web server's public directory.

## API Integration

The dashboard connects to the backend API at `http://192.168.88.7:5056/api/v1`

### Required API Endpoints

#### Authentication
- `POST /auth/admin/login` - Admin login
- `POST /auth/refresh` - Token refresh
- `POST /auth/logout` - Logout

#### Drivers
- `GET /drivers/pending` - Get pending drivers (with pagination)
- `GET /drivers/:id` - Get driver details
- `POST /drivers/:id/approve` - Approve driver
- `POST /drivers/:id/reject` - Reject driver
- `GET /drivers` - Get all drivers
- `POST /drivers/:id/activate` - Activate driver
- `POST /drivers/:id/deactivate` - Deactivate driver
- `GET /drivers/documents/:id` - Get document URL

#### Rides
- `GET /rides` - Get rides (with filters)
- `GET /rides/active` - Get active rides
- `GET /rides/:id` - Get ride details
- `POST /rides/:id/cancel` - Cancel ride

#### Analytics
- `GET /analytics/dashboard` - Get dashboard stats
- `GET /analytics/revenue` - Get revenue analytics
- `GET /analytics/drivers` - Get driver analytics
- `GET /analytics/rides` - Get ride analytics

## Features in Detail

### Driver Verification Workflow

1. **Pending Queue**: View all drivers awaiting verification
2. **Filter & Search**: Filter by status (pending/approved/rejected), search by name/phone/vehicle
3. **Document Review**: 
   - View uploaded driving license
   - View RC book
   - View profile photo
4. **Decision Making**:
   - **Approve**: Driver can start accepting rides
   - **Reject**: Driver notified with reason
5. **Notes**: Add internal notes during approval

### Ride Monitoring

1. **Real-time Updates**: Auto-refresh every 30 seconds
2. **Status Overview**: Quick stats for requested/in-progress rides
3. **Detailed View**: See complete ride information
4. **Admin Actions**: Cancel rides when necessary
5. **Filter Options**: Filter by status, date range

### Analytics Dashboard

1. **Date Range Selection**: Analyze any time period
2. **Key Metrics Cards**: Visual overview of important statistics
3. **Revenue Chart**: Track daily revenue trends
4. **Rides Chart**: Monitor daily ride volume
5. **Driver Distribution**: See verification status breakdown

## Security Features

- JWT token-based authentication
- Secure token storage using Flutter Secure Storage
- Automatic token refresh
- Role-based access control
- Admin-only endpoints

## Responsive Design

- **Desktop (>800px)**: Full sidebar, data tables, multi-column layouts
- **Mobile (<800px)**: Collapsible sidebar, card lists, single-column layouts

## Color Scheme

- **Primary**: Indigo (#1a237e)
- **Accent**: Orange (#ff6f00)
- **Success**: Green (#4caf50)
- **Warning**: Orange (#ff9800)
- **Error**: Red (#f44336)
- **Info**: Blue (#2196f3)

## Support

For issues or questions, contact the development team.

## License

Copyright © 2025 Allapalli Ride. All rights reserved.
