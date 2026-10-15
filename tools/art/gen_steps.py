# WARNING: 작업이 시작된 뒤에는 다시 돌리지 않는다. README 표의 상태와 Codex가 단계 파일에 남긴 기록을 덮어쓴다.
"""Generate art/steps/*.md from art/manifest.csv.

Usage: python tools/art/gen_steps.py
Existing "## 피드백" sections in step files are preserved.
"""
import csv, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MANIFEST = os.path.join(ROOT, "art", "manifest.csv")
OUT_DIR = os.path.join(ROOT, "art", "steps")

COMMON_CHAR_CHECKS = [
    "MUST KEEP 항목(머리, 눈, 의상, 무기, 장신구, 좌우 위치)이 모두 맞다",
    "같은 캐릭터의 이전 승인 이미지와 나란히 놓았을 때 같은 사람으로 보인다",
    "손과 소품 잡는 방식이 자연스럽다",
    "캐릭터 매력이 느껴진다 (성격이 표정과 자세에 드러난다)",
]

# step id -> definition
STEPS = {
 "S01": dict(title="화풍 기준 확정 (리나 수정본)", goal="리나 시안 1을 수정해 게임 전체의 화풍 기준 이미지를 정한다. 일상복 첫 시안도 함께 본다.",
             how=["`art/prompts/C01_lina_revision.md`의 완성 프롬프트를 그대로 쓴다 (1절: 전투복, 2절: 일상복)",
                  "결과는 `art/raw/`에 저장하고 보고한다"],
             checks=["방패를 팔에 끼우고 안쪽 손잡이를 잡았다", "십자가 꽃잎형(크로스 플러리)이고 좌우 대칭이다",
                     "눈이 연보라색이다", "표정에 '정의감 + 살짝 허당'이 보인다",
                     "대화 화면용 구도다 (정면, 무릎 위, 머리 위 여백 작음, 소품 안 잘림)",
                     "일상복이 귀엽고 리나답다 (밀가루 앞치마, 같은 땋은 머리와 리본)",
                     "**이 그림을 게임 전체의 화풍 기준으로 써도 좋은가**"],
             after="승인되면 전투복 수정본을 `art/refs/style-anchor.png`와 `art/final/characters/C01_lina/C01_portrait_combat_neutral.png`로, 일상복을 `C01_portrait_casual_neutral.png`로 복사한다 (manifest의 해당 행도 approved로)."),
 "S02": dict(title="리나 전투복 레퍼런스 시트", goal="리나 전투복의 정면·측면·후면을 고정한다. 이후 리나 전투복 이미지 전부의 기준이 된다.",
             how=["refs: style-anchor.png", "S01에서 승인된 전투복 디자인과 똑같아야 한다"],
             checks=["정면·측면·후면이 같은 디자인이다", "뒷모습(머리 길이, 서코트 뒷면, 방패 뒷면)이 그럴듯하다",
                     "S01 승인 이미지와 디자인이 같다"]),
 "S03": dict(title="파이프라인 시험 (리나 4장)", goal="대량 생성 전에 '표정 편집'과 'SD 변환'이 우리 규칙대로 되는지 리나로 시험한다.",
             how=["`C01_portrait_combat_neutral`은 S01 승인본을 복사한 것이다. **새로 만들지 않는다**",
                  "`C01_portrait_combat_smile`은 기본 스탠딩의 **얼굴만 마스크 편집** (style-guide 3.1절)",
                  "SD 2장은 레퍼런스 시트를 참조해 만들고 배경을 제거한다 (style-guide 6절)",
                  "끝나면 Claude가 **대화 화면·전투 화면 목업**에 얹어 확인한다"],
             checks=["웃음 표정으로 바꿨을 때 얼굴 밖(머리, 옷, 배경)이 그대로다 (겹쳐 보면 흔들림 없음)",
                     "SD가 2.5등신이고 리나로 알아볼 수 있다", "SD 배경 제거가 깨끗하다",
                     "대화 목업에서 얼굴이 대사창에 가리지 않는다", "전투 목업에서 SD 크기와 방향이 맞다"],
             after="여기서 나온 문제는 style-guide.md에 반영한 뒤 다음 단계로 간다."),
 "S04": dict(title="리나 전투복 세트 완성", goal="리나 전투복의 나머지 표정, SD 동작, 궁극기 컷인, 스킬 아이콘을 만든다.",
             how=["표정 4종은 모두 기본 스탠딩의 얼굴 마스크 편집", "SD는 S03 승인본과 같은 크기·기준선"],
             checks=COMMON_CHAR_CHECKS + ["표정 6종이 서로 확실히 구분된다", "SD 5동작이 전투에서 읽기 쉽다",
                                          "컷인이 박력 있다", "아이콘 3개가 작게 줄여도 무엇인지 보인다"]),
 "S05": dict(title="리나 일상복 세트", goal="리나 일상복 레퍼런스 시트와 일상복 표정 6종을 만든다.",
             how=["`C01_portrait_casual_neutral`은 S01 승인본을 복사한 것이다. **새로 만들지 않는다**",
                  "먼저 `C01_ref_casual`을 S01 일상복 승인본과 같은 디자인으로 만들고 **멈춰서 확인받는다** (중간 확인)",
                  "승인되면 표정 5종을 얼굴 마스크 편집으로 만든다"],
             checks=COMMON_CHAR_CHECKS + ["일상복이 컨셉(요리 실패 앞치마)에 맞게 예쁘다", "노출 등급(낮음)을 지킨다"]),
 "S06": dict(title="배경 시점 시험", goal="대화 배경 1장과 전투 맵 1장으로 배경 화풍과 전투 맵 시점을 확인한다.",
             how=["전투 맵은 '위에서 비스듬히 내려다보는 시점' (style-guide bg_battle)", "끝나면 Claude가 전투 목업에 SD와 함께 얹어 확인한다"],
             checks=["대화 배경 가운데가 비어 있어 스탠딩을 세울 수 있다", "전투 맵 가운데 70%가 평평하고 걸을 수 있다",
                     "리나 SD를 올렸을 때 바닥에 서 있는 것처럼 보인다", "중세 분위기가 짙다"]),
 "S13": dict(title="과거 길드원 레퍼런스", goal="회상 파티 3명의 레퍼런스 시트와 모르칸트의 기본 스탠딩을 만든다.",
             how=["알도(P02)는 리나 레퍼런스도 첨부해 **리나와 닮게**", "공통: 파란 서코트/망토의 은빛 등불 문장"],
             checks=["알도가 리나의 아버지로 보인다 (머리색, 눈색, 인상)", "젊은 고드릭이 현재 고드릭의 젊은 시절로 보인다 (안대 없음)",
                     "모르칸트가 겉으로는 친근하지만 어딘가 불안하다", "은빛 등불 문장이 네 명 모두 같은 모양이다"]),
 "S14": dict(title="과거 길드원 세트", goal="과거 길드원 스탠딩 표정과 회상 파티 SD를 만든다.",
             how=["표정은 3종(기본, 긍정, 부정)만", "SD는 회상 파티 3명만"], checks=COMMON_CHAR_CHECKS),
 "S15": dict(title="1장 적과 보스", goal="1장 일반 적 5종과 보스 붉은 수염의 SD를 만든다.",
             how=["적마다 대기(idle)를 먼저 만들고, 공격·피격은 대기 이미지를 참조해 만든다", "적은 왼쪽을 본다"],
             checks=["적 종류가 실루엣만으로 구분된다", "동료 SD와 크기 비율이 맞다", "보스가 확실히 위압적이다"]),
 "S16": dict(title="1장 배경 나머지", goal="1장 체험판에 필요한 나머지 대화 배경, 전투 맵, 지역 지도, 회상용 배경을 만든다.",
             how=["S06에서 승인된 배경 화풍을 따른다"],
             checks=["모든 배경이 같은 화풍이다", "전투 맵 가장자리의 지형 요소(기름 건초, 절벽 등)가 extra 설명과 맞다",
                     "지역 지도에 의뢰 핀을 꽂을 빈자리가 있다", "전성기 길드 하우스와 폐허 길드 하우스가 같은 건물로 보인다"]),
 "S17": dict(title="1장 NPC", goal="체험판에 나오는 NPC 스탠딩을 만든다.", how=["주요 NPC는 표정 3종, 마을 사람은 1종"],
             checks=["동료보다 눈에 덜 띄지만 개성은 있다", "중세 복식이 맞다"]),
 "S18": dict(title="체험판 CG", goal="1장 오프닝 CG와 체험판 동료 4명의 호감도 CG를 만든다.",
             how=["호감도 CG는 일상복 레퍼런스를 참조", "연애는 암시 정도, 노골적 묘사 금지"],
             checks=["오프닝 CG가 게임의 첫인상으로 충분히 강하다", "호감도 CG가 설레지만 선을 넘지 않는다",
                     "CG 속 캐릭터가 스탠딩과 같은 사람이다"]),
 "S27": dict(title="2장 적과 보스", goal="2장(수도원·지하묘지) 적 5종과 보스 타락한 수도원장.", how=["S15와 같은 방식"],
             checks=["1장 적들과 화풍·크기가 맞다", "언데드와 사교도가 서로 구분된다"]),
 "S28": dict(title="3장 적과 보스", goal="3장(도시·성) 적 5종과 보스 흑기사.", how=["흑기사는 모르칸트(P04)의 미래 모습이다. P04 스탠딩을 참조"],
             checks=["흑기사의 방패에 긁혀 지워진 은빛 등불 문장이 보인다", "도시 적들이 1·2장 적과 구분된다"]),
 "S29": dict(title="배경 나머지 (정식 출시)", goal="길드 하우스 복구 단계, 봉인된 방 나머지, 2·3장 배경과 전투 맵.", how=["S06·S16 화풍을 따른다"],
             checks=["길드 하우스 단계별 변화가 한눈에 보인다", "봉인된 방마다 분위기가 다르다"]),
 "S30": dict(title="NPC 나머지", goal="2·3장 NPC와 가면의 남자.", how=["S17과 같은 방식"], checks=["영주와 주교가 권력자로 보인다"]),
 "S31": dict(title="CG 나머지", goal="2·3장 핵심 장면, 엔딩, 나머지 동료 호감도 CG, 유료 동료 퀘스트 엔딩.", how=["S18과 같은 방식"],
             checks=["엔딩 CG에 모든 동료가 자연스럽게 모여 있다"]),
 "S32": dict(title="마케팅 일러스트", goal="키 비주얼과 유료 동료 팩 홍보 일러스트.", how=["로고·제목은 넣지 않는다 (나중에 합성)"],
             checks=["작게 줄여도(Steam 캡슐 크기) 눈에 띈다", "위쪽이나 한쪽에 로고 자리가 있다"]),
}

