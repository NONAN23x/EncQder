![EncQder Banner](assets/feature_graphic.png)

# EncQder

> A privacy-first, zero-friction QR tool that doesn't track you, built with a premium, gesture-first Flutter interface.

*This project is **AI Vibe Coded**, built as a high-fidelity experiment to push the boundaries of [Antigravity](https://google.com) and assist with my personal utility workflows.*

## Why It Exists

EncQder was born from a need for a beautiful, simple, and private QR tool. It's a playground for premium Flutter UI patterns and a personal assistant for my daily digital organization.

## What It Does

EncQder gives you three core tools in one swipeable interface:

- **Create** — Generate custom-styled QR codes for plain Text/URLs, connectable **Wi-Fi Networks**, or **UPI Payments** using an expressive, animated Material 3 UI. Autocomplete remembers your past UPI IDs to save time.
- **Scan** — Point your camera at any QR code to instantly read its content, or effortlessly **Scan from Gallery**. The app auto-detects links to browse, and parses Wi-Fi codes to easily copy network passwords.
- **History** — A reactive, persistent list of all your generated and scanned codes. Tap any code to view a beautiful fullscreen **Enlarged Preview**. All data is securely stored within your OS document directory so it survives app reinstalls, completely offline.
- **Privacy-First** — All data is stored **locally on your device**. No network calls, no accounts, no tracking.

## Premium UX Features

- **Expressive Material 3 Cards** — The Create and Settings screens feature bouncy, fluid card animations that morph corner radii, colors, and shadows as you interact with them.
- **Hero Image Previews** — Seamlessly pop any QR code into a crisp, fullscreen overlay for easy scanning by another device.
- **Native Splash Screens** — Elegant, typography-driven launch screens match your exact system theme instantly upon opening the app.
- **Dynamic Material You QR Codes** — QR codes are rendered with a subtle radial gradient that pulls from your Android wallpaper's color palette, making it feel deeply native.
- **Connected "Squircle" Aesthetics** — Finder patterns are rendered as continuous, smooth "squircle" shapes, and data modules are "airy" dots for a premium, modern feel.
- **Fluid Navigation** — A custom "sliding pill" bottom nav interpolates its position and style, and page transitions use slick circular reveals.
- **Smart Contextual Actions** — The camera intelligently surfaces a "Visit" button for URLs, or a "Connect" dialog for Wi-Fi codes to view and copy network passwords effortlessly.
- **Persistent Reactive Storage** — Your Home history dynamically updates in real-time. Uninstalling the app won't lose your data, thanks to native OS document directory storage and automatic backups.
- **Smart Share Sheet** — An animated, blurred overlay with staggered action chips for one-tap sharing or saving to the device gallery.

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
