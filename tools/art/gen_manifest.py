import csv, sys
from collections import Counter

out_path = sys.argv[1]
rows = []
ANCHOR = "art/refs/style-anchor.png"

def add(id, phase, fmt, subject, name_ko, extra, refs, output, notes="", outfit="-"):
    rows.append(dict(id=id, phase=phase, format=fmt, subject=subject, outfit=outfit, name_ko=name_ko,
                     extra=extra, refs=";".join(refs), output=output, status="todo", notes=notes))

# P0: Lina revision -> style anchor
V1 = "art/samples/codex-lina-v1.png"
add("P0_lina_combat_v2", "P0", "portrait", "C01", "리나 전투복 수정본 (화풍 기준 후보)",
    "Use art/prompts/C01_lina_revision.md section 1 exactly.", [V1],
    "art/raw/C01_portrait_combat_neutral_v2.png",
    "승인되면 art/refs/style-anchor.png 와 C01_portrait_combat_neutral 로 복사", outfit="combat")
add("P0_lina_casual_v1", "P0", "portrait", "C01", "리나 일상복 시안",
    "Use art/prompts/C01_lina_revision.md section 2 exactly.", [V1],
    "art/raw/C01_portrait_casual_neutral_v1.png",
    "승인되면 C01_portrait_casual_neutral 로 복사", outfit="casual")

chars = {
 "C01": ("lina", "리나", "raising her shield and sword as a golden aura of a knightly oath bursts around her",
         [("skill1", "a heater shield slamming forward with impact sparks"),
          ("skill2", "a raised shield radiating a provoking red glow"),
          ("ult", "a golden sword and shield crossed under a radiant oath sigil")]),
 "C02": ("cecile", "세실", "a blur of twin daggers striking out of the shadows",
         [("skill1", "a dagger striking from deep shadow"),
          ("skill2", "a smoke bomb bursting into grey smoke"),
          ("ult", "twin crossed daggers with motion trails")]),
 "C03": ("adelheid", "아델하이트", "the chained grimoire flying open and unleashing a storm of glowing runes",
         [("skill1", "a fiery bolt bursting from a glowing rune"),
          ("skill2", "chains of frost coiling"),
          ("ult", "an open chained grimoire blazing with runes")]),
 "C04": ("miriam", "미리엄", "praying as a pillar of warm holy light descends around her",
         [("skill1", "an open hand glowing with warm healing light"),
          ("skill2", "a scallop shell radiating soft light"),
          ("ult", "a pillar of holy light from the sky")]),
 "C05": ("rowen", "로웬", "playing the lute as enchanted musical notes swirl around her like ribbons",
         [("skill1", "a lute with rising golden notes"),
          ("skill2", "a crescent moon with drifting sleepy notes"),
          ("ult", "swirling enchanted ribbons of music")]),
 "C06": ("godric", "고드릭", "aiming the heavy crossbow with his one eye, a bolt glowing with silver light",
         [("skill1", "a crossbow bolt piercing through armor"),
          ("skill2", "a rope snare trap on the ground"),
          ("ult", "a silver-glowing crossbow bolt in flight")]),
 "C07": ("isolde", "이졸데", "a lightning-fast rapier thrust leaving a crimson trail of rose petals",
         [("skill1", "a rapier parry with bright sparks"),
          ("skill2", "a thrown white dueling glove"),
          ("ult", "a crimson rose pierced by a rapier")]),
 "C08": ("kasha", "카샤", "drawing her longbow beside her leaping grey wolf under the moonlight",
         [("skill1", "an arrow nocked on a drawn longbow"),
          ("skill2", "a grey wolf leaping to pounce"),
          ("ult", "an arrow flying across a full moon")]),
}
p1_chars = {"C01", "C02", "C03", "C04"}
expressions = [("smile", "warm happy smile"), ("angry", "angry, frowning, gritted teeth"),
               ("sad", "sad, teary eyes"), ("surprised", "surprised, wide eyes, open mouth"),
               ("embarrassed", "embarrassed, blushing, looking away")]
