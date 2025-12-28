# 📱 Allapalli Ride - App Structure Visualization

## Screen Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        APP LAUNCH                                │
└─────────────────────────────────────────────────────────────────┘
                               ↓
┌─────────────────────────────────────────────────────────────────┐
│  SPLASH SCREEN                                                   │
│  • Animated logo with scale + fade                               │
│  • Gradient background (yellow → orange)                         │
│  • Auto-navigate after 3s                                        │
└─────────────────────────────────────────────────────────────────┘
                               ↓
┌─────────────────────────────────────────────────────────────────┐
│  ONBOARDING CAROUSEL                                             │
│  • Page 1: "Book Rides Easily" (Green icon)                     │
│  • Page 2: "Safe & Reliable" (Blue icon)                        │
│  • Page 3: "Affordable Fares" (Yellow icon)                     │
│  • Smooth page indicators                                        │
│  • Skip or swipe through                                         │
└─────────────────────────────────────────────────────────────────┘
                               ↓
┌─────────────────────────────────────────────────────────────────┐
│  LOGIN SCREEN                                                    │
│  • Phone number input (+91)                                      │
│  • 10-digit validation                                           │
│  • "Send OTP" button                                             │
│  • Animated field transitions                                    │
└─────────────────────────────────────────────────────────────────┘
                               ↓
┌─────────────────────────────────────────────────────────────────┐
│  OTP VERIFICATION                                                │
│  • 6-digit PIN code input                                        │
│  • 30-second countdown timer                                     │
│  • Resend OTP option                                             │
│  • Auto-verify on complete                                       │
└─────────────────────────────────────────────────────────────────┘
                               ↓
┌─────────────────────────────────────────────────────────────────┐
│  USER TYPE SELECTION                                             │
│  • Passenger option (person icon)                                │
│  • Driver option (car icon)                                      │
│  • Single tap selection                                          │
│  • Animated card highlighting                                    │
└─────────────────────────────────────────────────────────────────┘
                               ↓
                    ┌──────────┴──────────┐
                    ↓                      ↓
        ╔═══════════════════╗  ╔═══════════════════╗
        ║  PASSENGER APP    ║  ║   DRIVER APP      ║
        ╚═══════════════════╝  ╚═══════════════════╝
                    ↓                      ↓

┌─────────────────────────────┐  ┌─────────────────────────────┐
│  PASSENGER HOME SCREEN      │  │  DRIVER DASHBOARD           │
├─────────────────────────────┤  ├─────────────────────────────┤
│  • Map view (full screen)   │  │  • Map view (full screen)   │
│  • Menu & Notifications     │  │  • Online/Offline toggle    │
│  • Bottom panel:            │  │  • Stats cards:             │
│    - Pickup search          │  │    - Today's rides          │
│    - Dropoff search         │  │    - Today's earnings       │
│    - Vehicle selector:      │  │  • Bottom panel:            │
│      • Auto                 │  │    - Go Online button       │
│      • Bike                 │  │    - Waiting for rides UI   │
│      • Car                  │  │                             │
│      • Shared               │  │                             │
│    - Book Ride button       │  │                             │
└─────────────────────────────┘  └─────────────────────────────┘
         ↓                                  ↓
┌─────────────────────────────┐  ┌─────────────────────────────┐
│  RIDE HISTORY SCREEN        │  │  DRIVER EARNINGS SCREEN     │
├─────────────────────────────┤  ├─────────────────────────────┤
│  • Filter button            │  │  • Date filter button       │
│  • Timeline of rides:       │  │  • Total earnings card      │
│    - Completed rides        │  │  • Stats grid:              │
│    - Cancelled rides        │  │    - Total rides            │
│    - With driver info       │  │    - Rating                 │
│    - Fare displayed         │  │    - Online hours           │
│    - Time stamp             │  │    - Acceptance rate        │
│  • Tap to view details      │  │  • Payout history:          │
│                             │  │    - Weekly payouts         │
│                             │  │    - Status & dates         │
└─────────────────────────────┘  └─────────────────────────────┘
```

---

## Component Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                        SHARED COMPONENTS                        │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  BUTTONS                    INPUT FIELDS                        │
│  ├─ PrimaryButton           ├─ CustomTextField                 │
│  ├─ SecondaryButton         ├─ PasswordField                   │
│  └─ RoundedIconButton       ├─ PhoneField                      │
│                             └─ SearchField                      │
│                                                                 │
│  CARDS                      MODALS                              │
│  ├─ RideCard                ├─ CustomBottomSheet              │
│  └─ DriverInfoCard          ├─ SlideUpModal                   │
│                             └─ CustomAlertDialog               │
│                                                                 │
│  LOADERS                                                        │
│  ├─ AnimatedLoader                                             │
│  ├─ LoadingOverlay                                             │
│  └─ ShimmerLoader                                              │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

---

## Theme System

```
┌────────────────────────────────────────────────────────────────┐
│                         DESIGN TOKENS                           │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  AppColors                  TextStyles                          │
│  ├─ Light Theme            ├─ Display (3 sizes)                │
│  │  ├─ Background          ├─ Heading (3 sizes)                │
│  │  ├─ Surface             ├─ Body (3 sizes)                   │
│  │  ├─ Text (3 levels)     ├─ Label (3 sizes)                  │
│  │  └─ Borders             ├─ Button (3 sizes)                 │
│  └─ Dark Theme             ├─ Caption                           │
│     ├─ Background          └─ Overline                          │
│     ├─ Surface                                                  │
│     ├─ Text (3 levels)     AppSpacing                           │
│     └─ Borders             ├─ Padding (XS → XXL)               │
│                            ├─ Border Radius (XS → Full)         │
│  Semantic Colors           ├─ Icon Sizes (XS → Huge)           │
│  ├─ Success (Green)        ├─ Button Heights (SM → XL)         │
│  ├─ Warning (Yellow)       └─ Avatar Sizes (SM → XXL)          │
│  ├─ Error (Red)                                                 │
│  └─ Info (Blue)                                                 │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

