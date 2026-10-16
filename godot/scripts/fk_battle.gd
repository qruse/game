extends RefCounted
## 포 더 킹식 전투 규칙 (화면과 분리). 화면은 events 를 받아 차례로 연출한다.
## 한 라운드 = 모든 유닛이 속도 순서대로 한 번씩 행동. 행동은 판정 칸 n개를 굴려 성공한 칸 비율만큼 효과를 낸다.

const Defs = preload("res://scripts/fk_defs.gd")

const FATE_MAX := 3
const RED := Color(1.0, 0.42, 0.38)
const GREEN := Color(0.55, 1.0, 0.55)
const GRAY := Color(0.82, 0.82, 0.82)
const GOLD := Color(1.0, 0.85, 0.4)
const PURPLE := Color(0.85, 0.62, 1.0)
const ORANGE := Color(1.0, 0.62, 0.22)
## 다음 자기 턴이 시작되면 풀리는 상태 (그 전까지 적의 공격을 막는다)
const UNTIL_NEXT := ["guard", "smoke", "cover"]


class Unit:
	var uid := 0
	var key := ""
	var name := ""
	var side := ""
	var role := ""
	var art := ""
	var color := Color.WHITE
	var max_hp := 1
	var hp := 1
	var def := 10
	var spd := 3
	var mods := {}
	var atk := 0
	var power := 0
	var slots := 2
	var skills: Array = []
	var ult := ""
	var boss := false
	var raged := false
	var slot := 0  # 무대 위 자리 번호 (같은 편 안에서 0 이 맨 앞)
	var st := {}  # 상태 -> 남은 턴
	var cd := {}  # 스킬 -> 남은 대기 턴
	var resolve := 0
	var downed := false
	var removed := false
	var n_act := 0

	func alive() -> bool:
		return not downed and not removed


var rng := RandomNumberGenerator.new()
var title := ""
var bg := ""
var units: Array = []
var objects: Array = []  # {id, key, name, x, y, used, cover}
var round_no := 0
var order: Array = []  # 이번 라운드 행동 순서 (uid)
var turn_idx := 0
var fate := 2
var events: Array = []
var result := ""
var downs := 0
var round_event := {}
var _next_uid := 1


func setup(battle_idx: int, party: Array) -> void:
	rng.randomize()
	var b: Dictionary = Defs.BATTLES[battle_idx]
	title = b.name
	bg = b.bg
	round_event = b.get("event", {}).duplicate()
	for i in party.size():
		units.append(_make_hero(party[i], i))
	var es: Array = []
	for i in b.enemies.size():
		var e := _make_enemy(b.enemies[i], i)
		units.append(e)
		es.append(e)
	for i in b.objects.size():
		var o: Dictionary = b.objects[i]
		var d: Dictionary = Defs.OBJECTS[o.key]
		var ob := {"id": i, "key": o.key, "name": d.name, "x": o.x, "y": o.y, "used": false, "cover": -1}
		if o.has("cover"):
			ob.cover = es[o.cover].uid
			es[o.cover].st["cover"] = 99
		objects.append(ob)
	round_no = 1
	_make_order()


func _make_hero(key: String, i: int) -> Unit:
	var d: Dictionary = Defs.HEROES[key]
	var u := Unit.new()
	u.uid = _next_uid
	_next_uid += 1
	u.key = key
	u.side = "ally"
	u.name = d.name
	u.role = d.role
	u.art = d.art
	u.color = d.color
	u.max_hp = d.hp
	u.hp = d.hp
	u.def = d.def
	u.spd = d.spd
	u.mods = d.mod
	u.skills = d.skills
	u.ult = d.ult
	u.slot = i
	return u


func _make_enemy(key: String, i: int) -> Unit:
	var d: Dictionary = Defs.ENEMIES[key]
	var u := Unit.new()
	u.uid = _next_uid
	_next_uid += 1
	u.key = key
	u.side = "enemy"
	u.name = d.name
	u.color = d.color
	u.max_hp = d.hp
	u.hp = d.hp
	u.def = d.def
	u.spd = d.spd
	u.atk = d.atk
	u.power = d.power
	u.slots = d.slots
	u.boss = d.get("boss", false)
	u.slot = i
	return u


# ── 조회 ────────────────────────────────────────────

func unit(uid: int) -> Unit:
	for u in units:
		if u.uid == uid:
			return u
	return null


