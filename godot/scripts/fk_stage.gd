extends Control
## 포 더 킹식 전투 무대: 배경 위에 동료(왼쪽)와 적(오른쪽)이 마주 서고, 주변 환경 오브젝트가 놓인다.
## 전투 이벤트를 한 줄로 받아 차례로 연출한다 (판정 칸 굴림 → 동작 → 숫자).

signal picked(ref: Dictionary)

const Defs = preload("res://scripts/fk_defs.gd")

const POSE_DUR := {"attack": 0.45, "skill": 0.6, "hit": 0.4}
const POSE_WAIT := {"attack": 0.3, "skill": 0.4, "hit": 0.0}
const CUTIN_DUR := 1.2
const SD_FEET := 488.0 / 512.0
const DIE_REVEAL := 0.32  # 판정 칸이 하나씩 멈추는 간격

var battle = null
var bg_tex: Texture2D = null
var sprites := {}  # uid -> {pose: Texture2D}
var cutins := {}
var silhouettes := {}  # uid -> Texture2D (적 그림이 없어 동료 SD를 어둡게 써서 자리만 잡는다)
var speed := 1.0
var targets: Array = []
var pending := {}
var actor_uid := -1
var inspect_uid := -1
var found := {}  # 플레이어가 눌러서 찾은 오브젝트 (이름이 보인다)
var focus_obj := -1  # 지금 살펴보는 오브젝트
var st_icons := {}  # 상태 키 -> 아이콘
var props := {}  # 소품 키 -> Codex 그림 (없으면 코드 도형)
var bold_font: Font = null
var panel_sb: StyleBox = null  # 판정 패널 틀
var _ghost := {}  # uid -> 잃은 HP 가 천천히 줄어드는 잔상 비율

var _seq: Array = []
var _wait := 0.0
var _poses := {}
var _fade := {}  # uid -> 남은 사라짐 시간
var _gone := {}
var _hidden := {}  # 아직 등장 연출 전인 증원
var _down := {}
var _hp := {}
var _floats: Array = []
var _roll := {}
var _cutin := {}
var _fx: Array = []
var _obj_gone := {}
var _hits: Array = []  # 누를 수 있는 영역 [{rect, ref}]
var _t := 0.0


func reset() -> void:
	_seq.clear()
	_wait = 0.0
	_poses.clear()
	_fade.clear()
	_gone.clear()
	_hidden.clear()
	_down.clear()
	_hp.clear()
	_floats.clear()
	_roll = {}
	_cutin = {}
	_fx.clear()
	_obj_gone.clear()
	targets = []
	pending = {}
	actor_uid = -1
	inspect_uid = -1
	found.clear()
	focus_obj = -1


func push(ev: Dictionary) -> void:
	if ev.t == "spawn":
		_hidden[ev.uid] = true
	if ev.t == "hp" and not _hp.has(ev.uid):
		_hp[ev.uid] = ev.before
	_seq.append(ev)


func busy() -> bool:
	return not _seq.is_empty() or _wait > 0.0 or not _roll.is_empty() or not _cutin.is_empty()


func _roll_len(r: Dictionary) -> float:
	return 0.3 + DIE_REVEAL * r.n + 0.75


func _run_seq(delta: float) -> void:
	_wait -= delta * speed
	while _wait <= 0.0 and _roll.is_empty() and _cutin.is_empty() and not _seq.is_empty():
		var ev: Dictionary = _seq.pop_front()
		match ev.t:
			"turn":
				actor_uid = ev.uid
				_wait = 0.15
			"roll":
				_roll = ev.duplicate()
				_roll.time = 0.0
			"pose":
				if ev.pose == "down":
					_down[ev.uid] = true
				elif ev.pose == "idle":
					_down.erase(ev.uid)
				else:
					var dir := 0.0
					var me := _feet(ev.uid)
					if ev.to != -1:
						dir = _feet(ev.to).x - me.x
					elif ev.obj != -1:
						dir = _obj_pos(battle.objects[ev.obj]).x - me.x
					_poses[ev.uid] = {"pose": ev.pose, "t": 0.0, "dur": POSE_DUR.get(ev.pose, 0.4), "dir": dir}
					_wait = POSE_WAIT.get(ev.pose, 0.2)
			"hp":
				_hp[ev.uid] = ev.hp
			"float":
				_add_float(ev.uid, ev.text, ev.color)
			"die":
				_fade[ev.uid] = 0.6
				_wait = 0.2
			"spawn":
				_hidden.erase(ev.uid)
				_add_float(ev.uid, "등장!", Color(1.0, 0.6, 0.3))
				_wait = 0.4
			"obj":
				_obj_gone[ev.id] = true
				_fx.append({"id": ev.id, "fx": ev.fx, "t": 0.0, "to": ev.get("to", -1)})
				_wait = 0.35
			"cutin":
				if cutins.has(ev.uid):
					_cutin = {"tex": cutins[ev.uid], "t": 0.0}