---

## Animation Timeline

```
Screen Load → Components Appear with Stagger

┌─────────────────────────────────────────────────────────────┐
│                                                              │
│  0ms     Header text          FadeIn + SlideX               │
│          ↓                                                   │
│  200ms   Subtitle            FadeIn + SlideX                │
│          ↓                                                   │
│  300ms   Icon/Logo           Scale + FadeIn                 │
│          ↓                                                   │
│  400ms   Input field 1       FadeIn + SlideY                │
│          ↓                                                   │
│  500ms   Input field 2       FadeIn + SlideY                │
│          ↓                                                   │
│  600ms   Button              FadeIn + SlideY                │
│                                                              │
│  All animations: 200-400ms duration                          │
│  Curves: easeOut, elasticOut                                │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## File Organization

```
lib/
├── main.dart                          # App entry, routes, theme
│
├── app/
│   ├── constants/
│   │   └── app_constants.dart         # App-wide constants
│   └── themes/
│       ├── app_colors.dart            # Color system
│       ├── app_spacing.dart           # Spacing system
│       ├── app_theme.dart             # Theme config
│       └── text_styles.dart           # Typography
│
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       └── screens/
│   │           ├── splash_screen.dart             # 1. First screen
│   │           ├── onboarding_screen.dart         # 2. Intro
│   │           ├── login_screen.dart              # 3. Phone input
│   │           ├── otp_verification_screen.dart   # 4. OTP
│   │           └── user_type_selection_screen.dart # 5. Role choice
│   │
│   ├── passenger/
│   │   └── presentation/
│   │       └── screens/
│   │           ├── passenger_home_screen.dart     # Main screen
│   │           └── ride_history_screen.dart       # Past rides
│   │
│   └── driver/
│       └── presentation/
│           └── screens/
│               ├── driver_dashboard_screen.dart   # Main screen
│               └── driver_earnings_screen.dart    # Revenue
│
└── shared/
    └── widgets/
        ├── buttons.dart              # 3 button types
        ├── cards.dart                # 2 card types
        ├── input_fields.dart         # 4 input types
        ├── loaders.dart              # 3 loader types
        └── modals.dart               # 3 modal types
```

---

## State Management Flow (Riverpod)

```
┌──────────────────────────────────────────────────────────────┐
│                      ProviderScope                            │
│                    (Root of app)                              │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│                    Theme Provider                             │
│                  (Light/Dark mode)                            │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│                    Auth Provider                              │
│               (User session state)                            │
│                  [TODO: Implement]                            │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│              Feature-specific Providers                       │
│    • Ride booking provider                                    │
│    • Location provider                                        │
│    • Payment provider                                         │
│    • Notification provider                                    │
│               [TODO: Implement]                               │
└──────────────────────────────────────────────────────────────┘
```

---

## Dependency Graph

```
main.dart
    ↓
app/themes/* ──────────┐
    ↓                  │
shared/widgets/* ──────┼─→ Used by all screens
    ↓                  │
features/*/screens ←───┘
```

---

## Color Scheme Visual

```
LIGHT MODE                    DARK MODE
┌──────────────┐             ┌──────────────┐
│ Background   │ #FAFAFA     │ Background   │ #121212
│ Surface      │ #FFFFFF     │ Surface      │ #1E1E1E
│ Card         │ #FFFFFF     │ Card         │ #2A2A2A
│ Text Primary │ #1A1A1A     │ Text Primary │ #FFFFFF
│ Text Second. │ #666666     │ Text Second. │ #B3B3B3
│ Border       │ #E0E0E0     │ Border       │ #3A3A3A
└──────────────┘             └──────────────┘

BRAND COLORS (Both modes)
┌──────────────┐
│ Primary      │ #FFB800 (Yellow)
│ Secondary    │ #FF8A00 (Orange)
│ Success      │ #00C853 (Green)
│ Error        │ #E53935 (Red)
│ Info         │ #2196F3 (Blue)
└──────────────┘
```

---

## Responsive Design

```
Screen Sizes Supported:
┌────────────────────────────────────┐
│  Small Phone    │ 320-480px        │
│  Medium Phone   │ 481-767px        │
│  Tablet         │ 768-1024px       │
│  Desktop        │ 1024px+          │
└────────────────────────────────────┘

All layouts use:
• Flexible spacing
• Adaptive padding
• Responsive text scaling
• Dynamic component sizing
```

---

**This visualization shows the complete app architecture at a glance!** 📊
