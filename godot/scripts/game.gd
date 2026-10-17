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
var _uid := 0


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
	_uid = 0
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


func quest_reward(qname: String, ok: bool) -> Dictionary:
	var r: Dictionary = G.QUEST_REWARD["ok" if ok else "ng"]
	earn(r.gold, r.mats, r.fame, "의뢰 '%s' %s" % [qname, "성공" if ok else "절반의 성공"])
	return r


# ── 재건 공사 · 시설 · 등급 ──

func stage_cost(i: int) -> Dictionary:
	var s: Dictionary = G.STAGES[i]
	var c := {"gold": s.gold}
	c.merge(s.mats)
	return c


func do_build() -> bool:
	if build + 1 >= G.STAGES.size():
		return false
	if not pay(stage_cost(build + 1), "재건 공사: " + G.STAGES[build + 1].name):
		return false
	build += 1
	week_log.append("재건 · '%s' 공사를 마쳤다" % G.STAGES[build].name)
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
		var top := mini(G.JOB_REQ.size() - 1, 1 + rank + build)
		var req: int = G.JOB_REQ[randi_range(0, top)] + randi_range(-3, 3)
		var mat: String = G.JOB_MATS[t[1]]
		jobs.append({"id": i, "name": t[0], "tag": t[1], "req": req, "gold": int(req * 2.2) + randi_range(0, 20),
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
			week_log.append("실패 · 위탁 '%s' · %s%s" % [j.name, who, (" · %s 다쳐서 한 주 쉰다" % ", ".join(PackedStringArray(hurt))) if not hurt.is_empty() else ""])


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
	_settle_jobs()
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
		var m: int = Defs.HEROES[k].mod.get(stat, 0)
		if m > mod:
			mod = m
			pick = k
	if pick == "":
		return {}
	return {"key": pick, "name": Defs.HEROES[pick].name, "mod": mod}


## d20 + mod >= dc 일 확률
static func chance(mod: int, dc: int) -> float:
	return clampf((21.0 - (dc - mod)) / 20.0, 0.05, 0.95)
