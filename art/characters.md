# 캐릭터 바이블 (아트용) v0.2

> 상태: **초안.** 이름, 성격, 외형은 기획 확정 전 임시안이다. 바뀌면 이 문서를 먼저 고치고, 이미지는 그다음에 만든다.
> **v0.2 변경:** 동료마다 **전투복 / 일상복**을 나눴다. 일상복은 컨셉에 맞게 예쁘게, 섹시 컨셉은 노출을 허용한다. 모든 동료를 **성인(18세 이상)**으로 바꿨다. 리나는 샘플(art/samples/codex-lina-v1.png)을 반영했다.

## 프롬프트 사용법

이미지 하나의 캐릭터 부분은 아래 두 블록을 이어 붙여 만든다.

```
[BODY]  +  [COMBAT 또는 CASUAL]
```

- **BODY:** 옷과 상관없이 늘 같은 외형(머리, 눈, 체형, 흉터 등)
- **COMBAT:** 전투복. 의뢰 수행 중 대화, 전투 SD, 컷인에 쓴다
- **CASUAL:** 일상복. 길드 하우스, 캠프, 호감도 이벤트 대화에 쓴다
- **MUST KEEP:** 모든 이미지에서 같아야 하는 항목(몸). 품질 검사(QA)의 기준이다
- **전투복 전용:** MUST KEEP 아래 줄. 전투복 이미지에서만 지킨다. **일상복에는 넣지 않는다**

### 설정대로 나오게 하는 규칙 (2026-10-15, S09 아델하이트 일상복에서 나온 문제)

S09 일상복 시트에 설정에 없는 지팡이가 들어가고(Codex가 "정체성 유지"라며 프롬프트에 추가), 전투복 시트를 주 참조로 넣어서 긴 로브·부츠 실루엣이 그대로 따라왔다. 그래서 아래를 지킨다.

1. **블록에 적힌 것만 그린다.** 일상복의 옷과 소품은 CASUAL 블록이 전부다. 무기, 갑옷, 망토, 지팡이, 마법서 같은 전투복 전용 물건은 CASUAL 블록에 이름이 있을 때만 넣는다. "알아보기 쉽게"라는 이유로 소품을 더하지 않는다
2. **정체성은 BODY와 MUST KEEP(몸)으로만 지킨다.** 얼굴, 머리, 눈, 체형, 흉터, 장신구가 같으면 같은 사람이다
3. **전투복 시트를 참조로 넣을 때는 얼굴·머리·체형 참조라고 프롬프트에 적고, 옷·소품·실루엣은 따라 하지 말라고 적는다**
4. **블록에 없는 신발·소품은 장면에 맞게 정한다.** 실내 일상복이면 실내화나 가벼운 신발이다. 전투용 부츠를 기본값으로 쓰지 않는다
5. **QA에 설정 대조표를 붙인다.** 블록의 구절을 하나씩 나눠 `설정 구절 / 결과(맞음·다름)`로 보고한다. 하나라도 "다름"이면 통과가 아니다
6. 일상복은 전투복과 **실루엣이 달라야 한다**(길이, 폭, 소매, 머리 모양 중 둘 이상)

### 얼굴 개성 규칙 (2026-10-16 사용자 지시: "너무 다 똑같이 생긴 느낌")
- 동료마다 **얼굴 자체**를 다르게 한다. 머리색·눈색만 바꾼 같은 얼굴 금지. 예쁜 건 유지한다
- 동료마다 BODY 블록의 **FACE** 구절을 반드시 프롬프트에 넣는다: 눈매(올라간 눈·처진 눈·반쯤 감긴 눈), 눈썹 굵기, 피부색, 얼굴형, 입 모양·버릇(덧니, 비뚜름한 웃음), 점·주근깨 같은 표시, 키와 체형
- 기준은 리나(표준 미소녀 얼굴). 다른 동료는 리나와 나란히 세웠을 때 실루엣만 봐도, 얼굴만 잘라 봐도 누군지 알 수 있어야 한다
- 다른 동료의 그림을 참조로 붙일 때는 **화풍·크기만** 따르고 얼굴은 따르지 않는다고 프롬프트에 적는다

### 새 캐릭터 개성 체크리스트 (2026-10-17 사용자 지시: "앞으로 만들 캐릭터들 개성도 잘 살려야 됨")
지금 승인된 캐릭터(리나·세실·아델하이트·미리엄)는 그대로 두고, **아직 그리지 않은 모든 캐릭터**(동료, NPC, 과거 길드원, 확장팩)는 처음 그리기 전에 아래 8개를 채운다. 하나라도 기존 캐릭터와 겹치면 바꾼다.

