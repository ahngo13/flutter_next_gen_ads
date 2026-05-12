import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ad_error.dart';
import 'ad_request.dart';
import 'ad_size.dart';

/// Lifecycle callbacks fired by a [BannerAdView].
class BannerAdListener {
  const BannerAdListener({
    this.onAdLoaded,
    this.onAdFailedToLoad,
    this.onAdImpression,
    this.onAdClicked,
    this.onAdShowedFullScreenContent,
    this.onAdDismissedFullScreenContent,
    this.onAdFailedToShowFullScreenContent,
    this.onAdRefreshed,
    this.onAdFailedToRefresh,
  });

  final VoidCallback? onAdLoaded;
  final void Function(AdError error)? onAdFailedToLoad;
  final VoidCallback? onAdImpression;
  final VoidCallback? onAdClicked;
  final VoidCallback? onAdShowedFullScreenContent;
  final VoidCallback? onAdDismissedFullScreenContent;
  final void Function(AdError error)? onAdFailedToShowFullScreenContent;

  /// Fires each time the SDK rotates to a new ad creative.
  ///
  /// Auto-refresh is controlled via the **AdMob console** for the ad unit
  /// (not from this plugin). When enabled, the SDK swaps in a new ad while
  /// the banner is visible and invokes this callback for each refresh.
  final VoidCallback? onAdRefreshed;

  /// Fires when an auto-refresh attempt fails (e.g. no fill).
  final void Function(AdError error)? onAdFailedToRefresh;
}

/// Widget that hosts a GMA Next-Gen banner ad inside the Flutter view tree.
///
/// **Sizing.** [BannerAdView] expects to be given an explicit size by its
/// parent (Flutter PlatformViews need bounded constraints to be created).
/// Wrap it in a `SizedBox`, place it inside a `Column` with a `SizedBox`
/// sibling, or pass an explicit [height] — otherwise the ad will silently
/// fail to render. A 50-100dp height covers most adaptive banner sizes;
/// 100-130dp for [AdSize.largeAnchored].
///
/// **Initialization.** `MobileAds.initialize()` must complete before this
/// widget mounts.
///
/// **Cross-platform.** On non-Android platforms the widget collapses to
/// [SizedBox.shrink] (or the supplied [placeholder]).
///
/// ```dart
/// SizedBox(
///   height: 120,
///   child: BannerAdView(
///     adUnitId: 'ca-app-pub-…/…',
///     size: AdSize.largeAnchored(),
///   ),
/// )
/// ```
class BannerAdView extends StatefulWidget {
  const BannerAdView({
    super.key,
    required this.adUnitId,
    this.size = const AdSize.anchored(),
    this.listener,
    this.placeholder,
    this.height,
    this.request,
  });

  /// AdMob ad unit ID. For testing use
  /// `ca-app-pub-3940256099942544/9214589741`.
  final String adUnitId;

  /// Logical size hint passed to the native banner.
  final AdSize size;

  /// Optional callbacks for ad lifecycle events.
  final BannerAdListener? listener;

  /// Optional widget shown on non-Android platforms, or after the ad fails
  /// to load. Pass nothing to collapse the space entirely in those cases.
  final Widget? placeholder;

  /// Convenience shortcut for the common case of "wrap me in a SizedBox of
  /// this height". If omitted, [BannerAdView] uses whatever size its parent
  /// supplies via [Container] / [SizedBox] / [Expanded] etc.
  final double? height;

  /// Optional targeting hints for this banner request.
  final AdRequest? request;

  @override
  State<BannerAdView> createState() => _BannerAdViewState();
}

class _BannerAdViewState extends State<BannerAdView> {
  MethodChannel? _viewChannel;
  bool _adFailed = false;

  void _onPlatformViewCreated(int id) {
    final channel = MethodChannel('next_gen_sdk/banner_ad_$id');
    _viewChannel = channel;
    channel.setMethodCallHandler(_handleEvent);
  }

  @override
  void didUpdateWidget(covariant BannerAdView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final adUnitChanged = oldWidget.adUnitId != widget.adUnitId;
    final sizeChanged = oldWidget.size.widthDp != widget.size.widthDp ||
        oldWidget.size.type != widget.size.type ||
        oldWidget.size.maxHeightDp != widget.size.maxHeightDp;
    final requestChanged = !mapEquals(
      oldWidget.request?.toMap(),
      widget.request?.toMap(),
    );
    if (adUnitChanged || sizeChanged || requestChanged) {
      debugPrint(
        '[flutter_next_gen_ads] BannerAdView props changed but the '
        'PlatformView is reused. Pass a `key: ValueKey(adUnitId)` from the '
        'parent to force recreation.',
      );
    }
  }

  Future<dynamic> _handleEvent(MethodCall call) async {
    final args = call.arguments;
    final map = (args is Map) ? args : const {};
    switch (call.method) {
      case 'onAdLoaded':
        widget.listener?.onAdLoaded?.call();
        break;
      case 'onAdFailedToLoad':
        if (mounted) setState(() => _adFailed = true);
        widget.listener?.onAdFailedToLoad?.call(AdError.fromMap(map));
        break;
      case 'onAdImpression':
        widget.listener?.onAdImpression?.call();
        break;
      case 'onAdClicked':
        widget.listener?.onAdClicked?.call();
        break;
      case 'onAdShowedFullScreenContent':
        widget.listener?.onAdShowedFullScreenContent?.call();
        break;
      case 'onAdDismissedFullScreenContent':
        widget.listener?.onAdDismissedFullScreenContent?.call();
        break;
      case 'onAdFailedToShowFullScreenContent':
        widget.listener?.onAdFailedToShowFullScreenContent?.call(AdError.fromMap(map));
        break;
      case 'onAdRefreshed':
        widget.listener?.onAdRefreshed?.call();
        break;
      case 'onAdFailedToRefresh':
        widget.listener?.onAdFailedToRefresh?.call(AdError.fromMap(map));
        break;
    }
  }

  @override
  void dispose() {
    _viewChannel?.setMethodCallHandler(null);
    _viewChannel = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Non-Android / web: collapse to the supplied placeholder so the host
    // layout still works on those platforms.
    if (kIsWeb || !Platform.isAndroid) {
      return widget.placeholder ?? const SizedBox.shrink();
    }

    // Show the failure placeholder once the load callback reports an error.
    if (_adFailed) {
      return widget.placeholder ?? const SizedBox.shrink();
    }

    final params = <String, dynamic>{
      'adUnitId': widget.adUnitId,
      'widthDp': widget.size.widthDp,
      'sizeType': widget.size.type,
      if (widget.size.maxHeightDp != null) 'maxHeightDp': widget.size.maxHeightDp,
      if (widget.request != null) 'request': widget.request!.toMap(),
    };

    final adView = AndroidView(
      viewType: 'next_gen_sdk/banner_ad',
      onPlatformViewCreated: _onPlatformViewCreated,
      creationParams: params,
      creationParamsCodec: const StandardMessageCodec(),
    );

    // If [height] is supplied, bound the AndroidView explicitly. Otherwise
    // rely on the parent to give us bounded constraints (Flutter
    // PlatformViews are skipped when given unbounded height).
    if (widget.height != null) {
      return SizedBox(height: widget.height, child: adView);
    }
    return adView;
  }
}
