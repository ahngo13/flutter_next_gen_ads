import 'package:flutter/material.dart';
import 'package:flutter_next_gen_ads/flutter_next_gen_ads.dart';

// Test ad unit IDs from the GMA Next-Gen SDK docs. Replace with your own
// production IDs before shipping.
const _bannerAdUnit = 'ca-app-pub-3940256099942544/9214589741';
const _interstitialAdUnit = 'ca-app-pub-3940256099942544/1033173712';
const _rewardedInterstitialAdUnit = 'ca-app-pub-3940256099942544/5354046379';
const _appOpenAdUnit = 'ca-app-pub-3940256099942544/9257395921';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.initialize();

  // IMPORTANT for development: register your dev device as a test device so
  // real ads don't accidentally serve and trigger AdMob policy violations.
  // Replace with your device's actual hash (find it in logcat — search for
  // "Use RequestConfiguration.Builder.setTestDeviceIds").
  await MobileAds.setRequestConfiguration(const RequestConfiguration(
    testDeviceIds: ['TESTING_DEVICE_HASH'],
  ));

  // Start filling the interstitial preloader pool so the first show()
  // returns instantly.
  await InterstitialAdPreloader.start(
    adUnitId: _interstitialAdUnit,
    bufferSize: 2,
  );

  runApp(const FlutterNextGenAdsDemoApp());
}

class FlutterNextGenAdsDemoApp extends StatelessWidget {
  const FlutterNextGenAdsDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_next_gen_ads Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const _DemoHomePage(),
    );
  }
}

class _DemoHomePage extends StatefulWidget {
  const _DemoHomePage();

  @override
  State<_DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<_DemoHomePage> with WidgetsBindingObserver {
  AppOpenAd? _appOpenAd;
  String _status = 'Ready.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _preloadAppOpenAd();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appOpenAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _maybeShowAppOpenAd();
    }
  }

  Future<void> _preloadAppOpenAd() async {
    try {
      final ad = await AppOpenAd.load(adUnitId: _appOpenAdUnit);
      if (!mounted) {
        await ad.dispose();
        return;
      }
      _appOpenAd = ad
        ..listener = AppOpenAdListener(
          onAdDismissedFullScreenContent: () {
            _appOpenAd = null;
            _preloadAppOpenAd();
          },
        );
      setState(() => _status = 'App open ad pre-loaded.');
    } on AdLoadException catch (e) {
      if (mounted) setState(() => _status = 'App open load failed: ${e.error}');
    }
  }

  Future<void> _maybeShowAppOpenAd() async {
    final ad = _appOpenAd;
    if (ad == null) return;
    if (await ad.isAvailable()) await ad.show();
  }

  Future<void> _showInterstitial() async {
    setState(() => _status = 'Showing interstitial…');
    try {
      InterstitialAd? ad = await InterstitialAdPreloader.poll(
        adUnitId: _interstitialAdUnit,
      );
      ad ??= await InterstitialAd.load(adUnitId: _interstitialAdUnit);
      ad.listener = InterstitialAdListener(
        onAdDismissedFullScreenContent: () =>
            setState(() => _status = 'Interstitial dismissed.'),
        onAdFailedToShowFullScreenContent: (e) =>
            setState(() => _status = 'Show failed: $e'),
      );
      await ad.show();
    } on AdLoadException catch (e) {
      setState(() => _status = 'Interstitial failed: ${e.error}');
    }
  }

  Future<void> _showRewarded() async {
    setState(() => _status = 'Loading rewarded…');
    try {
      final ad = await RewardedInterstitialAd.load(
        adUnitId: _rewardedInterstitialAdUnit,
      );
      ad.listener = RewardedInterstitialAdListener(
        onAdDismissedFullScreenContent: () =>
            setState(() => _status = 'Rewarded dismissed.'),
      );
      await ad.show(
        onUserEarnedReward: (reward) {
          setState(() => _status = 'Reward: ${reward.amount} ${reward.type}');
        },
      );
    } on AdLoadException catch (e) {
      setState(() => _status = 'Rewarded failed: ${e.error}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('flutter_next_gen_ads Demo'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_status, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _showInterstitial,
                      child: const Text('Show Interstitial (preloaded)'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _showRewarded,
                      child: const Text('Show Rewarded'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _maybeShowAppOpenAd,
                      child: const Text('Show App Open Ad (if loaded)'),
                    ),
                  ],
                ),
              ),
            ),
            // Banner ad — height is given explicitly via the `height` arg.
            const BannerAdView(
              adUnitId: _bannerAdUnit,
              size: AdSize.largeAnchored(),
              height: 120,
            ),
          ],
        ),
      ),
    );
  }
}