| # | 항목 | 기준 |
|---|---|---|
| 1 | 한 줄 콘셉트 | 기존 캐릭터와 겹치지 않는 역할·성격 (예: 표준 기사, 톰보이 도둑, 시큰둥한 책벌레, 속을 모를 누나) |
| 2 | 실루엣 | 머리 모양과 옷 윤곽만 검게 칠해도 누군지 알 수 있다 |
| 3 | 대표 색 | 아래 색 표에서 아직 안 쓴 색 |
| 4 | 얼굴 (FACE) | 눈매, 눈썹, 피부색, 얼굴형, 입 버릇, 표식(점·주근깨·흉터·문신) 중 최소 4개가 기존과 다르다 |
| 5 | 키·체형 | 리나 기준으로 크다·작다·다부지다·가늘다를 적는다 |
| 6 | 상징 소품·버릇 | 그 캐릭터만의 물건이나 몸짓 하나 |
| 7 | 말투 | 대사 한 줄만 봐도 누군지 알 수 있는 말버릇 |
| 8 | 반전 매력 | 겉모습과 다른 의외의 면 하나 (일상복·호감도 장면에서 쓴다) |

**대표 색 표 (겹치지 않게)**

| 캐릭터 | 대표 색 |
|---|---|
| 리나 | 진홍 + 크림 |
| 세실 | 짙은 녹색 + 갈색 가죽 |
| 아델하이트 | 남색 + 검정 |
| 미리엄 | 아이보리 + 금 |
| 로웬 | 겨자 + 자주 |
| 고드릭 | 회색 + 바랜 파랑 |
| 이졸데 | 검정 + 와인 (리나의 진홍과 구별되게 어두운 와인색) |
| 카샤 | 흰색 + 회청색 + 털 갈색 |
| 노라 (NPC 부관) | 청록 + 놋쇠 |

## 노출 수준 규칙

| 등급 | 허용 범위 |
|---|---|
| 낮음 | 노출 없음. 귀엽고 단정한 옷 |
| 중간 | 어깨, 쇄골, 배꼽 일부, 무릎 위 다리 |
| 높음 | 어깨 전체, 등 트임, 다리 트임(슬릿), 적당한 가슴골 |

- **모든 등급 공통 금지:** 나체, 속이 비치는 옷, 속옷 차림, 신체 부위를 강조하는 자세나 구도
- 노출이 "중간" 이상인 캐릭터는 프롬프트에 반드시 `adult woman` 을 넣는다
- 노출은 **일상복에만** 둔다. 전투복은 모두 실용적인 중세 장비로 통일해 세계관의 무게를 지킨다(BG3 톤)

## 공통 설정

- 세계: 12~14세기 유럽풍 저마법(low fantasy) 중세. 평화의 시대에 몰락한 시골 모험가 길드 **"하웰 모험가 길드"**(전대 용사와는 관계없는 평범한 길드)를 재건하는 이야기. 길드 문장은 파란 바탕에 은빛 우물과 교차한 두 검 (등불 문장은 2026-10-17에 버렸다)
- **주인공(길드 단장)은 화면에 그리지 않는다.** 플레이어 시점 인물이다
- 크로마키 배경색 **#FF00FF(마젠타)는 어떤 캐릭터 디자인에도 쓰지 않는다**(배경 제거용)

---

## 본편 동료 (메인 스토리 합류)

### C01 리나 (Lina / リナ) · 18세 · 탱커 · 견습 기사
- 특기: 위협, 운동 (힘) · 노출: 전투복 없음 / 일상복 **낮음**
- 성격: 고지식하고 정의감이 넘친다. 기사도에 진심이지만 허당이다. 요리를 못하는데 자꾸 하려고 한다
- 이야기: 몰락한 길드 마지막 기사의 딸. 아버지의 이름을 되찾으려고 길드에 남은 유일한 사람
- 기준 이미지: `art/samples/codex-lina-v1.png` (수정 전 시안)
- MUST KEEP: 갈색 긴 머리, 연보라색 눈, **왼쪽(보는 사람 기준 오른쪽) 옆머리의 작은 땋은 머리를 묶은 붉은 리본**
  - SD(오른쪽을 보는 3/4 시점)에서는 리본이 **얼굴 쪽 관자놀이**에 보여야 한다. 뒤통수 쪽에 있으면 반대다. 기준: `C01_sd_idle.png`
  - 전투복 전용(일상복에는 넣지 않음): 붉은 서코트의 금색 **크로스 플러리(끝이 꽃잎처럼 퍼지는 십자)**, 서코트 아래 흰 프릴 치맛단, 사슬 갑옷, 흰 바탕에 붉은 셰브런 방패, 롱소드
