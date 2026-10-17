extends Node
## 한 판의 진행 상태 (자동 로드 Game). 전투 장면으로 갔다 돌아와도 남는다.
## 흐름: 오프닝 → 길드 → 이번 주 의뢰(2개 고르기) → 의뢰마다 연대기 페이지 → 주말 소식 → 결전 → 체험판 끝

const LUCK_START := 2  # 페이지를 펼칠 때 받는 행운 주사위
const LUCK_MAX := 3

var week := 1
var party: Array = ["lina", "cecile", "adelheid"]
var picks: Array = []  # 이번 주에 고른 의뢰
var results := {}  # 의뢰 id -> "ok" / "ng"
var flags := {}
var pages: Array = []  # 완성한 연대기 페이지 [{quest, lines}]
var stage := "opening"  # opening / hub / page / news / finale / end
var page := {}  # 진행 중인 페이지 {quest, node, lines, visited, vars, luck}

var battle_req := {}  # 연대기 → 전투 {idx, party, luck, ambush, boss_hp, back}
var battle_res := {}  # 전투 → 연대기 {result, luck}

# ── 길드 운영 (docs/04-game-flow.md 3.8) ──
const G = preload("res://scripts/guild_defs.gd")
var gold := 0
var mats := {}  # wood / iron / herb
var fame := 0
var rank := 0  # G.RANKS 번호
var build := 0  # 재건 공사 단계 (G.STAGES 번호)
var facilities := {}  # 시설 id -> 레벨
var roster: Array = []  # 명부의 모험가 {id, name, grade, cls, power, tags, trait, wins, hurt}
var applicants: Array = []  # 이번 주 스카우트실 지원자
var jobs: Array = []  # 이번 주 위탁 의뢰 {id, name, tag, req, gold, mat, fame, crew: [모험가 id]}
var ledger: Array = []  # 주말 장부 [{week, lines, income, spend}]
var week_log: Array = []  # 이번 주에 쌓이는 장부 줄
var week_in := 0
var week_out := 0
var news: Array = []  # 지난 주말 소식 (마을 광장)
var bond := {}  # NPC 호감도 {nora, martha} (G.BONDS)
var bond_seen := {}  # NPC 이야기를 본 단계 수
var _uid := 0
# ── 동료 · 물건 · 빚 (docs/04-game-flow.md 5, 6절) ──
const P = preload("res://scripts/party_defs.gd")
var heroes := {}  # 합류한 동료 {lv, xp, weapon: [단계, 강화], armor: [단계, 강화]}
var items := {}  # 잡화점 물건 id -> 개수
var debt := 0  # 상회에 남은 빚

# ── 자동 저장 (화면이 바뀔 때마다. 저장·불러오기 메뉴는 없다) ──
var save_path := "user://autosave.dat"  # 확인용 실행(--goto, --story-shot)은 autosave_test.dat
const SAVE_KEYS := ["week", "party", "picks", "results", "flags", "pages", "stage", "page",
	"gold", "mats", "fame", "rank", "build", "facilities", "roster", "applicants", "jobs",
	"ledger", "week_log", "week_in", "week_out", "news", "bond", "bond_seen", "_uid",
	"heroes", "items", "debt"]


func save() -> void:
	if stage == "opening":
		return
	var d := {"v": 1}
	for k in SAVE_KEYS:
		d[k] = get(k)
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(var_to_str(d))
	f.close()


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func load_save() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		return false
	var d = str_to_var(f.get_as_text())
	f.close()
	if not d is Dictionary:
		return false
	reset()
	for k in SAVE_KEYS:
		if d.has(k):
			set(k, d[k])
	return true


func clear_save() -> void:
	if has_save():
		DirAccess.remove_absolute(save_path)


