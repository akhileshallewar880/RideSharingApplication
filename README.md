<div align="center">
  <img src="mobile/assets/images/vanyatra_new_logo.png" alt="VanYatra Logo" width="200" height="auto" style="border-radius: 20px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);">
  <br/>
  <br/>

  # VanYatra - Next Gen Ride Sharing
  ### *Seamless Journeys, Connected Experiences*

  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
  [![.NET Core](https://img.shields.io/badge/.NET%20Core-512BD4?style=for-the-badge&logo=dotnet&logoColor=white)](https://dotnet.microsoft.com/)
  [![Azure](https://img.shields.io/badge/Azure-0078D4?style=for-the-badge&logo=microsoft-azure&logoColor=white)](https://azure.microsoft.com/)
  [![SignalR](https://img.shields.io/badge/SignalR-Realtime-red?style=for-the-badge)](https://dotnet.microsoft.com/apps/aspnet/signalr)

</div>

---

## 🌟 Overview

**VanYatra** is not just another ride-sharing app; it is a comprehensive transportation ecosystem designed to bridge the gap between rural connectivity and urban convenience. Built with a focus on reliability, real-time tracking, and seamless user experiences, VanYatra empowers drivers and passengers alike.

### The Problem
In many regions, transportation remains fragmented. Passengers face uncertain wait times, lack of transparent pricing, and safety concerns due to untracked vehicles. Drivers struggle with inefficient dispatching and lack of digital tools to manage their business.

### The Solution
VanYatra solves this by providing a unified platform where:
- **Passengers** get reliable rides with accurate ETAs and fair pricing.
- **Drivers** receive optimized ride requests, maximizing their earnings.
- **Administrators** have full visibility over fleet operations through a powerful dashboard.

---

## 🚀 Technical Deep Dive

VanYatra leverages a modern, scalable technology stack to ensure performance and reliability.

### 📱 Mobile Application (Passenger & Driver)
Built with **Flutter**, the mobile app offers a native experience on both iOS and Android from a single codebase.

- **Architecture**: Clean Architecture with Riverpod for state management, ensuring separation of concerns and testability.
- **Navigation**: `go_router` for robust deep linking and navigation handling.
- **Maps Integration**: Advanced Google Maps implementation using `google_maps_flutter` for real-time tracking, polyline drawing, and location selection.
- **Real-time Operations**: Uses SignalR client (`signalr_core`) to receive instant ride updates, driver location pushes, and status changes without polling.

### 💻 Admin Dashboard
A powerful web-based command center built with **Flutter Web**.

- **Analytics**: Integrated `fl_chart` to visualize key metrics like daily active users, revenue trends, and ride volume.
- **Fleet Management**: Comprehensive tables (`data_table_2`) for managing drivers, vehicles, and user verification.
- **Real-time Monitoring**: Admins can watch active rides on a live map, powered by the same SignalR infrastructure as the mobile app.

### ☁️ Backend API
The backbone of VanYatra is a high-performance **.NET 8** Web API hosted on Azure.

- **Core Framework**: ASP.NET Core 8.0, utilizing Minimal APIs for lightweight, fast endpoints.
- **Database**: **Azure SQL Database** accessed via **Entity Framework Core 9**, ensuring strictly typed data access and easy migrations.
- **Real-time Engine**: **SignalR** Hubs manage thousands of concurrent connections, broadcasting location updates and ride status changes in milliseconds.
- **Security**: JWT Authentication (`Microsoft.AspNetCore.Authentication.JwtBearer`) secures all endpoints, with Role-Based Access Control (RBAC) for Admins vs. Users.
- **Logging**: structured logging with **Serilog** for deep observability into production issues.

---

## 📂 Project Structure

```bash
RideSharingApplication/
├── mobile/                 # Flutter Mobile App (iOS/Android)
│   ├── lib/
│   │   ├── features/       # Feature-based folders (Auth, Ride, Profile)
│   │   ├── core/           # Shared utilities and network logic
│   └── pubspec.yaml        # Dependencies (Riverpod, Dio, Google Maps)
│
├── admin_web/              # Flutter Web Admin Dashboard
│   ├── lib/
│   │   ├── screens/        # Dashboard, User Mgmt, Settings screens
│   └── pubspec.yaml
│
└── server/                 # .NET 8 Backend API
    └── ride_sharing_application/
        ├── RideSharing.API/
        │   ├── Controllers/ # REST Endpoints
        │   ├── Hubs/        # SignalR Real-time Hubs
        │   ├── Services/    # Business Logic
        │   └── Models/      # EF Core Entities
        └── appsettings.json # Configuration
```

## 🛠️ Getting Started

### Prerequisites
- **Flutter SDK**: 3.22+
- **.NET SDK**: 8.0+
- **SQL Server** (Local or Azure)

### Installation

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/your-org/ride-sharing-application.git
    cd RideSharingApplication
    ```

2.  **Backend Setup**
    -   Navigate to `server/ride_sharing_application/RideSharing.API`.
    -   Update `appsettings.Development.json` with your SQL Connection String.
    -   Run Migrations: `dotnet ef database update`.
    -   Start API: `dotnet run`.

3.  **Mobile App Setup**
    -   Navigate to `mobile/`.
    -   Get dependencies: `flutter pub get`.
    -   Run on emulator/device: `flutter run`.

4.  **Admin Web Setup**
    -   Navigate to `admin_web/`.
    -   Get dependencies: `flutter pub get`.
    -   Run in Chrome: `flutter run -d chrome`.

---

<div align="center">
  <p>Made with ❤️ by Akhilesh Allewar</p>
</div>