- BODY: `Lina, an 18-year-old young woman squire, long chestnut-brown hair with a small side braid tied with a red ribbon on the left side of her head, pale violet eyes, slender athletic build, earnest determined face`
- COMBAT: `wearing a full chainmail hauberk and chainmail chausses, a crimson surcoat with gold trim and a gold cross fleury with flared floral tips on the chest, a white frilled underskirt hem peeking under the surcoat, brown leather belt, brown leather gloves, tall brown leather boots with straps, a longsword in her right hand, a white heater shield with a red chevron strapped to her left forearm (held by its inner straps, not by the rim)`
- CASUAL: `wearing a cream linen kirtle dress with a red laced bodice and puffed sleeves rolled up to the elbows, a flour-dusted white apron (she keeps failing at cooking), hair down with the same braid and red ribbon, holding a wooden spoon and a flour-dusted wooden mixing bowl`
- 일상복 메모 (2026-10-15 사용자 결정): S01 일상복 시안의 목선(가슴골 살짝 보임)은 그대로 허용. 기본 표정은 차분한 미소, 당황한 얼굴은 표정 변형으로 만든다

### C02 세실 (Cécile / セシル) · 18세 · 근접 딜러 · 도적
- 특기: 은신, 손재주 (민첩) · 노출: 일상복 **중간**
- 성격: 장난기 많고 입이 험하지만 의리가 있다. 톰보이
- 이야기: 길드 금고를 털러 들어왔다가 텅 빈 금고를 보고 어이가 없어 눌러앉은 소매치기
- MUST KEEP: 짧은 은회색 단발(삐죽삐죽한 울프컷), 초록 눈, 왼쪽 볼의 작은 흉터, **2026-10-16 개성: 볕에 그을린 피부와 코의 주근깨, 고양이처럼 올라간 눈매, 굵은 눈썹, 덧니가 보이는 비뚜름한 웃음, 한쪽 귀의 은귀걸이, 작고 마른 체격(리나보다 작다)**
  - 전투복 전용(일상복에는 넣지 않음): 짙은 녹색 후드 망토, 가죽 조끼, 쌍단검
- BODY: `Cecile, an 18-year-old adult woman street thief, shaggy choppy short silver-grey wolf-cut bob with a longer messy strand by the face, green eyes, small scar on her left cheek. FACE: sun-kissed lightly tanned skin with a dusting of freckles across the nose, sharp upturned cat-like eyes, thick straight expressive eyebrows, a cocky lopsided grin showing one small snaggletooth fang, a small silver hoop and a stud in her right ear, a slightly narrower foxy face; petite wiry build, clearly shorter than Lina`
- COMBAT: `wearing a dark green hooded cloak, a fitted brown leather vest over a linen shirt, dark breeches, fingerless gloves, soft leather boots, twin daggers on her belt`
- CASUAL: `wearing a loose off-white linen shirt knotted at the waist showing a little midriff, short brown breeches, knee-high socks, soft shoes, a coin pouch on her hip, tossing an apple, relaxed tomboyish pose, no daggers, no cloak`

### C03 아델하이트 (Adelheid / アーデルハイト) · 20세 · 원거리 딜러 · 마법사
- 특기: 마법학, 지식 (지능) · 노출: 일상복 **낮음** (귀여움 담당)
- 성격: 냉소적인 독서광. 사람보다 책을 좋아한다. 밤샘 독서가 일상
- 이야기: 수도원에서 금서를 몰래 읽다 쫓겨난 견습 수녀 마법사
- MUST KEEP: 땋아 내린 검은 긴 머리, 금색 눈, 둥근 철테 안경, **2026-10-16 개성: 반듯한 일자 앞머리, 창백한 피부와 밤샘으로 생긴 눈 밑 그늘, 반쯤 감긴 나른한 처진 눈매, 가는 눈썹, 오른쪽 눈 밑 눈물점, 시큰둥한 입매, 키가 크고 가늘다(리나보다 크다)**
  - 전투복 전용(일상복에는 넣지 않음): 짙은 남색 수도복을 개조한 로브, 쇠사슬로 묶은 마법서, 나무 지팡이
- BODY: `Adelheid, a 20-year-old young woman former novice nun turned mage, long black hair in a single thick braid with a straight blunt-cut fringe across the forehead, golden eyes, round wire-rimmed glasses. FACE: pale porcelain skin with faint shadows under the eyes from reading all night, heavy-lidded half-closed droopy eyes with a bored deadpan look, thin arched eyebrows, a small beauty mark under her right eye, a small unimpressed flat mouth, a longer oval face and long neck; tall slender willowy build, clearly taller than Lina`
- COMBAT: `wearing a modified dark navy nun's habit robe with a short cape, carrying a thick grimoire bound with an iron chain and a gnarled wooden staff`
- CASUAL: `wearing an oversized dark charcoal wool tunic as a nightshirt that ends just above the knees, sleeves so long they cover her hands to the fingertips, thick knitted wool stockings, soft wool house slippers, a knitted shawl around her shoulders, her braid loosened and messy with stray hairs, holding a small candle in a holder and an ordinary open book (not her chained grimoire), sleepy cozy expression, no staff, no weapons`
- 일상복 메모 (2026-10-15 사용자 결정): 두 번째 시안(무릎 길이 니트 잠옷 + 숄 + 꽈배기 털양말 + 털 실내화 + 촛불과 책)을 그대로 승인. 바깥 장면에서도 이 옷을 쓴다. 첫 시안은 지팡이·부츠·발목 길이 로브로 나와 재작업. 전투복(발목까지 오는 남색 로브 + 지팡이)과 실루엣이 확실히 달라야 한다. 무릎 위 잠옷 + 손을 덮는 소매 + 털양말 + 실내화 + 풀어진 땋은 머리가 핵심

