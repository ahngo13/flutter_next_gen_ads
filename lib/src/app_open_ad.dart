import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ad_error.dart';
import 'ad_request.dart';
import 'channel.dart';

/// Lifecycle callbacks fired by an [AppOpenAd].
class AppOpenAdListener {
  const AppOpenAdListener({
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

/// Full-screen ad shown when the user opens (or returns to) the app.
///
/// App open ads expire 4 hours after they are loaded; use [isAvailable] to
/// check before calling [show]. Typical usage is to keep one loaded and
/// trigger [show] from a [WidgetsBindingObserver] when
/// `AppLifecycleState.resumed` fires.
class AppOpenAd {
  AppOpenAd._({required this.adId, required this.adUnitId});

  final String adId;
  final String adUnitId;

  AppOpenAdListener? _listener;
  bool _disposed = false;

  set listener(AppOpenAdListener? value) {
    _listener = value;
    if (value == null) {
      AdsChannel.instance.unregister(adId);
      return;
    }
    AdsChannel.instance.register(adId, {
      'onAppOpenShowed': (_) => value.onAdShowedFullScreenContent?.call(),
      'onAppOpenDismissed': (_) {
        value.onAdDismissedFullScreenContent?.call();
        _markConsumed();
      },
      'onAppOpenFailedToShow': (a) {
        value.onAdFailedToShowFullScreenContent?.call(AdError.fromMap(a));
        _markConsumed();
      },
      'onAppOpenImpression': (_) => value.onAdImpression?.call(),
      'onAppOpenClicked': (_) => value.onAdClicked?.call(),
    });
  }

  AppOpenAdListener? get listener => _listener;

  /// Load a single app open ad. Sample test unit:
  /// `ca-app-pub-3940256099942544/9257395921`.
  ///
  /// Pass an [AdRequest] to attach targeting (keywords, contentUrl, etc.).
  /// Returns the loaded ad. Throws [AdLoadException] on failure.
  static Future<AppOpenAd> load({
    required String adUnitId,
    AdRequest? request,
  }) async {
    final raw = await AdsChannel.instance.channel.invokeMethod<Map<dynamic, dynamic>>(
      'loadAppOpen',
      {'adUnitId': adUnitId, if (request != null) 'request': request.toMap()},
    );
    final loaded = (raw?['loaded'] as bool?) ?? false;
    if (!loaded) {
      throw AdLoadException(AdError.fromMap((raw?['error'] as Map?) ?? const {}));
    }
    return AppOpenAd._(
      adId: raw!['adId'] as String,
      adUnitId: adUnitId,
    );
  }

  /// Returns false if the ad has been consumed, never loaded, or expired
  /// (> 4 hours since load).
  Future<bool> isAvailable() async {
    if (_disposed) return false;
    final raw = await AdsChannel.instance.channel.invokeMethod<bool>(
      'isAppOpenAvailable',
      {'adId': adId},
    );
    return raw ?? false;
  }

  /// Show the ad. Throws [StateError] if it has already been shown or
  /// disposed.
  Future<void> show() async {
    if (_disposed) {
      throw StateError('AppOpenAd has already been consumed or disposed.');
    }
    await AdsChannel.instance.channel.invokeMethod<void>(
      'showAppOpen',
      {'adId': adId},
    );
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    AdsChannel.instance.unregister(adId);
    await AdsChannel.instance.channel.invokeMethod<void>(
      'disposeAppOpen',
      {'adId': adId},
    );
  }

  void _markConsumed() {
    _disposed = true;
    AdsChannel.instance.unregister(adId);
  }
}