CHAR_NAMES = {"C02": "세실", "C03": "아델하이트", "C04": "미리엄", "C05": "로웬", "C06": "고드릭", "C07": "이졸데", "C08": "카샤"}
EXPOSURE = {"C02": "중간", "C03": "낮음", "C04": "높음", "C05": "높음", "C06": "없음", "C07": "높음", "C08": "중간"}
pairs = [("S07", "S08", "C02"), ("S09", "S10", "C03"), ("S11", "S12", "C04"), ("S19", "S20", "C05"),
         ("S21", "S22", "C06"), ("S23", "S24", "C07"), ("S25", "S26", "C08")]
for ref_s, set_s, cid in pairs:
    n = CHAR_NAMES[cid]
    STEPS[ref_s] = dict(title=f"{n} 레퍼런스 시트 (전투복·일상복)", goal=f"{n}의 전투복과 일상복 레퍼런스 시트를 만든다. 이후 {n} 이미지 전부의 기준이 된다.",
                        how=["전투복 시트를 먼저 만들고, 일상복 시트는 전투복 시트를 참조해 같은 얼굴·체형으로 만든다"],
                        checks=["characters.md의 MUST KEEP이 모두 맞다", "정면·측면·후면이 같은 디자인이다",
                                "전투복과 일상복의 얼굴·체형이 같은 사람이다", f"일상복 노출이 등급({EXPOSURE[cid]})에 맞다",
                                "다른 동료들과 나란히 놓았을 때 실루엣과 색이 겹치지 않는다"])
    STEPS[set_s] = dict(title=f"{n} 세트", goal=f"{n}의 스탠딩(전투복·일상복 × 표정 6), SD 5동작, 컷인, 아이콘을 만든다.",
                        how=["**중간 확인:** 먼저 `portrait_combat_neutral`과 `sd_idle` 2장만 만들고 멈춰서 확인받는다",
                             "승인되면 나머지를 만든다. 표정은 모두 기본 스탠딩의 얼굴 마스크 편집"],
                        checks=COMMON_CHAR_CHECKS + [f"일상복 노출이 등급({EXPOSURE[cid]})을 넘지 않는다", "표정 6종이 서로 확실히 구분된다"])

