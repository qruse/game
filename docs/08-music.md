# 08. 음악

## 1. 목표

**게임을 안 해 본 사람도 사운드트랙만 따로 찾아 듣는 음악.** 테일즈위버처럼 음악으로도 사랑받고 기억되는 게임.
"RPG 배경음악"처럼 들리는 무난한 곡은 쓰지 않는다. 곡마다 제목만 들어도 멜로디가 떠오르는 한 곡이어야 한다.

## 2. 방향 (2026-10-17 확정: 타이틀 C3 테스트 결과)

**일본 뉴에이지풍 어쿠스틱 3중주.** 피아노·바이올린·첼로가 중심이고, 재즈 화음(7·9화음)이 섞인 피아노 위로 바이올린이 노래한다. 밝아도 어딘가 아련하다.

| 요소 | 정한 것 |
|---|---|
| 중심 편성 | **피아노, 바이올린, 첼로** (곡에 따라 클라리넷, 아코디언, 플루트, 콘트라베이스, 가벼운 손 타악기). **기타는 쓰지 않는다** (2026-10-17 사용자: 기타가 한 번씩 들어가는 게 취향이 아님. 류트는 중세 양념으로 **살짝만** 남긴다) |
| 화성 | 재즈풍 7·9화음을 섞은 맑은 화음. 장조라도 한 방울의 아련함 |
| 질감 | 작은 방에서 연주하는 듯한 따뜻한 어쿠스틱 소리. 웅장한 오케스트라가 아니라 **가까이서 들리는 실내악** |
| 중세 | **한 방울만.** 곡마다 틴 휘슬, 리코더, 하프, 류트(살짝), 덜시머, 허디거디 드론 중 하나가 한 구간에서 색을 낸다 |
| 멜로디 | 한 번 들으면 흥얼거리는 주선율(훅)이 곡의 중심. 반주만 깔리는 배경음은 만들지 않는다 |
| 구성 | 반복용 곡도 인트로 → A → B → 절정 → 돌아오기로 이야기가 있는 완결된 곡 |
| 메인 모티프 | 타이틀곡의 훅을 보스·회상·승리 곡에서 다른 모습으로 다시 쓴다 (Suno Cover) |
| 피할 것 | EDM, 덥스텝, 트랩, 메탈, 신시사이저 패드, 로파이, 에픽 트레일러풍 오케스트라, 보컬 |

**내부 참고 (프롬프트에는 절대 넣지 않는다):** 사용자가 든 레퍼런스는 DJ 오카와리(재즈 피아노 리프 + 바이올린, 부드러운 비트), 어쿠스틱 카페(피아노·바이올린·첼로 3중주, 정열적인 바이올린). 스타일만 따고 이름·곡은 쓰지 않는다 (docs/07-originality.md).

## 3. 곡 카드 (1장 체험판)

**곡 체계 (2026-10-17 사용자 결정):**
- **공용 긴장곡** (4번): 모든 장의 위기 장면·결전 직전
- **공용 보스 전투곡** (6번): 모든 장의 보스 전투
- **보스 테마곡: 장마다 새로 만든다.** 전투곡이 아니라 그 보스의 캐릭터 곡이다. 보스가 처음 모습을 드러내는 장면, 결전 직전 등장 장면에 깐다. 1장은 10번(붉은 수염)

**개성 규칙:** 곡마다 리드 악기, 박자, 조, 템포, 리듬 성격이 모두 달라야 한다. 앞 10초만 들어도 어느 곡인지 구별된다.