func side_units(side: String, include_downed := false) -> Array:
	return units.filter(func(u): return u.side == side and not u.removed and (include_downed or not u.downed))


func has_st(u: Unit, s: String) -> bool:
	return u.st.get(s, 0) > 0


func status_names(u: Unit) -> Array:
	var out: Array = []
	for k in u.st.keys():
		if u.st[k] > 0:
			out.append(Defs.STATUS.get(k, k))
	return out


func eff_def(u: Unit) -> int:
	var v := u.def
	if has_st(u, "guard"):
		v += 3
	if has_st(u, "smoke"):
		v += 3
	if has_st(u, "cover"):
		v += 4
	return v


func current() -> Unit:
	return unit(order[turn_idx]) if turn_idx < order.size() else null


func flammable(o: Dictionary) -> bool:
	return not o.used and Defs.OBJECTS[o.key].has("fire")


func upcoming_text() -> String:
	if round_event.is_empty() or round_event.get("done", false):
		return ""
	if side_units("enemy").filter(func(e): return e.key == round_event.alive).is_empty():
		return ""
	return round_event.warn


# ── 기록·연출 이벤트 ────────────────────────────────

func _log(t: String) -> void:
	events.append({"t": "log", "text": t})


func _float(u: Unit, text: String, col: Color) -> void:
	events.append({"t": "float", "uid": u.uid, "text": text, "color": col})


func _pose(u: Unit, pose: String, to_uid := -1, to_obj := -1) -> void:
	events.append({"t": "pose", "uid": u.uid, "pose": pose, "to": to_uid, "obj": to_obj})


# ── 판정 칸 ─────────────────────────────────────────

## 칸 하나를 성공시키는 데 필요한 d20 눈 (2~20). 1은 항상 실패, 20은 항상 성공
func need_face(bonus: int, diff: int) -> int:
	return clampi(diff - bonus, 2, 20)


func chance(bonus: int, diff: int) -> float:
	return (21 - need_face(bonus, diff)) / 20.0


func bonus_of(u: Unit, stat: String) -> int:
	var b: int = u.atk if u.side == "enemy" else u.mods.get(stat, 0)
	if has_st(u, "bless"):
		b += 3
	return b


## 칸 n개를 굴린다. auto 칸은 확정 성공(은신), locks 칸은 행운 주사위로 확정 성공
func roll_slots(u: Unit, label: String, n: int, bonus: int, diff: int, locks := 0, auto := 0) -> int:
	var need := need_face(bonus, diff)
	var slots: Array = []
	var ok_n := 0
	for i in n:
		var sl := {"v": 0, "ok": true, "tag": ""}
		if i < auto:
			sl.tag = "은신"
		elif i < auto + locks:
			sl.tag = "확정"
		else:
			var v := rng.randi_range(1, 20)
			sl.v = v
			sl.ok = v == 20 or (v != 1 and v >= need)
			if v == 20 and u.side == "ally":
				sl.tag = "대성공"
			elif v == 1:
				sl.tag = "대실패"
		if sl.ok:
			ok_n += 1
		slots.append(sl)
	events.append({"t": "roll", "uid": u.uid, "label": label, "slots": slots, "need": need, "ok": ok_n, "n": n})
	var faces: Array = slots.map(func(s): return s.tag if s.tag in ["은신", "확정"] else str(s.v))
	_log("%s %s: %s (필요 %d 이상) → %d/%d 성공%s" % [u.name, label, " ".join(PackedStringArray(faces)), need, ok_n, n, " · 완벽!" if ok_n == n and n > 1 else ""])
	if u.side == "ally":
		u.resolve = mini(100, u.resolve + 8 * ok_n)
		for s in slots:
			if s.tag == "대성공" and fate < FATE_MAX:
				fate += 1
				_log("대성공! 행운 주사위 +1 (%d)" % fate)
	return ok_n


func scaled(power: int, ok_n: int, n: int) -> int:
	return roundi(float(power) * ok_n / maxf(1.0, n))


# ── 피해·회복 ───────────────────────────────────────

