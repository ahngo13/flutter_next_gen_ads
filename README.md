# flutter_next_gen_ads

[![pub package](https://img.shields.io/pub/v/flutter_next_gen_ads.svg)](https://pub.dev/packages/flutter_next_gen_ads)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**English** · [한국어](README.ko.md) · [日本語](README.ja.md) · [简体中文](README.zh-CN.md)

Flutter wrapper for the **Google Mobile Ads (GMA) Next-Gen SDK 1.0+** — Banner,
Interstitial, Rewarded Interstitial, and App Open ads on Android.

> ⚠️ **Android only.** The GMA Next-Gen SDK is currently GA on Android only.
> For iOS, combine this package with [`google_mobile_ads`](https://pub.dev/packages/google_mobile_ads).
>
> ⚠️ **Unofficial.** This package is not affiliated with, endorsed by, or
> sponsored by Google. *AdMob*, *Google Mobile Ads*, and *Flutter* are
> trademarks of Google LLC. This plugin wraps the publicly distributed GMA
> Next-Gen SDK for convenience.

## Why this package?

The official `google_mobile_ads` plugin still uses the **legacy** GMA SDK at
the time of writing. If you want Next-Gen SDK features today on Android —
notably the **`InterstitialAdPreloader`** / **`RewardedInterstitialAdPreloader`**
pool-based preloaders that the legacy SDK lacks — this is the shortest path.

## Requirements

| | |
|---|---|
| Flutter | ≥ 3.10 |
| Dart | ≥ 3.10.7 |
| Android `compileSdk` | **35** |
| Android `minSdk` | **24** |
| Kotlin | ≥ 1.9 |

## Install

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_next_gen_ads: ^0.1.0
```

Add your AdMob app ID to `android/app/src/main/AndroidManifest.xml`:

```xml
<application ...>
  <meta-data
      android:name="com.google.android.gms.ads.APPLICATION_ID"
      android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
  ...
</application>
```

> Use AdMob's test ID `ca-app-pub-3940256099942544~3347511713` for local
> development. Replace before shipping.

## Quick start

### Initialize once at app startup

```dart
import 'package:flutter_next_gen_ads/flutter_next_gen_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.initialize(); // reads appId from AndroidManifest

  // CRITICAL during development: register your dev device so real ads
  // don't accidentally serve and trigger AdMob policy violations.
  await MobileAds.setRequestConfiguration(const RequestConfiguration(
    testDeviceIds: ['YOUR_DEVICE_HASH'], // grep logcat for the hash
  ));

  runApp(const MyApp());
}
```

### Banner ad

```dart
SizedBox(
  height: 120,
  child: BannerAdView(
    adUnitId: 'ca-app-pub-XXX/YYY',
    size: AdSize.largeAnchored(),
  ),
)
```

Or use the convenience `height:` param:

```dart
const BannerAdView(
  adUnitId: 'ca-app-pub-XXX/YYY',
  size: AdSize.largeAnchored(),
  height: 120,
)
```

### Interstitial ad

```dart
try {
  final ad = await InterstitialAd.load(
    adUnitId: 'ca-app-pub-XXX/YYY',
  );
  ad.listener = InterstitialAdListener(
    onAdDismissedFullScreenContent: () => debugPrint('dismissed'),
  );
  await ad.show();
} on AdLoadException catch (e) {
  debugPrint('load failed: ${e.error}');
}
```

### Rewarded interstitial ad

```dart
try {
  final ad = await RewardedInterstitialAd.load(
    adUnitId: 'ca-app-pub-XXX/YYY',
  );
  await ad.show(
    onUserEarnedReward: (reward) {
      grantCoins(reward.amount); // reward.type also available
    },
  );
} on AdLoadException catch (e) {
  debugPrint('rewarded failed: ${e.error}');
}
```

### App open ad (with 4-hour expiry handling)

```dart
class _RootState extends State<RootWidget> with WidgetsBindingObserver {
  AppOpenAd? _ad;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _preload();
  }

  Future<void> _preload() async {
    try {
      _ad = await AppOpenAd.load(adUnitId: 'ca-app-pub-XXX/YYY');
      _ad!.listener = AppOpenAdListener(
        onAdDismissedFullScreenContent: () {
          _ad = null;
          _preload();
        },
      );
    } on AdLoadException catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final ad = _ad;
      if (ad != null && await ad.isAvailable()) await ad.show();
    }
  }
  // ...
}
```

### Preloader pool (Next-Gen exclusive)

Keep a pool of interstitial / rewarded ads ready so `show()` returns
instantly instead of waiting on a network round trip.

```dart
// Startup: fill the pool
await InterstitialAdPreloader.start(
  adUnitId: 'ca-app-pub-XXX/YYY',
  bufferSize: 2,
);

