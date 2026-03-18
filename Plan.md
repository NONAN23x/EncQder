# EncQder – Feature Batch: Dynamic Theming & Focused Scanning

This document provides explicit implementation instructions for the next batch of features in the **EncQder** Flutter app. Read all referenced files carefully before writing any code.

---

## Project Context & Rules

- **Framework**: Flutter (Dart)
- **Rule 1**: Only add new packages to `pubspec.yaml` if strictly necessary to fulfill the requirements below (e.g., the `dynamic_color` package for Material You).
- **Rule 2**: Run `flutter analyze` after completing changes and fix all warnings/errors.
- **Rule 3**: Maintain the existing premium, 60fps fluid UI standards. Avoid layout jumps.

---

## Feature 1: Material You (Dynamic) System Theming

### Background
Currently, the application relies on hard-coded light and dark theme seed colors. The goal is to adopt Android's **Material You (Dynamic Color)**. If the user's device supports it (Android 12+), the app should inherit the system's dynamic color palette for its "System Theme" setting. 

### Implementation Steps
1. **Dependency Update**: If necessary, add the `dynamic_color` package to `pubspec.yaml` to extract OS-level theme data.
2. **Theme Configuration** (`lib/main.dart`):
   - Wrap the `MaterialApp` in a `DynamicColorBuilder` (or the equivalent approach).
   - **Supported Environments**: If dynamic colors (`lightDynamic` / `darkDynamic`) are provided by the OS, map them to your `ColorScheme`.
   - **Fallback Behavior**: If the device does not provide dynamic colors (or they fail contrast checks), seamlessly fall back to the existing automatic light/dark theme seed colors (`Colors.black` and `Colors.white`).
3. **Verification**: Ensure the dynamic colors apply globally without breaking the custom widget styling (cards, buttons, navbar).

---

## Feature 2: Focused Camera Scanning with Themed Overlay

### Background
The `CameraScreen` currently processes any QR code detected anywhere in the camera feed. It also lacks a focused visual guide. The user wants the scanner to be strictly confined to a central bounding box (the "frame") and the rest of the camera feed to be completely obscured.

### Implementation Steps (`lib/screens/camera_screen.dart`)

1. **Scan Area Restriction**:
   - Configure the `MobileScannerController` or barcode processing logic to only accept barcodes that intersect or fall within a defined central scan window (e.g., a 250x250 bounding box).
   - Immediately discard/ignore any QR codes detected outside of this bounding box.
   
2. **Themed Surroundings (Cutout Overlay)**:
   - Add a visual overlay UI that acts as a "cutout" over the camera feed. The center square should be entirely transparent.
   - **Crucial Theming Rule**: The "dimmed" area outside the central frame must completely obscure the camera feed and inherit its background color dynamically based on the active theme:
     - **Light Theme**: Solid or highly opaque light color (e.g., `Colors.white` or `scaffoldBackgroundColor`).
     - **Dark Theme**: Solid or highly opaque dark color (e.g., `Colors.black` or `scaffoldBackgroundColor`).
   - The user must *not* be able to see the camera feed outside the central cutout frame.

### Acceptance Criteria
- [ ] App dynamically adopts Material You colors on supported Android devices while retaining the current custom themes as a fallback.
- [ ] QR codes are only scanned if they appear inside the center camera frame.
- [ ] The camera feed outside the frame is fully obscured by a solid color matching the active theme mode.