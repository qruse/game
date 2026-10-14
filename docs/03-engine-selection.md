# 게임 엔진 선정 v0.1

> 작성일 2026-10-15 · 상태: **잠정 결론 Godot. 2주 기술 검증(스파이크) 후 확정**
> 근거 문서: [01-market-research.md](01-market-research.md) 7절, [02-game-concept.md](02-game-concept.md)

## 1. 결론

**Godot 4 (GDScript)를 1순위로 추천한다.** Unity는 기술 검증이 실패했을 때의 대안으로 둔다.

시장조사 v0.1에서는 Unity를 추천했다. 그때의 전제는 **가챠, 서버 뽑기, Live2D**였다. 지금은 전제가 바뀌었다.

| 바뀐 전제 | 엔진 선택에 주는 영향 |
|---|---|
| 가챠 → **메인 무료 + DLC** | 결제가 "한 번 사면 영구 해금"(비소모성 상품) 몇 개로 단순해졌다. Unity의 성숙한 결제 생태계가 주는 이점이 줄었다 |
| Live2D → **SD Spine + 스탠딩 일러스트** | Live2D 공식 SDK가 Unity에만 있다는 이유가 사라졌다 |
| **1인 개발 + AI(Claude Code) 활용** | 장면 파일이 사람이 읽을 수 있는 텍스트인 Godot이 AI 협업에 훨씬 유리하다 |
| **턴제 2D** | 엔진 성능 차이가 거의 의미 없다. 2D 작업 흐름과 반복 속도가 더 중요하다 |

## 2. 후보 비교

