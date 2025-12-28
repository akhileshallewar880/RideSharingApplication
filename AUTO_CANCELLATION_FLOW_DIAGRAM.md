# Auto-Cancellation Flow Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Auto-Cancellation System                     │
└─────────────────────────────────────────────────────────────────┘

┌────────────────────────────┐
│  Background Service        │
│  (RideAutoCancellation)    │
│  • Runs every 5 minutes    │
│  • Grace period: 15 min    │
└────────────┬───────────────┘
             │
             │ Checks for expired rides
             ▼
┌────────────────────────────┐
│  Database Query            │
│  WHERE Status IN           │
│  ('scheduled','upcoming')  │
│  AND Time Passed           │
└────────────┬───────────────┘
             │
             │ Found expired rides?
             ▼
       ┌─────┴─────┐
       │   YES     │   NO → Wait 5 minutes
       └─────┬─────┘
             │
             ▼
┌────────────────────────────┐
│  Update Ride               │
│  • Status = 'cancelled'    │
│  • Add reason              │
│  • Set timestamp           │
└────────────┬───────────────┘
             │
             ▼
┌────────────────────────────┐
│  Update Bookings           │
│  • Status = 'cancelled'    │
│    or 'refunded'           │
│  • CancellationType =      │
│    'system'                │
└────────────┬───────────────┘
             │
             ▼
┌────────────────────────────┐
│  Send Notifications        │
│  • To Driver               │
│  • To All Passengers       │
└────────────┬───────────────┘
             │
             ▼
┌────────────────────────────┐
│  Log Results               │
│  • Rides cancelled         │
│  • Bookings cancelled      │
│  • Refunds initiated       │
└────────────────────────────┘
```

---

## Timeline Flow

```
Scheduled Time: 10:00 AM
Grace Period: 15 minutes
Current Time: 10:20 AM

Timeline:
─────────────────────────────────────────────────────────>
        10:00 AM           10:15 AM          10:20 AM
           │                  │                 │
        Scheduled        Grace Period      Auto-Cancel
         Time              Ends             Triggered
           │                  │                 │
           │◄────15 min─────►│                 │
           │                  │                 │
           │                  │                 ▼
           │                  │         ┌───────────────┐
           │                  │         │ Ride Status:  │
           │                  │         │ 'cancelled'   │
           │                  │         └───────────────┘
```

---

## Status State Machine

### Ride Status Flow

```
      ┌─────────────┐
      │  scheduled  │
      └──────┬──────┘
             │
             │ Time approaching
             ▼
      ┌─────────────┐
      │   upcoming  │
      └──────┬──────┘
             │
       ┌─────┴──────┐
       │            │
  Driver     Scheduled time + grace
  starts        period passed
       │            │
       ▼            ▼
┌──────────┐  ┌────────────┐
│  active  │  │ cancelled  │
└────┬─────┘  └────────────┘
     │
     │ Ride completed
     ▼
┌──────────┐
│completed │
└──────────┘
```

### Booking Status Flow

```
      ┌─────────────┐
      │   pending   │
      └──────┬──────┘
             │
             │ Payment confirmed
             ▼
      ┌─────────────┐
      │  confirmed  │
      └──────┬──────┘
             │
       ┌─────┴──────┐
       │            │
    Driver      Auto-cancel
    starts       triggered
       │            │
       ▼            ▼
┌──────────┐  ┌────────────┐
│  active  │  │ cancelled/ │
└────┬─────┘  │  refunded  │
     │        └────────────┘
     │ Ride completed
     ▼
┌──────────┐
│completed │
└──────────┘
```

---

## Decision Tree

```
Is ride expired?
│
├─ YES: Is status 'scheduled' or 'upcoming'?
│       │
│       ├─ YES: Cancel the ride
│       │       │
│       │       └─ Are there bookings?
│       │           │
│       │           ├─ YES: For each booking:
│       │           │       │
│       │           │       └─ Is payment 'paid'?
│       │           │           │
│       │           │           ├─ YES: Status = 'refunded'
│       │           │           │       PaymentStatus = 'refunded'
│       │           │           │       → Initiate refund process
│       │           │           │
│       │           │           └─ NO:  Status = 'cancelled'
│       │           │                   PaymentStatus = unchanged
│       │           │
│       │           └─ NO: Just cancel ride
│       │
│       └─ NO: Skip (already completed/cancelled)
│
└─ NO: Skip (ride is still valid)
```

---

## Notification Flow

```
┌──────────────────┐
│ Ride Cancelled   │
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌────────────────┐
│Driver  │ │  Passengers    │
└───┬────┘ └───┬────────────┘
    │          │
    ▼          ▼
