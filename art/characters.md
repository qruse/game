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

- 세계: 12~14세기 유럽풍 저마법(low fantasy) 중세. 몰락한 명문 모험가 길드 **"은빛 등불 길드"(가칭)**를 재건하는 이야기
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
- MUST KEEP: 짧은 은회색 단발, 초록 눈, 왼쪽 볼의 작은 흉터
  - 전투복 전용(일상복에는 넣지 않음): 짙은 녹색 후드 망토, 가죽 조끼, 쌍단검
- BODY: `Cecile, an 18-year-old adult woman street thief, short silver-grey bob hair, green eyes, small scar on her left cheek, lean agile build, mischievous grin`
- COMBAT: `wearing a dark green hooded cloak, a fitted brown leather vest over a linen shirt, dark breeches, fingerless gloves, soft leather boots, twin daggers on her belt`
- CASUAL: `wearing a loose off-white linen shirt knotted at the waist showing a little midriff, short brown breeches, knee-high socks, soft shoes, a coin pouch on her hip, tossing an apple, relaxed tomboyish pose, no daggers, no cloak`

### C03 아델하이트 (Adelheid / アーデルハイト) · 20세 · 원거리 딜러 · 마법사
- 특기: 마법학, 지식 (지능) · 노출: 일상복 **낮음** (귀여움 담당)
- 성격: 냉소적인 독서광. 사람보다 책을 좋아한다. 밤샘 독서가 일상
- 이야기: 수도원에서 금서를 몰래 읽다 쫓겨난 견습 수녀 마법사
- MUST KEEP: 땋아 내린 검은 긴 머리, 금색 눈, 둥근 철테 안경
  - 전투복 전용(일상복에는 넣지 않음): 짙은 남색 수도복을 개조한 로브, 쇠사슬로 묶은 마법서, 나무 지팡이
- BODY: `Adelheid, a 20-year-old young woman former novice nun turned mage, long black hair in a single thick braid, golden eyes, round wire-rimmed glasses, aloof sarcastic face`
- COMBAT: `wearing a modified dark navy nun's habit robe with a short cape, carrying a thick grimoire bound with an iron chain and a gnarled wooden staff`
- CASUAL: `wearing an oversized dark charcoal wool tunic as a nightshirt that ends just above the knees, sleeves so long they cover her hands to the fingertips, thick knitted wool stockings, soft wool house slippers, a knitted shawl around her shoulders, her braid loosened and messy with stray hairs, holding a small candle in a holder and an ordinary open book (not her chained grimoire), sleepy cozy expression, no staff, no weapons`
- 일상복 메모 (2026-10-15 사용자 결정): 두 번째 시안(무릎 길이 니트 잠옷 + 숄 + 꽈배기 털양말 + 털 실내화 + 촛불과 책)을 그대로 승인. 바깥 장면에서도 이 옷을 쓴다. 첫 시안은 지팡이·부츠·발목 길이 로브로 나와 재작업. 전투복(발목까지 오는 남색 로브 + 지팡이)과 실루엣이 확실히 달라야 한다. 무릎 위 잠옷 + 손을 덮는 소매 + 털양말 + 실내화 + 풀어진 땋은 머리가 핵심

### C04 미리엄 (Miriam / ミリアム) · 24세 · 서포터 · 순례자 사제
- 특기: 설득 (매력), 치유 · 노출: 일상복 **높음** (청순한 순례자의 의외의 성숙함, 반전 매력)
- 성격: 다정하고 상냥하지만 속을 알 수 없다
- 이야기: 떠돌이 순례자. 길드를 찾아온 이유를 말하지 않는다
- MUST KEEP: 물결치는 금발, 하늘색 눈, 나무 성표 목걸이
  - 전투복 전용(일상복에는 넣지 않음): 흰 베일, 크림색 순례자 망토와 조개 배지, 순례 지팡이
- BODY: `Miriam, a 24-year-old adult woman, wavy golden blonde hair, sky-blue eyes, gentle but mysterious smile, graceful mature figure, wooden holy symbol necklace`
- COMBAT: `wearing a white veil over her hair, a cream pilgrim's cloak with a scallop-shell badge over a modest grey-blue travel dress, a tall pilgrim's staff`
- CASUAL: `adult woman, hair down without the veil, wearing an elegant ivory linen dress with an off-shoulder neckline, an open back and a side slit, a thin gold chain around her waist, barefoot, relaxed graceful pose with a faint teasing smile, no veil, no cloak, no staff`

### C05 로웬 (Rowen / ローウェン) · 22세 · 컨트롤러 · 음유시인
- 특기: 공연, 기만 (매력) · 노출: 일상복 **높음** (무대 의상)
- 성격: 능청스러운 거짓말쟁이이자 정보통. 노래 실력은 진짜다
- 이야기: 옛 길드의 영웅담을 노래하며 떠돌던 음유시인. 길드가 재건된다는 소문을 듣고 찾아온다
- MUST KEEP: 붉은 기 도는 주황색 반묶음 머리, 호박색 눈, 류트
  - 전투복 전용(일상복에는 넣지 않음): 깃털 베레모, 겨자색·자주색 두 가지 색 더블릿
