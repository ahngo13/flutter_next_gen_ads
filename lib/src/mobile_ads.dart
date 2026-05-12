import 'channel.dart';
import 'request_configuration.dart';

/// Result of [MobileAds.initialize].
class InitializationStatus {
  const InitializationStatus({required this.isReady});

  /// True when the SDK has finished initializing adapters.
  final bool isReady;

  factory InitializationStatus._fromMap(Map<dynamic, dynamic>? map) =>
      InitializationStatus(isReady: (map?['isReady'] as bool?) ?? false);
}

/// Entry point for the GMA Next-Gen SDK.
///
/// Call [initialize] exactly once (ideally at app startup) before loading
/// any ads. The native side performs initialization on a background thread,
/// so it is safe to await this from the UI isolate.
class MobileAds {
  MobileAds._();

  /// Initialize the SDK.
  ///
  /// By default the AdMob app ID is read from `AndroidManifest.xml`:
  ///
  /// ```xml
  /// <meta-data
  ///     android:name="com.google.android.gms.ads.APPLICATION_ID"
  ///     android:value="ca-app-pub-xxx~yyy"/>
  /// ```
  ///
  /// If you need to override it at runtime (rare) pass [appId] explicitly.
  /// Throws if neither the argument nor the manifest provides an app ID.
  static Future<InitializationStatus> initialize({String? appId}) async {
    final raw = await AdsChannel.instance.channel.invokeMethod<Map<dynamic, dynamic>>(
      'initialize',
      {'appId': appId},
    );
    return InitializationStatus._fromMap(raw);
  }

  /// Returns the underlying GMA Next-Gen SDK version string.
  static Future<String> getVersion() async {
    final v = await AdsChannel.instance.channel.invokeMethod<String>('getVersion');
    return v ?? '';
  }

  /// Apply a global [RequestConfiguration] to every subsequent ad request.
  ///
  /// During development, set [RequestConfiguration.testDeviceIds] so real ad
  /// units don't serve live impressions on your device — otherwise AdMob may
  /// flag the account.
  static Future<void> setRequestConfiguration(RequestConfiguration config) =>
      applyRequestConfiguration(config);
}