func _add_float(uid: int, text: String, col: Color) -> void:
	var n := 0
	for f in _floats:
		if f.uid == uid and f.t < 0.5:
			n += 1
	_floats.append({"uid": uid, "text": text, "color": col, "t": -0.3 * n})


func _process(delta: float) -> void:
	if battle == null:
		return
	_t += delta
	_run_seq(delta)
	var dt := delta * speed
	for uid in _poses.keys():
		_poses[uid].t += dt
		if _poses[uid].t >= _poses[uid].dur:
			_poses.erase(uid)
	for uid in _fade.keys():
		_fade[uid] -= dt
		if _fade[uid] <= 0.0:
			_fade.erase(uid)
			_gone[uid] = true
	if not _roll.is_empty():
		_roll.time += dt
		if _roll.time >= _roll_len(_roll):
			_roll = {}
	if not _cutin.is_empty():
		_cutin.t += dt
		if _cutin.t >= CUTIN_DUR:
			_cutin = {}
	for f in _floats:
		f.t += dt
	_floats = _floats.filter(func(f): return f.t < 1.4)
	for f in _fx:
		f.t += dt
	_fx = _fx.filter(func(f): return f.t < 0.8)
	for u in battle.units:
		var r: float = float(_hp.get(u.uid, u.hp)) / u.max_hp
		var g: float = _ghost.get(u.uid, r)
		_ghost[u.uid] = r if g < r else maxf(r, g - dt * 0.5)
	queue_redraw()


# ── 자리 계산 ───────────────────────────────────────

func _unit_h() -> float:
	return minf(size.y * 0.36, size.x * 0.12)


## 발끝 위치. 동료는 가운데에서 왼쪽으로, 적은 가운데에서 오른쪽으로 선다. 홀수 자리는 조금 앞(아래)으로
func _feet(uid: int) -> Vector2:
	var u = battle.unit(uid)
	if u == null:
		return Vector2.ZERO
	var x := 0.0
	var y: float = 0.74 + 0.10 * (u.slot % 2)
	if u.side == "ally":
		x = 0.38 - 0.12 * u.slot
	elif u.slot < 4:
		x = 0.62 + 0.10 * u.slot
	else:
		x = 0.67 + 0.10 * (u.slot - 4)
		y = 0.64
	return Vector2(x * size.x, y * size.y)


func _obj_pos(o: Dictionary) -> Vector2:
	return Vector2(o.x * size.x, o.y * size.y)


func _is_target(ref: Dictionary) -> bool:
	return ref in targets


# ── 그리기 ──────────────────────────────────────────

func _draw() -> void:
	if battle == null:
		return
	_hits.clear()
	var font := get_theme_default_font()
	var fs := int(clampf(size.y * 0.032, 12, 22))
	if bg_tex != null:
		# 무대를 꽉 채우도록 잘라서 깐다
		var ts := Vector2(bg_tex.get_size())
		var k := maxf(size.x / ts.x, size.y / ts.y)
		var src_sz := size / k
		var src := Rect2((ts - src_sz) / 2.0, src_sz)
		draw_texture_rect_region(bg_tex, Rect2(Vector2.ZERO, size), src, Color(0.78, 0.78, 0.78))
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.2, 0.24, 0.18))

	# 오브젝트와 유닛을 발끝 높이 순서로 (뒤에서 앞으로) 그린다
	var items: Array = []
	for o in battle.objects:
		items.append({"y": o.y * size.y, "o": o})
	for u in battle.units:
		if _gone.has(u.uid) or _hidden.has(u.uid):
			continue
		items.append({"y": _feet(u.uid).y, "u": u})
	items.sort_custom(func(a, b): return a.y < b.y)
	for it in items:
		if it.has("o"):
			_draw_obj(it.o, font, fs)
		else:
			_draw_unit(it.u, font, fs)

	for f in _fx:
		_draw_fx(f)
	var ff := int(fs * 1.5)
	for f in _floats:
		if f.t < 0.0 or battle.unit(f.uid) == null:
			continue
		var p := _feet(f.uid) - Vector2(0, _unit_h() * 0.95 + f.t * size.y * 0.08)
		var a := clampf(1.4 - f.t, 0.0, 1.0)
		var fc: Color = f.color
		fc.a = a
		draw_string_outline(font, p - Vector2(150, 0), f.text, HORIZONTAL_ALIGNMENT_CENTER, 300, ff, 6, Color(0, 0, 0, a))
		draw_string(font, p - Vector2(150, 0), f.text, HORIZONTAL_ALIGNMENT_CENTER, 300, ff, fc)
	if not _roll.is_empty():
		_draw_roll(font, fs)
	if not _cutin.is_empty():
		_draw_cutin()


