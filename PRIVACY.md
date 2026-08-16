# EncQder Privacy Notice

Effective: July 17, 2026

EncQder is an offline-first Android application. It has no accounts, advertising, analytics, tracking SDKs, or developer-operated backend, and it does not make app-originated network requests.

## Data EncQder handles

EncQder may store the following on the device:

- QR payloads that you generate, scan, or import
- User-provided labels
- Creation timestamps and whether an item was generated, scanned, or imported
- QR content type and UPI suggestion preferences
- The selected light, dark, or system theme preference

History is plaintext JSON in the app-private documents directory. It is protected by Android's app sandbox and any device-level protections, but it is not separately encrypted by EncQder.

## Camera and images

Camera access is used only while scanning QR codes. Camera frames are analyzed on-device and are not uploaded by EncQder. Images selected through Android's system picker are also analyzed on-device. EncQder does not retain the source camera frame or selected image as part of history.

## User-initiated sharing and external apps

EncQder can, only after a user action:

- Open an HTTP, HTTPS, or UPI destination in another installed app
- Share text or a generated QR image through Android's share sheet
- Save a generated QR image to the gallery
- Import or export a history backup through Android's file interface

Once content is handed to another app or saved outside EncQder's private directory, that destination's privacy practices and retention rules apply.

## Backup and retention

Android cloud backup is disabled for EncQder. Uninstalling the app or clearing its data normally removes app-private history and preferences. Manual JSON backups and gallery images remain wherever the user saved them and must be deleted separately.

History can be deleted inside EncQder. A corrupt history file may be quarantined in the app-private directory to support recovery; it remains local and is removed when app data is cleared or the app is uninstalled.

## Android permissions

- `CAMERA` enables QR scanning.
- `WRITE_EXTERNAL_STORAGE` is declared only for Android 10/API 29 and older for compatible gallery saves.
- Debug and profile builds include `INTERNET` for Flutter development tools. The release manifest does not request Internet access.

## Changes and contact

Material changes to this notice will be committed to this repository with an updated effective date. Questions or privacy concerns can be filed through the repository's [GitHub issue tracker](https://github.com/NONAN23x/EncQder/issues).
