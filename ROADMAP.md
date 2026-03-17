# EncQder Roadmap

## ✅ Completed (March 17, 2026)

### Premium Settings & Customization
- **Settings Dashboard**: Designed a dedicated settings interface for storage and visual management.
- **3-Stage Theme Slider**: Implemented a fluid, animated segmented control for `Light | System | Dark` modes.
- **Enhanced Scanner UX**: Replaced generic overlays with a premium black-and-transparent cutout UI, featuring elegant corner brackets.
- **Idle Timeout**: Added power-saving logic that auto-navigates away from the camera after 120 seconds of inactivity.

### Data & History Enhancements
- **QR Origin Tracking**: History now distinguishes between `Scanned` and `Generated` QR codes via local storage metadata.
- **Gallery Integration**: Scanned QR codes are automatically saved as high-resolution images to a dedicated "EncQder" album in the device gallery.
- **High-Fidelity Sharing**: Details view now shares pixel-perfect `.png` renders instead of raw text.
- **Improved List UI**: Added origin badges and formatted timestamps to the history list.

## ✅ Completed (March 16, 2026)

### Core Architecture
- Initialized Flutter project with iOS and Android targets.
- Established clean `screens / services / widgets` structure.
- Implemented `PageView` navigation with synced animated bottom bar.

### Features
- Text-to-QR generation with offline history persistence.
- `mobile_scanner` integration for native camera access.
- Duplicate promotion in history (prevents clutter).

## 🔮 Planned

### Upcoming
- [ ] **Custom QR Labels**: Ability to rename entries in history (e.g., "Home Wi-Fi", "Payment UPI", "Office Key") for easier identification.

### Data Portability
- [ ] **ZIP Export**: Batch export all QR metadata and images to a portable `.zip` archive.
- [ ] **Full Wipe**: Implement a secure "Reset App" action with haptic confirmation.

### Visual Identity
- [ ] **Custom App Icon**: Deploy `1024×1024` brand assets via `flutter_launcher_icons`.
- [ ] **Splash Screen**: Native splash sequence using `flutter_native_splash`.

### Advanced QR
- [ ] **Color Customization**: Allow users to change foreground/background colors for generated QRs.
- [ ] **Batch Scanning**: Support continuous scanning mode for high-volume use cases.
