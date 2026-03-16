# EncQder Roadmap

## ✅ Completed (March 16, 2026)

### Architecture
- Initialized Flutter project with iOS and Android targets.
- Established a clean `screens / services / widgets` directory structure.
- Implemented `PageView`-based navigation with a synced animated bottom bar for swipe-driven tab switching.

### Create QR Tab
- Text input with 500-character limit.
- No live preview — a "Ready to Encode" placeholder is shown while typing to keep the experience clean.
- Saves raw text to offline history on confirmation.

### Scan QR Tab
- `mobile_scanner` integration for native camera access.
- Custom viewfinder overlay with corner indicators, torch toggle, and camera flip controls.
- Raw content displayed in a modal on scan — no automatic URL resolution or link-following.
- One-tap save to history.

### History Tab
- Persistent offline storage via `shared_preferences`.
- Duplicate entries are automatically promoted to the top of the list rather than duplicated.
- Tapping an entry opens a detail modal showing the rendered QR code and a delete option.
- Formatted timestamps using the `intl` package.

### Code Quality
- Zero issues on `flutter analyze`.
- Replaced all deprecated `withOpacity()` calls with `withValues(alpha:)`.
- Fixed async `BuildContext` usage across all screens following `context.mounted` best practices.
- Corrected `CardTheme` → `CardThemeData` and invalid `Colors.whitee7` → `Colors.white70`.

---

## 🔮 Planned

### Custom App Icon
Uses `flutter_launcher_icons`. Add your `1024×1024` PNG at `assets/icon/app_icon.png` and configure `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
```

Then run:
```bash
flutter pub run flutter_launcher_icons
```

### Custom Splash Screen
Uses `flutter_native_splash`. Add your logo at `assets/splash/logo.png` and configure `pubspec.yaml`:

```yaml
flutter_native_splash:
  color: "#F8F9FA"
  image: "assets/splash/logo.png"
  color_dark: "#121212"
  image_dark: "assets/splash/logo.png"
  android: true
  ios: true
```

Then run:
```bash
flutter pub run flutter_native_splash:create
```
