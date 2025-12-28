# Visual Guide: New Admin Dashboard Screens

## 🗺️ Live Tracking Screen

### Layout Structure
```
┌─────────────────────────────────────────────────────────────────────┐
│ 🏠 Dashboard > Live Tracking                                        │
│                                                                     │
│ Live Tracking                                [Quick Stats]         │
│ Real-time driver and vehicle tracking      ┌─────┬─────┬─────┐   │
│                                             │ 🚗1 │ ✓ 1 │ ⚫ 1 │   │
│                                             │Active│Avail│Offline│   │
│                                             └─────┴─────┴─────┘   │
├─────────────────────────────────────────────────────────────────────┤
│                                    │                                │
│                                    │  🔍 [Search drivers...]       │
│                                    │                                │
│         GOOGLE MAP VIEW            │  [All] [Active] [Available]   │
│                                    │  [Offline]                     │
│    🚗 = Active Driver (Green)      │                                │
│    🚕 = Available Driver (Yellow)  │  ┌──────────────────────────┐ │
│    🚙 = Offline Driver (Red)       │  │ 👤 Rajesh Kumar          │ │
│                                    │  │ 🚗 MH 31 AB 1234    🟢   │ │
│  [Zoom controls]                   │  │ 📍 Allapalli to Gadchiroli│ │
│  [My location]                     │  │ 👥 3/5 passengers        │ │
│                                    │  └──────────────────────────┘ │
│                                    │                                │
│                                    │  ┌──────────────────────────┐ │
│                                    │  │ 👤 Amit Sharma           │ │
│                                    │  │ 🚗 MH 31 CD 5678    🟡   │ │
│                                    │  │ ✓ Available              │ │
│                                    │  └──────────────────────────┘ │
│                                    │                                │
└────────────────────────────────────┴────────────────────────────────┘
```

### Features
- **70% Google Maps** - Real-time driver markers with color coding
- **30% Driver List** - Search, filter, and click-to-zoom functionality
- **Status Colors:**
  - 🟢 Green = Active (on ride)
  - 🟡 Yellow = Available (online, no ride)
  - 🔴 Red = Offline
- **Filter Chips:** All, Active, Available, Offline
- **Search:** By name, phone, or vehicle number

---

## 👥 User Management Screen

### Layout Structure
```
┌─────────────────────────────────────────────────────────────────────┐
│ 🏠 Dashboard > User Management                [+ Create Admin User] │
│                                                                     │
│ User Management                                                     │
│ Manage users, drivers, and admin accounts                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│ ┌───────────┬───────────┬───────────┬───────────┐                 │
│ │Total Users│Active Users│  Drivers  │Passengers │                 │
│ │     4     │     3      │     1     │     2     │                 │
│ └───────────┴───────────┴───────────┴───────────┘                 │
│                                                                     │
├─────────────────────────────────────────────────────────────────────┤
│ 🔍 [Search by email or phone...]  [User Type ▼]  [Status ▼]       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ Email                    Phone         Type    Status  Actions  │ │
│ ├─────────────────────────────────────────────────────────────────┤ │
│ │ akhileshallewar880@      +9198765... 🟣ADMIN  🟢ACTIVE  👁️ ⛔  │ │
│ │ gmail.com ✓                                                      │ │
│ ├─────────────────────────────────────────────────────────────────┤ │
│ │ rajesh.kumar@example.com +9198765... 🟡DRIVER 🟢ACTIVE  👁️ ⛔ 🗑️│ │
│ │ ✓                                                                │ │
│ ├─────────────────────────────────────────────────────────────────┤ │
│ │ amit.sharma@example.com  +9198765... 🔵PASS.  🟢ACTIVE  👁️ ⛔ 🗑️│ │
│ │ ✓                                                                │ │
│ ├─────────────────────────────────────────────────────────────────┤ │
│ │ blocked.user@example.com +9198765... 🔵PASS.  🔴BLOCKED 👁️ ✅ 🗑️│ │
│ │                                                                  │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
│ Page 1 of 1 • 4 total users                                        │
└─────────────────────────────────────────────────────────────────────┘
```

### Features
- **Statistics Cards** - Total, Active, Drivers, Passengers count
- **Search & Filter** - By email, phone, user type, status
- **User Type Badges:**
  - 🟣 Purple = Admin
  - 🟡 Yellow = Driver
  - 🔵 Blue = Passenger
- **Status Indicators:**
  - 🟢 Active (with live dot)
  - 🔴 Blocked (with live dot)
- **Actions:**
  - 👁️ View Details
  - ⛔ Block/✅ Unblock
  - 🗑️ Delete (passengers/drivers only)

---

## 📋 Confirmation Modals

