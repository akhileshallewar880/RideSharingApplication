# Location Management UI Guide 🎨

## Screen Layout

```
┌─────────────────────────────────────────────────────────────────────┐
│ Admin Panel - Locations Management                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │ Total Locations  │  │      Active      │  │ With Coordinates │  │
│  │       150        │  │       145        │  │       142        │  │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ 🔍 Search by name, district, state, or pincode...           │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  [Filter ▼] [🔄 Refresh] [➕ Add Location]                          │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Name      │ District  │ State  │ Pincode │ Lat    │ Lng    │  │
│  ├──────────────────────────────────────────────────────────────┤  │
│  │ Allapalli │ Gadchiroli│ MH     │ 441702  │19.9167 │79.3167 │✏️🗑️│
│  │ Mumbai    │ Mumbai    │ MH     │ 400001  │19.0760 │72.8777 │✏️🗑️│
│  │ Nagpur    │ Nagpur    │ MH     │ 440001  │21.1458 │79.0882 │✏️🗑️│
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│              ◀ Page 1 of 3 ▶                                        │
└─────────────────────────────────────────────────────────────────────┘
```

## Add/Edit Location Dialog

```
┌─────────────────────────────────────────────┐
│ Add Location                            ✕   │
├─────────────────────────────────────────────┤
│                                             │
│  Location Name *                            │
│  ┌─────────────────────────────────────┐   │
│  │ Allapalli                           │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  State *                                    │
│  ┌─────────────────────────────────────┐   │
│  │ Maharashtra                         │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  District *                                 │
│  ┌─────────────────────────────────────┐   │
│  │ Gadchiroli                          │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  Pincode                                    │
│  ┌─────────────────────────────────────┐   │
│  │ 441702                              │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  Latitude *      Longitude *                │
│  ┌────────────┐  ┌────────────┐            │
│  │ 19.9167    │  │ 79.3167    │            │
│  └────────────┘  └────────────┘            │
│                                             │
│  ☐ Active                                   │
│                                             │
│         [Cancel]  [Save]                    │
└─────────────────────────────────────────────┘
```

## Statistics Cards

The statistics cards at the top provide quick insights:

**Total Locations**: Shows the total number of locations in the system
- Color: Blue
- Includes both active and inactive

**Active**: Number of currently active locations
- Color: Green
- Only locations with `IsActive = true`

**With Coordinates**: Locations that have latitude and longitude set
- Color: Orange
- Important for mapping and distance calculations

## Data Table Columns

| Column | Description | Format |
|--------|-------------|--------|
| **Name** | Location name | Text |
| **District** | District name | Text |
| **State** | State name | Text |
| **Pincode** | Postal code | Text (6 digits) |
| **Latitude** | Coordinate | Decimal (6 places) |
| **Longitude** | Coordinate | Decimal (6 places) |
| **Status** | Active/Inactive | Badge (Green/Red) |
| **Actions** | Edit/Delete | Icon buttons |

## Status Badge Colors

```
┌──────────┐     ┌──────────┐
│  Active  │     │ Inactive │
└──────────┘     └──────────┘
 Green bg         Red bg
 Dark green       Dark red
 text             text
```

## Form Validation

### Required Fields
- ✅ Location Name: Cannot be empty
- ✅ State: Cannot be empty
- ✅ District: Cannot be empty
- ✅ Latitude: Must be between -90 and 90
- ✅ Longitude: Must be between -180 and 180

### Optional Fields
- Pincode: Can be empty or 6 digits
- Active Status: Defaults to true for new locations

### Validation Messages
- "Please enter location name"
- "Please enter state"
- "Please enter district"
- "Invalid latitude" (if outside -90 to 90)
- "Invalid longitude" (if outside -180 to 180)

## Action Buttons

### Main Screen Actions

**🔍 Search Box**
- Searches across: name, district, state, pincode
- Real-time filtering
- Press Enter to search

**Filter Dropdown**
- Options:
  - "All" - Show all locations
  - "Active" - Show only active
  - "Inactive" - Show only inactive