### C04 미리엄 (Miriam / ミリアム) · 24세 · 서포터 · 순례자 사제
- 특기: 설득 (매력), 치유 · 노출: 일상복 **높음** (청순한 순례자의 의외의 성숙함, 반전 매력)
- 성격: 다정하고 상냥하지만 속을 알 수 없다
- 이야기: 떠돌이 순례자. 길드를 찾아온 이유를 말하지 않는다
- MUST KEEP: 물결치는 금발, 하늘색 눈, 나무 성표 목걸이, **2026-10-16 개성: 부드럽고 둥근 성숙한 얼굴, 긴 속눈썹의 온화한 처진 눈, 왼쪽 눈 밑 점, 도톰한 입술, 키 크고 굴곡 있는 체형**
  - 전투복 전용(일상복에는 넣지 않음): 흰 베일, 크림색 순례자 망토와 조개 배지, 순례 지팡이
- BODY: `Miriam, a 24-year-old adult woman, long voluminous wavy golden blonde hair, sky-blue eyes, wooden holy symbol necklace. FACE: a soft rounded mature face clearly older than the other girls, gentle droopy eyes with long lashes, a beauty mark under her left eye, full soft lips in a calm knowing half-smile, warm peach skin; tall graceful curvy figure`
- COMBAT: `wearing a white veil over her hair, a cream pilgrim's cloak with a scallop-shell badge over a modest grey-blue travel dress, a tall pilgrim's staff`
- CASUAL: `adult woman, hair down without the veil, wearing an elegant ivory linen dress with an off-shoulder neckline, an open back and a side slit, a thin gold chain around her waist, barefoot, relaxed graceful pose with a faint teasing smile, no veil, no cloak, no staff`

### C05 로웬 (Rowen / ローウェン) · 22세 · 컨트롤러 · 음유시인
- 특기: 공연, 기만 (매력) · 노출: 일상복 **높음** (무대 의상)
- 성격: 능청스러운 거짓말쟁이이자 정보통. 노래 실력은 진짜다
- 이야기: 옛 길드의 영웅담을 노래하며 떠돌던 음유시인. 길드가 재건된다는 소문을 듣고 찾아온다
- MUST KEEP: 붉은 기 도는 주황색 반묶음 머리, 호박색 눈, 류트, **개성: 올리브빛 피부, 한쪽 눈썹을 늘 치켜올린 능청스러운 표정, 양 볼 보조개, 눈가에 그린 작은 별 무대 화장, 하트형 얼굴과 뾰족한 턱, 보통 키(리나와 비슷)**
- 말투: 노래하듯 과장되고 말끝을 올린다. "자, 여기서 퀴즈~ 내가 한 말 중 진짜는 몇 개게?"
- 반전 매력: 거짓말쟁이인데 노래할 때만은 절대 거짓말을 안 한다
  - 전투복 전용(일상복에는 넣지 않음): 깃털 베레모, 겨자색·자주색 두 가지 색 더블릿
- BODY: `Rowen, a 22-year-old adult woman bard, reddish-orange hair in a half-up ponytail, amber eyes. FACE: warm olive skin, wide expressive almond eyes with thick lashes, one eyebrow always raised in amusement, deep dimples in both cheeks, a wide theatrical sly smile, a small heart-shaped face with a pointed chin, a tiny painted gold star beside her left eye as stage makeup; average height like Lina, curvy figure`
- COMBAT: `wearing a feathered beret, a bicolor doublet in mustard yellow and plum purple, dark hose, short travel boots, a lute slung on her back`
- CASUAL: `adult woman, wearing a tavern stage costume: a plum corset bodice with bare shoulders and a modest neckline, a layered ruffled skirt with a high slit, dark thigh-high stockings, small bells on one ankle, a feather hairpin, simple heeled shoes, holding her lute mid-performance, winking, no beret`

