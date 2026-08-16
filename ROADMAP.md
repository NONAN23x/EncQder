# EncQder Roadmap

## Version 1.1.0+8 — Android normalization

This release turns the original prototype into an Android-only application with explicit data and platform boundaries.

### Reliability and privacy

- Versioned history and backup schema with typed QR kind and origin values.
- Serialized, atomic history writes with backup recovery and corrupt-file quarantine.
- Migration from legacy JSON and `SharedPreferences` history without discarding user labels or suggestion preferences.
- Versioned JSON exports plus one-release compatibility with legacy ZIP imports.
- Bounded imports with clear added, duplicate, and rejected counts.
- Android cloud backup disabled; manual export is the supported device-migration path.

### QR correctness and safety

- Shared Wi-Fi and UPI payload codecs with escaping, validation, and typed parsing.
- Explicit allowlist for web and payment actions; unknown and dangerous URI schemes are not launched.
- Standards-friendly QR quiet zones and shared screen/export rendering.
- Wi-Fi results describe the available details instead of claiming to connect the device automatically.

### Android and maintainability

- Android-only Flutter 3.44.5 baseline with API 24 minimum and API 36 target.
- AGP 9.0.1, Gradle 9.1.0, Kotlin 2.3.20, and JDK 21 build tooling.
- Material `NavigationBar`, centralized theming, and lifecycle-aware camera behavior.
- Feature-oriented code organization with constructor-injected history and backup services.
- Latest compatible stable direct dependencies and removal of unused packages.
- CI for formatting, fatal analysis, tests, Android lint, and a debug APK build.
- Weekly dependency checks for Pub, Gradle, and GitHub Actions.

## Planned

- [ ] Complete physical-device accessibility review with TalkBack and 200% font scaling.
- [ ] Validate camera, gallery selection, sharing, UPI handoff, and gallery saving on API 24, 29, and 36 devices.
- [ ] Complete Play Console data-safety declarations and store-listing assets.
- [ ] Produce and validate the first signed release AAB with a protected upload key.
- [ ] Consider contact, calendar, and map actions only after the core release is stable.
- [ ] Remove legacy ZIP import after a documented migration window.

## Historical releases

### Version 1.0.4

- Added file-backed QR history, UPI suggestions, gallery scanning, native splash screens, Wi-Fi and UPI generation, and contextual scan actions.

### Version 1.0.1

- Added Material You colors, styled QR rendering, camera framing, and the original swipe navigation.
