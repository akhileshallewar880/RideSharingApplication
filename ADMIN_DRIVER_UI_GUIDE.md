# 🎨 Admin Driver Management - Visual Guide

## User Management Screen Layout

```
┌─────────────────────────────────────────────────────────────────────┐
│  Dashboard > User Management                                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  User Management                    [🚗 Register Driver] [+ Create  │
│  Manage users, drivers, and admin              Admin User]           │
│                                                                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐       │
│  │ Total     │  │ Active    │  │ Drivers   │  │ Passengers│       │
│  │ Users: 4  │  │ Users: 3  │  │ 1         │  │ 2         │       │
│  └───────────┘  └───────────┘  └───────────┘  └───────────┘       │
│                                                                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  🔍 Search: [________________]  Type: [All ▼]  Status: [All ▼]     │
│                                                                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Email                    Phone         Type      Status   Actions  │
│  ──────────────────────────────────────────────────────────────     │
│  akhileshallewar...      +919876...    ADMIN     🟢 ACTIVE  👁️     │
│  rajesh.kumar...         +919876...    DRIVER    🟢 ACTIVE  👁️⛔🗑️ │
│  amit.sharma...          +919876...    PASSENGER 🟢 ACTIVE  👁️⛔🗑️ │
│  blocked.user...         +919876...    PASSENGER 🔴 BLOCKED 👁️✅🗑️ │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

## New Features Highlighted

### 1. Register Driver Button
```
Location: Top right corner (before Create Admin User)
Color: Yellow (AdminTheme.accentColor)
Icon: 🚗 (local_taxi)
Text: "Register Driver"
```

### 2. Enhanced Block/Unblock
```
Active User → Click ⛔ → Block Dialog with Reason
Blocked User → Click ✅ → Unblock Confirmation
```

---

## Register Driver Dialog

```
┌─────────────────────────────────────────────────────────────┐
│  🚗 Register New Driver                                  [×] │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Personal Information                                         │
│  ─────────────────────                                        │
│                                                               │
│  👤 Full Name *                                              │
│  ├─────────────────────────────────────┤                     │
│  │ Enter driver's full name            │                     │
│  └─────────────────────────────────────┘                     │
│                                                               │
│  📧 Email *                                                  │
│  ├─────────────────────────────────────┤                     │
│  │ driver@example.com                  │                     │
│  └─────────────────────────────────────┘                     │
│                                                               │
│  📱 Phone Number *                                           │
│  ├─────────────────────────────────────┤                     │
│  │ 9876543210                           │                     │
│  └─────────────────────────────────────┘                     │
│                                                               │
│  🔒 Password *                                               │
│  ├─────────────────────────────────────┤                     │
│  │ ••••••••                            │                     │
│  └─────────────────────────────────────┘                     │
│                                                               │
│  License Information                                          │
│  ─────────────────────                                        │
│                                                               │
│  💳 License Number *                                         │
│  ├─────────────────────────────────────┤                     │
│  │ MH1234567890                         │                     │
│  └─────────────────────────────────────┘                     │
│                                                               │
│  Additional Information                                       │
│  ─────────────────────────                                    │
│                                                               │
│  📍 Address (Optional)                                       │
│  ├─────────────────────────────────────┤                     │
│  │ Street address, city, state         │                     │
│  │                                      │                     │
│  └─────────────────────────────────────┘                     │
│                                                               │
│  🚨 Emergency Contact (Optional)                            │
│  ├─────────────────────────────────────┤                     │
│  │ 9876543210                           │                     │
│  └─────────────────────────────────────┘                     │
│                                                               │
├─────────────────────────────────────────────────────────────┤
│                                      [Cancel] [✓ Register]   │
└─────────────────────────────────────────────────────────────┘
```

**Colors:**
- Header: Default with taxi icon
- Register Button: Yellow (#FFB300)
- Border Radius: 8px
- Max Width: 500px

---

## Block User Dialog (Enhanced)

```
┌─────────────────────────────────────────────────────────────┐
│  Block User                                              [×] │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Are you sure you want to block amit.sharma@example.com?    │
│                                                               │
│  Reason for blocking                                         │
│  ├─────────────────────────────────────┤                     │
│  │ Enter reason (optional)             │                     │
│  │                                      │                     │
│  │                                      │                     │
│  └─────────────────────────────────────┘                     │
│                                                               │
├─────────────────────────────────────────────────────────────┤
│                                      [Cancel] [Block User]   │
└─────────────────────────────────────────────────────────────┘
```

**Features:**
- Multi-line text field for reason
- Optional reason (can be left empty)
- Red "Block User" button
- Reason is stored with user record

---

## Unblock User Dialog

```
┌─────────────────────────────────────────────────────────────┐
│  Unblock User                                            [×] │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Are you sure you want to unblock blocked.user@example.com? │
│  They will regain access.                                    │
│                                                               │
├─────────────────────────────────────────────────────────────┤
│                                      [Cancel] [Unblock]      │
└─────────────────────────────────────────────────────────────┘
```

**Features:**
- Simple confirmation
- No reason required
- Green confirmation for unblocking

---

## User Table Status Badges

### Driver Badge
```
┌──────────┐
│ 🚗 DRIVER│  ← Yellow background (#FFB300 with 0.1 opacity)
└──────────┘    Yellow text
```

### Status Indicators
```
🟢 ACTIVE      ← Green badge for active users
🔴 BLOCKED     ← Red badge for blocked users
⚪ PENDING     ← Gray badge for pending verification (drivers)
```

### Action Icons
```
👁️ View Details    ← Blue
⛔ Block User      ← Red (only for active users)
✅ Unblock User    ← Green (only for blocked users)
🗑️ Delete User    ← Red (not for admin users)
```

---

## Success Toast Messages

### Register Driver
```
┌─────────────────────────────────────────┐
│ ✓ Driver John Doe registered successfully│
└─────────────────────────────────────────┘
Background: Green (#4CAF50)
Duration: 3 seconds
```

### Block User
```
┌─────────────────────────────────────────┐
│ ✓ User blocked successfully              │
└─────────────────────────────────────────┘
```

### Unblock User
```
┌─────────────────────────────────────────┐
│ ✓ User unblocked successfully            │
└─────────────────────────────────────────┘
```

---

## Color Scheme

**Primary Actions (Register Driver):**
- Button: `#FFB300` (Vibrant Yellow)
- Hover: `#FFD54F` (Light Yellow)
- Text: White

**Secondary Actions (Create Admin):**
- Button: `#1B5E20` (Forest Green)
- Hover: `#4CAF50` (Light Green)
- Text: White

**Destructive Actions (Block, Delete):**
- Button/Icon: `#F44336` (Red)
- Hover: `#EF5350` (Light Red)

**Success:**
- Badge: `#4CAF50` (Green)
- Toast: `#4CAF50` (Green)

**Warning:**
- Badge: `#FFB300` (Yellow)

**Neutral:**
- Badge: `#9E9E9E` (Gray)

---

## Responsive Behavior

### Desktop (1200px+)
- Dialog width: 500px
- Buttons side-by-side
- Full table visible

### Tablet (768px - 1199px)
- Dialog width: 90%
- Buttons side-by-side
- Horizontal scroll for table

### Mobile (< 768px)
- Dialog width: 95%
- Buttons stacked
- Table in card view

---

## Form Validation

### Required Fields (marked with *)
- Full Name
- Email
- Phone Number
- Password
- License Number

### Validation Rules
```
✓ Name: Minimum 2 characters
✓ Email: Valid email format (xxx@xxx.xxx)
✓ Phone: 10 digits (numeric only)
✓ Password: Minimum 8 characters
✓ License: Minimum 8 characters (alphanumeric)
```

### Error Messages
```
❌ "Please fill all required fields"
   → When any required field is empty

❌ "Invalid email format"
   → When email is not valid

❌ "Password must be at least 8 characters"
   → When password is too short
```

---

## API Integration Points

### Frontend → Backend Mapping

**Register Driver:**
```dart
AdminDriverService.registerDriver()
  ↓
POST /api/v1/AdminDriver/register
  ↓
Creates: User + UserProfile + Driver
```

**Block Driver:**
```dart
AdminDriverService.blockDriver()
  ↓
PUT /api/v1/AdminDriver/{driverId}/block
  ↓
Updates: User.IsActive, User.IsBlocked, Driver.IsOnline
```

**Get Drivers:**
```dart
AdminDriverService.getDrivers()
  ↓
GET /api/v1/AdminDriver?status=all&page=1
  ↓
Returns: List of drivers with pagination
```

---

## User Flow Diagram

### Register Driver Flow
```
Admin clicks "Register Driver"
    ↓
Dialog opens with form
    ↓
Admin fills required fields
    ↓
Admin clicks "Register Driver"
    ↓
Validation check
    ├─ Invalid → Show error message
    └─ Valid ↓
API call to backend
    ├─ Success ↓
    │   - Close dialog
    │   - Show success toast
    │   - Refresh user list
    └─ Error ↓
        - Show error toast
        - Keep dialog open
```

### Block Driver Flow
```
Admin clicks ⛔ on active user
    ↓
Block dialog opens
    ↓
Admin enters reason (optional)
    ↓
Admin clicks "Block User"
    ↓
API call to backend
    ├─ Success ↓
    │   - Close dialog
    │   - Update user status to BLOCKED
    │   - Change icon to ✅
    │   - Show success toast
    └─ Error ↓
        - Show error toast
        - Revert status
```

---

## Testing Checklist

### ✅ Visual Tests
- [ ] Register Driver button appears (yellow, with taxi icon)
- [ ] Dialog opens on button click
- [ ] All form fields render correctly
- [ ] Form validation shows errors
- [ ] Success toast appears after registration
- [ ] Block dialog shows reason field
- [ ] Unblock dialog is simple confirmation
- [ ] Status badges display correct colors
- [ ] Action icons appear for correct user types

### ✅ Functional Tests
- [ ] Can register new driver with all fields
- [ ] Can register driver with only required fields
- [ ] Cannot submit with missing required fields
- [ ] Can block user with reason
- [ ] Can block user without reason
- [ ] Can unblock user
- [ ] Status updates in real-time
- [ ] Toast messages display correctly

### ✅ Integration Tests
- [ ] API call succeeds for register
- [ ] API call succeeds for block
- [ ] API call succeeds for unblock
- [ ] Error handling works for failed API calls
- [ ] Loading states show during API calls

---

## Summary

**New UI Components:**
1. 🚗 **Register Driver** button (yellow, top right)
2. 📝 **Register Driver** dialog (comprehensive form)
3. 🚫 **Enhanced Block** dialog (with reason field)
4. ✅ **Simple Unblock** dialog (confirmation only)

**Key Features:**
- Clean, professional design
- Comprehensive form validation
- Clear visual feedback
- Responsive layout
- Consistent color scheme
- User-friendly error messages

**Next Steps:**
- Wire up API calls
- Add loading indicators
- Test on different screen sizes
- Add keyboard shortcuts (ESC to close, ENTER to submit)