func hurt(t: Unit, amount: int, src := "") -> void:
	if amount <= 0 or not t.alive():
		return
	if t.side == "ally" and has_st(t, "oath"):
		amount = maxi(1, amount / 2)
	var before := t.hp
	t.hp = maxi(0, t.hp - amount)
	events.append({"t": "pose", "uid": t.uid, "pose": "hit", "to": -1, "obj": -1})
	events.append({"t": "hp", "uid": t.uid, "hp": t.hp, "before": before})
	_float(t, "-%d" % amount, RED)
	_log("  %s %s 피해 %d (HP %d/%d)" % [t.name, src, amount, t.hp, t.max_hp])
	if t.side == "ally":
		t.resolve = mini(100, t.resolve + 12)
	if t.hp > 0:
		if t.boss and not t.raged and t.hp * 2 <= t.max_hp:
			t.raged = true
			t.atk += 2
			_float(t, "분노!", ORANGE)
			_log("%s가 분노했다! 명중 +2" % t.name)
		return
	if t.side == "ally":
		t.downed = true
		t.st.clear()
		downs += 1
		_log("%s 쓰러짐! (치유로 일으킬 수 있다)" % t.name)
		events.append({"t": "pose", "uid": t.uid, "pose": "down", "to": -1, "obj": -1})
	else:
		t.removed = true
		_log("%s 쓰러뜨림!" % t.name)
		events.append({"t": "die", "uid": t.uid})
		for o in objects:
			if o.cover == t.uid:
				o.cover = -1
	_check_end()


func heal(t: Unit, amount: int) -> void:
	if amount <= 0 or t.removed:
		return
	var before := t.hp
	if t.downed:
		t.downed = false
		t.hp = mini(t.max_hp, amount)
		_log("  %s 일어남 (HP %d)" % [t.name, t.hp])
		events.append({"t": "pose", "uid": t.uid, "pose": "idle", "to": -1, "obj": -1})
	else:
		t.hp = mini(t.max_hp, t.hp + amount)
		_log("  %s 회복 %d (HP %d/%d)" % [t.name, t.hp - before, t.hp, t.max_hp])
	events.append({"t": "hp", "uid": t.uid, "hp": t.hp, "before": before})
	_float(t, "+%d" % (t.hp - before), GREEN)


func add_st(t: Unit, s: String, turns: int) -> void:
	if not t.alive():
		return
	t.st[s] = maxi(t.st.get(s, 0), turns)
	_float(t, Defs.STATUS[s], PURPLE if s in ["stun", "burn", "taunt"] else GOLD)


func _check_end() -> void:
	if result != "":
		return
	if side_units("enemy").is_empty():
		result = "win"
		_log("── 승리! ──")
	elif side_units("ally").is_empty():
		result = "lose"
		_log("── 전멸… ──")


# ── 턴 흐름 ─────────────────────────────────────────

func _make_order() -> void:
	var live: Array = units.filter(func(u): return u.alive())
	live.sort_custom(_faster)
	order = live.map(func(u): return u.uid)
	turn_idx = 0


## 속도가 빠른 순, 같으면 동료 먼저, 그다음 앞자리부터
func _faster(a: Unit, b: Unit) -> bool:
	if a.spd != b.spd:
		return a.spd > b.spd
	if a.side != b.side:
		return a.side == "ally"
	return a.slot < b.slot


## 다음에 행동할 유닛으로 넘어간다. 라운드가 끝나면 null
func advance() -> Unit:
	while turn_idx < order.size():
		var u := unit(order[turn_idx])
		if u != null and u.alive():
			return u
		turn_idx += 1
	return null


## 턴 시작 처리. false 면 이번 턴은 건너뛴다 (기절, 화상으로 쓰러짐)
func begin_turn(u: Unit) -> bool:
	events.append({"t": "turn", "uid": u.uid})
	for s in UNTIL_NEXT:
		if s != "cover" or u.side == "ally":
			u.st.erase(s)
	for k in u.cd.keys():
		u.cd[k] = maxi(0, u.cd[k] - 1)
	if has_st(u, "burn"):
		_log("%s 화상" % u.name)
		hurt(u, 2, "(화상)")
		if not u.alive():
			return false
	if has_st(u, "stun"):
		u.st.erase("stun")
		_float(u, "기절", PURPLE)
		_log("%s 기절해서 턴을 넘긴다" % u.name)
		return false
	return true


func end_turn(u: Unit) -> void:
	for k in u.st.keys():
		if k in UNTIL_NEXT or k == "stun" or (k == "cover" and u.side == "enemy"):
			continue
		u.st[k] -= 1
		if u.st[k] <= 0:
			u.st.erase(k)
	turn_idx += 1


