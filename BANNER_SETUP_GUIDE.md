# Banner & Google Button Setup Guide

## ✅ Google Sign-In Button - FIXED

### What was changed:
- Updated button to use your custom images from `assets/images/light/` and `assets/images/dark/` folders
- Fixed image paths to match actual filenames: `android_light_sq.png` and `android_dark_sq.png`
- Button now displays the full pre-designed Google button image

### How it works:
- **Light mode**: Shows `assets/images/light/android_light_sq.png`
- **Dark mode**: Shows `assets/images/dark/android_dark_sq.png`
- **Fallback**: If images fail to load, shows icon + text

### To test:
1. Hot reload your Flutter app (`r` in terminal)
2. The button should now display your custom Google sign-in button image
3. Toggle between light/dark mode to see both variants

---

## 📱 Adding Banners to Your App

### Step 1: Start the Backend Server

```bash
cd /Users/akhileshallewar/project_dev/RideBuisnessCodePrivate/vanyatra_rural_ride_booking/server/ride_sharing_application
dotnet run --project RideSharing.API
```

The server should start on `http://0.0.0.0:5056`

### Step 2: Add Banner Data to Database

You need to insert banner records into your `Banners` table. Use SQL Server Management Studio or run this SQL:

```sql
-- Insert a sample banner
INSERT INTO Banners (
    Id,
    Title,
    Description,
    ImageUrl,
    TargetUrl,
    StartDate,
    EndDate,
    IsActive,
    Priority,
    TargetAudience,
    CreatedAt,
    UpdatedAt
)
VALUES (
    NEWID(),
    'Welcome to VanYatra',
    'Book your rural rides easily and safely',
    'https://via.placeholder.com/800x400/4285F4/FFFFFF?text=Welcome+Banner',
    null,
    GETDATE(),
    DATEADD(month, 3, GETDATE()),
    1,
    1,
    'all',
    GETDATE(),
    GETDATE()
);

-- Add another banner
INSERT INTO Banners (
    Id,
    Title,
    Description,
    ImageUrl,
    TargetUrl,
    StartDate,
    EndDate,
    IsActive,
    Priority,
    TargetAudience,
    CreatedAt,
    UpdatedAt
)
VALUES (
    NEWID(),
    'Safe & Comfortable',
    'Travel with verified drivers',
    'https://via.placeholder.com/800x400/34A853/FFFFFF?text=Safe+Travel',
    null,
    GETDATE(),
    DATEADD(month, 3, GETDATE()),
    1,
    2,
    'all',
    GETDATE(),
    GETDATE()
);

-- Add one more banner
INSERT INTO Banners (
    Id,
    Title,
    Description,
    ImageUrl,
    TargetUrl,
    StartDate,
    EndDate,
    IsActive,
    Priority,
    TargetAudience,
    CreatedAt,
    UpdatedAt
)
VALUES (
    NEWID(),
    'Best Prices',
    'Affordable rides to rural areas',
    'https://via.placeholder.com/800x400/FBBC04/FFFFFF?text=Best+Prices',
    null,
    GETDATE(),
    DATEADD(month, 3, GETDATE()),
    1,
    3,
    'all',
    GETDATE(),
    GETDATE()
);
```

### Step 3: Verify Banners API

Test the API endpoint:

```bash
curl http://192.168.88.10:5056/api/v1/passenger/banners
```

You should see JSON response with your banners.

### Step 4: Using Your Own Banner Images

#### Option A: Use Image URLs (Recommended)
Upload your banner images to:
- Your server's `wwwroot/uploads/banners/` folder
- Cloud storage (Azure Blob, AWS S3, etc.)
- Any accessible image hosting

Then update the `ImageUrl` in database:
```sql
UPDATE Banners
SET ImageUrl = 'http://192.168.88.10:5056/uploads/banners/welcome-banner.jpg'
WHERE Title = 'Welcome to VanYatra';
```

#### Option B: Use Local Assets (for testing)
1. Add images to `mobile/assets/images/banners/`
2. Update `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/images/
    - assets/images/banners/
```
3. Modify the banner display code to check for local assets first

### Step 5: Banner Image Requirements

- **Recommended size**: 800x400 pixels (2:1 ratio)
- **Format**: PNG or JPG
- **Max file size**: 500KB for good performance
- **Content**: Clear text, high contrast, mobile-friendly

### Step 6: View Banners in App

1. Make sure backend server is running
2. Open your Flutter app
3. Navigate to the login screen
4. You should see:
   - Loading indicator briefly
   - Banner carousel at the top
   - Swipeable banners
   - Indicator dots showing position

### What the App Shows:

**If server banners load successfully:**
- Network images from your database
- Title and description overlay
- Clickable banners (if TargetUrl is set)
- Auto-record impressions

**If server is unreachable:**
- Shows 3 fallback banners with:
  - "Welcome to VanYatra"
  - "Safe & Reliable"
  - "Easy Booking"
- Local placeholder images

---

## 🔧 Troubleshooting

### Banner not showing?

**Check 1: Server running?**
```bash
curl http://192.168.88.10:5056/api/v1/passenger/banners
```

**Check 2: Database has active banners?**
```sql
SELECT * FROM Banners WHERE IsActive = 1 AND StartDate <= GETDATE() AND EndDate >= GETDATE();
```

**Check 3: Flutter console for errors**
Look for: `Error loading banners: ...`

**Check 4: Network connectivity**
- Phone and computer on same WiFi?
- Firewall not blocking port 5056?

### Google button still showing text instead of image?

**Check 1: Image files exist?**
```bash
ls -la mobile/assets/images/light/
ls -la mobile/assets/images/dark/
```

Should show:
- `android_light_sq.png`
- `android_dark_sq.png`

**Check 2: pubspec.yaml includes assets?**
```yaml
flutter:
  assets:
    - assets/images/
```

**Check 3: Run flutter clean**
```bash
cd mobile
flutter clean
flutter pub get
flutter run
```

---

## 📊 Banner Analytics

The app automatically tracks:
- **Impressions**: When banner is viewed
- **Clicks**: When banner is tapped

These are sent to:
- `POST /api/v1/passenger/banners/{id}/impression`
- `POST /api/v1/passenger/banners/{id}/click`

View analytics in database:
```sql
SELECT 
    Title,
    ImpressionCount,
    ClickCount,
    CASE 
        WHEN ImpressionCount > 0 
        THEN CAST(ClickCount AS FLOAT) / ImpressionCount * 100 
        ELSE 0 
    END AS CTR_Percentage
FROM Banners
ORDER BY Priority;
```

---

## 🎨 Customizing Banner Display

### Change banner height:
Edit `login_with_onboarding_screen.dart`:
```dart
height: 200,  // Change this value (current: 200)
```

### Change carousel speed:
```dart
autoPlayInterval: Duration(seconds: 5),  // Change from 5 to your value
```

### Disable auto-play:
```dart
autoPlay: false,  // Change from true to false
```

---

## 📝 Next Steps

1. ✅ Google button is now fixed - hot reload to see it
2. 🔄 Start backend server: `dotnet run --project RideSharing.API`
3. 📊 Add banner data to database using SQL above
4. 🖼️ Upload your banner images to server
5. 📱 Test in Flutter app - should see banners loading!

Need help? Check the troubleshooting section above!
