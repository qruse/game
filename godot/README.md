# 전투 프로토타입 (Godot 4.7)

**지금 기본은 판정 칸 전투(포 더 킹식, docs/05-combat.md 0절)**다. 메뉴의 "이전 방식"을 누르면 예전 칸 이동 전투(1~17절)도 할 수 있다.

- 판정 칸 전투 바로 시작: `godot --path godot -- --battle=0` (0 숲속 공터, 1 무너진 길드 회관), 자동 진행 `--demo`, 첫 행동 미리 고르기 `--pick=cecile_ambush,0`
- 자동 시뮬레이션: `godot --headless --path godot -s res://scripts/fk_sim.gd`
- 파일: `fk_defs.gd`(수치·환경·전투 장면), `fk_battle.gd`(규칙·AI), `fk_stage.gd`(무대 그리기·연출), `fk_main.gd`(화면·흐름)

## 이전 방식: 칸 이동 전투

네모 박스로 만든 전투 시험판이다. 규칙과 수치는 [docs/05-combat.md](../docs/05-combat.md)를 따른다.

## 실행

- Godot 4.7에서 이 폴더(`godot/`)를 열고 F5
- 명령줄: `godot --path godot`
- 바로 맵 시작: `godot --path godot -- --map=3 --party=lina,cecile,adelheid`
- 자동 시뮬레이션 (화면 없음): `godot --headless --path godot -s res://scripts/sim.gd`

## 웹 / 모바일 (Cloudflare)

- 주소: https://project-d20.coolwin200.workers.dev (휴대폰은 가로로 돌려서)
- 다시 올리기 (저장소 루트에서):
  1. `powershell -ExecutionPolicy Bypass -File tools/web/build_web.ps1` : 그림·글꼴 복사, 웹 내보내기, 20MB 넘는 파일 gzip
  2. `cd tools/web/cloudflare; npx wrangler deploy` (Node 포터블: %LOCALAPPDATA%\\node-portable)
- 작은 화면이나 터치 기기는 960×540 기준 배치(글자·버튼 크게, 기록창 좁게)를 쓴다

## 들어 있는 것

- 맵 4개 (5×4 매복, 7×5 공터, 9×5 마을 외곽, 8×6 보스 절벽). `maps/*.txt` 텍스트 형식 (전투 규칙서 7.4절)
- 동료 4명 (리나, 세실, 아델하이트, 미리엄) 중 3명 선택. 기본 공격, 스킬 2개, 궁극기, 이동 특성
- 적 3종 + 보스 붉은 수염 (휩쓸기, 2페이즈 분노 + 증원)
- d20 명중, 유리/불리(높은 곳, 협공, 엄폐, 덤불, 연기, 은신), 저항 판정, 빈틈 공격, 밀치기와 낭떠러지
- 환경: 기름, 덤불, 기름 항아리 폭발, 건초 더미, 화염 지대, 물, 연기
- 행운 주사위 (옛 운명 주사위): 굴림 대신 놓기, 적에게 낙인 찍기, 대실패면 추가
- 전설 장면(소문 힌트)과 라운드 사건(증원), 이동 되돌리기, 2배속
- 그림: \rt/final\에 있으면 자동으로 쓴다. 동료 SD 5동작(대기, 공격, 스킬, 피격, 쓰러짐), 궁극기 컷인, 스킬 아이콘, 전투 배경. 없으면 동그라미

## 파일

| 파일 | 내용 |
|---|---|
| `scripts/defs.gd` | 동료·적·스킬 수치 |
| `scripts/battle.gd` | 전투 규칙과 AI (화면과 분리) |
| `scripts/board.gd` | 칸 그리기, 입력 |
| `scripts/main.gd` | 메뉴, 버튼, 흐름 |
| `scripts/sim.gd` | 헤드리스 자동 전투로 라운드 수 측정 |
