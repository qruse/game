# 아트 스타일 가이드 v0.1

> 상태: **스타일 미확정.** P0 단계(스타일 탐색)에서 사용자가 시안 하나를 고르면 `art/refs/style-anchor.png`로 저장하고 이 문서를 확정한다.
> 방향: **서브컬처 애니풍 캐릭터 + 짙은 중세 분위기.** UI와 프레임은 중세 채색 필사본풍(art/samples/sample-b)을 쓴다.

## 1. 프롬프트 조립 규칙

모든 이미지 프롬프트는 아래 순서로 조립한다. 블록 텍스트는 수정하지 말고 그대로 붙인다.

```
[STYLE_BLOCK] + [FORMAT_BLOCK(에셋 종류별)] + [캐릭터 PROMPT (characters.md)] + [에셋별 추가 지시 (manifest.csv의 extra)] + [NEGATIVE_BLOCK]
```

- 프롬프트는 영어로 쓴다(모델의 지시 이해가 가장 안정적이다)
- 참조 이미지: `art/refs/style-anchor.png`는 **항상** 첨부한다. 캐릭터 이미지면 그 캐릭터의 레퍼런스 시트(`art/refs/<char_id>_ref.png`)도 첨부한다
- 같은 캐릭터의 표정 차분은 **새로 생성하지 말고** 기본 스탠딩(`*_portrait_neutral`)을 편집해서 만든다(얼굴만 바꾸기)

## 2. STYLE_BLOCK

```
Anime-style illustration for a Korean/Japanese subculture RPG, clean confident line art,
cel shading with soft gradient highlights, expressive anime eyes, appealing character design.
Setting is grounded low-fantasy medieval Europe (12th-14th century): chainmail, surcoats,
wool, linen, leather, heraldry, candlelight, stone and timber.
Palette: rich but slightly muted medieval colors - deep crimson, royal blue, ochre gold,
forest green, parchment cream, warm browns.
```

## 3. FORMAT_BLOCK (에셋 종류별)

| 키 | 용도 | FORMAT_BLOCK 텍스트 | 생성 크기 | 최종 크기 |
|---|---|---|---|---|
| `ref_sheet` | 캐릭터 레퍼런스 시트 | `Character reference sheet: full body front view, side view and back view of the same character side by side, neutral standing pose, plain flat light grey background, consistent design across all views.` | 1536×1024 | 원본 유지 |
| `portrait` | 대화용 스탠딩 | `Knee-up standing portrait, character facing slightly to the left, both hands visible, centered, plain flat solid #FF00FF magenta background, no shadow on background.` | 1024×1536 | 1024×1536, 투명 PNG |
| `sd` | 전투용 SD | `Chibi SD proportions about 2.5 heads tall, full body, three-quarter view facing right, thick clean outline, readable silhouette at small size, plain flat solid #FF00FF magenta background, no ground shadow.` | 1024×1024 | 512×512, 투명 PNG |
| `cutin` | 궁극기 컷인 | `Dynamic ultimate-skill cut-in, extreme close-up action pose, dramatic lighting and speed lines, wide cinematic composition.` | 1536×1024 → 가로 3:1로 크롭 | 1920×640 |
| `bg_scene` | 대화 배경 | `Background art only, no characters, eye-level view, painterly anime background, atmospheric lighting, 16:9 composition, leave the lower middle area uncluttered for character portraits.` | 16:9 최대 크기 | 1920×1080 |
| `bg_battle` | 전투 맵 배경 | `Top-down orthographic view of a game battlefield, no characters, no perspective distortion, flat walkable ground in the central area covering about 70% of the image, decorative elements only at the edges, even lighting, no grid lines.` | 16:9 최대 크기 | 1920×1080 |
| `cg` | 이벤트 CG | `Key story event illustration, cinematic composition, 16:9.` | 16:9 최대 크기 | 1920×1080 |
| `icon` | 스킬 아이콘 | `Square game skill icon, single bold symbolic subject centered, painterly, high contrast, dark parchment vignette background, no text, no border.` | 1024×1024 | 256×256 |
| `enemy_sd` | 적 SD | `sd` 블록과 같다. 단 `facing left`로 바꾼다 | 1024×1024 | 512×512, 투명 PNG |

> 생성 크기는 모델이 지원하는 가장 가까운 크기를 쓴다. 지원 크기가 바뀌었으면 비율을 지키는 쪽으로 맞추고 이 표를 고친다.

## 4. NEGATIVE_BLOCK

```
Do not include: any text, letters, watermark, signature, logo, UI elements, frames or borders;
modern objects or clothing (zippers, glasses with modern frames, sneakers, guns, phones);
Japanese school uniforms; extra fingers or malformed hands; cropped heads or feet
(unless the format asks for a close-up); sexualized poses or revealing outfits.
```

## 5. 배경 제거 (투명 PNG)

모델의 투명 배경 지원 여부가 불확실하므로 **마젠타 배경으로 생성한 뒤 제거한다.**

1. 모델이 `background: transparent`를 지원하면 그것을 우선 쓴다
2. 아니면 `#FF00FF` 배경으로 생성하고 배경을 제거한다(rembg 같은 도구, 실패하면 크로마키)
3. 가장자리에 마젠타 테두리(fringe)가 남지 않았는지 확인한다
4. 투명 여백을 잘라내되(trim) 캔버스는 FORMAT_BLOCK의 최종 크기로 맞춘다. **발끝이 캔버스 하단 기준선에 오도록 정렬한다**(SD 전투 스프라이트의 위치 정렬용)

## 6. 품질 검사 (QA 체크리스트)

생성한 모든 이미지는 아래를 확인한다. 하나라도 걸리면 다시 생성한다.

- [ ] characters.md의 **MUST KEEP** 항목이 전부 맞다 (머리색, 눈색, 의상, 무기, 장신구)
- [ ] 손가락 개수와 손 모양이 정상이다
- [ ] 글자, 워터마크, 서명이 없다
- [ ] 현대 물건이나 시대에 맞지 않는 요소가 없다
- [ ] 방향이 맞다 (SD 동료는 오른쪽, 적은 왼쪽, 스탠딩은 약간 왼쪽)
- [ ] 같은 캐릭터의 다른 이미지와 나란히 놓았을 때 같은 사람으로 보인다
- [ ] 배경 제거 후 가장자리가 깨끗하다

## 7. 이 문서 밖에서 정하는 것 (Claude가 코드로 만든다)

이미지 생성으로 만들지 않는다. Codex는 이 항목들을 만들지 않는다.

- UI 프레임, 패널, 버튼, 양피지 질감 (SVG / Godot 테마)
- 상태이상 아이콘, 판정 결과 표시, 주사위(d20)와 굴림 애니메이션
- 전투 그리드, 이동 범위, 환경 위험 지대 표시 (불, 물, 전기)
- 스킬 이펙트 (파티클, 셰이더)
- 캐릭터 애니메이션 (SD 이미지를 코드로 움직인다: 흔들기, 돌진, 피격 번쩍임)
- 폰트 (Noto Serif KR / JP 등 무료 상업용 폰트)
