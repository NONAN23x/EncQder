# EncQder Roadmap

## ✅ Version 1.0.1 (Current)

### Premium Aesthetics (Shipped March 18, 2026)
- **Material You QR Codes**: Replaced static blue QR colors with a subtle, dynamic radial gradient that pulls from the user's OS-level wallpaper theme (Android 12+).
- **Connected Squircle Eyes**: Refined the QR finder patterns to be continuous, smooth "squircle" shapes, moving away from disconnected dots for a more premium, connected aesthetic.
- **Padded "Airy" Data Modules**: Adjusted the data dot density to increase the whitespace between modules, giving the QR code a lighter, more modern and readable feel.
- **Optimized Export Padding**: Halved the quiet zone on exported images for a tighter, more modern look.

### System Integration & Theming
- **Material You Dynamic Theming**: Configured the application to extract and apply OS-level dynamic color palettes on Android 12+ devices, while maintaining custom light/dark fallbacks.
- **Focused Camera Scanner**: Restrained the `MobileScanner` barcode capture to a central, framed cutout, effectively ignoring QRs detected in the periphery.
- **Theme-Aware Overlay**: Engineered a solid, full-opacity scanner overlay that perfectly mimics the underlying `scaffoldBackgroundColor`, adapting continuously to light/dark system themes.

### Premium UI & Fluidity
- **Sliding Pill Navigation**: Replaced the static bottom nav with a custom "sliding pill" background that interpolates position and opacity during swiping.
- **Smart Share Overlay**: Replaced vertical buttons with an animated, blurred share sheet featuring staggered action chips (Save to Gallery / Native Share).
- **UI Clean-up**: Removed redundant live QR previews on the Create screen for a more minimal, distraction-free input experience.
- **Portrait Enforcement**: Locked the app to portrait mode for a consistent single-handed layout.

### Smart Metadata & Management
- **Editable Labels**: Added a `label` field to history items with a pencil icon for inline renaming directly in the detail view.
- **Auto-Incrementing Naming**: New items now automatically receive unique default labels (e.g., "QR Code 2", "QR Code 3") to avoid clutter.
- **Side-by-Side Details Actions**: Redesigned the detail view actions into a clean horizontal layout for better reachability.

## 🔮 Planned (v1.1.0 and beyond)

### Next Up
- [x] **Play Store Release**: Complete final pre-launch security and compliance audits.
- [ ] **Automated Testing**: Implement widget and integration tests to ensure core workflow stability.

### Brand Identity
- [x] **App Iconography**: Integrated responsive brand assets using `flutter_launcher_icons`.
- [ ] **Native Splash Screen**: Implement seamless launch sequences using `flutter_native_splash`.

### Advanced Capabilities
- [ ] **Continuous Batch Scanning**: Enable high-throughput scanning mode without returning to the home screen.
- [ ] **QR Code Content Actions**: Add contextual buttons based on scanned content (e.g., "Add to Contacts", "Connect to Wi-Fi", "Open in Maps").
