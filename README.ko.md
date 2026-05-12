# flutter_next_gen_ads

[![pub package](https://img.shields.io/pub/v/flutter_next_gen_ads.svg)](https://pub.dev/packages/flutter_next_gen_ads)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[English](README.md) · **한국어** · [日本語](README.ja.md) · [简体中文](README.zh-CN.md)

**Google Mobile Ads (GMA) Next-Gen SDK 1.0+** 를 위한 Flutter 플러그인입니다.
Android에서 배너, 전면, 보상형 전면, 앱 오프닝 광고를 지원합니다.

> ⚠️ **Android 전용입니다.** GMA Next-Gen SDK는 현재 Android만 정식 출시(GA) 된
> 상태입니다. iOS는 [`google_mobile_ads`](https://pub.dev/packages/google_mobile_ads)
> 와 함께 쓰는 방식을 권장합니다.
>
> ⚠️ **비공식 패키지입니다.** Google과 제휴, 후원, 공식 인증 관계가 전혀 없는
> 서드파티 래퍼입니다. *AdMob*, *Google Mobile Ads*, *Flutter*는 Google LLC의
> 상표입니다.

<p align="center">
  <img src="screenshots/screenshot0.png" alt="Android 예제 앱 — 프리로드된 전면/보상형/앱 오프닝 버튼과 하단의 적응형 AdMob 배너" width="280" />
</p>

## 왜 이 패키지인가요

공식 `google_mobile_ads` 플러그인은 아직 **레거시** GMA SDK를 기반으로 합니다.
Next-Gen SDK 신기능을 지금 당장 Android에서 쓰고 싶다면 — 특히 레거시 SDK에는
없는 **`InterstitialAdPreloader`**, **`RewardedInterstitialAdPreloader`** 풀
기반 프리로더가 필요하다면 — 이 패키지가 가장 빠른 길입니다.

## 요구 사항

| | |
|---|---|
| Flutter | 3.10 이상 |
| Dart | 3.10.7 이상 |
| Android `compileSdk` | **35** |
| Android `minSdk` | **24** |
| Kotlin | 1.9 이상 |

## 설치

`pubspec.yaml`에 의존성을 추가합니다.

```yaml
dependencies:
  flutter_next_gen_ads: ^0.1.0
```

`android/app/src/main/AndroidManifest.xml`에 AdMob 앱 ID를 등록합니다.

```xml
<application ...>
  <meta-data
      android:name="com.google.android.gms.ads.APPLICATION_ID"
      android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
  ...
</application>
```

> 개발 중에는 AdMob 테스트 앱 ID `ca-app-pub-3940256099942544~3347511713`를
> 쓰세요. 배포 전에는 반드시 실제 ID로 교체합니다.

## 빠른 시작

### 앱 시작 시 한 번만 초기화

```dart
import 'package:flutter_next_gen_ads/flutter_next_gen_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.initialize(); // AndroidManifest에서 appId 자동 인식

  // 개발 중에는 반드시 테스트 디바이스로 등록하세요.
  // 실수로 실제 광고가 노출되면 AdMob 정책 위반이 됩니다.
  await MobileAds.setRequestConfiguration(const RequestConfiguration(
    testDeviceIds: ['YOUR_DEVICE_HASH'], // logcat에서 해시 확인
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

`height` 파라미터를 쓰면 더 간결합니다.

```dart
const BannerAdView(
  adUnitId: 'ca-app-pub-XXX/YYY',
  size: AdSize.largeAnchored(),
  height: 120,
)
```

### 전면 광고

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

### 보상형 전면 광고

```dart
try {
  final ad = await RewardedInterstitialAd.load(
    adUnitId: 'ca-app-pub-XXX/YYY',
  );
  await ad.show(
    onUserEarnedReward: (reward) {
      grantCoins(reward.amount); // reward.type도 사용 가능
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

전면/보상형 광고를 미리 풀에 채워두면 `show()` 호출 시 네트워크 왕복 없이
즉시 노출됩니다.

```dart
// 앱 시작 시 풀 채우기
await InterstitialAdPreloader.start(
  adUnitId: 'ca-app-pub-XXX/YYY',
  bufferSize: 2,
);

// 노출 시점에 풀에서 꺼내고, 비어있으면 즉시 로드로 폴백
InterstitialAd? ad = await InterstitialAdPreloader.poll(
  adUnitId: 'ca-app-pub-XXX/YYY',
);
ad ??= await InterstitialAd.load(adUnitId: 'ca-app-pub-XXX/YYY');
await ad.show();
```

### 타게팅 옵션

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

## 크로스 플랫폼 (Android + iOS)

이 플러그인은 Android만 지원합니다. 같은 코드베이스에서 iOS도 지원하려면
`google_mobile_ads`로 분기 처리하세요.

```dart
import 'dart:io' show Platform;

Future<void> showInterstitial(String adUnitId) async {
  if (Platform.isAndroid) {
    // flutter_next_gen_ads 사용
    final ad = await InterstitialAd.load(adUnitId: adUnitId);
    await ad.show();
  } else if (Platform.isIOS) {
    // google_mobile_ads 사용 (별도 설정 필요)
    // ...
  }
}
```

`BannerAdView` 위젯은 Android가 아닌 플랫폼에서 자동으로 `placeholder`로
대체되므로 레이아웃이 깨지지 않습니다.

## 공개 API

`package:flutter_next_gen_ads/flutter_next_gen_ads.dart`에서 export 합니다.

- `MobileAds` — `initialize()`, `getVersion()`, `setRequestConfiguration()`
- `RequestConfiguration` + 관련 enum (`TagForChildDirectedTreatment`,
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

- **0.2.0** — 네이티브 광고 (`NativeAd`, `NativeAdView`, `NativeAdPreloader`)
- **0.3.0+** — iOS 지원 (GMA Next-Gen iOS SDK GA 이후)

## 트러블슈팅

**배너 자리가 빈칸으로 나옵니다.** `BannerAdView`는 부모로부터 명확한 크기
제약을 받아야 합니다. `SizedBox(height: …)`로 감싸거나 `height` 파라미터를
넘기세요. 제약이 없으면 Flutter가 PlatformView 생성을 조용히 건너뜁니다.

**`AdLoadException(code: 3, message: No fill)` 가 발생합니다.** AdMob에 해당
요청에 채울 광고 재고가 없는 상태입니다. 보통 테스트 광고 유닛은 항상 응답을
주기 때문에, 잠시 후 재시도하거나 광고 유닛 ID를 확인하세요.

**에뮬레이터에서 앱이 실행 직후 꺼집니다.** GMA SDK + WebView는 런타임에
약 300MB를 사용합니다. RAM 4GB 미만 에뮬레이터에서는 OOM으로 죽을 수
있습니다. 실기기를 쓰거나 에뮬레이터 메모리를 늘리세요.

**실기기에서 테스트 광고가 아닌 실제 광고가 나옵니다.** 광고를 로드하기
전에 `MobileAds.setRequestConfiguration(RequestConfiguration(testDeviceIds: [...]))`
를 호출했는지 확인하세요. 기기 해시는 logcat에서
`Use RequestConfiguration.Builder.setTestDeviceIds` 키워드로 찾을 수 있습니다.

## 후원

<p align="center">
  <a href="https://github.com/sponsors/ahngo13">
    <img src="https://img.shields.io/badge/Sponsor%20on%20GitHub-%E2%9D%A4-ea4aaa?style=for-the-badge&logo=github-sponsors&logoColor=white" alt="Sponsor on GitHub" />
  </a>
</p>

이 패키지로 하루 일감이 줄었다면, 제 하루 일감도 후원으로 채워주세요.

후원금은 이렇게 씁니다.

- **0.2.0 네이티브 광고** — 현재 개발 중
- **버그 수정 & SDK 업그레이드** — Google 릴리스에 맞춰 지속 관리
- **이슈와 PR 대응** — 몇 주가 아닌 며칠 안에 답변

서울 거주 1인 Flutter 개발자 [**Hamlet Shu**](https://github.com/ahngo13)가
만들고 유지보수합니다.

## 라이선스

MIT. 자세한 내용은 [LICENSE](LICENSE)를 확인하세요.