**🔄 Refresh**
- Reloads location data
- Updates statistics
- Resets to page 1

**➕ Add Location**
- Opens add location dialog
- Form starts empty
- All fields ready for input

### Row Actions

**✏️ Edit**
- Opens edit dialog
- Pre-filled with current data
- Can modify any field
- Can toggle active status

**🗑️ Delete**
- Shows confirmation dialog
- Cannot delete if used by drivers
- Permanently removes location

## Pagination

```
◀ Page 1 of 3 ▶

Left Arrow: Previous page (disabled on page 1)
Right Arrow: Next page (disabled on last page)
Shows: Current page / Total pages
```

- Shows 50 locations per page
- Automatically calculates total pages
- Disabled buttons when at boundaries

## Color Scheme

### Primary Colors
- **Green (#4CAF50)**: Primary buttons, active status
- **Red (#F44336)**: Delete button, inactive status
- **Blue (#2196F3)**: Statistics, info
- **Orange (#FF9800)**: Warning, coordinate statistics

### UI Colors
- **Background**: Light gray (#F5F5F5)
- **Cards**: White (#FFFFFF)
- **Borders**: Light gray (#E0E0E0)
- **Text**: Dark gray (#333333)
- **Secondary Text**: Medium gray (#666666)

## Responsive Behavior

### Desktop (> 1200px)
- Full table visible
- All columns displayed
- Statistics cards in one row
- Sidebar always visible

### Tablet (768px - 1200px)
- Horizontal scroll for table
- All columns maintained
- Statistics cards may stack
- Collapsible sidebar

### Mobile (< 768px)
- Drawer navigation
- Horizontal scroll required
- Consider card view (future enhancement)

## Success/Error Messages

### Success Messages (Green Snackbar)
- "Location created successfully"
- "Location updated successfully"
- "Location deleted successfully"

### Error Messages (Red Snackbar)
- "Error creating location: [details]"
- "Error updating location: [details]"
- "Cannot delete location as it is being used by one or more drivers"
- "Location not found"
- "A location with this name, district, and state already exists"

## Loading States

### Initial Load
- Shows CircularProgressIndicator in center
- Blocks table area
- Statistics load separately

### Refresh
- Brief loading indicator
- Table remains visible
- Data updates smoothly

### Save Operation
- Button shows small spinner
- Dialog stays open
- Disables form interaction

## Empty States

### No Locations
```
┌─────────────────────────┐
│                         │
│   No locations found    │
│                         │
└─────────────────────────┘
```

### Search Results Empty
```
┌─────────────────────────┐
│                         │
│   No locations found    │
│   matching your search  │
│                         │
└─────────────────────────┘
```

### Error State
```
┌─────────────────────────┐
│         ⚠️              │
│  Error loading data     │
│                         │
│      [Retry]            │
└─────────────────────────┘
```

## Keyboard Shortcuts

- **Enter** in search box: Triggers search
- **Tab**: Navigate between form fields
- **Escape**: Close dialogs
- **R**: Hot reload (in development)

## Data Flow

```
User Action
    ↓
UI Component
    ↓
LocationService
    ↓
HTTP Request
    ↓
Backend API (AdminLocationsController)
    ↓
Database (City table)
    ↓
Response
    ↓
Update UI
```

## Best Practices

### Adding Locations
1. Use accurate coordinates from Google Maps
2. Standardize state names (e.g., "Maharashtra" not "MH")
3. Use full district names
4. Keep location names consistent
5. Verify coordinates before saving

### Editing Locations
1. Only change what needs updating
2. Document major coordinate changes
3. Be careful with locations used by drivers
4. Test changes in a staging environment first

### Deleting Locations
1. Check if location is in use
2. Consider deactivating instead of deleting
3. Have a backup before mass deletions
4. Communicate changes to drivers

---

**UI Status**: ✅ Fully Implemented  
**Theme**: Material Design with custom colors  
**Framework**: Flutter Web  
**Responsiveness**: Desktop-first, tablet-friendly  

Press 'R' in the Flutter terminal to hot restart and see the new Locations screen!