func reset() -> void:
	week = 1
	party = ["lina", "cecile", "adelheid"]
	picks = []
	results = {}
	flags = {}
	pages = []
	stage = "opening"
	page = {}
	battle_req = {}
	battle_res = {}
	gold = G.START_GOLD
	mats = {"wood": 2, "iron": 0, "herb": 0}
	fame = 0
	rank = 0
	build = 0
	facilities = G.START_FACILITIES.duplicate()
	roster = []
	applicants = []
	jobs = []
	ledger = []
	news = []
	bond = {"nora": 0, "martha": 0}
	bond_seen = {"nora": 0, "martha": 0}
	_uid = 0
	heroes = {}
	for k in ["lina", "cecile", "adelheid"]:
		join(k)
	items = {"potion": 2}
	debt = G.DEBT
	# 처음엔 촌장이 소개해 준 견습 둘이 명부에 있다
	for g in ["F", "F"]:
		roster.append(make_adventurer(g))
	new_week()


# ── 자원 ──

func can_pay(c: Dictionary) -> bool:
	if gold < c.get("gold", 0):
		return false
	for k in G.MATS:
		if mats.get(k, 0) < c.get(k, 0):
			return false
	return true


func pay(c: Dictionary, why: String) -> bool:
	if not can_pay(c):
		return false
	gold -= c.get("gold", 0)
	week_out += c.get("gold", 0)
	for k in G.MATS:
		mats[k] = mats.get(k, 0) - c.get(k, 0)
	week_log.append("지출 · %s (%s)" % [why, G.cost_text(c)])
	return true


func earn(g: int, m: Dictionary, f: int, why: String) -> void:
	gold += g
	week_in += g
	fame += f
	var parts: Array = ["금화 %d" % g] if g > 0 else []
	for k in m:
		if m[k] > 0:
			mats[k] = mats.get(k, 0) + m[k]
			parts.append("%s %d" % [G.MATS[k], m[k]])
	if f > 0:
		parts.append("명성 %d" % f)
	week_log.append("수입 · %s (%s)" % [why, ", ".join(PackedStringArray(parts))])


## 지금 장 (0부터): 끝낸 장 수
func chapter() -> int:
	var ch := 0
	while ch < 2 and flags.get("chapter%d_done" % (ch + 1), false):
		ch += 1
	return ch


func quest_reward(qname: String, ok: bool, ch := -1) -> Dictionary:
	var r: Dictionary = G.QUEST_REWARD[chapter() if ch < 0 else ch]["ok" if ok else "ng"]
	earn(r.gold, r.mats, r.fame, "의뢰 '%s' %s" % [qname, "성공" if ok else "절반의 성공"])
	if ok:
		add_bond("martha", 6)  # "길드 덕에 손님이 늘었어!"
	return r


# ── 재건 공사 · 시설 · 등급 ──

func stage_cost(i: int) -> Dictionary:
	var s: Dictionary = G.STAGES[i]
	var g: int = s.gold
	if bond_seen.get("nora", 0) >= 2:  # 노라 2단계: 공사 금화 −5%
		g = int(round(g * 0.95))
	var c := {"gold": g}
	c.merge(s.mats)
	return c


func do_build() -> bool:
	if build + 1 >= G.STAGES.size():
		return false
	if not pay(stage_cost(build + 1), "재건 공사: " + G.STAGES[build + 1].name):
		return false
	build += 1
	week_log.append("재건 · '%s' 공사를 마쳤다" % G.STAGES[build].name)
	add_bond("nora", G.NORA_BUILD)
	return true


# ── NPC 호감도 (마르타 · 노라) ──

## 다음 단계를 보기 전까지는 그 문턱에서 멈춘다
func add_bond(id: String, n: int) -> void:
	var b: Dictionary = Game.bond_def(id)
	var seen: int = bond_seen.get(id, 0)
	var cap: int = b.need[seen] if seen < b.need.size() else b.need[-1]
	# 문턱 0 인 단계(동료 첫인상)는 보기 전에도 다음 문턱까지 쌓인다
	if cap == 0 and seen + 1 < b.need.size():
		cap = b.need[seen + 1]
	bond[id] = mini(bond.get(id, 0) + n, cap)


