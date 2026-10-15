# 아트 스타일 가이드 v0.2

> 상태: **스타일 거의 확정.** 기준 시안은 `art/samples/codex-lina-v1.png`(Codex 리나 시안 1). 수정본이 승인되면 `art/refs/style-anchor.png`로 저장한다.
> 방향: **서브컬처 애니풍 캐릭터 + 짙은 중세 분위기.** UI와 프레임은 중세 채색 필사본풍(art/samples/sample-b)을 쓴다.
> **v0.2 변경:** 전투복/일상복 구분, 대화 화면용 스탠딩 규칙(4절), 표정 편집은 얼굴 영역만, 노출 규칙 반영.

## 1. 프롬프트 조립 규칙

```
[STYLE_BLOCK] + [FORMAT_BLOCK] + [BODY] + [COMBAT 또는 CASUAL] + [extra] + [NEGATIVE_BLOCK]
```

- BODY / COMBAT / CASUAL은 `characters.md`에서 그대로 가져온다. 어떤 의상을 쓸지는 manifest의 `outfit` 열이 정한다. NPC와 적은 표의 PROMPT 하나만 쓴다
- 프롬프트는 영어로 쓴다
- 참조 이미지: `art/refs/style-anchor.png`는 **항상** 첨부한다. 캐릭터 이미지면 그 의상의 레퍼런스 시트(`art/refs/<char_id>_ref_<outfit>.png`)도 첨부한다
- 표정 차분은 **새로 생성하지 말고** 기본 표정(`neutral`)을 편집한다(3.1절)

## 2. STYLE_BLOCK

```
Anime-style illustration for a Korean/Japanese subculture RPG, clean confident line art,
cel shading with soft gradient highlights, detailed but readable rendering of fabric, chainmail and leather,
expressive anime eyes, appealing character design.
Setting is grounded low-fantasy medieval Europe (12th-14th century): chainmail, surcoats,
wool, linen, leather, heraldry, candlelight, stone and timber.
Palette: rich but slightly muted medieval colors - deep crimson, royal blue, ochre gold,
forest green, parchment cream, warm browns.
```

## 3. FORMAT_BLOCK (에셋 종류별)

| 키 | 용도 | FORMAT_BLOCK 텍스트 | 생성 크기 | 최종 크기 |
|---|---|---|---|---|
| `ref_sheet` | 레퍼런스 시트 | `Character reference sheet: full body front view, side view and back view of the same character side by side, neutral standing pose, plain flat light grey background, consistent design across all views.` | 1536×1024 | 원본 유지 |
| `portrait` | **대화용 스탠딩** (4절) | `Dialogue standing portrait for a visual-novel style conversation screen: knee-up framing, character facing the viewer with the body angled slightly, eyes looking at the viewer, centered, the top of the head close to the top edge with a small margin, whole figure from head to knees inside the canvas, hands and props fully inside the canvas, plain flat solid #FF00FF magenta background, no shadow on the background.` | 1024×1536 | 1024×1536, 투명 PNG |
| `sd` | 전투용 SD (전투복만) | `Chibi SD proportions about 2.5 heads tall, full body, three-quarter view facing right, thick clean outline, simplified details readable at small size (simplify chainmail into a light pattern), plain flat solid #FF00FF magenta background, no ground shadow.` | 1024×1024 | 512×512, 투명 PNG |
| `cutin` | 궁극기 컷인 (전투복) | `Dynamic ultimate-skill cut-in, extreme close-up action pose, dramatic lighting and speed lines, wide cinematic composition.` | 1536×1024 → 가로 3:1로 크롭 | 1920×640 |
| `bg_scene` | 대화 배경 | `Background art only, no characters, eye-level view, painterly anime background, atmospheric lighting, 16:9 composition, leave the center area uncluttered because character portraits will stand there.` | 16:9 최대 크기 | 1920×1080 |
| `bg_battle` | 전투 맵 배경 | `High-angle three-quarter top-down view of a game battlefield, like a classic JRPG tactics map, looking down at about 60 degrees so that chibi characters drawn in three-quarter view look naturally standing on the ground, no characters, minimal perspective distortion, flat walkable ground in the central area covering about 70% of the image, decorative elements only at the edges, even lighting, no grid lines.` | 16:9 최대 크기 | 1920×1080 |
| `cg` | 이벤트 CG | `Key story event illustration, cinematic composition, 16:9.` | 16:9 최대 크기 | 1920×1080 |
| `icon` | 스킬 아이콘 | `Square game skill icon, single bold symbolic subject centered, painterly, high contrast, dark parchment vignette background, no text, no border.` | 1024×1024 | 256×256 |
| `enemy_sd` | 적 SD | `sd` 블록과 같다. 단 `facing left`로 바꾼다 | 1024×1024 | 512×512, 투명 PNG |

