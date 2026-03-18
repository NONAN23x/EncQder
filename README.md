![EncQder Banner](assets/feature_graphic.png)

# EncQder

> A privacy-first, zero-friction QR tool that doesn't track you, built with a premium, gesture-first Flutter interface.

*This project is **AI Vibe Coded**, built as a high-fidelity experiment to push the boundaries of [Antigravity](https://google.com) and assist with my personal utility workflows.*

## Why It Exists

EncQder was born from a need for a beautiful, simple, and private QR tool. It's a playground for premium Flutter UI patterns and a personal assistant for my daily digital organization.

## What It Does

EncQder gives you three core tools in one swipeable interface:

- **Create** — Type any text or URL to generate a custom-styled QR code with an auto-incrementing label.
- **Scan** — Point your camera at any QR code to instantly read its content and save it to your local history.
- **History** — Browse entries with custom labels, view high-res QR renders, and access a **Smart Share Sheet** for native sharing or gallery saving.
- **Privacy-First** — All data is stored **locally on your device**. No network calls, no accounts, no tracking.

## Premium UX Features

- **Dynamic Material You QR Codes** — QR codes are rendered with a subtle radial gradient that pulls from your Android wallpaper's color palette, making it feel deeply native.
- **Connected "Squircle" Aesthetics** — Finder patterns are rendered as continuous, smooth "squircle" shapes, and data modules are "airy" dots for a premium, modern feel.
- **Fluid Navigation** — A custom "sliding pill" bottom nav that interpolates its position and style in real-time as you swipe between screens.
- **Smart Share Sheet** — An animated, blurred overlay with staggered action chips for one-tap sharing or saving to the device gallery.
- **Focused Camera Scanning** — A distraction-free scanning experience that restricts the scan window to a central, themed cutout.
- **Inline Renaming** — Keep your history organized by giving any QR code a custom label (e.g., "Home Wi-Fi", "Office Key").
- **Portrait Locked** — Optimized for a consistent, single-handed mobile experience.

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or later)
- Android device or emulator (iOS support included)

### Run Locally

```bash
git clone https://github.com/your-username/encqder.git
cd encqder
flutter pub get
flutter run
```

## Key Dependencies

| Package | Purpose |
|---|---|
| `pretty_qr_code` | Premium, stylized QR code rendering |
| `mobile_scanner` | Camera-based QR scanning |
| `shared_preferences` | Offline local storage |
| `dynamic_color` | Material You OS theming support |
| `intl` | Date/time formatting in history |

## Roadmap

See [ROADMAP.md](./ROADMAP.md) for a detailed breakdown of completed features and what's planned next.