### C06 고드릭 (Godric / ゴドリック) · 55세 · 원거리 딜러 · 노병 석궁수
- 특기: 조사 (지능), 운동 (힘) · 노출: 없음
- 성격: 무뚝뚝하고 말수가 적다. 술을 좋아한다
- 이야기: 옛 길드 몰락 사건의 **생존자.** 진실을 알지만 말하지 않는다(H1 메인 미스터리의 열쇠)
- MUST KEEP: 짧은 회색 머리와 수염, 오른쪽 눈의 가죽 안대, **개성: 한 번 부러졌던 코, 굵고 처진 눈썹, 깊은 눈가 주름, 안대 위아래로 이어진 흉터, 볕에 탄 거친 피부, 리나보다 머리 하나 큰 떡 벌어진 몸**
- 말투: 짧게 끊는다. "…그래." "마셔." 꼭 필요한 말만 한다
- 반전 매력: 아이들과 동물에게는 서툴게 다정하다
  - 전투복 전용(일상복에는 넣지 않음): 낡은 갬비슨, 빛바랜 파란 망토(용사 일행 시절의 것), 석궁
- BODY: `Godric, a 55-year-old veteran, short grey hair and trimmed grey beard, leather eyepatch over his right eye. FACE: a once-broken crooked nose, thick heavy drooping eyebrows, deep crow's feet and forehead lines, an old scar running above and below the eyepatch, sun-weathered rough skin, a stern weary face; a head taller than Lina, broad barrel-chested build, NOT a handsome young man`
- COMBAT: `wearing a worn quilted gambeson, a faded old blue cloak, a heavy crossbow`
- CASUAL: `wearing a rolled-sleeve linen shirt and a leather apron, plain wool trousers, worn ankle boots, holding a wooden tankard of ale, a faint rare smile, no crossbow, no cloak`

---

## 첫 확장팩 동료 (출시 후)

### C07 이졸데 (Isolde / イゾルデ) · 21세 · 근접 딜러 · 몰락 귀족 결투가
- 특기: 기만, 설득 (매력) · 노출: 일상복 **높음** (귀족 드레스)
- 성격: 오만하고 자존심이 세지만 약자에게 약하다
- 이야기: 가문이 몰락해 결투 대리인으로 생계를 잇는 영애. 개인 퀘스트는 가문 몰락의 진실
- MUST KEEP: 세로 롤 금발 트윈테일, 진홍색 눈, 가문 문장 반지, **개성: 높은 광대와 곧은 콧날의 날카로운 귀족 얼굴, 내려다보는 듯한 긴 속눈썹의 아몬드 눈, 각지게 올라간 가는 눈썹, 도자기처럼 흰 피부, 와인색 입술의 도도한 입매, 아랫입술의 아주 작은 흉터(결투 상처), 꼿꼿한 자세, 리나와 비슷한 키에 가늘다**
- 대표 색: 검정 + 와인 (리나의 진홍과 구별)
- 말투: 고풍스러운 아가씨 말투. "그 정도로 저를 이기실 생각이셨나요?" 진심일 때만 반말이 튀어나온다
- 반전 매력: 가난해서 몰래 바느질 부업을 한다
  - 전투복 전용(일상복에는 넣지 않음): 검은색·진홍색 승마복풍 결투복, 레이피어
- BODY: `Isolde, a 21-year-old adult woman fallen noble, golden blonde twin tails in drill curls, crimson eyes, a signet ring with a family crest. FACE: sharp aristocratic features with high cheekbones and a straight narrow nose, almond eyes with long dark lashes and a haughty downward gaze, thin sharply angled eyebrows, porcelain-white skin, wine-colored lips in a proud little pout, a tiny dueling scar on her lower lip; ramrod-straight posture, Lina's height, slender elegant figure`
- COMBAT: `wearing a black and deep wine-red riding-style dueling coat with silver buttons, fitted breeches, tall black boots, a rapier`
- CASUAL: `adult woman, wearing a black and crimson evening gown with an off-shoulder neckline and a high leg slit, long black silk gloves, a velvet choker bearing her family crest, black heeled shoes, holding a folded fan, haughty elegant pose, no rapier`

### C08 카샤 (Kasha / カーシャ) · 19세 · 원거리 딜러 · 북방 사냥꾼
- 특기: 은신 (민첩), 운동 (힘) · 노출: 일상복 **중간**
- 성격: 과묵하고 자연을 사랑한다. 늑대와는 말이 통한다
- 이야기: 북방 숲에서 내려온 사냥꾼. 늑대 "스콜"과 함께 다닌다
- MUST KEEP: 흰 머리 느슨하게 땋은 장발, 청회색 눈, 회색 늑대 스콜, **개성: 바람에 붉어진 볼과 코끝, 흰 눈썹, 넓게 떨어진 차분한 눈, 곧고 또렷한 콧날, 턱에 세로로 그은 푸른 문신 두 줄(북방 부족 표시), 좀처럼 웃지 않는 작은 입, 리나보다 크고 다부진 체격**
- 말투: 단어 몇 개로만 말한다. "…눈 온다. 내일." 그런데 늑대 스콜에게는 길고 다정하게 말한다
- 반전 매력: 단 음식 앞에서 무너진다
  - 전투복 전용(일상복에는 넣지 않음): 털 달린 갈색 망토, 롱보우
