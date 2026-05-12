import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_next_gen_ads/flutter_next_gen_ads.dart';

void main() {
  testWidgets('BannerAdView constructs without throwing', (WidgetTester tester) async {
    // Smoke test: just ensure the BannerAdView widget can be instantiated.
    // Full ad-loading behavior requires a real Android device.
    const widget = SizedBox(
      width: 360,
      height: 100,
      child: BannerAdView(
        adUnitId: 'ca-app-pub-3940256099942544/9214589741',
      ),
    );
    expect(widget.child, isA<BannerAdView>());
  });
}
