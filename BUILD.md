# The Loop - Production Build Guide

This guide explains how to build The Loop for production release.

## Prerequisites

1. Flutter SDK (^3.9.2)
2. Android Studio / Xcode
3. YouTube Data API v3 key(s)

## API Key Configuration

API keys are loaded at compile-time via `--dart-define` environment variables. This keeps your keys secure and out of source control.

### Option 1: Using .env file (Recommended)

1. Copy the example env file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and add your API keys:
   ```
   YOUTUBE_API_KEY_1=your_first_api_key_here
   YOUTUBE_API_KEY_2=your_second_api_key_here
   ```

3. Build with:
   ```bash
   flutter build apk --dart-define-from-file=.env
   ```

### Option 2: Command Line Arguments

Pass API keys directly:
```bash
flutter build apk \
  --dart-define=YOUTUBE_API_KEY_1=your_key_1 \
  --dart-define=YOUTUBE_API_KEY_2=your_key_2
```

## Android Release Build

### 1. Setup Release Signing

1. Create a keystore (if you don't have one):
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias upload
   ```

2. Copy the keystore configuration:
   ```bash
   cp android/key.properties.example android/key.properties
   ```

3. Edit `android/key.properties` with your keystore details:
   ```properties
   storeFile=../upload-keystore.jks
   storePassword=your_keystore_password
   keyAlias=upload
   keyPassword=your_key_password
   ```

4. Place your keystore file in the `android/` directory

### 2. Build Release APK

```bash
# Debug build (no signing required)
flutter build apk --debug --dart-define-from-file=.env

# Release build (requires signing setup)
flutter build apk --release --dart-define-from-file=.env
```

### 3. Build App Bundle (for Play Store)

```bash
flutter build appbundle --release --dart-define-from-file=.env
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## iOS Release Build

### 1. Configure Signing in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the Runner target
3. Under Signing & Capabilities, configure your team and bundle ID
4. Enable automatic signing or configure manual provisioning profiles

### 2. Build Release IPA

```bash
flutter build ipa --release --dart-define-from-file=.env
```

Output: `build/ios/ipa/`

## Build Variants

### Debug Build
```bash
flutter build apk --debug --dart-define-from-file=.env
```

### Profile Build (for performance testing)
```bash
flutter build apk --profile --dart-define-from-file=.env
```

### Release Build
```bash
flutter build apk --release --dart-define-from-file=.env
```

## Verifying the Build

### Check APK Contents
```bash
# List APK contents
unzip -l build/app/outputs/flutter-apk/app-release.apk | grep -i key
```

### Test Release Build
```bash
flutter install --release
```

## Troubleshooting

### API Keys Not Working
- Ensure your YouTube Data API v3 is enabled in Google Cloud Console
- Check that the API key has no restrictions blocking your app

### Build Fails with Signing Error
- Verify `key.properties` paths are correct
- Ensure keystore password is correct
- Check that the keystore file exists at the specified path

### iOS Build Fails
- Run `flutter clean` and rebuild
- Ensure CocoaPods is up to date: `cd ios && pod update`
- Check Xcode signing configuration

## Security Notes

- **NEVER** commit `.env` or `key.properties` files
- **NEVER** commit keystore files (`*.jks`, `*.keystore`)
- These files are already in `.gitignore`
- Keep backup copies of your keystore in a secure location

## Version Management

Update version in `pubspec.yaml`:
```yaml
version: 1.0.0+1
# Format: major.minor.patch+buildNumber
```

For each release:
- Increment version number appropriately
- Increment build number (required for store updates)

---

**Created by Nikhil K**
