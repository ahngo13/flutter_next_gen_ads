import 'channel.dart';

/// COPPA / child-directed treatment.
enum TagForChildDirectedTreatment { unspecified, no, yes }

/// EEA under-age-of-consent treatment.
enum TagForUnderAgeOfConsent { unspecified, no, yes }

/// Maximum content rating allowed by the publisher.
enum MaxAdContentRating { unspecified, g, pg, t, ma }

/// Publisher-level personalization toggle (typically used when implementing
/// "Do not sell my data" controls).
enum PublisherPrivacyPersonalizationState { defaultState, enabled, disabled }

/// Global configuration applied to every ad request from the SDK.
///
/// Use [MobileAds.setRequestConfiguration] to apply. Most importantly, set
/// [testDeviceIds] during development so real ad units don't accidentally
/// serve live impressions on your dev device:
///
/// ```dart
/// await MobileAds.setRequestConfiguration(const RequestConfiguration(
///   testDeviceIds: ['33BE2250B43518CCDA7DE426D04EE231'],
/// ));
/// ```
class RequestConfiguration {
  const RequestConfiguration({
    this.testDeviceIds = const <String>[],
    this.tagForChildDirectedTreatment,
    this.tagForUnderAgeOfConsent,
    this.maxAdContentRating,
    this.publisherPrivacyPersonalizationState,
  });

  /// Device IDs that should always receive test ads. Find your device's ID in
  /// logcat: search for "Use RequestConfiguration.Builder.setTestDeviceIds".
  final List<String> testDeviceIds;

  /// COPPA setting. Set to [TagForChildDirectedTreatment.yes] for apps that
  /// target children.
  final TagForChildDirectedTreatment? tagForChildDirectedTreatment;

  /// EEA under-age-of-consent setting.
  final TagForUnderAgeOfConsent? tagForUnderAgeOfConsent;

  /// Highest content rating allowed.
  final MaxAdContentRating? maxAdContentRating;

  /// Publisher-level personalization opt-in/out.
  final PublisherPrivacyPersonalizationState? publisherPrivacyPersonalizationState;

  /// Convert to the wire format consumed by the Kotlin plugin.
  Map<String, dynamic> toMap() => <String, dynamic>{
    'testDeviceIds': testDeviceIds,
    if (tagForChildDirectedTreatment != null)
      'tagForChildDirectedTreatment': switch (tagForChildDirectedTreatment!) {
        TagForChildDirectedTreatment.yes => 'true',
        TagForChildDirectedTreatment.no => 'false',
        TagForChildDirectedTreatment.unspecified => 'unspecified',
      },
    if (tagForUnderAgeOfConsent != null)
      'tagForUnderAgeOfConsent': switch (tagForUnderAgeOfConsent!) {
        TagForUnderAgeOfConsent.yes => 'true',
        TagForUnderAgeOfConsent.no => 'false',
        TagForUnderAgeOfConsent.unspecified => 'unspecified',
      },
    if (maxAdContentRating != null)
      'maxAdContentRating': switch (maxAdContentRating!) {
        MaxAdContentRating.g => 'g',
        MaxAdContentRating.pg => 'pg',
        MaxAdContentRating.t => 't',
        MaxAdContentRating.ma => 'ma',
        MaxAdContentRating.unspecified => 'unspecified',
      },
    if (publisherPrivacyPersonalizationState != null)
      'publisherPrivacyPersonalizationState':
          switch (publisherPrivacyPersonalizationState!) {
        PublisherPrivacyPersonalizationState.enabled => 'enabled',
        PublisherPrivacyPersonalizationState.disabled => 'disabled',
        PublisherPrivacyPersonalizationState.defaultState => 'default',
      },
  };
}

/// Extension exposing [setRequestConfiguration] on the public `MobileAds`
/// API. Kept here so `mobile_ads.dart` stays focused on init/version.
extension MobileAdsRequestConfiguration on Object {
  // unused — see static method on MobileAds
}

/// Apply [config] as the SDK's global request configuration. Subsequent ad
/// loads will honor it.
Future<void> applyRequestConfiguration(RequestConfiguration config) async {
  await AdsChannel.instance.channel.invokeMethod<void>(
    'setRequestConfiguration',
    {'config': config.toMap()},
  );
}