sd_poses = [("idle", "relaxed ready combat stance"),
            ("attack", "dynamic attack pose using their main weapon"),
            ("skill", "performing a signature skill pose"),
            ("hit", "recoiling from being hit, wincing"),
            ("down", "knocked down, kneeling exhausted")]

outfit_ko = {"combat": "전투복", "casual": "일상복"}
for cid, (slug, ko, ult, icons) in chars.items():
    ph = "P1" if cid in p1_chars else "P2"
    base = f"art/final/characters/{cid}_{slug}"
    for of in ["combat", "casual"]:
        ref = f"art/refs/{cid}_ref_{of}.png"
        add(f"{cid}_ref_{of}", ph, "ref_sheet", cid, f"{ko} 레퍼런스 시트 ({outfit_ko[of]})", "",
            [ANCHOR] + ([] if of == "combat" else [f"art/refs/{cid}_ref_combat.png"]), ref,
            "승인 후 이 의상의 모든 이미지에 참조로 첨부", outfit=of)
        neutral = f"{base}/{cid}_portrait_{of}_neutral.png"
        add(f"{cid}_portrait_{of}_neutral", ph, "portrait", cid, f"{ko} 스탠딩 {outfit_ko[of]} 기본",
            "Neutral calm expression that still shows the character's personality.", [ANCHOR, ref], neutral,
            outfit=of)
        for e, d in expressions:
            add(f"{cid}_portrait_{of}_{e}", ph, "portrait", cid, f"{ko} 스탠딩 {outfit_ko[of]} {e}",
                f"EDIT (face mask only, see style-guide 3.1): change only the facial expression to: {d}.",
                [neutral], f"{base}/{cid}_portrait_{of}_{e}.png", "얼굴 영역만 편집. 얼굴 밖은 neutral과 동일해야 함",
                outfit=of)
    ref = f"art/refs/{cid}_ref_combat.png"
    for p, d in sd_poses:
        add(f"{cid}_sd_{p}", ph, "sd", cid, f"{ko} SD {p}", f"Pose: {d}.", [ANCHOR, ref],
            f"{base}/{cid}_sd_{p}.png", outfit="combat")
    add(f"{cid}_cutin", ph, "cutin", cid, f"{ko} 궁극기 컷인", f"Ultimate: {ult}.", [ANCHOR, ref],
        f"{base}/{cid}_cutin.png", outfit="combat")
    for k, d in icons:
        add(f"{cid}_icon_{k}", ph, "icon", cid, f"{ko} 아이콘 {k}", f"Subject: {d}.", [ANCHOR],
            f"art/final/icons/skills/{cid}_icon_{k}.png")

npcs = [("N01", "martha", "마르타", "P1", 3), ("N02", "basil", "바실", "P1", 3),
        ("N03", "oswald", "오스왈드", "P2", 3), ("N04", "eleanor", "엘리노어", "P2", 3),
        ("N06", "masked", "가면의 남자", "P2", 1),
        ("N07", "villager_m", "마을 사람(남)", "P1", 1), ("N08", "villager_f", "마을 사람(여)", "P1", 1),
        ("N11", "tobias", "촌장 토비아스", "P1", 3), ("N12", "greta", "대장장이 그레타", "P1", 1),
        ("N13", "pip", "잡화점 주인 핍", "P1", 1)]
for nid, slug, ko, ph, n in npcs:
    base = f"art/final/npcs/{nid}_{slug}"
    neutral = f"{base}/{nid}_portrait_neutral.png"
    add(f"{nid}_portrait_neutral", ph, "portrait", nid, f"{ko} 스탠딩 기본", "Neutral expression.",
        [ANCHOR], neutral)
    if n == 3:
        for e, d in [("positive", "friendly smile"), ("negative", "displeased frown")]:
            add(f"{nid}_portrait_{e}", ph, "portrait", nid, f"{ko} 스탠딩 {e}",
                f"EDIT (face mask only, see style-guide 3.1): change only the facial expression to: {d}.",
                [neutral], f"{base}/{nid}_portrait_{e}.png", "얼굴 영역만 편집")