- BODY: `Rowen, a 22-year-old adult woman bard, reddish-orange hair in a half-up ponytail, amber eyes, sly playful smile, curvy figure`
- COMBAT: `wearing a feathered beret, a bicolor doublet in mustard yellow and plum purple, dark hose, short travel boots, a lute slung on her back`
- CASUAL: `adult woman, wearing a tavern stage costume: a plum corset bodice with bare shoulders and a modest neckline, a layered ruffled skirt with a high slit, dark thigh-high stockings, small bells on one ankle, a feather hairpin, simple heeled shoes, holding her lute mid-performance, winking, no beret`

### C06 고드릭 (Godric / ゴドリック) · 55세 · 원거리 딜러 · 노병 석궁수
- 특기: 조사 (지능), 운동 (힘) · 노출: 없음
- 성격: 무뚝뚝하고 말수가 적다. 술을 좋아한다
- 이야기: 옛 길드 몰락 사건의 **생존자.** 진실을 알지만 말하지 않는다(H1 메인 미스터리의 열쇠)
- MUST KEEP: 짧은 회색 머리와 수염, 오른쪽 눈의 가죽 안대
  - 전투복 전용(일상복에는 넣지 않음): 낡은 갬비슨, 은빛 등불 문양이 바랜 망토, 석궁
- BODY: `Godric, a 55-year-old veteran, short grey hair and trimmed grey beard, leather eyepatch over his right eye, broad weathered build, stern weary face`
- COMBAT: `wearing a worn quilted gambeson, a faded cloak with a tarnished silver lantern emblem, a heavy crossbow`
- CASUAL: `wearing a rolled-sleeve linen shirt and a leather apron, plain wool trousers, worn ankle boots, holding a wooden tankard of ale, a faint rare smile, no crossbow, no cloak`

---

## 첫 확장팩 동료 (출시 후)

### C07 이졸데 (Isolde / イゾルデ) · 21세 · 근접 딜러 · 몰락 귀족 결투가
- 특기: 기만, 설득 (매력) · 노출: 일상복 **높음** (귀족 드레스)
- 성격: 오만하고 자존심이 세지만 약자에게 약하다
- 이야기: 가문이 몰락해 결투 대리인으로 생계를 잇는 영애. 개인 퀘스트는 가문 몰락의 진실
- MUST KEEP: 세로 롤 금발 트윈테일, 진홍색 눈, 가문 문장 반지
  - 전투복 전용(일상복에는 넣지 않음): 검은색·진홍색 승마복풍 결투복, 레이피어
- BODY: `Isolde, a 21-year-old adult woman fallen noble, golden blonde twin tails in drill curls, crimson eyes, proud haughty face, elegant slender figure, a signet ring with a family crest`
- COMBAT: `wearing a black and crimson riding-style dueling coat with silver buttons, fitted breeches, tall black boots, a rapier`
- CASUAL: `adult woman, wearing a black and crimson evening gown with an off-shoulder neckline and a high leg slit, long black silk gloves, a velvet choker bearing her family crest, black heeled shoes, holding a folded fan, haughty elegant pose, no rapier`

### C08 카샤 (Kasha / カーシャ) · 19세 · 원거리 딜러 · 북방 사냥꾼
- 특기: 은신 (민첩), 운동 (힘) · 노출: 일상복 **중간**
- 성격: 과묵하고 자연을 사랑한다. 늑대와는 말이 통한다
- 이야기: 북방 숲에서 내려온 사냥꾼. 늑대 "스콜"과 함께 다닌다
- MUST KEEP: 흰 머리 느슨하게 땋은 장발, 청회색 눈, 회색 늑대 스콜
  - 전투복 전용(일상복에는 넣지 않음): 털 달린 갈색 망토, 롱보우
- BODY: `Kasha, a 19-year-old adult woman northern huntress, long white hair in loose braids, blue-grey eyes, calm quiet face, a large grey wolf companion`
- COMBAT: `wearing a brown fur-trimmed cloak over leather hunting garb, a longbow and a quiver of arrows`
- CASUAL: `adult woman, wearing a Nordic-style embroidered linen dress with bare shoulders, a fur shawl draped loosely on her arms, a flower crown, barefoot on grass, the wolf resting beside her, no bow, no quiver`

---

## 주요 NPC (전투복·일상복 구분 없음, 스탠딩 표정 3종)

