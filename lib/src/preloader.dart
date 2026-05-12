import 'ad_request.dart';
import 'channel.dart';
import 'interstitial_ad.dart';
import 'rewarded_interstitial_ad.dart';

/// Pool-based preloader for [InterstitialAd]s — the GMA Next-Gen SDK loads
/// ads ahead of time so [poll] returns instantly.
///
/// Typical lifecycle:
///
/// ```dart
/// // App startup: start filling the pool
/// await InterstitialAdPreloader.start(
///   adUnitId: 'ca-app-pub-.../...',
///   bufferSize: 2,
/// );
///
/// // Time to show: poll → show
/// final ad = await InterstitialAdPreloader.poll(adUnitId: '...');
/// if (ad != null) {
///   await ad.show();
/// }
///
/// // When done (e.g. app exit or feature toggle):
/// await InterstitialAdPreloader.destroy(adUnitId: '...');
/// ```
class InterstitialAdPreloader {
  InterstitialAdPreloader._();

  /// Start preloading ads for [adUnitId]. The SDK keeps [bufferSize] ads
  /// ready (default = SDK-managed, usually 2).
  ///
  /// Returns `true` if preloading started successfully. Returns `false` if a
  /// preloader is already active for this ad unit.
  static Future<bool> start({
    required String adUnitId,
    AdRequest? request,
    int? bufferSize,
  }) async {
    final res = await AdsChannel.instance.channel.invokeMethod<bool>(
      'startInterstitialPreloader',
      {
        'adUnitId': adUnitId,
        'request': ?request?.toMap(),
        'bufferSize': ?bufferSize,
      },
    );
    return res ?? false;
  }

  /// Pull the next ready ad off the pool, or `null` if none is available.
  /// The pool refills in the background.
  static Future<InterstitialAd?> poll({required String adUnitId}) async {
    final res = await AdsChannel.instance.channel.invokeMethod<Map<dynamic, dynamic>>(
      'pollInterstitialPreloader',
      {'adUnitId': adUnitId},
    );
    if (res == null) return null;
    final adId = res['adId'] as String?;
    if (adId == null) return null;
    return InterstitialAd.fromPreloaded(adId: adId, adUnitId: adUnitId);
  }

  /// Check whether an ad is currently available without removing it.
  static Future<bool> isAvailable({required String adUnitId}) async {
    final res = await AdsChannel.instance.channel.invokeMethod<bool>(
      'isInterstitialPreloaded',
      {'adUnitId': adUnitId},
    );
    return res ?? false;
  }

  /// Number of ads currently in the pool.
  static Future<int> count({required String adUnitId}) async {
    final res = await AdsChannel.instance.channel.invokeMethod<int>(
      'interstitialPreloaderCount',
      {'adUnitId': adUnitId},
    );
    return res ?? 0;
  }

  /// Stop preloading and clear the pool for [adUnitId].
  static Future<bool> destroy({required String adUnitId}) async {
    final res = await AdsChannel.instance.channel.invokeMethod<bool>(
      'destroyInterstitialPreloader',
      {'adUnitId': adUnitId},
    );
    return res ?? false;
  }
}

/// Pool-based preloader for [RewardedInterstitialAd]s. Same shape as
/// [InterstitialAdPreloader] — see its docs for usage.
class RewardedInterstitialAdPreloader {
  RewardedInterstitialAdPreloader._();

  static Future<bool> start({
    required String adUnitId,
    AdRequest? request,
    int? bufferSize,
  }) async {
    final res = await AdsChannel.instance.channel.invokeMethod<bool>(
      'startRewardedPreloader',
      {
        'adUnitId': adUnitId,
        'request': ?request?.toMap(),
        'bufferSize': ?bufferSize,
      },
    );
    return res ?? false;
  }

  static Future<RewardedInterstitialAd?> poll({required String adUnitId}) async {
    final res = await AdsChannel.instance.channel.invokeMethod<Map<dynamic, dynamic>>(
      'pollRewardedPreloader',
      {'adUnitId': adUnitId},
    );
    if (res == null) return null;
    final adId = res['adId'] as String?;
    if (adId == null) return null;
    return RewardedInterstitialAd.fromPreloaded(adId: adId, adUnitId: adUnitId);
  }

  static Future<bool> isAvailable({required String adUnitId}) async {
    final res = await AdsChannel.instance.channel.invokeMethod<bool>(
      'isRewardedPreloaded',
      {'adUnitId': adUnitId},
    );
    return res ?? false;
  }

  static Future<int> count({required String adUnitId}) async {
    final res = await AdsChannel.instance.channel.invokeMethod<int>(
      'rewardedPreloaderCount',
      {'adUnitId': adUnitId},
    );
    return res ?? 0;
  }

  static Future<bool> destroy({required String adUnitId}) async {
    final res = await AdsChannel.instance.channel.invokeMethod<bool>(
      'destroyRewardedPreloader',
      {'adUnitId': adUnitId},
    );
    return res ?? false;
  }
}
