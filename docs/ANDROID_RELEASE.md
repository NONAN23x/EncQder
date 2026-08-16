# Android build and release

EncQder keeps the existing `com.nonanTech.EncQder` application ID so installed builds and future Play Store releases share the same upgrade identity.

## Toolchain

- Flutter 3.47 stable with Dart 3.12+
- JDK 21 to run Gradle
- Android SDK 36
- Android NDK 28.2 (Flutter-provided version)
- CMake 3.22.1 for native plugin compilation
- Gradle 9.1.0, Android Gradle Plugin 9.0.1, Kotlin 2.3.20

Java and Kotlin bytecode target Java 17. The Android minimum SDK is 24 and the target/compile SDK is supplied by Flutter 3.47.

## Verify a checkout

```bash
flutter --version
java -version
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --coverage
GRADLE_OPTS=--enable-native-access=ALL-UNNAMED flutter build apk --debug
cd android
./gradlew :app:lintDebug
```

Flutter creates the local Gradle wrapper during the Android build. In a fresh checkout, run `GRADLE_OPTS=--enable-native-access=ALL-UNNAMED flutter build apk --debug` before the direct `./gradlew` command.

## Unsigned release build

If `android/key.properties` does not exist, release variants compile without a signing configuration:

```bash
GRADLE_OPTS=--enable-native-access=ALL-UNNAMED flutter build apk --release
GRADLE_OPTS=--enable-native-access=ALL-UNNAMED flutter build appbundle --release
```

Unsigned artifacts are useful for compilation checks but cannot be installed or uploaded to Play Console as a release.

## Create an upload key

Create and protect an upload key outside the repository. The exact key-generation policy should match the Play Console account's operational requirements. A typical command is:

```bash
keytool -genkeypair -v \
  -keystore /secure/path/encqder-upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Copy the example properties file:

```bash
cp android/key.properties.example android/key.properties
```

Fill all four values:

```properties
storeFile=/secure/path/encqder-upload-keystore.jks
storePassword=your-store-password
keyAlias=upload
keyPassword=your-key-password
```

`android/key.properties`, `*.jks`, and `*.keystore` are ignored by Git. Do not commit the properties file, passwords, or the keystore. Back up the upload key and credentials in separate protected locations.

When `android/key.properties` exists, every field is required and the referenced keystore must exist. Gradle stops with a clear error if that signing request is incomplete.

## Build and verify a signed release

```bash
flutter clean
flutter pub get
GRADLE_OPTS=--enable-native-access=ALL-UNNAMED flutter build appbundle --release
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

For an APK, use the Android SDK's `apksigner`:

```bash
GRADLE_OPTS=--enable-native-access=ALL-UNNAMED flutter build apk --release
apksigner verify --verbose build/app/outputs/flutter-apk/app-release.apk
```

Before upload, also verify:

- Version name/code in `pubspec.yaml` are newer than the last published release.
- The merged release manifest contains camera and legacy API-29 storage permissions only, with no release Internet permission.
- Camera, image picker, sharing, gallery save, HTTPS links, and UPI handoff work on physical Android devices.
- `PRIVACY.md` and the Play Console data-safety form describe the release accurately.
- The final Git worktree does not contain build outputs, signing files, or generated secrets.
