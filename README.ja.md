# flutter_next_gen_ads

[![pub package](https://img.shields.io/pub/v/flutter_next_gen_ads.svg)](https://pub.dev/packages/flutter_next_gen_ads)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[English](README.md) · [한국어](README.ko.md) · **日本語** · [简体中文](README.zh-CN.md)

**Google Mobile Ads (GMA) Next-Gen SDK 1.0+** 向けの Flutter プラグインです。
Android でバナー、インタースティシャル、リワードインタースティシャル、
アプリオープン広告に対応します。

> ⚠️ **Android 専用です。** GMA Next-Gen SDK は現時点で Android のみ正式
> リリース(GA)されています。iOS は
> [`google_mobile_ads`](https://pub.dev/packages/google_mobile_ads) との
> 併用をおすすめします。
>
> ⚠️ **非公式パッケージです。** Google との提携・出資・公認関係は一切ありません。
> *AdMob*、*Google Mobile Ads*、*Flutter* は Google LLC の商標です。

<p align="center">
  <img src="screenshots/screenshot0.png" alt="Android のサンプルアプリ — プリロード済みのインタースティシャル / リワード / アプリオープン ボタンと、画面下部のアダプティブ AdMob バナー" width="280" />
</p>

## なぜこのパッケージか

公式の `google_mobile_ads` プラグインは現在も **レガシー** GMA SDK ベースです。
Next-Gen SDK の新機能 — 特にレガシー SDK には存在しない
**`InterstitialAdPreloader`** / **`RewardedInterstitialAdPreloader`** の
プール型プリローダー — を Android で今すぐ使いたい場合、最短ルートは
本パッケージです。

## 動作環境

| | |
|---|---|
| Flutter | 3.10 以上 |
| Dart | 3.10.7 以上 |
| Android `compileSdk` | **35** |
| Android `minSdk` | **24** |
| Kotlin | 1.9 以上 |

## インストール

`pubspec.yaml` に依存関係を追加します。

```yaml
dependencies:
  flutter_next_gen_ads: ^0.1.0
```

`android/app/src/main/AndroidManifest.xml` に AdMob のアプリ ID を記載します。

```xml
<application ...>
  <meta-data
      android:name="com.google.android.gms.ads.APPLICATION_ID"
      android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
  ...
</application>
```

> 開発時は AdMob のテストアプリ ID
> `ca-app-pub-3940256099942544~3347511713` を使ってください。リリース前に
> 必ず本番 ID へ差し替えます。

## クイックスタート

### アプリ起動時に 1 度だけ初期化

```dart
import 'package:flutter_next_gen_ads/flutter_next_gen_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.initialize(); // AndroidManifest から appId を自動取得

  // 開発中は必ずテストデバイスを登録してください。
  // 本番広告が誤って配信されると AdMob のポリシー違反になります。
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

`height` パラメータを使うとより簡潔に書けます。

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

### リワードインタースティシャル広告

```dart
try {
  final ad = await RewardedInterstitialAd.load(
    adUnitId: 'ca-app-pub-XXX/YYY',
  );
  await ad.show(
    onUserEarnedReward: (reward) {
      grantCoins(reward.amount); // reward.type も利用可能
    },
  );
} on AdLoadException catch (e) {
  debugPrint('rewarded failed: ${e.error}');
}
```

### アプリオープン広告 (4 時間の有効期限つき)

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

### プリローダープール (Next-Gen 専用)

インタースティシャルやリワード広告をプールにあらかじめ用意しておくと、
`show()` 時にネットワーク往復を待たず即座に表示できます。

```dart
// 起動時にプールを満たす
await InterstitialAdPreloader.start(
  adUnitId: 'ca-app-pub-XXX/YYY',
  bufferSize: 2,
);

// 表示時にプールから取り出す。空ならその場でロードにフォールバック
InterstitialAd? ad = await InterstitialAdPreloader.poll(
  adUnitId: 'ca-app-pub-XXX/YYY',
);
ad ??= await InterstitialAd.load(adUnitId: 'ca-app-pub-XXX/YYY');
await ad.show();
```

### ターゲティング指定

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

## クロスプラットフォーム対応 (Android + iOS)

本プラグインは Android 専用です。同じコードベースで iOS にも対応するには、
`google_mobile_ads` へ条件分岐でフォールバックします。

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

`BannerAdView` ウィジェットは Android 以外のプラットフォームで自動的に
`placeholder` へフォールバックするため、レイアウトが崩れることはありません。

## 公開 API

`package:flutter_next_gen_ads/flutter_next_gen_ads.dart` から re-export
されているものです。

- `MobileAds` — `initialize()`, `getVersion()`, `setRequestConfiguration()`
- `RequestConfiguration` と関連 enum (`TagForChildDirectedTreatment`,
  `TagForUnderAgeOfConsent`, `MaxAdContentRating`,
  `PublisherPrivacyPersonalizationState`)
- `BannerAdView`, `BannerAdListener`, `AdSize` (`anchored`, `largeAnchored`,
  `inline` の各ファクトリ)
- `InterstitialAd`, `InterstitialAdListener`
- `RewardedInterstitialAd`, `RewardedInterstitialAdListener`, `RewardItem`
- `AppOpenAd`, `AppOpenAdListener`
- `InterstitialAdPreloader`, `RewardedInterstitialAdPreloader`
- `AdRequest`, `AdError`, `AdLoadException`

## ロードマップ

- **0.2.0** — ネイティブ広告 (`NativeAd`, `NativeAdView`,
  `NativeAdPreloader`)
- **0.3.0+** — iOS 対応 (GMA Next-Gen iOS SDK の GA 後)

## トラブルシューティング

**バナーが空白で表示される。** `BannerAdView` は親から明示的なサイズ制約を
受け取る必要があります。`SizedBox(height: …)` で囲むか、`height` パラメータを
渡してください。制約がないと Flutter は PlatformView の生成を無言でスキップ
します。

**`AdLoadException(code: 3, message: No fill)` が発生する。** AdMob 側に
このリクエストへ配信できる在庫がない状態です。テスト広告ユニットは通常常に
レスポンスを返すので、しばらく待ってリトライするか、広告ユニット ID を
確認してください。

**エミュレータでアプリが起動直後に強制終了する。** GMA SDK と WebView は
ランタイムで約 300MB 消費します。RAM 4GB 未満のエミュレータでは OOM で
落ちることがあります。実機を使うか、エミュレータのメモリを増やしてください。

**実機で本番広告が表示されてしまう。** 広告ロード前に
`MobileAds.setRequestConfiguration(RequestConfiguration(testDeviceIds: [...]))`
を呼んでいるか確認してください。デバイスのハッシュは logcat で
`Use RequestConfiguration.Builder.setTestDeviceIds` を検索すると見つかります。

## スポンサー

<p align="center">
  <a href="https://github.com/sponsors/ahngo13">
    <img src="https://img.shields.io/badge/Sponsor%20on%20GitHub-%E2%9D%A4-ea4aaa?style=for-the-badge&logo=github-sponsors&logoColor=white" alt="Sponsor on GitHub" />
  </a>
</p>

このパッケージが 1 日分の作業を肩代わりしてくれたなら、私の 1 日分の作業を
スポンサーしてみませんか。

スポンサー費用の使いみち:

- **0.2.0 ネイティブ広告** — 現在開発中
- **バグ修正 & SDK アップグレード** — Google のリリースに継続的に追従
- **Issue と PR の対応** — 数週間ではなく数日でレスポンス

メンテナーは韓国・ソウル在住の独立系 Flutter 開発者
[**Hamlet Shu**](https://github.com/ahngo13) です。

## ライセンス

MIT。詳しくは [LICENSE](LICENSE) を参照してください。