> 생성 크기는 모델이 지원하는 가장 가까운 크기를 쓴다. 지원 크기가 바뀌었으면 비율을 지키는 쪽으로 맞추고 이 표를 고친다.

### 3.1 표정 차분 만드는 법 (중요)

대화 중 표정이 바뀔 때 **몸, 옷, 머리카락이 1픽셀도 움직이면 안 된다.** 그래서:

1. `neutral` 이미지를 그대로 두고, **얼굴 영역(눈썹~턱)만 마스크로 지정해서 편집**한다
2. 편집 지시: `Edit only the masked face area. Keep everything outside the mask pixel-identical. Change the facial expression to: <표정>.`
3. 결과물을 `neutral`과 겹쳐서 얼굴 밖에 차이가 없는지 확인한다(차이 비교 이미지로 검사)
4. 마스크 편집이 불가능한 환경이면, 편집 결과에서 얼굴 영역만 잘라 `neutral` 위에 합성한다

표정 6종: `neutral`(기본), `smile`(웃음), `angry`(화남), `sad`(슬픔), `surprised`(놀람), `embarrassed`(당황·부끄러움)

## 4. 대화 화면용 스탠딩 규칙

스탠딩 일러스트는 **캐릭터 대화 화면**에 그대로 쓴다. 화면 구성(Claude가 구현)은 이렇다.

```
┌──────────────────────────────────────────┐
│               (배경: bg_scene)             │
│        ┌────────┐                          │
│        │ 스탠딩  │   ← 말하는 캐릭터는 밝게, │
│        │ 일러스트│      듣는 캐릭터는 어둡게  │
│        │        │                          │
│ ┌──────┴────────┴──────────────────────┐   │
│ │ 이름  대사 텍스트...                    │   │
│ │ [선택지] [d20 판정 선택지 75%]          │   │
│ └──────────────────────────────────────┘   │
└──────────────────────────────────────────┘
```

이 화면에서 쓰기 위한 규칙:

| 규칙 | 이유 |
|---|---|
| **정면을 보고 몸만 살짝 비튼 자세** | 좌우 반전 없이 화면 왼쪽·가운데·오른쪽 어디에 세워도 어색하지 않다 |
| **좌우 반전 금지** | 리나의 리본, 세실의 흉터처럼 한쪽에만 있는 특징이 뒤바뀐다 |
| **무릎 위 구도, 머리 위 여백은 작게** | 대화창이 화면 아래 1/3을 가리므로 실제로 보이는 건 머리~허리다. 얼굴이 화면 위쪽에 와야 한다 |
| **손, 무기, 소품이 캔버스 밖으로 잘리지 않게** | 화면 크기에 따라 위치를 옮겨도 잘린 단면이 보이지 않게 |
| **캐릭터끼리 머리 크기를 비슷하게** | 키 차이는 코드에서 위치로 조정한다. 이미지 안의 머리 크기가 들쭉날쭉하면 대화 화면이 어색하다 |
| **표정 차분은 얼굴만 바뀌어야 함** | 3.1절. 표정이 바뀔 때 일러스트가 흔들리면 안 된다 |

**의상 사용처:**

| 상황 | 의상 |
|---|---|
| 의뢰 수행 중 대화, 판정 대화 | 전투복 (`combat`) |
| 길드 하우스, 캠프, 호감도 이벤트, 개인 스토리의 일상 장면 | 일상복 (`casual`) |
| 전투 SD, 궁극기 컷인 | 전투복만 |

## 5. NEGATIVE_BLOCK

```
Do not include: any text, letters, watermark, signature, logo, UI elements, frames or borders;
modern objects or clothing (zippers, modern eyewear, sneakers, guns, phones);
Japanese school uniforms; extra fingers or malformed hands; cropped head, hands or props;
nudity, see-through clothing, underwear, or poses that focus on body parts.
```

