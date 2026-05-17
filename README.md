# pump_alignment

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


App Launch
│
▼
_init() reads SharedPrefs + fetchDeviceStatus()
│
├─ isLoading = true  ──────────────► SplashScreen
│
├─ isUnlocked = false, !hasStartedTrial ──► PaywallScreen [Stage 1]
│       │
│       ▼ user taps "Generate Trial License Key"
│   startTrial() → API → hasStartedTrial=true, trialCount=5
│       │
│       ▼ isUnlocked = true
│
├─ isUnlocked = true ─────────────────► CalculatorScreen
│       │
│       ▼ user taps Calculate (×5)
│   consumeTrialAndCheck() → trialCount decrements
│       │
│       ▼ trialCount = 0 → isUnlocked = false
│
└─ isUnlocked = false, hasStartedTrial=true ─► PaywallScreen [Stage 3]
│
▼ Payment pressed
simulateMockPayment() → isPremium=true → isUnlocked=true
│
▼ CalculatorScreen (permanent)
