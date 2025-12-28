# Seat Selection UI Flow

## Checkout Screen Layout

```
┌─────────────────────────────────────────┐
│  Passenger Information                  │
│  Pickup → Dropoff              [Timer]  │
├─────────────────────────────────────────┤
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  Trip Summary Card                 │ │
│  │  - Driver info                     │ │
│  │  - Vehicle details                 │ │
│  │  - Route map                       │ │
│  │  - Seat counter (+/-)              │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  🪑 Select Your Seats (Optional) ▼ │ │  ← NEW!
│  │  Choose specific seats...          │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  ❤️ Donate to NGO                 │ │
│  │  Add ₹5 optional donation          │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  🎟️ Apply Coupon                  │ │
│  │  Enter coupon code                 │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  💳 Payment Methods               │ │
│  │  Cash / UPI / Card                 │ │
│  └───────────────────────────────────┘ │
│                                         │
├─────────────────────────────────────────┤
│  Total: ₹1650    [Confirm Booking] ✓  │
└─────────────────────────────────────────┘
```

## Expanded Seat Selection View

```
┌─────────────────────────────────────────┐
│  🪑 Select Your Seats (Optional)    ▲  │
│  2 seat(s) selected                    │
├─────────────────────────────────────────┤
│                                         │
│           ┌───┐                         │
│           │ 🚗 │  ← Driver               │
│           └───┘                         │
│                                         │
│      ┌───┐  ┌───┐  ┌───┐              │
│      │   │  │   │  │   │  Row 1        │
│      │   │  │   │  │   │               │
│      │550│  │550│  │550│               │
│      └───┘  └───┘  └───┘              │
│                                         │
│      ┌───┐  ┌───┐  ┌───┐              │
│      │ 👤│  │   │  │   │  Row 2        │
│      │   │  │   │  │   │               │
│      │   │  │550│  │550│               │
│      └───┘  └───┘  └───┘              │
│      BLUE   GREEN  GREEN               │
│                                         │
│      ┌───┐  ┌───┐  ┌───┐              │
│      │   │  │Sold│ │ ♀ │  Row 3        │
│      │   │  │   │  │   │               │
│      │550│  │   │  │550│               │
│      └───┘  └───┘  └───┘              │
│      GREEN   RED   PINK                │
│                                         │
│  Legend:                                │
│  🟢 Available  🔵 Selected              │
│  🔴 Sold       🩷 Female                │
│                                         │
│  ℹ️ Seat selection is optional. If you │
│     skip, seats will be assigned        │
│     automatically.                      │
│                                         │
└─────────────────────────────────────────┘
```

## Seat Colors & States

### Available Seats (Green)
- Background: `Colors.green[500]`
- Border: `Colors.green[700]`
- Shows: `₹550` (price per seat)
- Icon: `Icons.event_seat`
- Action: Tap to select

### Selected Seats (Blue)
- Background: `Colors.blue[500]`
- Border: `Colors.blue[700]`
- Shows: `₹550`
- Icon: `Icons.person` (user icon)
- Action: Tap to deselect

### Booked/Sold Seats (Red)
- Background: `Colors.red[100]`
- Border: `Colors.red[300]`
- Shows: `"Sold"`
- Icon: `Icons.event_seat`
- Action: Shows "already booked" message

### Female-Only Seats (Pink)
- Background: `Colors.pink[100]`
- Border: `Colors.pink[300]`
- Shows: `₹550`
- Icon: `Icons.female`
- Action: Tap to select (if female passenger)

## Interaction Flow

1. **Collapsed State (Default)**
   ```
   🪑 Select Your Seats (Optional)  ▼
   Choose specific seats for your journey
   ```
   - Single line with expand arrow
   - Subtle hint text

2. **Expanded State**
   ```
   🪑 Select Your Seats (Optional)  ▲
   2 seat(s) selected
   [Full seat grid display]
   [Legend]
   [Info message]
   ```
   - Full seat layout visible
   - Shows selection count
   - Interactive seat grid

3. **Selection Actions**
   - **Tap Available Seat**: Turns blue, adds to selection
   - **Tap Selected Seat**: Turns green, removes from selection
   - **Tap Booked Seat**: Red snackbar: "This seat is already booked"
   - **Exceed Limit**: Orange snackbar: "Maximum X seats can be selected"

4. **Booking Behavior**
   - **With Selection**: Passes selected seat IDs to backend
   - **Without Selection**: Passes `null`, backend auto-assigns
   - Both scenarios work seamlessly

## Code Locations

### Widget Creation
```dart
// File: compact_seat_widget.dart
CompactSeatSelectionWidget(
  seatingLayoutJson: widget.ride.seatingLayout,
  bookedSeats: widget.ride.bookedSeats ?? [],
  maxSelectableSeats: _passengerCount,
  pricePerSeat: widget.ride.pricePerSeat,
  onSeatsSelected: (selectedSeats) {
    setState(() => _selectedSeats = selectedSeats);
  },
)
```

### Integration in Checkout
```dart
// File: ride_checkout_screen.dart
// Lines ~223-237 (in body)
if (widget.ride.seatingLayout != null && 
    widget.ride.seatingLayout!.isNotEmpty)
  _buildSeatSelectionSection(isDark),
```

### Booking with Seats
```dart
// File: ride_checkout_screen.dart
// Lines ~1531 (in _processPayment)
selectedSeats: _selectedSeats.isEmpty ? null : _selectedSeats,
```

## Responsive Design

- **Seat Tile Size**: 70px × 80px
- **Spacing**: 8px between seats (horizontal)
- **Margin**: 4px per seat
- **Container**: Full-width with 16px padding
- **Background**: Grey[100] with rounded corners

## Accessibility

- ✅ Clear visual indicators (color + text)
- ✅ Icon-based status (works without color)
- ✅ Tap targets: 70×80px (large enough)
- ✅ Feedback: Snackbar messages for errors
- ✅ Optional feature: Users not forced to use it

---

**Designer Note**: This implementation closely matches the provided screenshot while adding improvements like legends, info messages, and better state management.