PHASE_OF = {}
rows = list(csv.DictReader(open(MANIFEST, encoding="utf-8")))
by_step = {}
for r in rows:
    by_step.setdefault(r["step"], []).append(r)

def existing_feedback(path):
    if not os.path.exists(path):
        return None
    txt = open(path, encoding="utf-8").read()
    m = re.search(r"\n## 피드백\n(.*)\Z", txt, re.S)
    return m.group(1) if m else None

os.makedirs(OUT_DIR, exist_ok=True)
order = sorted(by_step.keys())
for idx, s in enumerate(order):
    d = STEPS[s]
    items = by_step[s]
    prev = order[idx - 1] if idx > 0 else None
    nxt = order[idx + 1] if idx + 1 < len(order) else None
    phase = items[0]["phase"]
    lines = [f"# {s} · {d['title']}", "",
             f"> 단계: {phase} · 담당: Codex · 이미지 {len(items)}장",
             f"> 시작 조건: {'없음 (첫 단계)' if not prev else f'{prev} 승인 완료'} · 다음 단계: {nxt or '없음'}",
             "", "## 목표", "", d["goal"], "",
             "## 만들 것", "", "| id | 내용 | 형식 | 의상 | 저장 위치 |", "|---|---|---|---|---|"]
    for r in items:
        lines.append(f"| `{r['id']}` | {r['name_ko']} | {r['format']} | {r['outfit']} | `{r['output']}` |")
    lines += ["", "## 진행 방법", "",
              "1. `art/AGENTS.md`의 작업 순서와 규칙을 따른다",
              "2. 아래 **피드백** 칸을 먼저 읽는다. 재작업이면 피드백을 반드시 반영한다"]
    for i, h in enumerate(d["how"], start=3):
        lines.append(f"{i}. {h}")
    lines += ["", "## 멈춤 조건", "",
              "- 위 목록(또는 '중간 확인' 지점)까지 만들면 **멈추고 보고한다**",
              f"- 사용자가 이 단계를 승인하기 전에는 **{nxt or '다음 작업'}로 넘어가지 않는다**", "",
              "## 보고 형식", "",
              "```", f"[{s} 보고]", "만든 것: (id 목록과 파일 경로)", "재시도한 것: (id, 횟수, 이유)",
              "스스로 본 문제: (QA에서 애매했던 점)", "확인 요청: (사용자가 꼭 봐 줬으면 하는 점)", "```", "",
              "## 사용자 확인 포인트", ""]
    lines += [f"- [ ] {c}" for c in d["checks"]]
    if d.get("after"):
        lines += ["", "## 승인 후 처리", "", d["after"]]
    fb = existing_feedback(os.path.join(OUT_DIR, f"{s}.md"))
    lines += ["", "## 피드백", ""]
    lines.append(fb.rstrip("\n") if fb and fb.strip() else
                 "> 사용자 피드백을 여기에 날짜와 함께 적는다. 이미지별 피드백은 id를 적는다.\n"
                 "> 예: `2026-10-16 · C01_sd_idle: 칼을 더 크게, 표정은 더 자신만만하게`\n\n(아직 없음)")
    open(os.path.join(OUT_DIR, f"{s}.md"), "w", encoding="utf-8").write("\n".join(lines) + "\n")

