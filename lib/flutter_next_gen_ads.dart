/// Flutter wrapper around the Google Mobile Ads (GMA) Next-Gen SDK 1.0+.
///
/// **Android only.** For iOS, combine this package with `google_mobile_ads`.
///
/// Provides idiomatic Dart access to:
///
/// * [MobileAds] — SDK initialization, version, [RequestConfiguration]
/// * [BannerAdView] — inline banner ads (adaptive anchored / large anchored / inline)
/// * [InterstitialAd] — full-screen interstitial ads
/// * [RewardedInterstitialAd] — rewarded full-screen ads with [RewardItem]
/// * [AppOpenAd] — full-screen ads with 4-hour expiry, for foreground transitions
/// * [InterstitialAdPreloader], [RewardedInterstitialAdPreloader] — pool-based
///   preloading for instant ad display (Next-Gen SDK exclusive)
/// * [AdRequest] — targeting hints (keywords, contentUrl, customTargeting)
library;

export 'src/ad_error.dart';
export 'src/ad_request.dart';
export 'src/ad_size.dart';
export 'src/app_open_ad.dart';
export 'src/banner_ad.dart';
export 'src/interstitial_ad.dart';
export 'src/mobile_ads.dart';
export 'src/preloader.dart';
export 'src/request_configuration.dart' hide applyRequestConfiguration;
export 'src/rewarded_interstitial_ad.dart';