func end_round() -> void:
	var ev := round_event
	if not ev.is_empty() and not ev.get("done", false) and round_no == ev.round:
		ev.done = true
		if not side_units("enemy").filter(func(e): return e.key == ev.alive).is_empty():
			_log(ev.text)
			for k in ev.spawn:
				var e := _make_enemy(k, side_units("enemy").size())
				e.slot = units.filter(func(x): return x.side == "enemy").size()
				units.append(e)
				events.append({"t": "spawn", "uid": e.uid})
	round_no += 1
	_make_order()


# ── 행동 목록 ───────────────────────────────────────

## 동료가 고를 수 있는 행동. id: 스킬 id / "guard" / "env:<오브젝트 id>"
func actions_for(u: Unit) -> Array:
	var out: Array = []
	for sid in u.skills + [u.ult]:
		var s: Dictionary = Defs.SKILLS[sid]
		var ready := true
		var note := ""
		if sid == u.ult:
			ready = u.resolve >= 100
			note = "%d%%" % u.resolve
		elif u.cd.get(sid, 0) > 0:
			ready = false
			note = "대기 %d" % u.cd[sid]
		out.append({"id": sid, "name": s.name, "kind": "ult" if sid == u.ult else "skill", "slots": s.get("slots", 0), "stat": s.get("stat", ""), "ready": ready and not targets(u, sid).is_empty(), "note": note, "desc": s.desc})
	out.append({"id": "guard", "name": "방어", "kind": "basic", "slots": 0, "stat": "", "ready": true, "note": "", "desc": "다음 턴까지 방어 +3"})
	return out


## 오브젝트 하나로 이 동료가 할 수 있는 일. id: "env:<오브젝트 id>:<방법 번호>"
## 환경은 기본 행동 목록에 없고, 플레이어가 무대에서 눌러 찾아야 나온다
func obj_actions(u: Unit, oid: int) -> Array:
	var o := obj(oid)
	var out: Array = []
	if o.used:
		return out
	var acts: Array = Defs.OBJECTS[o.key].acts
	for i in acts.size():
		var a: Dictionary = acts[i]
		if not u.key in a.who:
			continue
		var aid := "env:%d:%d" % [oid, i]
		var ready := not targets(u, aid).is_empty()
		var note := ""
		var slots: int = a.get("slots", 0)
		if a.has("skill"):
			slots = Defs.SKILLS[a.skill].slots
			if u.cd.get(a.skill, 0) > 0:
				ready = false
				note = "대기 %d" % u.cd[a.skill]
		out.append({"id": aid, "name": a.name, "kind": "env", "slots": slots, "ready": ready, "note": note, "desc": _env_desc(o, a)})
	return out


func _env_desc(o: Dictionary, a: Dictionary) -> String:
	if a.has("skill"):
		var d: Dictionary = Defs.OBJECTS[o.key]
		if d.fire == "explode":
			return "%s: 불이 붙으면 적 전원 피해 %d + 화상" % [o.name, d.power]
		return "%s: 불타면 엄폐가 사라지고 뒤의 적이 화상" % o.name
	match a.effect:
		"explode":
			return "%s: 적 전원 피해 %d + 화상" % [o.name, a.power]
		"crush":
			return "%s: 고른 적 피해 %d%s · 완벽: 기절" % [o.name, a.power, ", 옆 적도 절반" if a.get("splash", false) else ""]
		"break_cover":
			return "%s: 궁수의 엄폐를 없앤다 · 완벽: 기절" % o.name
		"hide":
			return "%s: 은신 (적이 노리지 않고, 다음 공격 1칸 확정)" % o.name
		"cover_self":
			return "%s: 다음 턴까지 방어 +4" % o.name
	return o.name


func env_act(aid: String) -> Dictionary:
	return Defs.OBJECTS[obj(int(aid.get_slice(":", 1))).key].acts[int(aid.get_slice(":", 2))]


func obj(id: int) -> Dictionary:
	return objects[id]


## 스킬로 불붙이는 환경 행동은 그 스킬을 오브젝트에 쓰는 것으로 바꾼다
func _redirect(aid: String, t: Dictionary) -> Array:
	if aid.begins_with("env:"):
		var a := env_act(aid)
		if a.has("skill"):
			return [a.skill, {"k": "o", "id": int(aid.get_slice(":", 1))}]
	return [aid, t]


