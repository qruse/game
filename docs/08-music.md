# 08. 음악

## 1. 방향

**피아노가 멜로디를 이끄는 뉴에이지.** 2000년대 한국 온라인 RPG(테일즈위버 같은)의 감성을 오마주하되, 곡과 멜로디는 우리 것으로 한다 (docs/07-originality.md).

| 요소 | 정한 것 |
|---|---|
| 중심 악기 | 피아노 |
| 받쳐 주는 악기 | 현악 패드, 어쿠스틱 기타, 플루트·틴 휘슬, 오보에, 가벼운 퍼커션 |
| 화성 | 밝고 따뜻한 장조 위주, 7·9화음을 섞은 살짝 재즈·퓨전 느낌 |
| 멜로디 | 한 번 들으면 흥얼거릴 수 있는 또렷한 주선율. 메인 테마 멜로디를 길드·감동 장면에서 변주 |
| 전투 | 무거운 오케스트라 대신 **피아노 + 드럼 + 일렉 기타**의 빠른 퓨전 록. 보스만 현악과 합창을 얹는다 |
| 피할 것 | EDM, 덥스텝, 트랩, 메탈, 에픽 트레일러풍 오케스트라, 보컬 |

## 2. 1장 체험판 곡 목록

| # | 파일 이름 | 쓰는 곳 | 길이 | 분위기 |
|---|---|---|---|---|
| 1 | bgm_title | 타이틀 | 2~3분 | 메인 테마. 그리움과 설렘, 등불이 다시 켜지는 느낌 |
| 2 | bgm_guild | 길드 화면, 일상 대화 | 2분 반복 | 낡았지만 따뜻한 집. 느긋한 피아노와 기타 |
| 3 | bgm_chronicle | 의뢰 게시판, 연대기 페이지 | 2분 반복 | 길을 나서는 가벼운 발걸음. 플루트 멜로디 |
| 4 | bgm_tension | 위기 장면, 결전 직전 | 1분 반 반복 | 낮은 피아노 반복음과 현악 트레몰로 |
| 5 | bgm_battle | 일반 전투 | 2분 반복 | 빠른 피아노 리프 + 드럼 + 일렉 기타 |
| 6 | bgm_boss | 붉은 수염 결전 | 2분 반 반복 | 전투곡보다 무겁게, 현악·합창(가사 없는 '아~') |
| 7 | bgm_memory | 호감도 CG, 체험판 끝 | 2~3분 | 피아노 독주로 시작하는 메인 테마 느린 변주 |
| 8 | jingle_win | 전투 승리 | 5~8초 | 밝은 피아노·현악 마무리 |
| 9 | jingle_lose | 전투 패배 | 5~8초 | 내려가는 피아노 화음 |

## 3. Suno 프롬프트

- 모두 **Instrumental** 켜기. 스타일 칸에 아래 영어 문장을 그대로 넣는다 (게임·작곡가 이름은 넣지 않는다).
- 고급 설정 Exclude Styles 에는 공통으로 `vocals, EDM, dubstep, trap, metal, epic trailer` 를 넣는다.
- 한 곡에 여러 번 생성해 보고 마음에 드는 것만 내려받는다 (Pro 는 내려받기 월 20곡).
- 반복 재생용 곡은 끝을 페이드아웃 없이 받는 게 좋다. 반복 구간 자르기는 Claude 가 한다.

| # | 스타일 프롬프트 |
|---|---|
| 1 | `new age, piano-led, warm strings, acoustic guitar, flute, nostalgic and hopeful, memorable main melody, 2000s Korean online RPG title theme, 88 bpm, major key` |
| 2 | `new age, gentle piano and nylon acoustic guitar, soft string pad, cozy tavern warmth, relaxed slice of life, light jazz chords, 80 bpm, seamless loop` |
| 3 | `new age, bright piano and flute melody, light acoustic guitar strumming, soft shaker, adventurous walking pace, open road, 100 bpm, seamless loop` |
| 4 | `new age, low repeating piano ostinato, string tremolo, soft timpani, uneasy and suspenseful, minor key, 90 bpm, seamless loop` |
| 5 | `piano rock fusion, fast piano riff, driving drums, electric guitar, energetic RPG battle, bright minor key, 150 bpm, seamless loop` |
| 6 | `piano rock fusion, heavy drums, electric guitar, dramatic strings, wordless choir, intense RPG boss battle, minor key, 160 bpm, seamless loop` |
| 7 | `new age, solo piano intro, slow emotional ballad, soft strings join later, tender and bittersweet, 70 bpm, major key` |
| 8 | `short victory fanfare, bright piano and strings, 6 seconds, ending cadence` |
| 9 | `short defeat jingle, descending soft piano chords, 6 seconds, ending cadence` |

## 4. 게임에 넣기

- 받은 파일은 `audio/raw/` 에 원본 그대로 두고, 게임용은 OGG(96~128kbps)로 바꿔 `godot/audio/` 에 넣는다.
- 반복 곡은 반복 시작·끝 지점을 잡아 끊김 없이 돈다. 장면이 바뀌면 1초 크로스페이드.
- 웹 빌드는 파일 하나 25MiB 제한이 있어 음악은 게임 본체(pck)와 따로 내려받는다.
- 상업 이용은 Suno 유료 요금제로 만든 곡만. 무료 요금제로 만든 곡은 쓰지 않는다.
