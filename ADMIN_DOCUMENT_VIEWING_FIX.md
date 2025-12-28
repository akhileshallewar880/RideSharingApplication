# Admin Dashboard Document Viewing Fix

## Problem
Admin dashboard was unable to see uploaded driver documents (license and RC documents) because:
1. The backend was returning placeholder URLs instead of actual document paths
2. The Driver model didn't have a field to store license document paths
3. Document upload endpoint was not saving license document paths

## Changes Made

### 1. Database Schema Update
**File**: `RideSharing.API/Models/Domain/Driver.cs`

Added new field to store license document path:
```csharp
[MaxLength(500)]
public string? LicenseDocument { get; set; }
```

**Migration**: `20251129190024_AddLicenseDocumentToDriver`
- Added `LicenseDocument` column to `Drivers` table (nullable, max 500 chars)

### 2. Document Upload Logic Update
**File**: `RideSharing.API/Controllers/VehiclesController.cs`

Updated the `UploadDocument` method to save license document path:
```csharp
case "license":
case "licence":
    // Update driver's license document
    driver.LicenseDocument = documentUrl;
    driver.LicenseVerified = false;
    await _driverRepository.UpdateDriverAsync(driver);
    break;
```

**Before**: Only set `driver.LicenseNumber = "UPLOADED"` (didn't save document path)
**After**: Saves actual document URL to `driver.LicenseDocument`

### 3. Admin API Response Update
**File**: `RideSharing.API/Controllers/AdminController.cs`

Updated two endpoints to return actual document URLs:

#### GetPendingDrivers
Changed from placeholder:
```csharp
documentUrl = $"https://via.placeholder.com/600x400/1a237e/FFFFFF?text=License+{d.LicenseNumber}"
```

To actual path:
```csharp
drivingLicense = !string.IsNullOrEmpty(d.LicenseDocument) ? new
{
    documentId = d.Id.ToString(),
    documentUrl = d.LicenseDocument,
    documentType = "license",
    uploadedAt = d.CreatedAt,
    status = d.LicenseVerified ? "verified" : "uploaded"
} : null
```

#### GetDriverDetails
Applied the same change to return actual document URLs instead of placeholders.

## Document Storage Structure

Documents are saved in:
```
wwwroot/uploads/verification/{vehicleNumber}/
├── license_20241129123045.jpg
└── rc_20241129123050.pdf
```

## API Response Format

Admin endpoints now return:
```json
{
  "data": {
    "drivers": [
      {
        "id": "guid",
        "fullName": "John Doe",
        "documents": {
          "drivingLicense": {
            "documentId": "guid",
            "documentUrl": "/uploads/verification/MH01AB1234/license_20241129123045.jpg",
            "documentType": "license",
            "uploadedAt": "2024-11-29T12:30:45Z",
            "status": "uploaded"
          },
          "rcBook": {
            "documentId": "guid",
            "documentUrl": "/uploads/verification/MH01AB1234/rc_20241129123050.pdf",
            "documentType": "rc_book",
            "uploadedAt": "2024-11-29T12:30:50Z",
            "status": "uploaded"
          }
        }
      }
    ]
  }
}
```

## Static File Serving

Static files are served from `wwwroot` folder via `app.UseStaticFiles()` in `Program.cs`.

Document URLs like `/uploads/verification/MH01AB1234/license_20241129123045.jpg` will be accessible at:
```
http://localhost:5000/uploads/verification/MH01AB1234/license_20241129123045.jpg
```

## Testing Steps

1. **Backend Ready**: ✅ Migration applied, code compiled successfully
2. **Upload documents**: Use mobile app to upload license and RC documents
3. **Verify storage**: Check `wwwroot/uploads/verification/{vehicleNumber}/` folder
4. **Check database**: Verify `Drivers.LicenseDocument` and `Vehicles.RegistrationDocument` fields are populated
5. **Admin API**: Call `GET /api/v1/admin/drivers/pending` and verify document URLs are returned
6. **Access documents**: Try accessing document URLs in browser (should serve the actual files)

## Notes

- All existing drivers will have `LicenseDocument = NULL` until they re-upload documents
- Document paths are relative (start with `/uploads/...`)
- Static file serving is already configured in `Program.cs`
- Admin dashboard should construct full URL: `${baseUrl}${documentUrl}`

## Related Files Modified

1. `RideSharing.API/Models/Domain/Driver.cs` - Added LicenseDocument field
2. `RideSharing.API/Controllers/VehiclesController.cs` - Updated document upload logic
3. `RideSharing.API/Controllers/AdminController.cs` - Updated API responses
4. Database migration - Added LicenseDocument column