┌────────────────────────────┐
│ "Ride DR2401 cancelled..."│
└────────────────────────────┘

┌────────────────────────────────────┐
│ "Booking ALR2401234 cancelled..." │
│ + Refund info (if applicable)     │
└────────────────────────────────────┘
```

---

## Database Transaction Flow

```
BEGIN TRANSACTION
  │
  ├─► UPDATE Rides
  │   SET Status = 'cancelled',
  │       CancellationReason = '...',
  │       UpdatedAt = NOW()
  │   WHERE Status IN ('scheduled', 'upcoming')
  │     AND (conditions met)
  │
  ├─► UPDATE Bookings
  │   SET Status = CASE WHEN ... THEN 'refunded' ELSE 'cancelled' END,
  │       CancellationType = 'system',
  │       CancellationReason = '...',
  │       CancelledAt = NOW(),
  │       PaymentStatus = CASE WHEN ... THEN 'refunded' ELSE ... END
  │   WHERE RideId IN (cancelled rides)
  │     AND Status NOT IN ('completed', 'cancelled', 'refunded')
  │
  ├─► INSERT INTO Notifications
  │   (driver notifications)
  │
  ├─► INSERT INTO Notifications
  │   (passenger notifications)
  │
COMMIT TRANSACTION
  │
  └─► Log Results
```

---

## Mobile App Response Flow

```
User Opens App
      │
      ▼
┌─────────────────┐
│ Fetch Rides/    │
│ Bookings        │
└────────┬────────┘
         │
         ▼
   Status = 'cancelled'?
         │
    ┌────┴────┐
    │   YES   │   NO → Display normally
    └────┬────┘
         │
         ▼
┌────────────────────┐
│ Display Cancelled  │
│ UI with Reason     │
└────────┬───────────┘
         │
         ▼
   CancellationType = 'system'?
         │
    ┌────┴────┐
    │   YES   │   NO → Show user/driver cancelled
    └────┬────┘
         │
         ▼
┌────────────────────┐
│ Show Auto-Cancel   │
│ Message            │
└────────┬───────────┘
         │
         ▼
   PaymentStatus = 'refunded'?
         │
    ┌────┴────┐
    │   YES   │   NO → End
    └────┬────┘
         │
         ▼
┌────────────────────┐
│ Show Refund Info   │
│ & Timeline         │
└────────────────────┘
```

---

## Configuration Impact

```
appsettings.json
│
├─ Enabled: true/false
│  │
│  ├─ true  → Service runs
│  └─ false → Service disabled
│
├─ CheckIntervalMinutes: 5
│  │
│  └─ Determines how often checks occur
│     (affects responsiveness vs. load)
│
├─ GracePeriodMinutes: 15
│  │
│  └─ Affects when cancellation triggers
│     (shorter = stricter, longer = lenient)
│
├─ EnableNotifications: true/false
│  │
│  ├─ true  → Users notified
│  └─ false → Silent cancellation
│
└─ EnableAutoRefund: true/false
   │
   ├─ true  → Paid bookings marked for refund
   └─ false → Manual refund process
```

---

## Error Handling Flow

```
Try Execute
   │
   ├─► Database Connection Error
   │   └─► Log Error → Retry on next cycle
   │
   ├─► Transaction Error
   │   └─► Rollback → Log Error → Retry
   │
   ├─► Notification Error
   │   └─► Log Warning → Continue (non-critical)
   │
   └─► Success
       └─► Log Success → Wait for next cycle
```

---

## Performance Optimization

```
┌───────────────────────────┐
│ Indexed Query             │
│ IX_Rides_Status_TravelDate│
└─────────┬─────────────────┘
          │
          ▼
┌───────────────────────────┐
│ Fast Lookup (~5-10ms)     │
└─────────┬─────────────────┘
          │
          ▼
┌───────────────────────────┐
│ Batch Update (Transaction)│
└─────────┬─────────────────┘
          │
          ▼
┌───────────────────────────┐
│ Async Notifications       │
│ (Non-blocking)            │
└───────────────────────────┘
```

---

## Deployment Checklist

```
□ RideAutoCancellationService.cs created
□ Service registered in Program.cs
□ appsettings.json updated with config
□ Database indexes created
□ SQL stored procedure deployed (optional)
□ Mobile app updated to handle statuses
□ App constants updated
□ Notification handlers implemented
□ Testing completed
□ Monitoring/logging configured
□ Documentation reviewed
□ Stakeholders informed
```