| 기준 | **Godot 4** | **Unity 6** | GameMaker | Defold |
|---|---|---|---|---|
| 비용 | **완전 무료 (MIT), 수익 배분 없음** | 매출+투자 연 $200K까지 무료, 넘으면 Pro 좌석당 연 약 $2,310 | 상업용 Pro 일회성 약 $99.99 | 무료 |
| 2D 작업 흐름 | **최상급** (2D 전용 렌더러, 가벼운 에디터) | 좋음 (에디터가 무겁다) | 좋음 (2D 특화) | 좋음 |
| Steam 연동·DLC | GodotSteam (활발히 유지, DLC 확인 지원) | Steamworks.NET (성숙) | 확장 기능 | 확장 기능 |
| Android 결제 | **공식** Google Play Billing 플러그인 | 공식 Unity IAP | 확장 기능 | 확장 기능 |
| iOS 결제 | ⚠️ **커뮤니티 플러그인** (내장 InAppStore는 문서가 오래됨) | **공식** Unity IAP | 확장 기능 | 확장 기능 |
| 보상형 광고 | ⚠️ 커뮤니티 AdMob 플러그인 (보상형·GDPR 동의 지원) | **공식** SDK 다수 | 확장 기능 | 확장 기능 |
| Spine | 공식 런타임 (2022~, Unity보다 덜 성숙) | **공식 런타임 (2013~, 가장 성숙)** | 내장 지원 | 확장 기능 |
| 분기 대화 도구 | **Yarn Spinner 공식 지원 (GDScript·C#)**, Ink(GodotInk/inkgd), Dialogue Manager | Yarn Spinner, Ink (가장 성숙) | 직접 구현 위주 | 직접 구현 위주 |
| **AI(Claude Code) 협업** | **최상.** 장면(.tscn), 리소스(.tres), 스크립트가 전부 읽기 쉬운 텍스트다 | 보통. C# 학습 데이터는 많지만, 장면·프리팹이 복잡한 YAML이라 AI가 다루기 어렵다 | 보통 | 보통 |
| 콘솔 이식 (나중에) | 외부 업체를 통해야 한다 | 쉽다 | 가능 | 가능 |
| 상업 성공 사례 (2D) | **Slay the Spire 2** (Unity에서 갈아탐), **Brotato** (Steam + 모바일), Cassette Beasts, Dome Keeper, Halls of Torment | 매우 많다 (모바일 서브컬처 대부분) | Undertale 등 다수 | 소수 |

GameMaker와 Defold는 모바일 결제·광고·Steam을 모두 확장 기능에 기대야 하는데, Godot보다 나은 점이 뚜렷하지 않아 제외한다. Unreal은 2D 게임에 과하다.

## 3. Godot을 고르는 이유

1. **AI 협업 생산성이 가장 크다.** 1인 개발에서 가장 부족한 자원은 시간이다. Godot은 장면 구조까지 텍스트라서 Claude가 코드뿐 아니라 장면, UI, 리소스까지 직접 읽고 고칠 수 있다. Unity로 옮겼다가 Godot으로 돌아온 개발자가 "AI 코딩 결과가 확연히 좋아졌다"고 보고한 사례도 있다(개인 경험담이라 참고만 한다)
2. **비용과 라이선스 리스크가 없다.** Unity는 2023년 런타임 요금 사태 이후 철회했지만, 약관을 일방적으로 바꿀 수 있는 구조는 그대로다. Mega Crit은 이 때문에 개발 2년 차에 Slay the Spire 2를 Godot으로 옮겼고 출시까지 마쳤다
3. **이 장르에 이미 증명됐다.** Slay the Spire 2는 턴제 2D 전략 게임이고, Brotato는 Godot으로 Steam과 모바일에 모두 나왔다
4. **필요한 도구가 다 있다.** 분기 대화(Yarn Spinner 공식 지원), Steam DLC(GodotSteam), Android 결제(공식), Spine(공식 런타임)

## 4. Godot의 약점과 대응

| 약점 | 위험도 | 대응 |
|---|---|---|
| **iOS 결제가 커뮤니티 플러그인** | 중 | 우리 상품은 비소모성(영구 해금) 몇 개뿐이라 결제 중에서 가장 단순한 유형이다. 스파이크에서 TestFlight 실제 구매까지 검증한다. 플러그인 후보: hrk4649/godot_ios_plugin_iap, godot-iap(OpenIAP, StoreKit 2) |
| **보상형 광고가 커뮤니티 플러그인** | 중 | Poing Studios AdMob 플러그인(보상형, GDPR 동의 지원)을 스파이크에서 Android/iOS 둘 다 검증한다. 광고는 부가 수입이라 최악의 경우 출시 후에 붙여도 된다 |
| Spine 런타임이 Unity보다 덜 성숙 | 낮음~중 | 스킨 교체(코스튬)와 첨부 이미지 API를 스파이크에서 확인한다 |
| 콘솔 이식이 어렵다 | 낮음 | 현재 목표 플랫폼이 아니다. 필요해지면 외부 이식 업체를 쓴다 |
| 튜토리얼·에셋 스토어가 Unity보다 작다 | 낮음 | AI 협업으로 상당 부분 메운다 |

**언어는 GDScript로 한다.** Godot의 C#은 모바일 내보내기 지원이 GDScript보다 늦게 따라온다. GDScript가 모바일과 Steam 모두에서 가장 안전하다.

## 5. 기술 검증 (스파이크) 계획: 2주

본격 개발 전에 **"돈과 관련된 배관"**을 먼저 검증한다. 하나라도 막히면 Unity로 바꾼다.

| # | 검증 항목 | 통과 기준 |
|---|---|---|
| 1 | Android 결제 | 테스트 트랙에서 비소모성 상품 구매·복원 성공 |
| 2 | **iOS 결제** | TestFlight 샌드박스에서 구매·복원 성공 |
| 3 | **보상형 광고** | Android/iOS 테스트 광고 시청 → 보상 콜백 수신, GDPR 동의 창 동작 |
| 4 | Steam DLC | GodotSteam으로 테스트 앱에서 DLC 보유 여부 확인 |
| 5 | SD 애니메이션 | Spine 런타임으로 SD 캐릭터 1개 재생과 스킨(코스튬) 교체. **함께 비교:** Godot 내장 컷아웃 애니메이션(Skeleton2D + AnimationPlayer). 내장 방식은 애니메이션이 텍스트(.tscn)로 저장돼 Claude가 직접 만들고 고칠 수 있고 Spine 라이선스도 필요 없다. 품질이 충분하면 내장 방식을 쓴다 |
| 6 | 분기 대화 | Yarn Spinner로 d20 판정이 있는 분기 대화 1개 |
| 7 | 빌드 | 같은 프로젝트에서 Android / iOS / Windows 빌드 성공 |

> 필요한 계정: Google Play 개발자 계정, Apple Developer Program, Steamworks(앱 등록비 필요). 계정 생성과 결제는 직접 해야 한다.

## 6. Unity로 돌아갈 조건

- 2번(iOS 결제) 또는 3번(광고)이 2주 안에 해결되지 않을 때
- Spine 스킨 교체가 Godot에서 불가능할 때
- 출시 전에 콘솔(스위치) 동시 출시가 필수가 될 때

## 출처

- [Unity – Changes to subscription plans and pricing](https://unity.com/products/pricing-updates)
- [Unity – Runtime Fee 취소 공지](https://unity.com/runtime-fee)
- [Wikipedia – Slay the Spire II](https://en.wikipedia.org/wiki/Slay_the_Spire_II)
- [80.lv – Slay the Spire 2 is sticking with Godot](https://80.lv/articles/slay-the-spire-2-is-sticking-with-godot-leaving-unity-behind/)
- [GamingOnLinux – Godot gets a funding boost from Mega Crit (2026.4)](https://gamingonlinux.com/2026/04/godot-gets-a-funding-boost-from-slay-the-spire-2-devs-mega-crit)
- [Wikipedia – Brotato](https://en.wikipedia.com/wiki/Brotato)
- [Godot Docs – Android in-app purchases](https://docs.godotengine.org/en/stable/tutorials/platform/android/android_in_app_purchases.html)
- [Godot Docs – Plugins for iOS (4.6)](https://docs.godotengine.org/en/4.6/tutorials/platform/ios/plugins_for_ios.html)
- [GitHub – hrk4649/godot_ios_plugin_iap](https://github.com/hrk4649/godot_ios_plugin_iap)
- [GitHub – hyochan/godot-iap (OpenIAP)](https://github.com/hyochan/godot-iap)
- [GameDev.net – Godot mobile update April 2026](https://gamedev.net/news/2713-godot-mobile-update-april-2026/)
- [GitHub – poingstudios/godot-admob-plugin](https://github.com/poingstudios/godot-admob-plugin)
- [GodotSteam – Apps class](https://godotsteam.com/classes/apps/)
- [Godot Asset Library – GodotSteam GDExtension 4.4+](https://godotengine.org/asset-library/asset/2445)
- [Esoteric Software – Exploring spine-godot](https://esotericsoftware.com/blog/Exploring-spine-godot)
- [Live2D – Community SDK](https://docs.live2d.com/en/cubism-sdk-tutorials/community-sdk/)
- [Yarn Spinner – Godot docs](https://yarnspinner.dev/docs-beta/godot)
- [Yarn Spinner in 2026](https://yarnspinner.dev/blog/yarn-spinner-in-2026/)
- [inkgd – Choosing between inkgd and godot-ink](https://inkgd.readthedocs.io/en/latest/advanced/choosing_between_inkgd_and_godot_ink.html)
- [ziva.sh – Unity vs Godot 2026 with AI coding tools](https://ziva.sh/blogs/unity-vs-godot-2026-ai) (Godot 도구 판매사 블로그, 참고만)
- [DEV Community – Why AI writes better game code in Godot than in Unity](https://thenote.app/post/en/why-ai-writes-better-game-code-in-godot-than-in-unity-2c9a0sngc4) (개인 경험담)
- [Cinevva – Best 2D game engines 2026](https://app.cinevva.com/guides/best-2d-game-engines-2026) (자사 엔진 판매사, 참고만)
- [Ocean View Games – Unity vs Godot vs Unreal 2026](https://oceanviewgames.co.uk/blog/posts/unity-vs-godot-vs-unreal-2026) (Unity 스튜디오, 참고만)