## 볼 수 있는 다음 단계 (1~3), 없으면 0
func bond_ready(id: String) -> int:
	var b: Dictionary = Game.bond_def(id)
	var seen: int = bond_seen.get(id, 0)
	if seen >= b.need.size():
		return 0
	if bond.get(id, 0) < b.need[seen]:
		return 0
	var ch: int = b.chapter[seen]
	if ch > 0 and not flags.get("chapter%d_done" % ch, false):
		return 0
	# 장면이 아직 없는 단계는 열지 않는다 (체험판 범위)
	if not load("res://scripts/story_defs.gd").SCENES.has(b.scene + str(seen + 1)):
		return 0
	return seen + 1


## 다음 단계 문턱까지 (0~1)
func bond_ratio(id: String) -> float:
	var b: Dictionary = Game.bond_def(id)
	var seen: int = bond_seen.get(id, 0)
	if seen >= b.need.size():
		return 1.0
	var lo: int = 0 if seen == 0 else b.need[seen - 1]
	return clampf(float(bond.get(id, 0) - lo) / float(b.need[seen] - lo), 0.0, 1.0)


## 호감도 정의: NPC 는 G.BONDS, 동료는 5단계 (G.companion_bond)
func bond_def(id: String) -> Dictionary:
	if G.BONDS.has(id):
		return G.BONDS[id]
	return G.companion_bond(id, P_HEROES()[id].name)


func P_HEROES() -> Dictionary:
	return load("res://scripts/fk_defs.gd").HEROES


# ── 동료: 합류 · 레벨 · 장비 ──

func join(k: String) -> void:
	if heroes.has(k):
		return
	heroes[k] = {"lv": 1, "xp": 0, "weapon": [0, 0], "armor": [0, 0]}
	bond[k] = 0
	bond_seen[k] = 0


## 경험치를 주고, 오른 레벨 수를 돌려준다
func give_xp(k: String, n: int) -> int:
	var h: Dictionary = heroes[k]
	var ups := 0
	h.xp += n
	while h.lv < P.LV_MAX and h.xp >= P.xp_need(h.lv):
		h.xp -= P.xp_need(h.lv)
		h.lv += 1
		ups += 1
		add_bond(k, G.CB_LEVEL)
	if h.lv >= P.LV_MAX:
		h.xp = 0
	return ups


## 의뢰를 마친 뒤 경험치: 파티는 전부, 남은 동료는 훈련장 비율만큼. [[이름, 얻은 경험치, 오른 레벨], ...]
func quest_xp(base: int) -> Array:
	var out: Array = []
	var share: float = [0.0, 0.3, 0.5, 0.7][facilities.get("training", 0)]
	for k in heroes:
		var n: int = base if k in party else int(base * share)
		if n <= 0:
			continue
		var ups := give_xp(k, n)
		out.append([P_HEROES()[k].name, n, ups, heroes[k].lv])
	return out


## 레벨·장비로 붙는 전투 수치 {hp, def, power}
func hero_bonus(k: String) -> Dictionary:
	var h: Dictionary = heroes.get(k, {"lv": 1, "weapon": [0, 0], "armor": [0, 0]})
	return {"hp": (h.lv - 1) * P.LV_HP + h.armor[1] * 2,
		"def": h.armor[0],
		"power": P.lv_power(h.lv) + h.weapon[0] + h.weapon[1]}


func plus_cap() -> int:
	return P.PLUS_BASE + facilities.get("armory", 0)


## 대장간: 새 단계 장비 사기 (쓰던 것은 판다)
func gear_buy_cost(k: String, kind: String, tier: int) -> Dictionary:
	var t: Dictionary = P.TIERS[tier]
	return {"gold": t.gold, "iron": t.iron}


func gear_sell_value(k: String, kind: String) -> int:
	var g: Array = heroes[k][kind]
	var v: int = P.TIERS[g[0]].gold
	for i in g[1]:
		v += P.plus_cost(g[0], i).gold
	return int(v * P.SELL_RATE)


func buy_gear(k: String, kind: String, tier: int) -> bool:
	var g: Array = heroes[k][kind]
	if tier <= g[0] or build < P.TIERS[tier].build:
		return false
	var sell := gear_sell_value(k, kind)
	var gname := P.gear_name(k, kind, tier, 0)
	if not pay(gear_buy_cost(k, kind, tier), "%s %s" % [P_HEROES()[k].name, gname]):
		return false
	if sell > 0:
		earn(sell, {}, 0, "쓰던 %s 판값" % P.gear_name(k, kind, g[0], g[1]))
	heroes[k][kind] = [tier, 0]
	return true


