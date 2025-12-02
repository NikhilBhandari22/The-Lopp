# Google AdMob Setup Guide for The Loop

This guide explains how to enable ads in The Loop app using Google AdMob.

---

## Table of Contents
1. [AdMob Account Setup](#1-admob-account-setup)
2. [Create App & Ad Units](#2-create-app--ad-units)
3. [Flutter Package Installation](#3-flutter-package-installation)
4. [Android Configuration](#4-android-configuration)
5. [iOS Configuration](#5-ios-configuration)
6. [Code Implementation](#6-code-implementation)
7. [Testing](#7-testing)
8. [Going Live](#8-going-live)

---

## 1. AdMob Account Setup

### Create Account
1. Go to [https://admob.google.com](https://admob.google.com)
2. Sign in with your Google account
3. Accept terms and conditions
4. Fill in payment information

### Account Approval
- New accounts may take **24-48 hours** to get approved
- Ad serving may be limited initially until your app gets traffic

---

## 2. Create App & Ad Units

### Add Your App
1. Click **"Apps"** → **"Add App"**
2. Select platform (Android/iOS)
3. If not published, select **"No, it's not listed"**
4. Enter app name: **"The Loop"**
5. **Save the App ID**

### Create Ad Units
1. Click **"Add ad unit"**
2. Select **"Interstitial"** (full-screen startup ad)
3. Name: **"Startup Interstitial"**
4. **Save the Ad Unit ID**

### Your IDs Structure
```
┌─────────────────────────────────────────────────────────┐
│ Platform │ App ID              │ Interstitial Ad Unit  │
├─────────────────────────────────────────────────────────┤
│ Android  │ ca-app-pub-XXX~YYY  │ ca-app-pub-XXX/ZZZ    │
│ iOS      │ ca-app-pub-XXX~AAA  │ ca-app-pub-XXX/BBB    │
└─────────────────────────────────────────────────────────┘
```

### Test IDs (Use During Development)
**Android:**
- App ID: `ca-app-pub-3940256099942544~3347511713`
- Interstitial: `ca-app-pub-3940256099942544/1033173712`

**iOS:**
- App ID: `ca-app-pub-3940256099942544~1458002511`
- Interstitial: `ca-app-pub-3940256099942544/4411468910`

---

## 3. Flutter Package Installation

### Add to pubspec.yaml
```yaml
dependencies:
  google_mobile_ads: ^5.1.0
```

### Install
```bash
flutter pub get
```

---

## 4. Android Configuration

### File: `android/app/src/main/AndroidManifest.xml`

Add inside `<application>` tag:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
```

### File: `android/app/build.gradle.kts`

Ensure minSdk is at least 21:
```kotlin
android {
    defaultConfig {
        minSdk = 21
    }
}
```

---

## 5. iOS Configuration

### File: `ios/Runner/Info.plist`

Add before closing `</dict>`:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
    </dict>
</array>
```

---

## 6. Code Implementation

### Create New File: `lib/services/ad_service.dart`

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool _hasShownStartupAd = false;

  // Test IDs - Replace with your real IDs for production
  static String get _interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test ID
    }
    return '';
  }

  // Initialize AdMob SDK
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    if (kDebugMode) debugPrint('AdMob initialized');
  }

  // Load interstitial ad
  Future<void> loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          if (kDebugMode) debugPrint('Interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          _isAdLoaded = false;
          if (kDebugMode) debugPrint('Interstitial ad failed: ${error.message}');
        },
      ),
    );
  }

  // Show startup ad (only once per session)
  Future<bool> showStartupAd() async {
    if (_hasShownStartupAd) {
      if (kDebugMode) debugPrint('Startup ad already shown this session');
      return false;
    }

    if (!_isAdLoaded || _interstitialAd == null) {
      if (kDebugMode) debugPrint('Ad not ready');
      return false;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _isAdLoaded = false;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _isAdLoaded = false;
      },
    );

    await _interstitialAd!.show();
    _hasShownStartupAd = true;
    return true;
  }

  bool get isAdLoaded => _isAdLoaded;
  bool get hasShownStartupAd => _hasShownStartupAd;
}
```

### Modify: `lib/main.dart`

```dart
// Add import
import 'services/ad_service.dart';

// In _initializeApp() method, add after Firebase init:
Future<void> _initializeApp() async {
  // ... existing Firebase code ...

  // Initialize AdMob
  try {
    await AdService().initialize();
    await AdService().loadInterstitialAd();
    AppLogger.success('AdMob initialized', tag: 'Init');
  } catch (e) {
    AppLogger.error('AdMob initialization error', tag: 'Init', error: e);
  }

  // ... rest of existing code ...
}
```

### Modify: `lib/screens/splash_screen.dart`

```dart
// Add import
import '../services/ad_service.dart';

// In the splash completion callback, show ad before navigating:
void _onSplashComplete() async {
  // Try to show startup ad
  final adShown = await AdService().showStartupAd();

  // Small delay if ad was shown for smooth transition
  if (adShown) {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Call the original onComplete callback
  widget.onComplete();
}
```

---

## 7. Testing

### Use Test IDs
**IMPORTANT:** Always use test IDs during development to avoid AdMob policy violations.

### Test Scenarios
1. **Fresh app launch** → Ad should show
2. **Hot reload** → Ad should NOT show again
3. **App backgrounded and resumed** → Ad should NOT show again
4. **App fully closed and reopened** → Ad should show again

### Debug Logs
Look for these logs:
```
AdMob initialized
Interstitial ad loaded
Startup ad already shown this session  (on subsequent attempts)
```

---

## 8. Going Live

### Before Publishing

1. **Replace Test IDs with Real IDs**
   - Update `ad_service.dart` with your actual Ad Unit IDs
   - Update `AndroidManifest.xml` with your Android App ID
   - Update `Info.plist` with your iOS App ID

2. **AdMob Policy Compliance**
   - Don't click your own ads
   - Don't encourage users to click ads
   - Don't place ads that interfere with app content

3. **App Store Requirements**
   - iOS: Add App Tracking Transparency if targeting iOS 14+
   - Android: Ensure proper consent for EU users (GDPR)

### Production Checklist
- [ ] Replace all test Ad Unit IDs with production IDs
- [ ] Replace App IDs in AndroidManifest.xml and Info.plist
- [ ] Test on real devices
- [ ] Verify ads are showing correctly
- [ ] Monitor AdMob dashboard for impressions

---

## File Changes Summary

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `google_mobile_ads: ^5.1.0` |
| `android/app/src/main/AndroidManifest.xml` | Add AdMob App ID meta-data |
| `ios/Runner/Info.plist` | Add GADApplicationIdentifier |
| `lib/services/ad_service.dart` | **NEW FILE** - Ad loading logic |
| `lib/main.dart` | Initialize AdMob SDK |
| `lib/screens/splash_screen.dart` | Show ad after splash |

---

## Troubleshooting

### Ad Not Showing
- Check if using correct Ad Unit ID
- Ensure device has internet connection
- Wait for ad to load (check logs)
- New AdMob accounts may have delayed ad serving

### App Crashes
- Ensure minSdk is 21 or higher for Android
- Check that App ID is correct in manifest/plist
- Verify package is properly installed

### Policy Violation Warning
- Never use real Ad IDs during development
- Don't test by clicking ads repeatedly
- Use Google's official test IDs

---

## Support

- [AdMob Help Center](https://support.google.com/admob)
- [google_mobile_ads Package](https://pub.dev/packages/google_mobile_ads)
- [Flutter AdMob Documentation](https://developers.google.com/admob/flutter/quick-start)