- BODY: `Kasha, a 19-year-old adult woman northern huntress, long white hair in loose braids, blue-grey eyes, a large grey wolf companion. FACE: fair skin with wind-reddened cheeks and nose tip, white eyebrows, wide-set calm eyes, a strong straight nose, two thin vertical blue tribal tattoo lines on her chin, a small serious mouth that rarely smiles; taller than Lina, sturdy athletic build`
- COMBAT: `wearing a brown fur-trimmed cloak over leather hunting garb, a longbow and a quiver of arrows`
- CASUAL: `adult woman, wearing a Nordic-style embroidered linen dress with bare shoulders, a fur shawl draped loosely on her arms, a flower crown, barefoot on grass, the wolf resting beside her, no bow, no quiver`

---

## 주요 NPC (전투복·일상복 구분 없음, 스탠딩 표정 3종)

| ID | 이름 | 역할 | PROMPT |
|---|---|---|---|
| N01 | 마르타 (Martha) | 선술집 주인, 길드의 오랜 이웃 | `Martha, a boisterous big-hearted tavern keeper in her early 40s, broad sturdy plump build, strong forearms with rolled sleeves, hands on hips with a wooden ladle, faded green kerchief over an auburn bun with grey streaks, freckles across a wide nose, ruddy cheeks, beauty mark by the mouth, brass hoop earrings, stained apron` |
| N02 | 공증인 바실 (Basil) | 길드 재건 서류를 관리하는 공증인 | `Basil, a tall lanky fastidious notary in his late 30s, long narrow face, aquiline nose, thin mustache and small pointed goatee, small round spectacles low on the nose, slicked-back hair with a widow's peak, ink-stained fingers, quill behind ear, black scholar's robe, brass key ring and wax seal stamp on the belt, ledger clutched to his chest` |
| N03 | 영주 오스왈드 (Oswald) | 지역 영주, 속을 알 수 없다 | `Lord Oswald, a stately nobleman in his mid 50s, handsome in a cold calculating way, silver-streaked dark hair swept back, a sharp pointed goatee, heavy-lidded pale grey eyes that measure everything, a thin polite smile, faint lines at the eyes and mouth, tall lean posture, fur-lined mantle, gold chain of office, rings on gloved fingers, NOT a young man` |
| N04 | 주교 엘리노어 (Eleanor) | 수도원과 교회의 권력자 | `Bishop Eleanor, a woman in her late 60s with a graceful dignified face, silver hair pinned under the mitre, high cheekbones, piercing pale blue eyes, deep but elegant wrinkles, tight thin lips, upright regal posture, white and gold vestments, mitre, crozier, NOT a young woman` |
| N06 | 가면의 남자 | 흑막 | `a mysterious masked figure, plain white porcelain mask, black hooded cloak, faceless and unsettling` |
| N07 | 마을 사람 (남) | 범용 의뢰인 | `a sturdy weathered farmer in his 40s, short scruffy beard, crooked nose, frayed straw hat, patched linen tunic, pitchfork` |
| N11 | 촌장 토비아스 (Tobias) | 어린 주인공을 알아본 에드릭의 귓속말을 20년 동안 기억한 사람. 1장에서 길드 열쇠를 맡기고, 길드 등급 승급 장면을 맡는다 | `Elder Tobias, the village chief of Harwell, a kindly but shrewd man in his late 60s, NOT a young man, a long oval face with deep laugh lines, a bald crown with a neat white fringe of hair, bushy white eyebrows, a short trimmed white beard, warm hazel eyes, a slightly stooped tall thin frame, a plain brown wool coat over a moss-green tunic, a walking staff carved with a small well, a ring of old keys on his belt, gentle knowing smile` |
| N12 | 대장장이 그레타 (Greta) | 하웰 대장간 주인. 장비 사기·강화. 호탕하고 일 욕심이 많다 | `Greta, the Harwell blacksmith, a burly cheerful adult woman in her mid 30s, sun-tanned skin, a square jaw, short cropped ash-blonde hair under a red headband, a soot smudge on one cheek, a small burn scar on the left forearm, broad shoulders and strong muscular arms, attractive in a sturdy way, a scorched leather apron over a sleeveless linen shirt, heavy gloves tucked in her belt, a forging hammer resting on her shoulder, a big toothy grin` |
| N13 | 잡화점 주인 핍 (Pip) | 하웰 잡화점 주인. 소모품·선물·식재료. 수다스럽고 흥정을 좋아한다 | `Pip, the Harwell general store keeper, a plump fussy man in his mid 50s, NOT a young man, a round face with rosy cheeks, a large curled grey mustache, a bald head under a small embroidered cap, small bright eyes, short stocky build, a striped vest over a white shirt, a measuring cord around his neck, a wooden abacus in hand, an eager salesman smile` |
| N08 | 마을 사람 (여) | 범용 의뢰인 | `a village woman in her early 30s, round freckled face, thick dark braid, faded blue headscarf, wool dress and worn apron, basket of eggs` |
| N14 | 부관 노라 (Nora) | 하웰 모험가 길드 부관. 접수·장부·일정 담당. 길드 하우스 로비에 서서 이번 주 할 일을 알려 준다. 호감도(신임) 3단계 (docs/04-game-flow.md 6.4절). 전투에 나오지 않는다 | `Nora, the deputy officer of the Harwell adventurers' guild, an attractive adult woman of 26, NOT a young girl, slightly taller and slimmer than an average heroine with a very upright posture, a copper-red chin-length bob with straight-cut side locks and a small brass pen-nib hairpin, narrow upturned fox-like amber eyes that look half-smiling, thick straight dark brows, a slim V-shaped jaw, light warm olive skin, a small tear mole under her left eye, a polite businesslike smile with one corner of the mouth raised, a long teal deputy's coat with brass buttons over a white high-collared blouse, a teal armband with the Harwell guild emblem (blue shield, silver stone well, two crossed swords) on her left upper arm, a dark charcoal long skirt and polished brown boots, an open brass pocket watch in her right hand, a rolled quest notice held at her waist in her left hand` |