func plus_gear(k: String, kind: String) -> bool:
	var g: Array = heroes[k][kind]
	if g[1] >= plus_cap():
		return false
	if not pay(P.plus_cost(g[0], g[1]), "%s 강화 +%d" % [P.gear_name(k, kind, g[0], 0), g[1] + 1]):
		return false
	g[1] += 1
	return true


# ── 잡화점 물건 · 선물 ──

func buy_item(id: String) -> bool:
	if not pay({"gold": P.ITEMS[id].gold}, P.ITEMS[id].name):
		return false
	items[id] = items.get(id, 0) + 1
	return true


func use_item(id: String) -> bool:
	if items.get(id, 0) <= 0:
		return false
	items[id] -= 1
	if items[id] <= 0:
		items.erase(id)
	return true


func food_count() -> int:
	var n := 0
	for id in items:
		if P.ITEMS[id].kind == "food":
			n += items[id]
	return n


## 식재료 하나 쓰기 (가장 많은 것부터)
func use_food() -> String:
	var best_id := ""
	for id in items:
		if P.ITEMS[id].kind == "food" and (best_id == "" or items[id] > items[best_id]):
			best_id = id
	if best_id != "":
		use_item(best_id)
	return best_id


func can_gift(who: String) -> bool:
	return not flags.get("gift_%s_%d" % [who, week], false)


## 선물: 한 사람에게 한 주에 한 번. 돌려주는 값 [등급(0 좋아함 1 보통 2 별로), 오른 호감도]
func give_gift(who: String, id: String) -> Array:
	if not can_gift(who) or not use_item(id):
		return []
	flags["gift_%s_%d" % [who, week]] = true
	var gr := P.gift_grade(who, id)
	var before: int = bond.get(who, 0)
	add_bond(who, [P.GIFT_LIKE, P.GIFT_OK, P.GIFT_MEH][gr])
	return [gr, bond.get(who, 0) - before]


# ── 상회 빚 ──

## 이번 장이 끝날 때까지 갚아야 할 누계
func debt_due() -> int:
	var ch := 1
	while flags.get("chapter%d_done" % ch, false) and ch < G.DEBT_DUE.size():
		ch += 1
	var due := 0
	for i in ch:
		due += G.DEBT_DUE[i]
	return maxi(0, due - (G.DEBT - debt))


func pay_debt(n: int) -> bool:
	n = mini(n, debt)
	if n <= 0 or not pay({"gold": n}, "금저울 상회 빚 갚기"):
		return false
	debt -= n
	return true


func fac_max(id: String) -> int:
	var st: Dictionary = G.STAGES[build]
	return mini(G.FACILITIES[id].max, st.scout_max if id == "scout" else st.max_lv)


func slots_used() -> int:
	return facilities.size()


## 시설을 짓거나 올리는 값. 못 하면 빈 사전
func fac_next_cost(id: String) -> Dictionary:
	var lv: int = facilities.get(id, 0)
	if lv >= fac_max(id):
		return {}
	if lv == 0 and slots_used() >= G.STAGES[build].slots:
		return {}
	return G.FACILITIES[id].cost[lv]


func upgrade(id: String) -> bool:
	var c := fac_next_cost(id)
	if c.is_empty():
		return false
	var lv: int = facilities.get(id, 0)
	if not pay(c, "%s %d레벨" % [G.FACILITIES[id].name, lv + 1]):
		return false
	facilities[id] = lv + 1
	return true


func roster_cap() -> int:
	return G.ROSTER_CAP[facilities.get("dorm", 0)]


func can_rank_up() -> bool:
	return rank + 1 < G.RANKS.size() and fame >= G.RANKS[rank + 1].fame


# ── 모험가 인력풀 · 스카우트 ──