# past guild (flashbacks): P01-P03 playable, P04 NPC
past = [("P01", "edric", "에드릭", True), ("P02", "aldo", "기사 알도", True),
        ("P03", "young_godric", "젊은 고드릭", True), ("P04", "morcant", "모르칸트", False)]
for pid, slug, ko, playable in past:
    base = f"art/final/past/{pid}_{slug}"
    ref = f"art/refs/{pid}_ref.png"
    refs = [ANCHOR]
    if playable:
        add(f"{pid}_ref", "P1", "ref_sheet", pid, f"{ko} 레퍼런스 시트", "", [ANCHOR], ref,
            "승인 후 이 인물의 모든 이미지에 참조로 첨부")
        refs = [ANCHOR, ref]
    if pid == "P02":
        refs = refs + ["art/refs/C01_ref_combat.png"]
    neutral = f"{base}/{pid}_portrait_neutral.png"
    add(f"{pid}_portrait_neutral", "P1", "portrait", pid, f"{ko} 스탠딩 기본", "Neutral expression.",
        refs, neutral, "P02는 리나와 닮게(리나 레퍼런스 첨부)" if pid == "P02" else "")
    for e, d in [("positive", "warm smile"), ("negative", "grim, troubled")]:
        add(f"{pid}_portrait_{e}", "P1", "portrait", pid, f"{ko} 스탠딩 {e}",
            f"EDIT (face mask only, see style-guide 3.1): change only the facial expression to: {d}.",
            [neutral], f"{base}/{pid}_portrait_{e}.png", "얼굴 영역만 편집")
    if playable:
        for p, d in sd_poses:
            add(f"{pid}_sd_{p}", "P1", "sd", pid, f"{ko} SD {p}", f"Pose: {d}.", [ANCHOR, ref],
                f"{base}/{pid}_sd_{p}.png")

enemies = [("E01", "1"), ("E02", "1"), ("E03", "1"), ("E04", "1"), ("E05", "1"),
           ("E06", "2"), ("E07", "2"), ("E08", "2"), ("E09", "2"), ("E10", "2"),
           ("E11", "3"), ("E12", "3"), ("E13", "3"), ("E14", "3"), ("E15", "3")]
for eid, ch in enemies:
    ph = "P1" if ch == "1" else "P2"
    for p, d in [("idle", "menacing ready stance"), ("attack", "attacking"), ("hit", "recoiling from a hit")]:
        add(f"{eid}_sd_{p}", ph, "enemy_sd", eid, f"적 {eid} {p}", f"Pose: {d}.",
            [ANCHOR] + ([] if p == "idle" else [f"art/final/enemies/{eid}/{eid}_sd_idle.png"]),
            f"art/final/enemies/{eid}/{eid}_sd_{p}.png")
for bid, ch in [("B01", "1"), ("B02", "2"), ("B03", "3")]:
    ph = "P1" if ch == "1" else "P2"
    for p, d in sd_poses:
        add(f"{bid}_sd_{p}", ph, "enemy_sd", bid, f"보스 {bid} {p}", f"Boss, larger and more imposing. Pose: {d}.",
            [ANCHOR] + ([] if p == "idle" else [f"art/final/enemies/{bid}/{bid}_sd_idle.png"]),
            f"art/final/enemies/{bid}/{bid}_sd_{p}.png")

