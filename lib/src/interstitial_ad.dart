import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ad_error.dart';
import 'ad_request.dart';
import 'channel.dart';

/// Lifecycle callbacks fired by an [InterstitialAd].
class InterstitialAdListener {
  const InterstitialAdListener({
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

/// A full-screen interstitial ad.
///
/// Typical usage:
///
/// ```dart
/// try {
///   final ad = await InterstitialAd.load(
///     adUnitId: 'ca-app-pub-3940256099942544/1033173712',
///   );
///   ad.listener = InterstitialAdListener(
///     onAdDismissedFullScreenContent: () => debugPrint('dismissed'),
///   );
///   await ad.show();
/// } on AdLoadException catch (e) {
///   debugPrint('load failed: ${e.error}');
/// }
/// ```
class InterstitialAd {
  InterstitialAd._({required this.adId, required this.adUnitId});

  /// Internal constructor used by `InterstitialAdPreloader.poll` to wrap an
  /// already-adopted native ad. Not part of the public API.
  @internal
  factory InterstitialAd.fromPreloaded({
    required String adId,
    required String adUnitId,
  }) =>
      InterstitialAd._(adId: adId, adUnitId: adUnitId);

  final String adId;
  final String adUnitId;

  InterstitialAdListener? _listener;
  bool _disposed = false;

  /// Attach lifecycle callbacks. Call before [show].
  set listener(InterstitialAdListener? value) {
    _listener = value;
    if (value == null) {
      AdsChannel.instance.unregister(adId);
      return;
    }
    AdsChannel.instance.register(adId, {
      'onInterstitialShowed': (_) => value.onAdShowedFullScreenContent?.call(),
      'onInterstitialDismissed': (_) {
        value.onAdDismissedFullScreenContent?.call();
        _markConsumed();
      },
      'onInterstitialFailedToShow': (a) {
        value.onAdFailedToShowFullScreenContent?.call(AdError.fromMap(a));
        _markConsumed();
      },
      'onInterstitialImpression': (_) => value.onAdImpression?.call(),
      'onInterstitialClicked': (_) => value.onAdClicked?.call(),
    });
  }

  InterstitialAdListener? get listener => _listener;

  /// Load a single interstitial ad. Use AdMob's sample unit ID
  /// `ca-app-pub-3940256099942544/1033173712` for testing.
  ///
  /// Pass an [AdRequest] to attach targeting (keywords, contentUrl, etc.).
  /// Returns the loaded ad. Throws [AdLoadException] on failure.
  static Future<InterstitialAd> load({
    required String adUnitId,
    AdRequest? request,
  }) async {
    final raw = await AdsChannel.instance.channel.invokeMethod<Map<dynamic, dynamic>>(
      'loadInterstitial',
      {'adUnitId': adUnitId, if (request != null) 'request': request.toMap()},
    );
    final loaded = (raw?['loaded'] as bool?) ?? false;
    if (!loaded) {
      throw AdLoadException(AdError.fromMap((raw?['error'] as Map?) ?? const {}));
    }
    return InterstitialAd._(
      adId: raw!['adId'] as String,
      adUnitId: adUnitId,
    );
  }

  /// Show the loaded ad. Must be called from the foreground Activity.
  Future<void> show() async {
    if (_disposed) {
      throw StateError('InterstitialAd has already been disposed.');
    }
    await AdsChannel.instance.channel.invokeMethod<void>(
      'showInterstitial',
      {'adId': adId},
    );
  }

  /// Release native references to this ad. Always call when done.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    AdsChannel.instance.unregister(adId);
    await AdsChannel.instance.channel.invokeMethod<void>(
      'disposeInterstitial',
      {'adId': adId},
    );
  }

  void _markConsumed() {
    _disposed = true;
    AdsChannel.instance.unregister(adId);
  }
}
