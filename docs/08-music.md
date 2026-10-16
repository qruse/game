# 08. 음악

## 1. 방향

**피아노가 멜로디를 이끄는 뉴에이지에 중세 악기를 입힌다.** 2000년대 한국 온라인 RPG(테일즈위버 같은)의 감성을 오마주하되, 곡과 멜로디는 우리 것으로 한다 (docs/07-originality.md).
피아노 혼자 두면 현대 뉴에이지로 들리므로, 곡마다 **중세 악기 하나 이상**이 멜로디나 리듬을 같이 맡는다.

| 요소 | 정한 것 |
|---|---|
| 중심 악기 | 피아노 |
| 중세 색 | 류트, 하프, 리코더·틴 휘슬, 피들, 허디거디, 해머 덜시머, 프레임 드럼(보드란)·탬버린 |
| 받쳐 주는 악기 | 현악 패드, 첼로, 오보에 |
| 화성·선법 | 따뜻한 장조 위주. 중세 느낌이 필요한 곳은 도리안·믹솔리디안 선법과 낮은 지속음(드론) |
| 멜로디 | 한 번 들으면 흥얼거릴 수 있는 또렷한 주선율. 메인 테마 멜로디를 길드·감동 장면에서 변주 |
| 전투 | 무거운 오케스트라 대신 **피아노 + 피들·허디거디 + 프레임 드럼과 드럼**의 빠른 포크 퓨전. 보스만 현악과 합창을 얹는다 |
| 피할 것 | EDM, 덥스텝, 트랩, 메탈, 신시사이저, 일렉 기타, 에픽 트레일러풍 오케스트라, 보컬 |
## 2. 1장 체험판 곡 목록

| # | 파일 이름 | 쓰는 곳 | 길이 | 분위기 |
|---|---|---|---|---|
| 1 | bgm_title | 타이틀 | 2~3분 | 메인 테마. 그리움과 설렘, 등불이 다시 켜지는 느낌 |
| 2 | bgm_guild | 길드 화면, 일상 대화 | 2분 반복 | 낡았지만 따뜻한 집. 느긋한 피아노와 류트 |
| 3 | bgm_chronicle | 의뢰 게시판, 연대기 페이지 | 2분 반복 | 길을 나서는 가벼운 발걸음. 플루트 멜로디 |
| 4 | bgm_tension | 위기 장면, 결전 직전 | 1분 반 반복 | 낮은 피아노 반복음과 현악 트레몰로 |
| 5 | bgm_battle | 일반 전투 | 2분 반복 | 빠른 피아노 리프 + 피들·허디거디 + 드럼 |
| 6 | bgm_boss | 붉은 수염 결전 | 2분 반 반복 | 전투곡보다 무겁게, 현악·합창(가사 없는 '아~') |
| 7 | bgm_memory | 호감도 CG, 체험판 끝 | 2~3분 | 피아노 독주로 시작하는 메인 테마 느린 변주 |
| 8 | jingle_win | 전투 승리 | 5~8초 | 밝은 피아노·류트·현악 마무리 |
| 9 | jingle_lose | 전투 패배 | 5~8초 | 내려가는 피아노 화음 |

## 3. Suno 프롬프트

- 모두 **Instrumental** 켜기. 스타일 칸에 아래 영어 문장을 그대로 넣는다 (게임·작곡가 이름은 넣지 않는다).
- 고급 설정 Exclude Styles 에는 공통으로 `vocals, EDM, dubstep, trap, metal, synth, electric guitar, epic trailer` 를 넣는다.
- 한 곡에 여러 번 생성해 보고 마음에 드는 것만 내려받는다 (Pro 는 내려받기 월 20곡).
- 반복 재생용 곡은 끝을 페이드아웃 없이 받는 게 좋다. 반복 구간 자르기는 Claude 가 한다.

| # | 스타일 프롬프트 |
|---|---|
| 1 | `new age, piano-led, medieval fantasy, lute and harp accompaniment, warm strings, tin whistle melody, nostalgic and hopeful, memorable main melody, 2000s Korean online RPG title theme, 88 bpm, major key` |
| 2 | `new age, gentle piano and medieval lute, soft harp, recorder, cozy medieval tavern warmth, relaxed slice of life, 80 bpm, seamless loop` |
| 3 | `new age, bright piano with recorder melody, medieval lute and hammered dulcimer, light frame drum and tambourine, adventurous walking pace, open road, dorian mode, 100 bpm, seamless loop` |
| 4 | `new age, low repeating piano ostinato, hurdy-gurdy drone, cello and string tremolo, soft frame drum, uneasy medieval suspense, minor key, 90 bpm, seamless loop` |
| 5 | `medieval folk fusion, fast piano riff, energetic fiddle and hurdy-gurdy, driving frame drums and drum kit, RPG battle, dorian mode, 150 bpm, seamless loop` |
| 6 | `medieval folk fusion, heavy drums and frame drums, piano, aggressive fiddle and hurdy-gurdy, dramatic strings, wordless choir, intense RPG boss battle, minor key, 160 bpm, seamless loop` |
| 7 | `new age, solo piano intro, slow emotional ballad, harp and soft strings join later, gentle lute, tender and bittersweet, 70 bpm, major key` |
| 8 | `short medieval victory fanfare, bright piano, lute and strings, 6 seconds, ending cadence` |
| 9 | `short defeat jingle, descending soft piano chords with harp, 6 seconds, ending cadence` |

## 4. 게임에 넣기

- 받은 파일은 `audio/raw/` 에 원본 그대로 두고, 게임용은 OGG(96~128kbps)로 바꿔 `godot/audio/` 에 넣는다.
- 반복 곡은 반복 시작·끝 지점을 잡아 끊김 없이 돈다. 장면이 바뀌면 1초 크로스페이드.
- 웹 빌드는 파일 하나 25MiB 제한이 있어 음악은 게임 본체(pck)와 따로 내려받는다.
- 상업 이용은 Suno 유료 요금제로 만든 곡만. 무료 요금제로 만든 곡은 쓰지 않는다.