// Show time: poll the pool; fall back to a fresh load if empty
InterstitialAd? ad = await InterstitialAdPreloader.poll(
  adUnitId: 'ca-app-pub-XXX/YYY',
);
ad ??= await InterstitialAd.load(adUnitId: 'ca-app-pub-XXX/YYY');
await ad.show();
```

### Ad targeting hints

```dart
const request = AdRequest(
  keywords: ['flutter', 'mobile-dev'],
  contentUrl: 'https://example.com/article-being-read',
  customTargeting: {'genre': ['action', 'adventure']},
);

final ad = await InterstitialAd.load(
  adUnitId: 'ca-app-pub-XXX/YYY',
  request: request,
);
```

## Cross-platform usage (Android + iOS)

This plugin is Android-only. For iOS in the same codebase, conditionally
fall back to `google_mobile_ads`:

```dart
import 'dart:io' show Platform;

Future<void> showInterstitial(String adUnitId) async {
  if (Platform.isAndroid) {
    // Use flutter_next_gen_ads
    final ad = await InterstitialAd.load(adUnitId: adUnitId);
    await ad.show();
  } else if (Platform.isIOS) {
    // Use google_mobile_ads (separate setup required)
    // ...
  }
}
```

The `BannerAdView` widget collapses to its `placeholder` on non-Android
platforms automatically, so layouts keep working.

## API surface

Re-exported from `package:flutter_next_gen_ads/flutter_next_gen_ads.dart`:

- `MobileAds` — `initialize()`, `getVersion()`, `setRequestConfiguration()`
- `RequestConfiguration` + enums (`TagForChildDirectedTreatment`,
  `TagForUnderAgeOfConsent`, `MaxAdContentRating`,
  `PublisherPrivacyPersonalizationState`)
- `BannerAdView`, `BannerAdListener`, `AdSize` (`anchored`, `largeAnchored`,
  `inline` factories)
- `InterstitialAd`, `InterstitialAdListener`
- `RewardedInterstitialAd`, `RewardedInterstitialAdListener`, `RewardItem`
- `AppOpenAd`, `AppOpenAdListener`
- `InterstitialAdPreloader`, `RewardedInterstitialAdPreloader`
- `AdRequest`, `AdError`, `AdLoadException`

## Roadmap

- **0.2.0** — Native ads (`NativeAd`, `NativeAdView`, `NativeAdPreloader`).
- **0.3.0+** — iOS support (when GMA Next-Gen iOS SDK reaches GA).

## Troubleshooting

**Banner shows blank space.** `BannerAdView` needs explicit bounded
constraints from its immediate parent. Wrap in `SizedBox(height: …)` or pass
the `height:` parameter — without bounds Flutter silently skips PlatformView
creation.

**`AdLoadException(code: 3, message: No fill)`.** AdMob has no inventory for
your test request right now. Most test units always return ads, so retry or
verify the ad unit ID.

**App killed shortly after launch on emulator.** The GMA SDK + WebView is
~300 MB at runtime. Emulators with < 4 GB RAM may OOM. Use a real device or
allocate more emulator memory.

**Real device sees real ads, not test ads.** Call
`MobileAds.setRequestConfiguration(RequestConfiguration(testDeviceIds: [...]))`
before loading any ads. Find your device's hash in logcat — search for
`Use RequestConfiguration.Builder.setTestDeviceIds`.

## Sponsor

<p align="center">
  <a href="https://github.com/sponsors/ahngo13">
    <img src="https://img.shields.io/badge/Sponsor%20on%20GitHub-%E2%9D%A4-ea4aaa?style=for-the-badge&logo=github-sponsors&logoColor=white" alt="Sponsor on GitHub" />
  </a>
</p>

If this package saved you a day of work, consider sponsoring a day of mine.

Your sponsorship funds:

- **0.2.0 Native ads** — in active development
- **Bug fixes & SDK upgrades** — keeping pace with Google releases
- **Issue & PR triage** — replying within days, not weeks

Built and maintained by [**Hamlet Shu**](https://github.com/ahngo13) — an independent Flutter developer based in Seoul, Korea.

## License

MIT — see [LICENSE](LICENSE).
