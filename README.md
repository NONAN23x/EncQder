![EncQder Banner](assets/feature_graphic.png)

# EncQder

EncQder is a private, offline-first QR code scanner and generator for Android. It creates text, Wi-Fi, and UPI QR codes, scans with the camera or an image, and keeps an on-device history in a Material 3 interface.

## Features

- Create QR codes for text and URLs, Wi-Fi credentials, and UPI payments.
- Scan with the camera or choose an image from Android's system picker.
- Keep, label, filter, share, and delete generated or scanned codes.
- Import legacy EncQder ZIP backups and export versioned JSON backups.
- Follow the Android system theme and Material You dynamic colors.
- Work without accounts, ads, analytics, tracking, or app-originated network requests.

## Privacy and storage

History is stored as plaintext JSON in EncQder's app-private documents directory. Android's app sandbox restricts other apps from reading it, but EncQder does not add application-level encryption. Android cloud backup is disabled because QR history may contain sensitive content such as Wi-Fi credentials.

Uninstalling EncQder normally removes its app-private data. Export a manual JSON backup before uninstalling, clearing app data, or moving devices. Imports and exports are always initiated by the user.

Camera frames and chosen images are processed on-device. Opening a web or UPI link, sharing content, or saving an export hands that content to the Android app selected by the user. See [PRIVACY.md](PRIVACY.md) for the full data-handling description.

## Requirements

- Flutter 3.47 stable (Dart 3.12+)
- JDK 21
- Android SDK 36 with NDK 28.2 and CMake 3.22.1
- Android device or emulator running API 24 or newer

## Run locally

```bash
git clone https://github.com/NONAN23x/EncQder.git
cd EncQder
flutter pub get
flutter run
```

Run the same checks used by CI:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --coverage
GRADLE_OPTS=--enable-native-access=ALL-UNNAMED flutter build apk --debug
cd android
./gradlew :app:lintDebug
```

Flutter creates the local Gradle wrapper as part of the Android build, so run the APK build before invoking `./gradlew` in a fresh checkout.

## Project structure

```text
lib/
  app/       App startup, theme, and navigation
  data/      Durable history and backup services
  domain/    Typed QR models and payload codecs
  features/  Create, scan, history, and settings UI
  shared/    Reusable QR presentation and actions
```

The app deliberately uses constructor injection and `ChangeNotifier` rather than a state-management framework. Payload parsing and persistence live outside widgets so they can be tested as pure behavior.

## Key dependencies

| Package | Purpose |
|---|---|
| `pretty_qr_code` | QR rendering |
| `mobile_scanner` | Camera and image QR scanning |
| `file_selector` | Android system file selection |
| `path_provider` | App-private file locations |
| `shared_preferences` | Theme preference and legacy history migration |
| `dynamic_color` | Material You colors |
| `share_plus` | Android share sheet |

For Android release and signing instructions, see [docs/ANDROID_RELEASE.md](docs/ANDROID_RELEASE.md). Current and planned work is tracked in [ROADMAP.md](ROADMAP.md).

No open-source license has been selected. Copyright remains with the repository owner unless a license is added later.