# overview
ov = ["# 일러스트 작업 단계", "",
      "Codex는 **한 번에 한 단계만** 진행하고, 끝나면 멈춰서 보고한다. 사용자가 확인하고 피드백을 주면 반영하거나 다음 단계로 넘어간다.", "",
      "## 사용 방법", "",
      "1. Codex에게: `art/steps/S01.md 진행해`",
      "2. Codex가 만들고 멈춰서 보고한다",
      "3. 이미지를 확인하고, 각 단계 파일의 **사용자 확인 포인트**를 체크한다",
      "4. 고칠 게 있으면 → 단계 파일의 **피드백** 칸에 적고(또는 Claude에게 말하면 Claude가 적는다) Codex에게: `S01 피드백 반영해서 다시 해`",
      "5. 괜찮으면 → Codex에게: `S01 승인. 승인 후 처리하고 S02 진행해`", "",
      "> 진행 상태는 아래 표의 '상태' 칸에 적는다: `대기` → `진행 중` → `검토 대기` → `승인`", "",
      "## 사전 작업 (Claude)", "",
      "| 작업 | 쓰이는 단계 | 상태 |", "|---|---|---|",
      "| 은빛 등불 길드 문장 SVG (`art/refs/emblem-lantern.png`) | S13 전, 문장이 나오는 모든 이미지 | 대기 |",
      "| 대화 화면 목업 | S03 확인 | 대기 |",
      "| 전투 화면 목업 | S03, S06 확인 | 대기 |", "",
      "## 단계 목록", "",
      "| 단계 | 내용 | 장수 | 단계 구분 | 상태 |", "|---|---|---|---|---|"]
for s in order:
    items = by_step[s]
    ov.append(f"| [{s}]({s}.md) | {STEPS[s]['title']} | {len(items)} | {items[0]['phase']} | 대기 |")
ov += ["", f"총 {len(rows)}장 · P1(체험판)은 S01~S18, P2(정식 출시)는 S19~S32", "",
       "## 중요한 확인 지점", "",
       "- **S01:** 게임 전체 화풍이 여기서 정해진다",
       "- **S03:** 표정 편집과 SD 변환이 규칙대로 되는지. 여기서 문제를 잡으면 나머지 300장이 안전하다",
       "- **S06:** 전투 맵 시점. SD가 맵 위에 자연스럽게 서는지",
       "- **각 동료의 레퍼런스 단계:** 이후 20장의 기준이 된다. 여기서 충분히 고친다"]
open(os.path.join(OUT_DIR, "README.md"), "w", encoding="utf-8").write("\n".join(ov) + "\n")
print("steps:", len(order))