func make_adventurer(grade: String) -> Dictionary:
	_uid += 1
	var gi: Dictionary = G.GRADE_INFO[grade]
	var keys := G.CLASSES.keys()
	var cls: String = "novice" if grade == "F" and randf() < 0.5 else keys[randi() % keys.size()]
	var tags: Array = G.CLASSES[cls].tags.duplicate()
	if G.GRADES.find(grade) < 2 and randf() < 0.5:
		tags = [tags[randi() % 2]]
	var used: Array = roster.map(func(a): return a.name) + applicants.map(func(a): return a.name)
	var pool: Array = G.NAMES.filter(func(n): return not n in used)
	return {"id": _uid, "name": pool[randi() % pool.size()] if not pool.is_empty() else "무명", "grade": grade, "cls": cls,
		"power": randi_range(gi.power[0], gi.power[1]), "tags": tags, "trait": G.TRAITS[randi() % G.TRAITS.size()], "wins": 0, "hurt": 0}


func _roll_grade() -> String:
	var lv: int = facilities.get("scout", 1)
	var top: int = G.GRADES.find(G.SCOUT[lv - 1][1])
	# 아래 등급일수록 잘 나온다. 길드 등급이 오르면 한 칸 위쪽으로 치우친다
	var w: Array = []
	for i in top + 1:
		w.append(float(top + 1 - i) + (1.0 if i >= rank else 0.0))
	if top == 5:
		w[5] = 0.25  # S는 드물게
	var sum := 0.0
	for x in w:
		sum += x
	var r := randf() * sum
	for i in w.size():
		r -= w[i]
		if r <= 0.0:
			return G.GRADES[i]
	return G.GRADES[0]


func hire(a: Dictionary) -> bool:
	if roster.size() >= roster_cap():
		return false
	if not pay({"gold": G.GRADE_INFO[a.grade].fee}, "%s급 %s 계약금" % [a.grade, a.name]):
		return false
	applicants.erase(a)
	roster.append(a)
	return true


func adventurer(id: int) -> Dictionary:
	for a in roster:
		if a.id == id:
			return a
	return {}


# ── 위탁 의뢰 ──

func _make_jobs() -> void:
	jobs = []
	var n := mini(5, 3 + rank + (1 if facilities.get("board", 1) >= 2 else 0))
	var pool := G.JOBS.duplicate()
	pool.shuffle()
	for i in n:
		var t: Array = pool[i]
		var top := mini(G.JOB_REQ.size() - 1, 1 + rank + build / 2)
		var req: int = G.JOB_REQ[randi_range(0, top)] + randi_range(-3, 3)
		var mat: String = G.JOB_MATS[t[1]]
		jobs.append({"id": i, "name": t[0], "tag": t[1], "req": req, "gold": int(req * G.JOB_GOLD) + randi_range(0, 20),
			"mat": mat, "mat_n": 1 + req / 35 if mat != "" else 0, "fame": maxi(1, req / 15), "crew": []})


func busy(id: int) -> bool:
	for j in jobs:
		if id in j.crew:
			return true
	return false


## 위탁 의뢰 성공률 (0.05 ~ 0.95)
func job_chance(j: Dictionary, crew: Array) -> float:
	if crew.is_empty():
		return 0.0
	var eff := 0.0
	var bonus := 0.0
	for id in crew:
		var a := adventurer(id)
		eff += a.power * (1.25 if j.tag in a.tags else 1.0)
		var tr: Dictionary = a.trait
		if tr.has("chance") and (not tr.has("tag") or tr.tag == j.tag):
			bonus += tr.chance
	return clampf(0.5 + (eff - j.req) / (j.req * 1.2 + 20.0) + bonus, 0.05, 0.95)


