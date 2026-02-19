# Ride Sharing Application

This repository contains the source code for a comprehensive Ride Sharing Application, featuring a mobile app for drivers and passengers, an admin web panel, and a robust backend API.

## Project Structure

The repository is organized into three main components:

- **`mobile/`**: The mobile application built with Flutter, supporting both iOS and Android platforms. It handles passenger ride requests, driver navigation, and real-time tracking.
- **`admin_web/`**: The admin dashboard built with Flutter Web. It allows administrators to manage users, rides, pricing, and view analytics.
- **`server/`**: The backend API built with .NET Core. It provides the core logic, database interactions, and real-time communication via SignalR.

## Tech Stack

### Backend
- **Framework**: .NET Core (C#)
- **Database**: Azure SQL
- **Real-time Communication**: SignalR
- **ORM**: Entity Framework Core

### Mobile App
- **Framework**: Flutter
- **Platforms**: iOS, Android
- **State Management**: (Add specific state management if known, e.g., Provider/Riverpod/Bloc)
- **Maps Integration**: Google Maps / Mapbox (Implied by ride sharing)

### Admin Web
- **Framework**: Flutter Web
- **Deployment**: Azure Static Web Apps (implied by config files)

## Setup & Installation

### Backend (Server)
1. Navigate to `server/ride_sharing_application/RideSharing.API`.
2. Configure your database connection string in `appsettings.json` (or use User Secrets).
3. Run migrations to set up the database.
4. Start the API using `dotnet run`.

### Mobile App
1. Navigate to the `mobile` directory.
2. Install dependencies: `flutter pub get`.
3. Run the app: `flutter run`.

### Admin Web
1. Navigate to the `admin_web` directory.
2. Install dependencies: `flutter pub get`.
3. Run the web app: `flutter run -d chrome`.

## Security Note

**Important**: This repository should **NOT** contain any sensitive credentials such as API keys, database connection strings (with passwords), or service account JSON files.

- Ensure `appsettings.json` and `appsettings.Development.json` do not contain production secrets.
- Use Environment Variables or Azure Key Vault for production secrets.
- `serviceAccountKey.json` and similar files should be added to `.gitignore`.
