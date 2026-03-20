# EncQder Roadmap

## ✅ Version 1.0.4+6 (Current)

### Expressive Material 3 UI & Fluidity
- **Animated Expandable Cards**: Replaced rigid ExpansionPanels with expressive, rounded Material 3 cards featuring dynamic border radii, soft drop shadows, and bouncy height animations for the Create screen.
- **Enlarged QR Previews**: Tapping any QR code now seamlessly expands it into a fullscreen, transparent `Hero` overlay with custom labeling and data type badges.
- **Interactive Settings**: Redesigned the Settings screen with large, pill-shaped action cards, distinct destructive states, and a smooth circular reveal transition from the Home screen.
- **Dynamic Empty States**: The Home screen now features a floating, elastic-scaled empty state icon to make the app feel alive even when no data is present.

### Advanced Capabilities & Quality of Life
- **Smart UPI Suggestions**: The UPI generation form now remembers previously used IDs. Tapping the field reveals an autocomplete dropdown, complete with a "Forget" action that hides the suggestion without deleting the underlying history item.
- **Gallery Scanning**: Users can now select and scan QR codes from existing images in their device gallery using a beautiful, frosted-glass floating button on the Camera screen.
- **Native Splash Screens**: Replaced the default Flutter launch screen with elegant, typography-focused splash images for both light and dark themes using `flutter_native_splash`.

### Storage & Reactivity (Shipped March 19, 2026)
- **Persistent File Storage**: Migrated off `SharedPreferences` to local JSON file storage within the application document directory, guaranteeing data survives app reinstalls using native OS backups.
- **Reactive State Management**: Upgraded `StorageService` to a `ChangeNotifier`, ensuring the Home screen instantly reflects new scanned or generated items without requiring manual pull-to-refresh or tab toggling.

### Expanded Generation & Discovery
- **Wi-Fi & UPI Integration**: Users can generate explicit Wi-Fi connection codes (WPA/WEP/Open) and UPI payment codes alongside standard Text/URLs.
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
- [ ] **Play Store Release**: Complete final pre-launch security and compliance audits.
- [ ] **Automated Testing**: Implement widget and integration tests to ensure core workflow stability.
- [ ] **Continuous Batch Scanning**: Enable high-throughput scanning mode without returning to the home screen.
- [ ] **QR Code Content Actions**: Add contextual buttons based on scanned content (e.g., "Add to Contacts", "Open in Maps").