### Block User Modal
```
┌──────────────────────────────┐
│ ⚠️ Block User               │
│                              │
│ Are you sure you want to    │
│ block john@example.com?     │
│ They will not be able to    │
│ log in.                     │
│                              │
│        [Cancel]   [Block]   │
└──────────────────────────────┘
```

### Delete User Modal
```
┌──────────────────────────────┐
│ 🗑️ Delete User              │
│                              │
│ Are you sure you want to    │
│ delete john@example.com?    │
│ This action cannot be       │
│ undone.                     │
│                              │
│       [Cancel]   [Delete]   │
└──────────────────────────────┘
```

### Create Admin User Dialog
```
┌──────────────────────────────┐
│ Create Admin User            │
│                              │
│ Email:                       │
│ [                          ] │
│                              │
│ Phone Number:                │
│ [                          ] │
│                              │
│ Password:                    │
│ [                          ] │
│                              │
│ Role:                        │
│ [Admin             ▼]        │
│                              │
│      [Cancel]   [Create]     │
└──────────────────────────────┘
```

---

## 🎨 Color Scheme

### Primary Colors
- **Forest Green (#1B5E20):** Primary actions, active states
- **Vibrant Yellow (#FFB300):** Accents, available states
- **White (#FFFFFF):** Cards, surfaces
- **Light Gray (#F5F5F5):** Background

### Status Colors
- **Green (#4CAF50):** Active, success, available
- **Yellow (#FFB300):** Warning, available driver
- **Red (#F44336):** Error, blocked, offline
- **Purple (#9C27B0):** Admin badge
- **Blue (#2196F3):** Passenger badge

### Text Colors
- **Primary (#212121):** Headings, important text
- **Secondary (#757575):** Body text, labels
- **Hint (#BDBDBD):** Placeholders, disabled

---

## 📐 Responsive Breakpoints

### Desktop (>1024px)
- Full sidebar (250px width)
- Map: 70% | Driver List: 30%
- Table: 7 columns visible
- Stats: 4 cards in row

### Tablet (768-1024px)
- Collapsible sidebar (70px when collapsed)
- Map: 65% | Driver List: 35%
- Table: 6 columns visible
- Stats: 2 cards per row

### Mobile (<768px)
- Drawer navigation
- Map: 100% stacked
- Driver List: Bottom sheet
- Table: Horizontal scroll
- Stats: 1 card per row

---

## 🔄 Navigation Flow

### Main Navigation
```
Sidebar Menu
├── 📊 Dashboard → /dashboard
├── ✓ Driver Verification → /drivers/verification
├── 🚗 Active Rides → /rides/monitoring
├── 🗺️ Live Tracking → /tracking ⭐ NEW
├── 👥 User Management → /users ⭐ NEW
├── 🔔 Notifications → /notifications
├── 📈 Analytics → /analytics
├── 💰 Finance → /finance
└── ⚙️ Settings → /settings
```

### User Management Flow
```
User Management Screen
    │
    ├── Click "View" → User Detail Dialog/Screen
    │
    ├── Click "Block" → Confirmation Modal → API Call → Success Toast
    │
    ├── Click "Unblock" → Confirmation Modal → API Call → Success Toast
    │
    ├── Click "Delete" → Confirmation Modal → API Call → Success Toast
    │
    └── Click "Create Admin" → Dialog Form → API Call → Success Toast
```

### Live Tracking Flow
```
Live Tracking Screen
    │
    ├── Type in Search → Filter drivers in list
    │
    ├── Click Filter Chip → Update map markers + list
    │
    ├── Click Driver Card → Map zooms to driver location
    │
    └── SignalR Update → Update marker position (real-time)
```

---

## 🎯 Key Interactions

### Search Functionality
1. Type in search field
2. Debounce 300ms
3. Filter results by email/phone/vehicle
4. Update table/list instantly

### Filter Chips
1. Click chip to activate
2. Chip changes color (green outline)
3. Results filtered immediately
4. Multiple filters can be active

### Confirmation Modals
1. Click destructive action (Block/Delete)
2. Modal appears with warning
3. Click Cancel → Modal closes, no action
4. Click Confirm → API call → Success/Error message

### Data Table
1. Sortable columns (click header)
2. Horizontal scroll on mobile
3. Row hover highlights
4. Icon buttons for actions

---

## ✅ Accessibility Features

- **Keyboard Navigation:** Tab through all interactive elements
- **Screen Reader Support:** Proper ARIA labels
- **Color Contrast:** WCAG AA compliant
- **Focus Indicators:** Visible focus rings
- **Error Messages:** Clear, descriptive text
- **Tooltips:** On hover for icon buttons

---

**Implementation Date:** December 25, 2024  
**Designer:** AI-Assisted (Shiprocket-Inspired)  
**Framework:** Flutter Web + Material Design 3