| # | 파일 / 가제 | 쓰는 곳 | 리드 | 리듬 · 조 · 템포 | 개성 | 중세 한 방울 |
|---|---|---|---|---|---|---|
| 1 | bgm_title / 다시 열린 문 ✅ | 타이틀 | 피아노 → 바이올린 | 6/8 흔들리는 리듬, G장조, 104 | 첫 여행을 떠나는 설렘. 피아노와 플루트의 부름으로 시작해 바이올린이 훅에서 날아오르고, 마지막 후렴이 크게 터진다 | 틴 휘슬이 바이올린에 대답 |
| 2 | bgm_guild / 먼지 쌓인 장부 | 길드, 일상 대화 | 클라리넷과 피아노 2중주 | 4/4 느긋한 스윙, F장조, 86 | 카페 같은 아늑함. 클라리넷이 묻고 피아노가 답한다. 첼로 피치카토가 발끝을 까딱이게 한다. 이 곡만 브러시 스네어가 살짝 | 브리지에서 류트 한 소절 (살짝) |
| 3 | bgm_chronicle / 잉크가 닿는 길 | 게시판, 연대기 페이지 | 아코디언 | 2/4 경쾌한 걸음, A장조, 116 | 유럽 시골길 같은 여행 느낌. 아코디언 선율 위로 바이올린 피치카토가 펜처럼 달린다 | 해머 덜시머가 반주 일부 |
| 4 | bgm_tension / 다가오는 그림자 (공용 긴장곡) | 모든 장의 위기 장면, 결전 직전 | 피아노 저음 | 5/4, D단조, 96 | 다섯 박이라 발이 걸리는 불안. 바이올린이 줄 가까이 긁는 소리(sul ponticello), 첼로가 낮게 숨 쉰다. 멜로디는 적고 공간이 넓다 | 허디거디의 낮은 지속음 |
| 5 | bgm_battle / 검과 주사위 | 일반 전투 | 피아노 리프와 바이올린 | 4/4 몰아치는 브레이크비트, E단조, 150 | 재즈 피아노 리프가 몰아치고 바이올린과 피아노가 솔로를 주고받는다. **이 곡만 드럼 세트와 베이스가 단단하게** 받친다 | 피들이 훅을 한 번 이어받음 |
| 6 | bgm_boss_battle / 길을 막는 자 (공용 보스 전투곡) | 모든 장의 보스 전투 | 바이올린과 피아노, 현악 합주 | **탱고**, A단조, 128 | 정열적인 탱고 리듬으로 메인 모티프를 단조로 비튼다. 중반에 장조로 돌아서며 희망이 비치는 반격 구간 | 프레임 드럼이 탱고 리듬에 |
| 7 | bgm_memory / 어린 날의 길드 | 호감도 CG, 체험판 끝 | 피아노 독주 → 첼로 | 3/4 아주 느리게, D장조, 66 | 메인 모티프를 느린 왈츠로. 앞 절반은 피아노 하나, 뒤에서 첼로가 대선율로 들어오고 끝에 다시 피아노만 남는다 | 하프 한 줄기 |
| 8 | jingle_win | 전투 승리 | 피아노·바이올린 | 6초 | 메인 모티프 첫 네 음을 밝게 마무리 | 틴 휘슬 |
| 9 | jingle_lose | 전투 패배 | 피아노·첼로 | 6초 | 메인 모티프 첫 네 음을 단조로 내려앉게 | 하프 |
| 10 | bgm_theme_redbeard / 붉은 수염 (1장 보스 테마) | 붉은 수염이 모습을 드러내는 장면 (결전 직전 습격 장면, 소굴 정찰) | 낮은 첼로와 콘트라베이스 (활) | 12/8 건들거리는 무거운 걸음, C단조, 72 | 술 취한 행진처럼 건들거리는 거칠고 탐욕스러운 두목. 조금 우스꽝스럽지만 무섭다. 쿵쿵 밟는 프레임 드럼 위로 투박한 훅. 전투곡처럼 몰아치지 않는다 | 허디거디가 거칠게 으르렁 |

## 4. 만드는 법 (Suno)

1. Create → **Advanced(Custom)** → **Instrumental** 켜기. 모델은 최신 버전
2. 아래 스타일을 **Style** 칸에, 구성 태그를 **Lyrics** 칸에 넣는다. Title 칸에는 가제
3. Advanced Options 의 **Exclude** 칸이 보이면 공통 제외를 넣는다. 안 보이면 비워 둔다. 스타일 칸에 "no ○○"는 쓰지 않는다 (그 단어 때문에 오히려 들어간다)
4. Style Influence 슬라이더가 있으면 70% 정도로 올린다
5. **타이틀부터.** 마음에 드는 한 곡을 정하면 그 훅이 메인 모티프가 된다. 6·7·8·9번은 정한 타이틀 곡을 **Cover** 에 넣고 아래 스타일로 바꿔 만든다
6. 곡마다 최소 6번 생성해서 아래 고르는 기준으로 고른다

**공통 Exclude:** `vocals, guitar, acoustic guitar, electric guitar, EDM, dubstep, trap, metal, synth pad, lo-fi, epic trailer`
- 기타는 스타일 칸에 적지 않아도 Suno 가 끼워 넣는 경우가 있다. Exclude 칸이 없으면 기타가 들어간 결과는 버리고 다시 뽑는다

