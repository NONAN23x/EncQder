# EncQder Roadmap

## ✅ Completed (March 18, 2026)

### Premium UI & Fluidity
- **Sliding Pill Navigation**: Replaced the static bottom nav with a custom "sliding pill" background that interpolates position and opacity during swiping.
- **Smart Share Overlay**: Replaced vertical buttons with an animated, blurred share sheet featuring staggered action chips (Save to Gallery / Native Share).
- **UI Clean-up**: Removed redundant live QR previews on the Create screen for a more minimal, distraction-free input experience.
- **Portrait Enforcement**: Locked the app to portrait mode for a consistent single-handed layout.

### Smart Metadata & Management
- **Editable Labels**: Added a `label` field to history items with a pencil icon for inline renaming directly in the detail view.
- **Auto-Incrementing Naming**: New items now automatically receive unique default labels (e.g., "QR Code 2", "QR Code 3") to avoid clutter.
- **Side-by-Side Details Actions**: Redesigned the detail view actions into a clean horizontal layout for better reachability.

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
- **High-Fidelity Sharing**: Details view now shares pixel-perfect `.png` renders instead of raw text.
- **Improved List UI**: Added origin badges and formatted timestamps to the history list.

## 🔮 Planned

### Upcoming
- [ ] **Deployment**: Final audit for Play Store submission.

### Visual Identity
- [x] **Custom App Icon**: Deployed brand assets via `flutter_launcher_icons`.
- [ ] **Splash Screen**: Native splash sequence using `flutter_native_splash`.

### Advanced QR
- [ ] **Batch Scanning**: Support continuous scanning mode for high-volume use cases.