scenes = [
 ("bg_guildhall_ruined", "P1", "길드 하우스 (폐허)", "GUILDHALL: interior of a modest two-storey medieval timber-framed guild house (like a large town inn or mead hall, NOT a palace or cathedral): dark oak posts and beams, wattle-and-daub plaster walls, plank floor, a big stone hearth, a wooden gallery. Now abandoned and damaged: a collapsed section of the thatched/plank roof letting in light, broken benches and a long trestle table, dust, cobwebs, a torn blue banner with a silver well-and-crossed-swords emblem. Humble and homely, not luxurious."),
 ("bg_guildhall_camp_night", "P1", "길드 하우스 캠프 (밤)", "The same ruined timber guild house (see GUILDHALL) at night, partly cleaned, a warm fire in the stone hearth and bedrolls, companions' gear leaning on the walls."),
 ("bg_guildhall_restored1", "P2", "길드 하우스 (복구 1단계)", "The same timber guild house (see GUILDHALL) partly restored: fresh oak beams patching the roof, a repaired long table, a new blue guild banner with the silver well-and-crossed-swords emblem."),
 ("bg_guildhall_restored2", "P2", "길드 하우스 (복구 2단계)", "The same timber guild house (see GUILDHALL) fully restored and lively: banners, warm hearth, trophy shelves, notice board with requests."),
 ("bg_noticeboard", "P1", "의뢰 게시판", "Close-up of a wooden quest notice board covered in pinned parchment notices and wax seals (no readable text)."),
 ("bg_village_square", "P1", "마을 광장", "A medieval village square with a stone well, timber-framed houses and a market stall, morning light."),
 ("bg_tavern", "P1", "선술집", "Interior of a cozy medieval tavern with a hearth, barrels, long benches, candlelight."),
 ("bg_town_harwell", "P1", "하웰 마을 전경 (허브)", "TOWN: a wide establishing view of Harwell, a small frontier village of timber-framed houses on a gentle hillside by a river ford, seen from a slightly elevated angle as a village overview. Six places, each clearly separated and readable as a click target: the two-storey timber guild house with a damaged roof and a torn blue banner with the silver well-and-crossed-swords emblem (art/refs/emblem-harwell.png); a cozy tavern with a hanging copper ladle sign; a blacksmith with a smoking chimney and an anvil out front; a general store with striped awnings and crates; the village chief's modest stone house with a small garden; and the central square with an old stone well. Fields and forest beyond, morning light, warm and inviting. No text or labels."),
 ("bg_smithy", "P1", "대장간", "Interior of a village blacksmith's forge (see TOWN): glowing forge fire, anvil, hanging tools, racks of swords, shields and armor for sale, warm orange light."),
 ("bg_general_store", "P1", "잡화점", "Interior of a cluttered cozy village general store (see TOWN): shelves of jars, potions, dried herbs, sacks of grain, ribbons and trinkets, a wooden counter with scales, soft daylight."),
 ("bg_chief_house", "P1", "촌장 집", "Interior of the village chief's modest stone house (see TOWN): a fireplace, a heavy oak table with ledgers and a village map, dried herbs hanging from beams, a window to the garden, calm afternoon light."),
 ("bg_forest_road", "P1", "숲길", "A forest road through tall oaks, dappled light, a worn wooden signpost."),
 ("bg_bandit_hideout", "P1", "도적 은신처", "A bandit hideout in a rocky ravine, tents, crates, a smoky fire."),
 ("bg_monastery_gate", "P2", "수도원 정문", "The gate of a remote stone monastery on a misty hill at dusk."),
 ("bg_catacombs", "P2", "지하묘지", "Candle-lit catacombs with bone-lined niches and stone arches."),
 ("bg_city_street", "P2", "도시 거리", "A busy medieval city street with tall timber houses and banners."),
 ("bg_lord_hall", "P2", "영주의 대전", "The great hall of a lord's castle with a throne, tapestries and torches."),
 ("bg_city_gate_night", "P2", "밤의 성문", "A fortified city gate at night with torches and rain."),
 ("bg_world_map", "P1", "지역 지도 (이번 주 의뢰 화면 바탕)", "An illustrated parchment map of a medieval region with forests, villages, a monastery, a walled city and mountains, no labels or text. Top-down map view, with empty spots where quest pins can be placed."),
 ("bg_guildhall_past", "P1", "전성기의 길드 하우스 (회상)", "The same timber guild house (see GUILDHALL) in its glorious past: well-kept oak and plaster, blue banners with a silver well-and-crossed-swords emblem, a busy lively hall full of adventurers, warm golden hearth light. Prosperous but still a timber guild house, not a palace."),
 ("bg_room_archive", "P1", "봉인된 방: 기록실", "A dusty sealed archive room inside the timber guild house (see GUILDHALL: oak beams, plaster walls, plank floor), shelves of old ledgers and scrolls, a single beam of light on a locked chest."),
 ("bg_room_armory", "P2", "봉인된 방: 무기고", "A sealed armory in the timber guild house (oak beams, plaster walls), rusted weapon racks, a broken blue banner, one empty armor stand."),
 ("bg_room_office", "P2", "봉인된 방: 길드장 집무실", "The guildmaster's sealed office in the timber guild house (oak panelling, low beamed ceiling), an overturned desk, scattered letters, a portrait with the face slashed out."),
 ("bg_room_vault", "P2", "봉인된 방: 지하 금고", "A hidden stone cellar vault beneath the timber guild house, candle stubs, a stone pedestal holding an old iron-bound guild ledger."),
]
for sid, ph, ko, ex in scenes:
    add(sid, ph, "bg_scene", "-", ko, ex, [ANCHOR], f"art/final/backgrounds/scene/{sid}.png")

