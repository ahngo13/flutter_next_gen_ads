/// Targeting parameters attached to a single ad request.
///
/// Maps to the GMA Next-Gen SDK's `AdRequest.Builder` / `BannerAdRequest.Builder`
/// configuration methods (`addKeyword`, `setContentUrl`, `putCustomTargeting`,
/// etc.). All fields are optional — pass `const AdRequest()` if you have no
/// targeting hints.
///
/// ```dart
/// const request = AdRequest(
///   keywords: ['flutter', 'mobile-dev'],
///   contentUrl: 'https://example.com/article',
///   customTargeting: {'genre': ['action', 'adventure']},
/// );
/// final ad = await InterstitialAd.load(adUnitId: '...', request: request);
/// ```
class AdRequest {
  const AdRequest({
    this.keywords = const <String>[],
    this.customTargeting = const <String, List<String>>{},
    this.contentUrl,
    this.neighboringContentUrls = const <String>{},
    this.requestAgent,
    this.categoryExclusions = const <String>[],
    this.publisherProvidedId,
  });

  /// Keywords describing the content the ad is shown alongside.
  final List<String> keywords;

  /// Key-value targeting. Each key maps to one or more values.
  final Map<String, List<String>> customTargeting;

  /// URL of the content the ad is anchored to (e.g. the article being read).
  final String? contentUrl;

  /// Up to 4 URLs adjacent to the primary content. Helps the SDK pick
  /// contextually relevant ads.
  final Set<String> neighboringContentUrls;

  /// Identifies the requesting party (e.g. `'my_app_v1.2'`). Used for SDK
  /// analytics / debugging — not for monetization.
  final String? requestAgent;

  /// Category exclusion labels (configured in AdMob console).
  final List<String> categoryExclusions;

  /// Pre-supplied unique publisher-provided ID (used for some advanced
  /// targeting flows). Most apps can leave this null.
  final String? publisherProvidedId;

  /// Convert to the wire format consumed by the Kotlin plugin.
  Map<String, dynamic> toMap() => <String, dynamic>{
    if (keywords.isNotEmpty) 'keywords': keywords,
    if (customTargeting.isNotEmpty) 'customTargeting': customTargeting,
    if (contentUrl != null) 'contentUrl': contentUrl,
    if (neighboringContentUrls.isNotEmpty)
      'neighboringContentUrls': neighboringContentUrls.toList(),
    if (requestAgent != null) 'requestAgent': requestAgent,
    if (categoryExclusions.isNotEmpty) 'categoryExclusions': categoryExclusions,
    if (publisherProvidedId != null) 'publisherProvidedId': publisherProvidedId,
  };
}
