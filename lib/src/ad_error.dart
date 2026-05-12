/// Information about why an ad failed to load or show.
class AdError {
  const AdError({required this.code, required this.message});

  /// Error code from the GMA Next-Gen SDK.
  final int code;

  /// Human-readable description of the failure.
  final String message;

  factory AdError.fromMap(Map<dynamic, dynamic> map) => AdError(
    code: (map['code'] as int?) ?? -1,
    message: (map['message'] as String?) ?? 'unknown',
  );

  @override
  String toString() => 'AdError(code: $code, message: $message)';
}

/// Thrown by `XxxAd.load(...)` when the SDK reports a load failure.
///
/// Catch this to recover from no-fill / network / config issues.
class AdLoadException implements Exception {
  const AdLoadException(this.error);
  final AdError error;

  @override
  String toString() => 'AdLoadException: $error';
}