## 대상 후보. {"k": "u", "uid"} / {"k": "o", "id"} / {"k": "self"}
func targets(u: Unit, aid: String) -> Array:
	var kind := ""
	if aid == "guard":
		kind = "self"
	elif aid.begins_with("env:"):
		var o := obj(int(aid.get_slice(":", 1)))
		if o.used:
			return []
		var a := env_act(aid)
		if a.has("skill"):
			return [{"k": "o", "id": o.id}] if flammable(o) else []
		if a.effect == "crush":
			kind = "enemy"
		elif a.effect == "break_cover":
			kind = "self" if o.cover != -1 else "none"
		else:
			kind = "self"
	else:
		kind = Defs.SKILLS[aid].target
	var out: Array = []
	match kind:
		"self", "all_enemies", "all_allies":
			out.append({"k": "self"})
		"enemy":
			for e in side_units("enemy"):
				out.append({"k": "u", "uid": e.uid})
		"ally":
			for a in side_units("ally"):
				out.append({"k": "u", "uid": a.uid})
		"ally_any":
			for a in side_units("ally", true):
				if a.downed or a.hp < a.max_hp:
					out.append({"k": "u", "uid": a.uid})
	return out


## 굴리기 전 미리보기: 칸 수, 칸마다 성공 확률, 확정 칸(은신)
func preview(u: Unit, aid: String, t: Dictionary) -> Dictionary:
	var rd := _redirect(aid, t)
	aid = rd[0]
	t = rd[1]
	if aid == "guard" or (Defs.SKILLS.has(aid) and not Defs.SKILLS[aid].has("slots")):
		return {"n": 0, "chance": 1.0, "need": 0, "auto": 0, "stat": ""}
	var stat := ""
	var n := 0
	var diff := 10
	if aid.begins_with("env:"):
		var a := env_act(aid)
		stat = a.stat
		n = a.slots
		diff = a.diff
	else:
		var s: Dictionary = Defs.SKILLS[aid]
		stat = s.stat
		n = s.slots
		diff = _diff_for(s, t)
	var bonus := bonus_of(u, stat)
	var auto := 1 if has_st(u, "stealth") and _is_attack(aid) and t.get("k", "") == "u" else 0
	return {"n": n, "chance": chance(bonus, diff), "need": need_face(bonus, diff), "auto": auto, "stat": Defs.STAT.get(stat, ""), "diff": diff}


## 난이도: 적을 치면 그 적의 방어, 동료를 돕거나 혼자 하는 행동은 10, 환경에 불붙이기는 8
func _diff_for(s: Dictionary, t: Dictionary) -> int:
	if t.get("k", "") == "o":
		return 8
	if s.target == "enemy" and t.get("k", "") == "u":
		return eff_def(unit(t.uid))
	return 10


func _is_attack(aid: String) -> bool:
	return Defs.SKILLS.has(aid) and Defs.SKILLS[aid].target == "enemy"


# ── 동료 행동 ───────────────────────────────────────

func act(u: Unit, aid: String, t: Dictionary, locks := 0) -> void:
	var rd := _redirect(aid, t)
	aid = rd[0]
	t = rd[1]
	u.n_act += 1
	# 결의: 행동할 때마다 +15 (판정 성공 칸 +8, 맞으면 +12). 대략 3턴에 한 번 궁극기
	if aid != u.ult:
		u.resolve = mini(100, u.resolve + 15)
	if aid == "guard":
		_pose(u, "skill")
		add_st(u, "guard", 1)
		u.resolve = mini(100, u.resolve + 10)
		_log("%s 방어 자세" % u.name)
		return
	var pv := preview(u, aid, t)
	locks = clampi(locks, 0, mini(fate, pv.n - pv.auto))
	fate -= locks
	if aid.begins_with("env:"):
		_env(u, aid, t, locks)
		return
	var s: Dictionary = Defs.SKILLS[aid]
	if s.has("cd"):
		u.cd[aid] = s.cd
	if aid == u.ult:
		u.resolve = 0
		events.append({"t": "cutin", "uid": u.uid})
		_log("%s 궁극기: %s" % [u.name, s.name])
		_ult(u, s)
		return
	var tu: Unit = unit(t.uid) if t.get("k", "") == "u" else null
	_pose(u, "attack" if aid == u.skills[0] else "skill", tu.uid if tu != null and tu.side == "enemy" else -1, t.id if t.get("k", "") == "o" else -1)
	var ok_n := roll_slots(u, s.name, pv.n, bonus_of(u, s.stat), pv.diff, locks, pv.auto)
	var perfect: bool = ok_n == pv.n
	if pv.auto > 0:
		u.st.erase("stealth")
	if ok_n == 0:
		_log("  실패…")
		if tu != null:
			_float(tu, "빗나감", GRAY)
		return
	if t.get("k", "") == "o":
		_ignite(obj(t.id))
		return
	match s.get("effect", ""):
		"taunt":
			for e in side_units("enemy"):
				e.st["taunt"] = ok_n
			_float(u, "도발 %d턴" % ok_n, PURPLE)
			add_st(u, "guard", 1)
			_log("  적 전원이 %d턴 동안 리나를 노린다" % ok_n)
		"smoke":
			add_st(u, "stealth", 2)
			if perfect:
				for a in side_units("ally"):
					add_st(a, "smoke", 1)
				_log("  연막: 동료 전원 방어 +3")
		"heal":
			heal(tu, scaled(s.power, ok_n, pv.n))
		"bless":
			add_st(tu, "bless", ok_n)
			if perfect:
				add_st(tu, "guard", 1)
		_:
			if perfect and pv.n > 1:
				_float(u, "완벽!", GOLD)
			hurt(tu, scaled(s.power, ok_n, pv.n), "←" + s.name)
			if s.get("fire", false):
				add_st(tu, "burn", 2)
			if perfect and s.get("perfect", "") == "stun":
				add_st(tu, "stun", 1)