### N14 노라 개성 체크리스트 (2026-10-17)
| # | 항목 | 노라 |
|---|---|---|
| 1 | 한 줄 콘셉트 | 웃으면서 마감을 독촉하는 비서. 깍듯한 존댓말, 숫자에 칼같다 |
| 2 | 실루엣 | 턱선 단발 보브 + 무릎 아래까지 오는 긴 부관 코트, 꼿꼿한 자세 |
| 3 | 대표 색 | 청록 + 놋쇠 |
| 4 | 얼굴 | 가늘게 올라간 여우눈(호박색), 짙은 일자 눈썹, 갸름한 V턱, 따뜻한 올리브 피부, **본인 왼쪽 눈 밑 눈물점**, 한쪽 입꼬리만 올라간 사무적 미소 |
| 5 | 키·체형 | 리나보다 조금 크고 가늘다 |
| 6 | 상징 소품·버릇 | 놋쇠 회중시계를 딸깍 여닫는다. 놋쇠 펜촉 머리핀. (바실과 겹치지 않게 깃펜·장부는 들지 않는다) |
| 7 | 말투 | "단장님, 장부 마감까지 사흘 남았습니다. 웃는 얼굴로 기다릴게요." 문장마다 숫자가 들어간다 |
| 8 | 반전 매력 | 어릴 때부터 하웰 길드의 오랜 팬. 옛 의뢰서를 전부 스크랩해 두었다 |

---

## 전대 용사 일행 (회상 전용)

> 봉인된 방의 과거 회상에서 플레이하는 인물들. 회상 파티 3명(P01~P03)은 스탠딩 + SD + 레퍼런스 시트를 만든다. 의상은 1벌(전성기 길드 제복)이고, 표정은 3종(기본, 긍정, 부정)으로 줄인다.
> 공통 의상 요소: **파란 서코트/망토 (문장 없음).** 용사 일행은 하웰 길드와 관계없으므로 하웰 문장을 넣지 않는다 (2026-10-17).

### P01 에드릭 (Edric / エドリック) · 40대 · 전 길드장 · 지휘관
- 이야기: 30년 전 재앙을 쓰러뜨린 **용사**. 몰락 사건의 중심이고 현재는 행방불명. **누구보다 강한 검사이자 지휘관**이다 (2026-10-17 사용자 확정: 강한 건 에드릭, 약한 건 단장). docs/02 8.0절
- MUST KEEP: 짧게 다듬은 흑갈색 머리와 수염, 회색 눈, 손등의 흉터, 파란 서코트, 장검과 은빛 펜던트, **개성: 위압적인 영웅상이 아니라 친근하고 소탈한 얼굴인데 은근히 잘생겼다(미형), 웃으면 눈가에 접히는 주름, 살짝 휜 코, 단련된 탄탄한 체격(알도보다 키는 작다)**
- 말버릇: "문은 열어 둬. 누가 두드릴지 모르니까."
- PROMPT: `Edric, a legendary hero and guildmaster in his early 40s, a friendly approachable everyman face that is still quietly handsome, neatly trimmed dark brown hair and short beard, kind grey eyes with laugh lines, a slightly crooked nose, scarred hands, a lean battle-hardened athletic build a little shorter than Aldo, wearing a plain blue surcoat over a mail shirt, a simple silver pendant, a longsword, warm trusting smile`

