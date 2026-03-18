# EncQder Roadmap

## ✅ Completed (March 17, 2026)

### Data Portability & Management
- **ZIP Export/Import**: Implemented batch export of history metadata to a secure `.zip` archive and a matching import/merge restoration feature.
- **Secure Full Wipe**: Added a destructive "Wipe Data" action in Settings with double-confirmation and haptic-aligned feedback.
- **Advanced History Filtering**: Introduced a premium control bar for sorting (Asc/Desc) and filtering by `Month` or `Year`.
- **Dynamic Empty States**: Added conditional UI states for "No matches found" vs "No history exists."

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
... [Previous Core Architecture and Features] ...

## 🔮 Planned

### Upcoming
- [ ] **Custom QR Labels**: Ability to rename entries in history (e.g., "Home Wi-Fi", "Payment UPI", "Office Key") for easier identification.
- [ ] **Deployment** : add information for developer, fix bugs, unnecessary logic, publish to plaay store

### Visual Identity
- [x] **Custom App Icon**: Successfully deployed brand assets via `flutter_launcher_icons`.
- [ ] **Splash Screen**: Native splash sequence using `flutter_native_splash`.
- [ ] ** UI **: Enhance UI

### Advanced QR
- [ ] **Batch Scanning**: Support continuous scanning mode for high-volume use cases.
