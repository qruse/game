extends RefCounted
## 전투 규칙 (docs/05-combat.md). 화면과 분리된 로직이라 헤드리스 시뮬레이션(sim.gd)에서도 그대로 돈다.
## 화면에 보여 줄 일은 events 배열에 쌓고, 화면 쪽(main.gd)이 꺼내 쓴다.

const Defs = preload("res://scripts/defs.gd")

const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const FLOOR := [".", ",", "^", "\"", "~", "=", "t"]
const OBJECTS := ["#", "o", "h"]
const COVER := ["#", "h"]
const BUFFS := ["bless", "guard", "oath"]
const DEBUFFS := ["stun", "sleep", "root", "taunt", "burn"]
const FATE_MAX := 3
const NO_CELL := Vector2i(-1, -1)

const RED := Color(1.0, 0.42, 0.38)
const GREEN := Color(0.55, 1.0, 0.55)
const GRAY := Color(0.82, 0.82, 0.82)
const GOLD := Color(1.0, 0.85, 0.4)
const PURPLE := Color(0.85, 0.62, 1.0)
const ORANGE := Color(1.0, 0.62, 0.22)


class Unit:
	var uid := 0
	var key := ""
	var name := ""
	var short := ""
	var role := ""
	var side := ""
	var color := Color.WHITE
	var max_hp := 1
	var hp := 1
	var ac := 10
	var move := 3
	var atk := 0
	var saves := {}
	var melee := true
	var atk_range := 1
	var dmg := ""
	var ai := "melee"
	var traits: Array = []
	var actions: Array = []
	var ult := ""
	var is_boss := false
	var phase2 := false
	var pos := Vector2i.ZERO
	var cooldowns := {}
	var resolve := 0
	var st := {}
	var downed := false
	var removed := false
	var move_left := 0
	var move_at_start := 0
	var acted := false
	var turn_start_pos := Vector2i.ZERO
	var undo_ok := true
	var brand := 0
	var taunter := -1

	func alive() -> bool:
		return not removed and not downed


var rng := RandomNumberGenerator.new()
var title := ""
var cols := 0
var rows := 0
var tiles: Array = []
var fire := {}
var smoke := {}
var obj_hp := {}
var units: Array = []
var round_no := 0
var fate: Array = []
var brand_used := false
var events: Array = []
var result := ""
var star_rounds := 4
var downs := 0
var _next_uid := 1


# ── 준비 ─────────────────────────────────────────

func setup(map_path: String, party: Array) -> void:
	rng.randomize()
	var text := FileAccess.get_file_as_string(map_path)
	var enemy_keys: Array = []
	var boss_key := ""
	var grid: Array = []
	var first := true
	for raw in text.split("\n"):
		var line: String = raw.strip_edges()
		if line == "":
			continue
		if first and line.begins_with("#"):
			title = line.trim_prefix("#").strip_edges()
			first = false
			continue
		first = false
		if line.begins_with("enemies:"):
			enemy_keys = Array(line.trim_prefix("enemies:").strip_edges().split(" ", false))
		elif line.begins_with("boss:"):
			boss_key = line.trim_prefix("boss:").strip_edges()
		elif line.begins_with("stars:"):
			star_rounds = int(line.trim_prefix("stars:").strip_edges())
		else:
			grid.append(Array(line.split(" ", false)))
	rows = grid.size()
	cols = grid[0].size()
	var ally_cells: Array = []
	var enemy_cells: Array = []
	var boss_cell := NO_CELL
	tiles = []
	for y in rows:
		var row: Array = []
		for x in cols:
			var t: String = grid[y][x]
			var c := Vector2i(x, y)
			if t == "A":
				ally_cells.append(c)
				t = "."
			elif t == "E":
				enemy_cells.append(c)
				t = "."
			elif t == "B":
				boss_cell = c
				t = "."
			if t == "#":
				obj_hp[c] = 5
			row.append(t)
		tiles.append(row)
	for i in mini(party.size(), ally_cells.size()):
		units.append(_make_ally(party[i], ally_cells[i]))
	var counts := {}
	for k in enemy_keys:
		counts[k] = counts.get(k, 0) + 1
	var seen := {}
	for i in mini(enemy_keys.size(), enemy_cells.size()):
		var k: String = enemy_keys[i]
		var e := _make_enemy(k, enemy_cells[i])
		if counts[k] > 1:
			seen[k] = seen.get(k, 0) + 1
			e.name += " %d" % seen[k]
		units.append(e)
	if boss_key != "" and boss_cell != NO_CELL:
		units.append(_make_enemy(boss_key, boss_cell))
	fate = [d(20), d(20)]
	_log(title)
	_log("운명 주사위를 굴렸다: [%d] [%d]" % [fate[0], fate[1]])


func _make_ally(key: String, pos: Vector2i) -> Unit:
	var d: Dictionary = Defs.ALLIES[key]
	var u := Unit.new()
	u.uid = _next_uid
	_next_uid += 1
	u.key = key
	u.side = "ally"
	u.name = d.name
	u.short = d.short
	u.role = d.role
	u.color = d.color
	u.max_hp = d.hp
	u.hp = d.hp
	u.ac = d.ac
	u.move = d.move
	u.atk = d.atk
	u.saves = d.saves
	u.melee = d.melee
	u.atk_range = 1 if d.melee else 4
	u.ai = "melee" if d.melee else "ranged"
	u.traits = d.traits.duplicate()
	u.actions = d.actions.duplicate()
	u.ult = d.ult
	u.pos = pos
	u.turn_start_pos = pos
	return u


func _make_enemy(key: String, pos: Vector2i) -> Unit:
	var d: Dictionary = Defs.ENEMIES[key]
	var u := Unit.new()
	u.uid = _next_uid
	_next_uid += 1
	u.key = key
	u.side = "enemy"
	u.name = d.name
	u.short = d.short
	u.role = "보스" if d.get("boss", false) else ""
	u.color = d.get("color", Color(0.42, 0.16, 0.14))
	u.max_hp = d.hp
	u.hp = d.hp
	u.ac = d.ac
	u.move = d.move
	u.atk = d.atk
	u.saves = d.saves
	u.dmg = d.dmg
	u.atk_range = d["range"]
	u.melee = u.atk_range == 1
	u.ai = d.ai
	u.is_boss = d.get("boss", false)
	u.pos = pos
	u.turn_start_pos = pos
	return u