func _draw_unit(u, font: Font, fs: int) -> void:
	var feet := _feet(u.uid)
	var h := _unit_h() * (1.25 if u.boss else 1.0)
	var ps: Dictionary = _poses.get(u.uid, {})
	var pk: String = ps.get("pose", "idle")
	var down: bool = _down.has(u.uid)
	if ps.is_empty() and down:
		pk = "down"
	if not ps.is_empty():
		var k: float = ps.t / ps.dur
		if pk == "attack" or pk == "skill":
			feet.x += clampf(ps.dir * 0.35, -size.x * 0.12, size.x * 0.12) * sin(k * PI)
		elif pk == "hit":
			feet.x += sin(ps.t * 70.0) * h * 0.03 * (1.0 - k)
	var ref := {"k": "u", "uid": u.uid}
	var tg := _is_target(ref)
	var col: Color = u.color
	# 발밑 표시: 차례(금색), 대상 후보(빨강/초록), 고른 대상(밝게)
	if u.uid == actor_uid:
		_ellipse(feet, h * 0.30, h * 0.08, Color(1.0, 0.85, 0.3, 0.9))
	if tg:
		var tc := Color(1.0, 0.3, 0.25) if u.side == "enemy" else Color(0.4, 1.0, 0.5)
		tc.a = 0.55 + 0.25 * sin(_t * 6.0)
		if pending == ref:
			tc = Color(1.0, 0.95, 0.4)
		_ellipse(feet, h * 0.27, h * 0.07, tc)
	_ellipse(feet, h * 0.22, h * 0.05, Color(0, 0, 0, 0.45))

	var tex: Texture2D = null
	var frames: Dictionary = sprites.get(u.uid, {})
	if not frames.is_empty():
		tex = frames.get(pk, frames.get("idle"))
	var sil: bool = tex == null and silhouettes.has(u.uid)
	if sil:
		tex = silhouettes[u.uid]
	var mod := Color.WHITE
	if pk == "hit":
		mod = Color(1.0, 0.55, 0.55)
	if down and not frames.has("down"):
		mod = Color(0.4, 0.4, 0.4, 0.8)
	if _fade.has(u.uid):
		mod.a = _fade[u.uid] / 0.6
	var top := feet.y - h * 0.85
	if tex != null:
		var sz := h
		var rect := Rect2(feet.x - sz / 2.0, feet.y - sz * SD_FEET, sz, sz)
		var face_left: bool = u.side == "enemy"
		if not ps.is_empty() and absf(ps.dir) > 1.0:
			face_left = ps.dir < 0
		# 동료 그림은 오른쪽, 적 그림(과 실루엣으로 쓰는 동료 그림)은 원래 방향이 다르다
		var art_left: bool = u.side == "enemy" and not sil
		if face_left != art_left:
			rect = Rect2(rect.position, Vector2(-sz, sz))  # 음수 너비 = 좌우 반전 (같은 자리)
		if sil:
			# 실루엣: 붉은 테두리 + 어두운 몸
			var rim := Color(0.85, 0.2, 0.15, 0.8 * mod.a)
			for off in [Vector2(-3, 0), Vector2(3, 0), Vector2(0, -3), Vector2(0, 3)]:
				draw_texture_rect(tex, Rect2(rect.position + off, rect.size), false, rim)
			var body := Color(0.16, 0.10, 0.10, mod.a)
			if pk == "hit":
				body = Color(0.6, 0.15, 0.12, mod.a)
			draw_texture_rect(tex, rect, false, body)
		else:
			draw_texture_rect(tex, rect, false, mod)
	else:
		var r := h * 0.22
		var c := feet - Vector2(0, r * 1.2)
		draw_circle(c, r, Color(col, mod.a))
		draw_string(font, c + Vector2(-r, fs * 0.4), u.name.substr(0, 1), HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, fs + 4, Color.WHITE)
		top = c.y - r

	# HP 막대 (어두운 틀 + 잃은 만큼 하얀 잔상), 숫자, 이름, 결의, 상태 아이콘
	var bw := h * 0.6
	var bh := maxf(7.0, h * 0.045)
	var bp := feet + Vector2(-bw / 2.0, h * 0.08)
	var shp: int = _hp.get(u.uid, u.hp)
	var ratio: float = float(shp) / u.max_hp
	var hp_col := Color(0.36, 0.80, 0.38) if u.side == "ally" else Color(0.86, 0.27, 0.22)
	_bar(Rect2(bp, Vector2(bw, bh)), ratio, _ghost.get(u.uid, ratio), hp_col)
	var nf: Font = bold_font if bold_font != null else font
	var nfs := int(fs * 0.9)
	var label: String = u.name
	var num := "%d" % shp
	var ny := bp.y + bh + nfs + 2.0
	draw_string_outline(nf, Vector2(bp.x - 60, ny), label, HORIZONTAL_ALIGNMENT_CENTER, bw + 120, nfs, 5, Color(0, 0, 0, 0.9))
	draw_string(nf, Vector2(bp.x - 60, ny), label, HORIZONTAL_ALIGNMENT_CENTER, bw + 120, nfs, Color(1.0, 0.93, 0.8) if u.side == "ally" else Color(1.0, 0.82, 0.78))
	draw_string_outline(nf, Vector2(bp.x + bw + 4, bp.y + bh), num, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs, 4, Color(0, 0, 0, 0.9))
	draw_string(nf, Vector2(bp.x + bw + 4, bp.y + bh), num, HORIZONTAL_ALIGNMENT_LEFT, -1, nfs, Color.WHITE)
	if u.side == "ally" and not down:
		var rc := Color(1.0, 0.78, 0.25) if u.resolve < 100 else Color(1.0, 0.95, 0.55, 0.7 + 0.3 * sin(_t * 8.0))
		_bar(Rect2(bp + Vector2(0, -bh * 0.75 - 3.0), Vector2(bw, bh * 0.5)), u.resolve / 100.0, 0.0, rc)
	if down:
		draw_string_outline(font, Vector2(feet.x - 150, top - 6), "쓰러짐", HORIZONTAL_ALIGNMENT_CENTER, 300, fs, 4, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(feet.x - 150, top - 6), "쓰러짐", HORIZONTAL_ALIGNMENT_CENTER, 300, fs, Color(0.8, 0.8, 0.8))
	else:
		# 상태: 아이콘 한 줄 (남은 턴 숫자), 아이콘이 없으면 글자
		var keys: Array = []
		for k in u.st.keys():
			if u.st[k] > 0:
				keys.append(k)
		var isz := clampf(h * 0.13, 18.0, 34.0)
		var sx := feet.x - (keys.size() * (isz + 3.0) - 3.0) / 2.0
		for k in keys:
			var r := Rect2(sx, top - isz - 4.0, isz, isz)
			if st_icons.has(k):
				draw_texture_rect(st_icons[k], r, false)
				if u.st[k] > 1 and u.st[k] < 90:
					draw_string_outline(font, r.end - Vector2(isz * 0.3, 0), str(u.st[k]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(isz * 0.5), 3, Color.BLACK)
					draw_string(font, r.end - Vector2(isz * 0.3, 0), str(u.st[k]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(isz * 0.5), Color.WHITE)
			else:
				draw_string(font, r.position + Vector2(0, isz * 0.8), str(k).substr(0, 1), HORIZONTAL_ALIGNMENT_LEFT, -1, int(isz * 0.7), Color(1.0, 0.9, 0.6))
			sx += isz + 3.0
	if u.uid == actor_uid:
		var ay := top - fs * 1.6 + sin(_t * 5.0) * 4.0
		draw_colored_polygon(PackedVector2Array([Vector2(feet.x - 12, ay), Vector2(feet.x + 12, ay), Vector2(feet.x, ay + 16)]), Color(1.0, 0.85, 0.3))
	_hits.append({"rect": Rect2(feet.x - h * 0.28, feet.y - h * 0.85, h * 0.56, h * 0.95), "ref": ref})


## 소품 그림 크기 (유닛 키 대비, 512 정사각 캔버스 한 변)
const PROP_SIZE := {"bush": 0.8, "oil_jar": 0.6, "dead_tree": 2.0, "barricade": 0.72, "table": 0.85, "chandelier": 0.8, "ale_cask": 0.75}


## Codex 가 그린 소품 그림. 부서진 모습은 그림을 기울이거나 그을음으로 연출한다
func _draw_prop(o: Dictionary, tex: Texture2D, p: Vector2, gone: bool) -> Rect2:
	var sz: float = _unit_h() * PROP_SIZE.get(o.key, 0.7)
	var base := p
	if o.key == "dead_tree":
		base = p + Vector2(0, _unit_h() * 0.45)
	var rect := Rect2(-sz / 2.0, -sz * 0.95, sz, sz)  # 바닥 = 캔버스 95% 높이
	if o.key == "chandelier":
		rect = Rect2(-sz / 2.0, -sz / 2.0, sz, sz)
		if gone:
			base = Vector2(p.x, size.y * 0.8)
	if gone:
		match o.key:
			"oil_jar", "ale_cask":
				_ellipse(p - Vector2(0, sz * 0.03), sz * 0.45, sz * 0.12, Color(0.08, 0.06, 0.05, 0.7))
				return Rect2(base + rect.position, rect.size)
			"dead_tree":
				draw_set_transform(base, 1.3)
				draw_texture_rect(tex, rect, false)
				draw_set_transform(Vector2.ZERO)
				return Rect2()
			"chandelier":
				draw_set_transform(base, 0.25, Vector2(1.0, 0.7))
				draw_texture_rect(tex, rect, false, Color(0.7, 0.7, 0.7))
				draw_set_transform(Vector2.ZERO)
				return Rect2()
			_:
				draw_set_transform(base, 0.35)
				draw_texture_rect(tex, rect, false, Color(0.6, 0.6, 0.6, 0.6))
				draw_set_transform(Vector2.ZERO)
				return Rect2()
	if o.key != "chandelier":
		_ellipse(base, sz * 0.32, sz * 0.07, Color(0, 0, 0, 0.35))
	var r := Rect2(base + rect.position, rect.size)
	draw_texture_rect(tex, r, false)
	if focus_obj == o.id:
		# 살펴보는 중: 초록 빛이 깜빡인다
		draw_texture_rect(tex, r, false, Color(0.5, 1.0, 0.4, 0.25 + 0.2 * sin(_t * 6.0)))
	return r


func _draw_obj(o: Dictionary, font: Font, fs: int) -> void:
	var p := _obj_pos(o)
	var s := _unit_h() * 0.45
	var gone: bool = _obj_gone.has(o.id)
	var ref := {"k": "o", "id": o.id}
	var a := 0.35 if gone else 1.0
	if focus_obj == o.id and not gone:
		_ellipse(p + Vector2(0, s * 0.05), s * 0.75, s * 0.2, Color(0.6, 1.0, 0.4, 0.55 + 0.25 * sin(_t * 6.0)))
	var ptex: Texture2D = props.get(o.key)
	if ptex != null:
		var hr := _draw_prop(o, ptex, p, gone)
		if hr.size.x > 0.0:
			_hits.append({"rect": hr, "ref": ref})
		_obj_label(o, p, gone, font, fs)
		return
	match o.key:
		"bush":
			for i in 5:
				var q := p + Vector2((i - 2) * s * 0.28, -s * (0.25 + 0.12 * (i % 2)))
				draw_circle(q, s * 0.3, Color(0.16, 0.34, 0.14, a))
				draw_circle(q - Vector2(s * 0.06, s * 0.08), s * 0.16, Color(0.26, 0.48, 0.2, a))
		"oil_jar", "ale_cask":
			if gone:
				draw_circle(p - Vector2(0, s * 0.1), s * 0.35, Color(0.1, 0.08, 0.06, 0.7))
			elif o.key == "oil_jar":
				draw_circle(p - Vector2(0, s * 0.42), s * 0.38, Color(0.66, 0.38, 0.18))
				draw_rect(Rect2(p + Vector2(-s * 0.13, -s * 0.98), Vector2(s * 0.26, s * 0.24)), Color(0.5, 0.28, 0.12))
				draw_rect(Rect2(p + Vector2(-s * 0.3, -s * 0.5), Vector2(s * 0.6, s * 0.08)), Color(0.25, 0.14, 0.06))
			else:
				var r := Rect2(p + Vector2(-s * 0.4, -s * 0.95), Vector2(s * 0.8, s * 0.95))
				draw_rect(r, Color(0.52, 0.32, 0.16))
				for yy in [0.18, 0.5, 0.82]:
					draw_rect(Rect2(r.position + Vector2(0, r.size.y * yy), Vector2(r.size.x, s * 0.07)), Color(0.3, 0.3, 0.32))
		"dead_tree":
			var ang := 0.25 if not gone else 1.35
			draw_set_transform(p + Vector2(0, s * 1.0), ang, Vector2(0.75, 0.75))
			draw_rect(Rect2(-s * 0.18, -s * 2.6, s * 0.36, s * 2.6), Color(0.36, 0.26, 0.18, 1.0))
			draw_line(Vector2(0, -s * 2.0), Vector2(s * 0.6, -s * 2.5), Color(0.36, 0.26, 0.18), s * 0.1)
			draw_line(Vector2(0, -s * 1.5), Vector2(-s * 0.5, -s * 1.9), Color(0.36, 0.26, 0.18), s * 0.08)
			draw_set_transform(Vector2.ZERO)
		"barricade":
			for i in 3:
				draw_rect(Rect2(p + Vector2(-s * 0.7 + i * s * 0.48, -s * 0.9), Vector2(s * 0.3, s * 0.9)), Color(0.46, 0.32, 0.18, a))
			draw_line(p + Vector2(-s * 0.75, -s * 0.2), p + Vector2(s * 0.75, -s * 0.7), Color(0.32, 0.2, 0.1, a), s * 0.12)
		"chandelier":
			var cy := p.y + (size.y * 0.55 if gone else 0.0)
			if not gone:
				draw_line(Vector2(p.x, 0), Vector2(p.x, cy - s * 0.2), Color(0.3, 0.25, 0.2), 3.0)
			_ellipse(Vector2(p.x, cy), s * 0.7, s * 0.16, Color(0.55, 0.42, 0.22))
			if not gone:
				for i in 5:
					var cx := p.x + (i - 2) * s * 0.3
					draw_rect(Rect2(cx - 3, cy - s * 0.3, 6, s * 0.25), Color(0.95, 0.9, 0.8))
					draw_circle(Vector2(cx, cy - s * 0.36), 5, Color(1.0, 0.75, 0.3, 0.6 + 0.4 * sin(_t * 9.0 + i)))
		"table":
			draw_rect(Rect2(p + Vector2(-s * 0.7, -s * 0.55), Vector2(s * 1.4, s * 0.16)), Color(0.48, 0.32, 0.18))
			draw_rect(Rect2(p + Vector2(-s * 0.6, -s * 0.4), Vector2(s * 0.12, s * 0.4)), Color(0.38, 0.25, 0.14))
			draw_rect(Rect2(p + Vector2(s * 0.48, -s * 0.4), Vector2(s * 0.12, s * 0.4)), Color(0.38, 0.25, 0.14))
	_hits.append({"rect": Rect2(p.x - s * 0.8, p.y - s * 1.1, s * 1.6, s * 1.3), "ref": ref})
	_obj_label(o, p, gone, font, fs)


## 이름은 플레이어가 눌러서 찾은 뒤에만 보인다 (환경은 직접 찾는 것)
func _obj_label(o: Dictionary, p: Vector2, gone: bool, font: Font, fs: int) -> void:
	if gone or not found.has(o.id):
		return
	var name: String = o.name
	draw_string_outline(font, p + Vector2(-120, fs * 1.1), name, HORIZONTAL_ALIGNMENT_CENTER, 240, fs, 4, Color(0, 0, 0, 0.85))
	draw_string(font, p + Vector2(-120, fs * 1.1), name, HORIZONTAL_ALIGNMENT_CENTER, 240, fs, Color(1.0, 0.82, 0.5))


func _draw_fx(f: Dictionary) -> void:
	var o: Dictionary = battle.objects[f.id]
	var p := _obj_pos(o) - Vector2(0, _unit_h() * 0.2)
	var k: float = f.t / 0.8
	match f.fx:
		"explode", "burn":
			draw_circle(p, _unit_h() * (0.3 + 1.6 * k), Color(1.0, 0.55, 0.15, 0.6 * (1.0 - k)))
			draw_circle(p, _unit_h() * (0.15 + 0.8 * k), Color(1.0, 0.9, 0.4, 0.8 * (1.0 - k)))
		_:
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.25 * (1.0 - k)))