| # | Style | Lyrics (구성 태그) |
|---|---|---|
| 1 ✅ | `instrumental japanese new age fantasy adventure theme, acoustic chamber trio of piano violin and cello, bright piano melody with jazzy seventh chords, expressive violin answers and soars on the hook, warm cello counter melody, flute and tin whistle answer the violin, light hand percussion, lilting 6/8 rhythm, G major, 104 bpm, heartwarming and exciting like setting off on a first journey, catchy main hook, big uplifting final chorus, intimate warm acoustic room sound` | `[Intro: piano and flute call] [Verse: piano melody, light percussion, cello pulse] [Pre-Chorus: violin rises, trio builds] [Chorus: full hook, violin soars, tin whistle answers] [Bridge: quiet, piano and cello, violin hums] [Final Chorus: everything, uplifting] [Outro: piano and flute, last note rings]` |
| 2 | `instrumental japanese new age cafe piece, warm clarinet and piano duet in playful call and response, cello pizzicato walking line, soft brushed snare, relaxed swing in 4/4, F major, 86 bpm, cozy warm and a little wistful, jazzy seventh chords, a brief soft lute phrase in the bridge, charming catchy melody, intimate warm acoustic room sound` | `[Intro: piano alone] [Verse: clarinet asks, piano answers] [Chorus: both together, cello walks] [Bridge: soft lute phrase] [Chorus] [Outro: clarinet and piano, gentle end]` |
| 3 | `instrumental japanese new age travel piece, accordion carries a bouncy melody, violin pizzicato running like a pen on paper, staccato piano, hammered dulcimer accents, light hand percussion, cheerful 2/4 walking rhythm, A major, 116 bpm, curious and adventurous with a nostalgic european countryside feel, catchy hook, intimate warm acoustic room sound` | `[Intro: staccato piano and pizzicato] [Verse: accordion melody] [Chorus: full hook, violin joins] [Break: dulcimer and pizzicato] [Chorus] [Outro: accordion fades]` |
| 4 | `instrumental dark japanese new age, sparse low piano ostinato in 5/4, D minor, 96 bpm, breathing cello lines, eerie sul ponticello violin, faint hurdy-gurdy drone, distant soft timpani, lots of space and silence, uneasy and suspenseful, minimal melody, intimate acoustic room sound` | `[Intro: low piano ostinato] [Section A: cello enters] [Section B: violin scrapes, drone swells] [Section A] [Outro: ostinato alone]` |
| 5 | `instrumental japanese jazz fusion battle theme, relentless jazzy piano riff, virtuosic violin and piano trading solos, tight live drum kit breakbeat and upright bass, cello stabs, E minor, 150 bpm, fiddle takes the hook once, energetic heroic and a little wistful, catchy riff, crisp warm mix` | `[Intro: piano riff] [Verse: violin melody over drums] [Chorus: full hook] [Solo: piano] [Solo: violin] [Chorus: fiddle hook] [Outro: riff, hard stop]` |
| 6 | `instrumental passionate tango boss battle, acoustic trio of piano violin and cello with a string ensemble, menacing minor-key version of the main theme, sharp tango rhythm with frame drum, A minor, 128 bpm, fierce expressive violin, mid-section turns to major key for a hopeful counterattack, dramatic yet melodic, intimate warm acoustic sound` | `[Intro: tango piano stabs] [Verse: violin plays theme in minor] [Chorus: full ensemble, fierce] [Bridge: turn to major, hopeful] [Final Chorus: everything] [Outro: tango final hit]` |
| 7 | `instrumental japanese new age piano ballad, slow waltz in 3/4, very slow solo piano rendition of the main theme, D major, 66 bpm, cello countermelody joins halfway, single harp glissando, tender bittersweet and nostalgic, intimate room sound, ends on solo piano` | `[Intro: solo piano] [Verse: theme slowly] [Chorus: cello joins] [Bridge: harp] [Outro: solo piano fades]` |
| 8 | `instrumental short victory jingle, first four notes of the main theme, bright piano and violin, tin whistle, 6 seconds, final cadence` | `[Jingle]` |
| 9 | `instrumental short defeat jingle, first four notes of the main theme in minor, soft piano and cello with harp, 6 seconds, falling final cadence` | `[Jingle]` |
| 10 | `instrumental dark japanese new age villain character theme, slow swaggering heavy 12/8 rhythm like a drunken march, low bowed cello and double bass carry a crude menacing melody, rough growling hurdy-gurdy drone, staccato low piano chords, violin sneers in the middle section, stomping frame drum and hand percussion, C minor, 72 bpm, greedy brutish and a little comic, catchy sinister hook, intimate warm acoustic room sound` | `[Intro: frame drum stomps, hurdy-gurdy drone] [Theme: cello and bass melody] [Section B: piano stabs, violin sneers] [Theme: heavier, full] [Outro: drone and one last stomp]` |

## 5. 고르는 기준 (통과 못 하면 다시 생성)

- [ ] 한 번 듣고 나서 **훅을 흥얼거릴 수 있다**
- [ ] **앞 10초**만 들어도 다른 곡과 구별된다
- [ ] 밝은 곡도 **한 방울의 아련함**이 있다
- [ ] 곡 안에 감정의 흐름(시작 → 고조 → 마무리)이 있다
- [ ] 중세 악기는 양념 수준. 중세 음악처럼 들리면 탈락
- [ ] AI 티가 나는 소리가 없다: 음이 흐물거림, 갑자기 끊김, 뭉개진 믹스, 중간에 엉뚱한 장르로 바뀜
- [ ] 따로 플레이리스트에 넣어 들어도 **듣고 싶은 곡**이다

## 6. 게임에 넣기

- 받은 파일은 `audio/raw/` 에 원본 그대로 두고, 게임용은 OGG(96~128kbps)로 바꿔 `godot/audio/` 에 넣는다
- 반복 곡은 반복 시작·끝 지점을 잡아 끊김 없이 돈다. 장면이 바뀌면 1초 크로스페이드
- 웹 빌드는 파일 하나 25MiB 제한이 있어 음악은 게임 본체(pck)와 따로 내려받는다
- 상업 이용은 유료 요금제로 만든 곡만. 무료 요금제로 만든 곡은 비교용으로만 듣고 쓰지 않는다
- 반응이 좋으면 정한 곡들을 작곡가에게 편곡·실연 녹음을 맡겨 사운드트랙 DLC 로 낸다