# ── 기본 도구 ───────────────────────────────────────

func d(sides: int) -> int:
	return rng.randi_range(1, sides)


## "1d6+3", "1d4+3+2d6" 같은 식을 굴린다. 대성공이면 주사위 개수를 두 배로.
func roll(expr: String, crit := false) -> int:
	var total := 0
	for part in expr.replace("-", "+-").split("+", false):
		if "d" in part:
			var p: PackedStringArray = part.split("d")
			var n := int(p[0])
			if crit:
				n *= 2
			for i in n:
				total += d(int(p[1]))
		else:
			total += int(part)
	return maxi(total, 0)


func expr_range(expr: String) -> Vector2i:
	var lo := 0
	var hi := 0
	for part in expr.replace("-", "+-").split("+", false):
		if "d" in part:
			var p: PackedStringArray = part.split("d")
			lo += int(p[0])
			hi += int(p[0]) * int(p[1])
		else:
			lo += int(part)
			hi += int(part)
	return Vector2i(lo, hi)


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < cols and c.y < rows


func tile(c: Vector2i) -> String:
	if not in_bounds(c):
		return "X"
	return tiles[c.y][c.x]


func set_tile(c: Vector2i, t: String) -> void:
	tiles[c.y][c.x] = t


func is_floor(c: Vector2i) -> bool:
	return tile(c) in FLOOR


func is_object(c: Vector2i) -> bool:
	return tile(c) in OBJECTS


func enter_cost(c: Vector2i) -> int:
	return 2 if tile(c) in [",", "^", "~", "="] else 1