## 판정 칸: 주사위를 왼쪽 아래에서 던져 튕기며 굴러와 하나씩 멈춘다.
## 멈추는 순간 튀어 오르고, 성공은 초록 고리가 퍼지고, 실패는 흔들리고, 20은 금빛으로 터진다
func _draw_roll(font: Font, fs: int) -> void:
	var r := _roll
	var u = battle.unit(r.uid)
	var n: int = r.n
	var ds := clampf(size.y * 0.12, 44, 96)
	var gap := ds * 0.3
	var w := n * ds + (n - 1) * gap
	var pw := maxf(w + ds * 1.2, ds * 5.0)
	var c := Vector2(size.x / 2.0, size.y * 0.27)
	var t: float = r.time
	# 패널은 살짝 커지며 나타난다
	var pk := clampf(t / 0.15, 0.0, 1.0)
	var panel := Rect2(c.x - pw / 2.0, c.y - ds * 1.05, pw, ds * 2.6)
	panel = panel.grow(-(1.0 - ease(pk, 0.4)) * ds * 0.4)
	var all_in := t >= 0.3 + DIE_REVEAL * n
	var perfect: bool = r.ok == n and n > 1
	if all_in and perfect:
		# 완벽 성공: 패널 뒤로 금빛 빛줄기
		var k := clampf((t - (0.3 + DIE_REVEAL * n)) / 0.6, 0.0, 1.0)
		for j in 16:
			var ang := TAU * j / 16.0 + t * 0.8
			var d1 := Vector2(cos(ang), sin(ang))
			var d2 := Vector2(cos(ang + 0.08), sin(ang + 0.08))
			var rr := pw * (0.45 + 0.35 * ease(k, 0.3))
			draw_colored_polygon(PackedVector2Array([c, c + d1 * rr, c + d2 * rr]), Color(1.0, 0.85, 0.35, 0.45 * (1.0 - k * 0.6)))
	if panel_sb != null:
		draw_style_box(panel_sb, panel)
	else:
		draw_rect(panel, Color(0.08, 0.06, 0.05, 0.86 * pk))
		draw_rect(panel, Color(0.84, 0.70, 0.38, pk), false, 2.0)
	var title := "%s · %s" % [u.name if u != null else "", r.label]
	var tf: Font = bold_font if bold_font != null else font
	draw_string_outline(tf, Vector2(panel.position.x, panel.position.y + fs * 1.55), title, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, fs, 4, Color(0, 0, 0, 0.8 * pk))
	draw_string(tf, Vector2(panel.position.x, panel.position.y + fs * 1.55), title, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, fs, Color(0.96, 0.84, 0.55, pk))
	var shown := 0
	for i in n:
		var sl: Dictionary = r.slots[i]
		var target := Vector2(c.x - w / 2.0 + i * (ds + gap) + ds / 2.0, c.y + ds * 0.32)
		var t0 := 0.05 + i * 0.06  # 던지는 시각
		var t1 := 0.3 + DIE_REVEAL * (i + 1)  # 멈추는 시각
		if t < t0:
			continue
		var locked: bool = sl.tag in ["확정", "은신"]
		var k := clampf((t - t0) / (t1 - t0), 0.0, 1.0)
		var landed := t >= t1
		var pos := target
		var rot := 0.0
		var sc := 1.0
		var face := ""
		var col := Color(0.36, 0.30, 0.24)
		if not landed:
			# 굴러오는 중: 왼쪽 아래에서 날아와 점점 낮게 튕긴다
			var start := target + Vector2(-pw * 0.55 - i * ds * 0.3, ds * 1.6)
			pos = start.lerp(target, ease(k, 0.35))
			pos.y -= absf(sin(k * PI * 3.0)) * ds * 1.3 * pow(1.0 - k, 1.4)
			rot = pow(1.0 - k, 2.0) * TAU * 3.0 * (1.0 if i % 2 == 0 else -1.0)
			face = str(1 + int(t * 23.0 + i * 7) % 20)
			if locked:
				face = sl.tag
				col = Color(0.62, 0.42, 0.85) if sl.tag == "확정" else Color(0.3, 0.3, 0.45)
			# 바닥 그림자
			_ellipse(Vector2(pos.x, target.y + ds * 0.5), ds * 0.4 * (0.6 + 0.4 * k), ds * 0.08, Color(0, 0, 0, 0.35))
		else:
			shown += 1
			var lt := t - t1
			sc = 1.0 + 0.35 * maxf(0.0, 1.0 - lt / 0.18)
			if locked:
				face = sl.tag
				col = Color(0.62, 0.42, 0.85) if sl.tag == "확정" else Color(0.3, 0.3, 0.45)
			else:
				face = str(sl.v)
				col = Color(0.25, 0.62, 0.32) if sl.ok else Color(0.62, 0.2, 0.18)
				if sl.tag == "대성공":
					col = Color(0.92, 0.72, 0.2)
				elif sl.tag == "대실패":
					col = Color(0.28, 0.26, 0.26)
				if not sl.ok:
					pos.x += sin(lt * 70.0) * ds * 0.08 * maxf(0.0, 1.0 - lt / 0.3)
			# 멈춘 순간 퍼지는 고리
			if lt < 0.45:
				var ring := Color(0.5, 1.0, 0.5) if sl.ok else Color(1.0, 0.35, 0.3)
				if sl.tag == "대성공" or locked:
					ring = Color(1.0, 0.85, 0.35)
				ring.a = 0.8 * (1.0 - lt / 0.45)
				draw_arc(pos, ds * (0.5 + lt * 1.6), 0.0, TAU, 40, ring, 4.0)
			if sl.tag == "대성공" and lt < 0.6:
				for j in 8:
					var ang := TAU * j / 8.0
					var d := Vector2(cos(ang), sin(ang))
					draw_line(pos + d * ds * (0.55 + lt), pos + d * ds * (0.75 + lt * 1.6), Color(1.0, 0.9, 0.4, 1.0 - lt / 0.6), 3.0)
		draw_set_transform(pos, rot, Vector2(sc, sc))
		var pts := PackedVector2Array()
		for j in 6:
			var ang := -PI / 2.0 + j * PI / 3.0
			pts.append(Vector2(cos(ang), sin(ang)) * ds * 0.5)
		# d20 정면: 육각 외곽 + 가운데 삼각 면 + 둘레 면 6개를 번갈아 밝고 어둡게
		var shadow := PackedVector2Array()
		for p in pts:
			shadow.append(p + Vector2(0, ds * 0.06))
		draw_colored_polygon(shadow, Color(0, 0, 0, 0.45))
		draw_colored_polygon(pts, col.darkened(0.25))
		var inner := PackedVector2Array()
		for j in 3:
			var ang := -PI / 2.0 + j * TAU / 3.0
			inner.append(Vector2(cos(ang), sin(ang)) * ds * 0.3)
		for j in 6:
			var tv := inner[((j + 1) / 2) % 3]
			var shade := col.lightened(0.12) if j % 2 == 0 else col.darkened(0.08)
			draw_colored_polygon(PackedVector2Array([pts[j], pts[(j + 1) % 6], tv]), shade)
		draw_colored_polygon(inner, col.lightened(0.28))
		var edge := col.darkened(0.55)
		for j in 6:
			draw_line(pts[j], inner[((j + 1) / 2) % 3], edge, 1.5, true)
		var tri := inner.duplicate()
		tri.append(tri[0])
		draw_polyline(tri, edge, 1.5, true)
		pts.append(pts[0])
		draw_polyline(pts, Color(0.1, 0.07, 0.05), 3.0, true)
		draw_polyline(pts, Color(0.95, 0.88, 0.7, 0.8), 1.2, true)
		var dfs := int(ds * (0.42 if face.length() <= 2 else 0.26))
		var dfont: Font = bold_font if bold_font != null else font
		draw_string_outline(dfont, Vector2(-ds / 2.0, dfs * 0.36), face, HORIZONTAL_ALIGNMENT_CENTER, ds, dfs, 4, Color(0, 0, 0, 0.7))
		draw_string(dfont, Vector2(-ds / 2.0, dfs * 0.36), face, HORIZONTAL_ALIGNMENT_CENTER, ds, dfs, Color.WHITE)
		draw_set_transform(Vector2.ZERO)
	var foot := "필요 %d 이상" % r.need
	var fcol := Color(0.8, 0.8, 0.8)
	var ffs := fs
	if shown == n:
		foot = "%d/%d 성공" % [r.ok, n]
		fcol = Color(1.0, 0.85, 0.4)
		if perfect:
			foot += " · 완벽!"
		elif r.ok == 0:
			foot += " · 실패"
			fcol = Color(1.0, 0.5, 0.45)
		# 결과 글자가 튀어나온다
		var ft := t - (0.3 + DIE_REVEAL * n)
		ffs = int(fs * (1.0 + 0.5 * maxf(0.0, 1.0 - ft / 0.2)))
	draw_string_outline(font, Vector2(panel.position.x, panel.end.y - fs * 0.85), foot, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, ffs, 4, Color(0, 0, 0, 0.8))
	draw_string(font, Vector2(panel.position.x, panel.end.y - fs * 0.85), foot, HORIZONTAL_ALIGNMENT_CENTER, panel.size.x, ffs, fcol)

