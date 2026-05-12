# flutter_next_gen_ads

[![pub package](https://img.shields.io/pub/v/flutter_next_gen_ads.svg)](https://pub.dev/packages/flutter_next_gen_ads)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[English](README.md) · [한국어](README.ko.md) · [日本語](README.ja.md) · **简体中文**

封装 **Google Mobile Ads (GMA) Next-Gen SDK 1.0+** 的 Flutter 插件 —
在 Android 上提供横幅 / 插屏 / 激励插屏 / 应用开屏广告。

> ⚠️ **仅支持 Android。** GMA Next-Gen SDK 目前仅在 Android 上正式发布 (GA)。
> iOS 请配合 [`google_mobile_ads`](https://pub.dev/packages/google_mobile_ads)
> 一起使用。
>
> ⚠️ **非官方。** 本包未获 Google 关联、认可或赞助。
> *AdMob*、*Google Mobile Ads*、*Flutter* 是 Google LLC 的商标。
> 本插件只是为便于使用而封装公开发布的 GMA Next-Gen SDK。

## 为什么选这个包?

官方 `google_mobile_ads` 插件目前仍使用 **旧版** GMA SDK。若希望在 Android 上
立刻用到 Next-Gen SDK 的新功能 — 尤其是旧版 SDK 缺失的
**`InterstitialAdPreloader`** / **`RewardedInterstitialAdPreloader`**
基于池的预加载器 — 本包是最短路径。

## 环境要求

| | |
|---|---|
| Flutter | ≥ 3.10 |
| Dart | ≥ 3.10.7 |
| Android `compileSdk` | **35** |
| Android `minSdk` | **24** |
| Kotlin | ≥ 1.9 |

## 安装

在 `pubspec.yaml` 中添加:

```yaml
dependencies:
  flutter_next_gen_ads: ^0.1.0
```

将 AdMob 应用 ID 写入 `android/app/src/main/AndroidManifest.xml`:

```xml
<application ...>
  <meta-data
      android:name="com.google.android.gms.ads.APPLICATION_ID"
      android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
  ...
</application>
```

> 本地开发请使用 AdMob 测试 ID `ca-app-pub-3940256099942544~3347511713`。
> 发布前必须替换为实际 ID。

## 快速开始

### 应用启动时初始化一次

```dart
import 'package:flutter_next_gen_ads/flutter_next_gen_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.initialize(); // 自动从 AndroidManifest 读取 appId

  // 开发阶段必做: 将自己的设备注册为测试设备,
  // 防止真实广告意外送达并触发 AdMob 政策违规。
  await MobileAds.setRequestConfiguration(const RequestConfiguration(
    testDeviceIds: ['YOUR_DEVICE_HASH'], // 在 logcat 中获取设备哈希
  ));

  runApp(const MyApp());
}
```

### 横幅广告

```dart
SizedBox(
  height: 120,
  child: BannerAdView(
    adUnitId: 'ca-app-pub-XXX/YYY',
    size: AdSize.largeAnchored(),
  ),
)
```

或使用便捷的 `height:` 参数:

```dart
const BannerAdView(
  adUnitId: 'ca-app-pub-XXX/YYY',
  size: AdSize.largeAnchored(),
  height: 120,
)
```

### 插屏广告

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

### 激励插屏广告

```dart
try {
  final ad = await RewardedInterstitialAd.load(
    adUnitId: 'ca-app-pub-XXX/YYY',
  );
  await ad.show(
    onUserEarnedReward: (reward) {
      grantCoins(reward.amount); // reward.type 同样可用
    },
  );
} on AdLoadException catch (e) {
  debugPrint('rewarded failed: ${e.error}');
}
```

### 应用开屏广告 (含 4 小时过期处理)

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

### 预加载池 (Next-Gen 独有)

将插屏 / 激励广告预先加载到池中, `show()` 调用时即可立即展示, 无需等待
网络往返。

```dart
// 启动时: 填充池
await InterstitialAdPreloader.start(
  adUnitId: 'ca-app-pub-XXX/YYY',
  bufferSize: 2,
);

// 展示时: 从池中取广告; 池空时回退到即时加载
InterstitialAd? ad = await InterstitialAdPreloader.poll(
  adUnitId: 'ca-app-pub-XXX/YYY',
);
ad ??= await InterstitialAd.load(adUnitId: 'ca-app-pub-XXX/YYY');
await ad.show();
```

### 广告定向参数

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

## 跨平台使用 (Android + iOS)

本插件仅支持 Android。若需在同一份代码中也支持 iOS, 请条件性地回退到
`google_mobile_ads`:

```dart
import 'dart:io' show Platform;

Future<void> showInterstitial(String adUnitId) async {
  if (Platform.isAndroid) {
    // 使用 flutter_next_gen_ads
    final ad = await InterstitialAd.load(adUnitId: adUnitId);
    await ad.show();
  } else if (Platform.isIOS) {
    // 使用 google_mobile_ads (需单独配置)
    // ...
  }
}
```

`BannerAdView` 在非 Android 平台会自动退化为 `placeholder`, 布局不会破坏。

## API 一览

从 `package:flutter_next_gen_ads/flutter_next_gen_ads.dart` re-export:

- `MobileAds` — `initialize()`、`getVersion()`、`setRequestConfiguration()`
- `RequestConfiguration` 及枚举 (`TagForChildDirectedTreatment`、
  `TagForUnderAgeOfConsent`、`MaxAdContentRating`、
  `PublisherPrivacyPersonalizationState`)
- `BannerAdView`、`BannerAdListener`、`AdSize` (`anchored`、`largeAnchored`、
  `inline` 工厂方法)
- `InterstitialAd`、`InterstitialAdListener`
- `RewardedInterstitialAd`、`RewardedInterstitialAdListener`、`RewardItem`
- `AppOpenAd`、`AppOpenAdListener`
- `InterstitialAdPreloader`、`RewardedInterstitialAdPreloader`
- `AdRequest`、`AdError`、`AdLoadException`

## 路线图

- **0.2.0** — 原生广告 (`NativeAd`、`NativeAdView`、`NativeAdPreloader`)。
- **0.3.0+** — iOS 支持 (待 GMA Next-Gen iOS SDK GA 之后)。

## 故障排查

**横幅显示为空白。** `BannerAdView` 需要父级提供明确的有界约束。请用
`SizedBox(height: …)` 包裹, 或传入 `height:` 参数 — 没有约束时 Flutter
会静默跳过 PlatformView 的创建。

**`AdLoadException(code: 3, message: No fill)`。** AdMob 当前没有可填充
该请求的库存。大多数测试广告单元始终会返回广告, 请重试或核对广告单元 ID。

**应用在模拟器中启动后被杀。** GMA SDK + WebView 在运行时约占 300 MB。
RAM 不足 4 GB 的模拟器可能 OOM。请使用真机或为模拟器分配更多内存。

**真机上看到的是真实广告而非测试广告。** 请确认在加载广告之前调用了
`MobileAds.setRequestConfiguration(RequestConfiguration(testDeviceIds: [...]))`。
设备哈希可在 logcat 中搜索 `Use RequestConfiguration.Builder.setTestDeviceIds`
找到。

## 赞助

<p align="center">
  <a href="https://github.com/sponsors/ahngo13">
    <img src="https://img.shields.io/badge/Sponsor%20on%20GitHub-%E2%9D%A4-ea4aaa?style=for-the-badge&logo=github-sponsors&logoColor=white" alt="Sponsor on GitHub" />
  </a>
</p>

如果这个包帮你节省了一天的工作, 不妨赞助我一天的工作。

赞助款用于:

- **0.2.0 原生广告** — 开发中
- **缺陷修复 & SDK 升级** — 跟进 Google 的版本节奏
- **Issue 与 PR 跟进** — 以天为单位响应, 而非周

由 [**Hamlet Shu**](https://github.com/ahngo13) 构建并维护 —
来自韩国首尔的独立 Flutter 开发者。

## 许可证

MIT — 详见 [LICENSE](LICENSE)。