func dist(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func unit_at(c: Vector2i) -> Unit:
	for u in units:
		if not u.removed and u.pos == c:
			return u
	return null


func side_units(side: String, include_downed := false) -> Array:
	var out: Array = []
	for u in units:
		if u.side == side and not u.removed and (include_downed or not u.downed):
			out.append(u)
	return out


func opp(side: String) -> String:
	return "enemy" if side == "ally" else "ally"


func has_st(u: Unit, s: String) -> bool:
	return u.st.get(s, 0) > 0


func status_names(u: Unit) -> Array:
	var out: Array = []
	for k in u.st.keys():
		if u.st[k] > 0:
			out.append(Defs.STATUS.get(k, k))
	return out


func _square(c: Vector2i) -> Array:
	var out: Array = []
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var cc := c + Vector2i(dx, dy)
			if in_bounds(cc):
				out.append(cc)
	return out


func _sg(n: int) -> String:
	return ("+%d" % n) if n >= 0 else str(n)


func _log(t: String) -> void:
	events.append({"t": "log", "text": t})


func _float(c: Vector2i, text: String, col: Color) -> void:
	events.append({"t": "float", "cell": c, "text": text, "color": col})


func _move_ev(u: Unit, path: Array) -> void:
	events.append({"t": "move", "uid": u.uid, "path": path.duplicate()})


# ── 이동 ────────────────────────────────────────────

## 이동 가능한 칸과 비용. 같은 편은 지나갈 수 있고 적은 막는다.
func reachable(u: Unit, budget: int) -> Dictionary:
	var cost := {u.pos: 0}
	var prev := {}
	var open: Array = [u.pos]
	while not open.is_empty():
		var bi := 0
		for i in range(1, open.size()):
			if cost[open[i]] < cost[open[bi]]:
				bi = i
		var cur: Vector2i = open[bi]
		open.remove_at(bi)
		for dd in DIRS:
			var n: Vector2i = cur + dd
			if not is_floor(n):
				continue
			var o := unit_at(n)
			if o != null and o.side != u.side:
				continue
			var nc: int = cost[cur] + enter_cost(n)
			if nc > budget:
				continue
			if not cost.has(n) or nc < cost[n]:
				cost[n] = nc
				prev[n] = cur
				open.append(n)
	return {"cost": cost, "prev": prev}


func path_to(reach: Dictionary, c: Vector2i) -> Array:
	var prev: Dictionary = reach["prev"]
	var path: Array = []
	var cur := c
	while prev.has(cur):
		path.push_front(cur)
		cur = prev[cur]
	return path


func move_targets(u: Unit) -> Array:
	if u.move_left <= 0 or has_st(u, "root"):
		return []
	var out: Array = []
	var rc: Dictionary = reachable(u, u.move_left)["cost"]
	for c in rc.keys():
		if c != u.pos and unit_at(c) == null:
			out.append(c)
	return out


## 그 칸까지 가는 길에 기회 공격을 받는가 (이동 전 경고용)
func provokes(u: Unit, cell: Vector2i) -> bool:
	if "slip" in u.traits:
		return false
	var reach := reachable(u, u.move_left)
	var from := u.pos
	for c in path_to(reach, cell):
		for e in units:
			if e.side != u.side and e.alive() and e.melee and dist(e.pos, from) == 1 and dist(e.pos, c) > 1:
				return true
		from = c
	return false


func move_ally(u: Unit, cell: Vector2i) -> void:
	var reach := reachable(u, u.move_left)
	if not reach["cost"].has(cell) or unit_at(cell) != null:
		return
	move_unit(u, path_to(reach, cell))


func move_unit(u: Unit, path: Array) -> void:
	var spent := 0
	for c in path:
		var cc: Vector2i = c
		_opportunity(u, u.pos, cc)
		if not u.alive():
			break
		spent += enter_cost(cc)
		u.pos = cc
		_move_ev(u, [cc])
		if _enter_tile(u, cc) or not u.alive():
			break
	u.move_left = maxi(0, u.move_left - spent)
	if u.alive() and "bush_stealth" in u.traits and tile(u.pos) == "\"" and not has_st(u, "stealth"):
		u.st["stealth"] = 1
		_float(u.pos, "은신", PURPLE)
		_log("%s: 덤불 속에 숨었다" % u.name)


func _opportunity(mover: Unit, from: Vector2i, to: Vector2i) -> void:
	if "slip" in mover.traits:
		return
	for e in units.duplicate():
		if e.side == mover.side or not e.alive() or not e.melee:
			continue
		if has_st(e, "stun") or has_st(e, "sleep"):
			continue
		if dist(e.pos, from) == 1 and dist(e.pos, to) > 1:
			_log("%s의 기회 공격" % e.name)
			mover.undo_ok = false
			_basic_hit(e, mover)
			if not mover.alive():
				return


## 칸에 들어갈 때의 효과. true면 이동을 멈춘다.
func _enter_tile(u: Unit, c: Vector2i) -> bool:
	var stop := false
	if tile(c) == "t":
		set_tile(c, ".")
		_log("%s: 숨은 함정을 밟았다" % u.name)
		_float(c, "함정!", ORANGE)
		damage(u, roll("1d6"))
		u.st["root"] = 2
		u.undo_ok = false
		stop = true
	if fire.has(c) and u.alive():
		u.undo_ok = false
		_fire_hurt(u)
	return stop


func can_undo(u: Unit) -> bool:
	return u.side == "ally" and u.undo_ok and not u.acted and u.pos != u.turn_start_pos


func undo_move(u: Unit) -> void:
	if not can_undo(u):
		return
	u.pos = u.turn_start_pos
	u.move_left = u.move_at_start
	u.st.erase("stealth")
	_log("%s: 이동 되돌리기" % u.name)


# ── 굴림 ────────────────────────────────────────────

func roll_d20(u: Unit, adv: int, fixed := 0) -> Dictionary:
	if fixed > 0:
		return {"v": fixed, "txt": "운명 %d" % fixed, "fate": true}
	if u.brand > 0:
		var bv := u.brand
		u.brand = 0
		return {"v": bv, "txt": "낙인 %d" % bv, "fate": true}
	var a := d(20)
	if adv == 0:
		return {"v": a, "txt": str(a), "fate": false}
	var b := d(20)
	if adv > 0:
		return {"v": maxi(a, b), "txt": "%d,%d 유리" % [a, b], "fate": false}
	return {"v": mini(a, b), "txt": "%d,%d 불리" % [a, b], "fate": false}


## 유리(+1) / 불리(-1) / 보통(0). 05-combat.md 5.2절
func adv_state(att: Unit, tgt: Unit, ranged: bool, opts := {}) -> int:
	var adv := 0
	var dis := 0
	if opts.get("adv", false):
		adv += 1
	if not opts.get("plain", false):
		if ranged:
			if tile(att.pos) == "^" and tile(tgt.pos) != "^":
				adv += 1
			if _covered(att.pos, tgt.pos):
				dis += 1
			if tile(tgt.pos) == "\"":
				dis += 1
			for e in units:
				if e.side != att.side and e.alive() and dist(e.pos, att.pos) == 1:
					dis += 1
					break
		else:
			var o := unit_at(tgt.pos * 2 - att.pos)
			if dist(att.pos, tgt.pos) == 1 and o != null and o.side == att.side and o.alive():
				adv += 1
			if has_st(tgt, "prone"):
				adv += 1
	if has_st(att, "stealth"):
		adv += 1
	if smoke.has(tgt.pos):
		dis += 1
	return (1 if adv > 0 else 0) - (1 if dis > 0 else 0)


func adv_reasons(att: Unit, tgt: Unit, ranged: bool) -> Array:
	var out: Array = []
	if ranged and tile(att.pos) == "^" and tile(tgt.pos) != "^":
		out.append("높은 곳")
	if not ranged:
		var o := unit_at(tgt.pos * 2 - att.pos)
		if dist(att.pos, tgt.pos) == 1 and o != null and o.side == att.side and o.alive():
			out.append("협공")
		if has_st(tgt, "prone"):
			out.append("넘어짐")
	if has_st(att, "stealth"):
		out.append("은신")
	if ranged and _covered(att.pos, tgt.pos):
		out.append("엄폐(불리)")
	if ranged and tile(tgt.pos) == "\"":
		out.append("덤불(불리)")
	if smoke.has(tgt.pos):
		out.append("연기(불리)")
	if ranged:
		for e in units:
			if e.side != att.side and e.alive() and dist(e.pos, att.pos) == 1:
				out.append("적이 붙음(불리)")
				break
	return out


func _covered(from: Vector2i, to: Vector2i) -> bool:
	var dv := from - to
	var cells: Array = []
	if dv.x != 0 and absi(dv.x) >= absi(dv.y):
		cells.append(to + Vector2i(signi(dv.x), 0))
	if dv.y != 0 and absi(dv.y) >= absi(dv.x):
		cells.append(to + Vector2i(0, signi(dv.y)))
	for c in cells:
		if c != from and tile(c) in COVER:
			return true
	return false


func hit_mod(att: Unit, tgt: Unit, ranged: bool) -> int:
	if not ranged and tile(att.pos) == "^" and tile(tgt.pos) != "^":
		return 1
	return 0


func eff_ac(u: Unit) -> int:
	var ac := u.ac
	if has_st(u, "guard"):
		ac += 2
	if has_st(u, "bless"):
		ac += 2
	for o in units:
		if o != u and o.side == u.side and o.alive() and "guardian" in o.traits and dist(o.pos, u.pos) == 1:
			ac += 1
			break
	return ac


func _p_hit(bonus: int, ac: int) -> float:
	var n := 0
	for v in range(1, 21):
		if v == 20 or (v != 1 and v + bonus >= ac):
			n += 1
	return n / 20.0


func hit_chance(att: Unit, tgt: Unit, ranged: bool, opts := {}) -> float:
	var fixed: int = opts.get("fate", 0)
	var bonus := att.atk + hit_mod(att, tgt, ranged)
	var ac := eff_ac(tgt)
	var blessed := has_st(att, "bless")
	if fixed > 0:
		var b := 1 if blessed else 0
		return 1.0 if (fixed == 20 or (fixed != 1 and fixed + bonus + b >= ac)) else 0.0
	var p := 0.0
	if blessed:
		for b in range(1, 5):
			p += _p_hit(bonus + b, ac)
		p /= 4.0
	else:
		p = _p_hit(bonus, ac)
	var a := adv_state(att, tgt, ranged, opts)
	if a > 0:
		p = 1.0 - (1.0 - p) * (1.0 - p)
	elif a < 0:
		p = p * p
	return p


func attack(att: Unit, tgt: Unit, dmg: String, ranged: bool, opts := {}) -> bool:
	var a := adv_state(att, tgt, ranged, opts)
	var fixed: int = opts.get("fate", 0)
	if fixed > 0:
		a = 0
	var r := roll_d20(att, a, fixed)
	var bonus := att.atk + hit_mod(att, tgt, ranged)
	if has_st(att, "bless"):
		bonus += d(4)
	var ac := eff_ac(tgt)
	var v: int = r["v"]
	var crit := v == 20
	var hit := crit or (v != 1 and v + bonus >= ac)
	att.st.erase("stealth")
	var res := "대성공!" if crit else ("명중" if hit else "빗나감")
	_log("%s → %s: d20[%s] %s = %d vs AC %d · %s" % [att.name, tgt.name, r["txt"], _sg(bonus), v + bonus, ac, res])
	if att.side == "ally" and v == 1 and not r["fate"]:
		fate_gain("자연 1")
	if crit:
		att.resolve = mini(100, att.resolve + 25)
		_float(tgt.pos, "대성공!", GOLD)
	if hit:
		damage(tgt, roll(dmg, crit))
	else:
		_float(tgt.pos, "빗나감", GRAY)
	return hit


func save(u: Unit, ability: String, dc: int) -> bool:
	var r := roll_d20(u, 0)
	var mod: int = u.saves.get(ability, 0)
	if has_st(u, "bless"):
		mod += d(4)
	var v: int = r["v"]
	var ok := v + mod >= dc
	_log("  %s %s 저항: d20[%s] %s = %d vs DC %d · %s" % [u.name, Defs.ABIL[ability], r["txt"], _sg(mod), v + mod, dc, "성공" if ok else "실패"])
	if u.side == "ally" and v == 1 and not r["fate"]:
		fate_gain("자연 1")
	return ok


## 시전자 입장의 성공률 = 대상이 저항에 실패할 확률
func save_fail_chance(u: Unit, ability: String, dc: int) -> float:
	var mod: int = u.saves.get(ability, 0)
	if u.brand > 0:
		return 1.0 if u.brand + mod < dc else 0.0
	var n := 0
	for v in range(1, 21):
		if v + mod < dc:
			n += 1
	return n / 20.0


# ── 피해와 회복 ─────────────────────────────────────

func damage(target: Unit, amount: int) -> void:
	if target.removed or target.downed or amount <= 0:
		return
	var t := target
	if t.side == "ally" and not has_st(t, "oath"):
		for o in units:
			if o != t and o.side == t.side and o.alive() and has_st(o, "oath") and dist(o.pos, t.pos) == 1:
				_log("  %s: 대신 맞는다 (기사의 맹세)" % o.name)
				t = o
				break
	if has_st(t, "oath"):
		amount = ceili(amount / 2.0)
	t.hp -= amount
	_float(t.pos, "-%d" % amount, RED)
	t.st.erase("sleep")
	t.resolve = mini(100, t.resolve + 15)
	if t.hp <= 0:
		t.hp = 0
		if t.side == "ally":
			t.downed = true
			t.st.clear()
			downs += 1
			_log("%s 쓰러짐!" % t.name)
			_float(t.pos, "쓰러짐", RED)
		else:
			t.removed = true
			_log("%s 처치" % t.name)
	elif t.is_boss and not t.phase2 and t.hp * 2 <= t.max_hp:
		_boss_phase2(t)
	_check_end()


func heal(t: Unit, amount: int) -> void:
	if t.removed:
		return
	if t.downed:
		t.downed = false
		t.hp = 0
		t.acted = true
		t.move_left = 0
		_log("%s 일어남" % t.name)
	t.hp = mini(t.max_hp, t.hp + amount)
	_float(t.pos, "+%d" % amount, GREEN)


func _fire_hurt(u: Unit) -> void:
	_log("%s: 불길에 휩싸였다" % u.name)
	damage(u, roll("1d6"))
	if u.alive():
		u.st["burn"] = 2


func _boss_phase2(b: Unit) -> void:
	b.phase2 = true
	_log("%s 분노! 한 턴에 두 번 공격하고, 도적 2명이 증원으로 온다" % b.name)
	_float(b.pos, "분노!", ORANGE)
	var spawned := 0
	for x in range(cols - 1, -1, -1):
		for y in range(rows - 1, -1, -1):
			if spawned >= 2:
				break
			var c := Vector2i(x, y)
			if is_floor(c) and unit_at(c) == null and not fire.has(c):
				var e := _make_enemy("bandit", c)
				e.name = "증원 도적 %d" % (spawned + 1)
				units.append(e)
				_float(c, "증원", ORANGE)
				spawned += 1


func fate_gain(reason: String) -> void:
	var v := d(20)
	fate.append(v)
	_log("운명 주사위 +1 (%s): [%d]" % [reason, v])
	if fate.size() > FATE_MAX:
		# 프로토 단순화: 원래는 플레이어가 고르지만, 가장 애매한(10.5에 가까운) 눈을 버린다
		var wi := 0
		for i in fate.size():
			if absf(fate[i] - 10.5) < absf(fate[wi] - 10.5):
				wi = i
		_log("  주사위가 넘쳐서 [%d]을 버렸다" % fate[wi])
		fate.remove_at(wi)


func place_brand(i: int, e: Unit) -> bool:
	if brand_used or i < 0 or i >= fate.size() or e.side != "enemy" or not e.alive():
		return false
	var v: int = fate[i]
	fate.remove_at(i)
	e.brand = v
	brand_used = true
	_log("운명 낙인 → %s: 다음 d20은 %d" % [e.name, v])
	_float(e.pos, "낙인 %d" % v, PURPLE)
	return true


func _check_end() -> void:
	if result != "":
		return
	if side_units("enemy").is_empty():
		result = "win"
		_log("승리!")
	elif side_units("ally").is_empty():
		result = "lose"
		_log("패배…")


# ── 환경 ────────────────────────────────────────────

func ignite(c: Vector2i) -> void:
	var t := tile(c)
	match t:
		"o":
			_explode(c)
		"h":
			_burn_hay(c)
		"~", "\"":
			for cc in _flood(c, t):
				set_tile(cc, ".")
				_set_fire(cc, true)
		"=", "X", "v", "#":
			pass
		_:
			_set_fire(c, true)


func _set_fire(c: Vector2i, hurt: bool) -> void:
	if not is_floor(c) or tile(c) == "=":
		return
	fire[c] = round_no + 2
	if hurt:
		var u := unit_at(c)
		if u != null and u.alive():
			_fire_hurt(u)


func _flood(start: Vector2i, t: String) -> Array:
	var out: Array = [start]
	var i := 0
	while i < out.size():
		for dd in DIRS:
			var n: Vector2i = out[i] + dd
			if tile(n) == t and not n in out:
				out.append(n)
		i += 1
	return out


func _explode(c: Vector2i) -> void:
	set_tile(c, ".")
	_log("기름 항아리가 터졌다!")
	_float(c, "쾅!", ORANGE)
	var chain: Array = []
	for cc in _square(c):
		var tt := tile(cc)
		if tt in ["o", "h", "~", "\""]:
			chain.append(cc)
			continue
		_set_fire(cc, false)
		var u := unit_at(cc)
		if u != null and u.alive():
			damage(u, roll("2d6"))
			if u.alive():
				u.st["burn"] = 2
	for cc in chain:
		ignite(cc)


func _burn_hay(c: Vector2i) -> void:
	set_tile(c, ".")
	_log("건초 더미에 불이 번진다!")
	_float(c, "화르륵", ORANGE)
	var chain: Array = []
	for y in rows:
		for x in cols:
			var cc := Vector2i(x, y)
			if dist(cc, c) > 2:
				continue
			if tile(cc) in ["o", "h"]:
				chain.append(cc)
			else:
				_set_fire(cc, true)
	for cc in chain:
		ignite(cc)


func _hit_object(c: Vector2i, amount: int) -> void:
	match tile(c):
		"o":
			_explode(c)
		"#":
			obj_hp[c] = obj_hp.get(c, 5) - amount
			_float(c, "-%d" % amount, GRAY)
			if obj_hp[c] <= 0:
				set_tile(c, ".")
				_log("엄폐물이 부서졌다")


func push(att: Unit, tgt: Unit, n: int) -> void:
	if "iron_wall" in tgt.traits:
		_log("  %s: 철벽, 밀리지 않는다" % tgt.name)
		return
	var dv: Vector2i = tgt.pos - att.pos
	var dir := Vector2i(signi(dv.x), signi(dv.y))
	for i in n:
		var nxt: Vector2i = tgt.pos + dir
		if in_bounds(nxt) and tile(nxt) == "v":
			if tgt.is_boss:
				_log("  %s: 벼랑 끝에 매달려 버틴다" % tgt.name)
				damage(tgt, roll("3d6"))
			else:
				_log("  %s: 낭떠러지로 떨어졌다!" % tgt.name)
				_float(tgt.pos, "추락!", ORANGE)
				tgt.hp = 0
				tgt.removed = true
				_check_end()
			return
		var o := unit_at(nxt)
		if not is_floor(nxt) or o != null:
			_log("  %s: 부딪혔다" % tgt.name)
			damage(tgt, roll("1d4"))
			if o != null:
				damage(o, roll("1d4"))
			elif tile(nxt) == "#":
				_hit_object(nxt, roll("1d4"))
			return
		tgt.pos = nxt
		_move_ev(tgt, [nxt])
		_float(nxt, "밀림", GRAY)
		if _enter_tile(tgt, nxt) or not tgt.alive():
			return


## 밀치기 미리보기 문구
func push_note(att: Unit, tgt: Unit) -> String:
	if "iron_wall" in tgt.traits:
		return "철벽이라 밀리지 않음"
	var dv: Vector2i = tgt.pos - att.pos
	var nxt: Vector2i = tgt.pos + Vector2i(signi(dv.x), signi(dv.y))
	if in_bounds(nxt) and tile(nxt) == "v":
		return "보스는 벼랑 끝 3d6" if tgt.is_boss else "낭떠러지로 떨어뜨림!"
	if not is_floor(nxt) or unit_at(nxt) != null:
		return "부딪혀 1d4"
	if fire.has(nxt):
		return "불길로 밀어 넣음"
	return "1칸 밀림"


# ── 턴 진행 ─────────────────────────────────────────

func begin_ally_turn() -> void:
	round_no += 1
	for c in fire.keys():
		if fire[c] <= round_no:
			fire.erase(c)
	for c in smoke.keys():
		if smoke[c] <= round_no:
			smoke.erase(c)
	brand_used = false
	_log("━━ 라운드 %d ━━" % round_no)
	for u in side_units("ally"):
		_turn_start(u)


func end_ally_turn() -> void:
	for u in side_units("ally"):
		_turn_end(u)


func begin_enemy_turn() -> void:
	for e in side_units("enemy"):
		_turn_start(e)


func end_enemy_turn() -> void:
	for e in side_units("enemy"):
		_turn_end(e)


func _turn_start(u: Unit) -> void:
	if not u.alive():
		return
	for s in BUFFS:
		if u.st.has(s):
			u.st[s] -= 1
			if u.st[s] <= 0:
				u.st.erase(s)
	for k in u.cooldowns.keys():
		u.cooldowns[k] = maxi(0, u.cooldowns[k] - 1)
	u.acted = false
	u.undo_ok = true
	u.move_left = u.move
	if u.st.has("prone"):
		u.st.erase("prone")
		u.move_left = floori(u.move / 2.0)
	if has_st(u, "root"):
		u.move_left = 0
	if has_st(u, "stun") or has_st(u, "sleep"):
		u.acted = true
		u.move_left = 0
	u.move_at_start = u.move_left
	u.turn_start_pos = u.pos
	if has_st(u, "burn"):
		_log("%s: 화상" % u.name)
		damage(u, roll("1d4"))
	if u.alive() and fire.has(u.pos):
		_fire_hurt(u)


func _turn_end(u: Unit) -> void:
	for s in DEBUFFS:
		if u.st.has(s):
			u.st[s] -= 1
			if u.st[s] <= 0:
				u.st.erase(s)


# ── 아군 행동 ───────────────────────────────────────

func skill_targets(u: Unit, sid: String) -> Array:
	var s: Dictionary = Defs.SKILLS[sid]
	var rng_: int = s["range"]
	var out: Array = []
	match s.target:
		"self":
			out.append(u.pos)
		"enemy":
			for e in units:
				if e.side != u.side and e.alive() and dist(u.pos, e.pos) <= rng_:
					out.append(e.pos)
			if s.get("obj", false):
				for y in rows:
					for x in cols:
						var c := Vector2i(x, y)
						if tile(c) in ["#", "o"] and dist(u.pos, c) <= rng_:
							out.append(c)
		"ally", "ally_down":
			for a in side_units(u.side, s.target == "ally_down"):
				if dist(u.pos, a.pos) <= rng_:
					out.append(a.pos)
		"tile":
			for y in rows:
				for x in cols:
					var c := Vector2i(x, y)
					if dist(u.pos, c) <= rng_:
						out.append(c)
	return out


func area_of(sid: String, u: Unit, cell: Vector2i) -> Array:
	var out: Array = []
	match sid:
		"lina_taunt":
			for y in rows:
				for x in cols:
					var c := Vector2i(x, y)
					if dist(c, u.pos) <= 2:
						out.append(c)
		"cecile_smoke", "adel_ult":
			out = _square(cell)
		"cecile_ult":
			for e in _ult_targets(u):
				out.append(e.pos)
		"miriam_ult":
			for a in side_units(u.side, true):
				out.append(a.pos)
	return out


func _ult_targets(u: Unit) -> Array:
	var es: Array = side_units(opp(u.side)).filter(func(e): return dist(e.pos, u.pos) <= 4)
	es.sort_custom(func(a, b): return dist(a.pos, u.pos) < dist(b.pos, u.pos))
	return es.slice(0, 3)


func help_targets(u: Unit) -> Array:
	var out: Array = []
	for a in side_units(u.side, true):
		if a.downed and dist(a.pos, u.pos) == 1:
			out.append(a.pos)
	return out


func swap_targets(u: Unit) -> Array:
	var out: Array = []
	if not "guide" in u.traits or u.move_left <= 0 or u.move_left < u.move_at_start or has_st(u, "root"):
		return out
	for a in side_units(u.side):
		if a != u and dist(a.pos, u.pos) == 1:
			out.append(a.pos)
	return out


func help_up(u: Unit, cell: Vector2i) -> void:
	var t := unit_at(cell)
	if t == null or not t.downed or u.acted:
		return
	_log("%s: %s를 일으켜 세웠다" % [u.name, t.name])
	heal(t, 1)
	_after_action(u, "")


func swap(u: Unit, cell: Vector2i) -> void:
	var t := unit_at(cell)
	if t == null or not cell in swap_targets(u):
		return
	var p := u.pos
	u.pos = t.pos
	t.pos = p
	_move_ev(u, [u.pos])
	_move_ev(t, [t.pos])
	u.move_left = 0
	u.undo_ok = false
	_log("%s: %s와 자리를 바꿨다 (인도)" % [u.name, t.name])


func guard(u: Unit) -> void:
	if u.acted:
		return
	u.st["guard"] = 1
	_float(u.pos, "방어", GRAY)
	_log("%s: 방어 자세 (AC +2)" % u.name)
	_after_action(u, "")


func _after_action(u: Unit, sid: String) -> void:
	u.acted = true
	u.undo_ok = false
	if sid != "" and sid == u.ult:
		u.resolve = 0
	else:
		u.resolve = mini(100, u.resolve + 25)
	if sid != "":
		var cd: int = Defs.SKILLS[sid].get("cd", 0)
		if cd > 0:
			u.cooldowns[sid] = cd
	_check_end()


func _attack_or_object(u: Unit, cell: Vector2i, dmg: String, ranged: bool, opts: Dictionary) -> bool:
	var t := unit_at(cell)
	if t != null and t.alive():
		return attack(u, t, dmg, ranged, opts)
	if tile(cell) in ["#", "o"]:
		_log("%s: %s을 쳤다" % [u.name, "기름 항아리" if tile(cell) == "o" else "엄폐물"])
		_hit_object(cell, roll(dmg))
	return false


func use_skill(u: Unit, sid: String, cell: Vector2i, fate_idx := -1) -> void:
	if u.acted:
		return
	var s: Dictionary = Defs.SKILLS[sid]
	var fv := 0
	if fate_idx >= 0 and fate_idx < fate.size() and s.get("attack", false):
		fv = fate[fate_idx]
		fate.remove_at(fate_idx)
	_log("— %s: %s" % [u.name, s.name])
	var dc := 8 + u.atk
	var tgt := unit_at(cell)
	match sid:
		"lina_basic", "miriam_basic", "adel_basic":
			_attack_or_object(u, cell, s.dmg, s.get("ranged", false), {"fate": fv})
		"cecile_basic":
			if tgt == null:
				_attack_or_object(u, cell, s.dmg, false, {})
			else:
				for i in 2:
					if tgt.alive():
						attack(u, tgt, s.dmg, false, {"fate": fv if i == 0 else 0})
		"lina_bash":
			if tgt != null and attack(u, tgt, s.dmg, false, {"fate": fv}) and tgt.alive():
				if "iron_wall" in tgt.traits or not save(tgt, "str", dc):
					push(u, tgt, 1)
		"lina_taunt":
			for e in side_units(opp(u.side)):
				if dist(e.pos, u.pos) <= 2 and not save(e, "cha", dc):
					e.st["taunt"] = 1
					e.taunter = u.uid
					_float(e.pos, "도발", ORANGE)
		"lina_ult":
			u.st["oath"] = 2
			_float(u.pos, "기사의 맹세", GOLD)
		"cecile_ambush":
			if tgt != null:
				attack(u, tgt, s.dmg, false, {"adv": true, "fate": fv})
		"cecile_smoke":
			for c in _square(cell):
				smoke[c] = round_no + 2
				var a := unit_at(c)
				if a != null and a.side == u.side and a.alive():
					a.st["stealth"] = 1
					_float(c, "은신", PURPLE)
		"cecile_ult":
			_float(u.pos, "그림자 난무", GOLD)
			for e in _ult_targets(u):
				attack(u, e, s.dmg, false, {"plain": true})
		"adel_basic_unused":
			pass
		"adel_fire":
			if tgt != null and tgt.side != u.side and tgt.alive():
				attack(u, tgt, s.dmg, true, {"fate": fv})
			_log("  불이 붙었다")
			ignite(cell)
		"adel_frost":
			if tgt != null and attack(u, tgt, s.dmg, true, {"fate": fv}) and tgt.alive():
				if not save(tgt, "str", dc):
					tgt.st["root"] = 2
					_float(tgt.pos, "속박", Color(0.6, 0.85, 1.0))
		"adel_ult":
			_float(cell, "금서 해방", GOLD)
			for c in _square(cell):
				var e := unit_at(c)
				if e != null and e.side != u.side and e.alive():
					var amt := roll(s.dmg)
					if save(e, "dex", dc):
						amt = floori(amt / 2.0)
					damage(e, amt)
		"miriam_heal":
			if tgt != null:
				heal(tgt, roll(s.dmg))
		"miriam_bless":
			if tgt != null:
				tgt.st["bless"] = 2
				_float(tgt.pos, "축복", GOLD)
		"miriam_ult":
			_float(u.pos, "빛의 기둥", GOLD)
			for a in side_units(u.side, true):
				for k in ["burn", "stun", "root", "sleep", "prone", "taunt"]:
					a.st.erase(k)
				heal(a, roll(s.dmg))
	_after_action(u, sid)


func preview_text(u: Unit, sid: String, cell: Vector2i, fv: int) -> String:
	match sid:
		"help":
			return "일으키기 · 쓰러진 동료를 HP 1로 일으킨다"
		"swap":
			return "인도 · 이동 대신 자리를 바꾼다"
	var s: Dictionary = Defs.SKILLS[sid]
	var t := unit_at(cell)
	var parts: Array = [s.name]
	var dc := 8 + u.atk
	if s.get("attack", false) and t != null and t.side != u.side and t.alive():
		var ranged: bool = s.get("ranged", false)
		var opts := {"fate": fv, "adv": s.get("adv", false)}
		var p := hit_chance(u, t, ranged, opts)
		parts.append("→ %s" % t.name)
		if fv > 0:
			parts.append("운명 %d → %s" % [fv, "명중 확정" if p >= 1.0 else "빗나감 확정"])
		else:
			var hs := "명중 %d%%" % roundi(p * 100.0)
			var rs := adv_reasons(u, t, ranged)
			if s.get("adv", false):
				rs.push_front("기습")
			if not rs.is_empty():
				hs += " (" + ", ".join(PackedStringArray(rs)) + ")"
			parts.append(hs)
		var rg := expr_range(s.dmg)
		var dtxt := "피해 %d~%d" % [rg.x, rg.y]
		if s.get("hits", 1) > 1:
			dtxt += " × %d회" % s.hits
		parts.append(dtxt)
		if sid == "lina_bash":
			parts.append("밀치기 %d%% · %s" % [roundi(save_fail_chance(t, "str", dc) * 100.0), push_note(u, t)])
		elif sid == "adel_frost":
			parts.append("속박 성공률 %d%%" % roundi(save_fail_chance(t, "str", dc) * 100.0))
	elif s.get("obj", false) and tile(cell) in ["#", "o"]:
		parts.append("기름 항아리를 깨뜨려 폭발 (주변 3×3 2d6 + 불)" if tile(cell) == "o" else "엄폐물 부수기 (HP %d)" % obj_hp.get(cell, 5))
	match sid:
		"adel_fire":
			var tn: String = {"~": "기름 → 이어진 기름 전체가 화염 지대", "\"": "덤불 → 이어진 덤불 전체가 화염 지대", "o": "기름 항아리 → 폭발", "h": "건초 더미 → 2칸까지 번짐", "=": "물이라 불이 붙지 않음"}.get(tile(cell), "이 칸에 불 (2라운드)")
			parts.append(tn)
			var a := unit_at(cell)
			if a != null and a.side == u.side:
				parts.append("주의: 아군이 서 있음")
		"lina_taunt":
			var n := 0
			for e in side_units(opp(u.side)):
				if dist(e.pos, u.pos) <= 2:
					n += 1
			parts.append("반경 2칸 적 %d명 · 도발 1턴 (DC %d 매력)" % [n, dc])
		"cecile_smoke":
			parts.append("3×3 연기 2라운드 · 안의 아군 은신")
		"cecile_ult":
			parts.append("대상 %d명 · 각 피해 5~11" % _ult_targets(u).size())
		"adel_ult":
			var n2 := 0
			for c in _square(cell):
				var e := unit_at(c)
				if e != null and e.side != u.side and e.alive():
					n2 += 1
			parts.append("범위 안 적 %d명 · 4~24 (민첩 저항 시 절반, DC %d)" % [n2, dc])
		"miriam_heal":
			parts.append("회복 5~19" + (" · 일으킴" if t != null and t.downed else ""))
		"miriam_bless":
			parts.append("축복 + AC +2, 2턴")
		"miriam_ult":
			parts.append("아군 전원 3~24 회복 + 상태이상 해제")
		"lina_ult":
			parts.append("2턴 동안 인접 아군 피해를 대신 받고 절반만 받음")
	return " · ".join(PackedStringArray(parts))


# ── 자동 행동 (적 AI, 시뮬레이션용 아군 AI) ─────────

func enemy_act(e: Unit) -> void:
	if not e.alive() or result != "":
		return
	if has_st(e, "stun") or has_st(e, "sleep"):
		_float(e.pos, "행동 불가", GRAY)
		return
	if e.ai == "ranged":
		_ai_ranged(e)
	else:
		_ai_melee(e)


## 시뮬레이션용 단순 아군 AI: 다가가서 쓸 수 있는 가장 센 행동을 쓴다
func auto_act(u: Unit) -> void:
	if not u.alive() or u.acted or result != "":
		return
	if u.key == "miriam" and u.cooldowns.get("miriam_heal", 0) == 0:
		for a in side_units("ally", true):
			if (a.downed or a.hp * 2 < a.max_hp) and dist(a.pos, u.pos) <= 2:
				use_skill(u, "miriam_heal", a.pos)
				return
	if u.ai == "ranged":
		_ai_ranged(u)
	else:
		_ai_melee(u)


func _ai_targets(e: Unit) -> Array:
	var all: Array = side_units(opp(e.side))
	if has_st(e, "taunt"):
		for a in all:
			if a.uid == e.taunter:
				return [a]
	var vis: Array = all.filter(func(a): return not has_st(a, "stealth"))
	return vis if not vis.is_empty() else all


func _danger(c: Vector2i) -> float:
	return 8.0 if fire.has(c) else 0.0


## 목표 칸들까지의 거리장 (유닛 무시)
func _field(goals: Array) -> Dictionary:
	var cost := {}
	var open: Array = []
	for g in goals:
		cost[g] = 0
		open.append(g)
	while not open.is_empty():
		var bi := 0
		for i in range(1, open.size()):
			if cost[open[i]] < cost[open[bi]]:
				bi = i
		var cur: Vector2i = open[bi]
		open.remove_at(bi)
		for dd in DIRS:
			var n: Vector2i = cur + dd
			if not is_floor(n):
				continue
			var nc: int = cost[cur] + enter_cost(cur)
			if not cost.has(n) or nc < cost[n]:
				cost[n] = nc
				open.append(n)
	return cost


func _ai_melee(e: Unit) -> void:
	var targets := _ai_targets(e)
	if targets.is_empty():
		return
	var reach := reachable(e, e.move_left)
	var rc: Dictionary = reach["cost"]
	var best_cell = null
	var best_t = null
	var best_s := INF
	for t in targets:
		for dd in DIRS:
			var c: Vector2i = t.pos + dd
			if not rc.has(c):
				continue
			var occ := unit_at(c)
			if occ != null and occ != e:
				continue
			var s: float = t.hp * 1.0 + rc[c] * 0.3 + _danger(c)
			if e.ai == "beast":
				var o := unit_at(t.pos * 2 - c)
				if o != null and o.side == e.side and o.alive():
					s -= 4.0
			if s < best_s:
				best_s = s
				best_cell = c
				best_t = t
	if best_cell != null:
		if best_cell != e.pos:
			move_unit(e, path_to(reach, best_cell))
		if e.alive() and best_t.alive() and dist(e.pos, best_t.pos) == 1:
			_strike(e, best_t)
		return
	var goals: Array = []
	for t in targets:
		for dd in DIRS:
			var c: Vector2i = t.pos + dd
			if is_floor(c):
				goals.append(c)
	var field := _field(goals)
	var bc := e.pos
	var bs: float = field.get(e.pos, 999) + _danger(e.pos)
	for c in rc.keys():
		if c != e.pos and unit_at(c) != null:
			continue
		var s: float = field.get(c, 999) + _danger(c) + rc[c] * 0.01
		if s < bs:
			bs = s
			bc = c
	if bc != e.pos:
		move_unit(e, path_to(reach, bc))
	for t in targets:
		if e.alive() and t.alive() and dist(e.pos, t.pos) == 1:
			_strike(e, t)
			return


func _ai_ranged(e: Unit) -> void:
	var targets := _ai_targets(e)
	if targets.is_empty():
		return
	var reach := reachable(e, e.move_left)
	var rc: Dictionary = reach["cost"]
	var orig := e.pos
	var best_c := orig
	var best_s := INF
	var best_t = null
	var foes: Array = side_units(opp(e.side))
	for c in rc.keys():
		if c != orig and unit_at(c) != null:
			continue
		e.pos = c
		var adj := false
		for a in foes:
			if dist(a.pos, c) == 1:
				adj = true
		var s: float = rc[c] * 0.05 + _danger(c) + (6.0 if adj else 0.0) + (-1.5 if tile(c) == "^" else 0.0)
		var tb := INF
		var tbest = null
		for t in targets:
			if dist(c, t.pos) <= e.atk_range:
				var ts: float = -hit_chance(e, t, true) * 10.0 + t.hp * 0.2
				if ts < tb:
					tb = ts
					tbest = t
		if tbest == null:
			var md := 99
			for t in targets:
				md = mini(md, dist(c, t.pos))
			s += 20.0 + md
		else:
			s += tb
		if s < best_s:
			best_s = s
			best_c = c
			best_t = tbest
	e.pos = orig
	if best_c != orig:
		move_unit(e, path_to(reach, best_c))
	if e.alive() and best_t != null and best_t.alive() and dist(e.pos, best_t.pos) <= e.atk_range:
		_strike(e, best_t)


func _basic_hit(att: Unit, tgt: Unit) -> void:
	if att.side == "ally":
		var s: Dictionary = Defs.SKILLS[att.actions[0]]
		attack(att, tgt, s.dmg, false)
	else:
		attack(att, tgt, att.dmg, false)


func _strike(e: Unit, t: Unit) -> void:
	if e.side == "ally":
		_ally_strike(e, t)
		return
	var n := 2 if e.phase2 else 1
	for i in n:
		if not e.alive() or result != "":
			return
		if e.is_boss and i == 0 and round_no % 2 == 0:
			var adj: Array = side_units("ally").filter(func(a): return dist(a.pos, e.pos) == 1)
			if not adj.is_empty():
				_log("%s의 휩쓸기!" % e.name)
				_float(e.pos, "휩쓸기", ORANGE)
				for a in adj:
					attack(e, a, "1d8+4", false)
				continue
		var tgt: Unit = t
		if not tgt.alive() or dist(tgt.pos, e.pos) > e.atk_range:
			tgt = null
			for a in side_units("ally"):
				if dist(a.pos, e.pos) <= e.atk_range:
					tgt = a
					break
		if tgt == null:
			return
		var hit := attack(e, tgt, e.dmg, not e.melee)
		if hit and e.ai == "beast" and tgt.alive() and not "iron_wall" in tgt.traits:
			if not save(tgt, "str", 8 + e.atk):
				tgt.st["prone"] = 1
				_float(tgt.pos, "넘어짐", ORANGE)


func _ally_strike(u: Unit, t: Unit) -> void:
	var order: Array = []
	if u.resolve >= 100:
		order.append(u.ult)
	for sid in u.actions.slice(1):
		if u.cooldowns.get(sid, 0) == 0:
			order.append(sid)
	order.append(u.actions[0])
	for sid in order:
		var s: Dictionary = Defs.SKILLS[sid]
		var tg := skill_targets(u, sid)
		match s.target:
			"enemy", "tile":
				if t.pos in tg:
					use_skill(u, sid, t.pos)
					return
			"self":
				if sid == "lina_taunt" or sid == "cecile_ult" or sid == u.ult:
					use_skill(u, sid, u.pos)
					return
			"ally":
				use_skill(u, sid, u.pos)
				return