func _draw_cutin() -> void:
	var tex: Texture2D = _cutin.tex
	var k: float = _cutin.t / CUTIN_DUR
	var a := clampf(minf(k, 1.0 - k) * 8.0, 0.0, 1.0)
	var bh := size.y * 0.5
	var band := Rect2(0, (size.y - bh) / 2.0, size.x, bh)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45 * a))
	var tw := bh * tex.get_width() / float(tex.get_height())
	var slide := (1.0 - ease(clampf(k * 4.0, 0.0, 1.0), 0.3)) * size.x * 0.5 - k * size.x * 0.06
	draw_texture_rect(tex, Rect2((size.x - tw) / 2.0 + slide, band.position.y, tw, bh), false, Color(1, 1, 1, a))
	draw_rect(Rect2(0, band.position.y - 4, size.x, 4), Color(1.0, 0.85, 0.4, a))
	draw_rect(Rect2(0, band.end.y, size.x, 4), Color(1.0, 0.85, 0.4, a))


func _bar(r: Rect2, ratio: float, ghost: float, col: Color) -> void:
	draw_rect(r.grow(2), Color(0.05, 0.04, 0.03, 0.9))
	draw_rect(r, Color(0.16, 0.12, 0.1))
	if ghost > ratio:
		draw_rect(Rect2(r.position, Vector2(r.size.x * ghost, r.size.y)), Color(1.0, 0.95, 0.85, 0.8))
	var fr := Rect2(r.position, Vector2(r.size.x * clampf(ratio, 0.0, 1.0), r.size.y))
	draw_rect(fr, col)
	draw_rect(Rect2(fr.position, Vector2(fr.size.x, maxf(1.0, r.size.y * 0.3))), Color(1, 1, 1, 0.25))
	draw_rect(r.grow(1), Color(0.55, 0.43, 0.24, 0.9), false, 1.0)


func _ellipse(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, col)


func _gui_input(ev: InputEvent) -> void:
	if battle == null:
		return
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		# 앞(나중에 그린 것)부터 찾는다
		for i in range(_hits.size() - 1, -1, -1):
			if _hits[i].rect.has_point(ev.position):
				picked.emit(_hits[i].ref)
				return
