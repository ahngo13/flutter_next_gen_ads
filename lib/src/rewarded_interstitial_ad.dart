import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ad_error.dart';
import 'ad_request.dart';
import 'channel.dart';

/// Reward granted to a user after watching a rewarded ad.
class RewardItem {
  const RewardItem({required this.amount, required this.type});

  /// Amount of reward (per AdMob configuration).
  final int amount;

  /// Type of reward (per AdMob configuration).
  final String type;

  factory RewardItem.fromMap(Map<dynamic, dynamic> map) => RewardItem(
    amount: (map['amount'] as int?) ?? 0,
    type: (map['type'] as String?) ?? '',
  );

  @override
  String toString() => 'RewardItem(amount: $amount, type: $type)';
}

/// Lifecycle callbacks fired by a [RewardedInterstitialAd].
class RewardedInterstitialAdListener {
  const RewardedInterstitialAdListener({
    this.onAdShowedFullScreenContent,
    this.onAdDismissedFullScreenContent,
    this.onAdFailedToShowFullScreenContent,
    this.onAdImpression,
    this.onAdClicked,
  });

  final VoidCallback? onAdShowedFullScreenContent;
  final VoidCallback? onAdDismissedFullScreenContent;
  final void Function(AdError error)? onAdFailedToShowFullScreenContent;
  final VoidCallback? onAdImpression;
  final VoidCallback? onAdClicked;
}

/// A rewarded interstitial ad. Like an interstitial, but the user earns a
/// reward when watching to completion.
///
/// ```dart
/// try {
///   final ad = await RewardedInterstitialAd.load(
///     adUnitId: 'ca-app-pub-3940256099942544/5354046379',
///   );
///   await ad.show(onUserEarnedReward: (r) => grantCoins(r.amount));
/// } on AdLoadException catch (e) {
///   debugPrint('load failed: ${e.error}');
/// }
/// ```
class RewardedInterstitialAd {
  RewardedInterstitialAd._({required this.adId, required this.adUnitId});

  /// Internal constructor used by `RewardedInterstitialAdPreloader.poll` to
  /// wrap an already-adopted native ad. Not part of the public API.
  @internal
  factory RewardedInterstitialAd.fromPreloaded({
    required String adId,
    required String adUnitId,
  }) =>
      RewardedInterstitialAd._(adId: adId, adUnitId: adUnitId);

  final String adId;
  final String adUnitId;

  RewardedInterstitialAdListener? _listener;
  void Function(RewardItem reward)? _rewardListener;
  bool _disposed = false;

  set listener(RewardedInterstitialAdListener? value) {
    _listener = value;
    _wireHandlers();
  }

  RewardedInterstitialAdListener? get listener => _listener;

  void _wireHandlers() {
    final l = _listener;
    final r = _rewardListener;
    if (l == null && r == null) {
      AdsChannel.instance.unregister(adId);
      return;
    }
    AdsChannel.instance.register(adId, {
      'onRewardedShowed': (_) => l?.onAdShowedFullScreenContent?.call(),
      'onRewardedDismissed': (_) {
        l?.onAdDismissedFullScreenContent?.call();
        _markConsumed();
      },
      'onRewardedFailedToShow': (a) {
        l?.onAdFailedToShowFullScreenContent?.call(AdError.fromMap(a));
        _markConsumed();
      },
      'onRewardedImpression': (_) => l?.onAdImpression?.call(),
      'onRewardedClicked': (_) => l?.onAdClicked?.call(),
      'onUserEarnedReward': (a) => r?.call(RewardItem.fromMap(a)),
    });
  }

  /// Load a single rewarded interstitial ad. Use AdMob's sample unit ID
  /// `ca-app-pub-3940256099942544/5354046379` for testing.
  ///
  /// Pass an [AdRequest] to attach targeting (keywords, contentUrl, etc.).
  /// Returns the loaded ad. Throws [AdLoadException] on failure.
  static Future<RewardedInterstitialAd> load({
    required String adUnitId,
    AdRequest? request,
  }) async {
    final raw = await AdsChannel.instance.channel.invokeMethod<Map<dynamic, dynamic>>(
      'loadRewardedInterstitial',
      {'adUnitId': adUnitId, if (request != null) 'request': request.toMap()},
    );
    final loaded = (raw?['loaded'] as bool?) ?? false;
    if (!loaded) {
      throw AdLoadException(AdError.fromMap((raw?['error'] as Map?) ?? const {}));
    }
    return RewardedInterstitialAd._(
      adId: raw!['adId'] as String,
      adUnitId: adUnitId,
    );
  }

  /// Show the ad. The [onUserEarnedReward] callback fires when the user
  /// watches through to the reward threshold.
  Future<void> show({required void Function(RewardItem reward) onUserEarnedReward}) async {
    if (_disposed) {
      throw StateError('RewardedInterstitialAd has already been disposed.');
    }
    _rewardListener = onUserEarnedReward;
    _wireHandlers();
    await AdsChannel.instance.channel.invokeMethod<void>(
      'showRewardedInterstitial',
      {'adId': adId},
    );
  }

  /// Release native references.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    AdsChannel.instance.unregister(adId);
    await AdsChannel.instance.channel.invokeMethod<void>(
      'disposeRewardedInterstitial',
      {'adId': adId},
    );
  }

  void _markConsumed() {
    _disposed = true;
    AdsChannel.instance.unregister(adId);
  }
}