func _ult(u: Unit, s: Dictionary) -> void:
	_pose(u, "skill")
	match s.target:
		"all_enemies":
			for e in side_units("enemy"):
				hurt(e, s.power, "←" + s.name)
		"all_allies":
			for a in side_units("ally", true):
				for k in ["stun", "burn"]:
					a.st.erase(k)
				heal(a, s.power)
		"self":
			add_st(u, "oath", 2)
			_log("  2라운드 동안 동료가 받을 공격을 리나가 대신 받는다")


## 불꽃이 환경에 닿았다 (판정 없이 터진다)
func _ignite(o: Dictionary) -> void:
	var d: Dictionary = Defs.OBJECTS[o.key]
	o.used = true
	match d.fire:
		"explode":
			events.append({"t": "obj", "id": o.id, "fx": "explode"})
			_log("  %s에 불이 붙어 터졌다!" % o.name)
			for e in side_units("enemy"):
				hurt(e, d.power, "(폭발)")
				add_st(e, "burn", 2)
		"burn_cover":
			events.append({"t": "obj", "id": o.id, "fx": "burn"})
			_log("  %s가 불탄다! 엄폐가 사라졌다" % o.name)
			var e := unit(o.cover)
			if e != null and e.alive():
				e.st.erase("cover")
				hurt(e, 5, "(불)")
				add_st(e, "burn", 2)


func _env(u: Unit, aid: String, t: Dictionary, locks: int) -> void:
	var o := obj(int(aid.get_slice(":", 1)))
	var a: Dictionary = Defs.OBJECTS[o.key].acts[0]
	var tu: Unit = unit(t.uid) if t.get("k", "") == "u" else null
	_pose(u, "skill", -1, o.id)
	var ok_n := roll_slots(u, a.name, a.slots, bonus_of(u, a.stat), a.diff, locks)
	var perfect: bool = ok_n == a.slots and a.slots > 1
	if ok_n == 0:
		_log("  실패…")
		_float(u, "실패", GRAY)
		return
	if not Defs.OBJECTS[o.key].get("reuse", false):
		o.used = true
	match a.effect:
		"explode":
			events.append({"t": "obj", "id": o.id, "fx": "explode"})
			for e in side_units("enemy"):
				hurt(e, scaled(a.power, ok_n, a.slots), "(%s)" % o.name)
				add_st(e, "burn", 2)
		"crush":
			events.append({"t": "obj", "id": o.id, "fx": "crush", "to": tu.uid})
			var dmg := scaled(a.power, ok_n, a.slots)
			var near: Unit = null
			if a.get("splash", false):
				for e in side_units("enemy"):
					if e != tu and (near == null or absi(e.slot - tu.slot) < absi(near.slot - tu.slot)):
						near = e
			hurt(tu, dmg, "(%s)" % o.name)
			if perfect:
				add_st(tu, "stun", 1)
			if near != null:
				hurt(near, dmg / 2, "(%s)" % o.name)
		"break_cover":
			events.append({"t": "obj", "id": o.id, "fx": "crush"})
			var e := unit(o.cover)
			if e != null and e.alive():
				e.st.erase("cover")
				_log("  %s의 엄폐가 사라졌다" % e.name)
				if perfect:
					add_st(e, "stun", 1)
		"hide":
			add_st(u, "stealth", 2)
		"cover_self":
			add_st(u, "cover", 1)


