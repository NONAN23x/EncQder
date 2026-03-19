# EncQder Roadmap

## ✅ Version 1.0.4 (Current)

### Storage & Reactivity (Shipped March 19, 2026)
- **Persistent File Storage**: Migrated off `SharedPreferences` to local JSON file storage within the application document directory, guaranteeing data survives app reinstalls using native OS backups.
- **Reactive State Management**: Upgraded `StorageService` to a `ChangeNotifier`, ensuring the Home screen instantly reflects new scanned or generated items without requiring manual pull-to-refresh or tab toggling.

### Expanded Generation & Discovery
- **Wi-Fi & UPI Integration**: Refactored the Create screen into an elegant, accordion-style expandable UI. Users can now generate explicit Wi-Fi connection codes (WPA/WEP/Open) and UPI payment codes alongside standard Text/URLs.
- **Dynamic Action Overlays**: Rebuilt the camera scanning interface to auto-detect what is being scanned. 
  - Text scans provide 'Discard' and 'Save'.
  - URLs introduce a native 'Visit' button.
  - Wi-Fi scans generate a 'Connect' button that safely extracts and copies network passwords for easy OS-level connection.
- **Smart Data Tagging**: Added contextual badges (TEXT, WIFI, UPI) below the SCANNED/GENERATED tags in the Home list.
- **Auto-Formatting Names**: The system now automatically assigns clean default labels based on the data type (e.g., "WIFI Code X", "UPI Code Y").

## ✅ Version 1.0.1 (Previous)

### Premium Aesthetics
- **Material You QR Codes**: Replaced static blue QR colors with a subtle, dynamic radial gradient that pulls from the user's OS-level wallpaper theme (Android 12+).
- **Connected Squircle Eyes**: Refined the QR finder patterns to be continuous, smooth "squircle" shapes, moving away from disconnected dots for a more premium, connected aesthetic.

### System Integration & Theming
- **Material You Dynamic Theming**: Configured the application to extract and apply OS-level dynamic color palettes on Android 12+ devices, while maintaining custom light/dark fallbacks.
- **Focused Camera Scanner**: Restrained the `MobileScanner` barcode capture to a central, framed cutout.

### Premium UI & Fluidity
- **Sliding Pill Navigation**: Replaced the static bottom nav with a custom "sliding pill" background that interpolates position and opacity during swiping.

## 🔮 Planned (v1.1.0 and beyond)

### Next Up
- [x] **Play Store Release**: Complete final pre-launch security and compliance audits.
- [ ] **Automated Testing**: Implement widget and integration tests to ensure core workflow stability.

### Brand Identity
- [x] **App Iconography**: Integrated responsive brand assets using `flutter_launcher_icons`.
- [ ] **Native Splash Screen**: Implement seamless launch sequences using `flutter_native_splash`.

### Advanced Capabilities
- [ ] **Continuous Batch Scanning**: Enable high-throughput scanning mode without returning to the home screen.
- [ ] **QR Code Content Actions**: Add contextual buttons based on scanned content (e.g., "Add to Contacts", "Open in Maps").