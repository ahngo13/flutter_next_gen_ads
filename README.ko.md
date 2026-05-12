# flutter_next_gen_ads

[![pub package](https://img.shields.io/pub/v/flutter_next_gen_ads.svg)](https://pub.dev/packages/flutter_next_gen_ads)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[English](README.md) · **한국어** · [日本語](README.ja.md) · [简体中文](README.zh-CN.md)

**Google Mobile Ads (GMA) Next-Gen SDK 1.0+** 을 감싼 Flutter 플러그인 — Android에서
배너 / 전면 / 보상형 전면 / 앱 오프닝 광고를 지원합니다.

> ⚠️ **Android 전용.** GMA Next-Gen SDK는 현재 Android만 GA 상태입니다.
> iOS는 [`google_mobile_ads`](https://pub.dev/packages/google_mobile_ads) 와 함께
> 조합해서 사용하세요.
>
> ⚠️ **비공식 패키지.** 본 패키지는 Google과 제휴 관계가 없으며 후원/인증을 받지
> 않았습니다. *AdMob*, *Google Mobile Ads*, *Flutter* 는 Google LLC 의 상표입니다.
> 이 플러그인은 공개 배포되는 GMA Next-Gen SDK 를 편의 목적으로 래핑할 뿐입니다.

## 왜 이 패키지인가?

공식 `google_mobile_ads` 플러그인은 현재 시점에서 **레거시** GMA SDK 를 사용합니다.
Android에서 Next-Gen SDK 의 신기능 — 특히 레거시 SDK 에 없는
**`InterstitialAdPreloader`** / **`RewardedInterstitialAdPreloader`** 풀 기반
프리로더 — 을 지금 당장 쓰고 싶다면 이 패키지가 가장 빠른 길입니다.

## 요구 사항

| | |
|---|---|
| Flutter | ≥ 3.10 |
| Dart | ≥ 3.10.7 |
| Android `compileSdk` | **35** |
| Android `minSdk` | **24** |
| Kotlin | ≥ 1.9 |

## 설치

`pubspec.yaml` 에 패키지를 추가하세요:

```yaml
dependencies:
  flutter_next_gen_ads: ^0.1.0
```

`android/app/src/main/AndroidManifest.xml` 에 AdMob 앱 ID 를 등록하세요:

```xml
<application ...>
  <meta-data
      android:name="com.google.android.gms.ads.APPLICATION_ID"
      android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
  ...
</application>
```

> 로컬 개발에는 AdMob 의 테스트 ID `ca-app-pub-3940256099942544~3347511713` 를
> 사용하세요. 배포 전에 반드시 실제 ID 로 교체해야 합니다.

## 빠른 시작

### 앱 시작 시 한 번 초기화

```dart
import 'package:flutter_next_gen_ads/flutter_next_gen_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.initialize(); // AndroidManifest 에서 appId 자동 읽어옴

  // 개발 단계에서 필수: 본인 기기를 테스트 디바이스로 등록해야
  // 실제 광고가 잘못 송출돼 AdMob 정책 위반으로 잡히지 않습니다.
  await MobileAds.setRequestConfiguration(const RequestConfiguration(
    testDeviceIds: ['YOUR_DEVICE_HASH'], // logcat 에서 해시 확인
  ));

  runApp(const MyApp());
}
```

### 배너 광고

```dart
SizedBox(
  height: 120,
  child: BannerAdView(
    adUnitId: 'ca-app-pub-XXX/YYY',
    size: AdSize.largeAnchored(),
  ),
)
```

또는 `height:` 파라미터로 간단히:

```dart
const BannerAdView(
  adUnitId: 'ca-app-pub-XXX/YYY',
  size: AdSize.largeAnchored(),
  height: 120,
)
```

### 전면 광고 (Interstitial)

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

### 보상형 전면 광고 (Rewarded Interstitial)

```dart
try {
  final ad = await RewardedInterstitialAd.load(
    adUnitId: 'ca-app-pub-XXX/YYY',
  );
  await ad.show(
    onUserEarnedReward: (reward) {
      grantCoins(reward.amount); // reward.type 도 사용 가능
    },
  );
} on AdLoadException catch (e) {
  debugPrint('rewarded failed: ${e.error}');
}
```

### 앱 오프닝 광고 (4시간 만료 처리 포함)

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

### 프리로더 풀 (Next-Gen 전용)

전면/보상형 광고를 풀에 미리 채워두면 `show()` 호출 시 네트워크 왕복 없이
즉시 노출됩니다.

```dart
// 시작 시: 풀 채우기
await InterstitialAdPreloader.start(
  adUnitId: 'ca-app-pub-XXX/YYY',
  bufferSize: 2,
);

// 노출 시: 풀에서 가져오기, 비어 있으면 즉시 로드로 폴백
InterstitialAd? ad = await InterstitialAdPreloader.poll(
  adUnitId: 'ca-app-pub-XXX/YYY',
);
ad ??= await InterstitialAd.load(adUnitId: 'ca-app-pub-XXX/YYY');
await ad.show();
```

### 광고 타겟팅 힌트

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

## 크로스 플랫폼 사용 (Android + iOS)

이 플러그인은 Android 전용입니다. 같은 코드베이스에서 iOS 도 지원하려면
`google_mobile_ads` 로 조건부 폴백하세요:

```dart
import 'dart:io' show Platform;

Future<void> showInterstitial(String adUnitId) async {
  if (Platform.isAndroid) {
    // flutter_next_gen_ads 사용
    final ad = await InterstitialAd.load(adUnitId: adUnitId);
    await ad.show();
  } else if (Platform.isIOS) {
    // google_mobile_ads 사용 (별도 셋업 필요)
    // ...
  }
}
```

`BannerAdView` 위젯은 Android 가 아닌 플랫폼에서는 자동으로 `placeholder` 로
축소되므로 레이아웃이 깨지지 않습니다.

## API 표면

`package:flutter_next_gen_ads/flutter_next_gen_ads.dart` 에서 re-export:

- `MobileAds` — `initialize()`, `getVersion()`, `setRequestConfiguration()`
- `RequestConfiguration` + enum (`TagForChildDirectedTreatment`,
  `TagForUnderAgeOfConsent`, `MaxAdContentRating`,
  `PublisherPrivacyPersonalizationState`)
- `BannerAdView`, `BannerAdListener`, `AdSize` (`anchored`, `largeAnchored`,
  `inline` 팩토리)
- `InterstitialAd`, `InterstitialAdListener`
- `RewardedInterstitialAd`, `RewardedInterstitialAdListener`, `RewardItem`
- `AppOpenAd`, `AppOpenAdListener`
- `InterstitialAdPreloader`, `RewardedInterstitialAdPreloader`
- `AdRequest`, `AdError`, `AdLoadException`

## 로드맵

- **0.2.0** — 네이티브 광고 (`NativeAd`, `NativeAdView`, `NativeAdPreloader`).
- **0.3.0+** — iOS 지원 (GMA Next-Gen iOS SDK GA 이후).

## 문제 해결

**배너 자리가 비어있어요.** `BannerAdView` 는 부모로부터 명시적인 크기 제약을
받아야 합니다. `SizedBox(height: …)` 로 감싸거나 `height:` 파라미터를
전달하세요 — 크기 제약이 없으면 Flutter 가 조용히 PlatformView 생성을
건너뜁니다.

**`AdLoadException(code: 3, message: No fill)`.** 현재 요청에 대해 AdMob 재고가
없는 상태입니다. 대부분 테스트 광고 단위는 항상 채워지므로, 재시도하거나
광고 단위 ID 를 확인하세요.

**에뮬레이터에서 앱이 실행 직후 죽어요.** GMA SDK + WebView 는 런타임에 약
300 MB 를 차지합니다. RAM 4 GB 미만 에뮬레이터에서는 OOM 가 날 수 있습니다.
실제 기기를 쓰거나 에뮬레이터 메모리를 늘려주세요.

**실기기에서 실제 광고가 나와요.** 광고 로드 전에
`MobileAds.setRequestConfiguration(RequestConfiguration(testDeviceIds: [...]))`
를 호출했는지 확인하세요. 디바이스 해시는 logcat 에서
`Use RequestConfiguration.Builder.setTestDeviceIds` 키워드로 찾을 수 있습니다.

## 후원

<p align="center">
  <a href="https://github.com/sponsors/ahngo13">
    <img src="https://img.shields.io/badge/Sponsor%20on%20GitHub-%E2%9D%A4-ea4aaa?style=for-the-badge&logo=github-sponsors&logoColor=white" alt="Sponsor on GitHub" />
  </a>
</p>

이 패키지가 하루치 작업을 아껴줬다면, 제 하루치 작업을 후원해 주세요.

후원금은 다음에 사용됩니다:

- **0.2.0 네이티브 광고** — 현재 개발 중
- **버그 수정 & SDK 업그레이드** — Google 릴리스에 발맞춰 유지보수
- **이슈 & PR 트리아지** — 몇 주가 아닌 며칠 안에 응답

[**Hamlet Shu**](https://github.com/ahngo13) 가 만들고 유지보수합니다 —
대한민국 서울 기반 1인 Flutter 개발자.

## 라이선스

MIT — [LICENSE](LICENSE) 참고.