# ── 적 행동 ─────────────────────────────────────────

func enemy_act(e: Unit) -> void:
	e.n_act += 1
	var allies := side_units("ally")
	if allies.is_empty():
		return
	if e.boss and e.n_act % 3 == 0:
		_pose(e, "attack")
		_log("%s 휩쓸기! (동료 전원, 난이도 13)" % e.name)
		var ok_n := roll_slots(e, "휩쓸기", 2, e.atk, 13)
		if ok_n == 0:
			_log("  모두 피했다")
		for a in allies:
			hurt(_guarded(a), scaled(7, ok_n, 2), "←휩쓸기")
		return
	var t := _pick_target(e, allies)
	_pose(e, "attack", t.uid)
	var ok_n := roll_slots(e, "공격 → %s" % t.name, e.slots, e.atk, eff_def(t))
	if ok_n == 0:
		_float(t, "빗나감", GRAY)
		return
	hurt(_guarded(t), scaled(e.power, ok_n, e.slots), "←" + e.name)


func _pick_target(e: Unit, allies: Array) -> Unit:
	if has_st(e, "taunt"):
		for a in allies:
			if a.key == "lina":
				return a
	var seen: Array = allies.filter(func(a): return not has_st(a, "stealth"))
	if seen.is_empty():
		seen = allies
	if rng.randf() < 0.55:
		var low: Unit = seen[0]
		for a in seen:
			if a.hp < low.hp:
				low = a
		return low
	return seen[rng.randi() % seen.size()]


## 기사의 맹세: 리나가 동료 대신 맞는다
func _guarded(t: Unit) -> Unit:
	for a in side_units("ally"):
		if a != t and has_st(a, "oath"):
			_float(a, "대신 받기", GOLD)
			return a
	return t


# ── 자동 행동 (데모, 시뮬레이션) ────────────────────

func auto_act(u: Unit) -> void:
	var acts: Dictionary = {}
	for a in actions_for(u):
		if a.ready:
			acts[a.id] = a
	var enemies := side_units("enemy")
	var low_e: Unit = enemies[0]
	for e in enemies:
		if e.hp < low_e.hp:
			low_e = e
	var hit_low := {"k": "u", "uid": low_e.uid}
	var locks := 1 if fate >= 2 else 0
	if acts.has(u.ult):
		act(u, u.ult, {"k": "self"})
		return
	if u.key == "miriam" and acts.has("miriam_heal"):
		var hurt_a: Unit = null
		for a in side_units("ally", true):
			if a.downed or a.hp * 2 < a.max_hp:
				hurt_a = a
				break
		if hurt_a != null:
			act(u, "miriam_heal", {"k": "u", "uid": hurt_a.uid}, locks)
			return
	if u.key == "lina" and acts.has("lina_taunt"):
		for a in side_units("ally"):
			if a != u and a.hp * 5 < a.max_hp * 3:
				act(u, "lina_taunt", {"k": "self"})
				return
	if u.key == "adelheid" and acts.has("adel_fire") and enemies.size() >= 2:
		for o in objects:
			if flammable(o) and Defs.OBJECTS[o.key].fire == "explode":
				act(u, "adel_fire", {"k": "o", "id": o.id})
				return
	# 환경: 엄폐한 적이 있으면 방책을 치우고, 적이 많으면 크게 한 방
	var envs: Array = []
	for o in objects:
		envs += obj_actions(u, o.id).filter(func(x): return x.ready)
	for a in envs:
		var ea := env_act(a.id)
		if ea.has("skill"):
			continue
		if ea.effect == "break_cover" and u.key == "lina":
			act(u, a.id, {"k": "self"}, locks)
			return
		if ea.effect in ["explode", "crush"] and enemies.size() >= 3 and rng.randf() < 0.4:
			act(u, a.id, {"k": "self"} if ea.effect == "explode" else hit_low, locks)
			return
	for sid in [u.skills[1], u.skills[0]]:
		if acts.has(sid) and Defs.SKILLS[sid].target == "enemy":
			act(u, sid, hit_low, locks if Defs.SKILLS[sid].slots >= 3 else 0)
			return
	act(u, "guard", {"k": "self"})
