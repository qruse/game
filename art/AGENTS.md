# AGENTS.md — 아트 생성 작업 지침 (Codex용)

이 폴더(`art/`)에서는 **게임 일러스트를 이미지 생성 모델로 만든다.** 게임 코드는 다른 에이전트(Claude)가 맡는다. 이 지침은 `art/` 아래 작업에만 적용된다.

## 단계별로만 일한다 (가장 중요)

- 작업은 `art/steps/` 의 단계 파일(S01~S32) 단위로 한다. 사용자가 "S01 진행해"처럼 **지정한 단계만** 한다
- 단계 파일의 목록을 다 만들거나 **중간 확인** 지점에 오면 멈추고, 단계 파일의 보고 형식대로 보고한다
- 사용자가 승인하기 전에는 다음 단계로 넘어가지 않는다
- 재작업 요청을 받으면 단계 파일 맨 아래 **피드백** 칸을 먼저 읽고 반영한다. 사용자가 채팅으로만 피드백을 주면, 그 내용을 날짜와 함께 피드백 칸에 먼저 적고 시작한다
- 사용자가 "승인"이라고 하면 그 단계 이미지들의 manifest `status`를 `approved`로 바꾸고, 단계 파일의 **승인 후 처리**를 하고, `art/steps/README.md` 표의 상태를 `승인`으로 바꾼다
- 진행을 시작하면 `art/steps/README.md` 표의 상태를 `진행 중`, 보고할 때 `검토 대기`로 바꾼다

## 먼저 읽을 파일

1. `art/style-guide.md`: 프롬프트 조립 규칙, STYLE / FORMAT / NEGATIVE 블록, 배경 제거, QA 체크리스트
2. `art/characters.md`: 캐릭터별 BODY / COMBAT / CASUAL 블록과 MUST KEEP(반드시 지킬 외형). 과거 길드원(P01~P04)은 PROMPT 블록 하나
3. `art/manifest.csv`: 만들어야 할 이미지 전체 목록 (한 줄 = 이미지 한 장)

## manifest.csv 열 설명

| 열 | 뜻 |
|---|---|
| `id` | 고유 ID. 파일명과 같다 |
| `phase` | `P0` 스타일 확정 → `P1` 체험판(버티컬 슬라이스) → `P2` 정식 출시. **앞 단계가 끝나기 전에 다음 단계를 시작하지 않는다** |
| `format` | style-guide.md의 FORMAT_BLOCK 키 |
| `subject` | 캐릭터/적/NPC ID (characters.md). `-`는 배경 |
| `outfit` | `combat`(전투복) / `casual`(일상복) / `-`(구분 없음). characters.md에서 어느 의상 블록을 쓸지 정한다 |
| `extra` | 이 이미지에만 붙이는 추가 지시 |
| `refs` | 첨부할 참조 이미지 경로 (`;`로 구분). **파일이 아직 없으면 그 행은 시작하지 않는다** |
| `output` | 최종 저장 경로 |
| `status` | `todo` → `generated` → `approved` / `rejected` |
| `notes` | 작업 메모 |

## 작업 순서

1. `status=todo`이고, 현재 단계(phase)이며, `refs` 파일이 모두 존재하는 행을 고른다
2. style-guide.md 1절 순서대로 프롬프트를 조립한다
   - `[STYLE_BLOCK] + [FORMAT_BLOCK] + [BODY] + [COMBAT 또는 CASUAL] + [extra] + [NEGATIVE_BLOCK]`
   - `extra`가 `EDIT`로 시작하면 **새로 생성하지 말고** `refs`의 이미지를 **얼굴 영역만 마스크로** 편집한다 (style-guide.md 3.1절)
   - `extra`가 `art/prompts/...` 파일을 가리키면 그 파일의 완성된 프롬프트를 그대로 쓴다
3. 생성한 원본은 `art/raw/<id>_v<번호>.png`에 저장한다(덮어쓰지 않고 번호를 올린다)
4. style-guide.md 6절대로 배경을 제거하고 최종 크기로 맞춰서 `output` 경로에 저장한다
5. **프롬프트 기록:** `output`과 같은 이름의 `.prompt.txt`를 옆에 저장한다. 내용은 사용 모델명, 생성 날짜, 조립된 전체 프롬프트, 첨부한 참조 이미지 목록이다. Steam의 AI 콘텐츠 공개와 재현에 필요하니 **빠뜨리지 않는다**
6. style-guide.md 7절 QA 체크리스트로 검사한다. 통과하면 `status=generated`로 바꾸고, 실패하면 다시 생성한다(최대 3회, 그래도 안 되면 notes에 이유를 적고 넘어간다)
7. `approved` / `rejected`는 **사용자가 그렇게 말했을 때만** 바꾼다. Codex가 스스로 판단해서 바꾸지 않는다

## 반드시 지킬 규칙

- `status=approved`인 파일은 **절대 덮어쓰거나 지우지 않는다**
- 캐릭터 이미지는 그 의상의 레퍼런스 시트 `art/refs/<id>_ref_<outfit>.png`가 **approved된 뒤에만** 만든다 (과거 길드원 P01~P03은 의상이 1벌이라 `art/refs/<id>_ref.png`)
- **P0 단계:** 리나 수정본 2장(`P0_lina_*`, 프롬프트는 `art/prompts/C01_lina_revision.md`)을 만들고 멈춘다. 사용자가 전투복 수정본을 승인하면 `art/refs/style-anchor.png`로 복사한다. 이것이 정해지기 전에는 다른 어떤 이미지도 만들지 않는다
- 스탠딩 일러스트는 **대화 화면에 그대로 쓰인다.** style-guide.md 4절(정면 자세, 좌우 반전 금지, 무릎 위 구도, 표정 차분 정렬)을 반드시 지킨다
- 노출은 characters.md의 캐릭터별 등급을 넘지 않는다. 등급이 "중간" 이상이면 프롬프트에 `adult woman`이 들어 있어야 한다
- 캐릭터 외형을 바꿔야 할 것 같으면 이미지를 고치지 말고 **notes에 적고 사람에게 묻는다**
- 이 목록에 없는 이미지를 임의로 만들지 않는다. 필요해 보이면 manifest에 `status=proposed`로 행을 추가만 한다
- `art/` 밖의 파일(게임 코드, 문서)은 수정하지 않는다. 단, 배경 제거와 크기 조정 같은 후처리 도구가 필요하면 `tools/art/` 아래에 만들어도 된다
- UI 프레임, 상태 아이콘, 주사위, 전투 그리드, 이펙트는 **만들지 않는다** (style-guide.md 8절, Claude 담당)

## 저장소 관리

- `art/raw/`는 git에 올리지 않는다(.gitignore). 승인 전 시안과 재생성 이력이 쌓이는 곳이다
- `art/final/`, `art/refs/`의 PNG와 `.prompt.txt`만 커밋한다
- 커밋 단위: 캐릭터 한 명 또는 배경 묶음 하나씩. 커밋 메시지에 manifest의 id 범위를 적는다

## 진행 보고

작업을 마칠 때마다 아래를 짧게 보고한다.
- 이번에 `generated`로 바꾼 id 목록
- QA에서 3회 실패한 id와 이유
- 다음에 사람이 승인해야 하는 것 (예: `C01_ref_combat` 승인 필요)
