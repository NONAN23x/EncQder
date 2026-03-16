# Future Development Plans & Enhancements

This document outlines upcoming feature implementations for the EncQder project, refined with premium design standards, optimal user experience, and robust technical architectures.

## 1. Settings & Data Management (Activity)
**Objective**: Introduce a dedicated settings interface for storage management and visual preferences.
**Technical & UX Approach**:
- **Entry Point**: A slick, animated gear icon in the top-right corner of the History screen.
- **View Architecture**: Implement a clean, native-feeling modal sheet or a dedicated sub-route (`SettingsScreen`).
- **Features**:
  - **Storage Metrics**: Display current local data usage with a polished visual progress bar or circular ring.
  - **Data Controls**: 
    - *Export*: Generate a `.zip` archive of all saved QR metadata and images, exporting it via the native share sheet or directly to the `Downloads` folder using refined file-system operations.
    - *Wipe*: A "Reset App" destructive action guarded by a sophisticated confirmation dialogue with haptic feedback.
  - **Theme Control**: Replace standard toggles with a premium 3-stage animated slider (Segmented Control) mapping to: `Light | System | Dark`. Theme transitions must be instant and fluid (60fps).

## 2. Differentiating & Persisting QR Types
**Objective**: Distinguish between user-generated text QRs and scanned QRs, and introduce persistent image saving.
**Technical & UX Approach**:
- **Data Model Update**: Update local storage schemas to include an `origin_type` ENUM (`scanned` vs `generated`).
- **UI Enhancement**: Add subtle, elegant badging or iconography to History list items so users can instantly identify the origin of the entry.
- **Gallery Integration**: 
  - Instead of purely abstract data, implement a robust integration with Android's MediaStore and iOS Photo Library APIs.
  - Create a dedicated "EncQder" album. Save high-resolution, pixel-perfect `.jpg` exports of the QR codes natively to this album.
  - *Note*: Ensure permissions are requested contextually and gracefully, handling edge cases where access is denied.

## 3. High-Fidelity Image Sharing
**Objective**: Update the share functionality in the history detail view to share the actual QR graphic rather than the raw text string.
**Technical & UX Approach**:
- **Rendering Pipeline**: When the user taps "Share", programmatically render the `QrDisplay` into a high-resolution boundary (using `RepaintBoundary` or direct drawing via `ui.PictureRecorder`).
- **File Handling**: Convert the rendered graphic to a `.jpg` or `.png` residing in the app's temporary cache directory.
- **Native Sharing**: Use `share_plus` to invoke the native share sheet, passing the generated image file (XFile) so it appears as a visual preview in messaging apps, emphasizing a premium feel.

## 4. Intelligent Battery Management & Premium Scanner UI
**Objective**: Conserve battery during idle camera usage and elevate the scanner's visual aesthetic.
**Technical & UX Approach**:
- **Idle Timeout (Auto-Navigation)**: 
  - Implement a scoped `Timer` that tracks user touch activity on the camera screen.
  - If idle for 2 minutes (120 seconds), gracefully animate the `PageView` controller to slide back to the default History tab.
- **Minimalist Scanner Aesthetic**:
  - Completely replace the generic green grid overlay.
  - Design a luxury scanning experience: A solid deep-black background with a transparent center cutout.
  - Add smooth, minimal corner brackets with a subtle glow or a quiet, pulsing scanning line to indicate active scanning without visual clutter.