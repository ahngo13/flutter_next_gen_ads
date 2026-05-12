# Changelog

All notable changes to `flutter_next_gen_ads` are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned

- Native ad support (NativeAd, NativeAdView, NativeAdLoader).
- NativeAdPreloader for pool-based native ad delivery.
- iOS support (waiting for GMA Next-Gen iOS SDK GA).

## [0.1.3] - 2026-05-12

### Added

- Localized README in Korean, Japanese, and Simplified Chinese
  (`README.ko.md`, `README.ja.md`, `README.zh-CN.md`). Language switcher
  added at the top of every README variant.

### Changed

- Removed "iOS support" from the Sponsor section's funding targets.
  GMA Next-Gen iOS SDK is not yet GA and Google has not announced a
  date — sponsorship copy should describe work the maintainer can
  actually do, not external dependencies. iOS is still documented in
  the Roadmap as 0.3.0+ (pending GMA Next-Gen iOS GA).

## [0.1.2] - 2026-05-12

### Changed

- Redesigned README "Sponsor" section with a GitHub Sponsors badge,
  concrete funding targets (0.2.0 Native ads, iOS GA, SDK upgrades),
  and a maintainer signature. Pure docs change — no API impact.

## [0.1.1] - 2026-05-12

### Changed

- Removed non-Android example scaffolds (`ios`, `macos`, `linux`, `windows`,
  `web`) so the example reflects the plugin's Android-only scope. Cuts
  published package size from 284 KB to 31 KB.
- Added GitHub Sponsors link via `pubspec.yaml` `funding:` field and
  `.github/FUNDING.yml`. Funding link is now surfaced on the pub.dev page.

## [0.1.0] - 2026-05-12

Initial release. Wraps the GMA Next-Gen SDK 1.0.1 for Android.

### Added

- `MobileAds.initialize()` — reads AdMob app ID from `AndroidManifest.xml`
  meta-data automatically; pass an explicit `appId` to override.
- `MobileAds.setRequestConfiguration()` with full `RequestConfiguration`
  support: `testDeviceIds`, `tagForChildDirectedTreatment`,
  `tagForUnderAgeOfConsent`, `maxAdContentRating`,
  `publisherPrivacyPersonalizationState`.
- `MobileAds.getVersion()`.
- `BannerAdView` widget — adaptive anchored / large anchored / inline sizes.
  Supports `height`, `placeholder`, listener callbacks, and per-request
  `AdRequest` targeting.
- `InterstitialAd.load()` / `show()` with `InterstitialAdListener`.
- `RewardedInterstitialAd.load()` / `show(onUserEarnedReward:)` with
  `RewardItem` payload.
- `AppOpenAd.load()` / `show()` with 4-hour expiry tracking via
  `isAvailable()`.
- `InterstitialAdPreloader` and `RewardedInterstitialAdPreloader` — pool-based
  preloading exclusive to the Next-Gen SDK. Polled ads adopt into the
  standard `InterstitialAd` / `RewardedInterstitialAd` show flow.
- `AdRequest` builder: `keywords`, `customTargeting`, `contentUrl`,
  `neighboringContentUrls`, `requestAgent`, `categoryExclusions`,
  `publisherProvidedId`.
- `AdError` + `AdLoadException` — load failures surface as exceptions so
  `try/catch` is the natural error-handling pattern.

### Platform support

- **Android 7.0 (API 24) and above** — matches the Next-Gen SDK requirement.
- iOS / Web / desktop — `BannerAdView` collapses to `placeholder` /
  `SizedBox.shrink`; full-screen ad calls throw `MissingPluginException`. Pair
  with [`google_mobile_ads`](https://pub.dev/packages/google_mobile_ads) for
  iOS support.

### Known limitations

- Native ads not yet implemented (planned for 0.2.0).
- `BannerAdView` does not auto-reload when `adUnitId` changes on the same
  widget instance. Pass a `key: ValueKey(adUnitId)` to force recreation.