- 노출 수준은 characters.md의 각 캐릭터 등급을 따른다. 일상복 CASUAL 블록에 적힌 범위 이상으로 노출을 늘리지 않는다
- 노출이 "중간" 이상인 이미지는 프롬프트에 `adult woman` 이 들어 있는지 확인한다

## 6. 배경 제거 (투명 PNG)

모델의 투명 배경 지원 여부가 불확실하므로 **마젠타 배경으로 생성한 뒤 제거한다.**

1. 모델이 `background: transparent`를 지원하면 그것을 우선 쓴다
2. 아니면 `#FF00FF` 배경으로 생성하고 배경을 제거한다(rembg 같은 도구, 실패하면 크로마키)
3. 가장자리에 마젠타 테두리(fringe)가 남지 않았는지 확인한다. 금발·은발·흰 머리 캐릭터는 특히 머리카락 끝을 확인한다
   - **알파 기준 (S01에서 정함):** 캐릭터 안쪽은 알파 255(완전 불투명). 가장자리 1~2px만 반투명으로 남겨 부드럽게 한다. 알파를 0/255로만 나누면(이진화) 머리카락 끝이 계단처럼 거칠어지고, 안쪽까지 252~254로 두면 살짝 비친다. 둘 다 피한다
4. **스탠딩:** 캔버스 1024×1536을 유지하고 위치를 옮기지 않는다(표정 차분과 정렬이 깨진다)
5. **SD:** 투명 여백을 잘라낸 뒤 512×512 캔버스에 **발끝이 하단 기준선(아래에서 24px)에 오도록** 정렬한다

## 7. 품질 검사 (QA 체크리스트)

생성한 모든 이미지는 아래를 확인한다. 하나라도 걸리면 다시 생성한다.

- [ ] characters.md의 **MUST KEEP** 항목이 전부 맞다 (머리색, 눈색, 의상, 무기, 장신구, 좌우 위치)
- [ ] 손가락 개수와 손 모양이 정상이다. **소품을 잡는 방식이 자연스럽다** (예: 방패는 안쪽 손잡이를 잡거나 팔에 끼운다. 가장자리를 쥐지 않는다)
- [ ] 글자, 워터마크, 서명이 없다
- [ ] 현대 물건이나 시대에 맞지 않는 요소가 없다
- [ ] 방향이 맞다 (스탠딩은 정면, SD 동료는 오른쪽, 적은 왼쪽)
- [ ] 같은 캐릭터의 다른 이미지와 나란히 놓았을 때 같은 사람으로 보인다
- [ ] 노출이 그 캐릭터의 등급을 넘지 않는다
- [ ] 배경 제거 후 가장자리가 깨끗하다
- [ ] (표정 차분) 얼굴 밖 영역이 `neutral`과 같다

## 8. 이 문서 밖에서 정하는 것 (Claude가 코드로 만든다)

이미지 생성으로 만들지 않는다. Codex는 이 항목들을 만들지 않는다.

- UI 프레임, 대화창, 패널, 버튼, 양피지 질감 (SVG / Godot 테마)
- 상태이상 아이콘, 판정 결과 표시, 주사위(d20)와 굴림 애니메이션
- 전투 그리드, 이동 범위, 환경 위험 지대 표시 (불, 물, 전기)
- 스킬 이펙트 (파티클, 셰이더)
- 캐릭터 애니메이션 (SD 이미지를 코드로 움직인다: 흔들기, 돌진, 피격 번쩍임), 대화 스탠딩의 숨쉬기·등장 연출
- 폰트 (Noto Serif KR / JP 등 무료 상업용 폰트)

### S03 승인 후 공통 적용 · 2026-10-15

- 동작 SD는 승인된 sd_idle과 sd_attack을 함께 참조한다. 리나가 오른쪽을 보는 3/4 시점에서는 붉은 리본과 작은 땋은 머리가 얼굴 쪽(먼 쪽) 관자놀이에 있어야 한다. 뒤통수 쪽이면 잘못된 위치다.
- 일부만 틀렸으면 해당 영역만 마스크 편집하고 마스크 밖 RGBA 차이 0을 검사한다. 최대 3회 안에 해결되지 않으면 최선 시안을 보존하고 보고한다.