## 주말: 위탁 의뢰 결과
func _settle_jobs() -> void:
	for j in jobs:
		if j.crew.is_empty():
			continue
		var crew_names: Array = j.crew.map(func(id): return adventurer(id).name)
		var who := ", ".join(PackedStringArray(crew_names))
		if randf() < job_chance(j, j.crew):
			var g: float = j.gold
			var share := 0
			var gbonus := 0.0
			for id in j.crew:
				var a := adventurer(id)
				share += G.GRADE_INFO[a.grade].share
				gbonus += a.trait.get("gold", 0.0)
				a.wins += 1
			g *= 1.0 + gbonus
			if bond_seen.get("nora", 0) >= 3:  # 노라 3단계: 위탁 보수 +10%
				g *= 1.1
			var net := int(g * (1.0 - minf(share, 60) / 100.0))
			var m := {j.mat: j.mat_n} if j.mat != "" else {}
			earn(net, m, j.fame, "위탁 '%s' 성공 · %s (몫 %d%% 뗌)" % [j.name, who, mini(share, 60)])
			for id in j.crew:
				_maybe_promote(adventurer(id))
		else:
			var hurt: Array = []
			for id in j.crew:
				var a := adventurer(id)
				if not a.trait.get("safe", false):
					a.hurt = 2  # 다음 주 한 주 쉰다 (new_week 에서 1 줄어든다)
					hurt.append(a.name)
			week_log.append("실패 · 위탁 '%s' · %s%s" % [j.name, who, (" · %s 다쳐서 한 차례 쉰다" % ", ".join(PackedStringArray(hurt))) if not hurt.is_empty() else ""])


func _maybe_promote(a: Dictionary) -> void:
	var need := 2 if a.trait.get("fast", false) else 3
	var gi := G.GRADES.find(a.grade)
	if a.wins < need or gi >= 4:  # 승급으로는 A까지. S는 스카우트로만
		return
	a.wins = 0
	a.grade = G.GRADES[gi + 1]
	var pr: Array = G.GRADE_INFO[a.grade].power
	a.power = maxi(a.power + 12, pr[0])
	week_log.append("승급 · %s 이(가) 승급 시험에 붙어 %s급이 되었다" % [a.name, a.grade])


# ── 한 주 ──

func new_week() -> void:
	week_log = []
	week_in = 0
	week_out = 0
	for a in roster:
		a.hurt = maxi(0, a.hurt - 1)
	applicants = []
	var n: int = G.SCOUT[facilities.get("scout", 1) - 1][0]
	for i in n:
		applicants.append(make_adventurer(_roll_grade()))
	_make_jobs()


## 주말 정산 → 장부 한 페이지를 남기고 돌려준다
func settle() -> Dictionary:
	# 한 주에 한 번만 (이어하기로 장부 화면에 다시 와도 두 번 정산하지 않는다)
	if flags.get("settled_%d" % week, false) and not ledger.is_empty():
		return ledger[-1]
	flags["settled_%d" % week] = true
	var idle := jobs.any(func(j): return j.crew.is_empty())
	_settle_jobs()
	add_bond("nora", G.NORA_WEEK + (0 if idle else G.NORA_WEEK_FULL))
	var entry := {"week": week, "lines": week_log.duplicate(), "income": week_in, "spend": week_out}
	ledger.append(entry)
	return entry


## 그림 불러오기: 웹 빌드는 res://art (prepare_web 이 복사), 편집기에서는 ../art/final 도 읽는다
func tex(rel: String) -> Texture2D:
	if rel == "":
		return null
	var res := "res://art/" + rel
	if ResourceLoader.exists(res):
		return load(res)
	var path := ProjectSettings.globalize_path("res://").path_join("../art/final/" + rel)
	if OS.has_feature("web") or not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(path)
	return ImageTexture.create_from_image(img) if img != null else null


## 파티에서 이 능력치가 가장 높은 동료 (who 가 정해져 있으면 그 동료, 없으면 null)
func best(stat: String, who := "") -> Dictionary:
	var Defs = load("res://scripts/fk_defs.gd")
	var pick := ""
	var mod := -99
	for k in party:
		if who != "" and k != who:
			continue
		var m: int = Defs.HEROES[k].mod.get(stat, 0) + (1 if bond_seen.get(k, 0) >= 2 else 0)  # 동료 2단계: 판정 +1
		if m > mod:
			mod = m
			pick = k
	if pick == "":
		return {}
	return {"key": pick, "name": Defs.HEROES[pick].name, "mod": mod}


## d20 + mod >= dc 일 확률
static func chance(mod: int, dc: int) -> float:
	return clampf((21.0 - (dc - mod)) / 20.0, 0.05, 0.95)