battles = [
 ("bt_ch1_forest_ambush", "P1", "1장 숲속 매복 (좁은 맵)", (5, 4), "A narrow forest path hemmed in by thick trees and bushes on all sides."),
 ("bt_ch1_forest_clearing", "P1", "1장 숲속 공터", (7, 5), "Forest clearing with grass and dirt patches; bushes and dry haystacks on the right side."),
 ("bt_ch1_village_outskirts", "P1", "1장 마을 외곽 (넓은 맵)", (9, 5), "Village outskirts with a muddy road crossing the area, wooden fences and clay oil jars near the edges."),
 ("bt_ch1_bandit_cliff", "P1", "1장 도적 절벽 (보스)", (8, 6), "Rocky bandit camp; a sheer cliff drop runs along the entire top edge; crates and clay oil jars on the right."),
 ("bt_ch2_monastery_court", "P2", "2장 수도원 안뜰", (7, 5), "Monastery courtyard with flagstones, a shallow holy water basin, low walls at the edges."),
 ("bt_ch2_catacomb_hall", "P2", "2장 지하묘지 홀 (넓은 맵)", (9, 5), "Catacomb hall floor with shallow water puddles and stone sarcophagi near the edges."),
 ("bt_ch2_crypt_bridge", "P2", "2장 묘실 다리 (보스, 길쭉한 맵)", (8, 4), "A wide stone bridge over a dark chasm; the chasm runs along the top and bottom edges."),
 ("bt_ch3_city_market", "P2", "3장 도시 시장 (넓은 맵)", (9, 5), "City market square with cobblestones; stalls and carts only at the edges; a bell tower base on one side."),
 ("bt_ch3_lord_courtyard", "P2", "3장 영주 성 안뜰", (7, 5), "Castle courtyard with packed earth, an iron portcullis gate with a lever, stone walls at the edges."),
 ("bt_ch3_rampart", "P2", "3장 성벽 위 (보스, 길쭉한 맵)", (8, 4), "Top of a castle rampart at night; a drop off the wall runs along the bottom edge."),
]
for bid, ph, ko, (cols, rows_), ex in battles:
    add(bid, ph, "bg_battle", "-", f"{ko} · {cols}×{rows_}",
        ex + f" The playable area is a grid of {cols} columns by {rows_} rows in the center of the image; keep that area flat, clear and readable, and put scenery outside it.",
        [ANCHOR], f"art/final/backgrounds/battle/{bid}.png",
        f"격자 {cols}×{rows_}. 칸, 타일 표시, 위험 지대는 코드가 그린다. 가장자리 요소 위치를 맵 데이터(docs/05-combat.md 7.4)와 맞출 것")

