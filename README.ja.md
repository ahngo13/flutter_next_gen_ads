# flutter_next_gen_ads

[![pub package](https://img.shields.io/pub/v/flutter_next_gen_ads.svg)](https://pub.dev/packages/flutter_next_gen_ads)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[English](README.md) · [한국어](README.ko.md) · **日本語** · [简体中文](README.zh-CN.md)

**Google Mobile Ads (GMA) Next-Gen SDK 1.0+** をラップした Flutter プラグイン
— Android でバナー / インタースティシャル / リワード インタースティシャル /
アプリ オープン広告に対応します。

> ⚠️ **Android 専用。** GMA Next-Gen SDK は現時点で Android のみ GA です。
> iOS は [`google_mobile_ads`](https://pub.dev/packages/google_mobile_ads) と
> 組み合わせて利用してください。
>
> ⚠️ **非公式パッケージ。** 本パッケージは Google との提携・スポンサー・公認
> 関係はありません。*AdMob*、*Google Mobile Ads*、*Flutter* は Google LLC の
> 商標です。本プラグインは一般公開されている GMA Next-Gen SDK を利便性のため
> ラップしているだけです。

## このパッケージを選ぶ理由

公式の `google_mobile_ads` プラグインは現時点で **レガシー** の GMA SDK を
使用しています。Android で Next-Gen SDK の新機能 — 特にレガシー SDK には無い
**`InterstitialAdPreloader`** / **`RewardedInterstitialAdPreloader`** の
プール型プリローダー — を今すぐ使いたい場合、これが最短ルートです。

## 動作要件

| | |
|---|---|
| Flutter | ≥ 3.10 |
| Dart | ≥ 3.10.7 |
| Android `compileSdk` | **35** |
| Android `minSdk` | **24** |
| Kotlin | ≥ 1.9 |

## インストール

`pubspec.yaml` に追加:

```yaml
dependencies:
  flutter_next_gen_ads: ^0.1.0
```

`android/app/src/main/AndroidManifest.xml` に AdMob アプリ ID を記載:

```xml
<application ...>
  <meta-data
      android:name="com.google.android.gms.ads.APPLICATION_ID"
      android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
  ...
</application>
```

> ローカル開発時は AdMob のテスト ID `ca-app-pub-3940256099942544~3347511713`
> を使ってください。リリース前に必ず実際の ID に置き換えること。

## クイックスタート

### アプリ起動時に 1 回だけ初期化

```dart
import 'package:flutter_next_gen_ads/flutter_next_gen_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.initialize(); // AndroidManifest から appId を自動取得

  // 開発中は必須: 自分のデバイスをテストデバイスとして登録し、
  // 誤って実広告が配信されて AdMob ポリシー違反になるのを防ぐ。
  await MobileAds.setRequestConfiguration(const RequestConfiguration(
    testDeviceIds: ['YOUR_DEVICE_HASH'], // logcat でハッシュを確認
  ));

  runApp(const MyApp());
}
```

### バナー広告

```dart
SizedBox(
  height: 120,
  child: BannerAdView(
    adUnitId: 'ca-app-pub-XXX/YYY',
    size: AdSize.largeAnchored(),
  ),
)
```

または `height:` パラメータで簡潔に:

```dart
const BannerAdView(
  adUnitId: 'ca-app-pub-XXX/YYY',
  size: AdSize.largeAnchored(),
  height: 120,
)
```

### インタースティシャル広告

```dart
try {
  final ad = await InterstitialAd.load(
    adUnitId: 'ca-app-pub-XXX/YYY',
  );
  ad.listener = InterstitialAdListener(
    onAdDismissedFullScreenContent: () => debugPrint('dismissed'),
  );
  await ad.show();
} on AdLoadException catch (e) {
  debugPrint('load failed: ${e.error}');
}
```

### リワード インタースティシャル広告

```dart
try {
  final ad = await RewardedInterstitialAd.load(
    adUnitId: 'ca-app-pub-XXX/YYY',
  );
  await ad.show(
    onUserEarnedReward: (reward) {
      grantCoins(reward.amount); // reward.type も利用可
    },
  );
} on AdLoadException catch (e) {
  debugPrint('rewarded failed: ${e.error}');
}
```

### アプリ オープン広告 (4 時間の有効期限処理付き)

```dart
class _RootState extends State<RootWidget> with WidgetsBindingObserver {
  AppOpenAd? _ad;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _preload();
  }

  Future<void> _preload() async {
    try {
      _ad = await AppOpenAd.load(adUnitId: 'ca-app-pub-XXX/YYY');
      _ad!.listener = AppOpenAdListener(
        onAdDismissedFullScreenContent: () {
          _ad = null;
          _preload();
        },
      );
    } on AdLoadException catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final ad = _ad;
      if (ad != null && await ad.isAvailable()) await ad.show();
    }
  }
  // ...
}
```

### プリローダー プール (Next-Gen 限定)

インタースティシャル / リワード広告をプールに事前にロードしておくと、
`show()` 時にネットワーク待ちなく即座に表示できます。

```dart
// 起動時: プールを満たす
await InterstitialAdPreloader.start(
  adUnitId: 'ca-app-pub-XXX/YYY',
  bufferSize: 2,
);

// 表示時: プールから取得、空ならフォールバックで即時ロード
InterstitialAd? ad = await InterstitialAdPreloader.poll(
  adUnitId: 'ca-app-pub-XXX/YYY',
);
ad ??= await InterstitialAd.load(adUnitId: 'ca-app-pub-XXX/YYY');
await ad.show();
```

### 広告ターゲティング ヒント

```dart
const request = AdRequest(
  keywords: ['flutter', 'mobile-dev'],
  contentUrl: 'https://example.com/article-being-read',
  customTargeting: {'genre': ['action', 'adventure']},
);

final ad = await InterstitialAd.load(
  adUnitId: 'ca-app-pub-XXX/YYY',
  request: request,
);
```

## クロスプラットフォーム利用 (Android + iOS)

このプラグインは Android 専用です。同じコードベースで iOS にも対応するには、
`google_mobile_ads` に条件分岐でフォールバックします:

```dart
import 'dart:io' show Platform;

Future<void> showInterstitial(String adUnitId) async {
  if (Platform.isAndroid) {
    // flutter_next_gen_ads を使う
    final ad = await InterstitialAd.load(adUnitId: adUnitId);
    await ad.show();
  } else if (Platform.isIOS) {
    // google_mobile_ads を使う (別途セットアップが必要)
    // ...
  }
}
```

`BannerAdView` ウィジェットは非 Android プラットフォームで自動的に
`placeholder` に縮退するので、レイアウトは崩れません。

## API サーフェス

`package:flutter_next_gen_ads/flutter_next_gen_ads.dart` から re-export:

- `MobileAds` — `initialize()`, `getVersion()`, `setRequestConfiguration()`
- `RequestConfiguration` + 列挙型 (`TagForChildDirectedTreatment`,
  `TagForUnderAgeOfConsent`, `MaxAdContentRating`,
  `PublisherPrivacyPersonalizationState`)
- `BannerAdView`, `BannerAdListener`, `AdSize` (`anchored`, `largeAnchored`,
  `inline` ファクトリ)
- `InterstitialAd`, `InterstitialAdListener`
- `RewardedInterstitialAd`, `RewardedInterstitialAdListener`, `RewardItem`
- `AppOpenAd`, `AppOpenAdListener`
- `InterstitialAdPreloader`, `RewardedInterstitialAdPreloader`
- `AdRequest`, `AdError`, `AdLoadException`

## ロードマップ

- **0.2.0** — ネイティブ広告 (`NativeAd`, `NativeAdView`,
  `NativeAdPreloader`)。
- **0.3.0+** — iOS 対応 (GMA Next-Gen iOS SDK が GA に到達次第)。

## トラブルシューティング

**バナーが空白になる。** `BannerAdView` には親から明示的な有界の制約が必要です。
`SizedBox(height: …)` で囲むか、`height:` パラメータを渡してください — 制約が
無いと Flutter は PlatformView の生成を黙ってスキップします。

**`AdLoadException(code: 3, message: No fill)`。** 現在のリクエストに対する
AdMob 在庫がありません。ほとんどのテスト広告ユニットは必ず広告を返すので、
リトライするか広告ユニット ID を確認してください。

**エミュレータでアプリが起動直後に落ちる。** GMA SDK + WebView は実行時に
約 300 MB を消費します。RAM 4 GB 未満のエミュレータでは OOM の可能性が
あります。実機を使うか、エミュレータのメモリを増やしてください。

**実機で実広告が表示される。** 広告ロード前に
`MobileAds.setRequestConfiguration(RequestConfiguration(testDeviceIds: [...]))`
を呼んでいるか確認してください。デバイス ハッシュは logcat で
`Use RequestConfiguration.Builder.setTestDeviceIds` を検索すると見つかります。

## スポンサー

<p align="center">
  <a href="https://github.com/sponsors/ahngo13">
    <img src="https://img.shields.io/badge/Sponsor%20on%20GitHub-%E2%9D%A4-ea4aaa?style=for-the-badge&logo=github-sponsors&logoColor=white" alt="Sponsor on GitHub" />
  </a>
</p>

このパッケージが 1 日分の作業を節約してくれたなら、私の 1 日分の作業を
スポンサーしてみませんか。

スポンサー費用の使途:

- **0.2.0 ネイティブ広告** — 開発中
- **iOS 対応** — GMA Next-Gen iOS GA 時にすぐリリース
- **バグ修正 & SDK アップグレード** — Google のリリースに追随

メンテナー: [**Hamlet Shu**](https://github.com/ahngo13) — 韓国・ソウル拠点の
独立系 Flutter デベロッパー。

## ライセンス

MIT — [LICENSE](LICENSE) を参照。
