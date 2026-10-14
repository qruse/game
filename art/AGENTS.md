# AGENTS.md — 아트 생성 작업 지침 (Codex용)

이 폴더(`art/`)에서는 **게임 일러스트를 이미지 생성 모델로 만든다.** 게임 코드는 다른 에이전트(Claude)가 맡는다. 이 지침은 `art/` 아래 작업에만 적용된다.

## 먼저 읽을 파일

1. `art/style-guide.md`: 프롬프트 조립 규칙, STYLE / FORMAT / NEGATIVE 블록, 배경 제거, QA 체크리스트
2. `art/characters.md`: 캐릭터별 PROMPT 블록과 MUST KEEP(반드시 지킬 외형)
3. `art/manifest.csv`: 만들어야 할 이미지 전체 목록 (한 줄 = 이미지 한 장)

## manifest.csv 열 설명

| 열 | 뜻 |
|---|---|
| `id` | 고유 ID. 파일명과 같다 |
| `phase` | `P0` 스타일 확정 → `P1` 체험판(버티컬 슬라이스) → `P2` 정식 출시. **앞 단계가 끝나기 전에 다음 단계를 시작하지 않는다** |
| `format` | style-guide.md의 FORMAT_BLOCK 키 |
| `subject` | 캐릭터/적/NPC ID (characters.md). `-`는 배경 |
| `extra` | 이 이미지에만 붙이는 추가 지시 |
| `refs` | 첨부할 참조 이미지 경로 (`;`로 구분). **파일이 아직 없으면 그 행은 시작하지 않는다** |
| `output` | 최종 저장 경로 |
| `status` | `todo` → `generated` → `approved` / `rejected` |
| `notes` | 작업 메모 |

## 작업 순서

1. `status=todo`이고, 현재 단계(phase)이며, `refs` 파일이 모두 존재하는 행을 고른다
2. style-guide.md 1절 순서대로 프롬프트를 조립한다
   - `[STYLE_BLOCK] + [FORMAT_BLOCK] + [characters.md의 PROMPT] + [extra] + [NEGATIVE_BLOCK]`
   - `extra`가 `EDIT`로 시작하면 **새로 생성하지 말고** `refs`의 이미지를 편집한다
3. 생성한 원본은 `art/raw/<id>_v<번호>.png`에 저장한다(덮어쓰지 않고 번호를 올린다)
4. style-guide.md 5절대로 배경을 제거하고 최종 크기로 맞춰서 `output` 경로에 저장한다
5. **프롬프트 기록:** `output`과 같은 이름의 `.prompt.txt`를 옆에 저장한다. 내용은 사용 모델명, 생성 날짜, 조립된 전체 프롬프트, 첨부한 참조 이미지 목록이다. Steam의 AI 콘텐츠 공개와 재현에 필요하니 **빠뜨리지 않는다**
6. style-guide.md 6절 QA 체크리스트로 검사한다. 통과하면 `status=generated`로 바꾸고, 실패하면 다시 생성한다(최대 3회, 그래도 안 되면 notes에 이유를 적고 넘어간다)
7. `approved`는 **사람(사용자)만** 바꾼다. Codex는 `approved`나 `rejected`로 바꾸지 않는다

## 반드시 지킬 규칙

- `status=approved`인 파일은 **절대 덮어쓰거나 지우지 않는다**
- 캐릭터 이미지는 그 캐릭터의 `art/refs/<id>_ref.png`가 **approved된 뒤에만** 만든다
- **P0 단계:** 스타일 시안 4장(`P0_style_*`)을 만들고 멈춘다. 사용자가 하나를 고르면 그 파일을 `art/refs/style-anchor.png`로 복사한다. 이것이 정해지기 전에는 다른 어떤 이미지도 만들지 않는다
- 캐릭터 외형을 바꿔야 할 것 같으면 이미지를 고치지 말고 **notes에 적고 사람에게 묻는다**
- 이 목록에 없는 이미지를 임의로 만들지 않는다. 필요해 보이면 manifest에 `status=proposed`로 행을 추가만 한다
- `art/` 밖의 파일(게임 코드, 문서)은 수정하지 않는다. 단, 배경 제거와 크기 조정 같은 후처리 도구가 필요하면 `tools/art/` 아래에 만들어도 된다
- UI 프레임, 상태 아이콘, 주사위, 전투 그리드, 이펙트는 **만들지 않는다** (style-guide.md 7절, Claude 담당)

## 저장소 관리

- `art/raw/`는 git에 올리지 않는다(.gitignore). 승인 전 시안과 재생성 이력이 쌓이는 곳이다
- `art/final/`, `art/refs/`의 PNG와 `.prompt.txt`만 커밋한다
- 커밋 단위: 캐릭터 한 명 또는 배경 묶음 하나씩. 커밋 메시지에 manifest의 id 범위를 적는다

## 진행 보고

작업을 마칠 때마다 아래를 짧게 보고한다.
- 이번에 `generated`로 바꾼 id 목록
- QA에서 3회 실패한 id와 이유
- 다음에 사람이 승인해야 하는 것 (예: `C01_ref` 승인 필요)