cgs = [
 ("cg_ch1_inheritance", "P1", "1장 오프닝: 폐허 길드 상속", "Lina standing alone in the ruined guild hall, holding the rusted guild key out toward the viewer (the player), light through broken windows.", ["C01"]),
 ("cg_ch1_end", "P2", "1장 엔딩", "The first companions celebrating around a campfire in the ruined guild hall.", ["C01", "C02", "C03", "C04"]),
 ("cg_ch2_key", "P2", "2장 핵심 장면", "Adelheid confronting the Fallen Abbot in the candle-lit catacombs.", ["C03"]),
 ("cg_ch3_climax", "P2", "3장 클라이맥스", "Godric facing the Black Knight on a castle rampart at night, recognizing the old scratched-off mark on his shield.", ["C06"]),
 ("cg_ending", "P2", "엔딩", "The fully restored guild hall with all companions gathered under the blue guild banner with the silver well-and-crossed-swords emblem.", ["C01", "C02", "C03", "C04", "C05", "C06"]),
 ("cg_C07_quest_end", "P2", "이졸데 개인 퀘스트 엔딩", "Isolde kneeling at her family's ruined manor, holding her signet ring.", ["C07"]),
 ("cg_C08_quest_end", "P2", "카샤 개인 퀘스트 엔딩", "Kasha and her wolf on a snowy northern ridge at dawn.", ["C08"]),
]
affection = {
 "C01": ("P1", "Lina in her casual dress at dusk on the guild hall balcony, shyly offering a slightly burnt homemade pie to the viewer, warm sunset light"),
 "C02": ("P1", "Cecile sitting on a rooftop at night next to the viewer, sharing a stolen apple under the stars, unusually honest gentle smile"),
 "C03": ("P1", "Adelheid asleep at a candle-lit desk piled with books, the viewer's cloak draped over her shoulders, a bookmark with the guild crest in her hand"),
 "C04": ("P1", "Miriam by a moonlit spring without her veil, reaching out her hand toward the viewer, gentle mysterious smile"),
 "C05": ("P2", "Rowen on the tavern stage singing a song clearly dedicated to the viewer, the crowd blurred, spotlight of candlelight"),
 "C06": ("P2", "Godric and the viewer sharing ale at the restored guild hearth, Godric finally laughing, a faded guild-crest badge on the table"),
}
for cid, (ph, ex) in affection.items():
    cgs.append((f"cg_affection_{cid}", ph, f"{chars[cid][1]} 호감도 최대 CG",
                ex + ". Romance is only hinted, tasteful and heartwarming.", [cid]))
for gid, ph, ko, ex, cs in cgs:
    of = "casual" if gid.startswith("cg_affection") else "combat"
    add(gid, ph, "cg", ";".join(cs), ko, ex, [ANCHOR] + [f"art/refs/{c}_ref_{of}.png" for c in cs],
        f"art/final/cg/{gid}.png")

add("mk_key_visual", "P2", "cg", "C01;C02;C03;C04;C05;C06", "키 비주얼 (로고 없음)",
    "Game key visual: the companions posed heroically before the restored guild hall under the blue guild banner with the silver well-and-crossed-swords emblem. Leave empty space at the top for a logo.",
    [ANCHOR] + [f"art/refs/C0{i}_ref_combat.png" for i in range(1, 7)], "art/final/marketing/mk_key_visual.png",
    "Steam 캡슐, 앱 아이콘은 정식 제목이 정해진 뒤 이 이미지에서 파생")

