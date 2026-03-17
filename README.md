![EncQder](assets/thumbnail.png)

# EncQder

> A clean, minimal Flutter app for encoding and decoding QR codes — with offline history, system-adaptive theming, and a gesture-first interface.

*This project is **AI Vibe Coded**, built as a high-fidelity experiment to push the boundaries of [Antigravity](https://google.com) and assist with my personal utility workflows.*

## Why It Exists

EncQder was born from a need for a privacy-first, zero-friction QR tool that doesn't track you. It's a playground for premium Flutter UI patterns and a personal assistant for my daily digital organization.

## What It Does

EncQder gives you three core tools in one swipeable interface:

- **Create** — Type any text or URL to generate a QR code, then save it to your history.
- **Scan** — Point your camera at any QR code to read its raw content — no link-following, no auto-navigation.
- **History** — Browse previously created and scanned QR codes, view their full QR image, or delete them.

All data is stored **locally on your device**. No network calls, no accounts, no tracking.

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or later)
- Android device or emulator (iOS support included)
- For physical device testing: USB debugging enabled

### Run Locally

```bash
git clone https://github.com/your-username/encqder.git
cd encqder
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── main.dart                  # App entry point, theme configuration
├── screens/
│   ├── home_screen.dart       # PageView shell + animated bottom nav
│   ├── input_screen.dart      # Text input → QR generation + save
│   ├── history_screen.dart    # Offline history list + detail modal
│   └── camera_screen.dart     # QR scanner with torch + camera controls
├── services/
│   └── storage_service.dart   # SharedPreferences wrapper for history
└── widgets/
    └── qr_display.dart        # Reusable QR rendering widget
```

## Key Dependencies

| Package | Purpose |
|---|---|
| `qr_flutter` | QR code rendering |
| `mobile_scanner` | Camera-based QR scanning |
| `shared_preferences` | Offline local storage |
| `intl` | Date/time formatting in history |

## Roadmap

See [ROADMAP.md](./ROADMAP.md) for what's been built and what's planned next.
