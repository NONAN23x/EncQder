# EncQder – Next Feature Batch (Polished Spec)

This document instructs an AI coding assistant to implement a set of UI/UX and functional refinements for the **EncQder** Flutter app. Read all referenced files carefully before writing any code.

---

## Project Context & Rules

- **Framework**: Flutter (Dart)
- **Architecture/State**: `provider` + `shared_preferences` (via `StorageService`). Model is `QrItem` (fields include `label`, `data`, etc.).
- **Rule 1**: Do **not** add new packages to `pubspec.yaml` unless explicitly instructed.
- **Rule 2**: Run `flutter analyze` after completing changes and fix all warnings/errors.
- **Rule 3**: Achieve premium, fluid 60fps animations for UI state changes. Avoid layout jumps.

---

## Feature 1: Confine App to Portrait View

### Background
The app currently rotates if the user's Android device has auto-rotate enabled. The layout is optimized for portrait and should be locked to it.

### Implementation Steps
1. Open `lib/main.dart`.
2. Ensure `package:flutter/services.dart` is imported.
3. In `main()`, immediately after `WidgetsFlutterBinding.ensureInitialized();`, add the following to enforce portrait-up only:
   ```dart
   await SystemChrome.setPreferredOrientations([
     DeviceOrientation.portraitUp,
   ]);
   ```

---

## Feature 2: Premium Bottom Navigation Enhancements

### Background
Currently in `lib/screens/home_screen.dart`, the bottom navigation bar highlights the active tab continuously, but it does so by fading in/out a background color on each individual tab. The user wants a **"sliding pill" animation** where a single highlighted pill physically slides left/right to the selected tab. Additionally, the padding/width of the tabs fluctuates based on text length, causing inconsistent spacing.

### Implementation Steps (`lib/screens/home_screen.dart`)

1. **Standardize Tab Widths**: Ensure the container holding the navigation items evenly distributes space. Wrap each navigation item in an `Expanded` widget within the `Row` so they each take up exactly 1/3 of the width.
2. **Implement Sliding Background Pill**:
   - Wrap the `Row` of nav items in a `Stack`.
   - Add an `AnimatedPositioned` widget *behind* the row of icons/text.
   - Use the continuous `_pageController.page` value (which you can listen to via `AnimatedBuilder`) to calculate the exact horizontal offset of the pill.
   - The pill should have the active primary color with low opacity (e.g., `Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)`), a fixed height, and dynamic width equal to exactly 1/3 of the total container width (minus padding).
3. **Smooth Icon/Text Transitions**:
   - The icon color and text opacity should still smoothly interpolate based on the continuous distance `t` from the `currentPage` to their index, exactly as implemented recently.
   - Ensure the label text width does not cause the parent container to resize during the swipe. Wrap the label in a fixed-width container or use `ClipRect` with `Align` to prevent layout jumps.

*Acceptance Criteria*: Swiping the page view natively drags a physical background highlight pill proportionally across the bottom nav. The tabs are evenly spaced and do not jump in size.

---

## Feature 3: Side-by-Side Detail Buttons & Smart Share Content

### Background
In `lib/screens/history_screen.dart`, the `_showQrDetails` bottom sheet currently stacks the "Share" and "Delete" buttons vertically. They should be side-by-side. Furthermore, the shared text does not currently utilize the newly added user-edited label.

### Implementation Steps (`lib/screens/history_screen.dart` -> `_showQrDetails` and `ShareOverlay`)

1. **Layout Change**:
   - Locate the `ElevatedButton` (Share) and `TextButton` (Delete) in `_showQrDetails`.
   - Wrap them in a `Row`, and wrap each button in an `Expanded` widget so they take up 50% width each.
   - Separate them with a `SizedBox(width: 12)`.
   - Adjust button heights/padding so they visually match.

2. **Update Shared Text**:
   - In the `ShareOverlay` class (and anywhere else `Share.shareXFiles` or `Share.share` is called), update the `text` payload.
   - Instead of `'Scanned via EncQder: ${item.data}'`, change it to dynamically include the label:
     `'${item.label.isNotEmpty ? item.label : "QR Code"}\nScanned via EncQder: ${item.data}'`

*Acceptance Criteria*: Detail sheet features two equal-width buttons side-by-side. When sharing, the text preview in the OS share sheet includes the user's custom QR label.

---

## Feature 4: Create Text Page Clean-Up

### Background
In `lib/screens/input_screen.dart`, when a user types into the TextField, a live QR code preview ("ready to encode") and a greyed-out helper text ("save to add text into history") appear below it. The user wants to completely remove these elements once text is entered. Only the text box and the action buttons ("Clear" and "Save to history") should remain visible.

### Implementation Steps (`lib/screens/input_screen.dart`)

1. **Remove Preview Elements**:
   - Locate the block that renders when `_currentInput.isNotEmpty` (the `Expanded` widget containing the `QrDisplay`, the "Ready to encode" text, etc.).
   - Delete the `QrDisplay` widget and the helper text (`Text('Ready to encode...', ...)` and `Text('Save to add text into history...', ...)`).
   
2. **Adjust Layout**:
   - Ensure the "Clear" and "Save to History" buttons are prominently displayed immediately below or at the bottom of the screen.
   - Without the large QR preview taking up space, you may want to align the buttons to the bottom using `Spacer` or adjust the flex layout so the UI doesn't look empty.

*Acceptance Criteria*: Typing in the input box does *not* generate a live QR preview. The interface remains clean, showing only the input field and the necessary action buttons.

---

## Implementation Order
1. Lock orientation in `main.dart`.
2. Refactor `input_screen.dart` layout to remove the live preview.
3. Update `history_screen.dart` to fix the detail button layout and share text payload.
4. Refactor `home_screen.dart` to implement the premium sliding pill animation for the bottom nav.
5. Run `flutter analyze` and fix any issues.