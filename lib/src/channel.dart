import 'package:flutter/services.dart';

/// Internal callback signature for plugin -> Dart method dispatching.
typedef AdMethodHandler = void Function(Map<dynamic, dynamic> args);

/// Singleton router around the single `next_gen_sdk` MethodChannel.
///
/// Multiple ad instances share the same channel, so per-ad handlers are
/// registered against the ad's UUID and the channel demultiplexes incoming
/// callbacks by `adId`.
class AdsChannel {
  AdsChannel._() {
    channel.setMethodCallHandler(_dispatch);
  }

  static final AdsChannel instance = AdsChannel._();

  final MethodChannel channel = const MethodChannel('next_gen_sdk');

  final Map<String, Map<String, AdMethodHandler>> _handlers = {};

  void register(String adId, Map<String, AdMethodHandler> handlers) {
    _handlers[adId] = handlers;
  }

  void unregister(String adId) {
    _handlers.remove(adId);
  }

  Future<dynamic> _dispatch(MethodCall call) async {
    final raw = call.arguments;
    if (raw is! Map) return;
    final adId = raw['adId'] as String?;
    if (adId == null) return;
    final byMethod = _handlers[adId];
    final handler = byMethod?[call.method];
    handler?.call(raw);
  }
}