for cid in ["C07", "C08"]:
    add(f"mk_pack_{cid}", "P2", "cg", cid, f"{chars[cid][1]} 동료 팩 홍보 일러스트",
        "Promotional key art for a paid companion pack: the character in a striking signature pose, strong silhouette, leave empty space on one side for a title.",
        [ANCHOR, f"art/refs/{cid}_ref_combat.png"], f"art/final/marketing/mk_pack_{cid}.png",
        "인게임 상점 + Steam DLC 상점 이미지의 원본. 규격 이미지는 여기서 파생", outfit="combat")

# --- step assignment (see art/steps/README.md) ---
S33_IDS = {"bg_town_harwell", "bg_smithy", "bg_general_store", "bg_chief_house"}
S03_IDS = {"C01_portrait_combat_neutral", "C01_portrait_combat_smile", "C01_sd_idle", "C01_sd_attack"}
CHAR_STEPS = {"C02": ("S07", "S08"), "C03": ("S09", "S10"), "C04": ("S11", "S12"),
              "C05": ("S19", "S20"), "C06": ("S21", "S22"), "C07": ("S23", "S24"), "C08": ("S25", "S26")}

def step_of(r):
    i, ph, fmt, subj = r["id"], r["phase"], r["format"], r["subject"]
    if i.startswith("P0_"): return "S01"
    if i in S33_IDS or subj in ("N11", "N12", "N13"): return "S33"
    if i == "C01_ref_combat": return "S02"
    if i in S03_IDS: return "S03"
    if i.startswith("C01_"):
        return "S05" if ("casual" in i) else "S04"
    if i in ("bg_guildhall_ruined", "bt_ch1_forest_clearing"): return "S06"
    if subj in CHAR_STEPS and fmt != "cg":
        ref_step, set_step = CHAR_STEPS[subj]
        return ref_step if fmt == "ref_sheet" else set_step
    if subj in ("P01", "P02", "P03", "P04"):
        return "S13" if (fmt == "ref_sheet" or i == "P04_portrait_neutral") else "S14"
    if ph == "P1":
        if subj[:1] in ("E", "B"): return "S15"
        if fmt in ("bg_scene", "bg_battle"): return "S16"
        if subj.startswith("N"): return "S17"
        if fmt == "cg": return "S18"
    if i.startswith("mk_"): return "S32"
    if subj in ("E06", "E07", "E08", "E09", "E10", "B02"): return "S27"
    if subj in ("E11", "E12", "E13", "E14", "E15", "B03"): return "S28"
    if fmt in ("bg_scene", "bg_battle"): return "S29"
    if subj.startswith("N"): return "S30"
    if fmt == "cg": return "S31"
    raise ValueError(f"no step for {i}")

for r in rows:
    r["step"] = step_of(r)

fields = ["id", "step", "phase", "format", "subject", "outfit", "name_ko", "extra", "refs", "output", "status", "notes"]

# 이미 작업이 시작된 행(status가 todo가 아님)은 Codex가 남긴 상태·기록을 그대로 둔다
import os
if os.path.exists(out_path):
    with open(out_path, encoding="utf-8") as f:
        old = {r["id"]: r for r in csv.DictReader(f)}
    for r in rows:
        o = old.get(r["id"])
        if o and o["status"] != "todo":
            for k in ("extra", "refs", "status", "notes"):
                r[k] = o[k]

with open(out_path, "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=fields)
    w.writeheader()
    w.writerows(rows)

print("total", len(rows))
print("by phase", dict(Counter(r["phase"] for r in rows)))
print("by format", dict(Counter(r["format"] for r in rows)))
print("by step", dict(sorted(Counter(r["step"] for r in rows).items())))
ids = [r["id"] for r in rows]
assert len(ids) == len(set(ids)), "duplicate ids"