### P02 기사 알도 (Sir Aldo / アルド) · 40대 · 탱커 · 리나의 아버지
- 이야기: 몰락 때 죽었다고 알려져 있다. 리나와 닮은 얼굴
- MUST KEEP: **리나와 같은 갈색 머리와 연보라색 눈**, 짧은 머리, 듬직한 체격, **개성: 각진 턱과 짧은 턱수염, 굵은 일자 눈썹, 리나를 닮은 순한 눈매, 일행 중 가장 큰 키**, 리나의 것과 같은 흰 바탕 붉은 셰브런 방패(리나가 물려받은 방패), 파란 서코트
- PROMPT: `Sir Aldo, a broad-shouldered knight in his 40s, the tallest of the party, short chestnut-brown hair, pale violet eyes, a square jaw with a short beard, thick straight eyebrows, kind gentle eyes resembling his daughter, wearing chainmail and a plain blue surcoat, a white heater shield with a red chevron, a longsword`

### P03 젊은 고드릭 (Young Godric / 若きゴドリック) · 30세 · 석궁수
- 이야기: 현재의 고드릭. 아직 두 눈이 있고 잘 웃는다
- MUST KEEP: 짧은 흑회색 머리, **두 눈 모두 멀쩡함(안대 없음)**, 짧은 수염, 선명한 파란 망토(아직 바래지 않음), 석궁
- PROMPT: `young Godric, a 30-year-old crossbowman, short dark grey hair, both eyes intact (no eyepatch), light stubble, cheerful cocky grin, wearing a quilted gambeson and a bright blue cloak, a heavy crossbow`

### P04 모르칸트 (Morcant / モルカント) · 30대 · 길드의 검사 (회상 속 NPC)
- 이야기: **훗날의 흑기사.** 회상마다 표정과 태도가 조금씩 어두워진다
- MUST KEEP: 어깨까지 오는 검은 머리, 날카로운 검은 눈, 왼쪽 눈썹의 흉터, **개성: 움푹 들어간 볼, 창백한 피부, 깊게 꺼진 눈, 얇은 입술, 마르고 길쭉한 체형**, 파란 서코트, 대검
- PROMPT: `Morcant, a lean lanky swordsman in his 30s, shoulder-length black hair, sharp deep-set dark eyes, hollow cheeks, pale skin, thin lips, a scar through his left eyebrow, wearing dark plate pieces over a plain blue surcoat, a greatsword on his back, an easy smile that does not reach his eyes`

---

## 적 (SD 전투용)

> **적 규칙 (2026-10-16 사용자):** 적은 **보스까지 모두** 투박하고 못생기게, 수수하게 그린다 (주먹코, 작은 눈, 삐뚤어진 이, 땅딸막하고 둔한 체형, 때 묻은 옷). 채도 낮게, 장식 최소, 명암 단순, 험상궂거나 우스꽝스러운 얼굴. 잘생긴 적은 없다(사용자가 따로 말할 때만). 실루엣과 무기만 또렷하게 해서 동료가 돋보이게 한다. 잡몹은 대기 그림 1장만 만든다. 보스(B)는 동작 5장이고 덩치만 크게, 생김새는 똑같이 투박하게

| ID | 챕터 | 이름 | PROMPT |
|---|---|---|---|
| E01 | 1 | 도적 | `a bandit with a short sword, ragged hood, leather jerkin` |
| E02 | 1 | 도적 궁수 | `a bandit archer with a shortbow, cloth mask` |
| E03 | 1 | 늑대 | `a lean grey wolf, snarling` |
| E04 | 1 | 멧돼지 | `a huge wild boar with tusks` |
| E05 | 1 | 덫사냥꾼 | `a poacher trapper carrying bear traps and a hatchet` |
| B01 | 1 | **보스: 붉은 수염** | `Redbeard, a hulking ugly brutish bandit chief with a scraggly red beard, broken nose, missing teeth, pot belly, crude rusty greataxe, crude mismatched patched armor` |
| E06 | 2 | 해골 병사 | `a skeleton soldier with a rusted sword and broken shield` |
| E07 | 2 | 구울 | `a gaunt ghoul with long claws` |
| E08 | 2 | 이단 사교도 | `a heretic cultist in a dark red robe holding a ritual dagger` |
| E09 | 2 | 사교도 사제 | `a cult priest with a censer emitting purple smoke` |
| E10 | 2 | 거대 거미 | `a giant cave spider` |
| B02 | 2 | **보스: 타락한 수도원장** | `the Fallen Abbot, an undead abbot in tattered monk robes, glowing eyes, holding a black candle staff` |
| E11 | 3 | 용병 기사 | `a mercenary knight in plate armor with a mace` |
| E12 | 3 | 석궁병 | `a city crossbowman in a kettle helmet` |
| E13 | 3 | 도시 경비병 | `a city guard with a halberd and the city's tabard` |
| E14 | 3 | 암살자 | `an assassin in black with two curved knives` |
| E15 | 3 | 전투견 | `an armored war hound` |
| B03 | 3 | **보스: 흑기사** | `the Black Knight, a towering knight in blackened full plate, tattered black cape, greatsword, an old emblem scratched off his shield` |