| ID | 이름 | 역할 | PROMPT |
|---|---|---|---|
| N01 | 마르타 (Martha) | 선술집 주인, 길드의 오랜 이웃 | `Martha, a boisterous big-hearted tavern keeper in her early 40s, broad sturdy plump build, strong forearms with rolled sleeves, hands on hips with a wooden ladle, faded green kerchief over an auburn bun with grey streaks, freckles across a wide nose, ruddy cheeks, beauty mark by the mouth, brass hoop earrings, stained apron` |
| N02 | 공증인 바실 (Basil) | 길드 재건 서류를 관리하는 공증인 | `Basil, a tall lanky fastidious notary in his late 30s, long narrow face, aquiline nose, thin mustache and small pointed goatee, small round spectacles low on the nose, slicked-back hair with a widow's peak, ink-stained fingers, quill behind ear, black scholar's robe, brass key ring and wax seal stamp on the belt, ledger clutched to his chest` |
| N03 | 영주 오스왈드 (Oswald) | 지역 영주, 속을 알 수 없다 | `Lord Oswald, a stately nobleman in his 50s, fur-lined mantle, gold chain of office, neatly trimmed beard` |
| N04 | 주교 엘리노어 (Eleanor) | 수도원과 교회의 권력자 | `Bishop Eleanor, an elderly stern woman, white and gold vestments, mitre, crozier` |
| N06 | 가면의 남자 | 흑막 | `a mysterious masked figure, plain white porcelain mask, black hooded cloak, faceless and unsettling` |
| N07 | 마을 사람 (남) | 범용 의뢰인 | `a sturdy weathered farmer in his 40s, short scruffy beard, crooked nose, frayed straw hat, patched linen tunic, pitchfork` |
| N08 | 마을 사람 (여) | 범용 의뢰인 | `a village woman in her early 30s, round freckled face, thick dark braid, faded blue headscarf, wool dress and worn apron, basket of eggs` |

---

## 과거의 은빛 등불 길드 (회상 전용)

> 봉인된 방의 과거 회상에서 플레이하는 인물들. 회상 파티 3명(P01~P03)은 스탠딩 + SD + 레퍼런스 시트를 만든다. 의상은 1벌(전성기 길드 제복)이고, 표정은 3종(기본, 긍정, 부정)으로 줄인다.
> 공통 의상 요소: **파란 서코트/망토에 은빛 등불 문장.** 현재 길드 재건 후 쓰일 문장과 같다.

### P01 에드릭 (Edric / エドリック) · 40대 · 전 길드장 · 지휘관
- 이야기: 몰락 사건의 중심. 현재는 행방불명
- MUST KEEP: 짧게 다듬은 흑갈색 머리와 수염, 회색 눈, 손등의 흉터, 파란 서코트의 은빛 등불 문장, 장검과 길드장의 등불 모양 펜던트
- PROMPT: `Edric, a charismatic guildmaster in his early 40s, neatly trimmed dark brown hair and short beard, grey eyes, scarred hands, wearing a blue surcoat with a silver lantern emblem over a mail shirt, a lantern-shaped silver pendant, a longsword, warm confident smile`

### P02 기사 알도 (Sir Aldo / アルド) · 40대 · 탱커 · 리나의 아버지
- 이야기: 몰락 때 죽었다고 알려져 있다. 리나와 닮은 얼굴
- MUST KEEP: **리나와 같은 갈색 머리와 연보라색 눈**, 짧은 머리, 듬직한 체격, 리나의 것과 같은 흰 바탕 붉은 셰브런 방패(리나가 물려받은 방패), 파란 서코트의 은빛 등불 문장
- PROMPT: `Sir Aldo, a broad-shouldered knight in his 40s, short chestnut-brown hair, pale violet eyes, kind but stern face resembling his daughter, wearing chainmail and a blue surcoat with a silver lantern emblem, a white heater shield with a red chevron, a longsword`

### P03 젊은 고드릭 (Young Godric / 若きゴドリック) · 30세 · 석궁수
- 이야기: 현재의 고드릭. 아직 두 눈이 있고 잘 웃는다
- MUST KEEP: 짧은 흑회색 머리, **두 눈 모두 멀쩡함(안대 없음)**, 짧은 수염, 파란 망토의 은빛 등불 문장(아직 바래지 않음), 석궁
- PROMPT: `young Godric, a 30-year-old crossbowman, short dark grey hair, both eyes intact (no eyepatch), light stubble, cheerful cocky grin, wearing a quilted gambeson and a bright blue cloak with a polished silver lantern emblem, a heavy crossbow`

### P04 모르칸트 (Morcant / モルカント) · 30대 · 길드의 검사 (회상 속 NPC)
- 이야기: **훗날의 흑기사.** 회상마다 표정과 태도가 조금씩 어두워진다
- MUST KEEP: 어깨까지 오는 검은 머리, 날카로운 검은 눈, 왼쪽 눈썹의 흉터, 파란 서코트의 은빛 등불 문장, 대검
- PROMPT: `Morcant, a lean swordsman in his 30s, shoulder-length black hair, sharp dark eyes, a scar through his left eyebrow, wearing dark plate pieces over a blue surcoat with a silver lantern emblem, a greatsword on his back, an easy smile that does not reach his eyes`

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
| B03 | 3 | **보스: 흑기사** | `the Black Knight, a towering knight in blackened full plate, tattered black cape, greatsword, a faded silver lantern emblem scratched off his shield` |
